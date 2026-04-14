"""
Training Pipeline - Điều phối toàn bộ quy trình training.

Chạy theo thứ tự:
1. LabelGenerator → sinh training data
2. DataPreparator → chuẩn bị features + split
3. LightGBMTrainer → huấn luyện model
4. ProbabilityCalibrator → calibration
5. ModelEvaluator → đánh giá


6. MLflowTracker → log kết quả
"""

import logging
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional

logger = logging.getLogger("trust_eval_service")


@dataclass
class PipelineConfig:
    """Cấu hình training pipeline."""
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
    """Kết quả của toàn bộ pipeline."""
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
    """
    Pipeline điều phối toàn bộ quy trình training.

    Chuẩn bị → Huấn luyện → Calibration → Đánh giá → Log
    """

    def __init__(self, config: Optional[PipelineConfig] = None):
        self.config = config or PipelineConfig()
        os.makedirs(self.config.output_dir, exist_ok=True)

        # Initialize components
        self._init_components()

    def _init_components(self):
        """Khởi tạo các components."""
        # Import here để tránh circular import
        from app.training.label_generator import LabelGenerator
        from app.training.data_prep import DataPreparator
        from app.training.trainer import LightGBMTrainer
        from app.training.calibrator import ProbabilityCalibrator
        from app.training.evaluator import ModelEvaluator
        from app.training.mlflow_utils import get_mlflow_tracker, MLflowConfig
        from app.core.database import get_db_cursor

        self.label_generator = LabelGenerator()
        self.data_prep = DataPreparator()
        self.trainer = LightGBMTrainer(output_dir=self.config.output_dir)
        self.calibrator = ProbabilityCalibrator(output_dir=self.config.output_dir)
        self.evaluator = ModelEvaluator()
        self.mlflow = get_mlflow_tracker()

        # Configure MLflow
        if self.mlflow.is_available:
            self.mlflow.config.tracking_uri = self.config.mlflow_tracking_uri
            self.mlflow.config.experiment_name = self.config.mlflow_experiment

        self.get_db_cursor = get_db_cursor

    def run_full_pipeline(self) -> PipelineResult:
        """
        Chạy toàn bộ pipeline.

        Returns:
            PipelineResult
        """
        logger.info("=" * 60)
        logger.info("Starting Training Pipeline")
        logger.info(f"Output dir: {self.config.output_dir}")
        logger.info("=" * 60)

        try:
            # === STEP 1: Generate training data ===
            logger.info("\n[STEP 1] Generating training data...")
            labels_data = self._generate_labels()
            if len(labels_data) < self.config.min_training_samples:
                return PipelineResult(
                    success=False,
                    error=f"Only {len(labels_data)} training samples found, "
                          f"minimum {self.config.min_training_samples} required",
                    config=self.config,
                )

            # === STEP 2: Extract features ===
            logger.info("\n[STEP 2] Extracting features...")
            features_data = self._extract_features()
            if len(features_data) == 0:
                return PipelineResult(
                    success=False,
                    error="No features extracted from campaigns",
                    config=self.config,
                )

            # === STEP 3: Prepare data ===
            logger.info("\n[STEP 3] Preparing data...")
            X, y, feature_names, prep_stats = self._prepare_data(
                labels_data, features_data
            )
            logger.info(f"Training samples: {len(X)}, Labels: 1={sum(y==1)}, 0={sum(y==0)}")

            # === STEP 4: Split data ===
            X_train, X_val, y_train, y_val = self.data_prep.train_val_split(
                X, y,
                test_size=self.config.test_size,
                random_state=self.config.random_state,
            )
            logger.info(f"Train: {len(X_train)}, Val: {len(X_val)}")

            # === STEP 5: Compute class weights ===
            class_weights = self.data_prep.compute_class_weights(y_train)
            logger.info(f"Class weights: {class_weights}")

            # === STEP 6: Train campaign model ===
            logger.info("\n[STEP 5] Training campaign trust model...")
            campaign_result = self.trainer.train_campaign_model(
                X_train, y_train,
                X_val, y_val,
                class_weights=class_weights,
                feature_names=feature_names,
            )
            logger.info(f"Campaign model: {campaign_result.model_path}")

            # === STEP 7: Calibrate ===
            calibration_result = None
            if self.config.calibration_enabled:
                logger.info("\n[STEP 6] Calibrating...")
                try:
                    import lightgbm as lgb
                    model_file = os.path.join(campaign_result.model_path, "model.txt")
                    if os.path.exists(model_file):
                        model = lgb.Booster(model_file=model_file)
                        _, calibration_result = self.calibrator.calibrate(
                            model=model,
                            X_train=X_train,
                            y_train=y_train,
                            X_val=X_val,
                            y_val=y_val,
                            model_type="campaign_trust",
                        )
                        logger.info(
                            f"Calibration done: ECE {calibration_result.ece_before:.4f} → "
                            f"{calibration_result.ece_after:.4f}"
                        )
                    else:
                        logger.warning("Model file not found for calibration")
                except Exception as e:
                    logger.error(f"Calibration failed: {e}")
            else:
                logger.info("Calibration disabled, skipping")

            # === STEP 8: Evaluate ===
            logger.info("\n[STEP 7] Evaluating...")
            campaign_metrics = self._evaluate_model(
                campaign_result.model_path, X_val, y_val, feature_names,
                "campaign_trust"
            )

            # === STEP 9: Log to MLflow ===
            mlflow_run_id = None
            if self.mlflow.is_available:
                logger.info("\n[STEP 8] Logging to MLflow...")
                mlflow_run_id = self.mlflow.log_training_run(
                    model_type="campaign_trust",
                    params=campaign_result.params,
                    train_metrics={},
                    val_metrics=campaign_metrics,
                    feature_importance=campaign_result.feature_importance,
                    model_path=campaign_result.model_path,
                )

            # === STEP 10: Copy to latest path ===
            self._update_latest_path(
                campaign_result.model_path, "campaign_trust"
            )

            logger.info("\n" + "=" * 60)
            logger.info("Training Pipeline COMPLETED")
            logger.info(f"Campaign model: {campaign_result.model_path}")
            logger.info(f"Metrics: AUC={campaign_metrics.get('auc_roc')}")
            logger.info("=" * 60)

            return PipelineResult(
                success=True,
                campaign_model_path=campaign_result.model_path,
                training_samples=len(X_train),
                validation_samples=len(X_val),
                campaign_metrics=campaign_metrics,
                mlflow_run_id=mlflow_run_id,
                config=self.config,
            )

        except Exception as e:
            logger.error(f"Pipeline failed: {e}", exc_info=True)
            return PipelineResult(
                success=False,
                error=str(e),
                config=self.config,
            )

    def _generate_labels(self) -> list[dict]:
        """Generate labels từ database."""
        try:
            with self.get_db_cursor() as cursor:
                self.label_generator.db_cursor = cursor
                return self.label_generator.generate_training_data()
        except Exception as e:
            logger.error(f"Failed to generate labels: {e}")
            return []

    def _extract_features(self) -> list[dict]:
        """Extract features từ campaigns đã labeled."""
        from app.core.feature_extractor import CampaignFeatureExtractor
        from app.core.database import get_db_cursor

        features_data = []
        try:
            with get_db_cursor() as cursor:
                # Fetch campaigns đã có trong training set
                cursor.execute("""
                    SELECT cd.*, u.id as creator_user_id,
                           u.ho_ten as creator_name, u.email as creator_email,
                           u.anh_dai_dien as creator_avatar,
                           u.gioi_thieu as creator_bio,
                           u.trang_thai as creator_status,
                           u.xac_thuc_email_luc as creator_email_verified_at,
                           u.tao_luc as creator_created_at,
                           u.tinh_thanh_id as creator_province_id,
                           u.vi_do as creator_lat, u.kinh_do as creator_lng,
                           u.so_dien_thoai as creator_phone,
                           u.vai_tro as creator_role
                    FROM chien_dichs cd
                    LEFT JOIN nguoi_dungs u ON cd.nguoi_tao_id = u.id
                    WHERE cd.xoa_luc IS NULL
                    AND cd.trang_thai IN ('da_duyet', 'tu_choi', 'hoan_thanh')
                    LIMIT 1000
                """)
                campaigns = cursor.fetchall()

                for campaign in campaigns:
                    creator_id = campaign.get("nguoi_tao_id")
                    creator_data = {}
                    ratings = []
                    reports = []
                    reviews = []

                    if creator_id:
                        # Fetch creator stats
                        cursor.execute("""
                            SELECT COUNT(*) as total,
                                   SUM(CASE WHEN trang_thai = 'da_duyet' THEN 1 ELSE 0 END) as approved,
                                   SUM(CASE WHEN trang_thai IN ('da_huy','yeu_cau_huy') THEN 1 ELSE 0 END) as cancelled
                            FROM chien_dichs WHERE nguoi_tao_id = %s AND xoa_luc IS NULL
                        """, (creator_id,))
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

                        # Fetch ratings
                        cursor.execute("""
                            SELECT dg.so_sao FROM danh_gia_tnvs dg
                            JOIN chien_dichs cd ON dg.chien_dich_id = cd.id
                            WHERE cd.nguoi_tao_id = %s AND dg.xoa_luc IS NULL
                        """, (creator_id,))
                        ratings = cursor.fetchall()

                        # Fetch reports
                        cursor.execute("""
                            SELECT bc.id FROM bao_cao_chien_dichs bc
                            JOIN chien_dichs cd ON bc.chien_dich_id = cd.id
                            WHERE cd.nguoi_tao_id = %s AND bc.xoa_luc IS NULL
                        """, (creator_id,))
                        reports = cursor.fetchall()

                        # Fetch reviews
                        cursor.execute("""
                            SELECT lsk.id, lsk.hanh_dong, lsk.created_at
                            FROM lich_su_kiem_duyet_chien_dichs lsk
                            WHERE lsk.chien_dich_id = %s
                        """, (campaign["id"],))
                        reviews = cursor.fetchall()

                    # Extract features
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
            logger.error(f"Failed to extract features: {e}")

        return features_data

    def _prepare_data(
        self, labels_data: list[dict], features_data: list[dict]
    ):
        """Chuẩn bị features + labels, align theo campaign_id."""
        # Build label map
        label_map = {s["campaign_id"]: s["label"] for s in labels_data}

        # Match features with labels
        features_list = []
        labels = []

        for feat in features_data:
            cid = feat.get("campaign_id")
            if cid in label_map:
        # Remove campaign_status (string) - we add campaign_status_code below
        feat_clean = {k: v for k, v in feat.items()
                      if k not in ("campaign_id", "campaign_status")}
        # Encode status as numeric for LightGBM compatibility
        feat_clean["campaign_status_code"] = self._encode_campaign_status(
            feat.get("campaign_status")
        )
        features_list.append(feat_clean)
        labels.append(label_map[cid])

        # Prepare data
        X, y, feature_names, stats = self.data_prep.prepare_campaign_data(
            features_list, labels
        )

        logger.info(
            f"Prepared {len(X)} samples. "
            f"Reliable: {sum(y==1)}, Suspicious: {sum(y==0)}"
        )

        return X, y, feature_names, stats

    @staticmethod
    def _encode_campaign_status(status: Optional[str]) -> float:
        """Encode campaign status string to numeric for LightGBM."""
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

    def _evaluate_model(
        self,
        model_path: str,
        X_val: any,
        y_val: any,
        feature_names: list[str],
        model_type: str,
    ) -> dict:
        """Load model và đánh giá."""
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
            logger.error(f"Model evaluation failed: {e}")
            return {}

    def _update_latest_path(self, model_path: str, model_type: str):
        """Copy model path vào latest."""
        try:
            latest_path = os.path.join(
                self.config.output_dir, f"{model_type}_latest"
            )
            # Remove old symlink/file if exists
            if os.path.islink(latest_path) or os.path.isdir(latest_path) or os.path.isfile(latest_path):
                import shutil
                shutil.rmtree(latest_path, ignore_errors)

            import shutil
            shutil.copytree(model_path, latest_path)
            logger.info(f"Updated latest path: {latest_path}")
        except Exception as e:
            logger.warning(f"Failed to update latest path: {e}")

    def get_training_summary(self) -> dict:
        """Lấy summary của training data hiện có."""
        try:
            with self.get_db_cursor() as cursor:
                self.label_generator.db_cursor = cursor
                samples = self.label_generator.generate_training_data()
                return self.label_generator.get_label_distribution(samples)
        except Exception as e:
            logger.error(f"Failed to get training summary: {e}")
            return {}
