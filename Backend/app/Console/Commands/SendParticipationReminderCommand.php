<?php

namespace App\Console\Commands;

use App\Jobs\SendMailJob;
use App\Models\DangKyThamGia;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class SendParticipationReminderCommand extends Command
{
    protected $signature = 'campaigns:send-participation-reminders';

    protected $description = 'Gui email nhac tinh nguyen vien xac nhan tham gia mot lan trong vong 72 gio truoc khi chien dich bat dau.';

    public function handle(): int
    {
        try {
            $today = Carbon::today();
            $targetDate = $today->copy()->addDays(3);

            Log::info('Bat dau command gui email nhac xac nhan tham gia.', [
                'tu_ngay' => $today->toDateString(),
                'den_ngay' => $targetDate->toDateString(),
                'started_at' => now()->toDateTimeString(),
            ]);

            $dangKys = DangKyThamGia::query()
                ->where('trang_thai', 'da_dang_ky')
                ->whereHas('chienDich', function ($query) use ($today, $targetDate) {
                    $query->whereNull('xoa_luc')
                        ->where('trang_thai', 'da_duyet')
                        ->whereDate('ngay_bat_dau', '>=', $today->toDateString())
                        ->whereDate('ngay_bat_dau', '<=', $targetDate->toDateString());
                })
                ->with([
                    'chienDich:id,tieu_de,dia_diem,ngay_bat_dau,ngay_ket_thuc,han_dang_ky,trang_thai',
                    'nguoiDung:id,ho_ten,email',
                ])
                ->get();

            Log::info('Da tai danh sach dang ky can xem xet gui nhac.', [
                'count' => $dangKys->count(),
                'tu_ngay' => $today->toDateString(),
                'den_ngay' => $targetDate->toDateString(),
            ]);

            $sent = 0;
            $skipped = 0;

            foreach ($dangKys as $dangKy) {
                try {
                    $campaign = $dangKy->chienDich;
                    $volunteer = $dangKy->nguoiDung;

                    if (!$campaign || !$volunteer || !$volunteer->email) {
                        $skipped++;

                        Log::warning('Bo qua gui nhac do thieu chien dich, tinh nguyen vien hoac email.', [
                            'dang_ky_id' => $dangKy->id,
                            'chien_dich_id' => $dangKy->chien_dich_id,
                            'nguoi_dung_id' => $dangKy->nguoi_dung_id,
                            'has_campaign' => (bool) $campaign,
                            'has_volunteer' => (bool) $volunteer,
                            'has_email' => (bool) ($volunteer?->email),
                        ]);
                        continue;
                    }

                    $cacheKey = $this->cacheKey($dangKy->id);
                    $expiresAt = $campaign->ngay_bat_dau
                        ? $campaign->ngay_bat_dau->copy()->endOfDay()
                        : now()->addDays(4);

                    if (!Cache::add($cacheKey, now()->toDateTimeString(), $expiresAt)) {
                        $skipped++;

                        Log::info('Bo qua gui nhac vi dang ky nay da duoc danh dau da gui trong cache.', [
                            'dang_ky_id' => $dangKy->id,
                            'chien_dich_id' => $campaign->id,
                            'nguoi_dung_id' => $volunteer->id,
                            'cache_key' => $cacheKey,
                        ]);
                        continue;
                    }

                    SendMailJob::dispatch(
                        $volunteer->email,
                        'Nhắc nhở xác nhận tham gia chiến dịch',
                        'cap_nhat_dang_ky_chien_dich',
                        [
                            'loai' => 'nhac_xac_nhan_tham_gia',
                            'ho_ten' => $volunteer->ho_ten,
                            'ten_chien_dich' => $campaign->tieu_de,
                            'dia_diem' => $campaign->dia_diem,
                            'ngay_bat_dau' => $campaign->ngay_bat_dau?->format('d/m/Y'),
                            'ngay_ket_thuc' => $campaign->ngay_ket_thuc?->format('d/m/Y'),
                            'han_dang_ky' => $campaign->han_dang_ky?->format('d/m/Y'),
                            'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5173'), '/') . '/chi-tiet-chien-dich/' . $campaign->id,
                        ]
                    );

                    $sent++;

                    Log::info('Da dua email nhac xac nhan tham gia vao hang doi thanh cong.', [
                        'dang_ky_id' => $dangKy->id,
                        'chien_dich_id' => $campaign->id,
                        'nguoi_dung_id' => $volunteer->id,
                        'email' => $volunteer->email,
                        'cache_key' => $cacheKey,
                    ]);
                } catch (\Throwable $exception) {
                    $skipped++;

                    Log::error('Gui nhac xac nhan that bai cho mot dang ky tham gia.', [
                        'dang_ky_id' => $dangKy->id,
                        'chien_dich_id' => $dangKy->chien_dich_id,
                        'nguoi_dung_id' => $dangKy->nguoi_dung_id,
                        'error' => $exception->getMessage(),
                    ]);
                }
            }

            Log::info('Ket thuc command gui email nhac xac nhan tham gia.', [
                'tu_ngay' => $today->toDateString(),
                'den_ngay' => $targetDate->toDateString(),
                'sent' => $sent,
                'skipped' => $skipped,
                'finished_at' => now()->toDateTimeString(),
            ]);

            $this->info("Da gui {$sent} email nhac xac nhan, bo qua {$skipped} dang ky.");

            return self::SUCCESS;
        } catch (\Throwable $exception) {
            Log::error('Command gui email nhac xac nhan tham gia bi loi.', [
                'error' => $exception->getMessage(),
                'at' => now()->toDateTimeString(),
            ]);

            $this->error('Command gui nhac xac nhan tham gia gap loi.');

            return self::FAILURE;
        }
    }

    private function cacheKey(int $dangKyId): string
    {
        return "campaigns:participation-reminder-sent:{$dangKyId}";
    }
}
