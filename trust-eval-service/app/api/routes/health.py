import os
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException
from app.config import get_settings
from app.core.database import test_connection

router = APIRouter()
settings = get_settings()


@router.get("/health")
async def health_check():
    db_result = test_connection()

    mlflow_status = {"available": False, "error": "Not configured"}
    try:
        import mlflow
        client = mlflow.tracking.MlflowClient(settings.mlflow_tracking_uri)
        client.list_registered_models()
        mlflow_status = {"available": True}
    except Exception as e:
        mlflow_status = {"available": False, "error": str(e)}

    models_status = {}
    for model_name, model_path in [
        ("campaign_trust", settings.campaign_model_path),
        ("volunteer_trust", settings.volunteer_model_path),
        ("anomaly", settings.anomaly_model_path),
    ]:
        models_status[model_name] = os.path.exists(model_path)

    all_healthy = db_result["success"] and mlflow_status["available"]
    status = "healthy" if all_healthy else "degraded"

    return {
        "status": status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "database": db_result,
        "mlflow": mlflow_status,
        "models_loaded": models_status,
        "version": "0.1.0",
    }


@router.get("/model/info")
async def model_info():
    models_info = {}
    for model_name, model_path in [
        ("campaign_model_version", settings.campaign_model_path),
        ("volunteer_model_version", settings.volunteer_model_path),
        ("anomaly_model_version", settings.anomaly_model_path),
    ]:
        metadata_path = os.path.join(model_path, "metadata.json")
        if os.path.exists(metadata_path):
            import json
            with open(metadata_path, "r", encoding="utf-8") as f:
                models_info[model_name] = json.load(f)
        else:
            models_info[model_name] = {"status": "not_loaded", "path": model_path}

    return {
        "campaign_model_version": models_info.get("campaign_model_version", {}).get("version", "not_loaded"),
        "campaign_training_date": models_info.get("campaign_model_version", {}).get("training_date"),
        "campaign_training_samples": models_info.get("campaign_model_version", {}).get("training_samples"),
        "volunteer_model_version": models_info.get("volunteer_model_version", {}).get("version", "not_loaded"),
        "anomaly_model_version": models_info.get("anomaly_model_version", {}).get("version", "not_loaded"),
        "mlflow_tracking_uri": settings.mlflow_tracking_uri,
    }


@router.get("/model/feature-importance")
async def feature_importance():
    campaign_importance_path = os.path.join(settings.campaign_model_path, "feature_importance.json")
    if os.path.exists(campaign_importance_path):
        import json
        with open(campaign_importance_path, "r", encoding="utf-8") as f:
            campaign_importance = json.load(f)
    else:
        campaign_importance = None

    return {
        "campaign_feature_importance": campaign_importance,
        "note": "Feature importance available after model training (Phase 3)",
    }
