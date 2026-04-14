"""
A/B Testing Framework for Model Versions.

Cho phép chạy song song 2 phiên bản model và so sánh kết quả
trước khi promote model mới lên production.

Cách hoạt động:
1. Register 2 model versions (control = production, treatment = candidate)
2.分配 traffic: 10% treatment (candidate), 90% control (production)
3. Đánh giá kết quả sau N evaluations hoặc T ngày
4. So sánh metrics: AUC, agreement rate với KDV decisions, ECE


5. Quyết định promote/reject dựa trên statistical significance

Usage:
    python scripts/ab_test.py start --control v2.3.1 --treatment v2.4.0
    python scripts/ab_test.py status --experiment-id <id>
    python scripts/ab_test.py conclude --experiment-id <id>
"""

import argparse
import json
import logging
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import get_settings
from app.training.mlflow_utils import get_mlflow_tracker

settings = get_settings()

LOG_DIR = Path(__file__).parent.parent / "logs"
LOG_DIR.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "ab_test.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger("ab_test")


class ABTestConfig:
    """Configuration for an A/B test experiment."""

    def __init__(
        self,
        experiment_id: str,
        control_version: str,
        treatment_version: str,
        treatment_traffic_pct: float = 10.0,
        min_samples: int = 100,
        max_duration_days: int = 7,
        target_metrics: Optional[list[str]] = None,
    ):
        self.experiment_id = experiment_id
        self.control_version = control_version
        self.treatment_version = treatment_version
        self.treatment_traffic_pct = treatment_traffic_pct
        self.min_samples = min_samples
        self.max_duration_days = max_duration_days
        self.target_metrics = target_metrics or [
            "auc_roc",
            "kdv_agreement_rate",
            "ece",
            "false_positive_rate",
        ]
        self.created_at = datetime.now(timezone.utc).isoformat()
        self.status = "running"


class ABTestManager:
    """
    Quản lý A/B testing giữa 2 model versions.

    Mỗi evaluation request được phân phối theo tỷ lệ traffic:
    - Control (model hiện tại): (100 - treatment_traffic_pct)%
    - Treatment (model mới): treatment_traffic_pct%

    Kết quả được lưu lại và so sánh khi đủ samples hoặc hết thời gian.
    """

    def __init__(self):
        self.experiments: dict[str, dict] = {}
        self._load_experiments()

    def _experiments_file(self) -> Path:
        return LOG_DIR / "ab_experiments.json"

    def _load_experiments(self):
        path = self._experiments_file()
        if path.exists():
            try:
                with open(path) as f:
                    self.experiments = json.load(f)
            except Exception:
                self.experiments = {}

    def _save_experiments(self):
        with open(self._experiments_file(), "w") as f:
            json.dump(self.experiments, f, indent=2, default=str)

    # ─────────────────────────────────────────────
    # Experiment Lifecycle
    # ─────────────────────────────────────────────

    def start_experiment(
        self,
        control_version: str,
        treatment_version: str,
        treatment_traffic_pct: float = 10.0,
        min_samples: int = 100,
        max_duration_days: int = 7,
    ) -> dict:
        """Start a new A/B test experiment."""
        experiment_id = f"ab_{uuid.uuid4().hex[:8]}"

        config = ABTestConfig(
            experiment_id=experiment_id,
            control_version=control_version,
            treatment_version=treatment_version,
            treatment_traffic_pct=treatment_traffic_pct,
            min_samples=min_samples,
            max_duration_days=max_duration_days,
        )

        experiment = {
            "experiment_id": experiment_id,
            "config": {
                "control_version": control_version,
                "treatment_version": treatment_version,
                "treatment_traffic_pct": treatment_traffic_pct,
                "min_samples": min_samples,
                "max_duration_days": max_duration_days,
                "created_at": config.created_at,
                "status": "running",
            },
            "results": {
                "control": {"samples": 0, "metrics": {}},
                "treatment": {"samples": 0, "metrics": {}},
            },
            "decisions": {
                "control": [],
                "treatment": [],
            },
        }

        self.experiments[experiment_id] = experiment
        self._save_experiments()

        # Register experiment in MLflow
        try:
            tracker = get_mlflow_tracker()
            if tracker.is_available:
                tracker.log_ab_experiment(
                    experiment_id=experiment_id,
                    control_version=control_version,
                    treatment_version=treatment_version,
                    traffic_pct=treatment_traffic_pct,
                )
        except Exception as e:
            logger.warning(f"MLflow experiment logging failed: {e}")

        logger.info(f"Started A/B experiment: {experiment_id}")
        logger.info(f"  Control: {control_version}, Treatment: {treatment_version}")
        logger.info(f"  Traffic: {treatment_traffic_pct}% treatment")
        logger.info(f"  Min samples: {min_samples}, Max duration: {max_duration_days}d")

        return experiment

    def get_experiment(self, experiment_id: str) -> Optional[dict]:
        """Get experiment by ID."""
        return self.experiments.get(experiment_id)

    def list_experiments(self) -> list[dict]:
        """List all experiments."""
        return list(self.experiments.values())

    def record_evaluation(
        self,
        experiment_id: str,
        arm: str,
        campaign_id: int,
        prediction: dict,
        kdv_decision: Optional[str] = None,
    ):
        """
        Record an evaluation result for an experiment arm.

        Args:
            experiment_id: A/B experiment ID
            arm: 'control' or 'treatment'
            campaign_id: Campaign being evaluated
            prediction: Model prediction dict
            kdv_decision: Final KDV decision (for agreement rate calculation)
        """
        if experiment_id not in self.experiments:
            logger.warning(f"Experiment {experiment_id} not found")
            return

        exp = self.experiments[experiment_id]
        if exp["config"]["status"] != "running":
            logger.warning(f"Experiment {experiment_id} is not running")
            return

        if arm not in ("control", "treatment"):
            logger.warning(f"Invalid arm: {arm}")
            return

        exp["results"][arm]["samples"] += 1
        exp["results"][arm]["metrics"]["total_evaluations"] = exp["results"][arm]["samples"]

        # Record decision for agreement rate calculation
        if kdv_decision:
            exp["decisions"][arm].append({
                "campaign_id": campaign_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "kdv_decision": kdv_decision,
                "ml_recommendation": prediction.get("recommended_action"),
                "trust_score": prediction.get("trust_score", {}).get("calibrated_probability"),
                "risk_level": prediction.get("risk_assessment", {}).get("overall_risk_level"),
            })

        # Update metrics incrementally
        self._update_metrics(exp, arm)

        # Check if experiment should conclude
        self._check_auto_conclude(experiment_id)

        self._save_experiments()

    def _update_metrics(self, experiment: dict, arm: str):
        """Update metrics incrementally for an arm."""
        results = experiment["results"][arm]
        decisions = experiment["decisions"][arm]

        total = results["metrics"].get("total_evaluations", 0)
        if total == 0:
            return

        # KDV agreement rate
        if decisions:
            agreed = sum(
                1 for d in decisions
                if d.get("ml_recommendation") == d.get("kdv_decision")
            )
            results["metrics"]["kdv_agreement_rate"] = round(agreed / len(decisions), 4)
            results["metrics"]["agreement_samples"] = len(decisions)

        # Average scores
        scores = [d["trust_score"] for d in decisions if d.get("trust_score") is not None]
        if scores:
            results["metrics"]["avg_trust_score"] = round(sum(scores) / len(scores), 4)

    def _check_auto_conclude(self, experiment_id: str):
        """Check if experiment should auto-conclude."""
        exp = self.experiments[experiment_id]
        config = exp["config"]

        # Check sample threshold
        treatment_samples = exp["results"]["treatment"]["samples"]
        if treatment_samples >= config["min_samples"]:
            logger.info(f"Experiment {experiment_id}: Min samples reached ({treatment_samples})")
            # Don't auto-conclude, just log
            return

        # Check duration
        created = datetime.fromisoformat(config["created_at"].replace("Z", "+00:00"))
        days_running = (datetime.now(timezone.utc) - created).days
        if days_running >= config["max_duration_days"]:
            logger.info(f"Experiment {experiment_id}: Max duration reached ({days_running}d")
            # Don't auto-conclude, just log

    def conclude_experiment(self, experiment_id: str, force: bool = False) -> dict:
        """
        Conclude an experiment and compute final results.

        Returns statistical comparison between control and treatment.
        """
        if experiment_id not in self.experiments:
            raise ValueError(f"Experiment {experiment_id} not found")

        exp = self.experiments[experiment_id]
        config = exp["config"]

        if config["status"] != "running" and not force:
            raise ValueError(f"Experiment {experiment_id} is not running")

        logger.info(f"Concluding experiment: {experiment_id}")

        # Compute final comparison
        comparison = self._compute_comparison(exp)

        # Determine winner
        winner = self._determine_winner(comparison)

        result = {
            "experiment_id": experiment_id,
            "concluded_at": datetime.now(timezone.utc).isoformat(),
            "control_version": config["control_version"],
            "treatment_version": config["treatment_version"],
            "total_samples": {
                "control": exp["results"]["control"]["samples"],
                "treatment": exp["results"]["treatment"]["samples"],
            },
            "comparison": comparison,
            "winner": winner,
            "recommendation": self._get_recommendation(winner, comparison),
        }

        # Update experiment
        exp["config"]["status"] = "concluded"
        exp["config"]["concluded_at"] = result["concluded_at"]
        exp["conclusion"] = result
        self._save_experiments()

        # Log to MLflow
        try:
            tracker = get_mlflow_tracker()
            if tracker.is_available:
                tracker.log_ab_conclusion(experiment_id, result)
        except Exception as e:
            logger.warning(f"MLflow logging failed: {e}")

        logger.info(f"  Winner: {winner or 'no clear winner'}")
        logger.info(f"  Recommendation: {result['recommendation']}")

        return result

    def _compute_comparison(self, experiment: dict) -> dict:
        """Compute statistical comparison between arms."""
        control = experiment["results"]["control"]["metrics"]
        treatment = experiment["results"]["treatment"]["metrics"]

        comparison = {}
        metrics = ["kdv_agreement_rate", "auc_roc", "ece", "avg_trust_score", "total_evaluations"]

        for metric in metrics:
            ctrl_val = control.get(metric)
            treat_val = treatment.get(metric)

            if ctrl_val is not None and treat_val is not None:
                comparison[metric] = {
                    "control": round(ctrl_val, 6),
                    "treatment": round(treat_val, 6),
                    "diff": round(treat_val - ctrl_val, 6),
                    "pct_change": round((treat_val - ctrl_val) / ctrl_val * 100, 2)
                    if ctrl_val != 0 else None,
                }

        # Additional metrics
        comparison["samples"] = {
            "control": experiment["results"]["control"]["samples"],
            "treatment": experiment["results"]["treatment"]["samples"],
        }

        return comparison

    def _determine_winner(self, comparison: dict) -> Optional[str]:
        """
        Determine winning arm based on metrics.

        Priority:
        1. KDV agreement rate (most important)
        2. ECE (calibration quality)
        3. AUC-ROC
        """
        kdv = comparison.get("kdv_agreement_rate", {})
        if not kdv:
            return None

        ctrl_agree = kdv.get("control", 0)
        treat_agree = kdv.get("treatment", 0)
        agree_diff = treat_agree - ctrl_agree

        # Need at least 2% improvement to declare winner
        if abs(agree_diff) < 0.02:
            return None

        return "treatment" if agree_diff > 0 else "control"

    def _get_recommendation(self, winner: Optional[str], comparison: dict) -> str:
        """Get promotion recommendation based on results."""
        if winner == "treatment":
            return (
                "PROMOTE treatment model. "
                f"KDV agreement rate improved by {comparison.get('kdv_agreement_rate', {}).get('diff', 0):.2%}. "
                "Statistical significance requires manual review."
            )
        elif winner == "control":
            return (
                "REJECT treatment model. "
                f"KDV agreement rate decreased by {abs(comparison.get('kdv_agreement_rate', {}).get('diff', 0)):.2%}. "
                "Keep current production model."
            )
        else:
            return (
                "INCONCLUSIVE. Difference in KDV agreement rate is within noise threshold (<2%). "
                "Consider extending experiment duration or collecting more samples."
            )

    def promote_winner(self, experiment_id: str):
        """Promote the winning model to production."""
        if experiment_id not in self.experiments:
            raise ValueError(f"Experiment {experiment_id} not found")

        exp = self.experiments[experiment_id]
        if exp["config"]["status"] != "concluded":
            raise ValueError("Experiment must be concluded before promoting")

        conclusion = exp.get("conclusion", {})
        winner = conclusion.get("winner")

        if not winner:
            raise ValueError("No clear winner to promote")

        treatment_version = exp["config"]["treatment_version"]
        import shutil
        from pathlib import Path

        production_path = Path(settings.campaign_model_path)
        treatment_path = production_path.parent / f"campaign_trust_{treatment_version}"

        if not treatment_path.exists():
            raise FileNotFoundError(f"Treatment model not found: {treatment_path}")

        # Backup current production
        backup_path = production_path.parent / f"campaign_trust_backup_{datetime.now().strftime('%Y%m%d')}"
        if production_path.exists():
            shutil.copytree(production_path, backup_path)

        # Replace with treatment
        shutil.rmtree(production_path, ignore_errors=True)
        shutil.copytree(treatment_path, production_path)

        # Update metadata
        import json as _json
        metadata_path = production_path / "metadata.json"
        metadata = {}
        if metadata_path.exists():
            with open(metadata_path) as f:
                metadata = _json.load(f)

        metadata["production_version"] = treatment_version
        metadata["promoted_via"] = "ab_test"
        metadata["experiment_id"] = experiment_id
        metadata["promoted_at"] = datetime.now(timezone.utc).isoformat()

        with open(metadata_path, "w") as f:
            _json.dump(metadata, f, indent=2)

        logger.info(f"Promoted {treatment_version} to production via A/B test {experiment_id}")

        return treatment_version


def main():
    parser = argparse.ArgumentParser(description="A/B Testing Framework")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # start
    start_parser = subparsers.add_parser("start", help="Start new A/B experiment")
    start_parser.add_argument("--control", required=True, help="Control model version")
    start_parser.add_argument("--treatment", required=True, help="Treatment model version")
    start_parser.add_argument("--traffic", type=float, default=10.0, help="Treatment traffic %%")
    start_parser.add_argument("--min-samples", type=int, default=100, help="Min samples to conclude")
    start_parser.add_argument("--max-days", type=int, default=7, help="Max duration in days")

    # status
    status_parser = subparsers.add_parser("status", help="Show experiment status")
    status_parser.add_argument("--id", dest="experiment_id", help="Experiment ID")

    # conclude
    conclude_parser = subparsers.add_parser("conclude", help="Conclude an experiment")
    conclude_parser.add_argument("--id", dest="experiment_id", required=True, help="Experiment ID")
    conclude_parser.add_argument("--force", action="store_true", help="Force conclude even if running")

    # promote
    promote_parser = subparsers.add_parser("promote", help="Promote winner to production")
    promote_parser.add_argument("--id", dest="experiment_id", required=True, help="Experiment ID")

    args = parser.parse_args()
    manager = ABTestManager()

    if args.command == "start":
        exp = manager.start_experiment(
            control_version=args.control,
            treatment_version=args.treatment,
            treatment_traffic_pct=args.traffic,
            min_samples=args.min_samples,
            max_duration_days=args.max_days,
        )
        print(json.dumps(exp, indent=2, default=str))

    elif args.command == "status":
        if args.experiment_id:
            exp = manager.get_experiment(args.experiment_id)
            if exp:
                print(json.dumps(exp, indent=2, default=str))
            else:
                print(f"Experiment {args.experiment_id} not found")
        else:
            exps = manager.list_experiments()
            for e in exps:
                print(f"  {e['experiment_id']} | {e['config']['status']} | "
                      f"Ctrl: {e['config']['control_version']} | "
                      f"Treat: {e['config']['treatment_version']} | "
                      f"Samples: {e['results']['control']['samples']}/{e['results']['treatment']['samples']}")

    elif args.command == "conclude":
        result = manager.conclude_experiment(args.experiment_id, force=args.force)
        print(json.dumps(result, indent=2, default=str))

    elif args.command == "promote":
        version = manager.promote_winner(args.experiment_id)
        print(f"Promoted {version} to production")


if __name__ == "__main__":
    main()
