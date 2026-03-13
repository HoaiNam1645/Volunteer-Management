<?php

use App\Http\Controllers\XacThucController;
use App\Http\Controllers\DanhMucController;
use App\Http\Controllers\NguoiDungController;
use App\Http\Controllers\ChienDichController;
use Illuminate\Support\Facades\Route;

// =========================================== DANH MỤC (Public) ========================================
Route::get('/danh-muc/ky-nang', [DanhMucController::class, 'getKyNang']);
Route::get('/danh-muc/khu-vuc', [DanhMucController::class, 'getKhuVuc']);
Route::get('/danh-muc/tinh-thanh', [DanhMucController::class, 'getTinhThanh']);
Route::get('/danh-muc/phuong-xa', [DanhMucController::class, 'getPhuongXa']);
Route::get('/danh-muc/loai-chien-dich', [ChienDichController::class, 'danhSachLoai']);

// =========================================== XÁC THỰC ===============================================
Route::post('/xac-thuc/dang-ky', [XacThucController::class, 'dangKy']);
Route::post('/xac-thuc/xac-thuc-email', [XacThucController::class, 'xacThucEmail']);
Route::post('/xac-thuc/dang-nhap', [XacThucController::class, 'dangNhap']);
Route::post('/xac-thuc/dang-xuat', [XacThucController::class, 'dangXuat']);
Route::post('/xac-thuc/quen-mat-khau', [XacThucController::class, 'quenMatKhau']);
Route::post('/xac-thuc/dat-lai-mat-khau', [XacThucController::class, 'datLaiMatKhau']);
Route::get('/xac-thuc/thong-tin', [XacThucController::class, 'layThongTin']);

// =========================================== NGƯỜI DÙNG (Auth Required) ==============================
Route::middleware('auth:api')->group(function () {
    // API dành cho mọi tài khoản dùng chung
    Route::get('/nguoi-dung/thong-tin', [NguoiDungController::class, 'layThongTin']);
    Route::put('/nguoi-dung/cap-nhat-thong-tin', [NguoiDungController::class, 'capNhatThongTin']);
    Route::post('/nguoi-dung/doi-mat-khau', [NguoiDungController::class, 'doiMatKhau']);

    // API dành riêng cho Tình nguyện viên
    Route::get('/nguoi-dung/ho-so-nang-luc', [NguoiDungController::class, 'layHoSoNangLuc']);
    Route::put('/nguoi-dung/ho-so-nang-luc', [NguoiDungController::class, 'luuHoSoNangLuc']);
});

// =========================================== KIỂM DUYỆT VIÊN ==========================================
Route::middleware(['auth:api', 'kiemDuyetVien'])->group(function () {
    Route::get('/kiem-duyet/chien-dich', [ChienDichController::class, 'danhSach']);
    Route::post('/kiem-duyet/chien-dich', [ChienDichController::class, 'taoMoi']);
    Route::get('/kiem-duyet/chien-dich/{id}', [ChienDichController::class, 'chiTiet']);
    Route::put('/kiem-duyet/chien-dich/{id}', [ChienDichController::class, 'capNhat']);
    Route::put('/kiem-duyet/chien-dich/{id}/huy', [ChienDichController::class, 'huyChienDich']);
});

// =========================================== QUẢN TRỊ VIÊN ==========================================
Route::middleware(['auth:api', 'quanTriVien'])->group(function () {
    Route::get('/admin/nguoi-dung', [NguoiDungController::class, 'danhSachQuanLy']);
    Route::put('/admin/nguoi-dung/{id}/vai-tro', [NguoiDungController::class, 'capNhatVaiTro']);
});
