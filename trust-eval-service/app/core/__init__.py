# Core modules - Phase 2
from app.core.database import get_db_cursor, get_db_pool, test_connection
from app.core.feature_extractor import CampaignFeatureExtractor, VolunteerFeatureExtractor
from app.core.rule_validator import RuleBasedValidator, ValidationRule
from app.core.risk_keywords import (
    RISK_KEYWORD_DICTIONARY,
    RISK_KEYWORD_MAP,
    RISK_PATTERN_MAP,
    RiskKeyword,
)
from app.core.decision_logic import DecisionLogic

__all__ = [
    "get_db_cursor",
    "get_db_pool",
    "test_connection",
    "CampaignFeatureExtractor",
    "VolunteerFeatureExtractor",
    "RuleBasedValidator",
    "ValidationRule",
    "RISK_KEYWORD_DICTIONARY",
    "RISK_KEYWORD_MAP",
    "RISK_PATTERN_MAP",
    "RiskKeyword",
    "DecisionLogic",
]
