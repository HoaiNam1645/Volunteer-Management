"""
ML Models - Model loading, inference, and calibration.

Phase 2: Uses rule-based scoring as fallback (ML models not trained yet).
Phase 3: Load trained LightGBM models + Isotonic Regression calibration.
"""

import logging
import os
from typing import Optional

import numpy as np

logger = logging.getLogger("trust_eval_service")


class ModelLoader:
    """
    Quản lý việc load và sử dụng ML models.

    Phase 2: Rule-based scoring fallback.
    Phase 3: Load trained LightGBM + Isotonic Regression calibration.
    """

    def __init__(self):
        self._campaign_model = None
        self._volunteer_model = None
        self._campaign_calibrator = None
        self._volunteer_calibrator = None
        self._loaded = False
        self._calibration_loaded = False

    def load_models(self) -> bool:
        """
        Load all ML models and calibrators from disk.

        Tries to load from 'latest' paths first, then fallback to config paths.
        Returns True if ML models loaded, False if using rule-based fallback.
        Phase 3: Also loads isotonic regression calibrators.
        """
        from app.config import get_settings
        settings = get_settings()

        model_loaded = False
        calibration_loaded = False

        try:
            # Helper to try multiple paths
            def try_load_model(paths: list[str], loader_fn):
                for path in paths:
                    if os.path.exists(path):
                        try:
                            return loader_fn(path)
                        except Exception as e:
                            logger.debug(f"Failed to load from {path}: {e}")
                return None

            # Load campaign model
            campaign_paths = [
                os.path.join(settings.campaign_model_path, "model.txt"),
                "./models/campaign_trust_latest/model.txt",
            ]
            try:
                import lightgbm as lgb
                model_path = next((p for p in campaign_paths if os.path.exists(p)), None)
                if model_path:
                    self._campaign_model = lgb.Booster(model_file=model_path)
                    logger.info(f"Loaded campaign model from {model_path}")
                    model_loaded = True
            except ImportError:
                logger.warning("LightGBM not available")
            except Exception as e:
                logger.warning(f"Could not load campaign model: {e}")

            # Load campaign calibrator (Phase 3)
            calibration_paths = [
                settings.campaign_model_path,
                "./models/campaign_trust_latest",
            ]
            try:
                import joblib
                for calib_dir in calibration_paths:
                    for fname in os.listdir(calib_dir):
                        if fname.endswith("_calibrator.pkl"):
                            self._campaign_calibrator = joblib.load(
                                os.path.join(calib_dir, fname)
                            )
                            logger.info(f"Loaded campaign calibrator: {fname}")
                            calibration_loaded = True
                            break
            except ImportError:
                logger.warning("joblib not available for calibrator loading")
            except Exception as e:
                logger.warning(f"Could not load campaign calibrator: {e}")

            # Load volunteer model
            volunteer_paths = [
                os.path.join(settings.volunteer_model_path, "model.txt"),
                "./models/volunteer_trust_latest/model.txt",
            ]
            try:
                import lightgbm as lgb
                model_path = next((p for p in volunteer_paths if os.path.exists(p)), None)
                if model_path:
                    self._volunteer_model = lgb.Booster(model_file=model_path)
                    logger.info(f"Loaded volunteer model from {model_path}")
                    model_loaded = True
            except Exception as e:
                logger.warning(f"Could not load volunteer model: {e}")

            # Load volunteer calibrator (Phase 3)
            volunteer_calibration_paths = [
                settings.volunteer_model_path,
                "./models/volunteer_trust_latest",
            ]
            try:
                import joblib
                for calib_dir in volunteer_calibration_paths:
                    if not os.path.isdir(calib_dir):
                        continue
                    for fname in os.listdir(calib_dir):
                        if fname.endswith("_calibrator.pkl"):
                            self._volunteer_calibrator = joblib.load(
                                os.path.join(calib_dir, fname)
                            )
                            logger.info(f"Loaded volunteer calibrator: {fname}")
                            calibration_loaded = True
                            break
                    if self._volunteer_calibrator is not None:
                        break
            except ImportError:
                logger.warning("joblib not available for volunteer calibrator loading")
            except Exception as e:
                logger.warning(f"Could not load volunteer calibrator: {e}")

            self._loaded = model_loaded
            self._calibration_loaded = calibration_loaded

            if model_loaded:
                logger.info(f"Models loaded: campaign={self._campaign_model is not None}, "
                           f"volunteer={self._volunteer_model is not None}, "
                           f"calibration={calibration_loaded}")
            else:
                logger.info("ML models not found, using rule-based scoring")

            return model_loaded

        except ImportError as e:
            logger.warning(f"ML libraries not available: {e}. Using rule-based scoring.")
            return False
        except Exception as e:
            logger.warning(f"Error loading ML models: {e}. Using rule-based scoring.")
            return False

    def predict_campaign_trust(self, features: dict) -> dict:
        """
        Predict campaign trust score using ML model or fallback.
        """
        if self._campaign_model is not None:
            return self._ml_predict_campaign(features)
        else:
            return self._rule_based_campaign_score(features)

    def predict_volunteer_trust(self, features: dict) -> dict:
        """
        Predict volunteer trust score using ML model or fallback.
        """
        if self._volunteer_model is not None:
            return self._ml_predict_volunteer(features)
        else:
            return self._rule_based_volunteer_score(features)

    def _ml_predict_campaign(self, features: dict) -> dict:
        """ML-based campaign trust prediction with Phase 3 calibration."""
        import lightgbm as lgb

        feature_names = self._campaign_model.feature_name()
        values = [features.get(fn, 0.0) for fn in feature_names]

        raw_score = self._campaign_model.predict([values])[0]
        calibrated_score = self._calibrate(raw_score, self._campaign_calibrator)

        return {
            "raw_score": round(float(raw_score), 4),
            "calibrated_probability": round(float(calibrated_score), 4),
            "label": self._map_score_to_label(calibrated_score),
            "confidence": self._map_score_to_confidence(calibrated_score),
        }

    def _ml_predict_volunteer(self, features: dict) -> dict:
        """ML-based volunteer trust prediction with Phase 3 calibration."""
        import lightgbm as lgb
        from app.training.data_prep import DataPreparator

        # Get feature names: from model if available, else from DataPreparator constants
        try:
            feature_names = self._volunteer_model.feature_name()
            if not feature_names or feature_names == [f'f{i}' for i in range(len(feature_names))]:
                # Model was trained without feature names, use DataPreparator constants
                feature_names = DataPreparator.VOLUNTEER_FEATURE_NAMES
        except Exception:
            feature_names = DataPreparator.VOLUNTEER_FEATURE_NAMES

        values = [features.get(fn, 0.0) for fn in feature_names]

        raw_score = self._volunteer_model.predict([values])[0]
        calibrated_score = self._calibrate(raw_score, self._volunteer_calibrator)

        return {
            "raw_score": round(float(raw_score), 4),
            "calibrated_probability": round(float(calibrated_score), 4),
            "label": self._map_score_to_label(calibrated_score),
            "confidence": self._map_score_to_confidence(calibrated_score),
        }

    def _calibrate(self, raw_score: float, calibrator) -> float:
        """Apply probability calibration (Isotonic Regression)."""
        if calibrator is None:
            return raw_score
        try:
            return calibrator.predict([raw_score])[0]
        except Exception:
            return raw_score

    def _rule_based_campaign_score(self, features: dict) -> dict:
        """
        Rule-based trust scoring for campaigns.
        Used when ML models are not available (Phase 2).
        """
        score = 0.5

        # Campaign features
        if features.get("has_cover_image"):
            score += 0.05
        if features.get("has_location_coords"):
            score += 0.10
        if features.get("reg_deadline_reasonable"):
            score += 0.08
        if features.get("has_contact_info_in_desc"):
            score += 0.05
        if features.get("location_completeness", 0) > 0.5:
            score += 0.05
        if features.get("schedule_completeness", 0) > 0.5:
            score += 0.05
        if features.get("description_quality_score", 0) > 0.5:
            score += 0.05
        if features.get("skill_requirements_clarity"):
            score += 0.05
        if features.get("registration_ratio") and features["registration_ratio"] > 0.5:
            score += 0.03
        if features.get("max_volunteers") and features["max_volunteers"] >= 10:
            score += 0.02

        # Creator features
        if features.get("creator_has_verified_email"):
            score += 0.08
        if features.get("creator_has_avatar"):
            score += 0.03
        if features.get("creator_has_verified_phone"):
            score += 0.03
        if features.get("creator_campaign_count", 0) > 0:
            score += 0.05
        if features.get("creator_campaign_count", 0) > 10:
            score += 0.10
        if features.get("creator_account_age_days", 0) >= 30:
            score += 0.08
        if features.get("creator_avg_campaign_participation"):
            score += 0.05
        if (features.get("creator_volunteer_rating_avg") or 0) >= 4.5:
            score += 0.10
        elif (features.get("creator_volunteer_rating_avg") or 0) >= 4.0:
            score += 0.05
        if (features.get("creator_previous_cancellation_rate") or 0) < 0.1:
            score += 0.05
        if features.get("creator_report_count", 0) == 0:
            score += 0.03

        # Penalties
        if not features.get("has_cover_image"):
            score -= 0.05
        if not features.get("has_location_coords"):
            score -= 0.10
        if not features.get("reg_deadline_reasonable"):
            score -= 0.05
        if not features.get("creator_has_verified_email"):
            score -= 0.05
        if features.get("creator_account_age_days", 999) < 7:
            score -= 0.10
        if (features.get("creator_previous_cancellation_rate") or 0) > 0.3:
            score -= 0.15
        if features.get("creator_report_count", 0) > 0:
            score -= 0.10
        if features.get("creator_campaign_approval_rate", 1.0) < 0.5:
            score -= 0.10

        score = max(0.0, min(1.0, score))

        return {
            "raw_score": round(score, 4),
            "calibrated_probability": round(score, 4),
            "label": self._map_score_to_label(score),
            "confidence": self._map_score_to_confidence(score),
        }

    def _rule_based_volunteer_score(self, features: dict) -> dict:
        """
        Rule-based trust scoring for volunteers.
        """
        score = 0.5

        if features.get("has_verified_email"):
            score += 0.05
        if features.get("has_phone"):
            score += 0.03
        if features.get("has_avatar"):
            score += 0.03
        if features.get("has_certificates"):
            score += 0.08
        if features.get("has_experience"):
            score += 0.05
        if features.get("has_skills"):
            score += 0.03
        if features.get("account_age_days", 0) >= 30:
            score += 0.08
        if (features.get("completion_rate") or 0) >= 0.8:
            score += 0.10
        if (features.get("registration_cancellation_rate") or 1.0) < 0.1:
            score += 0.10
        if (features.get("avg_rating_received") or 0) >= 4.5:
            score += 0.08
        if (features.get("avg_feedback_rating_given") or 0) >= 4.0:
            score += 0.05
        if (features.get("profile_completeness_score") or 0) >= 0.8:
            score += 0.05

        # Penalties
        if features.get("is_new_account"):
            score -= 0.08
        if (features.get("registration_cancellation_rate") or 0) > 0.3:
            score -= 0.15
        if (features.get("no_show_rate") or 0) > 0.2:
            score -= 0.10
        if features.get("has_perfect_rating"):
            score -= 0.03  # Slight penalty for suspicious perfect ratings
        if (features.get("profile_completeness_score") or 1.0) < 0.4:
            score -= 0.08

        score = max(0.0, min(1.0, score))

        return {
            "raw_score": round(score, 4),
            "calibrated_probability": round(score, 4),
            "label": self._map_score_to_label(score),
            "confidence": self._map_score_to_confidence(score),
        }

    @staticmethod
    def _map_score_to_label(score: float) -> str:
        if score >= 0.80:
            return "RELIABLE_HIGH"
        if score >= 0.60:
            return "RELIABLE"
        if score >= 0.40:
            return "NEUTRAL"
        if score >= 0.20:
            return "SUSPICIOUS"
        return "SUSPICIOUS_HIGH"

    @staticmethod
    def _map_score_to_confidence(score: float) -> str:
        if score >= 0.75 or score <= 0.25:
            return "HIGH"
        if score >= 0.55 or score <= 0.35:
            return "MEDIUM"
        return "LOW"

    @staticmethod
    def _map_score_to_risk_level(score: float) -> str:
        if score >= 0.70:
            return "LOW"
        if score >= 0.40:
            return "MEDIUM"
        if score >= 0.20:
            return "HIGH"
        return "CRITICAL"


    def get_campaign_model_info(self) -> tuple:
        """Return (model, feature_names) for SHAP explainer."""
        return self._campaign_model, self._campaign_model.feature_name() if self._campaign_model else []

    def get_volunteer_model_info(self) -> tuple:
        """Return (model, feature_names) for SHAP explainer."""
        if self._volunteer_model:
            names = self._volunteer_model.feature_name()
            if not names or names == [f"f{i}" for i in range(len(names))]:
                from app.training.data_prep import DataPreparator
                names = DataPreparator.VOLUNTEER_FEATURE_NAMES
            return self._volunteer_model, names
        return None, []


# Global model loader instance
_model_loader: Optional[ModelLoader] = None


def get_model_loader() -> ModelLoader:
    global _model_loader
    if _model_loader is None:
        _model_loader = ModelLoader()
        _model_loader.load_models()
    return _model_loader
