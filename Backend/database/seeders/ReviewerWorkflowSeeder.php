<?php

namespace Database\Seeders;

use App\Models\BaoCaoChienDich;
use App\Models\ChienDich;
use App\Models\DanhGiaTnv;
use App\Models\LichSuKiemDuyetChienDich;
use App\Models\NguoiDung;
use App\Models\PhanHoiTnv;
use App\Models\ThePhanHoi;
use App\Models\ThongBao;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class ReviewerWorkflowSeeder extends Seeder
{
    public function run(): void
    {
        $reviewers = NguoiDung::where('vai_tro', 'kiem_duyet_vien')->get();
        $volunteers = NguoiDung::where('vai_tro', 'tinh_nguyen_vien')->get();
        $campaigns = ChienDich::with(['nguoiTao', 'dangKyThamGias'])->get();

        if ($reviewers->isEmpty() || $volunteers->isEmpty() || $campaigns->isEmpty()) {
            $this->command->warn('Thiếu dữ liệu reviewer/volunteer/campaign. Bỏ qua ReviewerWorkflowSeeder.');
            return;
        }

        $tags = collect([
            'Tổ chức tốt',
            'Hậu cần',
            'Giao tiếp',
            'An toàn',
            'Đúng giờ',
            'Cần cải thiện',
        ])->map(fn ($ten) => ThePhanHoi::firstOrCreate(['ten' => $ten]));

        $now = Carbon::now();
        $approvedCampaigns = $campaigns->whereIn('trang_thai', ['da_duyet', 'dang_dien_ra', 'hoan_thanh']);
        $completedCampaigns = $campaigns->where('trang_thai', 'hoan_thanh');
        $pendingCampaign = $campaigns->firstWhere('trang_thai', 'cho_duyet');
        $cancelRequestCampaign = $campaigns->firstWhere('trang_thai', 'yeu_cau_huy');

        foreach ($completedCampaigns->take(8) as $index => $campaign) {
            $campaign->loadMissing('dangKyThamGias');
            foreach ($campaign->dangKyThamGias->take(2) as $dangKy) {
                $feedback = PhanHoiTnv::updateOrCreate(
                    [
                        'chien_dich_id' => $campaign->id,
                        'nguoi_dung_id' => $dangKy->nguoi_dung_id,
                    ],
                    [
                        'so_sao' => 4 + ($index % 2),
                        'nhan_xet' => $index % 2 === 0
                            ? 'Chiến dịch được tổ chức tốt, thông tin rõ ràng và hỗ trợ kịp thời.'
                            : 'Trải nghiệm nhìn chung tích cực, mong có thêm hướng dẫn đầu buổi.',
                        'tao_luc' => $now->copy()->subDays(4 + $index),
                        'cap_nhat_luc' => $now->copy()->subDays(4 + $index),
                    ]
                );

                $feedback->thePhanHois()->sync($tags->random(2)->pluck('id')->all());

                DanhGiaTnv::updateOrCreate(
                    [
                        'chien_dich_id' => $campaign->id,
                        'tinh_nguyen_vien_id' => $dangKy->nguoi_dung_id,
                    ],
                    [
                        'danh_gia_boi' => $campaign->duyet_boi ?: $reviewers->first()->id,
                        'so_sao' => 4,
                        'nhan_xet' => 'Tình nguyện viên tham gia đầy đủ và phối hợp tốt.',
                        'tao_luc' => $now->copy()->subDays(3),
                        'cap_nhat_luc' => $now->copy()->subDays(3),
                    ]
                );
            }
        }

        foreach ($approvedCampaigns->take(10) as $index => $campaign) {
            BaoCaoChienDich::updateOrCreate(
                [
                    'chien_dich_id' => $campaign->id,
                    'tieu_de' => 'Báo cáo phát sinh #' . ($index + 1),
                ],
                [
                    'nguoi_gui_id' => $campaign->nguoi_tao_id,
                    'phan_loai' => ['lich_trinh', 'an_toan', 'nhan_su'][$index % 3],
                    'noi_dung' => [
                        'Cần cập nhật lại lịch trình vì địa điểm có thay đổi nhẹ.',
                        'Cần xác nhận lại phương án an toàn và người phụ trách y tế.',
                        'Một số TNV đăng ký nhưng chưa xác nhận tham gia.',
                    ][$index % 3],
                    'trang_thai' => ['moi', 'dang_xu_ly', 'da_xu_ly'][$index % 3],
                    'nguoi_xu_ly_id' => $index > 0 ? $reviewers[$index % $reviewers->count()]->id : null,
                    'xu_ly_luc' => $index > 0 ? $now->copy()->subDays($index) : null,
                    'phan_hoi_xu_ly' => $index > 0 ? 'Đã ghi nhận và phản hồi cho người tạo chiến dịch.' : null,
                    'tao_luc' => $now->copy()->subDays(5 + $index),
                    'cap_nhat_luc' => $now->copy()->subDays(max(1, 5 - $index)),
                ]
            );
        }

        if ($pendingCampaign) {
            LichSuKiemDuyetChienDich::firstOrCreate(
                [
                    'chien_dich_id' => $pendingCampaign->id,
                    'hanh_dong' => 'tao_chien_dich_cho_duyet',
                ],
                [
                    'nguoi_thuc_hien_id' => $pendingCampaign->nguoi_tao_id,
                    'tu_trang_thai' => 'nhap',
                    'den_trang_thai' => 'cho_duyet',
                    'ghi_chu' => 'Người tạo gửi chiến dịch lên để kiểm duyệt.',
                    'tao_luc' => $pendingCampaign->tao_luc ?? $now->copy()->subDays(2),
                ]
            );
        }

        if ($cancelRequestCampaign) {
            LichSuKiemDuyetChienDich::firstOrCreate(
                [
                    'chien_dich_id' => $cancelRequestCampaign->id,
                    'hanh_dong' => 'gui_yeu_cau_huy',
                ],
                [
                    'nguoi_thuc_hien_id' => $cancelRequestCampaign->nguoi_tao_id,
                    'tu_trang_thai' => 'da_duyet',
                    'den_trang_thai' => 'yeu_cau_huy',
                    'ghi_chu' => $cancelRequestCampaign->ly_do_tu_choi ?: 'Người tạo gửi yêu cầu hủy chiến dịch.',
                    'tao_luc' => $now->copy()->subDay(),
                ]
            );
        }

        foreach ($campaigns->whereNotNull('duyet_boi')->take(12) as $campaign) {
            ThongBao::firstOrCreate(
                [
                    'nguoi_dung_id' => $campaign->nguoi_tao_id,
                    'loai_tham_chieu' => 'chien_dich',
                    'tham_chieu_id' => $campaign->id,
                    'tieu_de' => 'Cập nhật chiến dịch "' . $campaign->tieu_de . '"',
                ],
                [
                    'nguoi_gui_id' => $campaign->duyet_boi,
                    'loai' => 'cap_nhat_cd',
                    'noi_dung' => 'Chiến dịch của bạn có cập nhật mới từ kiểm duyệt viên.',
                    'gui_qua' => 'ca_hai',
                    'tao_luc' => $now->copy()->subHours(12),
                ]
            );
        }

        $this->command->info('✅ Đã seed dữ liệu workflow cho kiểm duyệt viên.');
    }
}
