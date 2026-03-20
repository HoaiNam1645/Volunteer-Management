<?php

namespace App\Services;

class DistanceService
{
    public function haversine(?float $lat1, ?float $lon1, ?float $lat2, ?float $lon2): ?float
    {
        if ($lat1 === null || $lon1 === null || $lat2 === null || $lon2 === null) {
            return null;
        }

        $earthRadiusKm = 6371;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return round($earthRadiusKm * $c, 2);
    }

    public function scoreFromDistance(?float $distanceKm): float
    {
        if ($distanceKm === null) {
            return 0;
        }

        if ($distanceKm <= 3) {
            return 100;
        }

        if ($distanceKm <= 10) {
            return $this->interpolate($distanceKm, 3, 10, 100, 70);
        }

        if ($distanceKm <= 20) {
            return $this->interpolate($distanceKm, 10, 20, 70, 40);
        }

        return 10;
    }

    private function interpolate(float $value, float $minX, float $maxX, float $minY, float $maxY): float
    {
        if ($maxX <= $minX) {
            return $maxY;
        }

        $ratio = ($value - $minX) / ($maxX - $minX);

        return round($minY + (($maxY - $minY) * $ratio), 2);
    }
}
