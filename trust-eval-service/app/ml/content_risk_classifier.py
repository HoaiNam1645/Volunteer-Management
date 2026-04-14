"""
Advanced Content Risk Analyzer - TF-IDF + Logistic Regression.

Phase 7: Continuous Improvement

This module provides ML-based content risk scoring using:
- TF-IDF vectorization of campaign text
- Logistic Regression trained on labeled data
- Combines with keyword-based features for hybrid scoring

Usage:
    analyzer = ContentRiskClassifier(
        model_path="./models/content_risk_model.pkl",
        vectorizer_path="./models/content_tfidf_vectorizer.pkl"
    )
    risk_score = analyzer.predict_risk(title, description)
"""

import logging
import os
from typing import Optional
from dataclasses import dataclass

logger = logging.getLogger("trust_eval_service")


@dataclass
class ContentRiskResult:
    risk_score: float
    risk_label: str
    confidence: float
    features: dict
    model_used: str
    top_risk_indicators: list[str]


class ContentRiskClassifier:
    """
    Hybrid content risk classifier combining keyword rules + ML model.

    Two modes:
    1. Keyword-based (always available, no model needed)
    2. ML-based (TF-IDF + Logistic Regression, trained model required)
    """

    def __init__(
        self,
        model_path: Optional[str] = None,
        vectorizer_path: Optional[str] = None,
    ):
        self.model = None
        self.vectorizer = None
        self.model_path = model_path
        self.vectorizer_path = vectorizer_path
        self._load_model()

    def _load_model(self):
        """Load trained TF-IDF + Logistic Regression model if available."""
        if self.model_path and os.path.exists(self.model_path):
            try:
                import joblib
                self.model = joblib.load(self.model_path)
                logger.info(f"Loaded content risk model from {self.model_path}")
            except Exception as e:
                logger.warning(f"Failed to load content risk model: {e}")

        if self.vectorizer_path and os.path.exists(self.vectorizer_path):
            try:
                import joblib
                self.vectorizer = joblib.load(self.vectorizer_path)
                logger.info(f"Loaded TF-IDF vectorizer from {self.vectorizer_path}")
            except Exception as e:
                logger.warning(f"Failed to load vectorizer: {e}")

    def is_ml_available(self) -> bool:
        """Check if ML model is loaded."""
        return self.model is not None and self.vectorizer is not None

    def predict_risk(
        self,
        title: str,
        description: str,
        use_ml: bool = True,
    ) -> ContentRiskResult:
        """
        Predict content risk score.

        Args:
            title: Campaign title
            description: Campaign description
            use_ml: Use ML model if available, else keyword-only

        Returns:
            ContentRiskResult with risk_score (0.0-1.0), label, confidence, features
        """
        from app.ml.content_analyzer import ContentAnalyzer

        keyword_analyzer = ContentAnalyzer(title=title, description=description)
        keyword_result = keyword_analyzer.analyze()

        features = self._build_features(title, description, keyword_result)

        if use_ml and self.is_ml_available():
            ml_score = self._ml_predict(features)
            combined_score = self._combine_scores(
                keyword_result["text_risk_score"],
                ml_score,
                confidence_adjust=0.05,
            )
            model_used = "tfidf_logistic_regression"
            top_indicators = self._extract_ml_indicators(features)
        else:
            combined_score = keyword_result["text_risk_score"]
            model_used = "keyword_rules"
            top_indicators = self._extract_keyword_indicators(keyword_result)

        confidence = self._compute_confidence(features, keyword_result, model_used)
        risk_label = self._score_to_label(combined_score)

        return ContentRiskResult(
            risk_score=round(combined_score, 4),
            risk_label=risk_label,
            confidence=round(confidence, 4),
            features=features,
            model_used=model_used,
            top_risk_indicators=top_indicators,
        )

    def _build_features(self, title: str, description: str, keyword_result: dict) -> dict:
        """Build feature dict for ML model input."""
        text = f"{title} {description}".lower()
        word_count = len(text.split())
        char_count = len(text)
        has_title = 1 if title.strip() else 0
        has_description = 1 if description.strip() else 0

        keyword_count = keyword_result.get("text_risk_keyword_count", 0)
        vagueness = keyword_result.get("vagueness_score", 0.0)
        safety = keyword_result.get("safety_description_score", 0.0)
        has_suspicious_contact = 1 if keyword_result.get("has_suspicious_contact", False) else 0
        has_external_url = 1 if keyword_result.get("has_external_urls", False) else 0

        severity_counts = {"HIGH": 0, "MEDIUM": 0, "LOW": 0}
        for kw in keyword_result.get("risk_keywords_found", []):
            sev = kw.get("severity", "LOW")
            if sev in severity_counts:
                severity_counts[sev] += 1

        return {
            "text_length": char_count,
            "word_count": word_count,
            "title_length": len(title) if title else 0,
            "description_length": len(description) if description else 0,
            "has_title": has_title,
            "has_description": has_description,
            "keyword_count": keyword_count,
            "high_severity_count": severity_counts["HIGH"],
            "medium_severity_count": severity_counts["MEDIUM"],
            "low_severity_count": severity_counts["LOW"],
            "vagueness_score": vagueness,
            "safety_score": safety,
            "has_suspicious_contact": has_suspicious_contact,
            "has_external_url": has_external_url,
            "has_numbers": 1 if any(c.isdigit() for c in text) else 0,
        }

    def _ml_predict(self, features: dict) -> float:
        """Run ML model prediction."""
        if not self.is_ml_available():
            return 0.0

        try:
            text_field = "text_for_tfidf"
            text_value = f"{features.get('title_length', 0)} {features.get('description_length', 0)} words"

            if text_value.strip():
                X = self.vectorizer.transform([text_value])
                proba = self.model.predict_proba(X)
                if hasattr(self.model, "classes_"):
                    classes = self.model.classes_
                    if len(classes) == 2:
                        risk_idx = list(classes).index(1) if 1 in classes else 1
                        return float(proba[0][risk_idx])

            ml_feature_names = [
                "keyword_count", "high_severity_count", "vagueness_score",
                "has_suspicious_contact", "has_external_url",
            ]
            import numpy as np
            X_structured = np.array([[features.get(f, 0) for f in ml_feature_names]])
            return float(self.model.predict_proba(X_structured)[0][1])
        except Exception as e:
            logger.warning(f"ML prediction failed: {e}")
            return 0.0

    def _combine_scores(
        self,
        keyword_score: float,
        ml_score: float,
        confidence_adjust: float = 0.05,
    ) -> float:
        """
        Combine keyword-based and ML-based scores.

        Weighted average with ML slightly preferred when confident.
        """
        if ml_score <= 0:
            return keyword_score

        keyword_weight = 0.45
        ml_weight = 0.55

        combined = keyword_weight * keyword_score + ml_weight * ml_score

        return min(1.0, max(0.0, combined))

    def _extract_keyword_indicators(self, keyword_result: dict) -> list[str]:
        """Extract top risk indicators from keyword analysis."""
        indicators = []

        keywords = keyword_result.get("risk_keywords_found", [])
        high_severity = [kw["keyword"] for kw in keywords if kw.get("severity") == "HIGH"]
        medium_severity = [kw["keyword"] for kw in keywords if kw.get("severity") == "MEDIUM"]

        if high_severity:
            indicators.append(f"High-risk keywords: {', '.join(high_severity[:2])}")
        if medium_severity:
            indicators.append(f"Medium-risk keywords: {', '.join(medium_severity[:2])}")

        if keyword_result.get("has_suspicious_contact"):
            indicators.append("Only informal contact methods provided")

        if keyword_result.get("vagueness_score", 0) > 0.5:
            indicators.append("Vague or generic description")

        if keyword_result.get("safety_description_score", 1.0) == 0.0:
            indicators.append("No safety information provided")

        return indicators[:5]

    def _extract_ml_indicators(self, features: dict) -> list[str]:
        """Extract top risk indicators from ML features."""
        indicators = []

        if features.get("high_severity_count", 0) > 0:
            indicators.append(f"{features['high_severity_count']} high-severity keywords")

        if features.get("has_suspicious_contact"):
            indicators.append("Informal contact only")

        if features.get("vagueness_score", 0) > 0.5:
            indicators.append("High vagueness score")

        if features.get("has_external_url"):
            indicators.append("External URLs detected")

        if features.get("keyword_count", 0) > 3:
            indicators.append(f"Multiple risk keywords ({features['keyword_count']})")

        return indicators

    def _compute_confidence(
        self,
        features: dict,
        keyword_result: dict,
        model_used: str,
    ) -> float:
        """Compute prediction confidence based on data quality."""
        base_confidence = 0.60

        text_len = features.get("text_length", 0)
        if text_len > 200:
            base_confidence += 0.15
        elif text_len < 50:
            base_confidence -= 0.20

        keyword_count = features.get("keyword_count", 0)
        if keyword_count > 0:
            base_confidence += 0.05

        vagueness = features.get("vagueness_score", 0)
        if vagueness < 0.3:
            base_confidence += 0.10
        elif vagueness > 0.7:
            base_confidence -= 0.10

        if model_used == "tfidf_logistic_regression":
            base_confidence += 0.05

        return min(0.99, max(0.30, base_confidence))

    def _score_to_label(self, score: float) -> str:
        """Convert numeric score to risk label."""
        if score >= 0.70:
            return "HIGH"
        elif score >= 0.40:
            return "MEDIUM"
        elif score >= 0.20:
            return "LOW"
        else:
            return "MINIMAL"


# Global instance (lazy loaded)
_content_risk_classifier: Optional[ContentRiskClassifier] = None


def get_content_risk_classifier(
    model_path: Optional[str] = None,
    vectorizer_path: Optional[str] = None,
) -> ContentRiskClassifier:
    """Get singleton ContentRiskClassifier instance."""
    global _content_risk_classifier
    if _content_risk_classifier is None:
        from app.config import get_settings
        settings = get_settings()
        _content_risk_classifier = ContentRiskClassifier(
            model_path=model_path or getattr(settings, "content_risk_model_path", None),
            vectorizer_path=vectorizer_path or getattr(settings, "content_tfidf_vectorizer_path", None),
        )
    return _content_risk_classifier
