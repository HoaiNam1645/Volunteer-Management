"""
Training API Routes - FastAPI endpoints cho model training.
"""

import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, BackgroundTasks, status
from pydantic import BaseModel

from app.training.pipeline import TrainingPipeline, PipelineConfig, PipelineResult
from app.training.mlflow_utils import get_mlflow_tracker

logger = logging.getLogger("trust_eval_service")
router = APIRouter()


class TrainRequest(BaseModel):
    """Request body cho training endpoint."""
    test_size: float = 0.2
    random_state: int = 42
    use_smote: bool = False
    calibration_enabled: bool = True
    min_training_samples: int = 100


class TrainResponse(BaseModel):
    """Response body cho training endpoint."""
    success: bool
    message: str
    training_samples: Optional[int] = None
    validation_samples: Optional[int] = None
    campaign_model_path: Optional[str] = None
    volunteer_model_path: Optional[str] = None
    campaign_metrics: Optional[dict] = None
    volunteer_metrics: Optional[dict] = None
    mlflow_run_id: Optional[str] = None
    error: Optional[str] = None
    timestamp: str


class TrainingSummaryResponse(BaseModel):
    """Response cho training data summary."""
    total_samples: int
    reliable_count: int
    suspicious_count: int
    ratio: Optional[float]
    by_source: dict
    by_confidence: dict
    can_train: bool


class MLflowRunInfo(BaseModel):
    """MLflow run info."""
    run_id: str
    run_name: str
    status: str
    metrics: dict


@router.post("/train/campaigns", response_model=TrainResponse)
async def train_campaign_model(
    request: TrainRequest,
    background_tasks: BackgroundTasks,
):
    """
    Trigger campaign trust model training.

    Training chạy trong background và trả về ngay lập tức.
    MLflow tracking được bật nếu available.
    """
    logger.info("Training request received")

    # Validate request
    if not 0.05 <= request.test_size <= 0.4:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="test_size must be between 0.05 and 0.4"
        )

    # Check MLflow
    mlflow_tracker = get_mlflow_tracker()
    if not mlflow_tracker.is_available:
        logger.warning("MLflow not available, training will proceed without tracking")

    # Run pipeline
    config = PipelineConfig(
        test_size=request.test_size,
        random_state=request.random_state,
        use_smote=request.use_smote,
        calibration_enabled=request.calibration_enabled,
        min_training_samples=request.min_training_samples,
    )

    pipeline = TrainingPipeline(config=config)
    result = pipeline.run_full_pipeline()

    if result.success:
        return TrainResponse(
            success=True,
            message="Training completed successfully",
            training_samples=result.training_samples,
            validation_samples=result.validation_samples,
            campaign_model_path=result.campaign_model_path,
            volunteer_model_path=result.volunteer_model_path,
            campaign_metrics=result.campaign_metrics,
            volunteer_metrics=result.volunteer_metrics,
            mlflow_run_id=result.mlflow_run_id,
            timestamp=datetime.now(timezone.utc).isoformat(),
        )
    else:
        return TrainResponse(
            success=False,
            message="Training failed",
            error=result.error,
            timestamp=datetime.now(timezone.utc).isoformat(),
        )


@router.get("/train/summary", response_model=TrainingSummaryResponse)
async def get_training_summary():
    """
    Lấy summary của training data hiện có.

    Trả về số lượng samples, phân bố labels, và có thể train được không.
    """
    try:
        pipeline = TrainingPipeline()
        summary = pipeline.get_training_summary()

        if not summary or summary.get("total", 0) == 0:
            return TrainingSummaryResponse(
                total_samples=0,
                reliable_count=0,
                suspicious_count=0,
                ratio=None,
                by_source={},
                by_confidence={},
                can_train=False,
            )

        can_train = summary.get("total", 0) >= 100

        return TrainingSummaryResponse(
            total_samples=summary.get("total", 0),
            reliable_count=summary.get("reliable", 0),
            suspicious_count=summary.get("suspicious", 0),
            ratio=summary.get("ratio"),
            by_source=summary.get("by_source", {}),
            by_confidence=summary.get("by_confidence", {}),
            can_train=can_train,
        )

    except Exception as e:
        logger.error(f"Failed to get training summary: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get training summary: {str(e)}"
        )


@router.get("/train/mlflow/runs", response_model=list[dict])
async def get_mlflow_runs(max_results: int = 20):
    """
    Lấy lịch sử các training runs từ MLflow.
    """
    tracker = get_mlflow_tracker()
    if not tracker.is_available:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="MLflow is not available"
        )

    runs = tracker.get_run_history(max_results=max_results)
    return runs


@router.get("/train/mlflow/models")
async def get_registered_models():
    """Lấy danh sách registered models từ MLflow."""
    tracker = get_mlflow_tracker()
    if not tracker.is_available:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="MLflow is not available"
        )

    models = []
    for model_name in ["campaign-trust", "volunteer-trust"]:
        version = tracker.get_latest_model_version(model_name)
        models.append({
            "name": model_name,
            "latest_version": version,
            "is_staged": version is not None,
        })

    return {"models": models}
