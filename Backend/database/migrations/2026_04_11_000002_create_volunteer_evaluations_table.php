<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('volunteer_evaluations')) {
            return;
        }

        Schema::create('volunteer_evaluations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->string('model_version', 50)->default('fallback_v1');

            $table->decimal('trust_score_raw', 5, 4)->nullable();
            $table->decimal('trust_score_calibrated', 5, 4)->nullable();
            $table->string('trust_label', 30)->nullable();
            $table->string('trust_confidence', 20)->nullable();

            $table->json('reliability_summary')->nullable();
            $table->json('behavior_flags')->nullable();
            $table->json('shap_summary')->nullable();

            $table->timestamp('evaluated_at');
            $table->timestamps();

            $table->index('nguoi_dung_id', 'idx_ve_nguoi_dung');
            $table->index('trust_label', 'idx_ve_trust_label');
            $table->index('evaluated_at', 'idx_ve_evaluated_at');

            $table->foreign('nguoi_dung_id', 'fk_ve_nguoi_dung')
                ->references('id')
                ->on('nguoi_dungs')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('volunteer_evaluations');
    }
};
