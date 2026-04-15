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
    private const GENERATED_CAMPAIGN_COUNT = 120;

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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'phủ xanh thêm khu vực công viên Gia Định và nâng cao ý thức bảo vệ môi trường trong cộng đồng',
                    'problem' => 'mật độ cây xanh tại một số khu vực công cộng còn thấp và người dân chưa có nhiều hoạt động thực hành bảo vệ môi trường',
                    'tasks' => 'đào hố, trồng cây, tưới nước, dọn khu vực trồng và hướng dẫn người tham gia chăm sóc cây non đúng cách',
                    'commitment' => 'có mặt đúng giờ, làm việc theo nhóm, tuân thủ hướng dẫn an toàn lao động và tham gia trọn vẹn ca hoạt động',
                    'benefits' => 'được cung cấp dụng cụ làm việc, nước uống, áo chiến dịch và xác nhận tham gia hoạt động cộng đồng',
                    'contact' => 'Ban điều phối môi trường VMS, hotline 0909 100 101, email moi-truong@vms.vn',
                ]),
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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'bổ trợ kiến thức tiếng Anh cơ bản và tạo môi trường học tập tích cực cho trẻ em vùng cao',
                    'problem' => 'nhiều em học sinh tại khu vực này thiếu điều kiện tiếp cận lớp học ngoại ngữ và hoạt động tương tác thực hành',
                    'tasks' => 'đứng lớp theo nhóm nhỏ, hỗ trợ phát âm, tổ chức trò chơi học tập và đồng hành cùng giáo viên phụ trách trong 3 ngày liên tục',
                    'commitment' => 'chuẩn bị giáo án đơn giản, tham gia đủ các buổi dạy và giữ thái độ kiên nhẫn, tích cực với học sinh',
                    'benefits' => 'được hỗ trợ tài liệu giảng dạy, chỗ nghỉ cơ bản, suất ăn và giấy xác nhận tham gia chương trình',
                    'contact' => 'Điều phối giáo dục khu vực Tây Bắc, hotline 0909 100 102, email giaoduc@vms.vn',
                ]),
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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'hỗ trợ người cao tuổi được tiếp cận hoạt động khám sàng lọc và tư vấn sức khỏe miễn phí ngay tại địa phương',
                    'problem' => 'nhiều người cao tuổi chưa có điều kiện theo dõi sức khỏe định kỳ và cần được hướng dẫn chăm sóc phù hợp',
                    'tasks' => 'đón tiếp người dân, phân luồng, hỗ trợ đo chỉ số cơ bản, ghi nhận thông tin và hướng dẫn di chuyển giữa các bàn khám',
                    'commitment' => 'làm việc cẩn thận, giữ thái độ tôn trọng với người cao tuổi và tuân thủ phân công của đội ngũ y tế',
                    'benefits' => 'được tập huấn nhanh trước ca, hỗ trợ ăn nhẹ, áo nhận diện và chứng nhận tham gia chiến dịch',
                    'contact' => 'Tổ y tế cộng đồng VMS, hotline 0909 100 103, email yte@vms.vn',
                ]),
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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'làm sạch bãi biển Sơn Trà và lan tỏa thông điệp giảm rác thải nhựa tại khu vực ven biển',
                    'problem' => 'rác thải nhựa và rác sinh hoạt tích tụ dọc bờ biển gây ảnh hưởng đến cảnh quan và hệ sinh thái',
                    'tasks' => 'thu gom rác, phân loại rác tại chỗ, vận chuyển về điểm tập kết và hỗ trợ truyền thông cho người dân, du khách',
                    'commitment' => 'mang giày phù hợp, tuân thủ hướng dẫn an toàn ngoài trời và tham gia đủ thời lượng chương trình',
                    'benefits' => 'được cấp bao tay, kẹp gắp rác, nước uống, áo sự kiện và xác nhận đóng góp cho hoạt động môi trường',
                    'contact' => 'Nhóm điều phối biển xanh, hotline 0909 100 104, email bienxanh@vms.vn',
                ]),
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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'hỗ trợ khẩn cấp người dân vùng lũ sớm ổn định sinh hoạt và tiếp cận nhu yếu phẩm thiết yếu',
                    'problem' => 'nhiều hộ gia đình bị ảnh hưởng bởi lũ lụt thiếu lương thực, vật dụng thiết yếu và nhân lực hỗ trợ dọn dẹp',
                    'tasks' => 'vận chuyển hàng cứu trợ, phân phát nhu yếu phẩm, dọn bùn đất, khảo sát nhu cầu và hỗ trợ sắp xếp nơi ở tạm',
                    'commitment' => 'chấp hành điều phối hiện trường, ưu tiên an toàn cá nhân và sẵn sàng làm việc trong điều kiện khẩn cấp',
                    'benefits' => 'được trang bị bảo hộ cơ bản, hỗ trợ suất ăn, phương tiện di chuyển tại chỗ và xác nhận hoạt động cứu trợ',
                    'contact' => 'Ban chỉ huy cứu trợ miền Trung, hotline 0909 100 105, email cuutro@vms.vn',
                ]),
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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'chung tay cải thiện điều kiện nhà ở cho các hộ gia đình có hoàn cảnh khó khăn tại địa phương',
                    'problem' => 'một số hộ dân vẫn đang sống trong nhà xuống cấp, thiếu an toàn và cần được sửa chữa hoặc xây mới',
                    'tasks' => 'hỗ trợ vận chuyển vật liệu, phụ việc xây dựng cơ bản, dọn vệ sinh công trình và hậu cần cho đội thi công',
                    'commitment' => 'tham gia theo ca được phân công, tuân thủ nghiêm ngặt quy định an toàn công trình và phối hợp với đội kỹ thuật',
                    'benefits' => 'được hướng dẫn trước khi làm việc, hỗ trợ ăn uống tại chỗ, trang bị bảo hộ cơ bản và ghi nhận giờ công thiện nguyện',
                    'contact' => 'Điều phối công trình cộng đồng, hotline 0909 100 106, email congdong@vms.vn',
                ]),
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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'góp phần bổ sung nguồn máu dự trữ và nâng cao nhận thức cộng đồng về hiến máu nhân đạo',
                    'problem' => 'nguồn máu phục vụ cấp cứu và điều trị luôn cần được bổ sung ổn định từ các chương trình hiến máu cộng đồng',
                    'tasks' => 'đón tiếp người tham gia, hướng dẫn khai thông tin, điều phối khu vực chờ và hỗ trợ chăm sóc sau hiến máu',
                    'commitment' => 'làm việc đúng quy trình, giao tiếp thân thiện và giữ thái độ cẩn trọng trong suốt thời gian chương trình diễn ra',
                    'benefits' => 'được tập huấn nhanh, hỗ trợ suất ăn nhẹ, áo chương trình và giấy chứng nhận tham gia sự kiện nhân đạo',
                    'contact' => 'Ban tổ chức hiến máu VMS, hotline 0909 100 107, email hienmau@vms.vn',
                ]),
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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'mang đến một mùa Trung thu vui vẻ, ấm áp và giàu trải nghiệm cho trẻ em tại các mái ấm',
                    'problem' => 'nhiều em nhỏ có hoàn cảnh đặc biệt ít có cơ hội tham gia hoạt động lễ hội và nhận quà ý nghĩa trong dịp Trung thu',
                    'tasks' => 'chuẩn bị quà tặng, tổ chức trò chơi, giao lưu văn nghệ, phát lồng đèn và hỗ trợ điều phối chương trình tại mái ấm',
                    'commitment' => 'giữ thái độ tích cực, thân thiện với trẻ em, tham gia đủ ca và tuân thủ kịch bản hoạt động',
                    'benefits' => 'được hỗ trợ hậu cần, tài liệu hoạt náo, suất ăn nhẹ và giấy xác nhận sau chương trình',
                    'contact' => 'Nhóm điều phối thiếu nhi VMS, hotline 0909 100 108, email thieunhi@vms.vn',
                ]),
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
                'mo_ta'             => $this->buildCampaignDescription([
                    'purpose' => 'phát triển thói quen đọc sách và tạo thêm hoạt động học tập tích cực cho trẻ em vùng ven',
                    'problem' => 'thư viện cộng đồng còn thiếu đầu sách phù hợp và chưa có nhiều hoạt động thu hút trẻ em đến đọc sách thường xuyên',
                    'tasks' => 'phân loại sách, sắp xếp kệ, đọc sách cùng trẻ, tổ chức trò chơi tương tác và hỗ trợ vận hành góc thư viện',
                    'commitment' => 'tham gia đúng giờ, giữ gìn sách và không gian thư viện, phối hợp tốt với người phụ trách địa phương',
                    'benefits' => 'được hỗ trợ tài liệu hoạt động, nước uống, áo chiến dịch và xác nhận đóng góp cộng đồng',
                    'contact' => 'Điều phối thư viện cộng đồng, hotline 0909 100 109, email thuvien@vms.vn',
                ]),
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
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'cải thiện vệ sinh môi trường tại khu vực công cộng và lan tỏa thói quen sống xanh',
                    'problem' => 'rác thải sinh hoạt chưa được phân loại tốt và ý thức bảo vệ môi trường tại địa phương còn hạn chế',
                    'tasks' => 'làm sạch khu vực công cộng, phân loại rác, hỗ trợ vận chuyển rác và tuyên truyền trực tiếp cho người dân',
                    'commitment' => 'tham gia trọn buổi, tuân thủ hướng dẫn phân loại rác và phối hợp theo đội nhóm',
                    'benefits' => 'được cấp dụng cụ vệ sinh, nước uống, áo chiến dịch và xác nhận tham gia hoạt động môi trường',
                    'contact' => 'Nhóm điều phối môi trường địa phương, hotline 0909 200 201, email sundaygreen@vms.vn',
                ]),
                'loai' => 'Môi trường',
                'uu_tien' => 'cao',
                'min' => 12,
                'max' => 35,
                'skills' => ['Môi trường', 'Điều phối nhóm', 'Truyền thông / Sự kiện'],
            ],
            [
                'prefix' => 'Lớp học cộng đồng cuối tuần',
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'bổ sung kiến thức và kỹ năng mềm cho trẻ em có hoàn cảnh khó khăn vào dịp cuối tuần',
                    'problem' => 'nhiều em thiếu môi trường học tập bổ trợ và phụ huynh chưa có nhiều nguồn hỗ trợ đồng hành',
                    'tasks' => 'dạy học theo nhóm nhỏ, tổ chức sinh hoạt nhóm, hỗ trợ bài tập và kết nối thông tin với phụ huynh',
                    'commitment' => 'chuẩn bị nội dung trước buổi học, tham gia đủ lịch và giữ thái độ tích cực với học sinh',
                    'benefits' => 'được cấp tài liệu hoạt động, hỗ trợ ăn nhẹ và xác nhận tham gia chương trình giáo dục cộng đồng',
                    'contact' => 'Điều phối lớp học cộng đồng, hotline 0909 200 202, email lophoc@vms.vn',
                ]),
                'loai' => 'Giáo dục',
                'uu_tien' => 'trung_binh',
                'min' => 8,
                'max' => 20,
                'skills' => ['Giáo dục / Dạy học', 'Hỗ trợ trẻ em', 'Tổ chức trò chơi'],
            ],
            [
                'prefix' => 'Khám sức khỏe cộng đồng',
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'hỗ trợ người dân được tiếp cận khám sàng lọc và tư vấn sức khỏe ngay tại điểm khám lưu động',
                    'problem' => 'nhiều người dân chưa chủ động kiểm tra sức khỏe định kỳ và cần được hướng dẫn y tế cơ bản',
                    'tasks' => 'phân luồng, đo chỉ số cơ bản, hướng dẫn khai báo thông tin và hỗ trợ chăm sóc người dân tại điểm khám',
                    'commitment' => 'làm việc đúng quy trình, giao tiếp lịch sự và tuân thủ điều phối của đội chuyên môn',
                    'benefits' => 'được tập huấn nhanh, hỗ trợ ăn nhẹ, trang phục nhận diện và ghi nhận đóng góp cộng đồng',
                    'contact' => 'Tổ điều phối y tế lưu động, hotline 0909 200 203, email khamsuckhoe@vms.vn',
                ]),
                'loai' => 'Y tế',
                'uu_tien' => 'khan_cap',
                'min' => 10,
                'max' => 24,
                'skills' => ['Y tế / Chăm sóc sức khỏe', 'Sơ cứu khẩn cấp', 'Điều phối nhóm'],
            ],
            [
                'prefix' => 'Kết nối yêu thương',
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'mang lại sự quan tâm, hỗ trợ thiết thực và kết nối cộng đồng với các nhóm yếu thế',
                    'problem' => 'nhiều người thuộc nhóm yếu thế thiếu nguồn hỗ trợ tinh thần, vật chất và các hoạt động đồng hành thường xuyên',
                    'tasks' => 'thăm hỏi, tặng quà, hỗ trợ sinh hoạt cơ bản, ghi nhận nhu cầu và tổ chức các hoạt động giao lưu',
                    'commitment' => 'giữ thái độ tôn trọng, lắng nghe người được hỗ trợ và tham gia theo ca đã đăng ký',
                    'benefits' => 'được hỗ trợ hậu cần, nước uống, tài liệu chương trình và xác nhận tham gia chiến dịch',
                    'contact' => 'Nhóm kết nối cộng đồng VMS, hotline 0909 200 204, email ketnoi@vms.vn',
                ]),
                'loai' => 'Cộng đồng',
                'uu_tien' => 'cao',
                'min' => 10,
                'max' => 28,
                'skills' => ['Điều phối nhóm', 'Hỗ trợ người cao tuổi', 'Truyền thông / Sự kiện'],
            ],
            [
                'prefix' => 'Tiếp sức vùng lũ',
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'kịp thời hỗ trợ người dân vùng thiên tai tiếp cận nhu yếu phẩm và nguồn lực cần thiết',
                    'problem' => 'người dân bị ảnh hưởng bởi mưa lũ đang thiếu hàng cứu trợ và cần thêm nhân lực hỗ trợ hiện trường',
                    'tasks' => 'vận chuyển hàng, khảo sát nhu cầu, phân phát nhu yếu phẩm và hỗ trợ sắp xếp điểm tiếp nhận cứu trợ',
                    'commitment' => 'sẵn sàng làm việc trong điều kiện khẩn cấp, tuân thủ an toàn và chấp hành điều phối tập trung',
                    'benefits' => 'được hỗ trợ phương tiện nội bộ, đồ bảo hộ cơ bản, suất ăn và ghi nhận tham gia hoạt động cứu trợ',
                    'contact' => 'Ban điều phối cứu trợ khẩn cấp, hotline 0909 200 205, email tiepsuzunglu@vms.vn',
                ]),
                'loai' => 'Cứu trợ thiên tai',
                'uu_tien' => 'khan_cap',
                'min' => 18,
                'max' => 45,
                'skills' => ['Lái xe / Vận chuyển', 'Nấu ăn / Hậu cần', 'Khảo sát / Thu thập dữ liệu'],
            ],
            [
                'prefix' => 'Ngày hội thiếu nhi',
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'tạo sân chơi vui tươi và hỗ trợ phát triển kỹ năng mềm cho trẻ em tại địa phương',
                    'problem' => 'trẻ em thiếu không gian vui chơi bổ ích và các hoạt động hướng dẫn kỹ năng ngoài giờ học',
                    'tasks' => 'tổ chức trò chơi, phát quà, giao lưu, hỗ trợ sân khấu và hướng dẫn kỹ năng mềm theo nhóm',
                    'commitment' => 'tham gia đúng giờ, giữ năng lượng tích cực và tuân thủ kịch bản chương trình cho trẻ em',
                    'benefits' => 'được hỗ trợ hậu cần, tài liệu hoạt náo, nước uống và giấy xác nhận tham gia',
                    'contact' => 'Điều phối sự kiện thiếu nhi, hotline 0909 200 206, email ngayhoithieunhi@vms.vn',
                ]),
                'loai' => 'Thiếu nhi',
                'uu_tien' => 'trung_binh',
                'min' => 8,
                'max' => 22,
                'skills' => ['Hỗ trợ trẻ em', 'Tổ chức trò chơi', 'Truyền thông / Sự kiện'],
            ],
            [
                'prefix' => 'Chăm sóc người cao tuổi',
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'đồng hành, chăm sóc và tạo thêm hoạt động giao lưu cho người cao tuổi trong cộng đồng',
                    'problem' => 'nhiều người cao tuổi cần được hỗ trợ sinh hoạt nhẹ nhàng và có thêm cơ hội giao tiếp, kết nối',
                    'tasks' => 'thăm hỏi, hỗ trợ sinh hoạt, tổ chức giao lưu, đo huyết áp cơ bản và ghi nhận nhu cầu hỗ trợ',
                    'commitment' => 'giữ thái độ kiên nhẫn, nhẹ nhàng, tôn trọng người cao tuổi và tuân thủ lịch trình điều phối',
                    'benefits' => 'được tập huấn ngắn, hỗ trợ hậu cần, áo nhận diện và xác nhận tham gia hoạt động cộng đồng',
                    'contact' => 'Tổ điều phối người cao tuổi, hotline 0909 200 207, email nguoicaotuoi@vms.vn',
                ]),
                'loai' => 'Người cao tuổi',
                'uu_tien' => 'trung_binh',
                'min' => 6,
                'max' => 18,
                'skills' => ['Hỗ trợ người cao tuổi', 'Y tế / Chăm sóc sức khỏe', 'Tư vấn tâm lý'],
            ],
            [
                'prefix' => 'Công nghệ cho cộng đồng',
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'giúp người dân tiếp cận thuận tiện hơn với công nghệ số và dịch vụ công trực tuyến',
                    'problem' => 'nhiều người dân còn gặp khó khăn khi sử dụng điện thoại thông minh, ứng dụng số và các dịch vụ trực tuyến',
                    'tasks' => 'hướng dẫn thao tác cơ bản trên thiết bị, hỗ trợ cài ứng dụng cần thiết và giải đáp thắc mắc trực tiếp',
                    'commitment' => 'giải thích rõ ràng, kiên nhẫn, hỗ trợ đúng nội dung chương trình và tham gia đủ ca đã đăng ký',
                    'benefits' => 'được cung cấp tài liệu hướng dẫn, nước uống, áo chiến dịch và ghi nhận đóng góp chuyên môn',
                    'contact' => 'Nhóm công nghệ cộng đồng, hotline 0909 200 208, email congnghe@vms.vn',
                ]),
                'loai' => 'Công nghệ vì cộng đồng',
                'uu_tien' => 'thap',
                'min' => 5,
                'max' => 16,
                'skills' => ['Kỹ thuật / IT', 'Khảo sát / Thu thập dữ liệu', 'Ngoại ngữ / Phiên dịch'],
            ],
            [
                'prefix' => 'Sơn sửa nhà tình thương',
                'mo_ta' => $this->buildCampaignDescription([
                    'purpose' => 'cải thiện không gian sống an toàn và sạch sẽ hơn cho các hộ gia đình khó khăn',
                    'problem' => 'nhiều căn nhà xuống cấp cần được sửa chữa các hạng mục cơ bản nhưng thiếu nhân lực hỗ trợ',
                    'tasks' => 'sơn mới, dọn dẹp, phụ việc sửa chữa đơn giản và hỗ trợ hậu cần cho nhóm thi công chính',
                    'commitment' => 'tuân thủ hướng dẫn an toàn, tham gia đủ thời lượng và phối hợp chặt chẽ với nhóm phụ trách kỹ thuật',
                    'benefits' => 'được trang bị bảo hộ cơ bản, hỗ trợ ăn uống và xác nhận giờ công tham gia chiến dịch',
                    'contact' => 'Ban điều phối nhà tình thương, hotline 0909 200 209, email sonsuanhanh@vms.vn',
                ]),
                'loai' => 'Nhà ở / Công trình',
                'uu_tien' => 'cao',
                'min' => 12,
                'max' => 30,
                'skills' => ['Xây dựng / Sửa chữa', 'Nấu ăn / Hậu cần', 'Điều phối nhóm'],
            ],
        ];

        $statusPattern = [
            'da_duyet',
            'da_duyet',
            'da_duyet',
            'cho_duyet',
            'da_duyet',
            'hoan_thanh',
            'da_duyet',
            'tu_choi',
            'da_duyet',
            'yeu_cau_huy',
        ];
        $generatedStatuses = [];
        for ($i = 0; $i < self::GENERATED_CAMPAIGN_COUNT; $i++) {
            $generatedStatuses[] = $statusPattern[$i % count($statusPattern)];
        }

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

            $seedMonth = $now->copy()->startOfMonth()->subMonths(11 - ($index % 12));
            $createdAt = $seedMonth->copy()->addDays(($index * 2) % 24)->setTime(8 + ($index % 6), 0);
            $updatedAt = $createdAt->copy()->addDays(1 + ($index % 4));

            // Người tạo chiến dịch là TNV, luân phiên theo dữ liệu seed.
            $cdData['nguoi_tao_id'] = $nguoiTaoIds[$index % count($nguoiTaoIds)];
            $cdData['khu_vuc_id'] = $khuVucTen ? ($khuVucByName[$khuVucTen] ?? null) : null;

            // Nếu đã duyệt / hoàn thành → gán KDV duyệt.
            if (in_array($cdData['trang_thai'], ['da_duyet', 'dang_dien_ra', 'hoan_thanh', 'tu_choi', 'yeu_cau_huy'])) {
                $cdData['duyet_boi'] = $kiemDuyetVienIds[$index % count($kiemDuyetVienIds)];
                $cdData['duyet_luc'] = $createdAt->copy()->addDays(1 + ($index % 3));
                $updatedAt = $cdData['duyet_luc']->copy()->addDay();
            }

            $cdData['tao_luc'] = $createdAt;
            $cdData['cap_nhat_luc'] = $updatedAt;

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
                        max(6, $cd->so_luong_toi_thieu ? min($cd->so_luong_toi_thieu + 6, 20) : 8),
                        count($ungVienIds)
                    );
                    $selectedTnvIds = array_slice($ungVienIds, 0, $numRegistrations);

                    // Xóa đăng ký cũ để tránh giữ lại dữ liệu seed sai logic từ các lần chạy trước.
                    DangKyThamGia::where('chien_dich_id', $cd->id)->delete();

                    $soDangKy = 0;
                    $soXacNhan = 0;

                    foreach ($selectedTnvIds as $indexTnv => $tnvId) {
                        $dangKyData = $this->buildRegistrationSeedData($cd, $indexTnv);

                        $dangKy = DangKyThamGia::create([
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
                        $dangKy->timestamps = false;
                        $dangKy->forceFill([
                            'tao_luc' => $dangKyData['tao_luc'],
                            'cap_nhat_luc' => $dangKyData['cap_nhat_luc'],
                        ])->saveQuietly();

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

    private function buildRegistrationSeedData(ChienDich $chienDich, int $indexTnv): array
    {
        $baseDate = ($chienDich->duyet_luc ?: $chienDich->tao_luc ?: Carbon::now())->copy();
        $dangKyLuc = $baseDate->copy()->addDays(1 + ($indexTnv % 5))->setTime(9 + ($indexTnv % 6), 0);
        $capNhatLuc = $dangKyLuc->copy()->addHours(4);

        return match ($chienDich->trang_thai) {
            'da_duyet' => [
                // Giữ lẫn cả người mới đăng ký và người đã xác nhận để test đủ flow.
                'trang_thai' => $indexTnv % 2 === 0 ? 'da_dang_ky' : 'da_xac_nhan',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => $indexTnv % 2 === 0 ? null : $dangKyLuc->copy()->addDay(),
                'tao_luc' => $dangKyLuc,
                'cap_nhat_luc' => $capNhatLuc,
                'ghi_chu' => $indexTnv % 2 === 0
                    ? 'Tình nguyện viên đã đăng ký và đang chờ xác nhận tham gia.'
                    : 'Tình nguyện viên đã xác nhận tham gia chiến dịch.',
            ],
            'yeu_cau_huy' => [
                // Yêu cầu hủy thường xảy ra khi đã có người xác nhận.
                'trang_thai' => 'da_xac_nhan',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => $dangKyLuc->copy()->addDay(),
                'tao_luc' => $dangKyLuc,
                'cap_nhat_luc' => $capNhatLuc,
                'ghi_chu' => 'Tình nguyện viên đã xác nhận, chiến dịch đang chờ xử lý yêu cầu hủy.',
            ],
            'dang_dien_ra' => [
                'trang_thai' => 'dang_tham_gia',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => $dangKyLuc->copy()->addDay(),
                'tao_luc' => $dangKyLuc,
                'cap_nhat_luc' => $capNhatLuc,
                'ghi_chu' => 'Tình nguyện viên đang tham gia chiến dịch.',
            ],
            'hoan_thanh' => [
                'trang_thai' => 'hoan_thanh',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => $dangKyLuc->copy()->addDay(),
                'tao_luc' => $dangKyLuc,
                'cap_nhat_luc' => $capNhatLuc,
                'ghi_chu' => 'Tình nguyện viên đã hoàn tất tham gia chiến dịch.',
            ],
            default => [
                'trang_thai' => 'da_dang_ky',
                'dang_ky_luc' => $dangKyLuc,
                'xac_nhan_luc' => null,
                'tao_luc' => $dangKyLuc,
                'cap_nhat_luc' => $capNhatLuc,
                'ghi_chu' => 'Tình nguyện viên đã đăng ký tham gia chiến dịch.',
            ],
        };
    }

    private function buildCampaignDescription(array $parts): string
    {
        return collect([
            'Chiến dịch này được tổ chức nhằm mục đích ' . trim((string) ($parts['purpose'] ?? '')),
            'Chiến dịch tập trung giải quyết vấn đề hoặc nhu cầu là ' . trim((string) ($parts['problem'] ?? '')),
            'Tình nguyện viên sẽ trực tiếp thực hiện các công việc như ' . trim((string) ($parts['tasks'] ?? '')),
            'Khi tham gia, tình nguyện viên cần cam kết ' . trim((string) ($parts['commitment'] ?? '')),
            'Quyền lợi hoặc hỗ trợ dành cho tình nguyện viên bao gồm ' . trim((string) ($parts['benefits'] ?? '')),
            'Thông tin liên hệ của người phụ trách chiến dịch là ' . trim((string) ($parts['contact'] ?? '')),
        ])
            ->map(fn (string $sentence) => rtrim(trim($sentence), ". \t\n\r\0\x0B") . '.')
            ->implode(' ');
    }
}
