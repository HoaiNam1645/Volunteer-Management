<?php

namespace App\Services;

use App\Models\KhuVuc;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class AreaResolutionService
{
    private const AREA_CATALOG_CACHE_KEY = 'area_resolution.catalog.v1';
    private const AREA_CATALOG_CACHE_TTL = 3600;

    public function resolveCampaignAreaId(?int $explicitAreaId, ?string $location): ?int
    {
        if ($explicitAreaId) {
            return $explicitAreaId;
        }

        $normalizedLocation = $this->normalizeText($location);
        if ($normalizedLocation === '') {
            return null;
        }

        $segments = collect(explode(',', (string) $location))
            ->map(fn ($segment) => $this->normalizeText($segment))
            ->filter()
            ->values()
            ->all();

        $bestMatch = null;
        $bestScore = -1;

        foreach ($this->getAreaCatalog() as $area) {
            foreach ($area['candidates'] as $candidate) {
                $score = $this->scoreCandidate($candidate, $normalizedLocation, $segments);
                if ($score > $bestScore) {
                    $bestScore = $score;
                    $bestMatch = $area;
                }
            }
        }

        return $bestScore > 0 ? (int) $bestMatch['id'] : null;
    }

    private function getAreaCatalog(): array
    {
        return Cache::remember(self::AREA_CATALOG_CACHE_KEY, self::AREA_CATALOG_CACHE_TTL, function () {
            return KhuVuc::query()
                ->whereNull('xoa_luc')
                ->get(['id', 'ten'])
                ->map(function (KhuVuc $area) {
                    return [
                        'id' => (int) $area->id,
                        'name' => $area->ten,
                        'candidates' => $this->buildCandidates($area->ten),
                    ];
                })
                ->all();
        });
    }

    private function buildCandidates(?string $name): array
    {
        $normalized = $this->normalizeText($name);
        if ($normalized === '') {
            return [];
        }

        $candidates = [$normalized];
        $candidates[] = preg_replace('/^(thanh pho|tp|tinh)\s+/', '', $normalized);

        foreach ($this->buildSpecialAliases($normalized) as $alias) {
            $candidates[] = $alias;
        }

        return array_values(array_unique(array_filter($candidates)));
    }

    private function buildSpecialAliases(string $normalized): array
    {
        $aliases = [];

        if (str_contains($normalized, 'ho chi minh')) {
            $aliases = ['hcm', 'tphcm', 'tp hcm', 'sai gon', 'saigon'];
        } elseif (str_contains($normalized, 'da nang')) {
            $aliases = ['tp da nang'];
        } elseif (str_contains($normalized, 'ha noi')) {
            $aliases = ['hn'];
        } elseif (str_contains($normalized, 'hai phong')) {
            $aliases = ['tp hai phong'];
        } elseif (str_contains($normalized, 'can tho')) {
            $aliases = ['tp can tho'];
        } elseif (str_contains($normalized, 'hue')) {
            $aliases = ['thua thien hue', 'tp hue', 'thanh pho hue'];
        }

        return array_values(array_unique(array_filter(array_map(fn ($item) => $this->normalizeText($item), $aliases))));
    }

    private function scoreCandidate(string $candidate, string $normalizedLocation, array $segments): int
    {
        if ($candidate === '') {
            return -1;
        }

        if (in_array($candidate, $segments, true)) {
            return 300 + strlen($candidate);
        }

        $tailSegments = array_slice($segments, -2);
        foreach ($tailSegments as $segment) {
            if ($segment === $candidate) {
                return 260 + strlen($candidate);
            }
        }

        $pattern = '/(^|\s)' . preg_quote($candidate, '/') . '($|\s)/';
        if (preg_match($pattern, $normalizedLocation) === 1) {
            return 120 + strlen($candidate);
        }

        return -1;
    }

    private function normalizeText(?string $value): string
    {
        $ascii = Str::of((string) $value)->ascii()->lower()->value();
        $ascii = preg_replace('/[^a-z0-9]+/u', ' ', $ascii);

        return trim(preg_replace('/\s+/u', ' ', $ascii ?? ''));
    }
}
