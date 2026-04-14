"""
Probability Calibration - Isotonic Regression calibration cho trust scores.

Triển khai theo SPEC:
- Phương pháp: Isotonic Regression (CalibratedClassifierCV với method='isotonic', cv=5)
- Mục tiêu: Đảm bảo xác suất đầu ra phản ánh đúng tần suất thực tế
- Metric: Expected Calibration Error (ECE) < 0.05
"""

import logging
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional, Tuple
import numpy as np

logger = logging.getLogger("trust_eval_service")


@dataclass
class CalibrationResult:
    """Kết quả calibration."""
    calibrator_path: str
    ece_before: float
    ece_after: float
    calibration_improvement: float
    calibration_method: str = "isotonic"
    cv_folds: int = 5


class ProbabilityCalibrator:
    """
    Calibrate probability outputs sử dụng Isotonic Regression.

    Quy trình:
    1. Train isotonic regression trên predictions
    2. Evaluate ECE trước và sau calibration
    3. Save calibrator
    """

    def __init__(self, output_dir: str = "./models"):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)

    def calibrate(
        self,
        model,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: np.ndarray,
        y_val: np.ndarray,
        model_type: str = "campaign_trust",
        cv_folds: int = 5,
    ) -> Tuple[any, CalibrationResult]:
        """
        Calibrate model predictions using Isotonic Regression.

        Args:
            model: Trained model với .predict() method
            X_train, y_train: Training data để fit calibrator
            X_val, y_val: Validation data để evaluate
            model_type: "campaign_trust" hoặc "volunteer_trust"
            cv_folds: Số folds cho CV-based calibration

        Returns:
            (calibrated_model, CalibrationResult)
        """
        logger.info(f"Calibrating {model_type} model...")

        try:
            from sklearn.calibration import CalibratedClassifierCV
            from sklearn.isotonic import IsotonicRegression
        except ImportError:
            logger.warning("scikit-learn not available, skipping calibration")
            return model, CalibrationResult(
                calibrator_path="",
                ece_before=1.0,
                ece_after=1.0,
                calibration_improvement=0.0,
            )

        # Get raw predictions
        raw_probs_train = self._get_probs(model, X_train)
        raw_probs_val = self._get_probs(model, X_val)

        # ECE trước calibration
        ece_before = self._compute_ece(raw_probs_val, y_val)
        logger.info(f"ECE before calibration: {ece_before:.4f}")

        # Train isotonic regression
        try:
            calibrator = IsotonicRegression(y_min=0.0, y_max=1.0, out_of_bounds="clip")
            calibrator.fit(raw_probs_train, y_train)
            calibrated_probs_val = calibrator.predict(raw_probs_val)
        except Exception as e:
            logger.error(f"Isotonic Regression fitting failed: {e}")
            return model, CalibrationResult(
                calibrator_path="",
                ece_before=ece_before,
                ece_after=ece_before,
                calibration_improvement=0.0,
            )

        # ECE sau calibration
        ece_after = self._compute_ece(calibrated_probs_val, y_val)
        logger.info(f"ECE after calibration: {ece_after:.4f}")
        logger.info(f"Calibration improvement: {ece_before - ece_after:.4f}")

        # Save calibrator
        calibrator_path = self._save_calibrator(calibrator, model_type)

        result = CalibrationResult(
            calibrator_path=calibrator_path,
            ece_before=round(ece_before, 6),
            ece_after=round(ece_after, 6),
            calibration_improvement=round(ece_before - ece_after, 6),
            calibration_method="isotonic",
            cv_folds=cv_folds,
        )

        return calibrator, result

    def calibrate_with_cv(
        self,
        X: np.ndarray,
        y: np.ndarray,
        model_type: str = "campaign_trust",
        cv_folds: int = 5,
    ) -> Tuple[any, CalibrationResult]:
        """
        Calibrate sử dụng cross-validation để avoid overfitting.

        Sử dụng CalibratedClassifierCV với cv='prefit' hoặc cv folds.
        """
        logger.info(f"Calibrating {model_type} with {cv_folds}-fold CV...")

        try:
            from sklearn.calibration import CalibratedClassifierCV
            from sklearn.linear_model import LogisticRegression
            from sklearn.model_selection import StratifiedKFold
        except ImportError:
            logger.warning("scikit-learn not available, skipping calibration")
            return None, CalibrationResult(
                calibrator_path="",
                ece_before=1.0,
                ece_after=1.0,
                calibration_improvement=0.0,
            )

        # Train a simple logistic regression as base model for calibration
        # (in practice, you'd use the actual LightGBM predictions)
        base_model = LogisticRegression(max_iter=1000, random_state=42)
        base_model.fit(X, y)

        raw_probs = base_model.predict_proba(X)[:, 1]
        ece_before = self._compute_ece(raw_probs, y)
        logger.info(f"ECE before CV calibration: {ece_before:.4f}")

        # CalibratedClassifierCV với isotonic
        calibrated = CalibratedClassifierCV(
            estimator=base_model,
            method="isotonic",
            cv=cv_folds,
        )
        calibrated.fit(X, y)

        calibrated_probs = calibrated.predict_proba(X)[:, 1]
        ece_after = self._compute_ece(calibrated_probs, y)
        logger.info(f"ECE after CV calibration: {ece_after:.4f}")

        result = CalibrationResult(
            calibrator_path="",
            ece_before=round(ece_before, 6),
            ece_after=round(ece_after, 6),
            calibration_improvement=round(ece_before - ece_after, 6),
            calibration_method="isotonic_cv",
            cv_folds=cv_folds,
        )

        return calibrated, result

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
                raise ValueError("Model has no predict or predict_proba method")
        except Exception as e:
            logger.error(f"Error getting predictions: {e}")
            return np.zeros(len(X))

    def _compute_ece(
        self,
        probs: np.ndarray,
        labels: np.ndarray,
        n_bins: int = 10,
    ) -> float:
        """
        Tính Expected Calibration Error (ECE).

        ECE = Σ_b |B_b| / n * |acc(B_b) - conf(B_b)|

        Trong đó:
        - B_b là tập samples trong bin b
        - acc(B_b) là accuracy của bin b
        - conf(B_b) là average confidence của bin b
        """
        if len(probs) == 0 or len(labels) == 0:
            return 1.0

        bin_edges = np.linspace(0.0, 1.0, n_bins + 1)
        ece = 0.0

        for i in range(n_bins):
            bin_lower = bin_edges[i]
            bin_upper = bin_edges[i + 1]

            in_bin = (probs > bin_lower) & (probs <= bin_upper)
            if i == n_bins - 1:
                in_bin = (probs > bin_lower) & (probs <= bin_upper)

            bin_size = np.sum(in_bin)
            if bin_size == 0:
                continue

            bin_probs = probs[in_bin]
            bin_labels = labels[in_bin]

            avg_confidence = np.mean(bin_probs)
            accuracy = np.mean(bin_labels)

            ece += (bin_size / len(probs)) * abs(accuracy - avg_confidence)

        return float(ece)

    def _save_calibrator(
        self,
        calibrator,
        model_type: str,
    ) -> str:
        """Save isotonic regression calibrator to disk."""
        try:
            import joblib

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            calibrator_name = f"{model_type}_calibrator_{timestamp}.pkl"
            calibrator_path = os.path.join(self.output_dir, calibrator_name)

            joblib.dump(calibrator, calibrator_path)
            logger.info(f"Calibrator saved: {calibrator_path}")
            return calibrator_path
        except Exception as e:
            logger.error(f"Failed to save calibrator: {e}")
            return ""

    def load_calibrator(self, calibrator_path: str):
        """Load calibrator từ disk."""
        try:
            import joblib
            return joblib.load(calibrator_path)
        except Exception as e:
            logger.error(f"Failed to load calibrator: {e}")
            return None
