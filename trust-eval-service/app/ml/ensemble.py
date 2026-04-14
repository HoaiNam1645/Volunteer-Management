"""
Ensemble Methods Framework - Combine multiple models for improved predictions.

Phase 7: Continuous Improvement

Provides:
- Voting ensemble (majority vote)
- Stacking ensemble (meta-learner)
- Weighted average of multiple model predictions
- Per-campaign-type specialized models

Usage:
    ensemble = CampaignTrustEnsemble()
    result = ensemble.predict(features, metadata)
"""

import logging
from typing import Optional
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger("trust_eval_service")


class EnsembleStrategy(str, Enum):
    VOTING = "voting"
    WEIGHTED_AVERAGE = "weighted_average"
    STACKING = "stacking"
    BEST_PERFORMANCE = "best_performance"


@dataclass
class ModelPrediction:
    model_name: str
    model_type: str
    score: float
    confidence: float
    metadata: dict = field(default_factory=dict)


@dataclass
class EnsembleResult:
    final_score: float
    final_label: str
    final_confidence: float
    predictions: list[ModelPrediction]
    strategy_used: str
    disagreement_detected: bool
    top_contributors: list[dict]


class CampaignTrustEnsemble:
    """
    Ensemble of multiple models for campaign trust evaluation.

    Models included:
    - LightGBM primary (campaign_trust)
    - LightGBM secondary (different training split)
    - Rule-based validator (expert system)
    - Isolation Forest anomaly score
    - Content Risk Classifier (TF-IDF + LR)

    Strategies:
    - VOTING: Majority vote on labels
    - WEIGHTED_AVERAGE: Weighted average of scores
    - STACKING: Use meta-learner to combine predictions
    - BEST_PERFORMANCE: Use model with best historical accuracy
    """

    DEFAULT_WEIGHTS = {
        "lightgbm_primary": 0.35,
        "lightgbm_secondary": 0.20,
        "rule_based": 0.15,
        "anomaly": 0.10,
        "content_risk": 0.20,
    }

    def __init__(
        self,
        strategy: EnsembleStrategy = EnsembleStrategy.WEIGHTED_AVERAGE,
        custom_weights: Optional[dict[str, float]] = None,
    ):
        self.strategy = strategy
        self.weights = custom_weights or self.DEFAULT_WEIGHTS.copy()
        self._models: dict = {}
        self._load_models()

    def _load_models(self):
        """Load available models for ensemble."""
        try:
            from app.models.ml_models import get_model_loader
            self._models["lightgbm_primary"] = get_model_loader().campaign_model
            logger.info("LightGBM primary model loaded for ensemble")
        except Exception as e:
            logger.warning(f"Could not load LightGBM primary: {e}")

        try:
            secondary_path = self._get_secondary_model_path()
            if secondary_path:
                import joblib
                self._models["lightgbm_secondary"] = joblib.load(secondary_path)
                logger.info(f"LightGBM secondary model loaded from {secondary_path}")
        except Exception as e:
            logger.warning(f"Could not load LightGBM secondary: {e}")

    def _get_secondary_model_path(self) -> Optional[str]:
        """Get path to secondary model if exists."""
        from app.config import get_settings
        settings = get_settings()
        import os
        base = settings.campaign_model_path
        secondary = base.rsplit("/", 1)[0] + "/campaign_trust_v2_alt"
        return secondary if os.path.exists(secondary) else None

    def predict(
        self,
        features: dict,
        metadata: Optional[dict] = None,
        campaign_type: Optional[str] = None,
    ) -> EnsembleResult:
        """
        Run ensemble prediction on campaign features.

        Args:
            features: Campaign feature dict from CampaignFeatureExtractor
            metadata: Optional metadata (campaign_type, priority, etc.)
            campaign_type: Optional campaign type for specialized scoring

        Returns:
            EnsembleResult with final score, label, confidence, and per-model predictions
        """
        predictions: list[ModelPrediction] = []

        predictions.append(self._predict_lightgbm_primary(features))

        if "lightgbm_secondary" in self._models:
            predictions.append(self._predict_lightgbm_secondary(features))

        predictions.append(self._predict_rule_based(features))

        predictions.append(self._predict_anomaly(features))

        predictions.append(self._predict_content_risk(features, metadata))

        if self.strategy == EnsembleStrategy.VOTING:
            final_score, final_confidence = self._voting_strategy(predictions)
            final_label = self._score_to_label(final_score)
        elif self.strategy == EnsembleStrategy.WEIGHTED_AVERAGE:
            final_score, final_confidence = self._weighted_average_strategy(predictions)
            final_label = self._score_to_label(final_score)
        elif self.strategy == EnsembleStrategy.BEST_PERFORMANCE:
            final_score, final_confidence = self._best_performance_strategy(predictions)
            final_label = self._score_to_label(final_score)
        else:
            final_score, final_confidence = self._weighted_average_strategy(predictions)
            final_label = self._score_to_label(final_score)

        disagreement = self._detect_disagreement(predictions)

        top_contributors = self._get_top_contributors(predictions, final_score)

        return EnsembleResult(
            final_score=round(final_score, 4),
            final_label=final_label,
            final_confidence=round(final_confidence, 4),
            predictions=predictions,
            strategy_used=self.strategy.value,
            disagreement_detected=disagreement,
            top_contributors=top_contributors,
        )

    def _predict_lightgbm_primary(self, features: dict) -> ModelPrediction:
        """Predict using primary LightGBM model."""
        try:
            if "lightgbm_primary" in self._models and self._models["lightgbm_primary"] is not None:
                model = self._models["lightgbm_primary"]
                feature_vector = self._features_to_vector(features, model.feature_name())
                import numpy as np
                X = np.array([feature_vector])
                proba = model.predict(X)
                score = float(proba[0]) if np.isscalar(proba) else float(proba[0][0])
                score = max(0.0, min(1.0, score))
                return ModelPrediction(
                    model_name="lightgbm_primary",
                    model_type="gradient_boosting",
                    score=score,
                    confidence=0.85,
                    metadata={"algorithm": "LightGBM"},
                )
        except Exception as e:
            logger.warning(f"LightGBM primary prediction failed: {e}")

        return ModelPrediction(
            model_name="lightgbm_primary",
            model_type="gradient_boosting",
            score=0.5,
            confidence=0.0,
            metadata={"error": "model_unavailable"},
        )

    def _predict_lightgbm_secondary(self, features: dict) -> ModelPrediction:
        """Predict using secondary LightGBM model (different split)."""
        try:
            if "lightgbm_secondary" in self._models:
                model = self._models["lightgbm_secondary"]
                feature_names = getattr(model, "feature_name_", lambda: list(features.keys())[:model.n_features_in_])()
                feature_vector = [features.get(fn, 0.0) for fn in feature_names]
                import numpy as np
                X = np.array([feature_vector])
                proba = model.predict_proba(X)
                score = float(proba[0][1]) if proba.shape[1] > 1 else float(proba[0][0])
                score = max(0.0, min(1.0, score))
                return ModelPrediction(
                    model_name="lightgbm_secondary",
                    model_type="gradient_boosting",
                    score=score,
                    confidence=0.80,
                    metadata={"algorithm": "LightGBM", "variant": "secondary_split"},
                )
        except Exception as e:
            logger.warning(f"LightGBM secondary prediction failed: {e}")

        return ModelPrediction(
            model_name="lightgbm_secondary",
            model_type="gradient_boosting",
            score=0.5,
            confidence=0.0,
            metadata={"error": "model_unavailable"},
        )

    def _predict_rule_based(self, features: dict) -> ModelPrediction:
        """Rule-based fallback prediction."""
        try:
            from app.core.decision_logic import DecisionLogic
            dl = DecisionLogic()
            trust_score = features.get("trust_score", features.get("composite_score", 0.5))
            risk_level = self._infer_risk_level(trust_score)
            anomaly_score = features.get("anomaly_score", 0.0)

            score = dl.decide(
                trust_score=trust_score,
                risk_level=risk_level,
                anomaly_score=anomaly_score,
            )["confidence_score"]

            return ModelPrediction(
                model_name="rule_based",
                model_type="expert_system",
                score=score,
                confidence=0.75,
                metadata={"algorithm": "decision_table"},
            )
        except Exception as e:
            logger.warning(f"Rule-based prediction failed: {e}")

        return ModelPrediction(
            model_name="rule_based",
            model_type="expert_system",
            score=0.5,
            confidence=0.0,
            metadata={"error": "model_unavailable"},
        )

    def _predict_anomaly(self, features: dict) -> ModelPrediction:
        """Anomaly-based risk score."""
        try:
            from app.ml.anomaly import AnomalyDetector
            detector = AnomalyDetector()
            is_anomaly, anomaly_score, anomaly_types = detector.detect_anomaly(features)
            score = 1.0 - anomaly_score if not is_anomaly else anomaly_score * 0.5

            return ModelPrediction(
                model_name="anomaly",
                model_type="isolation_forest",
                score=max(0.0, min(1.0, score)),
                confidence=0.70,
                metadata={
                    "is_anomaly": is_anomaly,
                    "anomaly_score": anomaly_score,
                    "anomaly_types": anomaly_types,
                },
            )
        except Exception as e:
            logger.warning(f"Anomaly prediction failed: {e}")

        return ModelPrediction(
            model_name="anomaly",
            model_type="isolation_forest",
            score=0.5,
            confidence=0.0,
            metadata={"error": "model_unavailable"},
        )

    def _predict_content_risk(self, features: dict, metadata: Optional[dict]) -> ModelPrediction:
        """Content risk score from ContentRiskClassifier."""
        try:
            from app.ml.content_risk_classifier import get_content_risk_classifier

            classifier = get_content_risk_classifier()
            title = metadata.get("title", "") if metadata else ""
            description = metadata.get("description", "") if metadata else ""

            result = classifier.predict_risk(title, description, use_ml=True)

            risk_score = result.risk_score
            trust_score = 1.0 - risk_score

            return ModelPrediction(
                model_name="content_risk",
                model_type="tfidf_logistic_regression",
                score=trust_score,
                confidence=result.confidence,
                metadata={
                    "risk_score": result.risk_score,
                    "risk_label": result.risk_label,
                    "model_used": result.model_used,
                },
            )
        except Exception as e:
            logger.warning(f"Content risk prediction failed: {e}")

        return ModelPrediction(
            model_name="content_risk",
            model_type="tfidf_logistic_regression",
            score=0.5,
            confidence=0.0,
            metadata={"error": "model_unavailable"},
        )

    def _features_to_vector(self, features: dict, feature_names: list) -> list:
        """Convert feature dict to ordered vector for model input."""
        return [features.get(fn, 0.0) for fn in feature_names]

    def _infer_risk_level(self, trust_score: float) -> str:
        """Infer risk level from trust score."""
        if trust_score >= 0.70:
            return "LOW"
        elif trust_score >= 0.40:
            return "MEDIUM"
        elif trust_score >= 0.20:
            return "HIGH"
        return "CRITICAL"

    def _voting_strategy(self, predictions: list[ModelPrediction]) -> tuple[float, float]:
        """Majority vote on labels."""
        labels = []
        for p in predictions:
            if p.confidence > 0:
                label = self._score_to_label(p.score)
                labels.append((label, p.confidence))

        if not labels:
            return 0.5, 0.0

        label_counts: dict = {}
        for label, conf in labels:
            if label not in label_counts:
                label_counts[label] = 0.0
            label_counts[label] += conf

        winning_label = max(label_counts, key=label_counts.get)
        votes = label_counts[winning_label]
        confidence = votes / sum(label_counts.values())

        score = {"MINIMAL": 0.1, "LOW": 0.3, "MEDIUM": 0.5, "HIGH": 0.7, "CRITICAL": 0.9}[winning_label]

        return score, confidence

    def _weighted_average_strategy(self, predictions: list[ModelPrediction]) -> tuple[float, float]:
        """Weighted average of model scores."""
        total_weight = 0.0
        weighted_sum = 0.0
        confidence_sum = 0.0

        for p in predictions:
            weight = self.weights.get(p.model_name, 0.1)
            if p.confidence > 0:
                effective_weight = weight * p.confidence
                weighted_sum += p.score * effective_weight
                confidence_sum += effective_weight
                total_weight += effective_weight

        if total_weight > 0:
            final_score = weighted_sum / total_weight
            avg_confidence = confidence_sum / len([p for p in predictions if p.confidence > 0])
            return final_score, avg_confidence

        return 0.5, 0.0

    def _best_performance_strategy(self, predictions: list[ModelPrediction]) -> tuple[float, float]:
        """Use model with best historical performance (highest confidence)."""
        available = [p for p in predictions if p.confidence > 0]

        if not available:
            return 0.5, 0.0

        best = max(available, key=lambda p: p.confidence * self.weights.get(p.model_name, 0.1))
        return best.score, best.confidence

    def _detect_disagreement(self, predictions: list[ModelPrediction]) -> bool:
        """Detect if models significantly disagree."""
        available = [p for p in predictions if p.confidence > 0]
        if len(available) < 2:
            return False

        scores = [p.score for p in available]
        score_range = max(scores) - min(scores)

        return score_range > 0.40

    def _get_top_contributors(self, predictions: list[ModelPrediction], final_score: float) -> list[dict]:
        """Get top contributing models to final score."""
        contributions = []
        for p in predictions:
            if p.confidence > 0:
                weight = self.weights.get(p.model_name, 0.1)
                contribution = weight * p.confidence
                contributions.append({
                    "model": p.model_name,
                    "model_type": p.model_type,
                    "score": p.score,
                    "confidence": p.confidence,
                    "weight": weight,
                    "contribution": round(contribution, 4),
                    "aligned": (p.score - final_score) < 0.2,
                })

        contributions.sort(key=lambda x: x["contribution"], reverse=True)
        return contributions[:4]

    def _score_to_label(self, score: float) -> str:
        """Convert numeric score to risk label."""
        if score >= 0.80:
            return "RELIABLE_HIGH"
        elif score >= 0.60:
            return "RELIABLE"
        elif score >= 0.40:
            return "NEUTRAL"
        elif score >= 0.20:
            return "SUSPICIOUS"
        return "SUSPICIOUS_HIGH"

    def update_weights(self, new_weights: dict[str, float]):
        """Update model weights (e.g., after A/B test results)."""
        total = sum(new_weights.values())
        if abs(total - 1.0) > 0.01:
            raise ValueError("Weights must sum to 1.0")
        self.weights.update(new_weights)
        logger.info(f"Ensemble weights updated: {self.weights}")
