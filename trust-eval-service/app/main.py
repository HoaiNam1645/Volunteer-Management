"""
Trust Evaluation Service - Phase 7 Continuous Improvement
ML-based Campaign Trust & Risk Evaluation API.

Phase 2 implementation:
- Feature Engineering (CampaignFeatureExtractor, VolunteerFeatureExtractor)
- Rule-based Validation (RuleBasedValidator)
- Content Analysis (ContentAnalyzer with risk keywords)
- Anomaly Detection (AnomalyDetector with Isolation Forest)
- Decision Logic (recommended_action)
- Full API endpoints for campaign/volunteer/batch evaluation

Phase 3 implementation:
- Training Data Generator (LabelGenerator)
- Data Preparation (DataPreparator)
- LightGBM Training (LightGBMTrainer)
- Probability Calibration (ProbabilityCalibrator with Isotonic Regression)
- Model Evaluation (ModelEvaluator: AUC-ROC, ECE, feature importance)
- MLflow Tracking + Registry (MLflowTracker)
- Training Pipeline (TrainingPipeline)
- Training API endpoints (/train/campaigns, /train/summary)

Phase 4 implementation:
- SHAP Explainability (TreeExplainer for LightGBM)
- Per-evaluation SHAP explanations (top positive/negative factors)
- SHAP explanations in campaign and volunteer evaluation responses

Phase 6 implementation (Production Hardening):
- Scheduled Model Retraining (scripts/scheduled_retrain.py)
- A/B Testing Framework (scripts/ab_test.py)
- Comprehensive Test Suite (tests/)
- Performance Optimization (app/core/cache.py - LRU TTL cache, batch inference)
- API Documentation & Deployment Guide (DEPLOYMENT.md)
- Security Hardening (app/core/security.py - rate limiting, internal auth)
"""

import logging
import sys
from datetime import datetime, timezone
from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.api.routes import health, campaign, volunteer, batch, train, monitoring
from app.models.ml_models import get_model_loader

settings = get_settings()

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
    ],
)

logger = logging.getLogger("trust_eval_service")

app = FastAPI(
    title="Trust Evaluation Service",
    description="ML-based Campaign Trust & Risk Evaluation API",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS - restrictive in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.app_env == "production"
        and ["http://localhost:5173", "http://localhost:8000"]
        or ["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# Security + Rate Limiting Middleware
from app.core.security import (
    rate_limit_middleware,
    internal_auth_middleware,
    require_internal_key_openapi,
)
app.middleware("http")(rate_limit_middleware)
app.middleware("http")(internal_auth_middleware)

# Include routers
app.include_router(health.router, prefix="", tags=["Health"])
app.include_router(
    campaign.router,
    prefix="/api/v1",
    tags=["Campaign Evaluation"],
    dependencies=[Depends(require_internal_key_openapi)],
)
app.include_router(
    volunteer.router,
    prefix="/api/v1",
    tags=["Volunteer Evaluation"],
    dependencies=[Depends(require_internal_key_openapi)],
)
app.include_router(
    batch.router,
    prefix="/api/v1",
    tags=["Batch Evaluation"],
    dependencies=[Depends(require_internal_key_openapi)],
)
app.include_router(
    train.router,
    prefix="/api/v1",
    tags=["Model Training"],
    dependencies=[Depends(require_internal_key_openapi)],
)
app.include_router(monitoring.router, prefix="/api/v1", tags=["Monitoring"])


@app.on_event("startup")
async def startup_event():
    logger.info("=" * 60)
    logger.info("Trust Evaluation Service starting up (Phase 7)...")
    logger.info(f"Environment: {settings.app_env}")
    logger.info(f"Debug: {settings.app_debug}")
    logger.info(f"DB Host: {settings.db_host}:{settings.db_port}/{settings.db_database}")
    logger.info(f"MLflow: {settings.mlflow_tracking_uri}")

    # Load ML models (will use rule-based fallback if models not available)
    model_loader = get_model_loader()

    # Log all loaded modules
    logger.info("=" * 60)
    logger.info("Phase 2 modules loaded:")
    logger.info("  - CampaignFeatureExtractor, VolunteerFeatureExtractor")
    logger.info("  - RuleBasedValidator (10 rules)")
    logger.info("  - ContentAnalyzer (NLP risk keywords)")
    logger.info("  - AnomalyDetector (Isolation Forest)")
    logger.info("  - DecisionLogic (8-row decision table)")
    logger.info("Phase 3 modules loaded:")
    logger.info("  - Training Pipeline (LabelGenerator, DataPreparator, Trainer)")
    logger.info("  - Probability Calibrator (Isotonic Regression)")
    logger.info("  - Model Evaluator (AUC-ROC, ECE, feature importance)")
    logger.info("  - MLflow Tracker (experiment tracking + model registry)")
    logger.info("Phase 4 modules loaded:")
    logger.info("  - SHAP Explainer (TreeExplainer for LightGBM)")
    logger.info("Phase 6 modules loaded (Production Hardening):")
    logger.info("  - TTLCache (LRU with TTL - campaign/volunteer evaluation)")
    logger.info("  - BatchInferenceOptimizer")
    logger.info("  - RateLimiter (100 req/min eval, 10 req/min train)")
    logger.info("  - InternalAuth (API key validation)")
    logger.info("  - InputSanitizer")
    logger.info("Phase 7 modules loaded (Continuous Improvement):")
    logger.info("  - MLMonitor (agreement rate, drift detection, PSI)")
    logger.info("  - KDV Feedback Collector (Laravel backend + API)")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Trust Evaluation Service shutting down...")


@app.get("/", tags=["Root"])
async def root():
    return {
        "service": "Trust Evaluation Service",
        "version": "0.1.0",
        "docs": "/docs",
        "health": "/health",
    }
