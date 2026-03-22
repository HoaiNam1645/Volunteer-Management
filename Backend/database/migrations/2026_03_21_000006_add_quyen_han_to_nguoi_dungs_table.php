<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('nguoi_dungs', function (Blueprint $table) {
            if (!Schema::hasColumn('nguoi_dungs', 'quyen_han')) {
                $table->json('quyen_han')->nullable()->after('vai_tro');
            }
        });
    }

    public function down(): void
    {
        Schema::table('nguoi_dungs', function (Blueprint $table) {
            if (Schema::hasColumn('nguoi_dungs', 'quyen_han')) {
                $table->dropColumn('quyen_han');
            }
        });
    }
};
