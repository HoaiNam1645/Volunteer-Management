from app.training.pipeline import TrainingPipeline, PipelineConfig

config = PipelineConfig(
    test_size=0.2,
    random_state=42,
    min_training_samples=100,
    calibration_enabled=True,
)
pipeline = TrainingPipeline(config=config)
result = pipeline.run_full_pipeline()

print("=" * 60)
print(f"Success: {result.success}")
print(f"Training samples: {result.training_samples}")
print(f"Validation samples: {result.validation_samples}")

if result.campaign_metrics:
    auc = result.campaign_metrics.get("auc_roc")
    ece = result.campaign_metrics.get("ece")
    if auc is not None:
        print(f"AUC-ROC: {auc:.4f}")
    if ece is not None:
        print(f"ECE: {ece:.4f}")

if result.error:
    print(f"Error: {result.error}")

print("=" * 60)
