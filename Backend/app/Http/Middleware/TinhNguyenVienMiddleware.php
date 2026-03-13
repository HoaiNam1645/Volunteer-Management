<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TinhNguyenVienMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = auth('api')->user();
        if ($user && $user instanceof \App\Models\NguoiDung && $user->vai_tro == 'tinh_nguyen_vien') {
            return $next($request);
        }
        return response()->json([
            'status'  => 0,
            'message' => 'Bạn không có quyền truy cập chức năng này'
        ], 403);
    }
}
