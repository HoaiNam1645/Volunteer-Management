<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DanhMucController extends Controller
{
    // Danh sách kỹ năng (public - cho trang đăng ký)
    public function getKyNang()
    {
        $data = DB::table('ky_nangs')
            ->where('hoat_dong', 1)
            ->whereNull('xoa_luc')
            ->select('id', 'ten', 'bieu_tuong', 'mo_ta')
            ->orderBy('ten')
            ->get();

        return response()->json([
            'status' => 1,
            'data'   => $data,
        ]);
    }

    // Danh sách khu vực (public - cho trang đăng ký)
    public function getKhuVuc()
    {
        $data = DB::table('khu_vucs')
            ->where('hoat_dong', 1)
            ->whereNull('xoa_luc')
            ->select('id', 'ten')
            ->orderBy('ten')
            ->get();

        return response()->json([
            'status' => 1,
            'data'   => $data,
        ]);
    }

    // Danh sách tỉnh/thành phố (public)
    public function getTinhThanh()
    {
        $data = DB::table('tinh_thanh')
            ->select('id', 'ma', 'ten', 'vi_do', 'kinh_do')
            ->orderBy('ten')
            ->get();

        return response()->json([
            'status' => 1,
            'data'   => $data,
        ]);
    }

    // Danh sách phường/xã theo tỉnh/thành phố (public)
    public function getPhuongXa(Request $request)
    {
        $query = DB::table('phuong_xa')
            ->select('id', 'tinh_thanh_id', 'ma', 'ten', 'vi_do', 'kinh_do')
            ->orderBy('ten');

        if ($request->has('tinh_thanh_id') && $request->tinh_thanh_id) {
            $query->where('tinh_thanh_id', $request->tinh_thanh_id);
        }

        return response()->json([
            'status' => 1,
            'data'   => $query->get(),
        ]);
    }
}
