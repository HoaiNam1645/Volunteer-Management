<?php

namespace Database\Seeders;

use App\Models\KyNang;
use App\Models\KhuVuc;
use App\Models\LoaiChienDich;
use Illuminate\Database\Seeder;

class DanhMucSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Kỹ năng
        $ky_nangs = [
            ['ten' => 'Giáo dục / Dạy học', 'bieu_tuong' => 'fa-chalkboard-user', 'mo_ta' => 'Hỗ trợ giảng dạy, gia sư'],
            ['ten' => 'Y tế / Chăm sóc sức khỏe', 'bieu_tuong' => 'fa-staff-snake', 'mo_ta' => 'Hỗ trợ y tế, sơ cứu, tâm lý'],
            ['ten' => 'Môi trường', 'bieu_tuong' => 'fa-leaf', 'mo_ta' => 'Trồng cây, dọn dẹp vệ sinh'],
            ['ten' => 'Truyền thông / Sự kiện', 'bieu_tuong' => 'fa-bullhorn', 'mo_ta' => 'Chụp ảnh, quay phim, viết bài'],
            ['ten' => 'Kỹ thuật / IT', 'bieu_tuong' => 'fa-laptop-code', 'mo_ta' => 'Sửa chữa máy tính, xây dựng website'],
            ['ten' => 'Nấu ăn / Hậu cần', 'bieu_tuong' => 'fa-utensils', 'mo_ta' => 'Chuẩn bị suất ăn, vận chuyển'],
        ];

        foreach ($ky_nangs as $kn) {
            KyNang::updateOrCreate(['ten' => $kn['ten']], $kn);
        }

        // 2. Khu vực
        $khu_vucs = [
            ['ten' => 'TP. Hồ Chí Minh'],
            ['ten' => 'Hà Nội'],
            ['ten' => 'Đà Nẵng'],
            ['ten' => 'Cần Thơ'],
            ['ten' => 'Hải Phòng'],
            ['ten' => 'Nghệ An'],
            ['ten' => 'Thanh Hóa'],
            ['ten' => 'Khác'],
        ];

        foreach ($khu_vucs as $kv) {
            KhuVuc::updateOrCreate(['ten' => $kv['ten']], $kv);
        }

        // 3. Loại chiến dịch
        $loai_chien_dichs = [
            ['ten' => 'Môi trường',  'bieu_tuong' => 'fa-leaf',                  'mau_sac' => '#198754'],
            ['ten' => 'Giáo dục',    'bieu_tuong' => 'fa-book-open',             'mau_sac' => '#0d6efd'],
            ['ten' => 'Y tế',        'bieu_tuong' => 'fa-hand-holding-medical',  'mau_sac' => '#dc3545'],
            ['ten' => 'Cộng đồng',   'bieu_tuong' => 'fa-people-group',          'mau_sac' => '#fd7e14'],
            ['ten' => 'Cứu trợ thiên tai', 'bieu_tuong' => 'fa-house-flood-water', 'mau_sac' => '#6c757d'],
        ];

        foreach ($loai_chien_dichs as $lcd) {
            LoaiChienDich::updateOrCreate(['ten' => $lcd['ten']], $lcd);
        }
    }
}
