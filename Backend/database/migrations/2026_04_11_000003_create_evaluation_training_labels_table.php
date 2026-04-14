<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('evaluation_training_labels')) {
            return;
        }

        Schema::create('evaluation_training_labels', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('chien_dich_id');
            $table->unsignedBigInteger('evaluation_id')->nullable();
            $table->unsignedBigInteger('kdv_id');

            // KDV decision
            $table->enum('kdv_action', ['approve', 'approve_with_note', 'request_info', 'reject'])->notNull();
            $table->text('kdv_reason')->nullable();

            // ML original prediction
            $table->decimal('ml_trust_score', 5, 4)->nullable();
            $table->string('ml_risk_level', 20)->nullable();
            $table->string('ml_recommended_action', 50)->nullable();

            // Comparison
            $table->boolean('ml_agree_with_kdv')->nullable();

            // Feedback quality tracking
            $table->boolean('kdv_satisfied_with_ml')->nullable();
            $table->boolean('kdv_overridden_ml')->default(false);

            $table->timestamp('created_at')->useCurrent();

            $table->index('chien_dich_id', 'idx_etl_chien_dich');
            $table->index('kdv_id', 'idx_etl_kdv');
            $table->index('kdv_action', 'idx_etl_action');
            $table->index('ml_agree_with_kdv', 'idx_etl_agree');

            $table->foreign('chien_dich_id', 'fk_etl_chien_dich')
                ->references('id')
                ->on('chien_dichs')
                ->cascadeOnDelete();

            $table->foreign('evaluation_id', 'fk_etl_evaluation')
                ->references('id')
                ->on('campaign_evaluations')
                ->cascadeOnDelete();

            $table->foreign('kdv_id', 'fk_etl_kdv')
                ->references('id')
                ->on('nguoi_dungs');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('evaluation_training_labels');
    }
};
