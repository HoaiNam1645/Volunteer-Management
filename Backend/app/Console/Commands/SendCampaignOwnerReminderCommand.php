<?php

namespace App\Console\Commands;

use App\Jobs\SendMailJob;
use App\Models\ChienDich;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class SendCampaignOwnerReminderCommand extends Command
{
    protected $signature = 'campaigns:send-owner-start-reminders';

    protected $description = 'Gui email nhac chu chien dich khi chien dich sap bat dau trong vong 72 gio toi.';

    public function handle(): int
    {
        try {
            $today = Carbon::today();
            $targetDate = $today->copy()->addDays(3);

            Log::info('Bat dau command gui email nhac chu chien dich sap den ngay bat dau.', [
                'tu_ngay' => $today->toDateString(),
                'den_ngay' => $targetDate->toDateString(),
                'started_at' => now()->toDateTimeString(),
            ]);

            $campaigns = ChienDich::query()
                ->whereNull('xoa_luc')
                ->where('trang_thai', 'da_duyet')
                ->whereDate('ngay_bat_dau', '>=', $today->toDateString())
                ->whereDate('ngay_bat_dau', '<=', $targetDate->toDateString())
                ->with(['nguoiTao:id,ho_ten,email'])
                ->get();

            Log::info('Da tai danh sach chien dich can xem xet gui nhac cho chu so huu.', [
                'count' => $campaigns->count(),
                'tu_ngay' => $today->toDateString(),
                'den_ngay' => $targetDate->toDateString(),
            ]);

            $sent = 0;
            $skipped = 0;

            foreach ($campaigns as $campaign) {
                try {
                    $owner = $campaign->nguoiTao;

                    if (!$owner || !$owner->email) {
                        $skipped++;

                        Log::warning('Bo qua gui nhac cho chu chien dich do thieu nguoi tao hoac email.', [
                            'chien_dich_id' => $campaign->id,
                            'nguoi_tao_id' => $campaign->nguoi_tao_id,
                            'has_owner' => (bool) $owner,
                            'has_email' => (bool) ($owner?->email),
                        ]);
                        continue;
                    }

                    $cacheKey = $this->cacheKey($campaign->id);
                    $expiresAt = $campaign->ngay_bat_dau
                        ? $campaign->ngay_bat_dau->copy()->endOfDay()
                        : now()->addDays(4);

                    if (!Cache::add($cacheKey, now()->toDateTimeString(), $expiresAt)) {
                        $skipped++;

                        Log::info('Bo qua gui nhac cho chu chien dich vi cache da ton tai.', [
                            'chien_dich_id' => $campaign->id,
                            'nguoi_tao_id' => $owner->id,
                            'cache_key' => $cacheKey,
                        ]);
                        continue;
                    }

                    SendMailJob::dispatch(
                        $owner->email,
                        'Nhắc nhở chiến dịch sắp bắt đầu',
                        'nhac_chu_chien_dich_sap_bat_dau',
                        [
                            'ho_ten' => $owner->ho_ten,
                            'ten_chien_dich' => $campaign->tieu_de,
                            'dia_diem' => $campaign->dia_diem,
                            'ngay_bat_dau' => $campaign->ngay_bat_dau?->format('d/m/Y'),
                            'ngay_ket_thuc' => $campaign->ngay_ket_thuc?->format('d/m/Y'),
                            'han_dang_ky' => $campaign->han_dang_ky?->format('d/m/Y'),
                            'so_dang_ky' => $campaign->so_dang_ky,
                            'so_xac_nhan' => $campaign->so_xac_nhan,
                            'so_luong_toi_da' => $campaign->so_luong_toi_da,
                            'so_luong_con_thieu' => max(0, (int) $campaign->so_luong_toi_da - (int) $campaign->so_xac_nhan),
                            'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5173'), '/') . '/quan-ly-chien-dich/chi-tiet/' . $campaign->id,
                        ]
                    );

                    $sent++;

                    Log::info('Da dua email nhac chu chien dich vao hang doi thanh cong.', [
                        'chien_dich_id' => $campaign->id,
                        'nguoi_tao_id' => $owner->id,
                        'email' => $owner->email,
                        'cache_key' => $cacheKey,
                    ]);
                } catch (\Throwable $exception) {
                    $skipped++;

                    Log::error('Gui nhac cho chu chien dich that bai.', [
                        'chien_dich_id' => $campaign->id,
                        'nguoi_tao_id' => $campaign->nguoi_tao_id,
                        'error' => $exception->getMessage(),
                    ]);
                }
            }

            Log::info('Ket thuc command gui email nhac chu chien dich sap den ngay bat dau.', [
                'tu_ngay' => $today->toDateString(),
                'den_ngay' => $targetDate->toDateString(),
                'sent' => $sent,
                'skipped' => $skipped,
                'finished_at' => now()->toDateTimeString(),
            ]);

            $this->info("Da gui {$sent} email nhac chu chien dich, bo qua {$skipped} chien dich.");

            return self::SUCCESS;
        } catch (\Throwable $exception) {
            Log::error('Command gui email nhac chu chien dich bi loi.', [
                'error' => $exception->getMessage(),
                'at' => now()->toDateTimeString(),
            ]);

            $this->error('Command gui nhac chu chien dich gap loi.');

            return self::FAILURE;
        }
    }

    private function cacheKey(int $campaignId): string
    {
        return "campaigns:owner-start-reminder-sent:{$campaignId}";
    }
}
