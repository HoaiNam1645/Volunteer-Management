<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('kdv_feedback')) {
            return;
        }

        Schema::create('kdv_feedback', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('chien_dich_id');
            $table->unsignedBigInteger('nguoi_dung_id')->comment('KDV who gave feedback');
            $table->string('feedback_type', 30)->comment('override | agree | disagree | correct_action');
            $table->tinyInteger('ml_action_correct')->nullable()->comment('1=ML correct, 0=ML wrong, null=not applicable');
            $table->tinyInteger('final_trust_label_override')->nullable()->comment('1=reliable, 0=suspicious');
            $table->text('kdv_notes')->nullable();
            $table->json('overridden_fields')->nullable()->comment('Fields KDV manually changed');
            $table->timestamp('feedback_at');
            $table->timestamps();

            $table->index('chien_dich_id', 'idx_kf_chien_dich');
            $table->index('nguoi_dung_id', 'idx_kf_nguoi_dung');
            $table->index('feedback_type', 'idx_kf_type');
            $table->index('feedback_at', 'idx_kf_feedback_at');

            $table->foreign('chien_dich_id', 'fk_kf_chien_dich')
                ->references('id')
                ->on('chien_dichs')
                ->cascadeOnDelete();

            $table->foreign('nguoi_dung_id', 'fk_kf_nguoi_dung')
                ->references('id')
                ->on('nguoi_dungs')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kdv_feedback');
    }
};
