<?php

namespace App\Http\Controllers;

use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\NguoiDung;
use Illuminate\Http\JsonResponse;

class TrangChuController extends Controller
{
    public function thongTin(): JsonResponse
    {
        $featuredCampaigns = ChienDich::query()
            ->whereNull('xoa_luc')
            ->whereIn('trang_thai', ['da_duyet', 'dang_dien_ra'])
            ->with(['loaiChienDich:id,ten,bieu_tuong,mau_sac'])
            ->orderByRaw("FIELD(muc_do_uu_tien, 'khan_cap', 'cao', 'trung_binh', 'thap')")
            ->orderByDesc('so_xac_nhan')
            ->orderBy('ngay_bat_dau')
            ->limit(3)
            ->get();

        $completedCampaigns = ChienDich::query()
            ->whereNull('xoa_luc')
            ->where('trang_thai', 'hoan_thanh')
            ->with(['loaiChienDich:id,ten,bieu_tuong,mau_sac'])
            ->orderByDesc('thoi_gian_ket_thuc_thuc_te')
            ->orderByDesc('ngay_ket_thuc')
            ->limit(3)
            ->get();

        $upcomingCampaigns = ChienDich::query()
            ->whereNull('xoa_luc')
            ->where('trang_thai', 'da_duyet')
            ->whereDate('ngay_bat_dau', '>', now()->toDateString())
            ->with(['loaiChienDich:id,ten,bieu_tuong,mau_sac'])
            ->orderBy('ngay_bat_dau')
            ->orderByRaw("FIELD(muc_do_uu_tien, 'khan_cap', 'cao', 'trung_binh', 'thap')")
            ->limit(3)
            ->get();

        $campaignLocations = ChienDich::query()
            ->whereNull('xoa_luc')
            ->whereIn('trang_thai', ['da_duyet', 'dang_dien_ra', 'hoan_thanh'])
            ->pluck('dia_diem');

        $recentVolunteers = DangKyThamGia::query()
            ->whereIn('trang_thai', ['da_dang_ky', 'da_duyet', 'da_xac_nhan', 'dang_tham_gia', 'hoan_thanh'])
            ->whereNotNull('dang_ky_luc')
            ->whereHas('nguoiDung', function ($query) {
                $query->whereNull('xoa_luc')
                    ->where('vai_tro', 'tinh_nguyen_vien')
                    ->where('trang_thai', 'hoat_dong');
            })
            ->whereHas('chienDich', function ($query) {
                $query->whereNull('xoa_luc');
            })
            ->with([
                'nguoiDung:id,ho_ten,anh_dai_dien',
                'chienDich:id,tieu_de,dia_diem',
            ])
            ->orderByDesc('dang_ky_luc')
            ->limit(6)
            ->get();

        $provinceCount = $campaignLocations
            ->flatMap(function (?string $location) {
                return collect(explode(',', (string) $location))
                    ->map(fn ($item) => trim($item))
                    ->filter();
            })
            ->unique()
            ->count();

        return response()->json([
            'status' => 1,
            'message' => 'Lấy dữ liệu trang chủ thành công.',
            'data' => [
                'hero' => [
                    'volunteer_count' => NguoiDung::query()
                        ->whereNull('xoa_luc')
                        ->where('vai_tro', 'tinh_nguyen_vien')
                        ->where('trang_thai', 'hoat_dong')
                        ->whereNotNull('xac_thuc_email_luc')
                        ->count(),
                    'campaign_count' => ChienDich::query()
                        ->whereNull('xoa_luc')
                        ->whereIn('trang_thai', ['da_duyet', 'dang_dien_ra', 'hoan_thanh'])
                        ->count(),
                    'province_count' => $provinceCount,
                ],
                'featured_campaigns' => $featuredCampaigns
                    ->map(fn (ChienDich $campaign) => $this->mapCampaignCard($campaign))
                    ->values(),
                'completed_campaigns' => $completedCampaigns
                    ->map(fn (ChienDich $campaign) => $this->mapCampaignCard($campaign))
                    ->values(),
                'upcoming_campaigns' => $upcomingCampaigns
                    ->map(fn (ChienDich $campaign) => $this->mapCampaignCard($campaign))
                    ->values(),
                'recent_volunteers' => $recentVolunteers
                    ->map(fn (DangKyThamGia $registration) => $this->mapRecentVolunteer($registration))
                    ->values(),
            ],
        ]);
    }

    private function mapCampaignCard(ChienDich $campaign): array
    {
        return [
            'id' => $campaign->id,
            'tieu_de' => $campaign->tieu_de,
            'mo_ta' => $campaign->mo_ta,
            'anh_bia' => $campaign->anh_bia,
            'dia_diem' => $campaign->dia_diem,
            'ngay_bat_dau' => optional($campaign->ngay_bat_dau)->format('Y-m-d'),
            'ngay_ket_thuc' => optional($campaign->ngay_ket_thuc)->format('Y-m-d'),
            'muc_do_uu_tien' => $campaign->muc_do_uu_tien,
            'trang_thai' => $campaign->trang_thai,
            'so_luong_toi_da' => (int) $campaign->so_luong_toi_da,
            'so_dang_ky' => (int) $campaign->so_dang_ky,
            'so_xac_nhan' => (int) $campaign->so_xac_nhan,
            'loai_chien_dich' => $campaign->loaiChienDich ? [
                'id' => $campaign->loaiChienDich->id,
                'ten' => $campaign->loaiChienDich->ten,
                'bieu_tuong' => $campaign->loaiChienDich->bieu_tuong,
                'mau_sac' => $campaign->loaiChienDich->mau_sac,
            ] : null,
        ];
    }

    private function mapRecentVolunteer(DangKyThamGia $registration): array
    {
        return [
            'id' => $registration->id,
            'trang_thai' => $registration->trang_thai,
            'dang_ky_luc' => optional($registration->dang_ky_luc)->format('Y-m-d H:i:s'),
            'nguoi_dung' => $registration->nguoiDung ? [
                'id' => $registration->nguoiDung->id,
                'ho_ten' => $registration->nguoiDung->ho_ten,
                'anh_dai_dien' => $registration->nguoiDung->anh_dai_dien,
            ] : null,
            'chien_dich' => $registration->chienDich ? [
                'id' => $registration->chienDich->id,
                'tieu_de' => $registration->chienDich->tieu_de,
                'dia_diem' => $registration->chienDich->dia_diem,
            ] : null,
        ];
    }
}
