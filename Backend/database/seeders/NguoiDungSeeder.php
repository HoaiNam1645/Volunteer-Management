<?php

namespace Database\Seeders;

use App\Models\NguoiDung;
use App\Models\KyNang;
use App\Models\KhuVuc;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class NguoiDungSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Lấy danh sách ID kỹ năng và khu vực để random
        $kyNangIds = KyNang::pluck('id')->toArray();
        $khuVucIds = KhuVuc::pluck('id')->toArray();
        $thuTrongTuan = ['thu_hai', 'thu_ba', 'thu_tu', 'thu_nam', 'thu_sau', 'thu_bay', 'chu_nhat'];
        $khungGioUuTien = ['sang', 'chieu', 'toi', 'ca_ngay', 'linh_hoat'];

        $matKhauChung = Hash::make('password123');
        $now = Carbon::now();

        // 2. Tạo Admin
        NguoiDung::updateOrCreate(
            ['email' => 'admin@gmail.com'],
            [
                'ho_ten' => 'Quản Trị Viên',
                'mat_khau' => $matKhauChung,
                'so_dien_thoai' => '0901234567',
                'vai_tro' => 'quan_tri_vien',
                'trang_thai' => 'hoat_dong',
                'xac_thuc_email_luc' => $now,
                'ngay_sinh' => '1990-01-01',
                'gioi_tinh' => 'nam',
                'tao_luc' => $now,
                'cap_nhat_luc' => $now,
            ]
        );

        // 3. Tạo 2 Điều phối viên
        for ($i = 1; $i <= 2; $i++) {
            NguoiDung::updateOrCreate(
                ['email' => "dieu_phoi_vien_$i@gmail.com"],
                [
                    'ho_ten' => "Điều Phối Viên $i",
                    'mat_khau' => $matKhauChung,
                    'so_dien_thoai' => "091234567$i",
                    'vai_tro' => 'dieu_phoi_vien',
                    'trang_thai' => 'hoat_dong',
                    'xac_thuc_email_luc' => $now,
                    'ngay_sinh' => "1995-05-0$i",
                    'gioi_tinh' => $i % 2 == 0 ? 'nu' : 'nam',
                    'tao_luc' => $now,
                    'cap_nhat_luc' => $now,
                ]
            );
        }

        // 4. Tạo 5 Người dùng (Tình nguyện viên) với đầy đủ hồ sơ năng lực
        for ($i = 1; $i <= 5; $i++) {
            $user = NguoiDung::updateOrCreate(
                ['email' => "tinh_nguyen_vien_$i@gmail.com"],
                [
                    'ho_ten' => "Tình Nguyện Viên $i",
                    'mat_khau' => $matKhauChung,
                    'so_dien_thoai' => "098765432$i",
                    'vai_tro' => 'tinh_nguyen_vien',
                    'trang_thai' => 'hoat_dong',
                    'xac_thuc_email_luc' => $now,
                    'ngay_sinh' => "2000-10-1$i",
                    'gioi_tinh' => $i % 2 == 0 ? 'nam' : 'nu',
                    'tinh_thanh_id' => 4, // Đà Nẵng
                    'phuong_xa_id' => 13 + $i, // Random phường ở Đà Nẵng
                    'dia_chi_duong' => "Số $i, Đường Tình Nguyện",
                    'vi_do' => 16.0544 + ($i * 0.01),
                    'kinh_do' => 108.2022 + ($i * 0.01),
                    'gioi_thieu' => "Tôi là TNV năng nổ yêu thích các hoạt động vì môi trường và cộng đồng. Rất mong được cống hiến.",
                    'khung_gio_uu_tien' => $khungGioUuTien[array_rand($khungGioUuTien)],
                    'tuy_chon_thong_bao' => [
                        'campaign_new' => true,
                        'campaign_assign' => true,
                        'campaign_remind' => true,
                        'rating' => true,
                        'email_digest' => false,
                        'ai_suggest' => true
                    ],
                    'tao_luc' => $now,
                    'cap_nhat_luc' => $now,
                ]
            );

            // Random Kỹ năng (1-4 kỹ năng)
            if (!empty($kyNangIds)) {
                $randomSkillKeys = (array) array_rand($kyNangIds, rand(1, min(4, count($kyNangIds))));
                $skillsToAttach = [];
                foreach ($randomSkillKeys as $key) {
                    $skillsToAttach[] = $kyNangIds[$key];
                }
                $user->kyNangs()->sync($skillsToAttach);
            }

            // Random Khu vực (1-3 khu vực)
            if (!empty($khuVucIds)) {
                $randomAreaKeys = (array) array_rand($khuVucIds, rand(1, min(3, count($khuVucIds))));
                $areasToAttach = [];
                foreach ($randomAreaKeys as $key) {
                    $areasToAttach[] = $khuVucIds[$key];
                }
                $user->khuVucs()->sync($areasToAttach);
            }

            // Random Lịch rảnh (1-4 ngày)
            $user->lichRanhs()->delete();
            $randomDayKeys = (array) array_rand($thuTrongTuan, rand(1, 4));
            foreach ($randomDayKeys as $key) {
                $user->lichRanhs()->create([
                    'thu_trong_tuan' => $thuTrongTuan[$key]
                ]);
            }

            // Tạo Kinh nghiệm (0-2 kinh nghiệm)
            $user->kinhNghiems()->delete();
            $numExp = rand(0, 2);
            for ($k = 1; $k <= $numExp; $k++) {
                $user->kinhNghiems()->create([
                    'tieu_de' => "Dự án Tình nguyện $k năm 2023",
                    'to_chuc' => "Tổ chức Thanh Niên $k",
                    'thoi_gian' => "Tháng $k/2023 - Tháng " . ($k + 2) . "/2023",
                    'mo_ta' => "Tham gia hỗ trợ điều phối và tổ chức các sự kiện cho dự án.",
                ]);
            }

            // Tạo Chứng chỉ (0-1 chứng chỉ)
            $user->chungChis()->delete();
            $numCert = rand(0, 1);
            if ($numCert > 0) {
                $user->chungChis()->create([
                    'ten' => "Khóa học Kỹ năng Sơ cấp Cứu",
                    'don_vi_cap' => "Hội Chữ Thập Đỏ VN",
                ]);
            }
        }
    }
}
