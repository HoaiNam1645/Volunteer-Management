<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class KiemDuyetVienMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = auth('api')->user();
        if (
            $user
            && $user instanceof \App\Models\NguoiDung
            && in_array($user->vai_tro, ['kiem_duyet_vien', 'quan_tri_vien'], true)
        ) {
            return $next($request);
        }
        return response()->json([
            'status'  => 0,
            'message' => 'Bạn không có quyền truy cập chức năng này'
        ], 403);
    }
}
