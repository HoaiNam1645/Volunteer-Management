<?php

namespace Database\Seeders;

use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\NguoiDung;
use App\Models\LoaiChienDich;
use App\Models\KyNang;
use App\Models\KhuVuc;
use Illuminate\Database\Seeder;
use Carbon\Carbon;

class ChienDichSeeder extends Seeder
{
    public function run(): void
    {
        // Theo nghiệp vụ mới: TNV là người tạo chiến dịch, KDV là người duyệt.
        $nguoiTaoIds = NguoiDung::where('vai_tro', 'tinh_nguyen_vien')->pluck('id')->toArray();
        $kiemDuyetVienIds = NguoiDung::where('vai_tro', 'kiem_duyet_vien')->pluck('id')->toArray();
        $tnvIds = NguoiDung::where('vai_tro', 'tinh_nguyen_vien')->pluck('id')->toArray();
        $loaiIds = LoaiChienDich::pluck('id')->toArray();
        $loaiByName = LoaiChienDich::pluck('id', 'ten');
        $kyNangIds = KyNang::pluck('id')->toArray();
        $kyNangByName = KyNang::pluck('id', 'ten');
        $khuVucByName = KhuVuc::pluck('id', 'ten');

        if (empty($nguoiTaoIds) || empty($kiemDuyetVienIds) || empty($loaiIds)) {
            $this->command->warn('Cần có TNV, KDV và Loại chiến dịch trước. Bỏ qua ChienDichSeeder.');
            return;
        }

        $now = Carbon::now();

        $chienDichs = [
            [
                'tieu_de'           => 'Trồng cây xanh tại Công viên Gia Định',
                'mo_ta'             => 'Cùng nhau trồng 500 cây xanh tại công viên Gia Định nhằm tăng diện tích cây xanh cho thành phố. Hoạt động bao gồm đào hố, trồng cây, tưới nước và chăm sóc cây non.',
                'loai_chien_dich_id' => $loaiIds[0] ?? $loaiIds[0], // Môi trường
                'dia_diem'          => 'Công viên Gia Định, Quận Gò Vấp, TP.HCM',
                'vi_do'             => 10.8231,
                'kinh_do'           => 106.6780,
                'ngay_bat_dau'      => $now->copy()->addDays(7)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->addDays(8)->toDateString(),
                'han_dang_ky'       => $now->copy()->addDays(5)->toDateString(),
                'so_luong_toi_da'   => 30,
                'so_luong_toi_thieu' => 10,
                'muc_do_uu_tien'    => 'cao',
                'trang_thai'        => 'da_duyet',
            ],
            [
                'tieu_de'           => 'Dạy tiếng Anh miễn phí cho trẻ em vùng cao',
                'mo_ta'             => 'Chương trình dạy tiếng Anh cơ bản cho trẻ em tiểu học tại xã Tà Xùa, Sơn La. Tình nguyện viên sẽ dạy 2 buổi/ngày trong 3 ngày liên tục.',
                'loai_chien_dich_id' => $loaiIds[1] ?? $loaiIds[0], // Giáo dục
                'dia_diem'          => 'Xã Tà Xùa, Huyện Bắc Yên, Sơn La',
                'vi_do'             => 21.3256,
                'kinh_do'           => 103.9188,
                'ngay_bat_dau'      => $now->copy()->addDays(14)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->addDays(16)->toDateString(),
                'han_dang_ky'       => $now->copy()->addDays(10)->toDateString(),
                'so_luong_toi_da'   => 15,
                'so_luong_toi_thieu' => 5,
                'muc_do_uu_tien'    => 'trung_binh',
                'trang_thai'        => 'cho_duyet',
            ],
            [
                'tieu_de'           => 'Khám sức khỏe miễn phí cho người cao tuổi',
                'mo_ta'             => 'Phối hợp với Bệnh viện Đa khoa tổ chức khám sức khỏe, đo huyết áp, tư vấn dinh dưỡng miễn phí cho 200 người cao tuổi tại phường.',
                'loai_chien_dich_id' => $loaiIds[2] ?? $loaiIds[0], // Y tế
                'dia_diem'          => 'Nhà Văn hóa Phường 10, Quận 3, TP.HCM',
                'vi_do'             => 10.7756,
                'kinh_do'           => 106.6910,
                'ngay_bat_dau'      => $now->copy()->addDays(3)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->addDays(3)->toDateString(),
                'han_dang_ky'       => $now->copy()->addDays(1)->toDateString(),
                'so_luong_toi_da'   => 20,
                'so_luong_toi_thieu' => 8,
                'muc_do_uu_tien'    => 'khan_cap',
                'trang_thai'        => 'da_duyet',
            ],
            [
                'tieu_de'           => 'Dọn dẹp bãi biển Sơn Trà',
                'mo_ta'             => 'Hoạt động thu gom rác thải nhựa, làm sạch 2km bờ biển thuộc khu vực Sơn Trà. Dụng cụ thu gom sẽ được ban tổ chức cung cấp.',
                'loai_chien_dich_id' => $loaiIds[0] ?? $loaiIds[0], // Môi trường
                'dia_diem'          => 'Bãi biển Sơn Trà, Quận Sơn Trà, Đà Nẵng',
                'vi_do'             => 16.1050,
                'kinh_do'           => 108.2780,
                'ngay_bat_dau'      => $now->copy()->subDays(5)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->subDays(5)->toDateString(),
                'so_luong_toi_da'   => 50,
                'so_luong_toi_thieu' => 15,
                'muc_do_uu_tien'    => 'trung_binh',
                'trang_thai'        => 'hoan_thanh',
            ],
            [
                'tieu_de'           => 'Hỗ trợ nạn nhân lũ lụt tại Quảng Trị',
                'mo_ta'             => 'Vận chuyển và phân phát hàng cứu trợ, dọn dẹp bùn đất, hỗ trợ người dân ổn định cuộc sống sau lũ.',
                'loai_chien_dich_id' => $loaiIds[4] ?? $loaiIds[0], // Cứu trợ thiên tai
                'dia_diem'          => 'Huyện Hải Lăng, Quảng Trị',
                'vi_do'             => 16.7100,
                'kinh_do'           => 107.1900,
                'ngay_bat_dau'      => $now->copy()->addDays(2)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->addDays(5)->toDateString(),
                'han_dang_ky'       => $now->copy()->addDays(1)->toDateString(),
                'so_luong_toi_da'   => 40,
                'so_luong_toi_thieu' => 20,
                'muc_do_uu_tien'    => 'khan_cap',
                'trang_thai'        => 'da_duyet',
            ],
            [
                'tieu_de'           => 'Xây nhà tình thương tại Nghệ An',
                'mo_ta'             => 'Phối hợp xây dựng 2 căn nhà tình thương cho hộ gia đình khó khăn tại xã Quỳnh Thắng, Quỳnh Lưu, Nghệ An.',
                'loai_chien_dich_id' => $loaiIds[3] ?? $loaiIds[0], // Cộng đồng
                'dia_diem'          => 'Xã Quỳnh Thắng, Huyện Quỳnh Lưu, Nghệ An',
                'vi_do'             => 19.2342,
                'kinh_do'           => 105.6550,
                'ngay_bat_dau'      => $now->copy()->addDays(21)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->addDays(28)->toDateString(),
                'han_dang_ky'       => $now->copy()->addDays(18)->toDateString(),
                'so_luong_toi_da'   => 25,
                'so_luong_toi_thieu' => 10,
                'muc_do_uu_tien'    => 'cao',
                'trang_thai'        => 'yeu_cau_huy',
            ],
            [
                'tieu_de'           => 'Ngày hội hiến máu Xuân 2026',
                'mo_ta'             => 'Phối hợp với Viện Huyết học tổ chức ngày hội hiến máu nhân đạo. Tình nguyện viên hỗ trợ đón tiếp, hướng dẫn và chăm sóc người hiến máu.',
                'loai_chien_dich_id' => $loaiIds[2] ?? $loaiIds[0], // Y tế
                'dia_diem'          => 'Trường ĐH Bách Khoa, Quận 10, TP.HCM',
                'vi_do'             => 10.7725,
                'kinh_do'           => 106.6590,
                'ngay_bat_dau'      => $now->copy()->subDays(10)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->subDays(10)->toDateString(),
                'so_luong_toi_da'   => 35,
                'so_luong_toi_thieu' => 10,
                'muc_do_uu_tien'    => 'cao',
                'trang_thai'        => 'hoan_thanh',
            ],
            [
                'tieu_de'           => 'Phát quà Trung thu cho trẻ em mồ côi',
                'mo_ta'             => 'Tổ chức chương trình vui Trung thu, phát lồng đèn và quà cho 150 trẻ em tại các mái ấm trên địa bàn quận Bình Thạnh.',
                'loai_chien_dich_id' => $loaiIds[3] ?? $loaiIds[0], // Cộng đồng
                'dia_diem'          => 'Mái ấm Hải Đường, Quận Bình Thạnh, TP.HCM',
                'vi_do'             => 10.8050,
                'kinh_do'           => 106.7110,
                'ngay_bat_dau'      => $now->copy()->addDays(10)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->addDays(10)->toDateString(),
                'han_dang_ky'       => $now->copy()->addDays(8)->toDateString(),
                'so_luong_toi_da'   => 20,
                'so_luong_toi_thieu' => 8,
                'muc_do_uu_tien'    => 'trung_binh',
                'trang_thai'        => 'da_duyet',
            ],
            [
                'tieu_de'           => 'Chương trình hỗ trợ thư viện vùng ven',
                'mo_ta'             => 'Bổ sung đầu sách và tổ chức đọc sách cho trẻ em tại thư viện cộng đồng vùng ven.',
                'loai_chien_dich_id' => $loaiIds[1] ?? $loaiIds[0],
                'dia_diem'          => 'Nhà văn hóa xã Bình Mỹ, Củ Chi, TP.HCM',
                'vi_do'             => 10.9542,
                'kinh_do'           => 106.5320,
                'ngay_bat_dau'      => $now->copy()->addDays(11)->toDateString(),
                'ngay_ket_thuc'     => $now->copy()->addDays(13)->toDateString(),
                'han_dang_ky'       => $now->copy()->addDays(7)->toDateString(),
                'so_luong_toi_da'   => 18,
                'so_luong_toi_thieu' => 6,
                'muc_do_uu_tien'    => 'thap',
                'trang_thai'        => 'tu_choi',
                'ly_do_tu_choi'     => 'Kế hoạch tổ chức và phương án an toàn chưa đầy đủ.',
            ],
        ];

        $locationSeeds = [
            ['dia_diem' => 'Bán đảo Sơn Trà, Đà Nẵng', 'vi_do' => 16.1187, 'kinh_do' => 108.2991, 'khu_vuc' => 'Đà Nẵng'],
            ['dia_diem' => 'Công viên 29/3, Đà Nẵng', 'vi_do' => 16.0518, 'kinh_do' => 108.2103, 'khu_vuc' => 'Đà Nẵng'],
            ['dia_diem' => 'Phố đi bộ Hồ Gươm, Hà Nội', 'vi_do' => 21.0287, 'kinh_do' => 105.8523, 'khu_vuc' => 'Hà Nội'],
            ['dia_diem' => 'Làng trẻ SOS Gò Vấp, TP.HCM', 'vi_do' => 10.8364, 'kinh_do' => 106.6697, 'khu_vuc' => 'TP. Hồ Chí Minh'],
            ['dia_diem' => 'Bệnh viện Đa khoa Cần Thơ', 'vi_do' => 10.0371, 'kinh_do' => 105.7834, 'khu_vuc' => 'Cần Thơ'],
            ['dia_diem' => 'Bãi biển Mỹ Khê, Đà Nẵng', 'vi_do' => 16.0678, 'kinh_do' => 108.2468, 'khu_vuc' => 'Đà Nẵng'],
            ['dia_diem' => 'Trung tâm bảo trợ xã hội Hải Phòng', 'vi_do' => 20.8443, 'kinh_do' => 106.6897, 'khu_vuc' => 'Hải Phòng'],
            ['dia_diem' => 'Xã Triệu Long, Quảng Trị', 'vi_do' => 16.7392, 'kinh_do' => 107.1994, 'khu_vuc' => 'Quảng Trị'],
            ['dia_diem' => 'Nhà thiếu nhi Huế', 'vi_do' => 16.4691, 'kinh_do' => 107.5903, 'khu_vuc' => 'Huế'],
            ['dia_diem' => 'Xã Ia Kênh, Gia Lai', 'vi_do' => 13.9790, 'kinh_do' => 107.9912, 'khu_vuc' => 'Gia Lai'],
            ['dia_diem' => 'Trường THCS Quỳnh Thắng, Nghệ An', 'vi_do' => 19.2162, 'kinh_do' => 105.6541, 'khu_vuc' => 'Nghệ An'],
            ['dia_diem' => 'Phường Phước Hải, Khánh Hòa', 'vi_do' => 12.2279, 'kinh_do' => 109.2056, 'khu_vuc' => 'Khánh Hòa'],
            ['dia_diem' => 'Xã Tân Phú, Đồng Nai', 'vi_do' => 11.3508, 'kinh_do' => 107.3768, 'khu_vuc' => 'Đồng Nai'],
            ['dia_diem' => 'Chợ nổi Cái Răng, Cần Thơ', 'vi_do' => 10.0017, 'kinh_do' => 105.7851, 'khu_vuc' => 'Cần Thơ'],
            ['dia_diem' => 'Khu dân cư An Phú, TP.HCM', 'vi_do' => 10.7896, 'kinh_do' => 106.7475, 'khu_vuc' => 'TP. Hồ Chí Minh'],
        ];

        $campaignTemplates = [
            [
                'prefix' => 'Ngày chủ nhật xanh',
                'mo_ta' => 'Chiến dịch tập trung làm sạch khu vực công cộng, phân loại rác và tuyên truyền bảo vệ môi trường cho người dân địa phương.',
                'loai' => 'Môi trường',
                'uu_tien' => 'cao',
                'min' => 12,
                'max' => 35,
                'skills' => ['Môi trường', 'Điều phối nhóm', 'Truyền thông / Sự kiện'],
            ],
            [
                'prefix' => 'Lớp học cộng đồng cuối tuần',
                'mo_ta' => 'Tổ chức lớp học kỹ năng và học tập cho trẻ em có hoàn cảnh khó khăn, kết hợp sinh hoạt nhóm và hỗ trợ phụ huynh.',
                'loai' => 'Giáo dục',
                'uu_tien' => 'trung_binh',
                'min' => 8,
                'max' => 20,
                'skills' => ['Giáo dục / Dạy học', 'Hỗ trợ trẻ em', 'Tổ chức trò chơi'],
            ],
            [
                'prefix' => 'Khám sức khỏe cộng đồng',
                'mo_ta' => 'Hỗ trợ khám sàng lọc, tư vấn sức khỏe, phân luồng và chăm sóc người dân tại điểm khám lưu động.',
                'loai' => 'Y tế',
                'uu_tien' => 'khan_cap',
                'min' => 10,
                'max' => 24,
                'skills' => ['Y tế / Chăm sóc sức khỏe', 'Sơ cứu khẩn cấp', 'Điều phối nhóm'],
            ],
            [
                'prefix' => 'Kết nối yêu thương',
                'mo_ta' => 'Tổ chức hoạt động thăm hỏi, tặng quà và hỗ trợ sinh hoạt cho các nhóm yếu thế trong cộng đồng.',
                'loai' => 'Cộng đồng',
                'uu_tien' => 'cao',
                'min' => 10,
                'max' => 28,
                'skills' => ['Điều phối nhóm', 'Hỗ trợ người cao tuổi', 'Truyền thông / Sự kiện'],
            ],
            [
                'prefix' => 'Tiếp sức vùng lũ',
                'mo_ta' => 'Hỗ trợ vận chuyển hàng cứu trợ, khảo sát nhu cầu và phân phát nhu yếu phẩm cho người dân bị ảnh hưởng thiên tai.',
                'loai' => 'Cứu trợ thiên tai',
                'uu_tien' => 'khan_cap',
                'min' => 18,
                'max' => 45,
                'skills' => ['Lái xe / Vận chuyển', 'Nấu ăn / Hậu cần', 'Khảo sát / Thu thập dữ liệu'],
            ],
            [
                'prefix' => 'Ngày hội thiếu nhi',
                'mo_ta' => 'Tổ chức trò chơi, phát quà, giao lưu và hướng dẫn kỹ năng mềm cho trẻ em tại địa phương.',
                'loai' => 'Thiếu nhi',
                'uu_tien' => 'trung_binh',
                'min' => 8,
                'max' => 22,
                'skills' => ['Hỗ trợ trẻ em', 'Tổ chức trò chơi', 'Truyền thông / Sự kiện'],
            ],
            [
                'prefix' => 'Chăm sóc người cao tuổi',
                'mo_ta' => 'Thăm hỏi, hỗ trợ sinh hoạt, tổ chức hoạt động giao lưu và đo huyết áp cho người cao tuổi.',
                'loai' => 'Người cao tuổi',
                'uu_tien' => 'trung_binh',
                'min' => 6,
                'max' => 18,
                'skills' => ['Hỗ trợ người cao tuổi', 'Y tế / Chăm sóc sức khỏe', 'Tư vấn tâm lý'],
            ],
            [
                'prefix' => 'Công nghệ cho cộng đồng',
                'mo_ta' => 'Hỗ trợ người dân làm quen với dịch vụ số, thiết bị cơ bản và kỹ năng sử dụng công nghệ trong đời sống.',
                'loai' => 'Công nghệ vì cộng đồng',
                'uu_tien' => 'thap',
                'min' => 5,
                'max' => 16,
                'skills' => ['Kỹ thuật / IT', 'Khảo sát / Thu thập dữ liệu', 'Ngoại ngữ / Phiên dịch'],
            ],
            [
                'prefix' => 'Sơn sửa nhà tình thương',
                'mo_ta' => 'Hỗ trợ sửa chữa, sơn mới và hoàn thiện các hạng mục cơ bản cho nhà của hộ gia đình khó khăn.',
                'loai' => 'Nhà ở / Công trình',
                'uu_tien' => 'cao',
                'min' => 12,
                'max' => 30,
                'skills' => ['Xây dựng / Sửa chữa', 'Nấu ăn / Hậu cần', 'Điều phối nhóm'],
            ],
        ];

        $generatedStatuses = [
            'da_duyet', 'da_duyet', 'da_duyet', 'da_duyet',
            'cho_duyet', 'da_duyet', 'hoan_thanh', 'da_duyet',
            'tu_choi', 'da_duyet', 'yeu_cau_huy', 'hoan_thanh',
            'da_duyet', 'da_duyet', 'cho_duyet', 'da_duyet',
            'hoan_thanh', 'da_duyet', 'da_duyet', 'tu_choi',
            'da_duyet', 'yeu_cau_huy', 'da_duyet', 'hoan_thanh',
        ];

        foreach ($generatedStatuses as $index => $status) {
            $template = $campaignTemplates[$index % count($campaignTemplates)];
            $location = $locationSeeds[$index % count($locationSeeds)];
            $start = match ($status) {
                'hoan_thanh' => $now->copy()->subDays(25 - ($index % 8)),
                'tu_choi' => $now->copy()->addDays(12 + ($index % 6)),
                'cho_duyet' => $now->copy()->addDays(8 + ($index % 10)),
                'yeu_cau_huy' => $now->copy()->addDays(6 + ($index % 5)),
                default => $now->copy()->addDays(3 + ($index % 20)),
            };
            $durationDays = 1 + ($index % 4);
            $end = $start->copy()->addDays($durationDays);
            $deadline = match ($status) {
                'hoan_thanh' => $start->copy()->subDays(3),
                default => $start->copy()->subDays(2 + ($index % 3)),
            };

            $chienDichs[] = [
                'tieu_de' => $template['prefix'] . ' - ' . $location['khu_vuc'] . ' #' . str_pad((string) ($index + 1), 2, '0', STR_PAD_LEFT),
                'mo_ta' => $template['mo_ta'],
                'loai_chien_dich_id' => $loaiByName[$template['loai']] ?? $loaiIds[0],
                'dia_diem' => $location['dia_diem'],
                'khu_vuc_ten' => $location['khu_vuc'],
                'vi_do' => $location['vi_do'] + ((($index % 3) - 1) * 0.004),
                'kinh_do' => $location['kinh_do'] + ((($index % 5) - 2) * 0.004),
                'ngay_bat_dau' => $start->toDateString(),
                'ngay_ket_thuc' => $end->toDateString(),
                'han_dang_ky' => $deadline->toDateString(),
                'so_luong_toi_da' => $template['max'] + ($index % 6),
                'so_luong_toi_thieu' => $template['min'],
                'muc_do_uu_tien' => $template['uu_tien'],
                'trang_thai' => $status,
                'ly_do_tu_choi' => $status === 'tu_choi' ? 'Nội dung kế hoạch hoặc phương án tổ chức chưa đủ rõ ràng.' : null,
                'skills_seed' => $template['skills'],
            ];
        }

        foreach ($chienDichs as $index => $cdData) {
            $skillsSeed = $cdData['skills_seed'] ?? [];
            $khuVucTen = $cdData['khu_vuc_ten'] ?? null;
            unset($cdData['skills_seed']);
            unset($cdData['khu_vuc_ten']);

            // Người tạo chiến dịch là TNV, luân phiên theo dữ liệu seed.
            $cdData['nguoi_tao_id'] = $nguoiTaoIds[$index % count($nguoiTaoIds)];
            $cdData['khu_vuc_id'] = $khuVucTen ? ($khuVucByName[$khuVucTen] ?? null) : null;

            // Nếu đã duyệt / hoàn thành → gán KDV duyệt.
            if (in_array($cdData['trang_thai'], ['da_duyet', 'dang_dien_ra', 'hoan_thanh', 'tu_choi', 'yeu_cau_huy'])) {
                $cdData['duyet_boi'] = $kiemDuyetVienIds[$index % count($kiemDuyetVienIds)];
                $cdData['duyet_luc'] = $now->copy()->subDays(rand(1, 5));
            }

            $cdData['tao_luc'] = $now;
            $cdData['cap_nhat_luc'] = $now;

            $cd = ChienDich::updateOrCreate(
                ['tieu_de' => $cdData['tieu_de']],
                $cdData
            );

            // Gắn kỹ năng theo chủ đề chiến dịch, bổ sung thêm 1 kỹ năng liên quan nếu cần.
            if (!empty($kyNangIds)) {
                $skillsData = [];
                $seedSkillIds = [];
                foreach ($skillsSeed as $skillName) {
                    $skillId = $kyNangByName[$skillName] ?? null;
                    if ($skillId) {
                        $seedSkillIds[] = $skillId;
                    }
                }
                if (count($seedSkillIds) < 2) {
                    $seedSkillIds[] = $kyNangIds[$index % count($kyNangIds)];
                    $seedSkillIds[] = $kyNangIds[($index + 4) % count($kyNangIds)];
                }

                $seedSkillIds = array_values(array_unique($seedSkillIds));
                foreach ($seedSkillIds as $skillIndex => $skillId) {
                    $skillsData[$skillId] = [
                        'bat_buoc' => $skillIndex === 0 ? 1 : (($index + $skillIndex) % 2),
                        'tao_luc'  => $now,
                    ];
                }
                $cd->kyNangs()->sync($skillsData);
            }

            // Tạo đăng ký tham gia theo đúng logic trạng thái tham gia.
            if (in_array($cd->trang_thai, ['da_duyet', 'dang_dien_ra', 'hoan_thanh', 'yeu_cau_huy']) && !empty($tnvIds)) {
                $ungVienIds = array_values(array_filter($tnvIds, fn ($id) => $id !== $cd->nguoi_tao_id));

                if (!empty($ungVienIds)) {
                    shuffle($ungVienIds);
                    $numRegistrations = min(
                        max(3, $cd->so_luong_toi_thieu ? min($cd->so_luong_toi_thieu + 2, 8) : 4),
                        count($ungVienIds)
                    );
                    $selectedTnvIds = array_slice($ungVienIds, 0, $numRegistrations);

                    // Xóa đăng ký cũ để tránh giữ lại dữ liệu seed sai logic từ các lần chạy trước.
                    DangKyThamGia::where('chien_dich_id', $cd->id)->delete();

                    $soDangKy = 0;
                    $soXacNhan = 0;

                    foreach ($selectedTnvIds as $indexTnv => $tnvId) {
                        $dangKyData = $this->buildRegistrationSeedData($cd->trang_thai, $now, $indexTnv);

                        DangKyThamGia::create([
                            'chien_dich_id' => $cd->id,
                            'nguoi_dung_id' => $tnvId,
                            'trang_thai' => $dangKyData['trang_thai'],
                            'dang_ky_luc' => $dangKyData['dang_ky_luc'],
                            'duyet_luc' => null,
                            'xac_nhan_luc' => $dangKyData['xac_nhan_luc'],
                            'huy_luc' => null,
                            'ly_do_huy' => null,
                            'ghi_chu' => $dangKyData['ghi_chu'],
                        ]);

                        if (!in_array($dangKyData['trang_thai'], ['da_huy', 'tu_choi'], true)) {
                            $soDangKy++;
                        }

                        if (in_array($dangKyData['trang_thai'], ['da_xac_nhan', 'dang_tham_gia', 'hoan_thanh'], true)) {
                            $soXacNhan++;
                        }
                    }

                    $cd->update([
                        'so_dang_ky'  => $soDangKy,
                        'so_xac_nhan' => $soXacNhan,
                    ]);
                }
            }
        }

        $this->command->info('✅ Đã seed ' . count($chienDichs) . ' chiến dịch + đăng ký tham gia.');
    }

    private function buildRegistrationSeedData(string $trangThaiChienDich, Carbon $now, int $indexTnv): array
    {
        $dangKyLuc = $now->copy()->subDays(rand(2, 10));

        return match ($trangThaiChienDich) {
            'da_duyet' => [
                // Giữ lẫn cả người mới đăng ký và người đã xác nhận để test đủ flow.
                'trang_thai' => $indexTnv % 2 === 0 ? 'da_dang_ky' : 'da_xac_nhan',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => $indexTnv % 2 === 0 ? null : $dangKyLuc->copy()->addDay(),
                'ghi_chu' => $indexTnv % 2 === 0
                    ? 'Tình nguyện viên đã đăng ký và đang chờ xác nhận tham gia.'
                    : 'Tình nguyện viên đã xác nhận tham gia chiến dịch.',
            ],
            'yeu_cau_huy' => [
                // Yêu cầu hủy thường xảy ra khi đã có người xác nhận.
                'trang_thai' => 'da_xac_nhan',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => $dangKyLuc->copy()->addDay(),
                'ghi_chu' => 'Tình nguyện viên đã xác nhận, chiến dịch đang chờ xử lý yêu cầu hủy.',
            ],
            'dang_dien_ra' => [
                'trang_thai' => 'dang_tham_gia',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => $dangKyLuc->copy()->addDay(),
                'ghi_chu' => 'Tình nguyện viên đang tham gia chiến dịch.',
            ],
            'hoan_thanh' => [
                'trang_thai' => 'hoan_thanh',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => $dangKyLuc->copy()->addDay(),
                'ghi_chu' => 'Tình nguyện viên đã hoàn tất tham gia chiến dịch.',
            ],
            default => [
                'trang_thai' => 'da_dang_ky',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => null,
                'ghi_chu' => 'Tình nguyện viên đã đăng ký tham gia chiến dịch.',
            ],
        };
    }
}
