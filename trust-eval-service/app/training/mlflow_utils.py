"""
MLflow Utilities - Tracking, logging và model registry.

Triển khai theo SPEC:
- MLflow Tracking Server
- Experiment: campaign-trust-evaluation
- Model Registry: campaign-trust-models
- Log: parameters, metrics, model artifacts
"""

import logging
import os
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional, Any
import json

logger = logging.getLogger("trust_eval_service")


@dataclass
class MLflowConfig:
    """MLflow configuration."""
    tracking_uri: str = "http://localhost:5000"
    experiment_name: str = "campaign-trust-evaluation"
    model_registry: str = "campaign-trust-models"
    artifact_root: str = "./mlruns"


@dataclass
class RunInfo:
    """Thông tin về một MLflow run."""
    run_id: str
    experiment_id: str
    run_name: str
    status: str
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    artifact_uri: Optional[str] = None


class MLflowTracker:
    """
    Wrapper cho MLflow tracking.

    Features:
    - Start/end runs
    - Log parameters, metrics
    - Log artifacts (model files, feature importance)
    - Register models
    """

    _instance = None
    _initialized = False

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, config: Optional[MLflowConfig] = None):
        if self._initialized:
            return

        self.config = config or MLflowConfig()
        self._client = None
        self._experiment_id = None
        self._active_run = None

        self._try_initialize()
        self._initialized = True

    def _try_initialize(self):
        """Thử khởi tạo MLflow client."""
        try:
            import mlflow
            mlflow.set_tracking_uri(self.config.tracking_uri)
            mlflow.set_experiment(self.config.experiment_name)
            self._client = mlflow.tracking.MlflowClient()
            logger.info(f"MLflow initialized: {self.config.tracking_uri}")
        except ImportError:
            logger.warning("MLflow not available, tracking disabled")
            self._client = None
        except Exception as e:
            logger.warning(f"MLflow initialization failed: {e}")
            self._client = None

    @property
    def is_available(self) -> bool:
        """Check if MLflow is available."""
        return self._client is not None

    def start_run(
        self,
        run_name: Optional[str] = None,
        tags: Optional[dict] = None,
    ) -> Optional[str]:
        """
        Bắt đầu một MLflow run.

        Returns:
            run_id nếu thành công, None nếu MLflow không khả dụng
        """
        if not self.is_available:
            return None

        try:
            import mlflow

            # Set experiment
            mlflow.set_experiment(self.config.experiment_name)

            # Start run
            run = mlflow.start_run(
                run_name=run_name,
                tags=tags,
            )
            self._active_run = run
            logger.info(f"MLflow run started: {run.info.run_id}")
            return run.info.run_id

        except Exception as e:
            logger.error(f"Failed to start MLflow run: {e}")
            return None

    def end_run(
        self,
        status: str = "FINISHED",
        run_id: Optional[str] = None,
    ):
        """Kết thúc MLflow run."""
        if not self.is_available:
            return

        try:
            import mlflow
            mlflow.end_run(status=status)
            self._active_run = None
            logger.info(f"MLflow run ended: {status}")
        except Exception as e:
            logger.error(f"Failed to end MLflow run: {e}")

    def log_param(self, key: str, value: Any):
        """Log một parameter."""
        if not self.is_available:
            return

        try:
            import mlflow
            mlflow.log_param(key, value)
        except Exception as e:
            logger.warning(f"Failed to log param {key}: {e}")

    def log_params(self, params: dict):
        """Log nhiều parameters."""
        if not self.is_available:
            return

        try:
            import mlflow
            mlflow.log_params(params)
        except Exception as e:
            logger.warning(f"Failed to log params: {e}")

    def log_metric(self, key: str, value: float):
        """Log một metric."""
        if not self.is_available:
            return

        try:
            import mlflow
            mlflow.log_metric(key, value)
        except Exception as e:
            logger.warning(f"Failed to log metric {key}: {e}")

    def log_metrics(self, metrics: dict):
        """Log nhiều metrics."""
        if not self.is_available:
            return

        try:
            import mlflow
            mlflow.log_metrics(metrics)
        except Exception as e:
            logger.warning(f"Failed to log metrics: {e}")

    def log_artifact(self, local_path: str, artifact_path: Optional[str] = None):
        """Log một artifact (file)."""
        if not self.is_available:
            return

        try:
            import mlflow
            mlflow.log_artifact(local_path, artifact_path)
            logger.info(f"Logged artifact: {local_path}")
        except Exception as e:
            logger.warning(f"Failed to log artifact {local_path}: {e}")

    def log_model_artifact(
        self,
        model_path: str,
        model_type: str,
        params: dict,
        metrics: dict,
    ):
        """
        Log model files as artifact.

        Tự động log tất cả files trong model_path.
        """
        if not self.is_available:
            return

        try:
            import mlflow

            # Log params and metrics
            mlflow.log_params(params)
            mlflow.log_metrics(metrics)

            # Log all files in model directory
            if os.path.isdir(model_path):
                mlflow.log_artifacts(model_path, artifact_path="model")
                logger.info(f"Logged model artifact directory: {model_path}")
            elif os.path.isfile(model_path):
                mlflow.log_artifact(model_path)
                logger.info(f"Logged model artifact: {model_path}")

        except Exception as e:
            logger.warning(f"Failed to log model artifacts: {e}")

    def register_model(
        self,
        model_path: str,
        model_name: str,
        model_version: Optional[str] = None,
        description: Optional[str] = None,
        tags: Optional[dict] = None,
        run_id: Optional[str] = None,
    ) -> Optional[str]:
        """
        Register model vào MLflow Model Registry.

        Returns:
            model_version URI nếu thành công
        """
        if not self.is_available:
            return None

        try:
            import mlflow
            from mlflow.tracking import MlflowClient

            client = MlflowClient()

            # Create registered model if not exists
            try:
                client.create_registered_model(model_name)
                logger.info(f"Created registered model: {model_name}")
            except Exception:
                # Model already exists
                pass

            # Create model version
            model_uri = f"runs:/{run_id}/model" if run_id else model_path

            mv = client.create_model_version(
                name=model_name,
                source=model_uri,
                run_id=run_id,
                description=description,
                tags=tags,
            )

            logger.info(
                f"Registered model: {model_name} v{mv.version} "
                f"(run_id={run_id})"
            )
            return f"models:/{model_name}/{mv.version}"

        except Exception as e:
            logger.error(f"Failed to register model: {e}")
            return None

    def get_latest_model_version(self, model_name: str) -> Optional[int]:
        """Lấy version mới nhất của registered model."""
        if not self.is_available:
            return None

        try:
            from mlflow.tracking import MlflowClient
            client = MlflowClient()
            versions = client.get_latest_versions(model_name)
            if versions:
                return int(versions[0].version)
            return None
        except Exception as e:
            logger.warning(f"Failed to get latest model version: {e}")
            return None

    def transition_model_stage(
        self,
        model_name: str,
        version: int,
        stage: str,
    ) -> bool:
        """
        Chuyển model sang stage khác.

        Stages: Staging, Production, Archived
        """
        if not self.is_available:
            return False

        try:
            from mlflow.tracking import MlflowClient
            client = MlflowClient()
            client.transition_model_version_stage(
                name=model_name,
                version=version,
                stage=stage,
            )
            logger.info(f"Model {model_name} v{version} → {stage}")
            return True
        except Exception as e:
            logger.error(f"Failed to transition model stage: {e}")
            return False

    def get_run_history(
        self,
        experiment_name: Optional[str] = None,
        max_results: int = 50,
    ) -> list[dict]:
        """Lấy lịch sử các runs."""
        if not self.is_available:
            return []

        try:
            import mlflow

            exp_name = experiment_name or self.config.experiment_name
            exp = mlflow.get_experiment_by_name(exp_name)
            if exp is None:
                return []

            from mlflow.tracking import MlflowClient
            client = MlflowClient()

            runs = client.search_runs(
                experiment_ids=[exp.experiment_id],
                max_results=max_results,
                order_by=["start_time DESC"],
            )

            return [
                {
                    "run_id": r.info.run_id,
                    "run_name": r.info.run_name,
                    "status": r.info.status,
                    "start_time": r.info.start_time,
                    "end_time": r.info.end_time,
                    "metrics": {k: v for k, v in r.data.metrics.items()},
                    "params": {k: v for k, v in r.data.params.items()},
                }
                for r in runs
            ]
        except Exception as e:
            logger.warning(f"Failed to get run history: {e}")
            return []

    def log_training_run(
        self,
        model_type: str,
        params: dict,
        train_metrics: dict,
        val_metrics: dict,
        feature_importance: list[dict],
        model_path: str,
        calibration_result: Optional[dict] = None,
    ) -> Optional[str]:
        """
        Log toàn bộ training run.

        Args:
            model_type: "campaign_trust" hoặc "volunteer_trust"
            params: Hyperparameters
            train_metrics: Training set metrics
            val_metrics: Validation set metrics
            feature_importance: Feature importance list
            model_path: Đường dẫn model file
            calibration_result: Kết quả calibration

        Returns:
            run_id
        """
        run_name = f"{model_type}_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M')}"
        tags = {
            "model_type": model_type,
            "environment": os.getenv("APP_ENV", "development"),
        }

        run_id = self.start_run(run_name=run_name, tags=tags)
        if run_id is None:
            return None

        try:
            # Log params
            self.log_params(params)

            # Log metrics
            for prefix, metrics in [("train", train_metrics), ("val", val_metrics)]:
                for key, value in metrics.items():
                    self.log_metric(f"{prefix}_{key}", value)

            # Log calibration
            if calibration_result:
                for key, value in calibration_result.items():
                    self.log_metric(f"calibration_{key}", value)

            # Log feature importance as artifact
            if feature_importance:
                fi_path = os.path.join(self.config.artifact_root, "feature_importance.json")
                os.makedirs(os.path.dirname(fi_path), exist_ok=True)
                with open(fi_path, "w") as f:
                    json.dump(feature_importance, f, indent=2)
                self.log_artifact(fi_path)

            # Log model
            self.log_model_artifact(
                model_path=model_path,
                model_type=model_type,
                params=params,
                metrics={**train_metrics, **val_metrics},
            )

            self.end_run(status="FINISHED")
            logger.info(f"Training run logged: {run_id}")
            return run_id

        except Exception as e:
            logger.error(f"Failed to log training run: {e}")
            self.end_run(status="FAILED")
            return None


# Global instance
_mlflow_tracker: Optional[MLflowTracker] = None


def get_mlflow_tracker() -> MLflowTracker:
    """Lấy global MLflowTracker instance."""
    global _mlflow_tracker
    if _mlflow_tracker is None:
        _mlflow_tracker = MLflowTracker()
    return _mlflow_tracker
