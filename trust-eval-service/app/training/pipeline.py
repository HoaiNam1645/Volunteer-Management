"""
Training pipeline orchestration for campaign and volunteer trust models.
"""

import json
import logging
import os
import shutil
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Optional

logger = logging.getLogger("trust_eval_service")


@dataclass
class PipelineConfig:
    """Configuration for the training pipeline."""

    output_dir: str = "./models"
    mlflow_tracking_uri: str = "http://localhost:5000"
    mlflow_experiment: str = "campaign-trust-evaluation"
    model_registry: str = "campaign-trust-models"
    test_size: float = 0.2
    random_state: int = 42
    min_training_samples: int = 100
    use_smote: bool = False
    calibration_enabled: bool = True


@dataclass
class PipelineResult:
    """Output of the full training pipeline."""

    success: bool
    campaign_model_path: Optional[str] = None
    volunteer_model_path: Optional[str] = None
    calibrator_path: Optional[str] = None
    campaign_metrics: Optional[dict] = None
    volunteer_metrics: Optional[dict] = None
    training_samples: int = 0
    validation_samples: int = 0
    mlflow_run_id: Optional[str] = None
    error: Optional[str] = None
    config: Optional[PipelineConfig] = None


class TrainingPipeline:
    """Run end-to-end training for campaign and volunteer trust models."""

    def __init__(self, config: Optional[PipelineConfig] = None):
        self.config = config or PipelineConfig()
        os.makedirs(self.config.output_dir, exist_ok=True)
        self._init_components()

    def _init_components(self):
        from app.training.label_generator import LabelGenerator
        from app.training.data_prep import DataPreparator
        from app.training.trainer import LightGBMTrainer
        from app.training.calibrator import ProbabilityCalibrator
        from app.training.evaluator import ModelEvaluator
        from app.training.mlflow_utils import get_mlflow_tracker
        from app.core.database import get_db_cursor

        self.label_generator = LabelGenerator()
        self.data_prep = DataPreparator()
        self.trainer = LightGBMTrainer(output_dir=self.config.output_dir)
        self.calibrator = ProbabilityCalibrator(output_dir=self.config.output_dir)
        self.evaluator = ModelEvaluator()
        self.mlflow = get_mlflow_tracker()
        self.get_db_cursor = get_db_cursor

        if self.mlflow.is_available:
            self.mlflow.config.tracking_uri = self.config.mlflow_tracking_uri
            self.mlflow.config.experiment_name = self.config.mlflow_experiment

    def run_full_pipeline(self) -> PipelineResult:
        logger.info("=" * 60)
        logger.info("Starting training pipeline")
        logger.info("Output dir: %s", self.config.output_dir)
        logger.info("=" * 60)

        try:
            labels_data = self._generate_labels()
            if len(labels_data) < self.config.min_training_samples:
                return PipelineResult(
                    success=False,
                    error=(
                        f"Only {len(labels_data)} campaign labels found, "
                        f"minimum {self.config.min_training_samples} required"
                    ),
                    config=self.config,
                )

            campaign_features = self._extract_campaign_features()
            if not campaign_features:
                return PipelineResult(
                    success=False,
                    error="No campaign features extracted from database",
                    config=self.config,
                )

            campaign_X, campaign_y, campaign_feature_names, _ = self._prepare_campaign_data(
                labels_data, campaign_features
            )
            if len(campaign_X) < self.config.min_training_samples:
                return PipelineResult(
                    success=False,
                    error=(
                        f"Only {len(campaign_X)} campaign samples remain after feature alignment, "
                        f"minimum {self.config.min_training_samples} required"
                    ),
                    config=self.config,
                )

            (
                campaign_X_train,
                campaign_X_val,
                campaign_y_train,
                campaign_y_val,
            ) = self._split_training_data(campaign_X, campaign_y, "campaign")

            campaign_class_weights = self.data_prep.compute_class_weights(campaign_y_train)
            campaign_result = self.trainer.train_campaign_model(
                campaign_X_train,
                campaign_y_train,
                campaign_X_val,
                campaign_y_val,
                class_weights=campaign_class_weights,
                feature_names=campaign_feature_names,
            )

            campaign_calibration = self._calibrate_model(
                campaign_result.model_path,
                campaign_X_train,
                campaign_y_train,
                campaign_X_val,
                campaign_y_val,
                "campaign_trust",
            )
            campaign_metrics = self._evaluate_model(
                campaign_result.model_path,
                campaign_X_val,
                campaign_y_val,
                campaign_feature_names,
                "campaign_trust",
            )
            campaign_run_id, campaign_registry_uri = self._log_and_register_model(
                model_name="campaign-trust",
                model_result=campaign_result,
                metrics=campaign_metrics,
                calibration_result=campaign_calibration,
            )
            self._persist_model_metadata(
                model_path=campaign_result.model_path,
                model_name="campaign_trust",
                feature_names=campaign_feature_names,
                train_result=campaign_result,
                metrics=campaign_metrics,
                calibration_result=campaign_calibration,
                registry_uri=campaign_registry_uri,
                extra={
                    "label_samples": len(labels_data),
                    "train_class_distribution": {
                        "reliable": int((campaign_y_train == 1).sum()),
                        "suspicious": int((campaign_y_train == 0).sum()),
                    },
                    "validation_class_distribution": {
                        "reliable": int((campaign_y_val == 1).sum()),
                        "suspicious": int((campaign_y_val == 0).sum()),
                    },
                },
            )
            self._update_latest_path(campaign_result.model_path, "campaign_trust")

            volunteer_model_path = None
            volunteer_metrics = None
            volunteer_calibration_path = None

            volunteer_training_data = self._extract_volunteer_training_data()
            volunteer_sample_count = len(volunteer_training_data["labels"])
            volunteer_min_samples = self._min_volunteer_samples()

            if volunteer_sample_count >= volunteer_min_samples:
                volunteer_X, volunteer_y, volunteer_feature_names, _ = self.data_prep.prepare_volunteer_data(
                    volunteer_training_data["features"],
                    volunteer_training_data["labels"],
                )
                try:
                    (
                        volunteer_X_train,
                        volunteer_X_val,
                        volunteer_y_train,
                        volunteer_y_val,
                    ) = self._split_training_data(volunteer_X, volunteer_y, "volunteer")

                    volunteer_class_weights = self.data_prep.compute_class_weights(volunteer_y_train)
                    volunteer_result = self.trainer.train_volunteer_model(
                        volunteer_X_train,
                        volunteer_y_train,
                        volunteer_X_val,
                        volunteer_y_val,
                        class_weights=volunteer_class_weights,
                        feature_names=volunteer_feature_names,
                    )

                    volunteer_calibration = self._calibrate_model(
                        volunteer_result.model_path,
                        volunteer_X_train,
                        volunteer_y_train,
                        volunteer_X_val,
                        volunteer_y_val,
                        "volunteer_trust",
                    )
                    volunteer_metrics = self._evaluate_model(
                        volunteer_result.model_path,
                        volunteer_X_val,
                        volunteer_y_val,
                        volunteer_feature_names,
                        "volunteer_trust",
                    )
                    _, volunteer_registry_uri = self._log_and_register_model(
                        model_name="volunteer-trust",
                        model_result=volunteer_result,
                        metrics=volunteer_metrics,
                        calibration_result=volunteer_calibration,
                    )
                    self._persist_model_metadata(
                        model_path=volunteer_result.model_path,
                        model_name="volunteer_trust",
                        feature_names=volunteer_feature_names,
                        train_result=volunteer_result,
                        metrics=volunteer_metrics,
                        calibration_result=volunteer_calibration,
                        registry_uri=volunteer_registry_uri,
                        extra={
                            "heuristic_label_samples": volunteer_sample_count,
                            "train_class_distribution": {
                                "reliable": int((volunteer_y_train == 1).sum()),
                                "suspicious": int((volunteer_y_train == 0).sum()),
                            },
                            "validation_class_distribution": {
                                "reliable": int((volunteer_y_val == 1).sum()),
                                "suspicious": int((volunteer_y_val == 0).sum()),
                            },
                        },
                    )
                    self._update_latest_path(volunteer_result.model_path, "volunteer_trust")
                    volunteer_model_path = volunteer_result.model_path
                    volunteer_calibration_path = (
                        volunteer_calibration.calibrator_path if volunteer_calibration else None
                    )
                except ValueError as split_err:
                    logger.warning(
                        "Skipping volunteer model training due to class distribution issue: %s",
                        split_err,
                    )
            else:
                logger.warning(
                    "Skipping volunteer model training: only %s samples found, minimum %s required",
                    volunteer_sample_count,
                    volunteer_min_samples,
                )

            logger.info("=" * 60)
            logger.info("Training pipeline completed")
            logger.info("Campaign model: %s", campaign_result.model_path)
            if volunteer_model_path:
                logger.info("Volunteer model: %s", volunteer_model_path)
            logger.info("=" * 60)

            return PipelineResult(
                success=True,
                campaign_model_path=campaign_result.model_path,
                volunteer_model_path=volunteer_model_path,
                calibrator_path=campaign_calibration.calibrator_path if campaign_calibration else volunteer_calibration_path,
                campaign_metrics=campaign_metrics,
                volunteer_metrics=volunteer_metrics,
                training_samples=len(campaign_X_train),
                validation_samples=len(campaign_X_val),
                mlflow_run_id=campaign_run_id,
                config=self.config,
            )

        except Exception as e:
            logger.error("Pipeline failed: %s", e, exc_info=True)
            return PipelineResult(
                success=False,
                error=str(e),
                config=self.config,
            )

    def _generate_labels(self) -> list[dict]:
        try:
            with self.get_db_cursor() as cursor:
                self.label_generator.db_cursor = cursor
                return self.label_generator.generate_training_data()
        except Exception as e:
            logger.error("Failed to generate labels: %s", e)
            return []

    def _extract_campaign_features(self) -> list[dict]:
        from app.core.feature_extractor import CampaignFeatureExtractor
        from app.core.database import get_db_cursor

        features_data = []
        try:
            with get_db_cursor() as cursor:
                cursor.execute(
                    """
                    SELECT cd.*, u.id AS creator_user_id,
                           u.ho_ten AS creator_name, u.email AS creator_email,
                           u.anh_dai_dien AS creator_avatar,
                           u.gioi_thieu AS creator_bio,
                           u.trang_thai AS creator_status,
                           u.xac_thuc_email_luc AS creator_email_verified_at,
                           u.tao_luc AS creator_created_at,
                           u.tinh_thanh_id AS creator_province_id,
                           u.vi_do AS creator_lat, u.kinh_do AS creator_lng,
                           u.so_dien_thoai AS creator_phone,
                           u.vai_tro AS creator_role
                    FROM chien_dichs cd
                    LEFT JOIN nguoi_dungs u ON cd.nguoi_tao_id = u.id
                    WHERE cd.xoa_luc IS NULL
                    AND cd.trang_thai IN ('da_duyet', 'tu_choi', 'hoan_thanh', 'dang_dien_ra')
                    LIMIT 2000
                    """
                )
                campaigns = cursor.fetchall()

                for campaign in campaigns:
                    creator_id = campaign.get("nguoi_tao_id")
                    creator_data = {}
                    ratings = []
                    reports = []
                    reviews = []

                    if creator_id:
                        cursor.execute(
                            """
                            SELECT COUNT(*) AS total,
                                   SUM(CASE WHEN trang_thai = 'da_duyet' THEN 1 ELSE 0 END) AS approved,
                                   SUM(CASE WHEN trang_thai IN ('da_huy','yeu_cau_huy') THEN 1 ELSE 0 END) AS cancelled
                            FROM chien_dichs
                            WHERE nguoi_tao_id = %s AND xoa_luc IS NULL
                            """,
                            (creator_id,),
                        )
                        stats = cursor.fetchone()
                        total = stats["total"] or 0
                        creator_data = {
                            "id": creator_id,
                            "ho_ten": campaign.get("creator_name"),
                            "email": campaign.get("creator_email"),
                            "anh_dai_dien": campaign.get("creator_avatar"),
                            "gioi_thieu": campaign.get("creator_bio"),
                            "trang_thai": campaign.get("creator_status"),
                            "xac_thuc_email_luc": campaign.get("creator_email_verified_at"),
                            "tao_luc": campaign.get("creator_created_at"),
                            "tinh_thanh_id": campaign.get("creator_province_id"),
                            "vi_do": campaign.get("creator_lat"),
                            "kinh_do": campaign.get("creator_lng"),
                            "so_dien_thoai": campaign.get("creator_phone"),
                            "vai_tro": campaign.get("creator_role"),
                            "campaign_count": total,
                            "campaign_approval_rate": (stats["approved"] or 0) / total if total > 0 else 0.0,
                            "campaign_cancellation_rate": (stats["cancelled"] or 0) / total if total > 0 else 0.0,
                        }

                        cursor.execute(
                            """
                            SELECT dg.so_sao
                            FROM danh_gia_tnv dg
                            JOIN chien_dichs cd ON dg.chien_dich_id = cd.id
                            WHERE cd.nguoi_tao_id = %s
                            """,
                            (creator_id,),
                        )
                        ratings = cursor.fetchall()

                        cursor.execute(
                            """
                            SELECT bc.id
                            FROM bao_cao_chien_dich bc
                            JOIN chien_dichs cd ON bc.chien_dich_id = cd.id
                            WHERE cd.nguoi_tao_id = %s
                            """,
                            (creator_id,),
                        )
                        reports = cursor.fetchall()

                        cursor.execute(
                            """
                            SELECT lsk.id, lsk.hanh_dong, lsk.tao_luc AS created_at
                            FROM lich_su_kiem_duyet_chien_dichs lsk
                            WHERE lsk.chien_dich_id = %s
                            """,
                            (campaign["id"],),
                        )
                        reviews = cursor.fetchall()

                    extractor = CampaignFeatureExtractor(
                        campaign=campaign,
                        creator=creator_data,
                        registrations=[],
                        ratings=ratings,
                        reports=reports,
                        review_history=reviews,
                    )
                    features = extractor.extract()
                    features["campaign_id"] = campaign["id"]
                    features_data.append(features)

        except Exception as e:
            logger.error("Failed to extract campaign features: %s", e)

        return features_data

    def _prepare_campaign_data(
        self,
        labels_data: list[dict],
        features_data: list[dict],
    ):
        label_map = {sample["campaign_id"]: sample["label"] for sample in labels_data}
        features_list = []
        labels = []

        for feat in features_data:
            campaign_id = feat.get("campaign_id")
            if campaign_id not in label_map:
                continue

            feat_clean = {
                key: value
                for key, value in feat.items()
                if key not in ("campaign_id", "campaign_status")
            }
            feat_clean["campaign_status_code"] = self._encode_campaign_status(
                feat.get("campaign_status")
            )
            features_list.append(feat_clean)
            labels.append(label_map[campaign_id])

        X, y, feature_names, stats = self.data_prep.prepare_campaign_data(
            features_list,
            labels,
        )

        logger.info(
            "Prepared %s campaign samples. Reliable=%s, Suspicious=%s",
            len(X),
            int((y == 1).sum()),
            int((y == 0).sum()),
        )
        return X, y, feature_names, stats

    def _extract_volunteer_training_data(self) -> dict:
        from app.core.feature_extractor import VolunteerFeatureExtractor
        from app.core.database import get_db_cursor

        features_list = []
        labels = []
        sample_info = []

        try:
            with get_db_cursor() as cursor:
                cursor.execute(
                    """
                    SELECT DISTINCT u.*,
                        (SELECT COUNT(*) FROM chung_chis cc
                         WHERE cc.nguoi_dung_id = u.id) AS chung_chi_count,
                        (SELECT COUNT(*) FROM kinh_nghiems kn
                         WHERE kn.nguoi_dung_id = u.id) AS kinh_nghiem_count,
                        (SELECT COUNT(*) FROM nguoi_dung_ky_nangs knd
                         WHERE knd.nguoi_dung_id = u.id) AS ky_nang_count
                    FROM nguoi_dungs u
                    JOIN dang_ky_tham_gias dkt ON dkt.nguoi_dung_id = u.id
                    WHERE u.xoa_luc IS NULL
                    LIMIT 2000
                    """
                )
                volunteers = cursor.fetchall()

                for volunteer in volunteers:
                    volunteer_id = volunteer["id"]

                    cursor.execute(
                        """
                        SELECT dkt.id, dkt.chien_dich_id, dkt.trang_thai, dkt.dang_ky_luc AS ngay_dang_ky, dkt.huy_luc
                        FROM dang_ky_tham_gias dkt
                        WHERE dkt.nguoi_dung_id = %s
                        ORDER BY dkt.dang_ky_luc DESC
                        """,
                        (volunteer_id,),
                    )
                    registrations = cursor.fetchall()

                    cursor.execute(
                        """
                        SELECT dg.so_sao, dg.nhan_xet AS noi_dung, dg.tao_luc AS created_at
                        FROM danh_gia_tnv dg
                        WHERE dg.danh_gia_boi = %s
                        """,
                        (volunteer_id,),
                    )
                    ratings_given = cursor.fetchall()

                    cursor.execute(
                        """
                        SELECT dg.so_sao, dg.nhan_xet AS noi_dung, dg.tao_luc AS created_at
                        FROM danh_gia_tnv dg
                        WHERE dg.tinh_nguyen_vien_id = %s
                        """,
                        (volunteer_id,),
                    )
                    ratings_received = cursor.fetchall()

                    extractor = VolunteerFeatureExtractor(
                        volunteer,
                        registrations,
                        ratings_given,
                        ratings_received,
                    )
                    features = extractor.extract()

                    label_info = self._infer_volunteer_label(features)
                    if not label_info:
                        continue

                    features_list.append(features)
                    labels.append(label_info["label"])
                    sample_info.append(
                        {
                            "volunteer_id": volunteer_id,
                            "confidence": label_info["confidence"],
                            "reason": label_info["reason"],
                        }
                    )

        except Exception as e:
            logger.error("Failed to extract volunteer training data: %s", e)

        logger.info(
            "Prepared %s volunteer samples. Reliable=%s, Suspicious=%s",
            len(labels),
            sum(1 for label in labels if label == 1),
            sum(1 for label in labels if label == 0),
        )
        return {
            "features": features_list,
            "labels": labels,
            "sample_info": sample_info,
        }

    def _infer_volunteer_label(self, features: dict) -> Optional[dict]:
        registration_count = int(features.get("registration_count") or 0)
        rating_count = int(features.get("rating_received_count") or 0)
        completion_rate = float(features.get("completion_rate") or 0.0)
        cancellation_rate = float(features.get("registration_cancellation_rate") or 0.0)
        no_show_rate = float(features.get("no_show_rate") or 0.0)
        late_cancellation_count = int(features.get("late_cancellation_count") or 0)
        avg_rating_received = features.get("avg_rating_received")
        profile_completeness = float(features.get("profile_completeness_score") or 0.0)

        if registration_count < 3 and rating_count < 2:
            return None

        reliable = (
            registration_count >= 3
            and completion_rate >= 0.7
            and cancellation_rate <= 0.15
            and no_show_rate <= 0.1
            and profile_completeness >= 0.45
            and (avg_rating_received is None or avg_rating_received >= 4.0)
        )
        suspicious = (
            (registration_count >= 3 and completion_rate <= 0.35)
            or cancellation_rate >= 0.35
            or no_show_rate >= 0.25
            or late_cancellation_count >= 2
            or (
                avg_rating_received is not None
                and rating_count >= 2
                and avg_rating_received < 3.0
            )
        )

        if reliable == suspicious:
            return None

        confidence = "high" if registration_count >= 8 or rating_count >= 4 else "medium"
        reason = (
            "high completion and low cancellation"
            if reliable
            else "high cancellation or no-show behavior"
        )

        return {
            "label": 1 if reliable else 0,
            "confidence": confidence,
            "reason": reason,
        }

    def _split_training_data(self, X, y, dataset_name: str):
        unique_labels = set(y.tolist())
        if len(unique_labels) < 2:
            raise ValueError(f"{dataset_name} dataset has only one class: {sorted(unique_labels)}")

        label_counts = {int(label): int((y == label).sum()) for label in unique_labels}
        if min(label_counts.values()) < 2:
            raise ValueError(
                f"{dataset_name} dataset has too few samples in at least one class: {label_counts}"
            )

        X_train, X_val, y_train, y_val = self.data_prep.train_val_split(
            X,
            y,
            test_size=self.config.test_size,
            random_state=self.config.random_state,
        )

        train_labels = set(y_train.tolist())
        val_labels = set(y_val.tolist())
        if len(train_labels) < 2 or len(val_labels) < 2:
            raise ValueError(
                f"{dataset_name} split is not stratified enough: "
                f"train={sorted(train_labels)}, val={sorted(val_labels)}"
            )

        logger.info(
            "%s split: train=%s, val=%s",
            dataset_name.capitalize(),
            len(X_train),
            len(X_val),
        )
        return X_train, X_val, y_train, y_val

    def _calibrate_model(
        self,
        model_path: str,
        X_train,
        y_train,
        X_val,
        y_val,
        model_type: str,
    ):
        if not self.config.calibration_enabled:
            return None

        try:
            import lightgbm as lgb

            model_file = os.path.join(model_path, "model.txt")
            if not os.path.exists(model_file):
                logger.warning("Model file not found for calibration: %s", model_file)
                return None

            model = lgb.Booster(model_file=model_file)
            _, calibration_result = self.calibrator.calibrate(
                model=model,
                X_train=X_train,
                y_train=y_train,
                X_val=X_val,
                y_val=y_val,
                model_type=model_type,
            )

            if calibration_result and calibration_result.calibrator_path:
                attached_path = self._attach_file_to_model_dir(
                    calibration_result.calibrator_path,
                    model_path,
                )
                if attached_path:
                    calibration_result.calibrator_path = attached_path

            return calibration_result

        except Exception as e:
            logger.error("Calibration failed for %s: %s", model_type, e)
            return None

    def _attach_file_to_model_dir(self, source_path: str, model_path: str) -> Optional[str]:
        if not source_path or not os.path.exists(source_path):
            return None

        target_path = os.path.join(model_path, os.path.basename(source_path))
        if os.path.abspath(source_path) == os.path.abspath(target_path):
            return target_path

        shutil.copy2(source_path, target_path)
        return target_path

    def _log_and_register_model(self, model_name: str, model_result, metrics: dict, calibration_result=None):
        run_id = None
        registry_uri = None

        calibration_dict = None
        if calibration_result:
            calibration_dict = {
                "ece_before": calibration_result.ece_before,
                "ece_after": calibration_result.ece_after,
                "calibration_improvement": calibration_result.calibration_improvement,
            }

        if self.mlflow.is_available:
            run_id = self.mlflow.log_training_run(
                model_type=model_result.model_type,
                params=model_result.params,
                train_metrics={},
                val_metrics=metrics or {},
                feature_importance=model_result.feature_importance,
                model_path=model_result.model_path,
                calibration_result=calibration_dict,
            )
            registry_uri = self.mlflow.register_model(
                model_path=model_result.model_path,
                model_name=model_name,
                description=f"{model_result.model_type} trained on {model_result.training_date}",
                tags={
                    "model_type": model_result.model_type,
                    "training_samples": str(model_result.training_samples),
                    "validation_samples": str(model_result.validation_samples),
                },
                run_id=run_id,
            )

        return run_id, registry_uri

    def _persist_model_metadata(
        self,
        model_path: str,
        model_name: str,
        feature_names: list[str],
        train_result,
        metrics: Optional[dict],
        calibration_result=None,
        registry_uri: Optional[str] = None,
        extra: Optional[dict] = None,
    ) -> None:
        metadata = {
            "model_name": model_name,
            "model_type": train_result.model_type,
            "training_date": train_result.training_date,
            "training_samples": train_result.training_samples,
            "validation_samples": train_result.validation_samples,
            "params": train_result.params,
            "metrics": metrics or {},
            "feature_names": feature_names,
            "calibration": (
                {
                    "method": calibration_result.calibration_method,
                    "ece_before": calibration_result.ece_before,
                    "ece_after": calibration_result.ece_after,
                    "improvement": calibration_result.calibration_improvement,
                    "calibrator_path": calibration_result.calibrator_path,
                }
                if calibration_result
                else None
            ),
            "registered_model_uri": registry_uri,
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }
        if extra:
            metadata.update(extra)

        feature_importance_path = os.path.join(model_path, "feature_importance.json")
        metadata_path = os.path.join(model_path, "metadata.json")

        with open(feature_importance_path, "w", encoding="utf-8") as f:
            json.dump(train_result.feature_importance, f, indent=2, ensure_ascii=False)

        with open(metadata_path, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)

    def _evaluate_model(
        self,
        model_path: str,
        X_val: Any,
        y_val: Any,
        feature_names: list[str],
        model_type: str,
    ) -> dict:
        try:
            import lightgbm as lgb

            model_file = os.path.join(model_path, "model.txt")
            if not os.path.exists(model_file):
                return {}

            model = lgb.Booster(model_file=model_file)
            metrics = self.evaluator.evaluate(
                model=model,
                X_test=X_val,
                y_test=y_val,
                feature_names=feature_names,
                model_type=model_type,
            )

            return {
                "auc_roc": metrics.auc_roc,
                "precision": metrics.precision,
                "recall": metrics.recall,
                "f1_score": metrics.f1_score,
                "accuracy": metrics.accuracy,
                "ece": metrics.ece,
            }

        except Exception as e:
            logger.error("Model evaluation failed: %s", e)
            return {}

    def _update_latest_path(self, model_path: str, model_type: str):
        try:
            latest_path = os.path.join(self.config.output_dir, f"{model_type}_latest")
            if os.path.islink(latest_path) or os.path.isdir(latest_path) or os.path.isfile(latest_path):
                shutil.rmtree(latest_path, ignore_errors=True)

            shutil.copytree(model_path, latest_path)
            logger.info("Updated latest path: %s", latest_path)
        except Exception as e:
            logger.warning("Failed to update latest path: %s", e)

    def get_training_summary(self) -> dict:
        try:
            with self.get_db_cursor() as cursor:
                self.label_generator.db_cursor = cursor
                samples = self.label_generator.generate_training_data()
                return self.label_generator.get_label_distribution(samples)
        except Exception as e:
            logger.error("Failed to get training summary: %s", e)
            return {}

    def _min_volunteer_samples(self) -> int:
        return max(30, self.config.min_training_samples // 2)

    @staticmethod
    def _encode_campaign_status(status: Optional[str]) -> float:
        if status is None:
            return 0.0
        status_map = {
            "nhap": 0.0,
            "cho_duyet": 1.0,
            "da_duyet": 2.0,
            "dang_dien_ra": 3.0,
            "hoan_thanh": 4.0,
            "tu_choi": 5.0,
            "yeu_cau_huy": 6.0,
            "da_huy": 7.0,
        }
        return status_map.get(status, 0.0)
