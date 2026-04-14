"""
Scheduled Model Retraining Script.

Chạy định kỳ (tuần/tháng) để retrain model với dữ liệu mới.
Dùng cron job hoặc Laravel scheduler gọi qua HTTP.

Cách dùng:
    # Chạy thủ công:
    python scripts/scheduled_retrain.py

    # Cron job (chạy Chủ Nhật hàng tuần lúc 2h sáng):
    0 2 * * 0 cd /app && python scripts/scheduled_retrain.py --mode weekly >> /logs/retrain.log 2>&1

    # Cron job (chạy ngày 1 hàng tháng lúc 3h sáng):
    0 3 1 * * cd /app && python scripts/scheduled_retrain.py --mode monthly >> /logs/retrain.log 2>&1
"""

import argparse
import json
import logging
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# Add parent dir to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import get_settings
from app.training.pipeline import TrainingPipeline, PipelineConfig

settings = get_settings()

# Configure logging
LOG_DIR = Path(__file__).parent.parent / "logs"
LOG_DIR.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "retrain.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger("scheduled_retrain")


class ScheduledRetrainingManager:
    """
    Quản lý scheduled retraining với:
    - Check điều kiện trước khi train
    - So sánh model mới với model hiện tại
    - Auto-promote nếu model mới tốt hơn
    - Gửi notification khi hoàn thành
    """

    def __init__(self, mode: str = "weekly"):
        self.mode = mode
        self.timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        self.report: dict = {
            "run_id": f"retrain_{self.timestamp}",
            "mode": mode,
            "started_at": datetime.now(timezone.utc).isoformat(),
            "status": "running",
        }

    def run(self) -> dict:
        """Execute scheduled retraining pipeline."""
        logger.info("=" * 60)
        logger.info(f"Scheduled Retraining Started - Mode: {self.mode}")
        logger.info(f"Run ID: {self.report['run_id']}")
        logger.info("=" * 60)

        try:
            # Step 1: Check preconditions
            if not self._check_preconditions():
                self.report["status"] = "skipped"
                self.report["skipped_reason"] = "Preconditions not met"
                self._save_report()
                return self.report

            # Step 2: Check if enough new data since last training
            if not self._has_enough_new_data():
                self.report["status"] = "skipped"
                self.report["skipped_reason"] = "Not enough new labeled data since last training"
                self._save_report()
                return self.report

            # Step 3: Run training
            training_result = self._run_training()

            if not training_result["success"]:
                self.report["status"] = "failed"
                self.report["error"] = training_result.get("error")
                self._save_report()
                return self.report

            # Step 4: Evaluate new model
            eval_result = self._evaluate_new_model(training_result)

            # Step 5: Compare with current model
            promote = self._should_promote(eval_result)

            if promote:
                self._promote_new_model(training_result)
                self.report["action"] = "promoted"
            else:
                self.report["action"] = "rejected"
                logger.info("New model NOT promoted - performance not significantly better")

            self.report["status"] = "completed"
            self.report["completed_at"] = datetime.now(timezone.utc).isoformat()
            self.report["training_result"] = training_result
            self.report["evaluation_result"] = eval_result

            # Step 6: Save training label for future comparison
            self._save_training_record(training_result, eval_result)

            self._save_report()
            self._send_notification()

            logger.info("=" * 60)
            logger.info(f"Scheduled Retraining COMPLETED - Action: {self.report['action']}")
            logger.info("=" * 60)

            return self.report

        except Exception as e:
            logger.error(f"Scheduled retraining failed: {e}", exc_info=True)
            self.report["status"] = "failed"
            self.report["error"] = str(e)
            self._save_report()
            return self.report

    def _check_preconditions(self) -> bool:
        """Check if system is ready for retraining."""
        logger.info("[CHECK] Preconditions...")

        # Check MLflow availability
        from app.training.mlflow_utils import get_mlflow_tracker
        tracker = get_mlflow_tracker()
        if not tracker.is_available:
            logger.warning("MLflow not available - proceeding without tracking")

        # Check database connectivity
        try:
            from app.core.database import get_db_cursor
            with get_db_cursor() as cursor:
                cursor.execute("SELECT 1")
            logger.info("  - Database: OK")
        except Exception as e:
            logger.error(f"  - Database: FAILED - {e}")
            return False

        # Check output directory
        os.makedirs(settings.campaign_model_path, exist_ok=True)
        logger.info("  - Output directory: OK")

        return True

    def _has_enough_new_data(self) -> bool:
        """Check if there's enough new labeled data since last training."""
        logger.info("[CHECK] New labeled data since last training...")

        MIN_NEW_SAMPLES = 50 if self.mode == "weekly" else 20

        try:
            pipeline = TrainingPipeline()
            summary = pipeline.get_training_summary()

            total = summary.get("total", 0)
            last_record = self._get_last_training_record()

            if last_record and "training_samples" in last_record:
                # Count samples since last training (rough estimate via total)
                samples_since = total - last_record.get("total_samples", 0)
                logger.info(f"  - Total samples: {total}, New since last train: ~{samples_since}")
                if samples_since < MIN_NEW_SAMPLES:
                    logger.info(f"  - Not enough new samples (need >= {MIN_NEW_SAMPLES})")
                    return False
            else:
                logger.info(f"  - Total samples: {total}")
                if total < 100:
                    logger.info("  - Not enough total samples for training")
                    return False

            logger.info("  - OK")
            return True

        except Exception as e:
            logger.warning(f"  - Could not check new data: {e}")
            return True  # Proceed anyway

    def _run_training(self) -> dict:
        """Run the full training pipeline."""
        logger.info("[TRAIN] Starting training pipeline...")

        config = PipelineConfig(
            test_size=0.2,
            random_state=42,
            calibration_enabled=True,
            min_training_samples=100,
            mlflow_tracking_uri=settings.mlflow_tracking_uri,
            mlflow_experiment=settings.mlflow_experiment_name,
            model_registry=settings.mlflow_model_registry,
        )

        pipeline = TrainingPipeline(config=config)
        result = pipeline.run_full_pipeline()

        if result.success:
            logger.info(f"  - Training SUCCESS: {result.training_samples} samples, "
                        f"AUC={result.campaign_metrics.get('auc_roc')}")
            return {
                "success": True,
                "model_path": result.campaign_model_path,
                "training_samples": result.training_samples,
                "validation_samples": result.validation_samples,
                "metrics": result.campaign_metrics,
                "mlflow_run_id": result.mlflow_run_id,
            }
        else:
            logger.error(f"  - Training FAILED: {result.error}")
            return {"success": False, "error": result.error}

    def _evaluate_new_model(self, training_result: dict) -> dict:
        """Evaluate the newly trained model against current production model."""
        logger.info("[EVAL] Comparing new model vs current...")

        new_metrics = training_result.get("metrics", {})
        current_metrics = self._get_current_model_metrics()

        comparison = {
            "new_auc_roc": new_metrics.get("auc_roc"),
            "current_auc_roc": current_metrics.get("auc_roc"),
            "auc_improvement": None,
            "new_ece": new_metrics.get("ece"),
            "current_ece": current_metrics.get("ece"),
            "ece_improvement": None,
        }

        if comparison["current_auc_roc"] is not None:
            comparison["auc_improvement"] = (
                comparison["new_auc_roc"] - comparison["current_auc_roc"]
            )

        if comparison["current_ece"] is not None:
            comparison["ece_improvement"] = (
                comparison["current_ece"] - comparison["new_ece"]
            )  # Lower ECE is better

        logger.info(f"  - New AUC-ROC:  {comparison['new_auc_roc']}")
        logger.info(f"  - Current AUC-ROC: {comparison['current_auc_roc']}")
        logger.info(f"  - AUC Improvement: {comparison['auc_improvement']}")
        logger.info(f"  - New ECE:  {comparison['new_ece']}")
        logger.info(f"  - Current ECE: {comparison['current_ece']}")

        return comparison

    def _should_promote(self, eval_result: dict) -> bool:
        """
        Decide if new model should replace current production model.

        Promotion criteria:
        - AUC improvement >= 0.01 (1%) OR
        - ECE improvement >= 0.02 (2%, lower is better) AND AUC not worse
        """
        auc_imp = eval_result.get("auc_improvement") or 0
        ece_imp = eval_result.get("ece_improvement") or 0

        promote = auc_imp >= 0.01 or (ece_imp >= 0.02 and auc_imp >= -0.01)

        logger.info(f"  - Should promote: {promote}")
        logger.info(f"    (AUC imp={auc_imp:.4f}, ECE imp={ece_imp:.4f})")

        return promote

    def _promote_new_model(self, training_result: dict):
        """Promote new model to production."""
        logger.info("[PROMOTE] Promoting new model to production...")

        new_path = training_result.get("model_path")
        if not new_path:
            logger.error("  - No model path to promote")
            return

        # Read new model metadata
        import json as _json
        metadata_path = Path(new_path) / "metadata.json"
        if metadata_path.exists():
            with open(metadata_path) as f:
                metadata = _json.load(f)
        else:
            metadata = {}

        # Update model version
        new_version = f"campaign_trust_v{self.timestamp}"
        production_path = Path(settings.campaign_model_path)

        # Copy new model to production path
        import shutil
        if production_path.exists():
            shutil.rmtree(production_path)
        shutil.copytree(new_path, production_path)

        # Update metadata with new version
        metadata["production_version"] = new_version
        metadata["promoted_at"] = datetime.now(timezone.utc).isoformat()
        metadata["promoted_by"] = "scheduled_retrain"
        metadata["promoted_run_id"] = self.report["run_id"]

        with open(production_path / "metadata.json", "w") as f:
            _json.dump(metadata, f, indent=2)

        logger.info(f"  - Promoted to: {production_path}")
        logger.info(f"  - Version: {new_version}")

        # Register in MLflow
        try:
            from app.training.mlflow_utils import get_mlflow_tracker
            tracker = get_mlflow_tracker()
            if tracker.is_available:
                tracker.register_model(
                    model_path=str(production_path),
                    model_name="campaign-trust",
                    version=metadata,
                )
                logger.info("  - Registered in MLflow")
        except Exception as e:
            logger.warning(f"  - MLflow registration failed: {e}")

        # Trigger cache invalidation notification
        self._invalidate_model_cache()

    def _invalidate_model_cache(self):
        """Notify Laravel to invalidate evaluation cache."""
        logger.info("[CACHE] Invalidating model cache...")

        try:
            import httpx
            # Notify Laravel to reload model
            response = httpx.post(
                f"{os.environ.get('LARAVEL_API_URL', 'http://localhost:8000')}/api/trust-eval/model-reloaded",
                timeout=10,
                headers={"X-Internal-Key": os.environ.get("INTERNAL_API_KEY", "")},
            )
            logger.info(f"  - Laravel cache invalidation: {response.status_code}")
        except Exception as e:
            logger.warning(f"  - Cache invalidation failed: {e}")

    def _get_last_training_record(self) -> dict | None:
        """Read the last training record from disk."""
        record_path = LOG_DIR / "training_history.json"
        if record_path.exists():
            try:
                with open(record_path) as f:
                    history = json.load(f)
                    if history:
                        return history[-1]
            except Exception:
                pass
        return None

    def _save_training_record(self, training_result: dict, eval_result: dict):
        """Save this training run to history."""
        record_path = LOG_DIR / "training_history.json"
        history = []

        if record_path.exists():
            try:
                with open(record_path) as f:
                    history = json.load(f)
            except Exception:
                pass

        record = {
            "run_id": self.report["run_id"],
            "mode": self.mode,
            "completed_at": datetime.now(timezone.utc).isoformat(),
            "total_samples": training_result.get("training_samples", 0),
            "metrics": training_result.get("metrics", {}),
            "evaluation": eval_result,
            "action": self.report.get("action", "unknown"),
            "mlflow_run_id": training_result.get("mlflow_run_id"),
        }

        history.append(record)

        # Keep last 100 records
        history = history[-100:]

        with open(record_path, "w") as f:
            json.dump(history, f, indent=2, default=str)

    def _get_current_model_metrics(self) -> dict:
        """Get metrics of the currently deployed model."""
        metadata_path = Path(settings.campaign_model_path) / "metadata.json"
        if metadata_path.exists():
            try:
                with open(metadata_path) as f:
                    metadata = json.load(f)
                    return metadata.get("metrics", {})
            except Exception:
                pass
        return {}

    def _save_report(self):
        """Save run report to disk."""
        report_path = LOG_DIR / f"retrain_report_{self.timestamp}.json"
        with open(report_path, "w") as f:
            json.dump(self.report, f, indent=2, default=str)
        logger.info(f"Report saved: {report_path}")

    def _send_notification(self):
        """Send notification when retraining completes."""
        # Log-based notification (extend to email/Slack/Discord as needed)
        status_emoji = "✅" if self.report["status"] == "completed" else "❌"
        action = self.report.get("action", "unknown")
        logger.info(f"{status_emoji} Retraining {self.report['status']} - Action: {action}")

        # TODO: Add email/Slack webhook notification
        # Example:
        # if settings.notification_webhook:
        #     httpx.post(settings.notification_webhook, json=self.report)


def main():
    parser = argparse.ArgumentParser(description="Scheduled Model Retraining")
    parser.add_argument(
        "--mode",
        choices=["weekly", "monthly"],
        default="weekly",
        help="Retraining frequency mode",
    )
    args = parser.parse_args()

    manager = ScheduledRetrainingManager(mode=args.mode)
    result = manager.run()

    if result["status"] == "failed":
        sys.exit(1)
    elif result["status"] == "skipped":
        sys.exit(0)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
