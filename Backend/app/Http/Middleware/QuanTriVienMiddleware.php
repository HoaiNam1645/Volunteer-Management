<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class QuanTriVienMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = auth('api')->user();
        if ($user && $user instanceof \App\Models\NguoiDung && $user->vai_tro == 'quan_tri_vien') {
            return $next($request);
        }
        return response()->json([
            'status'  => 0,
            'message' => 'Bạn không có quyền truy cập chức năng này'
        ], 403);
    }
}
