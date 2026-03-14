<?php

namespace Database\Seeders;

use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\NguoiDung;
use App\Models\LoaiChienDich;
use App\Models\KyNang;
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
        $kyNangIds = KyNang::pluck('id')->toArray();

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

        foreach ($chienDichs as $index => $cdData) {
            // Người tạo chiến dịch là TNV, luân phiên theo dữ liệu seed.
            $cdData['nguoi_tao_id'] = $nguoiTaoIds[$index % count($nguoiTaoIds)];

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

            // Gắn kỹ năng ngẫu nhiên (1-3)
            if (!empty($kyNangIds)) {
                $randomKeys = (array) array_rand($kyNangIds, rand(1, min(3, count($kyNangIds))));
                $skillsData = [];
                foreach ($randomKeys as $key) {
                    $skillsData[$kyNangIds[$key]] = [
                        'bat_buoc' => rand(0, 1),
                        'tao_luc'  => $now,
                    ];
                }
                $cd->kyNangs()->sync($skillsData);
            }

            // Tạo đăng ký tham gia cho chiến dịch đã duyệt / đang diễn ra / hoàn thành
            if (in_array($cd->trang_thai, ['da_duyet', 'dang_dien_ra', 'hoan_thanh', 'yeu_cau_huy']) && !empty($tnvIds)) {
                $numRegistrations = rand(2, min(4, count($tnvIds)));
                $selectedTnvIds = array_slice($tnvIds, 0, $numRegistrations);

                $soDangKy = 0;
                $soXacNhan = 0;

                foreach ($selectedTnvIds as $tnvId) {
                    $trangThaiDk = $cd->trang_thai === 'hoan_thanh' ? 'hoan_thanh' : 'da_duyet';
                    DangKyThamGia::updateOrCreate(
                        [
                            'chien_dich_id' => $cd->id,
                            'nguoi_dung_id' => $tnvId,
                        ],
                        [
                            'trang_thai'   => $trangThaiDk,
                            'dang_ky_luc'  => $now->copy()->subDays(rand(1, 7)),
                            'duyet_luc'    => $now->copy()->subDays(rand(0, 3)),
                            'xac_nhan_luc' => $trangThaiDk === 'hoan_thanh' ? $now->copy()->subDays(rand(0, 2)) : null,
                        ]
                    );
                    $soDangKy++;
                    if ($trangThaiDk === 'hoan_thanh') $soXacNhan++;
                }

                // Cập nhật cache
                $cd->update([
                    'so_dang_ky'  => $soDangKy,
                    'so_xac_nhan' => $soXacNhan,
                ]);
            }
        }

        $this->command->info('✅ Đã seed ' . count($chienDichs) . ' chiến dịch + đăng ký tham gia.');
    }
}
