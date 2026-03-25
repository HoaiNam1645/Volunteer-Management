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

        // Giảm lợi thế của yếu tố khoảng cách: dưới 5km vẫn là gần,
        // nhưng chỉ nên mang lại mức điểm trên 80 thay vì gần như tuyệt đối.
        if ($distanceKm <= 5) {
            return $this->interpolate($distanceKm, 0, 5, 92, 82);
        }

        if ($distanceKm <= 10) {
            return $this->interpolate($distanceKm, 5, 10, 80, 65);
        }

        if ($distanceKm <= 20) {
            return $this->interpolate($distanceKm, 10, 20, 65, 40);
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
