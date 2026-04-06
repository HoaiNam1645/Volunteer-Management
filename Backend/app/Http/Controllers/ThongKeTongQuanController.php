<?php

namespace App\Http\Controllers;

use App\Models\BaoCaoChienDich;
use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\NguoiDung;
use App\Models\PhanHoiTnv;
use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Http\Request;

class ThongKeTongQuanController extends Controller
{
    public function dashboardAdmin(Request $request)
    {
        $period = $this->resolvePeriod($request->input('period'));
        ['current_start' => $currentStart, 'current_end' => $currentEnd, 'previous_start' => $previousStart, 'previous_end' => $previousEnd] = $this->resolveDateRange($period);

        $usersBase = NguoiDung::query()->whereNull('xoa_luc');
        $campaignsBase = ChienDich::query()->whereNull('xoa_luc');
        $feedbackBase = PhanHoiTnv::query();

        $totalUsers = (clone $usersBase)->count();
        $activeCampaigns = (clone $campaignsBase)->whereIn('trang_thai', ['da_duyet', 'dang_dien_ra'])->count();
        $pendingApprovals = (clone $usersBase)->where('trang_thai', 'cho_duyet')->count();
        $totalFeedback = (clone $feedbackBase)->count();

        $summary = [
            'total_users' => [
                'key' => 'total_users',
                'label' => 'Tổng người dùng',
                'value' => $totalUsers,
                'icon' => 'fa-solid fa-users',
                'bg_class' => 'bg-primary-subtle text-primary',
                'trend' => $this->buildTrend(
                    (clone $usersBase)->whereBetween('tao_luc', [$currentStart, $currentEnd])->count(),
                    (clone $usersBase)->whereBetween('tao_luc', [$previousStart, $previousEnd])->count()
                ),
            ],
            'active_campaigns' => [
                'key' => 'active_campaigns',
                'label' => 'Chiến dịch hoạt động',
                'value' => $activeCampaigns,
                'icon' => 'fa-solid fa-flag',
                'bg_class' => 'bg-success-subtle text-success',
                'badge_label' => $activeCampaigns . ' đang hoạt động',
                'trend' => $this->buildTrend(
                    (clone $campaignsBase)->whereIn('trang_thai', ['da_duyet', 'dang_dien_ra'])->whereBetween('tao_luc', [$currentStart, $currentEnd])->count(),
                    (clone $campaignsBase)->whereIn('trang_thai', ['da_duyet', 'dang_dien_ra'])->whereBetween('tao_luc', [$previousStart, $previousEnd])->count()
                ),
            ],
            'pending_approvals' => [
                'key' => 'pending_approvals',
                'label' => 'Tài khoản chờ duyệt',
                'value' => $pendingApprovals,
                'icon' => 'fa-solid fa-user-clock',
                'bg_class' => 'bg-warning-subtle text-warning',
                'trend' => [
                    'text' => $pendingApprovals > 0 ? 'Cần xử lý' : 'Ổn định',
                    'positive' => $pendingApprovals === 0,
                ],
            ],
            'total_feedback' => [
                'key' => 'total_feedback',
                'label' => 'Phản hồi đã nhận',
                'value' => $totalFeedback,
                'icon' => 'fa-solid fa-comments',
                'bg_class' => 'bg-info-subtle text-info',
                'trend' => $this->buildTrend(
                    (clone $feedbackBase)->whereBetween('tao_luc', [$currentStart, $currentEnd])->count(),
                    (clone $feedbackBase)->whereBetween('tao_luc', [$previousStart, $previousEnd])->count()
                ),
            ],
        ];

        $activityChart = $this->buildTimeBuckets($period, $currentEnd, function (CarbonInterface $start, CarbonInterface $end) use ($usersBase, $campaignsBase) {
            $registrationItems = (clone $usersBase)
                ->whereBetween('tao_luc', [$start, $end])
                ->orderByDesc('tao_luc')
                ->get(['id', 'ho_ten', 'email', 'so_dien_thoai', 'anh_dai_dien', 'tao_luc', 'vai_tro', 'trang_thai'])
                ->map(function (NguoiDung $user) {
                    return [
                        'id' => $user->id,
                        'name' => $user->ho_ten,
                        'email' => $user->email,
                        'phone' => $user->so_dien_thoai,
                        'avatar' => $user->anh_dai_dien,
                        'created_at' => $user->tao_luc?->format('Y-m-d H:i:s'),
                        'role' => $user->vai_tro,
                        'status' => $user->trang_thai,
                        'role_label' => $this->humanUserRole($user->vai_tro),
                        'status_label' => $this->humanUserStatus($user->trang_thai),
                        'status_badge_class' => $this->userStatusBadgeClass($user->trang_thai),
                    ];
                })
                ->values();

            $campaignItems = (clone $campaignsBase)
                ->with(['nguoiTao:id,ho_ten,email'])
                ->whereBetween('tao_luc', [$start, $end])
                ->orderByDesc('tao_luc')
                ->get(['id', 'nguoi_tao_id', 'tieu_de', 'dia_diem', 'so_xac_nhan', 'so_luong_toi_da', 'trang_thai', 'tao_luc'])
                ->map(function (ChienDich $campaign) {
                    return [
                        'id' => $campaign->id,
                        'title' => $campaign->tieu_de,
                        'location' => $campaign->dia_diem,
                        'volunteers' => (int) $campaign->so_xac_nhan,
                        'target' => (int) $campaign->so_luong_toi_da,
                        'status' => $campaign->trang_thai,
                        'status_label' => $this->humanCampaignStatus($campaign->trang_thai),
                        'status_badge_class' => $this->campaignStatusBadgeClass($campaign->trang_thai),
                        'created_at' => $campaign->tao_luc?->format('Y-m-d H:i:s'),
                        'creator_name' => $campaign->nguoiTao?->ho_ten,
                        'creator_email' => $campaign->nguoiTao?->email,
                    ];
                })
                ->values();

            return [
                'registrations' => $registrationItems->count(),
                'campaigns' => $campaignItems->count(),
                'registration_items' => $registrationItems,
                'campaign_items' => $campaignItems,
            ];
        });

        $roleCounts = [
            'volunteer' => (clone $usersBase)->where('vai_tro', 'tinh_nguyen_vien')->count(),
            'coordinator' => (clone $usersBase)->where('vai_tro', 'kiem_duyet_vien')->count(),
            'admin' => (clone $usersBase)->where('vai_tro', 'quan_tri_vien')->count(),
            'pending' => (clone $usersBase)->where('trang_thai', 'cho_duyet')->count(),
        ];
        $roleMax = max(1, ...array_values($roleCounts));

        $recentUsers = (clone $usersBase)
            ->orderByDesc('tao_luc')
            ->limit(5)
            ->get(['id', 'ho_ten', 'email', 'anh_dai_dien', 'tao_luc', 'vai_tro', 'trang_thai'])
            ->map(function (NguoiDung $user) {
                return [
                    'id' => $user->id,
                    'name' => $user->ho_ten,
                    'email' => $user->email,
                    'avatar' => $user->anh_dai_dien,
                    'time' => $this->humanizeDiff($user->tao_luc),
                    'role' => $user->vai_tro,
                    'status' => $user->trang_thai,
                    'role_label' => $this->humanUserRole($user->vai_tro),
                    'status_label' => $this->humanUserStatus($user->trang_thai),
                    'status_badge_class' => $this->userStatusBadgeClass($user->trang_thai),
                ];
            })
            ->values();

        $recentCampaigns = (clone $campaignsBase)
            ->orderByDesc('tao_luc')
            ->limit(5)
            ->get(['id', 'tieu_de', 'anh_bia', 'dia_diem', 'so_xac_nhan', 'so_luong_toi_da', 'trang_thai'])
            ->map(function (ChienDich $campaign) {
                return [
                    'id' => $campaign->id,
                    'title' => $campaign->tieu_de,
                    'image' => $campaign->anh_bia,
                    'location' => $campaign->dia_diem,
                    'volunteers' => (int) $campaign->so_xac_nhan,
                    'target' => (int) $campaign->so_luong_toi_da,
                    'status' => $campaign->trang_thai,
                    'status_label' => $this->humanCampaignStatus($campaign->trang_thai),
                    'status_badge_class' => $this->campaignStatusBadgeClass($campaign->trang_thai),
                ];
            })
            ->values();

        return response()->json([
            'status' => 1,
            'message' => 'Lấy dữ liệu dashboard quản trị thành công.',
            'data' => [
                'period' => $period,
                'summary' => $summary,
                'activity_chart' => $activityChart,
                'role_distribution' => [
                    ['key' => 'volunteer', 'label' => 'Tình nguyện viên', 'count' => $roleCounts['volunteer'], 'percent' => $this->toPercent($roleCounts['volunteer'], $roleMax), 'color' => '#4f8cf7'],
                    ['key' => 'coordinator', 'label' => 'Kiểm duyệt viên', 'count' => $roleCounts['coordinator'], 'percent' => $this->toPercent($roleCounts['coordinator'], $roleMax), 'color' => '#28a745'],
                    ['key' => 'admin', 'label' => 'Quản trị viên', 'count' => $roleCounts['admin'], 'percent' => $this->toPercent($roleCounts['admin'], $roleMax), 'color' => '#fd7e14'],
                    ['key' => 'pending', 'label' => 'Chờ duyệt', 'count' => $roleCounts['pending'], 'percent' => $this->toPercent($roleCounts['pending'], $roleMax), 'color' => '#dc3545'],
                ],
                'recent_users' => $recentUsers,
                'recent_campaigns' => $recentCampaigns,
            ],
        ]);
    }

    public function thongKeKiemDuyet(Request $request)
    {
        $reviewer = auth('api')->user();
        $period = $this->resolvePeriod($request->input('period'));
        ['current_start' => $currentStart, 'current_end' => $currentEnd, 'previous_start' => $previousStart, 'previous_end' => $previousEnd] = $this->resolveDateRange($period);

        $campaignQueueBase = ChienDich::query()->whereNull('xoa_luc');
        $reviewedCampaignsBase = ChienDich::query()
            ->whereNull('xoa_luc')
            ->where('duyet_boi', $reviewer->id);
        $assignedReportsBase = BaoCaoChienDich::query()->where('nguoi_xu_ly_id', $reviewer->id);
        $feedbackBase = PhanHoiTnv::query()->whereHas('chienDich', function ($query) use ($reviewer) {
            $query->whereNull('xoa_luc')->where('duyet_boi', $reviewer->id);
        });
        $registrationsBase = DangKyThamGia::query()
            ->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])
            ->whereHas('chienDich', function ($query) use ($reviewer) {
                $query->whereNull('xoa_luc')->where('duyet_boi', $reviewer->id);
            });

        $avgRating = round((float) ((clone $feedbackBase)->avg('so_sao') ?? 0), 1);

        $kpis = [
            'pending_review' => [
                'key' => 'pending_review',
                'label' => 'Chiến dịch chờ duyệt',
                'value' => (clone $campaignQueueBase)->where('trang_thai', 'cho_duyet')->count(),
                'icon' => 'fa-solid fa-hourglass-half',
                'bg_color' => 'rgba(79,140,247,0.1)',
                'color' => '#4f8cf7',
                'trend' => $this->buildTrend(
                    (clone $campaignQueueBase)->where('trang_thai', 'cho_duyet')->whereBetween('tao_luc', [$currentStart, $currentEnd])->count(),
                    (clone $campaignQueueBase)->where('trang_thai', 'cho_duyet')->whereBetween('tao_luc', [$previousStart, $previousEnd])->count()
                ),
            ],
            'cancel_requests' => [
                'key' => 'cancel_requests',
                'label' => 'Yêu cầu hủy chờ xử lý',
                'value' => (clone $campaignQueueBase)->where('trang_thai', 'yeu_cau_huy')->count(),
                'icon' => 'fa-solid fa-ban',
                'bg_color' => 'rgba(253,126,20,0.1)',
                'color' => '#fd7e14',
                'trend' => $this->buildTrend(
                    (clone $campaignQueueBase)->where('trang_thai', 'yeu_cau_huy')->whereBetween('cap_nhat_luc', [$currentStart, $currentEnd])->count(),
                    (clone $campaignQueueBase)->where('trang_thai', 'yeu_cau_huy')->whereBetween('cap_nhat_luc', [$previousStart, $previousEnd])->count()
                ),
            ],
            'processing_reports' => [
                'key' => 'processing_reports',
                'label' => 'Báo cáo đang xử lý',
                'value' => (clone $assignedReportsBase)->where('trang_thai', 'dang_xu_ly')->count(),
                'icon' => 'fa-solid fa-triangle-exclamation',
                'bg_color' => 'rgba(220,53,69,0.1)',
                'color' => '#dc3545',
                'trend' => $this->buildTrend(
                    (clone $assignedReportsBase)->where('trang_thai', 'dang_xu_ly')->whereBetween('cap_nhat_luc', [$currentStart, $currentEnd])->count(),
                    (clone $assignedReportsBase)->where('trang_thai', 'dang_xu_ly')->whereBetween('cap_nhat_luc', [$previousStart, $previousEnd])->count()
                ),
            ],
            'avg_rating' => [
                'key' => 'avg_rating',
                'label' => 'Điểm phản hồi trung bình',
                'value' => $avgRating > 0 ? $avgRating : '0.0',
                'icon' => 'fa-solid fa-star',
                'bg_color' => 'rgba(40,167,69,0.1)',
                'color' => '#28a745',
                'trend' => [
                    'text' => ((clone $feedbackBase)->count() > 0 ? (clone $feedbackBase)->count() : 0) . ' phản hồi',
                    'positive' => $avgRating >= 4,
                ],
            ],
        ];

        $periodReviewedCampaignsBase = (clone $reviewedCampaignsBase)
            ->where(function ($query) use ($currentStart, $currentEnd) {
                $query->whereBetween('duyet_luc', [$currentStart, $currentEnd])
                    ->orWhere(function ($subQuery) use ($currentStart, $currentEnd) {
                        $subQuery->whereNull('duyet_luc')
                            ->whereBetween('tao_luc', [$currentStart, $currentEnd]);
                    });
            });
        $periodRegistrationsBase = (clone $registrationsBase)
            ->whereBetween('dang_ky_luc', [$currentStart, $currentEnd]);

        $monthlyData = $this->buildTimeBuckets($period, $currentEnd, function (CarbonInterface $start, CarbonInterface $end) use ($reviewedCampaignsBase, $registrationsBase) {
            return [
                'campaigns' => (clone $reviewedCampaignsBase)
                    ->where(function ($query) use ($start, $end) {
                        $query->whereBetween('duyet_luc', [$start, $end])
                            ->orWhere(function ($subQuery) use ($start, $end) {
                                $subQuery->whereNull('duyet_luc')
                                    ->whereBetween('tao_luc', [$start, $end]);
                            });
                    })
                    ->count(),
                'volunteers' => (clone $registrationsBase)->whereBetween('dang_ky_luc', [$start, $end])->count(),
            ];
        });

        $statusCounts = [
            ['label' => 'Chờ duyệt', 'count' => (clone $campaignQueueBase)->where('trang_thai', 'cho_duyet')->count(), 'color' => '#ffc107', 'icon' => 'fa-solid fa-hourglass-half'],
            ['label' => 'Đã duyệt', 'count' => (clone $reviewedCampaignsBase)->where('trang_thai', 'da_duyet')->count(), 'color' => '#20c997', 'icon' => 'fa-solid fa-check-double'],
            ['label' => 'Đang diễn ra', 'count' => (clone $reviewedCampaignsBase)->where('trang_thai', 'dang_dien_ra')->count(), 'color' => '#0d6efd', 'icon' => 'fa-solid fa-play'],
            ['label' => 'Hoàn thành', 'count' => (clone $reviewedCampaignsBase)->where('trang_thai', 'hoan_thanh')->count(), 'color' => '#6c757d', 'icon' => 'fa-solid fa-check'],
        ];
        $statusMax = max(1, ...collect($statusCounts)->pluck('count')->all());

        $topRegionRows = (clone $periodReviewedCampaignsBase)
            ->selectRaw('dia_diem, COUNT(*) as total')
            ->whereNotNull('dia_diem')
            ->where('dia_diem', '!=', '')
            ->groupBy('dia_diem')
            ->orderByDesc('total')
            ->limit(6)
            ->get();
        $regionTotals = $topRegionRows->pluck('total')->map(fn ($value) => (int) $value)->all();
        $regionMax = max([1, ...$regionTotals]);
        $topRegions = $topRegionRows->map(fn ($item) => [
            'name' => $item->dia_diem,
            'volunteers' => (int) $item->total,
            'percent' => $this->toPercent((int) $item->total, $regionMax),
        ])->values();

        $skillRows = collect(\DB::table('chien_dich_ky_nangs as cdk')
            ->join('chien_dichs as cd', 'cd.id', '=', 'cdk.chien_dich_id')
            ->join('ky_nangs as kn', 'kn.id', '=', 'cdk.ky_nang_id')
            ->selectRaw('kn.ten as ten, COUNT(*) as total')
            ->whereNull('cd.xoa_luc')
            ->where('cd.duyet_boi', $reviewer->id)
            ->where(function ($query) use ($currentStart, $currentEnd) {
                $query->whereBetween('cd.duyet_luc', [$currentStart, $currentEnd])
                    ->orWhere(function ($subQuery) use ($currentStart, $currentEnd) {
                        $subQuery->whereNull('cd.duyet_luc')
                            ->whereBetween('cd.tao_luc', [$currentStart, $currentEnd]);
                    });
            })
            ->groupBy('kn.id', 'kn.ten')
            ->orderByDesc('total')
            ->limit(6)
            ->get());
        $skillTotals = $skillRows->pluck('total')->map(fn ($v) => (int) $v)->all();
        $skillMax = max([1, ...$skillTotals]);
        $skillPalette = [
            ['#4f8cf7', 'fa-solid fa-chalkboard-user'],
            ['#e83e8c', 'fa-solid fa-bullhorn'],
            ['#dc3545', 'fa-solid fa-kit-medical'],
            ['#6f42c1', 'fa-solid fa-laptop-code'],
            ['#fd7e14', 'fa-solid fa-utensils'],
            ['#198754', 'fa-solid fa-hammer'],
        ];
        $topSkills = $skillRows->values()->map(function ($item, $index) use ($skillPalette, $skillMax) {
            [$color, $icon] = $skillPalette[$index] ?? ['#4f8cf7', 'fa-solid fa-star'];

            return [
                'name' => $item->ten,
                'count' => (int) $item->total,
                'percent' => $this->toPercent((int) $item->total, $skillMax),
                'color' => $color,
                'icon' => $icon,
            ];
        });

        return response()->json([
            'status' => 1,
            'message' => 'Lấy dữ liệu thống kê kiểm duyệt thành công.',
            'data' => [
                'period' => $period,
                'kpis' => $kpis,
                'monthly_data' => $monthlyData,
                'period_summary' => [
                    'campaigns' => (clone $periodReviewedCampaignsBase)->count(),
                    'volunteers' => (clone $periodRegistrationsBase)->count(),
                ],
                'campaign_statuses' => collect($statusCounts)->map(fn (array $item) => [
                    'label' => $item['label'],
                    'count' => $item['count'],
                    'percent' => $this->toPercent($item['count'], $statusMax),
                    'icon' => $item['icon'],
                    'color' => $item['color'],
                    'bg_color' => $this->toAlphaColor($item['color']),
                ])->values(),
                'top_regions' => $topRegions,
                'top_skills' => $topSkills,
            ],
        ]);
    }

    private function resolvePeriod(?string $period): string
    {
        return in_array($period, ['week', 'month', 'quarter', 'year'], true) ? $period : 'month';
    }

    private function resolveDateRange(string $period): array
    {
        $now = now();

        return match ($period) {
            'week' => [
                'current_start' => $now->copy()->startOfWeek(),
                'current_end' => $now->copy()->endOfWeek(),
                'previous_start' => $now->copy()->subWeek()->startOfWeek(),
                'previous_end' => $now->copy()->subWeek()->endOfWeek(),
            ],
            'quarter' => [
                'current_start' => $now->copy()->startOfQuarter(),
                'current_end' => $now->copy()->endOfQuarter(),
                'previous_start' => $now->copy()->subQuarter()->startOfQuarter(),
                'previous_end' => $now->copy()->subQuarter()->endOfQuarter(),
            ],
            'year' => [
                'current_start' => $now->copy()->startOfYear(),
                'current_end' => $now->copy()->endOfYear(),
                'previous_start' => $now->copy()->subYear()->startOfYear(),
                'previous_end' => $now->copy()->subYear()->endOfYear(),
            ],
            default => [
                'current_start' => $now->copy()->startOfMonth(),
                'current_end' => $now->copy()->endOfMonth(),
                'previous_start' => $now->copy()->subMonth()->startOfMonth(),
                'previous_end' => $now->copy()->subMonth()->endOfMonth(),
            ],
        };
    }

    private function buildTrend(int|float $current, int|float $previous): array
    {
        $change = $current - $previous;

        return [
            'text' => $change === 0 ? '0' : (($change > 0 ? '+' : '') . $change),
            'positive' => $change >= 0,
        ];
    }

    private function buildTimeBuckets(string $period, CarbonInterface $anchor, callable $resolver): array
    {
        $buckets = collect();

        if ($period === 'week') {
            for ($offset = 6; $offset >= 0; $offset--) {
                $start = $anchor->copy()->startOfWeek()->addDays(6 - $offset)->startOfDay();
                $end = $start->copy()->endOfDay();
                $label = match ($start->dayOfWeekIso) {
                    1 => 'T2',
                    2 => 'T3',
                    3 => 'T4',
                    4 => 'T5',
                    5 => 'T6',
                    6 => 'T7',
                    default => 'CN',
                };
                $buckets->push(compact('label', 'start', 'end'));
            }
        } elseif ($period === 'year') {
            for ($month = 1; $month <= 12; $month++) {
                $start = $anchor->copy()->startOfYear()->month($month)->startOfMonth();
                $end = $start->copy()->endOfMonth();
                $buckets->push([
                    'label' => 'T' . $month,
                    'start' => $start,
                    'end' => $end,
                ]);
            }
        } else {
            $count = $period === 'quarter' ? 3 : 6;
            for ($offset = $count - 1; $offset >= 0; $offset--) {
                $start = $anchor->copy()->startOfMonth()->subMonths($offset);
                $end = $start->copy()->endOfMonth();
                $buckets->push([
                    'label' => 'T' . $start->month,
                    'start' => $start,
                    'end' => $end,
                ]);
            }
        }

        return $buckets->map(function (array $bucket) use ($resolver) {
            $data = $resolver($bucket['start'], $bucket['end']);

            return array_merge([
                'label' => $bucket['label'],
            ], $data);
        })->all();
    }

    private function humanizeDiff(?CarbonInterface $dateTime): string
    {
        if (!$dateTime) {
            return 'Không rõ';
        }

        $minutes = max(1, (int) floor($dateTime->diffInMinutes(now())));

        if ($minutes < 60) {
            return $minutes . ' phút trước';
        }

        $hours = (int) floor($minutes / 60);
        if ($hours < 24) {
            return $hours . ' giờ trước';
        }

        $days = max(1, (int) floor($hours / 24));
        if ($days < 30) {
            return $days . ' ngày trước';
        }

        $months = max(1, (int) floor($days / 30));
        return $months . ' tháng trước';
    }

    private function toPercent(int|float $value, int|float $max): int
    {
        if ($max <= 0) {
            return 0;
        }

        return (int) round(($value / $max) * 100);
    }

    private function toAlphaColor(string $hexColor): string
    {
        $hex = ltrim($hexColor, '#');
        if (strlen($hex) !== 6) {
            return 'rgba(79,140,247,0.1)';
        }

        return sprintf(
            'rgba(%d,%d,%d,0.1)',
            hexdec(substr($hex, 0, 2)),
            hexdec(substr($hex, 2, 2)),
            hexdec(substr($hex, 4, 2)),
        );
    }

    private function humanUserRole(string $role): string
    {
        return match ($role) {
            'tinh_nguyen_vien' => 'Tình nguyện viên',
            'kiem_duyet_vien' => 'Kiểm duyệt viên',
            'quan_tri_vien' => 'Quản trị viên',
            default => $role,
        };
    }

    private function humanUserStatus(string $status): string
    {
        return match ($status) {
            'cho_duyet' => 'Chờ duyệt',
            'hoat_dong' => 'Hoạt động',
            'bi_khoa' => 'Bị khóa',
            default => $status,
        };
    }

    private function userStatusBadgeClass(string $status): string
    {
        return match ($status) {
            'cho_duyet' => 'bg-warning-subtle text-warning',
            'hoat_dong' => 'bg-success-subtle text-success',
            'bi_khoa' => 'bg-danger-subtle text-danger',
            default => 'bg-light text-dark',
        };
    }

    private function humanCampaignStatus(string $status): string
    {
        return match ($status) {
            'da_duyet' => 'Đang tuyển',
            'dang_dien_ra' => 'Đang diễn ra',
            'hoan_thanh' => 'Hoàn thành',
            'da_huy' => 'Đã hủy',
            'cho_duyet' => 'Chờ duyệt',
            'yeu_cau_huy' => 'Yêu cầu hủy',
            default => $status,
        };
    }

    private function campaignStatusBadgeClass(string $status): string
    {
        return match ($status) {
            'da_duyet' => 'bg-success-subtle text-success',
            'dang_dien_ra' => 'bg-primary-subtle text-primary',
            'hoan_thanh' => 'bg-secondary-subtle text-secondary',
            'da_huy' => 'bg-danger-subtle text-danger',
            'cho_duyet', 'yeu_cau_huy' => 'bg-warning-subtle text-warning',
            default => 'bg-light text-dark',
        };
    }
}
