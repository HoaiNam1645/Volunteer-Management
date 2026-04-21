"""
Training Data Generator - Sinh training data từ existing campaigns và historical decisions.

Phase 3: Generate training data từ existing campaigns.

Chiến lược sinh nhãn:
1. Lấy tất cả campaigns đã có trạng thái cuối cùng (da_duyet, tu_choi, hoan_thanh)
2. Nhãn từ KDV decisions:
   - da_duyet / hoan_thanh → label = 1 (reliable)
   - tu_choi → label = 0 (suspicious)
3. Campaigns ở trạng thái chưa có decision → dùng heuristic:
   - Có feedback tích cực + registration cao → reliable
   - Có báo cáo nhiều → suspicious
4. Campaigns chưa đủ dữ liệu → bỏ qua
"""

import logging
from datetime import datetime, date, timezone
from typing import Optional

logger = logging.getLogger("trust_eval_service")


class LabelGenerator:
    """
    Sinh training labels từ historical campaign data.

    Sources of labels:
    1. KDV decisions (campaign_evaluations table)
    2. Final campaign status (da_duyet/hoan_thanh → 1, tu_choi → 0)
    3. Feedback patterns (positive feedback → 1, negative → 0)
    4. Report patterns (many reports → 0)
    """

    # Thresholds cho heuristic labeling
    MIN_FEEDBACK_FOR_PATTERN = 3
    MIN_RATING_FOR_PATTERN = 4.0
    MAX_REPORTS_SUSPICIOUS = 2

    def __init__(self, db_cursor=None):
        self.db_cursor = db_cursor

    def generate_training_data(self) -> list[dict]:
        """
        Sinh danh sách training samples từ database.

        Mỗi sample gồm:
        - campaign_id: int
        - label: int (1 = reliable, 0 = suspicious)
        - label_source: str (kdv_decision | status | feedback | report)
        - label_confidence: str (high | medium | low)
        """
        if self.db_cursor is None:
            logger.warning("No database cursor provided, returning empty training data")
            return []

        samples = []

        # 1. Lấy nhãn từ KDV decisions (ưu tiên cao nhất)
        samples.extend(self._labels_from_kdv_decisions())

        # 2. Lấy nhãn từ trạng thái campaign (ưu tiên thấp hơn)
        samples.extend(self._labels_from_campaign_status())

        # 3. Lấy nhãn từ feedback patterns (bổ sung)
        samples.extend(self._labels_from_feedback())

        # 4. Lấy nhãn từ report patterns (bổ sung)
        samples.extend(self._labels_from_reports())

        # Deduplicate: giữ nhãn có confidence cao nhất
        samples = self._deduplicate_labels(samples)

        logger.info(
            f"Generated {len(samples)} training samples. "
            f"Reliable: {sum(1 for s in samples if s['label'] == 1)}, "
            f"Suspicious: {sum(1 for s in samples if s['label'] == 0)}"
        )
        return samples

    def _labels_from_kdv_decisions(self) -> list[dict]:
        """Lấy nhãn từ feedback loop KDV và campaign evaluations theo schema hiện tại."""
        samples = []

        action_map = {
            "approve": 1,
            "approve_with_note": 1,
            "request_info": None,
            "reject": 0,
            "da_duyet": 1,
            "hoan_thanh": 1,
            "tu_choi": 0,
        }

        try:
            self.db_cursor.execute("""
                SELECT etl.chien_dich_id AS campaign_id,
                       etl.kdv_action,
                       etl.created_at,
                       etl.ml_trust_score,
                       etl.ml_risk_level
                FROM evaluation_training_labels etl
                ORDER BY etl.created_at DESC
            """)
            rows = self.db_cursor.fetchall()

            for row in rows:
                label = action_map.get(row["kdv_action"])
                if label is None:
                    continue

                samples.append({
                    "campaign_id": row["campaign_id"],
                    "label": label,
                    "label_source": "training_label",
                    "label_confidence": "high",
                    "decision": row["kdv_action"],
                    "trust_score": row.get("ml_trust_score"),
                    "risk_level": row.get("ml_risk_level"),
                })

        except Exception as e:
            logger.warning(f"Error fetching training labels: {e}")

        try:
            self.db_cursor.execute("""
                SELECT ce.chien_dich_id AS campaign_id,
                       ce.kdv_final_action AS decision,
                       ce.evaluated_at AS created_at,
                       ce.trust_score_calibrated AS trust_score,
                       ce.risk_level
                FROM campaign_evaluations ce
                WHERE ce.kdv_final_action IS NOT NULL
                ORDER BY ce.evaluated_at DESC
            """)
            rows = self.db_cursor.fetchall()

            for row in rows:
                label = action_map.get(row["decision"])
                if label is None:
                    continue

                samples.append({
                    "campaign_id": row["campaign_id"],
                    "label": label,
                    "label_source": "kdv_decision",
                    "label_confidence": "high",
                    "decision": row["decision"],
                    "trust_score": row.get("trust_score"),
                    "risk_level": row.get("risk_level"),
                })

        except Exception as e:
            logger.error(f"Error fetching KDV decisions: {e}")

        logger.info(f"Labels from KDV decisions: {len(samples)}")
        return samples

    def _labels_from_campaign_status(self) -> list[dict]:
        """
        Lấy nhãn từ trạng thái cuối cùng của campaign.

        Logic:
        - da_duyet, dang_dien_ra, hoan_thanh → reliable (1)
        - tu_choi → suspicious (0)
        - Các trạng thái khác → bỏ qua
        """
        samples = []
        try:
            self.db_cursor.execute("""
                SELECT cd.id, cd.trang_thai, cd.ngay_bat_dau, cd.ngay_ket_thuc,
                       cd.so_dang_ky, cd.so_xac_nhan,
                       cd.mo_ta, cd.anh_bia, cd.dia_diem,
                       u.trang_thai as creator_status, u.xac_thuc_email_luc,
                       cd.tao_luc
                FROM chien_dichs cd
                LEFT JOIN nguoi_dungs u ON cd.nguoi_tao_id = u.id
                WHERE cd.trang_thai IN ('da_duyet', 'dang_dien_ra', 'hoan_thanh',
                                       'tu_choi')
                AND cd.xoa_luc IS NULL
                AND cd.mo_ta IS NOT NULL AND LENGTH(cd.mo_ta) >= 50
                AND cd.dia_diem IS NOT NULL AND LENGTH(cd.dia_diem) > 0
            """)
            rows = self.db_cursor.fetchall()

            for row in rows:
                status_map = {
                    "da_duyet": 1,
                    "dang_dien_ra": 1,
                    "hoan_thanh": 1,
                    "tu_choi": 0,
                }
                label = status_map.get(row["trang_thai"])

                # Tính confidence dựa trên data quality
                confidence = self._calc_label_confidence(row)

                if confidence != "low":
                    samples.append({
                        "campaign_id": row["id"],
                        "label": label,
                        "label_source": "campaign_status",
                        "label_confidence": confidence,
                        "status": row["trang_thai"],
                        "creator_status": row.get("creator_status"),
                        "has_email_verified": row.get("xac_thuc_email_luc") is not None,
                    })

        except Exception as e:
            logger.error(f"Error fetching campaign status labels: {e}")

        logger.info(f"Labels from campaign status: {len(samples)}")
        return samples

    def _labels_from_feedback(self) -> list[dict]:
        """
        Lấy nhãn từ feedback patterns.

        Logic:
        - avg_rating >= 4.0 với >= 3 feedback → reliable
        - avg_rating < 3.0 với >= 3 feedback → suspicious
        """
        samples = []
        try:
            self.db_cursor.execute("""
                SELECT cd.id, cd.trang_thai,
                       AVG(dg.so_sao) as avg_rating,
                       COUNT(dg.id) as feedback_count,
                       MIN(dg.so_sao) as min_rating
                FROM chien_dichs cd
                JOIN danh_gia_tnv dg ON cd.id = dg.chien_dich_id
                WHERE cd.xoa_luc IS NULL
                GROUP BY cd.id, cd.trang_thai
                HAVING COUNT(dg.id) >= %s
            """, (self.MIN_FEEDBACK_FOR_PATTERN,))
            rows = self.db_cursor.fetchall()

            for row in rows:
                avg_rating = row["avg_rating"] or 0
                min_rating = row["min_rating"] or 0
                count = row["feedback_count"] or 0

                if avg_rating >= self.MIN_RATING_FOR_PATTERN:
                    label = 1
                    confidence = "medium"
                elif avg_rating < 3.0 and min_rating < 2.5:
                    label = 0
                    confidence = "medium"
                else:
                    continue  # Không đủ rõ ràng

                samples.append({
                    "campaign_id": row["id"],
                    "label": label,
                    "label_source": "feedback_pattern",
                    "label_confidence": confidence,
                    "avg_rating": round(avg_rating, 2),
                    "feedback_count": count,
                })

        except Exception as e:
            logger.error(f"Error fetching feedback labels: {e}")

        logger.info(f"Labels from feedback patterns: {len(samples)}")
        return samples

    def _labels_from_reports(self) -> list[dict]:
        """
        Lấy nhãn từ report patterns.

        Logic:
        - >= 3 reports với status confirmed → suspicious
        """
        samples = []
        try:
            self.db_cursor.execute("""
                SELECT cd.id, cd.trang_thai,
                       COUNT(bc.id) as report_count,
                       SUM(CASE WHEN bc.trang_thai = 'da_xu_ly' THEN 1 ELSE 0 END) as confirmed_count
                FROM chien_dichs cd
                JOIN bao_cao_chien_dich bc ON cd.id = bc.chien_dich_id
                WHERE cd.xoa_luc IS NULL
                GROUP BY cd.id, cd.trang_thai
                HAVING COUNT(bc.id) >= %s
            """, (self.MAX_REPORTS_SUSPICIOUS + 1,))
            rows = self.db_cursor.fetchall()

            for row in rows:
                confirmed = row["confirmed_count"] or 0
                total = row["report_count"] or 0

                if confirmed >= self.MAX_REPORTS_SUSPICIOUS:
                    samples.append({
                        "campaign_id": row["id"],
                        "label": 0,
                        "label_source": "report_pattern",
                        "label_confidence": "medium",
                        "report_count": total,
                        "confirmed_count": confirmed,
                    })

        except Exception as e:
            logger.error(f"Error fetching report labels: {e}")

        logger.info(f"Labels from report patterns: {len(samples)}")
        return samples

    def _calc_label_confidence(self, row: dict) -> str:
        """
        Tính confidence của nhãn dựa trên data quality.

        High confidence: Có đủ thông tin + người tạo verified
        Medium confidence: Có đủ thông tin cơ bản
        Low confidence: Thiếu nhiều thông tin
        """
        score = 0

        # Có đủ thông tin cơ bản
        if row.get("mo_ta") and len(row["mo_ta"] or "") >= 100:
            score += 1
        if row.get("anh_bia"):
            score += 1
        if row.get("dia_diem"):
            score += 1

        # Người tạo verified
        if row.get("creator_status") == "hoat_dong":
            score += 1
        if row.get("xac_thuc_email_luc"):
            score += 1

        # Có engagement
        so_dang_ky = row.get("so_dang_ky") or 0
        if so_dang_ky > 0:
            score += 1

        if score >= 5:
            return "high"
        elif score >= 3:
            return "medium"
        else:
            return "low"

    def _deduplicate_labels(self, samples: list[dict]) -> list[dict]:
        """
        Loại bỏ duplicates, giữ nhãn có confidence cao nhất.

        Priority: training_label > kdv_decision > campaign_status > feedback_pattern > report_pattern
        """
        priority = {
            "training_label": 5,
            "kdv_decision": 4,
            "campaign_status": 3,
            "feedback_pattern": 2,
            "report_pattern": 1,
        }
        confidence_priority = {"high": 3, "medium": 2, "low": 1}

        # Group by campaign_id
        campaign_map: dict[int, dict] = {}
        for sample in samples:
            cid = sample["campaign_id"]
            if cid not in campaign_map:
                campaign_map[cid] = sample
            else:
                existing = campaign_map[cid]
                # So sánh priority
                existing_prio = (priority.get(existing["label_source"], 0),
                                 confidence_priority.get(existing["label_confidence"], 0))
                new_prio = (priority.get(sample["label_source"], 0),
                            confidence_priority.get(sample["label_confidence"], 0))
                if new_prio > existing_prio:
                    campaign_map[cid] = sample

        return list(campaign_map.values())

    def get_label_distribution(self, samples: list[dict]) -> dict:
        """Thống kê phân bố nhãn."""
        total = len(samples)
        if total == 0:
            return {"total": 0, "reliable": 0, "suspicious": 0, "ratio": None}

        reliable = sum(1 for s in samples if s["label"] == 1)
        suspicious = sum(1 for s in samples if s["label"] == 0)

        return {
            "total": total,
            "reliable": reliable,
            "suspicious": suspicious,
            "ratio": round(reliable / suspicious, 2) if suspicious > 0 else None,
            "by_source": {
                src: sum(1 for s in samples if s["label_source"] == src)
                for src in set(s["label_source"] for s in samples)
            },
            "by_confidence": {
                conf: sum(1 for s in samples if s["label_confidence"] == conf)
                for conf in set(s["label_confidence"] for s in samples)
            },
        }
