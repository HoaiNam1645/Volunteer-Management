# Hướng dẫn Triển khai Local — Trust & Risk Evaluation Module

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Bước 0 — Yêu cầu hệ thống](#2-bước-0--yêu-cầu-hệ-thống)
3. [Bước 1 — Chạy Migration](#3-bước-1--chạy-migration)
4. [Bước 2 — Setup MySQL User cho ML Service](#4-bước-2--setup-mysql-user-cho-ml-service)
5. [Bước 3 — Cấu hình Environment](#5-bước-3--cấu-hình-environment)
6. [Bước 4 — Train Model với Dữ liệu Thực tế](#6-bước-4--train-model-với-dữ-liệu-thực-tế)
7. [Bước 5 — Chạy ML Service (Local)](#7-bước-5--chạy-ml-service-local)
8. [Bước 6 — Test End-to-End](#8-bước-6--test-end-to-end)

---

## 1. Tổng quan

Mô-đun Trust & Risk Evaluation gồm 2 phần chạy song song:

```
Laravel Backend (port 8000)
    └── HTTP → Python FastAPI ML Service (port 8001)
                    ├── LightGBM models (campaign trust, volunteer trust)
                    ├── Isolation Forest (anomaly detection)
                    ├── SHAP Explainer
                    └── MLflow Tracking Server (port 5000)
```

---

## 2. Bước 0 — Yêu cầu hệ thống

Kiểm tra các công cụ đã cài đặt:

```bash
# Python 3.10+
python --version

# Docker & Docker Compose (nếu dùng Docker)
docker --version
docker-compose --version

# MySQL client (để chạy SQL commands)
mysql --version

# Git
git --version
```

Nếu chưa có, cài đặt:
- **Python**: https://www.python.org/downloads/ (chọn Python 3.10+)
- **MySQL**: https://dev.mysql.com/downloads/mysql/ (Community Server 8.0+)
- **Docker** (tùy chọn): https://docs.docker.com/desktop/

---

## 3. Bước 1 — Chạy Migration

Tạo các bảng mới cho mô-đun trong MySQL.

### 3.1 Kiểm tra MySQL đang chạy

```powershell
# Windows PowerShell
Get-Service *mysql*
```

```bash
# Linux/Mac
sudo systemctl status mysql
# hoặc
brew services list | grep mysql
```

### 3.2 Chạy Migration từ Laravel

```bash
# Di chuyển vào thư mục Backend
cd Backend

# Chạy tất cả migrations (bao gồm 5 bảng mới)
php artisan migrate
```

Kết quả mong đợi — 5 bảng mới được tạo:

| Bảng | Mô tả |
|------|--------|
| `campaign_evaluations` | Lưu kết quả đánh giá chiến dịch |
| `volunteer_evaluations` | Lưu kết quả đánh giá TNV |
| `evaluation_training_labels` | Lưu nhãn training (feedback loop) |
| `kdv_feedback` | Lưu phản hồi KDV về quyết định ML |
| `campaign_evaluation_kdv_tracking` | (đã merge vào `campaign_evaluations`) |

### 3.3 Kiểm tra bảng đã tạo

```sql
-- Kết nối MySQL (thay bằng credentials của bạn)
mysql -u root -p volunteer_management

-- Liệt kê các bảng mới
SHOW TABLES LIKE '%evaluation%';
SHOW TABLES LIKE '%kdv%';

-- Kiểm tra cấu trúc
DESC campaign_evaluations;
DESC kdv_feedback;
```

---

## 4. Bước 2 — Setup MySQL User cho ML Service

ML Service chỉ cần quyền **SELECT** (read-only) để trích xuất features từ database.

### 4.1 Kết nối MySQL với quyền Admin

```bash
mysql -u root -p
```

### 4.2 Tạo User và Grant quyền

```sql
-- Tạo user với password mạnh
CREATE USER 'trust_evaluator'@'localhost' IDENTIFIED BY 'VmsTrust2026!@#';

-- Cấp quyền SELECT trên tất cả các bảng
GRANT SELECT ON volunteer_management.* TO 'trust_evaluator'@'localhost';

-- Nếu ML Service chạy từ container Docker (khác host):
CREATE USER 'trust_evaluator'@'%' IDENTIFIED BY 'VmsTrust2026!@#';
GRANT SELECT ON volunteer_management.* TO 'trust_evaluator'@'%';

-- Áp dụng thay đổi
FLUSH PRIVILEGES;

-- Xác nhận quyền
SHOW GRANTS FOR 'trust_evaluator'@'localhost';
```

> **Lưu ý bảo mật:**
> - Thay `VmsTrust2026!@#` bằng password mạnh thật sự
> - ML Service **không bao giờ** được cấp quyền INSERT/UPDATE/DELETE
> - Laravel giữ quyền read/write bình thường

### 4.3 Test kết nối với user mới

```bash
# Test đăng nhập bằng user mới
mysql -u trust_evaluator -p volunteer_management -e "SELECT 1 AS test;"

# Xác nhận chỉ đọc được, không ghi được
mysql -u trust_evaluator -p volunteer_management -e "INSERT INTO campaign_evaluations (id) VALUES (999);"
# → Lỗi: "INSERT command denied to user" ← Đúng như mong đợi
```

---

## 5. Bước 3 — Cấu hình Environment

### 5.1 Cấu hình Laravel Backend

Mở file `Backend/.env` (hoặc tạo từ `.env.example`):

```env
# ============================
# KẾT NỐI DATABASE (MySQL)
# ============================
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=volunteer_management
DB_USERNAME=root          # Hoặc user có quyền read/write
DB_PASSWORD=your_password

# ============================
# ML TRUST EVALUATION SERVICE
# ============================
ML_TRUST_ENABLED=true
ML_TRUST_SERVICE_URL=http://127.0.0.1:8001
ML_TRUST_TIMEOUT=10
ML_TRUST_CACHE_TTL=3600
ML_TRUST_VOLUNTEER_CACHE_TTL=21600
ML_TRUST_FALLBACK_ENABLED=true
```

### 5.2 Cấu hình Python ML Service

Di chuyển vào thư mục `trust-eval-service`:

```bash
cd trust-eval-service
cp .env.example .env
```

Chỉnh sửa file `.env`:

```env
# ============================
# APP
# ============================
APP_ENV=development
APP_DEBUG=true
APP_HOST=0.0.0.0
APP_PORT=8001

# ============================
# DATABASE (Read-only!)
# ============================
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=volunteer_management
DB_USERNAME=trust_evaluator           # ← User read-only đã tạo ở Bước 2
DB_PASSWORD=VmsTrust2026!@#          # ← Password đã đặt ở Bước 2
DB_CHARSET=utf8mb4

# ============================
# MLFLOW
# ============================
MLFLOW_TRACKING_URI=http://localhost:5000
MLFLOW_EXPERIMENT_NAME=campaign-trust-evaluation
MLFLOW_MODEL_REGISTRY=campaign-trust-models

# ============================
# MODEL PATHS
# ============================
CAMPAIGN_MODEL_PATH=./models/campaign_trust_latest
VOLUNTEER_MODEL_PATH=./models/volunteer_trust_latest
ANOMALY_MODEL_PATH=./models/campaign_anomaly_latest

# ============================
# SECURITY
# ============================
INTERNAL_API_KEY=vms-internal-key-2026
LARAVEL_API_URL=http://localhost:8000

# ============================
# LOGGING
# ============================
LOG_LEVEL=INFO
```

### 5.3 Cài đặt Python dependencies

```bash
cd trust-eval-service

# Tạo virtual environment
python -m venv venv

# Kích hoạt:
# Windows PowerShell:
.\venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Cài dependencies
pip install -r requirements.txt
```

### 5.4 Tạo thư mục cho models và logs

```bash
mkdir -p models logs
```

---

## 6. Bước 4 — Train Model với Dữ liệu Thực tế

Trước khi chạy ML Service, cần train model với dữ liệu từ các chiến dịch đã duyệt/từ chối.

### 6.1 Điều kiện tiên quyết

Đảm bảo:
- Database có các bảng `campaign_evaluations`, `kdv_feedback` đã được tạo (Bước 1)
- MySQL user `trust_evaluator` có quyền SELECT (Bước 2)
- Có dữ liệu thực tế trong bảng `chien_dichs` với các trạng thái `da_duyet`, `tu_choi`, `hoan_thanh`

Kiểm tra dữ liệu:

```sql
SELECT trang_thai, COUNT(*) as so_luong
FROM chien_dichs
WHERE xoa_luc IS NULL
GROUP BY trang_thai;
```

Kết quả mong đợi: cần ít nhất **100 chiến dịch** đã được duyệt hoặc từ chối để train model tốt.

### 6.2 Chạy Training Pipeline

```bash
# Đảm bảo đang ở thư mục trust-eval-service và venv đã activate
cd trust-eval-service
source venv/bin/activate  # (Linux/Mac)
# hoặc: .\venv\Scripts\activate  # (Windows PowerShell)

# Chạy training pipeline
python -c "
from app.training.pipeline import TrainingPipeline, PipelineConfig

config = PipelineConfig(
    test_size=0.2,
    random_state=42,
    min_training_samples=100,
    calibration_enabled=True,
)
pipeline = TrainingPipeline(config=config)
result = pipeline.run_full_pipeline()

print('=' * 60)
print(f'Success: {result.success}')
print(f'Training samples: {result.training_samples}')
print(f'Validation samples: {result.validation_samples}')
if result.campaign_metrics:
    print(f'AUC-ROC: {result.campaign_metrics.get(\"auc_roc\"):.4f}')
    print(f'ECE: {result.campaign_metrics.get(\"ece\"):.4f}')
if result.error:
    print(f'Error: {result.error}')
print('=' * 60)
"
```

### 6.3 Training thành công

Khi training thành công, các file model được lưu vào thư mục `models/`:

```
models/
├── campaign_trust_v20260412_143022/   ← Thư mục model version mới
│   ├── model.txt                      ← LightGBM model
│   ├── calibration.pkl               ← Isotonic calibration
│   └── metadata.json                  ← Thông tin model
├── campaign_trust_latest/            ← Symlink/copy của version mới nhất
├── volunteer_trust_latest/
└── campaign_anomaly_latest/
```

### 6.4 Nếu chưa có đủ dữ liệu

Nếu số lượng chiến dịch chưa đủ, hệ thống sẽ báo:

```
Only 42 training samples found, minimum 100 required
```

**Giải pháp:**
1. Thêm dữ liệu test vào database
2. Hoặc giảm `min_training_samples` trong config (không khuyến nghị cho production):

```python
config = PipelineConfig(min_training_samples=50)
```

### 6.5 Xem MLflow Dashboard

Sau khi training xong, mở trình duyệt:

```
http://localhost:5000
```

Xem:
- Experiment `campaign-trust-evaluation`
- Run mới nhất với metrics: AUC-ROC, ECE, F1, Precision, Recall
- Feature importance chart

---

## 7. Bước 5 — Chạy ML Service (Local)

### 7.1 Khởi động MLflow Tracking Server

Mở terminal mới (terminal riêng để chạy nền):

```bash
# Terminal 1: MLflow
cd trust-eval-service
source venv/bin/activate
mlflow ui --host 0.0.0.0 --port 5000
```

Truy cập: http://localhost:5000

### 7.2 Khởi động FastAPI ML Service

Mở terminal mới:

```bash
# Terminal 2: FastAPI ML Service
cd trust-eval-service
source venv/bin/activate

# Development mode (auto-reload khi code thay đổi)
uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

### 7.3 Kiểm tra Health

```bash
# Test health endpoint
curl http://localhost:8001/health
```

Kết quả mong đợi:

```json
{
  "status": "ok",
  "database": "connected",
  "mlflow": "available",
  "models": {
    "campaign_trust": "loaded",
    "volunteer_trust": "loaded",
    "anomaly": "loaded"
  },
  "timestamp": "2026-04-12T10:00:00Z"
}
```

### 7.4 Xem API Documentation

- Swagger UI: http://localhost:8001/docs
- ReDoc: http://localhost:8001/redoc

---

## 8. Bước 6 — Test End-to-End

### 8.1 Chuẩn bị dữ liệu test

Đảm bảo có ít nhất 1 chiến dịch ở trạng thái `cho_duyet` trong database:

```sql
-- Tạo chiến dịch test (nếu chưa có)
INSERT INTO chien_dichs (tieu_de, mo_ta, dia_diem, vi_do, kinh_do,
  ngay_bat_dau, ngay_ket_thuc, han_dang_ky,
  so_luong_toi_da, so_luong_toi_thieu,
  nguoi_tao_id, trang_thai, loai_chien_dich_id)
VALUES ('Chiến dịch tình nguyện mùa hè 2026',
  'Tổ chức dọn dẹp bãi biển, thu gom rác thải, tuyên truyền bảo vệ môi trường biển...',
  'Bãi biển Mỹ Khê, Đà Nẵng', 16.0544, 108.2022,
  DATE_ADD(CURDATE(), INTERVAL 7 DAY), DATE_ADD(CURDATE(), INTERVAL 10 DAY),
  DATE_ADD(CURDATE(), INTERVAL 3 DAY),
  50, 10, 1, 'cho_duyet', 1);

-- Lấy ID chiến dịch vừa tạo
SELECT id FROM chien_dichs ORDER BY id DESC LIMIT 1;
```

### 8.2 Test trực tiếp qua ML Service API

```bash
# Thay {campaign_id} bằng ID thực tế
curl -X POST "http://localhost:8001/api/v1/evaluate/campaign/{campaign_id}"

# Ví dụ:
curl -X POST "http://localhost:8001/api/v1/evaluate/campaign/1"
```

Kết quả mong đợi — JSON response chứa:

```json
{
  "campaign_id": 1,
  "evaluation_timestamp": "2026-04-12T10:30:00Z",
  "trust_score": {
    "raw_score": 0.72,
    "calibrated_probability": 0.78,
    "label": "RELIABLE"
  },
  "risk_assessment": {
    "overall_risk_level": "LOW",
    "risk_score": 0.22,
    "flags": [
      {
        "code": "CREATOR_NEW_ACCOUNT",
        "severity": "MEDIUM",
        "message": "Tài khoản người tạo mới tạo (5 ngày)"
      }
    ]
  },
  "shap_explanation": {
    "top_positive_factors": [
      {"feature": "creator_has_verified_email", "contribution": 0.08}
    ],
    "top_negative_factors": [
      {"feature": "creator_account_age_days", "contribution": -0.04}
    ]
  },
  "decision_support": {
    "recommended_action": "APPROVE_WITH_NOTE"
  }
}
```

### 8.3 Test qua Laravel Backend (khuyến nghị)

```bash
# Đảm bảo Laravel đang chạy (port 8000)
cd Backend
php artisan serve --port=8000
```

```bash
# Lấy evaluation cho chiến dịch (thay token bằng JWT thực tế)
curl -H "Authorization: Bearer {your_jwt_token}" \
     "http://localhost:8000/api/trust-eval/campaign/{campaign_id}"

# Trigger refresh evaluation
curl -X POST \
     -H "Authorization: Bearer {your_jwt_token}" \
     "http://localhost:8000/api/trust-eval/campaign/{campaign_id}/refresh"

# Lấy thống kê ML/KDV agreement
curl -H "Authorization: Bearer {your_jwt_token}" \
     "http://localhost:8000/api/trust-eval/statistics"
```

### 8.4 Test qua Swagger UI

1. Mở http://localhost:8001/docs
2. Tìm endpoint `POST /api/v1/evaluate/campaign/{id}`
3. Click **Try it out**
4. Nhập campaign ID
5. Click **Execute**
6. Xem kết quả response

### 8.5 Test Monitoring Endpoints

```bash
# Xem dashboard monitoring
curl http://localhost:8001/api/v1/monitoring

# Xem agreement stats
curl http://localhost:8001/api/v1/monitoring/agreement-stats

# Xem alerts
curl http://localhost:8001/api/v1/monitoring/alerts

# Kiểm tra model info
curl http://localhost:8001/api/v1/model/info
```

### 8.6 Test Frontend (nếu Frontend đã chạy)

1. Mở Frontend tại http://localhost:5173 (hoặc port khác)
2. Đăng nhập với tài khoản KDV (`kiemDuyetVien`)
3. Vào trang **Quản lý chiến dịch**
4. Mở chi tiết chiến dịch đang ở trạng thái `cho_duyet`
5. Panel **TrustEvalPanel** sẽ hiển thị:
   - Trust score circle với label (RELIABLE/SUSPICIOUS)
   - Risk flags với màu sắc theo severity
   - SHAP explanation với bar chart
   - Decision support widget với recommended action

---

## Quick Reference — Lệnh tắt

```bash
# === TERMINAL 1: Laravel Backend ===
cd Backend
php artisan migrate
php artisan serve --port=8000

# === TERMINAL 2: MLflow ===
cd trust-eval-service
source venv/bin/activate
mlflow ui --port 5000

# === TERMINAL 3: ML Service ===
cd trust-eval-service
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload

# === TRAIN MODEL ===
cd trust-eval-service
source venv/bin/activate
python -c "from app.training.pipeline import TrainingPipeline; r = TrainingPipeline().run_full_pipeline(); print(r.success)"

# === TEST ===
curl http://localhost:8001/health
curl -X POST "http://localhost:8001/api/v1/evaluate/campaign/1"
```

---

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Cách xử lý |
|------|-------------|-------------|
| `Database connection failed` | Sai credentials hoặc MySQL chưa chạy | Kiểm tra `.env`, `mysql -u trust_evaluator -p` |
| `Model not found` | Chưa train model | Chạy Bước 4 (Training) |
| `Port 8001 in use` | Process khác đã chiếm port | `netstat -ano \| findstr :8001` rồi kill |
| `MLflow not available` | MLflow chưa chạy | Chạy `mlflow ui --port 5000` |
| `Permission denied` | User MySQL thiếu quyền | Chạy lại Bước 2 (GRANT SELECT) |
| `campaign_evaluations table not found` | Migration chưa chạy | `php artisan migrate` trong Backend |
| `401 Unauthorized` | JWT token sai hoặc hết hạn | Đăng nhập lại lấy token mới |
