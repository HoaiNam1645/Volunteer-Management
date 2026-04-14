"""
Model Evaluator - Đánh giá model performance.

Metrics:
- AUC-ROC
- ECE (Expected Calibration Error)
- Feature importance
- Confusion matrix
- Precision/Recall/F1
"""

import logging
from dataclasses import dataclass, field
from typing import Optional
import numpy as np

logger = logging.getLogger("trust_eval_service")


@dataclass
class EvaluationMetrics:
    """Kết quả đánh giá model."""
    model_type: str
    auc_roc: float
    precision: float
    recall: float
    f1_score: float
    accuracy: float
    ece: float
    confusion_matrix: list[list[int]]
    threshold: float
    feature_importance: list[dict] = field(default_factory=list)
    prediction_distribution: dict = field(default_factory=dict)


class ModelEvaluator:
    """
    Đánh giá performance của trained model.

    Metrics:
    1. AUC-ROC - khả năng phân biệt reliable/suspicious
    2. ECE - calibration quality
    3. Precision/Recall/F1 - classification quality
    4. Feature importance - contribution của từng feature
    """

    DEFAULT_THRESHOLD = 0.5

    def evaluate(
        self,
        model,
        X_test: np.ndarray,
        y_test: np.ndarray,
        feature_names: list[str],
        model_type: str = "campaign_trust",
        threshold: float = DEFAULT_THRESHOLD,
    ) -> EvaluationMetrics:
        """
        Đánh giá model trên test set.

        Args:
            model: Trained model
            X_test: Test features
            y_test: True labels
            feature_names: Tên các features
            model_type: "campaign_trust" hoặc "volunteer_trust"
            threshold: Classification threshold

        Returns:
            EvaluationMetrics
        """
        logger.info(f"Evaluating {model_type} model: {len(X_test)} test samples")

        try:
            from sklearn.metrics import (
                roc_auc_score,
                precision_score,
                recall_score,
                f1_score,
                accuracy_score,
                confusion_matrix as sk_confusion_matrix,
            )
        except ImportError:
            logger.error("scikit-learn not available for evaluation")
            raise RuntimeError("scikit-learn required for evaluation")

        # Get predictions
        raw_probs = self._get_probs(model, X_test)
        y_pred = (raw_probs >= threshold).astype(int)

        # Compute metrics
        try:
            auc_roc = roc_auc_score(y_test, raw_probs)
        except ValueError:
            auc_roc = 0.5  # Fallback nếu chỉ có một class

        precision = precision_score(y_test, y_pred, zero_division=0)
        recall = recall_score(y_test, y_pred, zero_division=0)
        f1 = f1_score(y_test, y_pred, zero_division=0)
        accuracy = accuracy_score(y_test, y_pred)
        conf_matrix = sk_confusion_matrix(y_test, y_pred).tolist()

        # ECE
        ece = self._compute_ece(raw_probs, y_test)

        # Feature importance
        feature_imp = self._get_feature_importance(model, feature_names)

        # Prediction distribution
        pred_dist = {
            "mean_prob": float(np.mean(raw_probs)),
            "std_prob": float(np.std(raw_probs)),
            "min_prob": float(np.min(raw_probs)),
            "max_prob": float(np.max(raw_probs)),
            "above_threshold": int(np.sum(y_pred)),
            "below_threshold": int(np.sum(y_pred == 0)),
        }

        # Log results
        logger.info(f"AUC-ROC: {auc_roc:.4f}")
        logger.info(f"Accuracy: {accuracy:.4f}")
        logger.info(f"Precision: {precision:.4f}, Recall: {recall:.4f}, F1: {f1:.4f}")
        logger.info(f"ECE: {ece:.4f}")

        return EvaluationMetrics(
            model_type=model_type,
            auc_roc=round(auc_roc, 6),
            precision=round(precision, 6),
            recall=round(recall, 6),
            f1_score=round(f1, 6),
            accuracy=round(accuracy, 6),
            ece=round(ece, 6),
            confusion_matrix=conf_matrix,
            threshold=threshold,
            feature_importance=feature_imp,
            prediction_distribution=pred_dist,
        )

    def find_optimal_threshold(
        self,
        model,
        X_test: np.ndarray,
        y_test: np.ndarray,
        metric: str = "f1",
    ) -> float:
        """
        Tìm threshold tối ưu dựa trên metric.

        Args:
            model: Trained model
            X_test: Test features
            y_test: True labels
            metric: "f1", "precision", "recall", "accuracy"

        Returns:
            Optimal threshold
        """
        try:
            from sklearn.metrics import f1_score, precision_score, recall_score, accuracy_score
        except ImportError:
            return 0.5

        raw_probs = self._get_probs(model, X_test)

        best_threshold = 0.5
        best_score = 0.0

        for threshold in np.arange(0.1, 0.9, 0.05):
            y_pred = (raw_probs >= threshold).astype(int)

            if metric == "f1":
                score = f1_score(y_test, y_pred, zero_division=0)
            elif metric == "precision":
                score = precision_score(y_test, y_pred, zero_division=0)
            elif metric == "recall":
                score = recall_score(y_test, y_pred, zero_division=0)
            elif metric == "accuracy":
                score = accuracy_score(y_test, y_pred)
            else:
                score = f1_score(y_test, y_pred, zero_division=0)

            if score > best_score:
                best_score = score
                best_threshold = threshold

        logger.info(f"Optimal threshold ({metric}): {best_threshold:.2f} (score={best_score:.4f})")
        return round(best_threshold, 2)

    def cross_validate(
        self,
        X: np.ndarray,
        y: np.ndarray,
        model_class,
        model_params: dict,
        n_folds: int = 5,
        threshold: float = DEFAULT_THRESHOLD,
    ) -> dict:
        """
        Cross-validate model performance.

        Returns:
            dict với mean và std của các metrics
        """
        try:
            from sklearn.model_selection import StratifiedKFold
            from sklearn.metrics import roc_auc_score, f1_score, accuracy_score
        except ImportError:
            return {}

        skf = StratifiedKFold(n_splits=n_folds, shuffle=True, random_state=42)

        auc_scores = []
        f1_scores = []
        acc_scores = []

        for fold, (train_idx, val_idx) in enumerate(skf.split(X, y)):
            X_tr, X_vl = X[train_idx], X[val_idx]
            y_tr, y_vl = y[train_idx], y[val_idx]

            model = model_class(**model_params)
            model.fit(X_tr, y_tr)

            raw_probs = self._get_probs(model, X_vl)
            y_pred = (raw_probs >= threshold).astype(int)

            try:
                auc = roc_auc_score(y_vl, raw_probs)
            except ValueError:
                auc = 0.5
            f1 = f1_score(y_vl, y_pred, zero_division=0)
            acc = accuracy_score(y_vl, y_pred)

            auc_scores.append(auc)
            f1_scores.append(f1)
            acc_scores.append(acc)

            logger.info(f"Fold {fold+1}: AUC={auc:.4f}, F1={f1:.4f}, Acc={acc:.4f}")

        return {
            "auc_mean": float(np.mean(auc_scores)),
            "auc_std": float(np.std(auc_scores)),
            "f1_mean": float(np.mean(f1_scores)),
            "f1_std": float(np.std(f1_scores)),
            "accuracy_mean": float(np.mean(acc_scores)),
            "accuracy_std": float(np.std(acc_scores)),
            "fold_results": [
                {"auc": auc, "f1": f1, "accuracy": acc}
                for auc, f1, acc in zip(auc_scores, f1_scores, acc_scores)
            ],
        }

    def _get_probs(self, model, X: np.ndarray) -> np.ndarray:
        """Get probability predictions từ model."""
        try:
            if hasattr(model, "predict_proba"):
                probs = model.predict_proba(X)
                if probs.ndim == 2:
                    return probs[:, 1]
                return probs
            elif hasattr(model, "predict"):
                preds = model.predict(X)
                return preds.astype(float)
            else:
                return np.zeros(len(X))
        except Exception:
            return np.zeros(len(X))

    def _compute_ece(
        self,
        probs: np.ndarray,
        labels: np.ndarray,
        n_bins: int = 10,
    ) -> float:
        """Compute Expected Calibration Error."""
        if len(probs) == 0:
            return 1.0

        bin_edges = np.linspace(0.0, 1.0, n_bins + 1)
        ece = 0.0

        for i in range(n_bins):
            in_bin = (probs > bin_edges[i]) & (probs <= bin_edges[i + 1])
            if i == n_bins - 1:
                in_bin = (probs > bin_edges[i]) & (probs <= bin_edges[i + 1])

            bin_size = np.sum(in_bin)
            if bin_size == 0:
                continue

            avg_confidence = np.mean(probs[in_bin])
            accuracy = np.mean(labels[in_bin])

            ece += (bin_size / len(probs)) * abs(accuracy - avg_confidence)

        return float(ece)

    def _get_feature_importance(
        self,
        model,
        feature_names: list[str],
        top_n: int = 20,
    ) -> list[dict]:
        """Lấy top-N feature importance."""
        try:
            if hasattr(model, "feature_importances_"):
                importances = model.feature_importances_
                total = importances.sum()
                if total == 0:
                    return []

                paired = [
                    (name, float(imp), float(imp / total * 100))
                    for name, imp in zip(feature_names, importances)
                    if imp > 0
                ]
                paired.sort(key=lambda x: x[1], reverse=True)

                return [
                    {
                        "feature": name,
                        "importance": imp,
                        "importance_pct": pct,
                    }
                    for name, imp, pct in paired[:top_n]
                ]
            elif hasattr(model, "feature_name") and hasattr(model, "feature_importance"):
                # LightGBM
                import lightgbm as lgb
                names = model.feature_name()
                importances = model.feature_importance(importance_type="gain")
                total = importances.sum()
                if total == 0:
                    return []

                paired = [
                    (name, float(imp), float(imp / total * 100))
                    for name, imp in zip(names, importances)
                    if imp > 0
                ]
                paired.sort(key=lambda x: x[1], reverse=True)

                return [
                    {
                        "feature": name,
                        "importance": imp,
                        "importance_pct": pct,
                    }
                    for name, imp, pct in paired[:top_n]
                ]
            else:
                return []
        except Exception as e:
            logger.warning(f"Could not extract feature importance: {e}")
            return []
