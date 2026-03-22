<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class PermissionMiddleware
{
    public function handle(Request $request, Closure $next, string ...$permissions): Response
    {
        $user = auth('api')->user();

        if (!$user || !$user instanceof \App\Models\NguoiDung) {
            return response()->json([
                'status' => 0,
                'message' => 'Bạn cần đăng nhập để tiếp tục.',
            ], 401);
        }

        if (empty($permissions)) {
            return $next($request);
        }

        foreach ($permissions as $permission) {
            if ($user->coQuyen($permission)) {
                return $next($request);
            }
        }

        return response()->json([
            'status' => 0,
            'message' => 'Bạn không có quyền truy cập chức năng này.',
        ], 403);
    }
}
