<?php

use App\Http\Controllers\XacThucController;
use App\Http\Controllers\DanhMucController;
use App\Http\Controllers\NguoiDungController;
use App\Http\Controllers\ChienDichController;
use App\Http\Controllers\KiemDuyetChienDichController;
use App\Http\Controllers\ThamGiaChienDichController;
use App\Http\Controllers\TheoDoiPhanHoiController;
use App\Http\Controllers\RecommendationController;
use Illuminate\Support\Facades\Route;

// =========================================== DANH MỤC (Public) ========================================
Route::get('/danh-muc/ky-nang', [DanhMucController::class, 'getKyNang']);
Route::get('/danh-muc/khu-vuc', [DanhMucController::class, 'getKhuVuc']);
Route::get('/danh-muc/tinh-thanh', [DanhMucController::class, 'getTinhThanh']);
Route::get('/danh-muc/phuong-xa', [DanhMucController::class, 'getPhuongXa']);
Route::get('/danh-muc/loai-chien-dich', [ChienDichController::class, 'danhSachLoai']);
Route::get('/chien-dich/bo-loc', [ThamGiaChienDichController::class, 'boLoc']);
Route::get('/chien-dich/tim-kiem', [ThamGiaChienDichController::class, 'timKiem']);
Route::get('/chien-dich', [ThamGiaChienDichController::class, 'danhSach']);
Route::get('/chien-dich/{id}', [ThamGiaChienDichController::class, 'chiTiet']);

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
    Route::middleware('permission:account_center.view')->group(function () {
        Route::get('/nguoi-dung/thong-tin', [NguoiDungController::class, 'layThongTin']);
    });

    Route::middleware('permission:account_center.manage')->group(function () {
        Route::put('/nguoi-dung/cap-nhat-thong-tin', [NguoiDungController::class, 'capNhatThongTin']);
        Route::post('/nguoi-dung/cap-nhat-thong-tin', [NguoiDungController::class, 'capNhatThongTin']);
        Route::post('/nguoi-dung/doi-mat-khau', [NguoiDungController::class, 'doiMatKhau']);
    });

    // API dành riêng cho Tình nguyện viên
    Route::middleware('permission:competency_profile.view')->group(function () {
        Route::get('/nguoi-dung/ho-so-nang-luc', [NguoiDungController::class, 'layHoSoNangLuc']);
    });

    Route::middleware('permission:competency_profile.manage')->group(function () {
        Route::put('/nguoi-dung/ho-so-nang-luc', [NguoiDungController::class, 'luuHoSoNangLuc']);
    });
});

// =========================================== Tình Nguyện Viên ==========================================
Route::middleware(['auth:api', 'tinhNguyenVien'])->group(function () {
    Route::middleware('permission:ai_recommendation.view,campaign_coordination.view')->group(function () {
        Route::get('/goi-y', [RecommendationController::class, 'goiY']);
    });

    Route::middleware('permission:volunteer_campaigns.view,campaign_coordination.view,campaign_report_monitoring.view')->group(function () {
        Route::get('/tinh-nguyen-vien/chien-dich', [ChienDichController::class, 'danhSach']);
        Route::get('/tinh-nguyen-vien/chien-dich/{id}', [ChienDichController::class, 'chiTiet']);
    });

    Route::middleware('permission:volunteer_campaigns.manage')->group(function () {
        Route::post('/tinh-nguyen-vien/chien-dich', [ChienDichController::class, 'taoMoi']);
        Route::put('/tinh-nguyen-vien/chien-dich/{id}', [ChienDichController::class, 'capNhat']);
        Route::put('/tinh-nguyen-vien/chien-dich/{id}/trang-thai', [ChienDichController::class, 'capNhatTrangThai']);
        Route::put('/tinh-nguyen-vien/chien-dich/{id}/dang-ky/{registrationId}/trang-thai', [ChienDichController::class, 'capNhatTrangThaiDangKy']);
        Route::put('/tinh-nguyen-vien/chien-dich/{id}/huy', [ChienDichController::class, 'huyChienDich']);
    });

    Route::middleware('permission:campaign_participation.manage')->group(function () {
        Route::post('/chien-dich/{id}/dang-ky', [ThamGiaChienDichController::class, 'dangKy']);
        Route::put('/chien-dich/{id}/huy-dang-ky', [ThamGiaChienDichController::class, 'huyDangKy']);
        Route::put('/chien-dich/{id}/xac-nhan-tham-gia', [ThamGiaChienDichController::class, 'xacNhanThamGia']);
    });

    Route::middleware('permission:campaign_coordination.manage')->group(function () {
        Route::post('/chien-dich/{id}/moi-tinh-nguyen-vien', [RecommendationController::class, 'moiTinhNguyenVien']);
    });

    Route::middleware('permission:feedback_tracking.view')->group(function () {
        Route::get('/tinh-nguyen-vien/theo-doi-phan-hoi', [TheoDoiPhanHoiController::class, 'tongQuan']);
    });

    Route::middleware('permission:feedback_tracking.manage')->group(function () {
        Route::post('/tinh-nguyen-vien/theo-doi-phan-hoi/bao-cao', [TheoDoiPhanHoiController::class, 'taoBaoCao']);
        Route::post('/tinh-nguyen-vien/theo-doi-phan-hoi/danh-gia-chien-dich', [TheoDoiPhanHoiController::class, 'danhGiaChienDich']);
    });
});

// =========================================== KIỂM DUYỆT VIÊN =========================================
Route::middleware(['auth:api', 'kiemDuyetVien'])->group(function () {
    Route::middleware('permission:campaign_review.view')->group(function () {
        Route::get('/kiem-duyet/chien-dich/bo-loc', [KiemDuyetChienDichController::class, 'boLoc']);
        Route::get('/kiem-duyet/chien-dich', [KiemDuyetChienDichController::class, 'danhSach']);
        Route::get('/kiem-duyet/chien-dich/{id}', [KiemDuyetChienDichController::class, 'chiTiet']);
        Route::get('/kiem-duyet/chien-dich/{id}/feedback', [KiemDuyetChienDichController::class, 'danhSachFeedback']);
        Route::get('/kiem-duyet/chien-dich/{id}/bao-cao', [KiemDuyetChienDichController::class, 'danhSachBaoCao']);
    });

    Route::middleware('permission:campaign_review.manage')->group(function () {
        Route::put('/kiem-duyet/chien-dich/{id}/duyet', [KiemDuyetChienDichController::class, 'duyet']);
        Route::put('/kiem-duyet/chien-dich/{id}/tu-choi', [KiemDuyetChienDichController::class, 'tuChoi']);
        Route::put('/kiem-duyet/chien-dich/{id}/yeu-cau-huy/duyet', [KiemDuyetChienDichController::class, 'duyetYeuCauHuy']);
        Route::put('/kiem-duyet/chien-dich/{id}/yeu-cau-huy/tu-choi', [KiemDuyetChienDichController::class, 'tuChoiYeuCauHuy']);
        Route::put('/kiem-duyet/bao-cao/{id}/xu-ly', [KiemDuyetChienDichController::class, 'xuLyBaoCao']);
    });
});

// =========================================== QUẢN TRỊ VIÊN ==========================================
Route::middleware(['auth:api', 'quanTriVien'])->group(function () {
    Route::middleware('permission:user_management.view')->group(function () {
        Route::get('/admin/nguoi-dung', [NguoiDungController::class, 'danhSachQuanLy']);
    });

    Route::middleware('permission:user_management.manage')->group(function () {
        Route::post('/admin/nguoi-dung', [NguoiDungController::class, 'taoQuanLy']);
        Route::put('/admin/nguoi-dung/{id}', [NguoiDungController::class, 'capNhatQuanLy']);
        Route::put('/admin/nguoi-dung/{id}/trang-thai', [NguoiDungController::class, 'capNhatTrangThaiQuanLy']);
        Route::delete('/admin/nguoi-dung/{id}', [NguoiDungController::class, 'xoaQuanLy']);
    });

    Route::middleware('permission:permission_management.view')->group(function () {
        Route::get('/admin/phan-quyen', [NguoiDungController::class, 'danhSachPhanQuyen']);
    });

    Route::middleware('permission:permission_management.manage')->group(function () {
        Route::put('/admin/phan-quyen/{id}', [NguoiDungController::class, 'capNhatPhanQuyen']);
    });

    Route::middleware('permission:category_management.view')->group(function () {
        Route::get('/admin/danh-muc', [DanhMucController::class, 'danhSachQuanLy']);
    });

    Route::middleware('permission:category_management.manage')->group(function () {
        Route::post('/admin/danh-muc/{type}', [DanhMucController::class, 'taoQuanLy']);
        Route::put('/admin/danh-muc/{type}/{id}', [DanhMucController::class, 'capNhatQuanLy']);
        Route::delete('/admin/danh-muc/{type}/{id}', [DanhMucController::class, 'xoaQuanLy']);
    });
});
