# Trust Evaluation Service - Deployment Guide

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Yêu cầu hệ thống](#2-yêu-cầu-hệ-thống)
3. [Cài đặt nhanh với Docker](#3-cài-đặt-nhanh-với-docker)
4. [Cài đặt thủ công](#4-cài-đặt-thủ-công)
5. [Cấu hình](#5-cấu-hình)
6. [MySQL User cho ML Service](#6-mysql-user-cho-ml-service)
7. [Khởi chạy và kiểm tra](#7-khởi-chạy-và-kiểm-tra)
8. [Model Training](#8-model-training)
9. [Scheduled Retraining (Cron)](#9-scheduled-retraining-cron)
10. [A/B Testing](#10-ab-testing)
11. [Chạy Tests](#11-chạy-tests)
12. [Monitoring](#12-monitoring)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Tổng quan

Trust Evaluation Service là Python FastAPI service chạy độc lập, giao tiếp với Laravel backend qua HTTP REST API.

```
Laravel Backend (port 8000)
    └── HTTP POST → Trust Evaluation Service (port 8001)
                        ├── LightGBM Models
                        ├── Isolation Forest (Anomaly)
                        ├── SHAP Explainer
                        └── MLflow Tracking (port 5000)
```

---

## 2. Yêu cầu hệ thống

- **Python**: 3.10+
- **MySQL**: 8.0+ (shared với Laravel, read-only access)
- **Docker & Docker Compose**: (khuyến nghị)
- **RAM**: tối thiểu 2GB, khuyến nghị 4GB+
- **CPU**: 2 cores+

---

## 3. Cài đặt nhanh với Docker

### 3.1 Clone và cấu hình

```bash
cd trust-eval-service

# Copy file cấu hình
cp .env.example .env

# Chỉnh sửa .env
nano .env
```

### 3.2 Nội dung .env

```env
APP_ENV=production
APP_DEBUG=false
APP_HOST=0.0.0.0
APP_PORT=8001

DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=volunteer_management
DB_USERNAME=trust_evaluator
DB_PASSWORD=<your_secure_password>
DB_CHARSET=utf8mb4

MLFLOW_TRACKING_URI=http://mlflow:5000
MLFLOW_EXPERIMENT_NAME=campaign-trust-evaluation
MLFLOW_MODEL_REGISTRY=campaign-trust-models

CAMPAIGN_MODEL_PATH=./models/campaign_trust_v2.3.1
VOLUNTEER_MODEL_PATH=./models/volunteer_trust_v1.2.0
ANOMALY_MODEL_PATH=./models/campaign_anomaly_v1.0.0

LOG_LEVEL=INFO

# Internal API key (dùng cho authentication với Laravel)
INTERNAL_API_KEY=<your_internal_api_key>
LARAVEL_API_URL=http://laravel:8000
```

### 3.3 Build và chạy

```bash
# Build image
docker-compose build

# Chạy tất cả services (ML service + MLflow)
docker-compose up -d

# Kiểm tra logs
docker-compose logs -f ml-service

# Kiểm tra health
curl http://localhost:8001/health
```

### 3.4 Stop

```bash
docker-compose down
```

---

## 4. Cài đặt thủ công

### 4.1 Tạo virtual environment

```bash
cd trust-eval-service
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# hoặc: venv\Scripts\activate  # Windows
```

### 4.2 Cài dependencies

```bash
pip install -r requirements.txt
```

### 4.3 Cấu hình

```bash
cp .env.example .env
# Chỉnh sửa .env với thông tin database thật
```

### 4.4 Chạy service

```bash
# Development mode (auto-reload)
uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload

# Production mode
uvicorn app.main:app --host 0.0.0.0 --port 8001 --workers 4
```

---

## 5. Cấu hình

### 5.1 Environment Variables

| Variable | Mô tả | Giá trị mặc định |
|---|---|---|
| `APP_ENV` | Môi trường (development/production) | `development` |
| `APP_DEBUG` | Debug mode | `true` |
| `APP_PORT` | Port chạy service | `8001` |
| `DB_HOST` | MySQL host | `127.0.0.1` |
| `DB_PORT` | MySQL port | `3306` |
| `DB_DATABASE` | Database name | `volunteer_management` |
| `DB_USERNAME` | MySQL read-only user | `trust_evaluator` |
| `DB_PASSWORD` | MySQL password | — |
| `MLFLOW_TRACKING_URI` | MLflow server URL | `http://localhost:5000` |
| `INTERNAL_API_KEY` | Key xác thực request từ Laravel | — |

### 5.2 Logging

Log được ghi ra stdout (Docker) và file:

```bash
tail -f logs/app.log
tail -f logs/retrain.log
tail -f logs/ab_test.log
```

---

## 6. MySQL User cho ML Service

Chạy script SQL trên MySQL server (thay `<your_secure_password>` bằng password thật):

```sql
CREATE USER 'trust_evaluator'@'%' IDENTIFIED BY '<your_secure_password>';
GRANT SELECT ON volunteer_management.* TO 'trust_evaluator'@'%';
FLUSH PRIVILEGES;
```

**Lưu ý**: ML Service chỉ cần quyền `SELECT`. Laravel giữ quyền `SELECT/INSERT/UPDATE/DELETE`.

---

## 7. Khởi chạy và kiểm tra

### 7.1 Health check

```bash
curl http://localhost:8001/health
```

Response mẫu:
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

### 7.2 Model info

```bash
curl http://localhost:8001/api/v1/model/info
```

### 7.3 Evaluate một campaign (test)

```bash
curl -X POST http://localhost:8001/api/v1/evaluate/campaign/1
```

### 7.4 API Documentation

Swagger UI: http://localhost:8001/docs
ReDoc: http://localhost:8001/redoc

---

## 8. Model Training

### 8.1 Training qua API

```bash
curl -X POST http://localhost:8001/api/v1/train/campaigns \
  -H "Content-Type: application/json" \
  -d '{"test_size": 0.2, "random_state": 42}'
```

### 8.2 Training qua script

```bash
cd trust-eval-service
python -c "
from app.training.pipeline import TrainingPipeline, PipelineConfig
pipeline = TrainingPipeline(config=PipelineConfig())
result = pipeline.run_full_pipeline()
print(f'Success: {result.success}')
"
```

### 8.3 Xem training summary

```bash
curl http://localhost:8001/api/v1/train/summary
```

---

## 9. Scheduled Retraining (Cron)

### 9.1 Cron job setup (Linux)

```bash
# Mở crontab
crontab -e

# Thêm các dòng sau:

# Chạy retraining hàng tuần (Chủ Nhật 2h sáng)
0 2 * * 0 cd /path/to/trust-eval-service && /path/to/venv/bin/python scripts/scheduled_retrain.py --mode weekly >> logs/retrain.log 2>&1

# Chạy retraining hàng tháng (ngày 1, 3h sáng)
0 3 1 * * cd /path/to/trust-eval-service && /path/to/venv/bin/python scripts/scheduled_retrain.py --mode monthly >> logs/retrain.log 2>&1
```

### 9.2 Windows Task Scheduler

Tạo file `retrain_weekly.bat`:
```batch
@echo off
cd /d C:\path\to\trust-eval-service
call venv\Scripts\activate.bat
python scripts\scheduled_retrain.py --mode weekly
```

Tạo scheduled task với Task Scheduler, trigger: Weekly, Sunday 2:00 AM.

### 9.3 Chạy thủ công

```bash
# Weekly mode
python scripts/scheduled_retrain.py --mode weekly

# Monthly mode
python scripts/scheduled_retrain.py --mode monthly
```

---

## 10. A/B Testing

### 10.1 Bắt đầu experiment

```bash
python scripts/ab_test.py start \
  --control campaign_trust_v2.3.1 \
  --treatment campaign_trust_v2.4.0 \
  --traffic 10 \
  --min-samples 100 \
  --max-days 7
```

### 10.2 Theo dõi experiment

```bash
# List all experiments
python scripts/ab_test.py status

# Chi tiết experiment
python scripts/ab_test.py status --id ab_abc12345
```

### 10.3 Kết thúc experiment

```bash
python scripts/ab_test.py conclude --id ab_abc12345
```

### 10.4 Promote winner

```bash
python scripts/ab_test.py promote --id ab_abc12345
```

---

## 11. Chạy Tests

### 11.1 Cài đặt test dependencies

```bash
pip install pytest pytest-asyncio httpx
```

### 11.2 Chạy tất cả tests

```bash
cd trust-eval-service
pytest tests/ -v
```

### 11.3 Chạy specific test file

```bash
pytest tests/test_decision_logic.py -v
pytest tests/test_rule_validator.py -v
pytest tests/test_content_analyzer.py -v
```

### 11.4 Chạy với coverage

```bash
pytest tests/ --cov=app --cov-report=html
# Mở htmlcov/index.html để xem coverage report
```

---

## 12. Monitoring

### 12.1 MLflow Dashboard

MLflow tracking server chạy tại http://localhost:5000

Xem:
- Training runs history
- Model artifacts
- Metrics (AUC-ROC, ECE, F1)
- Feature importance

### 12.2 Cache Statistics

```bash
# Xem cache stats (cần implement endpoint hoặc log)
curl http://localhost:8001/api/v1/cache/stats
```

### 12.3 Health Check cho Load Balancer

```bash
curl -f http://localhost:8001/health
# Exit code 0 = healthy, non-zero = unhealthy
```

---

## 13. Troubleshooting

### Lỗi: Database connection failed

```bash
# Kiểm tra MySQL đang chạy
mysql -h 127.0.0.1 -u trust_evaluator -p

# Kiểm tra user permissions
SHOW GRANTS FOR 'trust_evaluator'@'%';
```

### Lỗi: Model not found

```bash
# Kiểm tra model files tồn tại
ls -la models/

# Nếu chưa có model, chạy training trước
python scripts/scheduled_retrain.py --mode monthly
```

### Lỗi: MLflow not available

```bash
# Kiểm tra MLflow container đang chạy
docker-compose ps mlflow

# Khởi động lại MLflow
docker-compose restart mlflow
```

### Lỗi: Port 8001 đã bị chiếm

```bash
# Tìm process đang dùng port 8001
# Linux:
lsof -i :8001
# Windows:
netstat -ano | findstr :8001

# Đổi port trong .env
APP_PORT=8002
```

### Lỗi: Out of memory khi training

```bash
# Giảm batch size trong pipeline config
# Hoặc chạy training với docker và tăng memory limit:
docker-compose run --memory=4g ml-service python scripts/scheduled_retrain.py
```

---

## Security Checklist

- [ ] Đổi `INTERNAL_API_KEY` bằng giá trị ngẫu nhiên mạnh
- [ ] Đổi `DB_PASSWORD` bằng password mạnh
- [ ] ML Service chỉ expose port 8001 trong internal network
- [ ] MLflow port 5000 không expose ra public internet
- [ ] MySQL user `trust_evaluator` chỉ có quyền SELECT
- [ ] Log file không chứa sensitive data
