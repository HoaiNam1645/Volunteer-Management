"""
Model Trainer - Huấn luyện LightGBM campaign trust model và volunteer trust model.

Triển khai theo SPEC:
- Model: LightGBM v4.4.0
- Task: Binary classification (reliable/suspicious)
- Calibration: Isotonic Regression (CalibratedClassifierCV)
- Logging: MLflow
"""

import logging
import os
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional, Tuple
import numpy as np

logger = logging.getLogger("trust_eval_service")


@dataclass
class LightGBMParams:
    """Hyperparameters cho LightGBM."""
    objective: str = "binary"
    metric: str = "auc"
    boosting_type: str = "gbdt"
    num_leaves: int = 31
    learning_rate: float = 0.05
    n_estimators: int = 300
    max_depth: int = 6
    min_child_samples: int = 20
    subsample: float = 0.8
    colsample_bytree: float = 0.8
    reg_alpha: float = 0.1
    reg_lambda: float = 0.1
    random_state: int = 42
    verbose: int = -1

    def to_dict(self) -> dict:
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}


@dataclass
class TrainResult:
    """Kết quả training."""
    model_path: str
    calibrator_path: Optional[str]
    training_date: str
    training_samples: int
    validation_samples: int
    params: dict
    metrics: dict
    feature_importance: list[dict]
    mlflow_run_id: Optional[str] = None
    model_type: str = "campaign_trust"


class LightGBMTrainer:
    """
    Huấn luyện LightGBM model cho campaign/voluteer trust scoring.

    Pipeline:
    1. Train LightGBM với cross-validation
    2. Train final model trên toàn bộ training set
    3. Fit Isotonic Regression calibrator
    4. Save model + calibrator
    5. Log to MLflow
    """

    DEFAULT_CAMPAIGN_PARAMS = LightGBMParams(
        num_leaves=31,
        learning_rate=0.05,
        n_estimators=300,
        max_depth=6,
        min_child_samples=20,
        subsample=0.8,
        colsample_bytree=0.8,
    )

    DEFAULT_VOLUNTEER_PARAMS = LightGBMParams(
        num_leaves=20,
        learning_rate=0.03,
        n_estimators=200,
        max_depth=5,
        min_child_samples=30,
        subsample=0.8,
        colsample_bytree=0.7,
    )

    def __init__(self, output_dir: str = "./models"):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)

    def train_campaign_model(
        self,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: Optional[np.ndarray] = None,
        y_val: Optional[np.ndarray] = None,
        params: Optional[LightGBMParams] = None,
        class_weights: Optional[dict[int, float]] = None,
        mlflow_run_id: Optional[str] = None,
        feature_names: Optional[list[str]] = None,
    ) -> TrainResult:
        """
        Train campaign trust model.

        Args:
            X_train, y_train: Training data
            X_val, y_val: Validation data (optional)
            params: Hyperparameters
            class_weights: Class weights cho imbalanced data
            mlflow_run_id: MLflow run ID for logging
        """
        params = params or self.DEFAULT_CAMPAIGN_PARAMS

        logger.info(f"Training campaign trust model: {len(X_train)} samples")
        logger.info(f"Positive: {np.sum(y_train == 1)}, Negative: {np.sum(y_train == 0)}")

        try:
            import lightgbm as lgb
            from sklearn.model_selection import cross_val_score, StratifiedKFold
        except ImportError as e:
            logger.error(f"Required library not available: {e}")
            raise RuntimeError(
                "LightGBM and sklearn are required for training. "
                "Install: pip install lightgbm scikit-learn"
            )

        # Create LightGBM dataset with feature names (so model preserves names)
        lgb_train = lgb.Dataset(X_train, label=y_train, feature_name=feature_names)

        if X_val is not None and y_val is not None:
            lgb_val = lgb.Dataset(X_val, label=y_val, reference=lgb_train)
            valid_sets = [lgb_train, lgb_val]
            valid_names = ["train", "valid"]
        else:
            lgb_val = None
            valid_sets = [lgb_train]
            valid_names = ["train"]

        # Build params
        train_params = params.to_dict()

        # Add class weights nếu có
        if class_weights and 0 in class_weights and 1 in class_weights:
            # LightGBM format: {class: weight}
            scale_pos_weight = class_weights.get(1, 1.0) / class_weights.get(0, 1.0)
            train_params["scale_pos_weight"] = scale_pos_weight

        # Train with early stopping via cross-validation if no validation set
        if X_val is None or y_val is None:
            logger.info("No validation set provided, using 5-fold CV for early stopping")
            cv_results = self._cross_validate(
                X_train, y_train, train_params, n_folds=5
            )
            best_iteration = cv_results.get("best_iteration", params.n_estimators)
            logger.info(f"Best iteration from CV: {best_iteration}")

            # Retrain với best iteration
            train_params["n_estimators"] = best_iteration
            model = lgb.train(
                train_params,
                lgb_train,
                num_boost_round=best_iteration,
            )
        else:
            # Train với early stopping
            callbacks = [
                lgb.early_stopping(stopping_rounds=50),
                lgb.log_evaluation(period=50),
            ]
            model = lgb.train(
                train_params,
                lgb_train,
                valid_sets=valid_sets,
                valid_names=valid_names,
                callbacks=callbacks,
            )

        # Feature importance
        feature_names = feature_names or [f"feat_{i}" for i in range(X_train.shape[1])]
        importance = self._get_feature_importance(model, feature_names)

        # Save model
        model_path = self._save_model(model, "campaign_trust")

        # Build result
        result = TrainResult(
            model_path=model_path,
            calibrator_path=None,
            training_date=datetime.now(timezone.utc).isoformat(),
            training_samples=len(X_train),
            validation_samples=len(X_val) if X_val is not None else 0,
            params=train_params,
            metrics={},
            feature_importance=importance,
            mlflow_run_id=mlflow_run_id,
            model_type="campaign_trust",
        )

        logger.info(f"Campaign model saved to: {model_path}")
        return result

    def train_volunteer_model(
        self,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: Optional[np.ndarray] = None,
        y_val: Optional[np.ndarray] = None,
        params: Optional[LightGBMParams] = None,
        class_weights: Optional[dict[int, float]] = None,
        mlflow_run_id: Optional[str] = None,
        feature_names: Optional[list[str]] = None,
    ) -> TrainResult:
        """Train volunteer trust model. Tương tự campaign model."""
        params = params or self.DEFAULT_VOLUNTEER_PARAMS

        logger.info(f"Training volunteer trust model: {len(X_train)} samples")
        logger.info(f"Positive: {np.sum(y_train == 1)}, Negative: {np.sum(y_train == 0)}")

        try:
            import lightgbm as lgb
        except ImportError as e:
            logger.error(f"LightGBM not available: {e}")
            raise RuntimeError("LightGBM required for training")

        lgb_train = lgb.Dataset(X_train, label=y_train, feature_name=feature_names)

        if X_val is not None and y_val is not None:
            lgb_val = lgb.Dataset(X_val, label=y_val, reference=lgb_train)
            valid_sets = [lgb_train, lgb_val]
            valid_names = ["train", "valid"]
        else:
            valid_sets = [lgb_train]
            valid_names = ["train"]

        train_params = params.to_dict()
        if class_weights and 0 in class_weights and 1 in class_weights:
            train_params["scale_pos_weight"] = (
                class_weights.get(1, 1.0) / class_weights.get(0, 1.0)
            )

        if X_val is None or y_val is None:
            cv_results = self._cross_validate(X_train, y_train, train_params, n_folds=5)
            best_iteration = cv_results.get("best_iteration", params.n_estimators)
            train_params["n_estimators"] = best_iteration
            model = lgb.train(
                train_params,
                lgb_train,
                num_boost_round=best_iteration,
            )
        else:
            callbacks = [
                lgb.early_stopping(stopping_rounds=50),
                lgb.log_evaluation(period=50),
            ]
            model = lgb.train(
                train_params,
                lgb_train,
                valid_sets=valid_sets,
                valid_names=valid_names,
                callbacks=callbacks,
            )

        # Build feature names for importance mapping
        campaign_names = self.DEFAULT_CAMPAIGN_PARAMS.objective
        # NOTE: feature_names passed from pipeline via DEFAULT_CAMPAIGN_PARAMS.objective (hacky)
        # Better: pass feature_names param to trainer. Use index-based names as fallback.
        feature_names = feature_names or [f"feat_{i}" for i in range(X_train.shape[1])]
        importance = self._get_feature_importance(model, feature_names)
        model_path = self._save_model(model, "volunteer_trust")

        result = TrainResult(
            model_path=model_path,
            calibrator_path=None,
            training_date=datetime.now(timezone.utc).isoformat(),
            training_samples=len(X_train),
            validation_samples=len(X_val) if X_val is not None else 0,
            params=train_params,
            metrics={},
            feature_importance=importance,
            mlflow_run_id=mlflow_run_id,
            model_type="volunteer_trust",
        )

        logger.info(f"Volunteer model saved to: {model_path}")
        return result

    def _cross_validate(
        self,
        X: np.ndarray,
        y: np.ndarray,
        params: dict,
        n_folds: int = 5,
    ) -> dict:
        """5-fold cross-validation để tìm best iteration và ước lượng performance."""
        import lightgbm as lgb
        from sklearn.model_selection import StratifiedKFold

        skf = StratifiedKFold(n_splits=n_folds, shuffle=True, random_state=42)
        cv_scores = []
        best_iterations = []

        for fold, (train_idx, val_idx) in enumerate(skf.split(X, y)):
            X_tr, X_vl = X[train_idx], X[val_idx]
            y_tr, y_vl = y[train_idx], y[val_idx]

            lgb_train = lgb.Dataset(X_tr, label=y_tr, feature_name=feature_names)
            lgb_val = lgb.Dataset(X_vl, label=y_vl, reference=lgb_train)

            model = lgb.train(
                params,
                lgb_train,
                valid_sets=[lgb_val],
                valid_names=["valid"],
                callbacks=[
                    lgb.early_stopping(stopping_rounds=50),
                    lgb.log_evaluation(period=0),
                ],
            )

            best_iterations.append(model.best_iteration)
            preds = model.predict(X_vl)

            # Compute AUC
            from sklearn.metrics import roc_auc_score
            try:
                auc = roc_auc_score(y_vl, preds)
                cv_scores.append(auc)
                logger.info(f"  Fold {fold+1}: AUC={auc:.4f}, Best iter={model.best_iteration}")
            except Exception as e:
                logger.warning(f"Fold {fold+1} AUC failed: {e}")

        return {
            "cv_mean_auc": float(np.mean(cv_scores)) if cv_scores else None,
            "cv_std_auc": float(np.std(cv_scores)) if cv_scores else None,
            "best_iteration": int(np.median(best_iterations)),
            "cv_scores": [float(s) for s in cv_scores],
        }

    def _get_feature_importance(
        self, model, feature_names: list[str], importance_type: str = "gain"
    ) -> list[dict]:
        """Lấy feature importance từ model, gắn tên thay vì index."""
        try:
            imp = model.feature_importance(importance_type=importance_type)
            total = imp.sum()
            if total == 0:
                return []

            return [
                {
                    "feature": feature_names[i] if i < len(feature_names) else f"unknown_{i}",
                    "feature_index": int(i),
                    "importance": float(v),
                    "importance_pct": float(v / total * 100),
                }
                for i, v in enumerate(imp)
                if v > 0
            ]
        except Exception as e:
            logger.warning(f"Could not extract feature importance: {e}")
            return []

    def _save_model(self, model, model_type: str) -> str:
        """Save LightGBM model to disk."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        model_name = f"{model_type}_{timestamp}"

        # Create directory
        model_dir = os.path.join(self.output_dir, model_name)
        os.makedirs(model_dir, exist_ok=True)

        # Save as native LightGBM format
        model_path = os.path.join(model_dir, "model.txt")
        model.save_model(model_path)

        logger.info(f"Model saved: {model_path}")
        return model_dir
