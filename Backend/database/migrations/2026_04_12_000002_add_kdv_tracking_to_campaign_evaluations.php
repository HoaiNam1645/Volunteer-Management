<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('campaign_evaluations', 'kdv_final_action')) {
            Schema::table('campaign_evaluations', function (Blueprint $table) {
                $table->string('kdv_final_action', 50)->nullable()->after('recommended_action');
                $table->string('kdv_final_trust_label', 30)->nullable()->after('kdv_final_action');
                $table->unsignedBigInteger('kdv_id')->nullable()->after('kdv_final_trust_label');
                $table->timestamp('kdv_decided_at')->nullable()->after('kdv_id');
                $table->boolean('ml_agreement')->nullable()->after('kdv_decided_at');

                $table->index('kdv_final_action', 'idx_ce_kdv_action');
                $table->index('kdv_final_trust_label', 'idx_ce_kdv_label');
                $table->index('ml_agreement', 'idx_ce_ml_agreement');
            });
        }
    }

    public function down(): void
    {
        Schema::table('campaign_evaluations', function (Blueprint $table) {
            $columns = ['kdv_final_action', 'kdv_final_trust_label', 'kdv_id', 'kdv_decided_at', 'ml_agreement'];
            $existing = array_filter($columns, fn($c) => Schema::hasColumn('campaign_evaluations', $c));
            if (!empty($existing)) {
                $table->dropColumn($existing);
            }
        });
    }
};
