<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('campaign_evaluations')) {
            return;
        }

        Schema::create('campaign_evaluations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('chien_dich_id');
            $table->string('model_version', 50)->default('fallback_v1');
            $table->enum('evaluation_source', ['ml_service', 'fallback'])->default('fallback');

            // Trust Score
            $table->decimal('trust_score_raw', 5, 4)->nullable();
            $table->decimal('trust_score_calibrated', 5, 4)->nullable();
            $table->string('trust_label', 30)->nullable(); // RELIABLE_HIGH, RELIABLE, NEUTRAL, SUSPICIOUS, SUSPICIOUS_HIGH
            $table->string('trust_confidence', 20)->nullable(); // HIGH, MEDIUM, LOW

            // Volunteer Trust
            $table->decimal('volunteer_trust_score', 5, 4)->nullable();
            $table->string('volunteer_trust_label', 30)->nullable();

            // Risk Assessment
            $table->enum('risk_level', ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'])->nullable();
            $table->decimal('risk_score', 5, 4)->nullable();
            $table->decimal('anomaly_score', 6, 4)->nullable();
            $table->boolean('is_anomaly')->default(false);

            // Flags & Analysis
            $table->json('risk_flags')->nullable();
            $table->json('content_analysis')->nullable();
            $table->json('anomaly_types')->nullable();

            // Decision Support
            $table->string('recommended_action', 50)->nullable(); // APPROVE, APPROVE_WITH_NOTE, REQUEST_ADDITIONAL_INFO, REJECT
            $table->string('decision_confidence', 20)->nullable(); // HIGH, MEDIUM, LOW
            $table->text('decision_reason')->nullable();
            $table->json('questions_to_verify')->nullable();

            // SHAP Summary
            $table->json('shap_summary')->nullable();

            // Validation
            $table->json('validation_result')->nullable();

            $table->timestamp('evaluated_at');
            $table->timestamps();

            $table->index('chien_dich_id', 'idx_ce_chien_dich');
            $table->index('trust_label', 'idx_ce_trust_label');
            $table->index('risk_level', 'idx_ce_risk_level');
            $table->index('evaluated_at', 'idx_ce_evaluated_at');
            $table->index('model_version', 'idx_ce_model_version');

            $table->foreign('chien_dich_id', 'fk_ce_chien_dich')
                ->references('id')
                ->on('chien_dichs')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('campaign_evaluations');
    }
};
