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
            ['ten' => 'Y tế / Chăm sóc sức khỏe', 'bieu_tuong' => 'fa-staff-snake', 'mo_ta' => 'Hỗ trợ y tế, sơ cứu, chăm sóc sức khỏe'],
            ['ten' => 'Môi trường', 'bieu_tuong' => 'fa-leaf', 'mo_ta' => 'Trồng cây, dọn dẹp vệ sinh, phân loại rác'],
            ['ten' => 'Truyền thông / Sự kiện', 'bieu_tuong' => 'fa-bullhorn', 'mo_ta' => 'Chụp ảnh, quay phim, viết bài, dẫn chương trình'],
            ['ten' => 'Kỹ thuật / IT', 'bieu_tuong' => 'fa-laptop-code', 'mo_ta' => 'Hỗ trợ kỹ thuật, dữ liệu, website, phần mềm'],
            ['ten' => 'Nấu ăn / Hậu cần', 'bieu_tuong' => 'fa-utensils', 'mo_ta' => 'Chuẩn bị suất ăn, hậu cần, vận chuyển'],
            ['ten' => 'Thiết kế đồ họa', 'bieu_tuong' => 'fa-pen-ruler', 'mo_ta' => 'Thiết kế ấn phẩm truyền thông, poster, banner'],
            ['ten' => 'Nhiếp ảnh / Quay phim', 'bieu_tuong' => 'fa-camera', 'mo_ta' => 'Ghi lại hình ảnh và video hoạt động'],
            ['ten' => 'Ngoại ngữ / Phiên dịch', 'bieu_tuong' => 'fa-language', 'mo_ta' => 'Hỗ trợ dịch thuật, giao tiếp với đối tác'],
            ['ten' => 'Tư vấn tâm lý', 'bieu_tuong' => 'fa-brain', 'mo_ta' => 'Lắng nghe, hỗ trợ tinh thần cho người tham gia'],
            ['ten' => 'Tổ chức trò chơi', 'bieu_tuong' => 'fa-puzzle-piece', 'mo_ta' => 'Khuấy động, hoạt náo, tổ chức trò chơi cộng đồng'],
            ['ten' => 'Kêu gọi tài trợ', 'bieu_tuong' => 'fa-hand-holding-heart', 'mo_ta' => 'Kết nối nguồn lực, vận động tài trợ'],
            ['ten' => 'Điều phối nhóm', 'bieu_tuong' => 'fa-people-arrows', 'mo_ta' => 'Điều phối đội nhóm, chia ca, quản lý hiện trường'],
            ['ten' => 'Lái xe / Vận chuyển', 'bieu_tuong' => 'fa-truck', 'mo_ta' => 'Vận chuyển người và hàng hóa cho chiến dịch'],
            ['ten' => 'Sơ cứu khẩn cấp', 'bieu_tuong' => 'fa-kit-medical', 'mo_ta' => 'Xử lý các tình huống sơ cứu ban đầu'],
            ['ten' => 'Gây quỹ cộng đồng', 'bieu_tuong' => 'fa-coins', 'mo_ta' => 'Tổ chức chương trình gây quỹ và vận động cộng đồng'],
            ['ten' => 'Khảo sát / Thu thập dữ liệu', 'bieu_tuong' => 'fa-clipboard-list', 'mo_ta' => 'Khảo sát hiện trạng, nhập liệu, thống kê'],
            ['ten' => 'Hỗ trợ trẻ em', 'bieu_tuong' => 'fa-child-reaching', 'mo_ta' => 'Tổ chức hoạt động cho trẻ em, hỗ trợ học tập'],
            ['ten' => 'Hỗ trợ người cao tuổi', 'bieu_tuong' => 'fa-person-cane', 'mo_ta' => 'Đồng hành và chăm sóc người cao tuổi'],
            ['ten' => 'Xây dựng / Sửa chữa', 'bieu_tuong' => 'fa-hammer', 'mo_ta' => 'Sơn sửa, xây dựng công trình cộng đồng'],
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
            ['ten' => 'Huế'],
            ['ten' => 'Nghệ An'],
            ['ten' => 'Thanh Hóa'],
            ['ten' => 'Quảng Trị'],
            ['ten' => 'Quảng Ngãi'],
            ['ten' => 'Gia Lai'],
            ['ten' => 'Khánh Hòa'],
            ['ten' => 'Lâm Đồng'],
            ['ten' => 'Đắk Lắk'],
            ['ten' => 'Đồng Nai'],
            ['ten' => 'Tây Ninh'],
            ['ten' => 'Vĩnh Long'],
            ['ten' => 'Đồng Tháp'],
            ['ten' => 'Cà Mau'],
            ['ten' => 'An Giang'],
            ['ten' => 'Khác'],
        ];

        foreach ($khu_vucs as $kv) {
            KhuVuc::updateOrCreate(['ten' => $kv['ten']], $kv);
        }

        // 3. Loại chiến dịch
        $loai_chien_dichs = [
            ['ten' => 'Môi trường', 'bieu_tuong' => 'fa-leaf', 'mau_sac' => '#198754'],
            ['ten' => 'Giáo dục', 'bieu_tuong' => 'fa-book-open', 'mau_sac' => '#0d6efd'],
            ['ten' => 'Y tế', 'bieu_tuong' => 'fa-hand-holding-medical', 'mau_sac' => '#dc3545'],
            ['ten' => 'Cộng đồng', 'bieu_tuong' => 'fa-people-group', 'mau_sac' => '#fd7e14'],
            ['ten' => 'Cứu trợ thiên tai', 'bieu_tuong' => 'fa-house-flood-water', 'mau_sac' => '#6c757d'],
            ['ten' => 'Thiếu nhi', 'bieu_tuong' => 'fa-child-reaching', 'mau_sac' => '#20c997'],
            ['ten' => 'Người cao tuổi', 'bieu_tuong' => 'fa-person-cane', 'mau_sac' => '#6610f2'],
            ['ten' => 'Công nghệ vì cộng đồng', 'bieu_tuong' => 'fa-microchip', 'mau_sac' => '#0dcaf0'],
            ['ten' => 'Nhà ở / Công trình', 'bieu_tuong' => 'fa-house', 'mau_sac' => '#795548'],
        ];

        foreach ($loai_chien_dichs as $lcd) {
            LoaiChienDich::updateOrCreate(['ten' => $lcd['ten']], $lcd);
        }
    }
}
