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
    private const TOTAL_VOLUNTEERS = 360;

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
        $diaChiMau = [
            'Khu dân cư Hòa Bình',
            'Tổ dân phố Ánh Dương',
            'Cụm dân cư Thanh Niên',
            'Khu phố Cộng Đồng',
            'Hẻm Tình Nguyện',
            'Đường Hoa Phượng',
            'Đường Nguyễn Tri Ân',
            'Khu phố Hy Vọng',
        ];
        $soNhaMau = ['12A', '15/2', '28', '33B', '47', '59/7', '102', '118A', '205', '12/14'];
        $profileBlueprints = [
            [
                'label' => 'Moi truong Da Nang',
                'primary_area' => 'Đà Nẵng',
                'secondary_areas' => ['Huế', 'Quảng Trị', 'Khác'],
                'skills' => ['Môi trường', 'Điều phối nhóm', 'Truyền thông / Sự kiện', 'Khảo sát / Thu thập dữ liệu'],
                'days' => ['thu_bay', 'chu_nhat', 'thu_sau', 'thu_hai'],
            ],
            [
                'label' => 'Giao duc Ha Noi',
                'primary_area' => 'Hà Nội',
                'secondary_areas' => ['Thanh Hóa', 'Nghệ An', 'Khác'],
                'skills' => ['Giáo dục / Dạy học', 'Hỗ trợ trẻ em', 'Tổ chức trò chơi', 'Ngoại ngữ / Phiên dịch'],
                'days' => ['thu_bay', 'chu_nhat', 'thu_tu', 'thu_nam'],
            ],
            [
                'label' => 'Y te Can Tho',
                'primary_area' => 'Cần Thơ',
                'secondary_areas' => ['TP. Hồ Chí Minh', 'Đồng Nai', 'Khác'],
                'skills' => ['Y tế / Chăm sóc sức khỏe', 'Sơ cứu khẩn cấp', 'Điều phối nhóm', 'Hỗ trợ người cao tuổi'],
                'days' => ['thu_hai', 'thu_ba', 'thu_tu', 'chu_nhat'],
            ],
            [
                'label' => 'Cong dong Sai Gon',
                'primary_area' => 'TP. Hồ Chí Minh',
                'secondary_areas' => ['Đồng Nai', 'Tây Ninh', 'Khác'],
                'skills' => ['Điều phối nhóm', 'Truyền thông / Sự kiện', 'Hỗ trợ người cao tuổi', 'Nấu ăn / Hậu cần'],
                'days' => ['thu_sau', 'thu_bay', 'chu_nhat', 'thu_tu'],
            ],
            [
                'label' => 'Cuu tro Quang Tri',
                'primary_area' => 'Quảng Trị',
                'secondary_areas' => ['Huế', 'Thanh Hóa', 'Khác'],
                'skills' => ['Lái xe / Vận chuyển', 'Nấu ăn / Hậu cần', 'Khảo sát / Thu thập dữ liệu', 'Sơ cứu khẩn cấp'],
                'days' => ['thu_hai', 'thu_ba', 'thu_tu', 'thu_nam'],
            ],
            [
                'label' => 'Thieu nhi HCM',
                'primary_area' => 'TP. Hồ Chí Minh',
                'secondary_areas' => ['Đà Nẵng', 'Cần Thơ', 'Khác'],
                'skills' => ['Hỗ trợ trẻ em', 'Tổ chức trò chơi', 'Truyền thông / Sự kiện', 'Giáo dục / Dạy học'],
                'days' => ['thu_bay', 'chu_nhat', 'thu_sau', 'thu_nam'],
            ],
            [
                'label' => 'Nguoi cao tuoi Hue',
                'primary_area' => 'Huế',
                'secondary_areas' => ['Đà Nẵng', 'Nghệ An', 'Khác'],
                'skills' => ['Hỗ trợ người cao tuổi', 'Y tế / Chăm sóc sức khỏe', 'Tư vấn tâm lý', 'Điều phối nhóm'],
                'days' => ['thu_ba', 'thu_tu', 'thu_nam', 'chu_nhat'],
            ],
            [
                'label' => 'Cong nghe Ha Noi',
                'primary_area' => 'Hà Nội',
                'secondary_areas' => ['Hải Phòng', 'Đà Nẵng', 'Khác'],
                'skills' => ['Kỹ thuật / IT', 'Khảo sát / Thu thập dữ liệu', 'Ngoại ngữ / Phiên dịch', 'Thiết kế đồ họa'],
                'days' => ['thu_hai', 'thu_tu', 'thu_sau', 'chu_nhat'],
            ],
            [
                'label' => 'Cong trinh Nghe An',
                'primary_area' => 'Nghệ An',
                'secondary_areas' => ['Thanh Hóa', 'Quảng Trị', 'Khác'],
                'skills' => ['Xây dựng / Sửa chữa', 'Nấu ăn / Hậu cần', 'Điều phối nhóm', 'Lái xe / Vận chuyển'],
                'days' => ['thu_hai', 'thu_ba', 'thu_bay', 'chu_nhat'],
            ],
        ];
        $skillIdByName = $kyNangs->pluck('id', 'ten');
        $matchedVolunteerCutoff = (int) floor(self::TOTAL_VOLUNTEERS * 0.7);

        // 4. Tạo tập người dùng lớn hơn để test thực tế
        for ($i = 1; $i <= self::TOTAL_VOLUNTEERS; $i++) {
            $matchedProfile = $i <= $matchedVolunteerCutoff
                ? $profileBlueprints[($i - 1) % count($profileBlueprints)]
                : null;
            $diaPhuongTen = $matchedProfile['primary_area'] ?? $diaPhuongUuTien[($i - 1) % count($diaPhuongUuTien)];
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
            $xacThucEmailLuc = $i % 23 === 0 ? null : $now;
            $trangThai = $i % 29 === 0
                ? 'bi_khoa'
                : ($xacThucEmailLuc ? 'hoat_dong' : 'cho_duyet');
            $diaChiDuong = $soNhaMau[$i % count($soNhaMau)] . ', ' . $diaChiMau[$i % count($diaChiMau)];
            $latBase = (float) ($phuongXa->vi_do ?? $tinhThanh->vi_do ?? 16.0544);
            $lngBase = (float) ($phuongXa->kinh_do ?? $tinhThanh->kinh_do ?? 108.2022);

            $user = NguoiDung::updateOrCreate(
                ['email' => "tinh_nguyen_vien_$i@gmail.com"],
                [
                    'ho_ten' => $fullName,
                    'mat_khau' => $matKhauChung,
                    'so_dien_thoai' => sprintf('0987654%03d', $i),
                    'vai_tro' => 'tinh_nguyen_vien',
                    'trang_thai' => $trangThai,
                    'xac_thuc_email_luc' => $xacThucEmailLuc,
                    'ngay_sinh' => Carbon::create(1988 + ($i % 15), (($i % 12) + 1), (($i % 27) + 1))->toDateString(),
                    'gioi_tinh' => $gioiTinh,
                    'so_cccd' => sprintf('%012d', 310000000000 + $i),
                    'tinh_thanh_id' => $tinhThanh->id,
                    'phuong_xa_id' => $phuongXa?->id,
                    'dia_chi_duong' => $diaChiDuong,
                    'vi_do' => round($latBase + ((($i % 9) - 4) * 0.0021), 7),
                    'kinh_do' => round($lngBase + ((($i % 11) - 5) * 0.0021), 7),
                    'gioi_thieu' => $gioiThieuMau[$i % count($gioiThieuMau)] . ' Tôi có thể tham gia theo ca linh hoạt và ưu tiên các chiến dịch gần ' . $diaPhuongTen . ($matchedProfile ? ', đặc biệt phù hợp với nhóm "' . $matchedProfile['label'] . '".' : '.'),
                    'khung_gio_uu_tien' => $khungGioUuTien[array_rand($khungGioUuTien)],
                    'tuy_chon_thong_bao' => [
                        'campaign_new' => true,
                        'campaign_assign' => true,
                        'campaign_remind' => true,
                        'rating' => $i % 4 !== 0,
                        'email_digest' => $i % 3 === 0,
                        'ai_suggest' => true
                    ],
                    'tao_luc' => $now->copy()->subDays($i % 120),
                    'cap_nhat_luc' => $now->copy()->subDays($i % 45),
                ]
            );

            // Kỹ năng (3-8 kỹ năng) để recommendation có đủ độ phủ
            if (!empty($kyNangIds)) {
                $skillsToAttach = [];
                if ($matchedProfile) {
                    foreach ($matchedProfile['skills'] as $skillName) {
                        $skillId = $skillIdByName->get($skillName);
                        if ($skillId) {
                            $skillsToAttach[] = $skillId;
                        }
                    }
                    $skillCount = min(count($kyNangIds), 4 + ($i % 3));
                    for ($offset = 0; count($skillsToAttach) < $skillCount && $offset < count($kyNangIds) * 2; $offset++) {
                        $skillsToAttach[] = $kyNangIds[($i + ($offset * 5)) % count($kyNangIds)];
                    }
                } else {
                    $skillCount = 3 + ($i % 6);
                    for ($offset = 0; $offset < $skillCount; $offset++) {
                        $skillsToAttach[] = $kyNangIds[($i + ($offset * 3)) % count($kyNangIds)];
                    }
                }
                $user->kyNangs()->sync(array_values(array_unique($skillsToAttach)));
            }

            // Khu vực hoạt động (3-5 khu vực)
            $areasToAttach = [];
            $areasToAttach[] = $khuVucIdByName->get($diaPhuongTen);
            $preferredAreas = $matchedProfile
                ? array_merge([$matchedProfile['primary_area']], $matchedProfile['secondary_areas'])
                : [
                    $diaPhuongUuTien[$i % count($diaPhuongUuTien)],
                    $diaPhuongUuTien[($i + 3) % count($diaPhuongUuTien)],
                    $diaPhuongUuTien[($i + 6) % count($diaPhuongUuTien)],
                    'Khác'
                ];
            foreach ($preferredAreas as $areaName) {
                $areaId = $khuVucIdByName->get($areaName);
                if ($areaId) {
                    $areasToAttach[] = $areaId;
                }
            }
            $user->khuVucs()->sync(array_values(array_unique(array_filter($areasToAttach))));

            // Lịch rảnh (4-7 ngày) để tỉ lệ khớp cao hơn
            $user->lichRanhs()->delete();
            $dayCount = 4 + ($i % 4);
            $selectedDays = $matchedProfile ? $matchedProfile['days'] : [];
            for ($offset = 0; count($selectedDays) < $dayCount; $offset++) {
                $selectedDays[] = $thuTrongTuan[($i + $offset) % count($thuTrongTuan)];
            }
            foreach (array_values(array_unique($selectedDays)) as $day) {
                $user->lichRanhs()->create([
                    'thu_trong_tuan' => $day
                ]);
            }

            // Kinh nghiệm (2-5)
            $user->kinhNghiems()->delete();
            $numExp = 2 + ($i % 4);
            for ($k = 1; $k <= $numExp; $k++) {
                $template = $kinhNghiemMau[($i + $k) % count($kinhNghiemMau)];
                $user->kinhNghiems()->create([
                    'tieu_de' => $template['tieu_de'],
                    'to_chuc' => $template['to_chuc'],
                    'thoi_gian' => "Tháng " . (($k * 2) + ($i % 4)) . "/2024 - Tháng " . (($k * 2) + ($i % 4) + 2) . "/2024",
                    'mo_ta' => "Tham gia phối hợp triển khai hoạt động, làm việc nhóm, hỗ trợ hiện trường và báo cáo nhanh trong chiến dịch {$k}.",
                ]);
            }

            // Chứng chỉ (1-3) cho phần profile strength
            $user->chungChis()->delete();
            $numCert = 1 + ($i % 3);
            for ($c = 0; $c < $numCert; $c++) {
                $template = $chungChiMau[($i + $c) % count($chungChiMau)];
                $user->chungChis()->create([
                    'ten' => $template['ten'],
                    'don_vi_cap' => $template['don_vi_cap'],
                ]);
            }
        }

        $this->command?->info('✅ Đã seed ' . self::TOTAL_VOLUNTEERS . ' tình nguyện viên với hồ sơ phong phú cho màn gợi ý.');
    }
}
