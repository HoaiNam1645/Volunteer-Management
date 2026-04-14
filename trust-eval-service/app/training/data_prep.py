"""
Data Preparation - Chuẩn bị features và labels cho training.

Xử lý:
1. Gộp features từ CampaignFeatureExtractor với labels
2. Xử lý missing values
3. Feature engineering cho training
4. Train/validation split
5. Class balancing
"""

import logging
from typing import Optional, Tuple
import numpy as np

logger = logging.getLogger("trust_eval_service")


class DataPreparator:
    """
    Chuẩn bị data cho model training.

    Đảm bảo:
    - Feature matrix đồng nhất (không có extra/missing columns)
    - Missing values được xử lý hợp lý
    - Train/val split đúng tỷ lệ
    - Class imbalance được handle
    """

    # Feature names cho campaign trust model
    CAMPAIGN_FEATURE_NAMES = [
        # Campaign features
        "has_cover_image",
        "gallery_image_count",
        "description_length",
        "description_word_count",
        "description_quality_score",
        "location_completeness",
        "has_location_coords",
        "coords_in_vietnam",
        "schedule_completeness",
        "days_until_start",
        "campaign_duration_days",
        "registration_window_days",
        "reg_deadline_reasonable",
        "team_size_feasibility",
        "max_volunteers",
        "min_volunteers",
        "volunteer_range_valid",
        "is_urgent_priority",
        "has_contact_info_in_desc",
        "text_contains_external_urls",
        "external_url_count",
        "skill_requirements_clarity",
        "campaign_status_code",
        "registration_count",
        "confirmed_count",
        "registration_ratio",
        "confirmation_ratio",
        # Creator features
        "creator_account_age_days",
        "creator_has_verified_email",
        "creator_has_verified_phone",
        "creator_has_avatar",
        "creator_has_bio",
        "creator_campaign_count",
        "creator_campaign_approval_rate",
        "creator_previous_cancellation_rate",
        "creator_volunteer_rating_avg",
        "creator_volunteer_rating_count",
        "creator_avg_campaign_participation",
        "creator_report_count",
        "creator_location_complete",
        "creator_profile_completeness",
        "creator_ky_nang_count",
        "creator_chung_chi_count",
        "creator_kinh_nghiem_count",
        "creator_is_active",
        # Behavioral features
        "is_created_during_office_hours",
        "is_created_on_weekend",
        "is_created_late_night",
        "creation_hour",
        "creation_weekday",
        "content_edit_frequency",
        "recent_edit_before_start",
        "registration_to_start_ratio",
        "ghost_registration_suspicion",
        # Content quality features
        "vagueness_short_sentence_ratio",
        "vagueness_generic_phrase_count",
        "vagueness_score",
        "safety_description_score",
    ]

    # Feature names cho volunteer trust model
    VOLUNTEER_FEATURE_NAMES = [
        "account_age_days",
        "is_new_account",
        "has_verified_email",
        "has_phone",
        "has_avatar",
        "has_bio",
        "days_since_last_activity",
        "registration_count",
        "cancelled_registrations",
        "completed_registrations",
        "registration_cancellation_rate",
        "completion_rate",
        "no_show_rate",
        "late_cancellation_count",
        "avg_feedback_rating_given",
        "avg_rating_received",
        "rating_received_count",
        "has_perfect_rating",
        "profile_completeness_score",
        "has_certificates",
        "has_experience",
        "has_skills",
    ]

    def __init__(self, strategy: str = "mean"):
        """
        Args:
            strategy: Chiến lược fill missing values ('mean', 'median', 'zero', 'drop')
        """
        self.strategy = strategy

    def prepare_campaign_data(
        self,
        features_list: list[dict],
        labels: list[int],
        sample_info: Optional[list[dict]] = None,
    ) -> Tuple[np.ndarray, np.ndarray, list[str], dict]:
        """
        Chuẩn bị data cho campaign trust model.

        Args:
            features_list: List of feature dicts từ CampaignFeatureExtractor
            labels: List of labels (1 = reliable, 0 = suspicious)
            sample_info: Optional metadata cho từng sample

        Returns:
            (X_train, X_val, y_train, y_val, feature_names, stats)
        """
        if len(features_list) != len(labels):
            raise ValueError(
                f"Features ({len(features_list)}) and labels ({len(labels)}) mismatch"
            )

        # Extract feature matrix
        X = self._build_feature_matrix(features_list, self.CAMPAIGN_FEATURE_NAMES)
        y = np.array(labels)

        # Handle missing values
        X, stats = self._handle_missing_values(X, self.CAMPAIGN_FEATURE_NAMES)

        # Log class distribution
        pos = np.sum(y == 1)
        neg = np.sum(y == 0)
        logger.info(f"Class distribution: reliable={pos}, suspicious={neg}")

        if pos == 0 or neg == 0:
            logger.warning(
                "Only one class present! Training may not be meaningful. "
                f"Labels: {list(y)}"
            )

        return X, y, self.CAMPAIGN_FEATURE_NAMES, stats

    def prepare_volunteer_data(
        self,
        features_list: list[dict],
        labels: list[int],
    ) -> Tuple[np.ndarray, np.ndarray, list[str], dict]:
        """
        Chuẩn bị data cho volunteer trust model.
        """
        if len(features_list) != len(labels):
            raise ValueError(
                f"Features ({len(features_list)}) and labels ({len(labels)}) mismatch"
            )

        X = self._build_feature_matrix(features_list, self.VOLUNTEER_FEATURE_NAMES)
        y = np.array(labels)

        X, stats = self._handle_missing_values(X, self.VOLUNTEER_FEATURE_NAMES)

        pos = np.sum(y == 1)
        neg = np.sum(y == 0)
        logger.info(f"Volunteer class distribution: reliable={pos}, suspicious={neg}")

        return X, y, self.VOLUNTEER_FEATURE_NAMES, stats

    def _build_feature_matrix(
        self, features_list: list[dict], feature_names: list[str]
    ) -> np.ndarray:
        """Build numpy array từ list of feature dicts."""
        matrix = []
        for features in features_list:
            row = []
            for name in feature_names:
                val = features.get(name)
                row.append(val)
            matrix.append(row)
        return np.array(matrix, dtype=np.float64)

    def _handle_missing_values(
        self, X: np.ndarray, feature_names: list[str]
    ) -> Tuple[np.ndarray, dict]:
        """
        Xử lý missing values trong feature matrix.

        Chiến lược:
        - Numeric: fill bằng median của column
        - Boolean (0/1): fill bằng 0 (missing = False)
        - Boolean flags: fill bằng False (0)
        """
        stats = {
            "total_samples": len(X),
            "missing_per_feature": {},
            "fill_strategy": self.strategy,
        }

        X_clean = X.copy()
        fill_values = {}

        for i, name in enumerate(feature_names):
            col = X_clean[:, i]
            missing_mask = np.isnan(col)
            missing_count = np.sum(missing_mask)
            stats["missing_per_feature"][name] = int(missing_count)

            if missing_count == 0:
                continue

            if self.strategy == "drop":
                # Drop samples với missing values
                mask = ~np.any(np.isnan(X_clean), axis=1)
                X_clean = X_clean[mask]
                stats["samples_after_drop"] = len(X_clean)
                break

            elif self.strategy == "mean":
                fill_val = np.nanmean(col)
            elif self.strategy == "median":
                fill_val = np.nanmedian(col)
            elif self.strategy == "zero":
                fill_val = 0.0
            else:
                fill_val = 0.0

            X_clean[missing_mask, i] = fill_val
            fill_values[name] = float(fill_val)

        stats["fill_values"] = fill_values
        return X_clean, stats

    def train_val_split(
        self,
        X: np.ndarray,
        y: np.ndarray,
        test_size: float = 0.2,
        random_state: int = 42,
        stratify: bool = True,
    ) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """
        Split data thành train và validation.

        Args:
            X: Feature matrix
            y: Labels
            test_size: Tỷ lệ validation (0.2 = 20%)
            random_state: Seed cho reproducibility
            stratify: Giữ tỷ lệ class giống nhau

        Returns:
            (X_train, X_val, y_train, y_val)
        """
        if stratify and len(np.unique(y)) < 2:
            logger.warning("Cannot stratify with only one class, proceeding without stratification")
            stratify = False

        if stratify:
            from sklearn.model_selection import train_test_split
            return train_test_split(
                X, y,
                test_size=test_size,
                random_state=random_state,
                stratify=y,
            )
        else:
            from sklearn.model_selection import train_test_split
            return train_test_split(
                X, y,
                test_size=test_size,
                random_state=random_state,
            )

    def compute_class_weights(
        self, y: np.ndarray
    ) -> dict[int, float]:
        """
        Tính class weights để handle imbalance.

        Returns:
            Dict {class_label: weight}
        """
        from sklearn.utils.class_weight import compute_class_weight

        classes = np.unique(y)
        weights = compute_class_weight(
            class_weight="balanced",
            classes=classes,
            y=y,
        )
        return {int(c): float(w) for c, w in zip(classes, weights)}

    def generate_synthetic_positives(
        self,
        X: np.ndarray,
        y: np.ndarray,
        target_ratio: float = 0.5,
        random_state: int = 42,
    ) -> Tuple[np.ndarray, np.ndarray]:
        """
        Generate synthetic positive samples để balance dataset.

        Sử dụng SMOTE (Synthetic Minority Over-sampling Technique).

        Returns:
            (X_augmented, y_augmented)
        """
        try:
            from imblearn.over_sampling import SMOTE
        except ImportError:
            logger.warning(
                "imbalanced-learn not available, skipping synthetic oversampling"
            )
            return X, y

        pos_mask = y == 1
        neg_mask = y == 0
        pos_count = np.sum(pos_mask)
        neg_count = np.sum(neg_mask)

        if pos_count >= neg_count:
            logger.info("Positive class not minority, skipping oversampling")
            return X, y

        try:
            sampler = SMOTE(random_state=random_state)
            X_resampled, y_resampled = sampler.fit_resample(X, y)
            logger.info(
                f"SMOTE: {len(X)} → {len(X_resampled)} samples "
                f"(reliable: {np.sum(y_resampled == 1)}, suspicious: {np.sum(y_resampled == 0)})"
            )
            return X_resampled, y_resampled
        except Exception as e:
            logger.error(f"SMOTE failed: {e}, returning original data")
            return X, y
