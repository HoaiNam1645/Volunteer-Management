# SPEC: MÔ-ĐUN ĐÁNH GIÁ ĐỘ TIN CẬY, RỦI RO & HỖ TRỢ DUYỆT CHIẾN DỊCH

Tài liệu kỹ thuật mô tả kiến trúc, luồng xử lý, API và phạm vi triển khai cho mô-đun ML-based Campaign Trust & Risk Evaluation

Nền tảng: Python FastAPI (ML Service) + Laravel 12 (API Gateway & Business Logic) + MySQL (shared database)

---

## 1. Mục tiêu của mô-đun

Mô-đun này không kết luận tuyệt đối chiến dịch là thật hay giả, mà tập trung vào bốn nhiệm vụ chính: kiểm tra điều kiện bắt buộc, đánh giá độ tin cậy, phát hiện rủi ro/bất thường và hỗ trợ quản trị viên quyết định duyệt, yêu cầu bổ sung hoặc từ chối chiến dịch.

Về bản chất, đây là mô-đun **AI-assisted Campaign Trust & Risk Evaluation**, sử dụng machine learning để hỗ trợ xác minh độ tin cậy và mức độ an toàn của chiến dịch trước khi công bố cho tình nguyện viên đăng ký.

### Phạm vi chức năng

- **Đầu ra**: hệ thống trả về điểm tin cậy, mức rủi ro, danh sách cảnh báo và đề xuất trạng thái xử lý dưới dạng REST API.
- **Ngoài phạm vi**: hệ thống không tự động duyệt hoặc từ chối chiến dịch; mọi quyết định cuối cùng thuộc về quản trị viên/kiểm duyệt viên.

---

## 2. Các kỹ thuật sử dụng

### 2.1. Kiểm tra luật nghiệp vụ [Rule-based Validation]

Lớp bắt buộc, dễ triển khai và hiệu quả cao. Dùng để xác minh chiến dịch có đáp ứng các điều kiện tối thiểu trước khi cho phép chuyển sang bước ML evaluation.

**Các luật kiểm tra bắt buộc:**

- Tên chiến dịch: không rỗng, độ dài 10–200 ký tự.
- Mô tả chiến dịch: không rỗng, độ dài tối thiểu 50 ký tự.
- Địa điểm: `dia_diem` không rỗng.
- Tọa độ: `vi_do` và `kinh_do` phải nằm trong phạm vi Việt Nam (lat: 8.4–23.4, lng: 102.1–109.5).
- Thời gian: `ngay_bat_dau` <= `ngay_ket_thuc`; `ngay_bat_dau` phải >= ngày hiện tại.
- Hạn đăng ký: `han_dang_ky` phải nằm trong khoảng [ngày hiện tại, `ngay_bat_dau`].
- Số lượng: `so_luong_toi_da` >= `so_luong_toi_thieu` >= 1.
- Người tạo: `nguoi_tao_id` phải tồn tại và có `trang_thai` = 'hoat_dong'.
- Email người tạo: phải được xác thực (`xac_thuc_email_luc` not null).
- Loại chiến dịch: `loai_chien_dich_id` phải tồn tại.

**Kỹ thuật áp dụng:** Pydantic validation (request/response models), constraint validation, format validation, temporal consistency checking, geographic boundary validation.

**Đầu ra rule-based:** danh sách `validation_errors` với mã lỗi, severity, message và suggestion. Nếu có lỗi `CRITICAL`, chiến dịch không được chuyển sang ML evaluation.

### 2.2. Chấm điểm độ tin cậy [Trust Scoring]

Kỹ thuật cốt lõi để lượng hóa mức độ đáng tin của chiến dịch trên thang 0.0–1.0 (xác suất calibrated).

**Mô hình sử dụng:** LightGBM (gradient boosting) cho cả campaign trust score và volunteer trust score. Model được train với binary classification (reliable/suspicious), sau đó calibrated bằng Isotonic Regression để đảm bảo xác suất đáng tin cậy.

**Công thức tổng hợp:**

```
TrustScore = 0.4 × CampaignFeatures + 0.35 × CreatorFeatures + 0.15 × BehavioralFeatures + 0.10 × ContentQuality
```

**Nhóm tiêu chí 1 – Đặc trưng chiến dịch (Campaign Features):**

- `has_cover_image`: có ảnh bìa hay không.
- `has_gallery_images`: số lượng ảnh trong gallery (0–10+).
- `description_length`: độ dài mô tả (từ).
- `description_quality_score`: điểm chất lượng mô tả (Jaccard similarity với template "chiến dịch tốt").
- `location_completeness`: điểm hoàn thiện địa điểm (tọa độ + địa chỉ text + khu vực).
- `schedule_completeness`: có đầy đủ ngày bắt đầu, kết thúc, giờ bắt đầu thực tế?
- `skill_requirements_clarity`: mô tả kỹ năng cần thiết rõ ràng?
- `registration_deadline_reasonableness`: hạn đăng ký hợp lý (> 3 ngày trước ngày bắt đầu)?
- `team_size_feasibility`: tỷ lệ `so_luong_toi_da` / duration hợp lý?
- `days_until_start`: số ngày đến ngày bắt đầu.
- `campaign_duration_days`: thời lượng chiến dịch (ngày).
- `is_urgent_priority`: có mức ưu tiên `khan_cap`?
- `has_contact_info_in_description`: có thông tin liên hệ trong mô tả?
- `text_contains_external_urls`: có chứa URL ngoài?

**Nhóm tiêu chí 2 – Uy tín người tạo (Creator Features):**

- `creator_account_age_days`: số ngày từ khi tạo tài khoản.
- `creator_has_verified_email`: email đã xác thực?
- `creator_has_verified_phone`: số điện thoại đã xác thực? (dựa trên `so_dien_thoai` không rỗng + có trigger xác thực SMS trong tương lai).
- `creator_has_avatar`: có ảnh đại diện?
- `creator_has_bio`: có giới thiệu bản thân?
- `creator_campaign_count`: tổng số chiến dịch đã tạo.
- `creator_campaign_approval_rate`: tỷ lệ chiến dịch được duyệt / tổng số đã gửi.
- `creator_previous_cancellation_rate`: tỷ lệ chiến dịch bị hủy.
- `creator_avg_campaign_participation`: trung bình số TNV tham gia mỗi chiến dịch.
- `creator_volunteer_rating_avg`: điểm đánh giá trung bình từ TNV (trên thang 1–5).
- `creator_volunteer_rating_count`: số lượt đánh giá.
- `creator_report_count`: số lần bị báo cáo.
- `creator_location_complete`: có đầy đủ địa chỉ và tọa độ?
- `creator_ky_nang_count`: số kỹ năng đã khai báo.
- `creator_chung_chi_count`: số chứng chỉ đã khai báo.
- `creator_kinh_nghiem_count`: số kinh nghiệm đã khai báo.

**Nhóm tiêu chí 3 – Hành vi (Behavioral Features):**

- `is_created_during_office_hours`: tạo trong giờ hành chính (8:00–18:00)?
- `is_created_on_weekend`: tạo vào cuối tuần?
- `content_edit_frequency`: số lần chỉnh sửa trước khi gửi duyệt.
- `recent_edit_before_start`: có chỉnh sửa trong vòng 48 giờ trước ngày bắt đầu?
- `registration_to_start_ratio`: tỷ lệ `so_dang_ky` / `so_luong_toi_da`.

**Nhóm tiêu chí 4 – Chất lượng nội dung văn bản (Content Quality):**

- `text_risk_keyword_count`: số từ khóa rủi ro trong mô tả.
- `text_risk_score`: điểm rủi ro văn bản (TF-IDF + Logistic Regression).
- `vagueness_score`: điểm mơ hồ của mô tả (sentence length variance, ratio of generic phrases).
- `safety_description_score`: có mô tả phương án an toàn?

**Volunteer Trust Score (đánh giá hành vi TNV):**

- `registration_count`: tổng số lần đăng ký.
- `registration_cancellation_rate`: tỷ lệ hủy / tổng đăng ký.
- `no_show_rate`: tỷ lệ đăng ký nhưng không xác nhận tham gia.
- `completion_rate`: tỷ lệ hoàn thành / tổng đăng ký.
- `late_cancellation_count`: số lần hủy trong vòng 3 ngày trước sự kiện.
- `avg_feedback_rating_given`: điểm đánh giá trung bình mà TNV đã đánh giá người khác.
- `profile_completeness_score`: % trường thông tin đã điền.
- `days_since_last_activity`: số ngày kể từ hoạt động cuối.
- `is_new_account`: tài khoản mới tạo (< 7 ngày)?

**Mức phân loại đầu ra Trust Score:**

| Điểm calibrated | Nhãn | Ý nghĩa |
|---|---|---|
| 0.80–1.00 | RELIABLE_HIGH | Đáng tin cậy cao, confidence cao |
| 0.60–0.79 | RELIABLE | Đáng tin cậy |
| 0.40–0.59 | NEUTRAL | Trung lập, cần xem xét |
| 0.20–0.39 | SUSPICIOUS | Đáng ngờ |
| 0.00–0.19 | SUSPICIOUS_HIGH | Đáng ngờ cao, confidence cao |

### 2.3. Phát hiện bất thường [Anomaly Detection]

Lớp kỹ thuật dùng để nhận diện các mẫu hành vi không bình thường mà luật cứng và model supervised khó phát hiện hết. Hoạt động song song với Trust Scoring.

**Kỹ thuật áp dụng:** Isolation Forest (scikit-learn) cho unsupervised anomaly detection trên campaign behavioral features. Kết hợp statistical profiling (Z-score) cho một số features cụ thể.

**Isolation Forest cấu hình:**

- `contamination`: 0.05 (5% outlier dự kiến).
- `n_estimators`: 200.
- `max_samples`: 'auto'.
- `random_state`: 42 (đảm bảo reproducibility).

**Các bất thường cần phát hiện:**

- Tài khoản mới (< 14 ngày) nhưng tạo chiến dịch đầu tiên với mô tả dài/bài bản (machine-generated suspicion).
- Người tạo có tỷ lệ hủy chiến dịch cao bất thường (> 30%).
- Chiến dịch có nội dung trùng lặp cao với chiến dịch khác (text similarity > 0.85).
- Số lượng đăng ký không tăng sau 50% thời gian đăng ký (engagement anomaly).
- Địa điểm không khớp với khu vực của người tạo (distance > 200km mà không có lý do).
- Thời gian tạo chiến dịch bất thường (02:00–05:00, nhiều chiến dịch liên tiếp trong 1 giờ).
- Tỷ lệ `so_dang_ky` / `so_luong_toi_da` > 0.9 nhưng `so_xac_nhan` / `so_dang_ky` < 0.3 (ghost registrations).

**Đầu ra:** `anomaly_score` (float, càng âm càng bất thường), `is_anomaly` (boolean, threshold = -0.5), danh sách `anomaly_types`.

### 2.4. Phân tích nội dung văn bản [NLP-based Content Risk Analysis]

Thành phần phát hiện rủi ro từ nội dung mô tả chiến dịch.

**Từ điểm từ khóa rủi ro (Risk Keyword Dictionary):**

| Nhóm | Từ khóa | Severity |
|---|---|---|
| Yêu cầu tiền trước | "chuyển khoản", "đặt cọc", "thu phí", "phí tham gia", "nộp tiền", "trả trước" | HIGH |
| Địa điểm mơ hồ | "sẽ thông báo sau", "gửi địa điểm riêng", "gặp mặt trực tiếp sẽ nói" | HIGH |
| Bảo mật đáng ngờ | "bí mật", "không tiết lộ", "không công khai", "chỉ người được chọn" | MEDIUM |
| Nội dung mơ hồ | "hoạt động đặc biệt", "sự kiện đặc biệt", "ngày đặc biệt" | MEDIUM |
| Thông tin nhạy cảm | "cmnd", "cccd", "sao kê", "tài khoản ngân hàng" (yêu cầu TNV cung cấp) | HIGH |
| Liên hệ không chính thức | "zalo", "facebook", "messenger" (là kênh liên hệ DUY NHẤT, không có email/điện thoại) | MEDIUM |

**Mức triển khai:**

- **Mức 1 (cơ bản, bắt buộc):** Từ điển từ khóa rủi ro + luật phát hiện cụm từ nguy hiểm + đếm tần suất.
- **Mức 2 (nâng cao, mục tiếp theo):** TF-IDF vectorization + Logistic Regression (binary: safe/risky) trained trên dữ liệu đã label.

**Chấm điểm nội dung:**

- `text_risk_keyword_count`: tổng số từ khóa rủi ro phát hiện.
- `text_risk_score`: xác suất rủi ro từ model (0.0–1.0).
- `vagueness_score`: điểm mơ hồ (dựa trên: tỷ lệ sentence có < 10 ký tự, tỷ lệ generic phrases).
- `safety_description_score`: 1.0 nếu có mô tả phương án an toàn, 0.5 nếu có keyword "an toàn" nhưng không mô tả, 0.0 nếu không có.

### 2.5. Calibration và Explainability

**Probability Calibration:**

- Phương pháp: Isotonic Regression (scikit-learn `CalibratedClassifierCV` với `method='isotonic'`, `cv=5`).
- Mục tiêu: đảm bảo xác suất đầu ra phản ánh đúng tần suất thực tế (nếu model trả P=0.8, thì 80% trường hợp thực sự là reliable).
- Metric theo dõi: Expected Calibration Error (ECE) < 0.05.

**SHAP Explanations:**

- Thư viện: `shap` (TreeExplainer cho LightGBM).
- Mục đích: giải thích từng đánh giá cụ thể — yếu tố nào làm tăng/giảm trust score.
- Đầu ra: danh sách top positive factors, top negative factors, và feature importance tổng thể.

---

## 3. Luồng làm việc tổng thể

Quy trình khuyến nghị cho hệ thống được tổ chức theo chuỗi bước sau:

**Bước 1 – Người tổ chức gửi chiến dịch:** nhập tên, mô tả, thời gian, địa điểm, số lượng TNV, thông tin liên hệ và tài liệu minh chứng. Chiến dịch ở trạng thái `nhap` hoặc `cho_duyet`.

**Bước 2 – Laravel gọi ML Service:** khi KDV mở trang chi tiết chiến dịch hoặc khi hệ thống detect chiến dịch mới ở trạng thái `cho_duyet`, Laravel Gateway Service gửi HTTP POST request đến FastAPI `/api/v1/evaluate/campaign/{id}`.

**Bước 3 – ML Service trích xuất đặc trưng [Feature Extraction]:** tự động join dữ liệu từ database (campaign, creator, registrations, feedbacks, reports, review history) và sinh feature vector.

**Bước 4 – Rule-based Validation:** áp dụng Pydantic validation để kiểm tra dữ liệu đầu vào. Nếu có lỗi `CRITICAL`, trả về kết quả ngay mà không chạy ML.

**Bước 5 – ML Inference:** chạy LightGBM campaign trust model và volunteer trust model (nếu cần) để sinh `trust_score`, `risk_score`.

**Bước 6 – Probability Calibration:** apply Isotonic Regression calibration để đảm bảo xác suất đáng tin cậy.

**Bước 7 – Anomaly Detection:** chạy Isolation Forest trên behavioral features để sinh `anomaly_score` và `anomaly_types`.

**Bước 8 – NLP Content Analysis:** chạy risk keyword detection và TF-IDF model để sinh `text_risk_score` và `risk_flags`.

**Bước 9 – Decision Logic:** tổng hợp tất cả điểm số và rules để sinh `recommended_action`, `risk_level`, và `questions_to_verify`.

**Bước 10 – SHAP Explanation:** sinh SHAP values để giải thích kết quả đánh giá cho KDV.

**Bước 11 – Trả kết quả về Laravel:** ML Service trả JSON response về Laravel Gateway Service. Laravel lưu vào `campaign_evaluations` table và cache kết quả.

**Bước 12 – KDV kiểm duyệt:** quản trị viên xem dashboard, đọc các cảnh báo (risk flags), kiểm tra SHAP explanation, và đưa ra quyết định duyệt, yêu cầu bổ sung hoặc từ chối.

**Bước 13 – Retraining feedback loop:** khi KDV đưa ra quyết định, kết quả (label + features) được lưu lại. Định kỳ (tuần/tháng), model được retrain với dữ liệu mới để cải thiện accuracy.

**Luồng trạng thái nghiệp vụ hiện tại (đã có trong hệ thống):**

| Trạng thái | Ý nghĩa |
|---|---|
| `nhap` | Người tổ chức mới tạo chiến dịch. |
| `cho_duyet` | Chiến dịch đang chờ kiểm duyệt viên duyệt. ML evaluation được trigger ở trạng thái này. |
| `da_duyet` | Admin/KDV chấp thuận và cho phép công bố. |
| `dang_dien_ra` | Chiến dịch đang diễn ra. |
| `hoan_thanh` | Chiến dịch kết thúc, dữ liệu phản hồi được đưa vào hậu kiểm. |
| `tu_choi` | Chiến dịch không đáp ứng yêu cầu hoặc có rủi ro cao. |
| `yeu_cau_huy` | Chiến dịch đang yêu cầu hủy. |
| `da_huy` | Chiến dịch đã bị hủy. |

**Bổ sung luồng ML Evaluation:**

| Trạng thái ML | Ý nghĩa |
|---|---|
| `pending_evaluation` | Đã gửi yêu cầu ML evaluation, đang xử lý. |
| `evaluated_safe` | ML evaluation hoàn tất, trust_score >= 0.6, risk_level <= MEDIUM. |
| `evaluated_warning` | ML evaluation hoàn tất, có cảnh báo nhưng không nghiêm trọng. |
| `evaluated_risky` | ML evaluation hoàn tất, risk_level HIGH hoặc CRITICAL. |
| `evaluation_failed` | ML Service không phản hồi hoặc lỗi. |

---

## 4. Dữ liệu đầu vào và đầu ra

### 4.1. Dữ liệu đầu vào

**Dữ liệu chiến dịch (từ bảng `chien_dichs`):**

- ID, `tieu_de`, `mo_ta`, `anh_bia`, `dia_diem`.
- `vi_do`, `kinh_do`, `khu_vuc_id`, `loai_chien_dich_id`.
- `ngay_bat_dau`, `ngay_ket_thuc`, `han_dang_ky`.
- `so_luong_toi_da`, `so_luong_toi_thieu`.
- `muc_do_uu_tien`, `trang_thai`.
- `so_dang_ky`, `so_xac_nhan`.
- `nguoi_tao_id`, `tao_luc`.

**Dữ liệu người tạo (từ bảng `nguoi_dungs` + relations):**

- ID, `ho_ten`, `email`, `anh_dai_dien`, `gioi_thieu`.
- `vai_tro`, `trang_thai`, `xac_thuc_email_luc`.
- `tinh_thanh_id`, `phuong_xa_id`, `vi_do`, `kinh_do`.
- `khung_gio_uu_tien`, `so_dien_thoai`.
- Relation: `ky_nangs`, `chung_chis`, `kinh_nghiems`, `dangKyThamGias`, `danhGiaTnvs`, `baoCaoChienDichs`.

**Dữ liệu đăng ký (từ bảng `dang_ky_tham_gias`):**

- Số lượng đăng ký theo trạng thái, tỷ lệ hủy, tỷ lệ hoàn thành.

**Dữ liệu đánh giá (từ bảng `danh_gia_tnv`):**

- Điểm đánh giá TNV đã nhận, số lượt đánh giá.

**Dữ liệu báo cáo (từ bảng `bao_cao_chien_dich`):**

- Số lượng báo cáo, trạng thái báo cáo, nội dung báo cáo.

**Dữ liệu lịch sử kiểm duyệt (từ bảng `lich_su_kiem_duyet_chien_dichs`):**

- Số lần duyệt, từ chối, yêu cầu bổ sung.

**Dữ liệu feedback (từ bảng `phan_hoi_tnv`):**

- Nội dung phản hồi, điểm sao.

### 4.2. Đầu ra của mô-đun (API Response)

**Campaign Evaluation Response:**

```json
{
  "campaign_id": 42,
  "evaluation_timestamp": "2026-04-11T10:30:00Z",
  "evaluation_source": "ml_service",

  "validation_result": {
    "passed": true,
    "critical_errors": [],
    "warnings": [
      {
        "code": "NO_COVER_IMAGE",
        "severity": "LOW",
        "field": "anh_bia",
        "message": "Chiến dịch không có ảnh bìa",
        "suggestion": "Yêu cầu người tạo bổ sung ảnh bìa để tăng độ tin cậy"
      }
    ]
  },

  "trust_score": {
    "raw_score": 0.72,
    "calibrated_probability": 0.78,
    "label": "RELIABLE",
    "confidence": "HIGH"
  },

  "volunteer_trust_score": {
    "raw_score": 0.65,
    "calibrated_probability": 0.67,
    "label": "RELIABLE",
    "confidence": "MEDIUM"
  },

  "risk_assessment": {
    "overall_risk_level": "LOW",
    "risk_score": 0.22,
    "flags": [
      {
        "code": "NO_COVER_IMAGE",
        "severity": "LOW",
        "category": "INFORMATION_COMPLETENESS",
        "message": "Chiến dịch không có ảnh bìa",
        "suggestion": "Yêu cầu người tạo bổ sung ảnh bìa để tăng độ tin cậy",
        "auto_resolvable": true
      },
      {
        "code": "CREATOR_NEW_ACCOUNT",
        "severity": "MEDIUM",
        "category": "CREATOR_RELIABILITY",
        "message": "Tài khoản người tạo mới tạo (5 ngày)",
        "suggestion": "Kiểm tra kỹ thông tin chiến dịch, yêu cầu bổ sung giấy tờ minh chứng",
        "auto_resolvable": false
      },
      {
        "code": "SHORT_REGISTRATION_WINDOW",
        "severity": "LOW",
        "category": "SCHEDULE_REASONABLENESS",
        "message": "Thời hạn đăng ký chỉ còn 2 ngày",
        "suggestion": "Xem xét gia hạn để thu hút thêm TNV",
        "auto_resolvable": false
      }
    ],
    "anomaly_score": -0.15,
    "is_anomaly": false,
    "anomaly_types": []
  },

  "content_analysis": {
    "text_risk_keyword_count": 0,
    "text_risk_score": 0.05,
    "vagueness_score": 0.2,
    "safety_description_score": 0.0,
    "risk_keywords_found": []
  },

  "decision_support": {
    "recommended_action": "APPROVE_WITH_NOTE",
    "confidence": "HIGH",
    "reason": "Chiến dịch có thông tin đầy đủ, người tạo có lịch sử hoạt động tốt trong hệ thống",
    "questions_to_verify": [
      "Xác nhận địa điểm chi tiết với người tạo",
      "Kiểm tra giấy phép/quyền tổ chức nếu là hoạt động chính thức"
    ]
  },

  "shap_explanation": {
    "base_value": 0.50,
    "prediction": 0.72,
    "top_positive_factors": [
      {
        "feature": "creator_has_verified_email",
        "feature_display_name": "Email đã xác thực",
        "contribution": 0.08,
        "value": true,
        "value_display": "Có"
      },
      {
        "feature": "creator_avg_rating",
        "feature_display_name": "Điểm đánh giá trung bình",
        "contribution": 0.06,
        "value": 4.5,
        "value_display": "4.5 / 5.0"
      },
      {
        "feature": "description_length",
        "feature_display_name": "Độ dài mô tả",
        "contribution": 0.05,
        "value": 850,
        "value_display": "850 từ"
      }
    ],
    "top_negative_factors": [
      {
        "feature": "creator_account_age_days",
        "feature_display_name": "Tuổi tài khoản",
        "contribution": -0.04,
        "value": 5,
        "value_display": "5 ngày"
      },
      {
        "feature": "missing_location_coords",
        "feature_display_name": "Thiếu tọa độ địa điểm",
        "contribution": -0.03,
        "value": false,
        "value_display": "Có tọa độ"
      }
    ],
    "feature_importance": [
      {"name": "creator_reliability_score", "display_name": "Điểm uy tín người tạo", "importance": 0.28},
      {"name": "campaign_completeness", "display_name": "Mức độ hoàn thiện chiến dịch", "importance": 0.22},
      {"name": "temporal_patterns", "display_name": "Mẫu thời gian", "importance": 0.15},
      {"name": "text_anomaly_score", "display_name": "Điểm bất thường văn bản", "importance": 0.12},
      {"name": "location_quality", "display_name": "Chất lượng địa điểm", "importance": 0.08}
    ]
  },

  "model_info": {
    "campaign_model_version": "campaign_trust_v2.3.1",
    "campaign_training_date": "2026-04-01",
    "campaign_training_samples": 4521,
    "campaign_calibration_method": "isotonic",
    "campaign_mlflow_run_id": "a1b2c3d4-e5f6-7890",
    "volunteer_model_version": "volunteer_trust_v1.2.0",
    "anomaly_model_version": "campaign_anomaly_v1.0.0"
  }
}
```

**Volunteer Evaluation Response:**

```json
{
  "volunteer_id": 7,
  "evaluation_timestamp": "2026-04-11T10:30:00Z",

  "trust_score": {
    "raw_score": 0.68,
    "calibrated_probability": 0.71,
    "label": "RELIABLE",
    "confidence": "MEDIUM"
  },

  "reliability_summary": {
    "total_registrations": 15,
    "cancelled_registrations": 2,
    "cancellation_rate": 0.13,
    "completion_rate": 0.87,
    "avg_rating_received": 4.3,
    "rating_count": 12
  },

  "behavior_flags": [
    {
      "code": "NEW_ACCOUNT",
      "severity": "LOW",
      "message": "Tài khoản mới tạo (5 ngày)",
      "suggestion": "Theo dõi hoạt động trong 30 ngày đầu"
    },
    {
      "code": "PERFECT_RATING",
      "severity": "LOW",
      "message": "Tất cả đánh giá đều là 5 sao (có thể không tự nhiên)",
      "suggestion": "Kiểm tra nội dung đánh giá chi tiết"
    }
  ]
}
```

**Batch Evaluation Response:**

```json
{
  "batch_id": "batch_20260411_001",
  "submitted_at": "2026-04-11T10:00:00Z",
  "completed_at": "2026-04-11T10:05:23Z",
  "total": 50,
  "succeeded": 48,
  "failed": 2,
  "results": [
    {
      "campaign_id": 42,
      "status": "success",
      "evaluation": { "...campaign evaluation object..." }
    },
    {
      "campaign_id": 43,
      "status": "error",
      "error": "Campaign not found"
    }
  ]
}
```

### 4.3. Decision Logic

Bảng quyết định để sinh `recommended_action`:

| Trust Score | Risk Level | Anomaly | Text Risk | Recommended Action |
|---|---|---|---|---|
| >= 0.70 | LOW | false | < 0.2 | **APPROVE** |
| >= 0.70 | LOW | false | >= 0.2 | **APPROVE_WITH_NOTE** |
| >= 0.60 | LOW/MEDIUM | false | any | **APPROVE_WITH_NOTE** |
| >= 0.60 | HIGH/CRITICAL | true | any | **REQUEST_ADDITIONAL_INFO** |
| 0.40–0.59 | LOW | false | < 0.3 | **REQUEST_ADDITIONAL_INFO** |
| 0.40–0.59 | MEDIUM | any | any | **REQUEST_ADDITIONAL_INFO** |
| 0.40–0.59 | HIGH/CRITICAL | any | any | **REJECT** |
| < 0.40 | any | any | any | **REJECT** |

---

## 5. Kiến trúc hệ thống

### 5.1. Tổng quan Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Vue 3 Frontend                        │
│     KDV Dashboard: Chi tiết chiến dịch + Risk Assessment     │
│     Panel + SHAP Explanation + Decision Support              │
└────────────────────────────┬─────────────────────────────────┘
                             │ HTTP/REST
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                    Laravel 12 Backend API                      │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │         TrustScoreService (Gateway / Sidecar)           │ │
│  │  • Gọi Python ML Service qua HTTP                        │ │
│  │  • Cache kết quả (Redis hoặc DB)                         │ │
│  │  • Fallback rule-based khi ML down                       │ │
│  │  • Invalidate cache khi campaign/user update            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐│
│  │              MLflow Tracking Server (localhost:5000)       ││
│  │  • Experiment tracking                                    ││
│  │  • Model registry & versioning                          ││
│  │  • Metrics logging                                      ││
│  └──────────────────────────────────────────────────────────┘│
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐│
│  │                    MySQL Database (shared)                         ││
│  │  Tables: campaign_evaluations, volunteer_evaluations     ││
│  │  Existing: chien_dichs, nguoi_dungs, dang_ky_tham_gias,   ││
│  │            danh_gia_tnv, bao_cao_chien_dich,              ││
│  │            lich_su_kiem_duyet_chien_dichs                 ││
│  └──────────────────────────────────────────────────────────┘│
└────────────────────────────┬─────────────────────────────────┘
                             │ HTTP (internal network)
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                  Python FastAPI ML Service                    │
│                      Port: 8001                               │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐│
│  │ Campaign     │  │ Volunteer    │  │ Anomaly Detection   ││
│  │ Trust API    │  │ Trust API    │  │ API                 ││
│  │ (LightGBM)   │  │ (LightGBM)   │  │ (Isolation Forest)  ││
│  └──────┬───────┘  └──────┬───────┘  └──────────┬─────────┘│
│         │                  │                       │          │
│  ┌──────▼─────────────────▼───────────────────────▼─────────┐│
│  │              Feature Engineering Pipeline                  ││
│  │  • CampaignFeatureExtractor                               ││
│  │  • VolunteerFeatureExtractor                             ││
│  │  • ContentAnalyzer (NLP)                                 ││
│  └─────────────────────────┬───────────────────────────────┘│
│                            │                                 │
│  ┌─────────────────────────▼───────────────────────────────┐│
│  │              MLflow (MlflowClient)                        ││
│  │  • Log parameters, metrics, artifacts                     ││
│  │  • Model registration                                     ││
│  └──────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

### 5.2. Cấu trúc thư mục Python ML Service

```
trust-eval-service/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI app entry point
│   ├── config.py                  # Settings, env vars, config
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/
│   │   │   ├── __init__.py
│   │   │   ├── campaign.py        # POST /evaluate/campaign/{id}
│   │   │   ├── volunteer.py       # POST /evaluate/volunteer/{id}
│   │   │   ├── batch.py          # POST /evaluate/batch/campaigns
│   │   │   ├── train.py          # POST /train/campaigns, GET /train/summary
│   │   │   ├── monitoring.py      # GET /monitoring, /agreement-stats, /alerts, /drift-check
│   │   │   └── health.py          # GET /health, GET /model/info
│   │   └── deps.py                # Dependencies (DB connection, model loader)
│   │
│   ├── core/
│   │   ├── __init__.py
│   │   ├── database.py            # MySQL connection via mysql-connector-python + queries
│   │   ├── feature_extractor.py   # Feature extraction logic
│   │   ├── decision_logic.py      # recommended_action logic
│   │   ├── rule_validator.py      # Rule-based validation (10 rules)
│   │   ├── risk_keywords.py       # Risk keyword dictionary
│   │   ├── cache.py               # TTLCache (LRU+TTL), BatchInferenceOptimizer
│   │   ├── monitor.py             # MLMonitor (agreement rate, PSI drift detection)
│   │   └── security.py            # RateLimiter, InternalAuth, InputSanitizer
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── schemas.py             # Pydantic request/response models
│   │   ├── ml_models.py           # Model loading & inference
│   │   ├── calibration.py         # Probability calibration
│   │   └── anomaly.py             # Isolation Forest logic
│   │
│   ├── ml/
│   │   ├── __init__.py
│   │   ├── feature_engineering.py  # Feature engineering pipeline
│   │   ├── content_analyzer.py    # NLP / keyword detection
│   │   ├── content_risk_classifier.py  # TF-IDF + Logistic Regression
│   │   ├── shap_explainer.py      # SHAP explanation generation
│   │   └── ensemble.py            # Multi-model ensemble (Voting, Weighted Avg, Stacking)
│   │
│   └── training/
│       ├── __init__.py
│       ├── train_campaign_model.py
│       ├── train_volunteer_model.py
│       ├── train_anomaly_model.py
│       ├── evaluate.py            # Evaluation metrics
│       └── mlflow_tracking.py     # MLflow experiment logging
│
├── models/                        # Saved model artifacts (.pkl, .txt)
│   ├── campaign_trust_v2.3.1/
│   │   ├── model.txt              # LightGBM model
│   │   ├── calibration.pkl
│   │   ├── shap_explainer.pkl
│   │   └── metadata.json
│   ├── volunteer_trust_v1.2.0/
│   │   ├── model.txt
│   │   ├── calibration.pkl
│   │   └── metadata.json
│   └── campaign_anomaly_v1.0.0/
│       ├── model.pkl
│       └── metadata.json
│
├── scripts/
│   ├── scheduled_retrain.py      # Scheduled cron retraining
│   └── ab_test.py                # A/B testing framework
│
├── training/
│   ├── data/
│   │   ├── raw/                   # Raw data from Laravel DB
│   │   ├── processed/             # Feature-engineered data
│   │   └── labels/                # Labeled training data
│   ├── notebooks/
│   │   ├── 01_data_exploration.ipynb
│   │   ├── 02_feature_engineering.ipynb
│   │   ├── 03_model_training.ipynb
│   │   ├── 04_calibration.ipynb
│   │   └── 05_evaluation.ipynb
│   └── scripts/
│       ├── retrain_campaign.sh
│       ├── retrain_all.sh
│       └── generate_training_data.py
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_decision_logic.py
│   ├── test_rule_validator.py
│   ├── test_content_analyzer.py
│   ├── test_feature_extraction.py
│   └── test_anomaly.py
│
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── DEPLOYMENT.md
└── README.md
```

**requirements.txt:**

```txt
# FastAPI & Web
fastapi==0.115.0
uvicorn[standard]==0.30.0
pydantic==2.9.0
pydantic-settings==2.5.0

# Database (MySQL shared với Laravel)
mysql-connector-python==8.4.0
# Hoặc async: aiomysql==0.2.0

# ML
lightgbm==4.4.0
scikit-learn==1.5.0
pandas==2.2.0
numpy==1.26.0

# Explainability
shap==0.45.0

# Experiment Tracking
mlflow==2.16.0

# NLP
scikit-learn # TF-IDF + Logistic Regression (đã có ở trên)

# Utilities
python-dotenv==1.0.0
httpx==0.27.0
joblib==1.4.0
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  ml-service:
    build: .
    container_name: trust-eval-service
    ports:
      - "8001:8001"
    env_file:
      - .env
    volumes:
      - ./models:/app/models:ro
      - ./logs:/app/logs
    depends_on:
      - mlflow
    restart: unless-stopped
    networks:
      - trust-eval-network

  mlflow:
    image: ghcr.io/mlflow/mlflow:latest
    container_name: mlflow-server
    ports:
      - "5000:5000"
    command: mlflow server --host 0.0.0.0 --port 5000 --backend-store-uri sqlite:///mlflow.db --default-artifact-root ./artifacts
    # MLflow backend-store dùng SQLite (local file, không phải shared MySQL với Laravel)
    volumes:
      - mlflow-data:/mlflow
    restart: unless-stopped
    networks:
      - trust-eval-network

volumes:
  mlflow-data:

networks:
  trust-eval-network:
    driver: bridge
```

### 5.3. Cấu trúc thư mục Laravel Integration

```
Backend/
├── app/
│   ├── Services/
│   │   └── TrustScoreService.php   # ML Gateway Service (NEW)
│   │
│   ├── Http/Controllers/
│   │   └── Api/
│   │       └── TrustEvalController.php  # API endpoint wrapper (NEW)
│   │
│   └── Models/
│       ├── CampaignEvaluation.php   # NEW
│       └── VolunteerEvaluation.php  # NEW
│
├── database/
│   └── migrations/
│       ├── xxxx_create_campaign_evaluations_table.php   # NEW
│       └── xxxx_create_volunteer_evaluations_table.php   # NEW
│
├── config/
│   └── services.php                # Thêm ml_trust config
│
└── routes/
    └── api.php                     # Thêm ML eval endpoints
```

---

## 6. API Endpoints

### 6.1. ML Service (Python FastAPI)

**Base URL:** `http://localhost:8001/api/v1`

| Method | Endpoint | Mô tả |
|---|---|---|
| POST | `/evaluate/campaign/{id}` | Đánh giá độ tin cậy + rủi ro chiến dịch |
| POST | `/evaluate/volunteer/{id}` | Đánh giá độ tin cậy hành vi TNV |
| POST | `/evaluate/batch/campaigns` | Batch evaluate nhiều campaigns |
| GET | `/health` | Health check (model loaded?, DB accessible?) |
| GET | `/model/info` | Model version, training date, metadata |
| GET | `/model/feature-importance` | Feature importance summary |

### 6.2. Laravel API (Gateway)

| Method | Endpoint | Mô tả | Quyền |
|---|---|---|---|
| GET | `/api/trust-eval/campaign/{id}` | Lấy evaluation hiện tại (từ cache/DB) | `kiemDuyetVien` |
| POST | `/api/trust-eval/campaign/{id}/refresh` | Trigger re-evaluation từ ML Service | `kiemDuyetVien` |
| GET | `/api/trust-eval/volunteer/{id}` | Lấy evaluation TNV | `kiemDuyetVien` |
| GET | `/api/trust-eval/campaigns/pending` | Danh sách campaigns chưa được evaluate | `quanTriVien` |
| GET | `/api/trust-eval/statistics` | Thống kê evaluation (avg score, flag distribution) | `quanTriVien` |

---

## 7. Database Schema

### 7.1. Bảng `campaign_evaluations` (NEW)

```sql
CREATE TABLE campaign_evaluations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    chien_dich_id BIGINT UNSIGNED NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    evaluation_source ENUM('ml_service', 'fallback') DEFAULT 'ml_service',

    -- Trust Score
    trust_score_raw DECIMAL(5,4) NULL,
    trust_score_calibrated DECIMAL(5,4) NULL,
    trust_label VARCHAR(30) NULL,
    trust_confidence VARCHAR(20) NULL,

    -- Volunteer Trust
    volunteer_trust_score DECIMAL(5,4) NULL,
    volunteer_trust_label VARCHAR(30) NULL,

    -- Risk Assessment
    risk_level ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NULL,
    risk_score DECIMAL(5,4) NULL,
    anomaly_score DECIMAL(6,4) NULL,
    is_anomaly BOOLEAN DEFAULT FALSE,

    -- Flags & Analysis
    risk_flags JSON NULL,
    content_analysis JSON NULL,
    anomaly_types JSON NULL,

    -- Decision Support
    recommended_action VARCHAR(50) NULL,
    decision_confidence VARCHAR(20) NULL,
    decision_reason TEXT NULL,
    questions_to_verify JSON NULL,

    -- SHAP
    shap_summary JSON NULL,

    -- Metadata
    evaluated_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_chien_dich_id (chien_dich_id),
    INDEX idx_trust_label (trust_label),
    INDEX idx_risk_level (risk_level),
    INDEX idx_evaluated_at (evaluated_at),
    INDEX idx_model_version (model_version),
    FOREIGN KEY (chien_dich_id) REFERENCES chien_dichs(id) ON DELETE CASCADE
);
```

### 7.2. Bảng `volunteer_evaluations` (NEW)

```sql
CREATE TABLE volunteer_evaluations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nguoi_dung_id BIGINT UNSIGNED NOT NULL,
    model_version VARCHAR(50) NOT NULL,

    trust_score_raw DECIMAL(5,4) NULL,
    trust_score_calibrated DECIMAL(5,4) NULL,
    trust_label VARCHAR(30) NULL,
    trust_confidence VARCHAR(20) NULL,

    reliability_summary JSON NULL,
    behavior_flags JSON NULL,
    shap_summary JSON NULL,

    evaluated_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_nguoi_dung_id (nguoi_dung_id),
    INDEX idx_trust_label (trust_label),
    INDEX idx_evaluated_at (evaluated_at),
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dungs(id) ON DELETE CASCADE
);
```

### 7.3. Bảng `evaluation_training_labels` (NEW — cho feedback loop)

```sql
CREATE TABLE evaluation_training_labels (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    chien_dich_id BIGINT UNSIGNED NOT NULL,
    evaluation_id BIGINT UNSIGNED NOT NULL,
    kdv_id BIGINT UNSIGNED NOT NULL,

    -- KDV decision
    kdv_action ENUM('approve', 'approve_with_note', 'request_info', 'reject') NOT NULL,
    kdv_reason TEXT NULL,

    -- ML original prediction
    ml_trust_score DECIMAL(5,4) NULL,
    ml_risk_level VARCHAR(20) NULL,
    ml_recommended_action VARCHAR(50) NULL,

    -- Comparison
    ml_agree_with_kdv BOOLEAN NULL,

    -- Feedback quality tracking
    kdv_satisfied_with_ml BOOLEAN NULL,
    kdv_overridden_ml BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_chien_dich_id (chien_dich_id),
    INDEX idx_kdv_id (kdv_id),
    INDEX idx_kdv_action (kdv_action),
    INDEX idx_ml_agree (ml_agree_with_kdv),
    FOREIGN KEY (chien_dich_id) REFERENCES chien_dichs(id) ON DELETE CASCADE,
    FOREIGN KEY (evaluation_id) REFERENCES campaign_evaluations(id) ON DELETE CASCADE,
    FOREIGN KEY (kdv_id) REFERENCES nguoi_dungs(id)
);
```

---

## 8. Caching Strategy

### 8.1. Cache Layers

| Cache Key Pattern | TTL | Invalidation Trigger |
|---|---|---|
| `campaign_evaluation:{id}` | 1 giờ | Campaign update, new registration, new report |
| `campaign_evaluation:{id}:force` | — | Manual refresh by KDV |
| `volunteer_evaluation:{id}` | 6 giờ | Volunteer profile update, new registration |
| `campaign_batch:{batch_id}` | 24 giờ | — |
| `ml_service_health` | 5 phút | — |

### 8.2. Cache Invalidation Events

- Khi `ChienDich` được tạo/cập nhật → invalidate `campaign_evaluation:{id}`.
- Khi `DangKyThamGia` được tạo/hủy → invalidate `campaign_evaluation:{id}` + `volunteer_evaluation:{nguoi_dung_id}`.
- Khi `BaoCaoChienDich` được tạo → invalidate `campaign_evaluation:{id}`.
- Khi `NguoiDung` được cập nhật → invalidate `volunteer_evaluation:{id}` + tất cả `campaign_evaluation` mà user đó là `nguoi_tao_id`.

---

## 9. Fallback Strategy

Khi Python ML Service không khả dụng (down, timeout, error), hệ thống tự động fallback sang rule-based scoring để đảm bảo KDV vẫn có thể xem và duyệt chiến dịch.

### 9.1. Fallback Rule-based Campaign Scoring

```
base_score = 0.5

IF has_cover_image:             +0.05
IF has_location_coords:         +0.10
IF has_registration_deadline:   +0.08
IF has_contact_info:            +0.05
IF creator_has_verified_email:  +0.08
IF creator_has_avatar:          +0.03
IF creator_campaign_count > 0:  +0.05
IF creator_campaign_count > 10: +0.10
IF creator_avg_rating >= 4.0:   +0.10
IF creator_cancellation_rate < 0.1: +0.05
IF description_length > 200:    +0.05
IF has_min_volunteers_met:      +0.05

IF no_cover_image:               -0.05
IF missing_location_coords:     -0.10
IF no_registration_deadline:    -0.08
IF creator_is_new:              -0.10
IF creator_cancellation_rate > 0.3: -0.15
IF creator_report_count > 0:    -0.10
IF text_risk_keywords > 0:      -0.10
```

### 9.2. Fallback Decision Mapping

| Fallback Score | Risk Level | Recommended Action |
|---|---|---|
| >= 0.70 | LOW | APPROVE |
| 0.50–0.69 | MEDIUM | APPROVE_WITH_NOTE |
| 0.30–0.49 | HIGH | REQUEST_ADDITIONAL_INFO |
| < 0.30 | CRITICAL | REJECT |

---

## 10. Monitoring & Observability

### 10.1. Metrics cần theo dõi

**ML Service:**

- Request latency (p50, p95, p99).
- Model inference time.
- Error rate by endpoint.
- Feature extraction time breakdown.
- Cache hit/miss ratio.

**Model Quality:**

- AUC-ROC, Precision, Recall, F1 trên test set.
- Expected Calibration Error (ECE).
- ML agreement rate với KDV decisions.
- False positive rate (reliable bị đánh flag HIGH).
- False negative rate (risky bị pass qua).

**Business:**

- Số evaluation theo ngày/tuần/tháng.
- Phân bố `recommended_action`.
- Phân bố `risk_level`.
- Top frequent `risk_flags`.
- Average time từ evaluation đến KDV decision.

### 10.2. MLflow Experiments

Mỗi model version cần log:

- Parameters (hyperparameters, training config).
- Training metrics (AUC, loss, calibration error).
- Validation metrics.
- Feature importance (top 20 features).
- Test set performance.
- Training date, sample count.
- Git commit hash.

Model registry: mỗi lần retrain, tạo new version trong registry. Production model được promote qua API sau khi validate offline.

---

## 11. Phased Implementation Plan

### Phase 1: Infrastructure & Core (Tuần 1–2)

- [x] Setup Python FastAPI project structure.
- [x] Configure MySQL connection từ Python (mysql-connector-python hoặc aiomysql).
- [ ] Setup read-only MySQL user cho ML Service (để tránh accidental writes). **Thao tác thủ công - chạy SQL script bên dưới.**
- [x] Implement Pydantic schemas cho request/response.
- [x] Setup MLflow tracking server (docker-compose).
- [x] Viết database migrations cho Laravel (`campaign_evaluations`, `volunteer_evaluations`).
- [x] Tạo `TrustScoreService.php` (Laravel Gateway) với fallback rule-based.
- [x] Implement rule-based campaign scoring (để test fallback ngay).
- [x] FastAPI health check + basic endpoints.

**SQL Script - Chạy trên MySQL để tạo read-only user cho ML Service:**
```sql
CREATE USER 'trust_evaluator'@'%' IDENTIFIED BY 'your_secure_password';
GRANT SELECT ON volunteer_management.* TO 'trust_evaluator'@'%';
FLUSH PRIVILEGES;
```

### Phase 2: Feature Engineering & Rule-based Validation (Tuần 3–4)

- [x] Implement `CampaignFeatureExtractor` (campaign features).
- [x] Implement `VolunteerFeatureExtractor` (volunteer features).
- [x] Implement Rule-based Validation (Pydantic validation layer).
- [x] Implement Risk Keyword Dictionary + detection.
- [x] Implement `ContentAnalyzer` (text quality scoring).
- [x] Implement Isolation Forest anomaly detection.
- [x] FastAPI full endpoints (`/evaluate/campaign`, `/evaluate/volunteer`).
- [x] Integration: Laravel → ML Service → store results → cache.

### Phase 3: ML Model Training (Tuần 5–7)

- [x] Generate training data từ existing campaigns.
- [x] Label training data (manual labeling hoặc từ KDV decisions).
- [x] Train LightGBM campaign trust model.
- [x] Train LightGBM volunteer trust model.
- [x] Implement probability calibration (Isotonic Regression).
- [x] Evaluate: AUC-ROC, ECE, feature importance.
- [x] Log to MLflow: parameters, metrics, model artifacts.
- [x] Register model versions in MLflow model registry.

### Phase 4: SHAP & Explainability (Tuần 8)

- [x] Implement `SHAPExplainer` với TreeExplainer.
- [x] Generate per-evaluation SHAP explanations.
- [x] Summarize SHAP values for API response.
- [x] Batch evaluation endpoint.

### Phase 5: Frontend Integration (Tuần 9–10)

- [x] Risk Assessment Panel component (Vue 3) — `TrustEvalPanel.vue` với trust score circle, risk assessment, validation result, content analysis.
- [x] SHAP explanation visualization — `SHAPExplanation.vue` với bar chart cho positive/negative factors, base value marker, prediction marker.
- [x] Risk flags display với severity coloring — `RiskFlagsPanel.vue` + `RiskFlagRow.vue` với LOW/MEDIUM/HIGH/CRITICAL coloring.
- [x] Decision support widget (recommended action + reason) — `DecisionSupport.vue` với action badge, confidence dots, reason, questions to verify.
- [x] KDV can request re-evaluation — nút "Đánh giá lại" (refresh) trong `TrustEvalPanel.vue`, gọi `POST /trust-eval/campaign/:id/refresh`.
- [x] Notification when evaluation is ready — notification banner trong `TrustEvalPanel.vue` sau khi refresh thành công.
- [x] Admin statistics dashboard — `TrustEvalDashboard.vue` với KPIs, risk/trust/action distribution, evaluation source, recent high-risk table.

**Frontend Files Created:**
- `Frontend/src/services/trustEvalTypes.js` — TypeScript/JSDoc types matching backend schemas
- `Frontend/src/services/trustEvalApi.js` — API client wrapping Laravel TrustEvalController
- `Frontend/src/components/Admin/TrustEval/TrustEvalPanel.vue` — Main campaign evaluation panel
- `Frontend/src/components/Admin/TrustEval/SHAPExplanation.vue` — SHAP visualization
- `Frontend/src/components/Admin/TrustEval/DecisionSupport.vue` — Decision widget
- `Frontend/src/components/Admin/TrustEval/RiskFlagsPanel.vue` — Risk flags with severity
- `Frontend/src/components/Admin/TrustEval/RiskFlagRow.vue` — Individual risk flag row
- `Frontend/src/components/Admin/TrustEval/VolunteerTrustPanel.vue` — Volunteer evaluation panel
- `Frontend/src/components/Admin/TrustEval/TrustEvalDashboard.vue` — Admin statistics dashboard

**Frontend Routes:**
- `/admin/trust-eval/dashboard` — TrustEvalDashboard.vue (statistics)

**Frontend Integrations:**
- `TrustEvalPanel` embedded in KDV campaign detail modal (`Quan_Ly_Chien_Dich.vue`)
- Admin sidebar link to `/admin/trust-eval/dashboard` (`Bo_Cuc_Admin.vue`)
- i18n translations added (`vi.js`, `en.js`)

### Phase 6: Production Hardening (Tuần 11–12)

- [x] Model retraining pipeline (scheduled cron job).
- [x] A/B testing framework cho model versions.
- [x] Comprehensive test suite.
- [x] Performance optimization (batch inference, caching).
- [x] Documentation (API docs, deployment guide).
- [x] Security hardening (internal API authentication).

**Files created:**

- `trust-eval-service/scripts/scheduled_retrain.py` — Scheduled cron retraining với auto-promote, preconditions check, comparison với current model, và MLflow logging.
- `trust-eval-service/scripts/ab_test.py` — A/B testing framework với traffic allocation, incremental metrics tracking, statistical comparison, và promote winner.
- `trust-eval-service/tests/conftest.py` — Pytest fixtures (sample_campaign, sample_creator, suspicious_campaign, mock_db_cursor).
- `trust-eval-service/tests/test_decision_logic.py` — Tests cho bảng quyết định 8 rows (APPROVE, APPROVE_WITH_NOTE, REQUEST_ADDITIONAL_INFO, REJECT).
- `trust-eval-service/tests/test_rule_validator.py` — Tests cho tất cả rules (title, description, location, coords, schedule, registration, counts, creator, type).
- `trust-eval-service/tests/test_content_analyzer.py` — Tests cho risk keyword detection, vagueness scoring, safety description scoring.
- `trust-eval-service/tests/test_feature_extraction.py` — Tests cho CampaignFeatureExtractor.
- `trust-eval-service/tests/test_anomaly.py` — Tests cho AnomalyDetector (Isolation Forest).
- `trust-eval-service/app/core/cache.py` — TTLCache (LRU + TTL), BatchInferenceOptimizer, cache decorators, cache utilities.
- `trust-eval-service/app/core/security.py` — RateLimiter (token bucket), InternalAuth (HMAC key validation), InputSanitizer, security middleware, audit logging.
- `trust-eval-service/DEPLOYMENT.md` — Complete deployment guide: Docker setup, env config, cron job, A/B testing, tests, monitoring, troubleshooting, security checklist.

### Phase 7: Continuous Improvement (Tuần 13–14)

- [x] Retrain models với KDV feedback (weekly/monthly).
- [x] Monitor ML agreement rate, adjust thresholds.
- [x] Expand feature set dựa trên SHAP importance.
- [x] Consider TF-IDF + Logistic Regression cho content risk (Phase 2 NLP).
- [x] Consider ensemble methods nếu single model không đủ.

**Files created:**

- `Backend/database/migrations/2026_04_12_000001_create_kdv_feedback_table.php` — Lưu KDV feedback: override, agree, disagree, correct_action, ml_action_correct, final_trust_label_override.
- `Backend/database/migrations/2026_04_12_000002_add_kdv_tracking_to_campaign_evaluations.php` — Tracking KDV decision: kdv_final_action, kdv_final_trust_label, ml_agreement.
- `Backend/app/Models/KdvFeedback.php` — Eloquent model cho KDV feedback.
- `Backend/app/Http/Controllers/KdvFeedbackController.php` — API endpoints: POST /feedback, GET /feedback, GET /agreement-stats.
- `Backend/routes/api.php` — Routes cho KDV feedback endpoints.
- `trust-eval-service/app/core/monitor.py` — MLMonitor class: AgreementStats (total, by_action, weekly_trend), DriftDetection (PSI-based), performance alerts.
- `trust-eval-service/app/api/routes/monitoring.py` — Monitoring API: GET /monitoring, GET /monitoring/agreement-stats, GET /monitoring/alerts, GET /monitoring/drift-check.
- `trust-eval-service/app/ml/content_risk_classifier.py` — ContentRiskClassifier: TF-IDF + Logistic Regression, hybrid scoring với keyword rules, confidence computation.
- `trust-eval-service/app/ml/ensemble.py` — CampaignTrustEnsemble: Voting, Weighted Average, Stacking, Best Performance strategies, multi-model prediction aggregation (LightGBM primary/secondary, rule-based, anomaly, content risk).

---

## 12. Công nghệ chi tiết

| Thành phần | Công nghệ | Phiên bản | Vai trò |
|---|---|---|---|
| **ML Service Framework** | FastAPI | latest | REST API server, async, Pydantic validation |
| **Data Validation** | Pydantic | v2 | Input/output validation, serialization |
| **Data Processing** | pandas | latest | Feature engineering, data manipulation |
| **ML Models** | LightGBM | v4.4.0 | Trust scoring, risk scoring |
| **Anomaly Detection** | scikit-learn (IsolationForest) | latest | Unsupervised outlier detection |
| **Calibration** | scikit-learn (CalibratedClassifierCV) | latest | Probability calibration |
| **Explainability** | SHAP | latest | Model interpretation, feature contribution |
| **Experiment Tracking** | MLflow | latest | Model versioning, metrics, artifacts |
| **NLP** | TF-IDF + Logistic Regression (hoặc keyword dict) | — | Content risk analysis |
| **Model Serialization** | LightGBM native (.txt) + joblib | — | Model persistence |
| **Database (Python)** | MySQL + mysql-connector-python / aiomysql | — | Direct read (readonly) cho feature extraction |
| **Database (Laravel)** | MySQL | — | Existing backend DB, shared với Python ML Service |
| **MySQL User (ML)** | MySQL | — | User `trust_evaluator` với quyền SELECT only |
| **Caching** | Laravel Cache (Redis/DB) | — | API response caching |
| **Containerization** | Docker + docker-compose | — | ML Service deployment |

---

## 13. Environment Variables

### ML Service (.env)

```env
APP_ENV=development
APP_DEBUG=true
APP_HOST=0.0.0.0
APP_PORT=8001

# MySQL Database (shared với Laravel, read-only access)
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=volunteer_management
DB_USERNAME=trust_evaluator
DB_PASSWORD=your_secure_password
DB_CHARSET=utf8mb4

# MLflow
MLFLOW_TRACKING_URI=http://localhost:5000
MLFLOW_EXPERIMENT_NAME=campaign-trust-evaluation
MLFLOW_MODEL_REGISTRY=campaign-trust-models

# Model paths
CAMPAIGN_MODEL_PATH=./models/campaign_trust_v2.3.1
VOLUNTEER_MODEL_PATH=./models/volunteer_trust_v1.2.0
ANOMALY_MODEL_PATH=./models/campaign_anomaly_v1.0.0

# Logging
LOG_LEVEL=INFO
LOG_FILE=./logs/app.log

# Internal API key (cho authentication với Laravel)
INTERNAL_API_KEY=your_internal_api_key
LARAVEL_API_URL=http://localhost:8000
```

**Lưu ý MySQL:** Tạo một MySQL user riêng `trust_evaluator` với quyền read-only trên database `volunteer_management` để ML Service chỉ đọc dữ liệu, không ghi. Laravel giữ quyền read/write.

```sql
-- Tạo user cho ML Service (read-only)
CREATE USER 'trust_evaluator'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT SELECT ON volunteer_management.* TO 'trust_evaluator'@'localhost';
FLUSH PRIVILEGES;
```

### Laravel (.env / .env.services)

```env
ML_TRUST_SERVICE_URL=http://localhost:8001
ML_TRUST_SERVICE_TIMEOUT=10
ML_TRUST_CACHE_TTL=3600
ML_TRUST_FALLBACK_ENABLED=true
```

---

## 14. Security Considerations

- ML Service chỉ expose trong internal network (localhost/docker network).
- Laravel gọi ML Service qua HTTP nội bộ; không có public endpoint.
- ML Service kết nối MySQL read-only (user `trust_evaluator`) để tránh accidental writes.
- Database MySQL chỉ read-only cho ML Service (user với quyền SELECT duy nhất).
- ML model files được mount vào container từ host hoặc volume.
- API authentication: Internal API key (HMAC, constant-time comparison) bảo vệ training endpoints.
- Rate limiting: Token bucket rate limiter (100 req/min eval, 10 req/min train) chống abuse.
- Input sanitization: InputSanitizer bảo vệ chống injection.
- Security headers: X-Content-Type-Options, X-Frame-Options, HSTS, CSP.
- Audit logging: Security-relevant events (auth failures, rate limits, invalid input) được log.
- CORS restrictive trong production (chỉ cho phép localhost origins).

---

## 15. Tài liệu tham khảo

- FastAPI: https://fastapi.tiangolo.com/
- Pydantic: https://docs.pydantic.dev/latest/concepts/models/
- LightGBM: https://lightgbm.readthedocs.io/en/v4.4.0/Python-API.html
- scikit-learn: https://scikit-learn.org/stable/user_guide.html
- scikit-learn Calibration: https://scikit-learn.org/stable/modules/calibration.html
- Isolation Forest: https://scikit-learn.org/stable/modules/outlier_detection.html
- SHAP: https://shap.readthedocs.io/
- MLflow: https://mlflow.org/docs/latest/ml/tracking.html
