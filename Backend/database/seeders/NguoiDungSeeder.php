<?php

namespace Database\Seeders;

use App\Models\NguoiDung;
use App\Models\KyNang;
use App\Models\KhuVuc;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class NguoiDungSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $kyNangs = KyNang::query()->get(['id', 'ten']);
        $khuVucs = KhuVuc::query()->get(['id', 'ten']);
        $tinhThanhs = DB::table('tinh_thanh')->select('id', 'ten', 'vi_do', 'kinh_do')->get();
        $phuongXas = DB::table('phuong_xa')->select('id', 'tinh_thanh_id', 'ten', 'vi_do', 'kinh_do')->get()->groupBy('tinh_thanh_id');

        $kyNangIds = $kyNangs->pluck('id')->values()->all();
        $khuVucIdByName = $khuVucs->pluck('id', 'ten');
        $tinhThanhByName = $tinhThanhs->keyBy('ten');
        $thuTrongTuan = ['thu_hai', 'thu_ba', 'thu_tu', 'thu_nam', 'thu_sau', 'thu_bay', 'chu_nhat'];
        $khungGioUuTien = ['sang', 'chieu', 'toi', 'ca_ngay', 'linh_hoat'];
        $gioiTinhCycle = ['nam', 'nu'];
        $diaPhuongUuTien = [
            'Đà Nẵng',
            'TP Hồ Chí Minh',
            'Hà Nội',
            'Huế',
            'Cần Thơ',
            'Hải Phòng',
            'Nghệ An',
            'Thanh Hóa',
            'Quảng Trị',
            'Khánh Hòa',
            'Gia Lai',
            'Đồng Nai',
        ];

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

        // 3. Tạo kiểm duyệt viên
        for ($i = 1; $i <= 4; $i++) {
            NguoiDung::updateOrCreate(
                ['email' => "kiem_duyet_vien_$i@gmail.com"],
                [
                    'ho_ten' => "Kiểm Duyệt Viên $i",
                    'mat_khau' => $matKhauChung,
                    'so_dien_thoai' => sprintf('09123456%02d', $i),
                    'vai_tro' => 'kiem_duyet_vien',
                    'trang_thai' => 'hoat_dong',
                    'xac_thuc_email_luc' => $now,
                    'ngay_sinh' => "199" . ($i % 4) . "-05-" . str_pad((string) max(1, $i), 2, '0', STR_PAD_LEFT),
                    'gioi_tinh' => $i % 2 == 0 ? 'nu' : 'nam',
                    'tao_luc' => $now,
                    'cap_nhat_luc' => $now,
                ]
            );
        }

        $ho = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Võ', 'Đặng', 'Bùi', 'Đỗ', 'Hồ'];
        $tenLot = ['Văn', 'Thị', 'Minh', 'Ngọc', 'Quốc', 'Gia', 'Thanh', 'Tuấn', 'Khánh', 'Bảo', 'Phương', 'Thiên'];
        $ten = ['An', 'Bình', 'Châu', 'Duy', 'Hà', 'Hân', 'Hiếu', 'Hùng', 'Khôi', 'Linh', 'Mai', 'My', 'Nam', 'Nhi', 'Phúc', 'Quân', 'Thảo', 'Trang', 'Trúc', 'Vy'];
        $gioiThieuMau = [
            'Tôi yêu thích các hoạt động cộng đồng và muốn đóng góp kỹ năng thực tế cho các chiến dịch ý nghĩa.',
            'Tôi thường tham gia các hoạt động hỗ trợ môi trường, giáo dục và rất sẵn sàng phối hợp theo nhóm.',
            'Tôi mong muốn đồng hành lâu dài với các chiến dịch có tác động tích cực cho trẻ em và cộng đồng.',
            'Tôi có tinh thần trách nhiệm, thích làm việc hiện trường và luôn chủ động trong các hoạt động tình nguyện.',
        ];
        $kinhNghiemMau = [
            ['tieu_de' => 'Điều phối hoạt động tình nguyện mùa hè', 'to_chuc' => 'CLB Thanh niên Xanh'],
            ['tieu_de' => 'Hỗ trợ truyền thông chiến dịch cộng đồng', 'to_chuc' => 'Mạng lưới Tình nguyện miền Trung'],
            ['tieu_de' => 'Tham gia chương trình dạy học cuối tuần', 'to_chuc' => 'Nhóm Dạy học vì cộng đồng'],
            ['tieu_de' => 'Hậu cần cho chương trình cứu trợ', 'to_chuc' => 'Đội Phản ứng nhanh địa phương'],
        ];
        $chungChiMau = [
            ['ten' => 'Sơ cấp cứu cộng đồng', 'don_vi_cap' => 'Hội Chữ thập đỏ Việt Nam'],
            ['ten' => 'Điều phối sự kiện cộng đồng', 'don_vi_cap' => 'Trung tâm Thanh thiếu niên'],
            ['ten' => 'Kỹ năng lãnh đạo nhóm', 'don_vi_cap' => 'Học viện Thanh niên'],
            ['ten' => 'An toàn trong hoạt động thiện nguyện', 'don_vi_cap' => 'Tổ chức Phát triển cộng đồng'],
        ];

        // 4. Tạo tập người dùng lớn hơn để test thực tế
        for ($i = 1; $i <= 48; $i++) {
            $diaPhuongTen = $diaPhuongUuTien[($i - 1) % count($diaPhuongUuTien)];
            $tinhThanh = $tinhThanhByName->get($diaPhuongTen) ?? $tinhThanhByName->get('Đà Nẵng');
            $wardOptions = collect($phuongXas->get($tinhThanh->id, collect()))->values();
            $phuongXa = $wardOptions->get(($i - 1) % max(1, $wardOptions->count()));
            $fullName = sprintf(
                '%s %s %s',
                $ho[($i - 1) % count($ho)],
                $tenLot[($i + 2) % count($tenLot)],
                $ten[($i + 5) % count($ten)]
            );

            $gioiTinh = $gioiTinhCycle[$i % count($gioiTinhCycle)];
            $xacThucEmailLuc = $i % 19 === 0 ? null : $now;
            $trangThai = $i % 17 === 0
                ? 'bi_khoa'
                : ($xacThucEmailLuc ? 'hoat_dong' : 'cho_duyet');

            $user = NguoiDung::updateOrCreate(
                ['email' => "tinh_nguyen_vien_$i@gmail.com"],
                [
                    'ho_ten' => $fullName,
                    'mat_khau' => $matKhauChung,
                    'so_dien_thoai' => sprintf('0987654%03d', $i),
                    'vai_tro' => 'tinh_nguyen_vien',
                    'trang_thai' => $trangThai,
                    'xac_thuc_email_luc' => $xacThucEmailLuc,
                    'ngay_sinh' => Carbon::create(1994 + ($i % 10), (($i % 12) + 1), (($i % 27) + 1))->toDateString(),
                    'gioi_tinh' => $gioiTinh,
                    'tinh_thanh_id' => $tinhThanh->id,
                    'phuong_xa_id' => $phuongXa?->id,
                    'dia_chi_duong' => "Số {$i}, Đường Tình Nguyện " . (($i % 8) + 1),
                    'vi_do' => round((float) ($phuongXa->vi_do ?? $tinhThanh->vi_do) + ((($i % 5) - 2) * 0.0035), 7),
                    'kinh_do' => round((float) ($phuongXa->kinh_do ?? $tinhThanh->kinh_do) + ((($i % 7) - 3) * 0.0035), 7),
                    'gioi_thieu' => $gioiThieuMau[$i % count($gioiThieuMau)],
                    'khung_gio_uu_tien' => $khungGioUuTien[array_rand($khungGioUuTien)],
                    'tuy_chon_thong_bao' => [
                        'campaign_new' => true,
                        'campaign_assign' => true,
                        'campaign_remind' => true,
                        'rating' => $i % 4 !== 0,
                        'email_digest' => $i % 3 === 0,
                        'ai_suggest' => true
                    ],
                    'tao_luc' => $now,
                    'cap_nhat_luc' => $now,
                ]
            );

            // Kỹ năng (2-6 kỹ năng)
            if (!empty($kyNangIds)) {
                $skillsToAttach = [];
                $skillCount = 2 + ($i % 5);
                for ($offset = 0; $offset < $skillCount; $offset++) {
                    $skillsToAttach[] = $kyNangIds[($i + ($offset * 3)) % count($kyNangIds)];
                }
                $user->kyNangs()->sync(array_values(array_unique($skillsToAttach)));
            }

            // Khu vực hoạt động (2-4 khu vực)
            $areasToAttach = [];
            $areasToAttach[] = $khuVucIdByName->get($diaPhuongTen);
            foreach ([$diaPhuongUuTien[$i % count($diaPhuongUuTien)], $diaPhuongUuTien[($i + 3) % count($diaPhuongUuTien)], 'Khác'] as $areaName) {
                $areaId = $khuVucIdByName->get($areaName);
                if ($areaId) {
                    $areasToAttach[] = $areaId;
                }
            }
            $user->khuVucs()->sync(array_values(array_unique(array_filter($areasToAttach))));

            // Lịch rảnh (3-6 ngày)
            $user->lichRanhs()->delete();
            $dayCount = 3 + ($i % 4);
            $selectedDays = [];
            for ($offset = 0; $offset < $dayCount; $offset++) {
                $selectedDays[] = $thuTrongTuan[($i + $offset) % count($thuTrongTuan)];
            }
            foreach (array_values(array_unique($selectedDays)) as $day) {
                $user->lichRanhs()->create([
                    'thu_trong_tuan' => $day
                ]);
            }

            // Kinh nghiệm (1-3)
            $user->kinhNghiems()->delete();
            $numExp = 1 + ($i % 3);
            for ($k = 1; $k <= $numExp; $k++) {
                $template = $kinhNghiemMau[($i + $k) % count($kinhNghiemMau)];
                $user->kinhNghiems()->create([
                    'tieu_de' => $template['tieu_de'],
                    'to_chuc' => $template['to_chuc'],
                    'thoi_gian' => "Tháng " . (($k * 2) + ($i % 4)) . "/2024 - Tháng " . (($k * 2) + ($i % 4) + 2) . "/2024",
                    'mo_ta' => "Tham gia phối hợp triển khai hoạt động, làm việc nhóm và hỗ trợ hiện trường trong chiến dịch {$k}.",
                ]);
            }

            // Chứng chỉ (0-2)
            $user->chungChis()->delete();
            $numCert = $i % 3;
            for ($c = 0; $c < $numCert; $c++) {
                $template = $chungChiMau[($i + $c) % count($chungChiMau)];
                $user->chungChis()->create([
                    'ten' => $template['ten'],
                    'don_vi_cap' => $template['don_vi_cap'],
                ]);
            }
        }
    }
}
