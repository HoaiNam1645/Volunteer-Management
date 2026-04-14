from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # App
    app_env: str = "development"
    app_debug: bool = True
    app_host: str = "0.0.0.0"
    app_port: int = 8001

    # MySQL Database (shared với Laravel, read-only)
    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_database: str = "volunteer_management"
    db_username: str = "trust_evaluator"
    db_password: str = "your_secure_password"
    db_charset: str = "utf8mb4"

    # MLflow
    mlflow_tracking_uri: str = "http://localhost:5000"
    mlflow_experiment_name: str = "campaign-trust-evaluation"
    mlflow_model_registry: str = "campaign-trust-models"

    # Model paths
    campaign_model_path: str = "./models/campaign_trust_v2.3.1"
    volunteer_model_path: str = "./models/volunteer_trust_v1.2.0"
    anomaly_model_path: str = "./models/campaign_anomaly_v1.0.0"

    # Logging
    log_level: str = "INFO"
    log_file: str = "./logs/app.log"

    @property
    def database_url(self) -> str:
        return (
            f"mysql+mysql.connector://{self.db_username}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_database}?charset={self.db_charset}"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
