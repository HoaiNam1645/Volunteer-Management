<?php

namespace App\Http\Controllers;

use App\Http\Requests\DangKyRequest;
use App\Http\Requests\DangNhapRequest;
use App\Http\Requests\DatLaiMatKhauRequest;
use App\Http\Requests\QuenMatKhauRequest;
use App\Jobs\SendMailJob;
use App\Models\KhuVuc;
use App\Models\KyNang;
use App\Models\NguoiDung;
use App\Models\TaiKhoanLienKet;
use Google\Client as GoogleClient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class XacThucController extends Controller
{
    private function resolveKyNangIcon(): string
    {
        return KyNang::query()
            ->whereNotNull('bieu_tuong')
            ->where('bieu_tuong', '!=', '')
            ->value('bieu_tuong') ?? 'fa-solid fa-bars-staggered';
    }

    private function resolveCustomKyNangIds(array $items): array
    {
        return collect($items)
            ->map(fn($value) => trim((string) $value))
            ->filter()
            ->map(function (string $ten) {
                $icon = $this->resolveKyNangIcon();
                $existing = KyNang::query()
                    ->whereRaw('LOWER(ten) = ?', [mb_strtolower($ten)])
                    ->first();

                if ($existing) {
                    $updates = [];

                    if ((int) $existing->hoat_dong !== 1 || $existing->xoa_luc) {
                        $updates['hoat_dong'] = 1;
                        $updates['xoa_luc'] = null;
                    }

                    if (!$existing->bieu_tuong) {
                        $updates['bieu_tuong'] = $icon;
                    }

                    if (!empty($updates)) {
                        $existing->update([
                            ...$updates,
                        ]);
                    }

                    return $existing->id;
                }

                return KyNang::create([
                    'ten' => $ten,
                    'bieu_tuong' => $icon,
                    'hoat_dong' => 1,
                ])->id;
            })
            ->unique()
            ->values()
            ->all();
    }

    private function resolveCustomKhuVucIds(array $items): array
    {
        return collect($items)
            ->map(fn($value) => trim((string) $value))
            ->filter()
            ->map(function (string $ten) {
                $existing = KhuVuc::query()
                    ->whereRaw('LOWER(ten) = ?', [mb_strtolower($ten)])
                    ->first();

                if ($existing) {
                    if ((int) $existing->hoat_dong !== 1 || $existing->xoa_luc) {
                        $existing->update([
                            'hoat_dong' => 1,
                            'xoa_luc' => null,
                        ]);
                    }

                    return $existing->id;
                }

                return KhuVuc::create([
                    'ten' => $ten,
                    'hoat_dong' => 1,
                ])->id;
            })
            ->unique()
            ->values()
            ->all();
    }

    // ======================== ĐĂNG KÝ ========================
    public function dangKy(DangKyRequest $request)
    {
        $nguoi_dung = DB::transaction(function () use ($request) {
            $nguoiDung = NguoiDung::create([
                'ho_ten'        => $request->ho_ten,
                'email'         => $request->email,
                'mat_khau'      => $request->password,
                'so_dien_thoai' => $request->so_dien_thoai,
            ]);

            $kyNangIds = collect($request->input('ky_nang_ids', []))
                ->map(fn($id) => (int) $id)
                ->filter()
                ->values();

            $kyNangIds = $kyNangIds
                ->merge($this->resolveCustomKyNangIds($request->input('ky_nang_khac', [])))
                ->unique()
                ->values();

            if ($kyNangIds->isNotEmpty()) {
                $ky_nang_data = $kyNangIds->map(fn($id) => [
                    'nguoi_dung_id' => $nguoiDung->id,
                    'ky_nang_id'    => $id,
                    'tao_luc'       => now(),
                ])->all();

                DB::table('nguoi_dung_ky_nangs')->insert($ky_nang_data);
            }

            $khuVucIds = collect($request->input('khu_vuc_ids', []))
                ->map(fn($id) => (int) $id)
                ->filter()
                ->values();

            $khuVucIds = $khuVucIds
                ->merge($this->resolveCustomKhuVucIds($request->input('khu_vuc_khac', [])))
                ->unique()
                ->values();

            if ($khuVucIds->isNotEmpty()) {
                $khu_vuc_data = $khuVucIds->map(fn($id) => [
                    'nguoi_dung_id' => $nguoiDung->id,
                    'khu_vuc_id'    => $id,
                    'tao_luc'       => now(),
                ])->all();

                DB::table('nguoi_dung_khu_vucs')->insert($khu_vuc_data);
            }

            $ma_xac_thuc = Str::uuid()->toString();
            DB::table('xac_thuc_emails')->insert([
                'nguoi_dung_id' => $nguoiDung->id,
                'ma_xac_thuc'   => $ma_xac_thuc,
                'het_han_luc'   => now()->addHour(),
                'tao_luc'       => now(),
            ]);

            $nguoiDung->setAttribute('ma_xac_thuc_email', $ma_xac_thuc);

            return $nguoiDung;
        });

        // Gửi mail xác thực
        $data_mail = [
            'ho_ten' => $nguoi_dung->ho_ten,
            'link'   => env('FRONTEND_URL', 'http://localhost:5173') . '/xac-thuc-email/' . $nguoi_dung->ma_xac_thuc_email,
        ];
        SendMailJob::dispatch(
            $nguoi_dung->email,
            'Xác Thực Email - VolunteerHub',
            'xac_thuc_email',
            $data_mail
        );

        return response()->json([
            'status'  => 1,
            'message' => 'Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản.',
        ]);
    }

    // ======================== XÁC THỰC EMAIL ========================
    public function xacThucEmail(Request $request)
    {
        $token = DB::table('xac_thuc_emails')
            ->where('ma_xac_thuc', $request->ma_xac_thuc)
            ->whereNull('xac_thuc_luc')
            ->first();

        if (!$token) {
            return response()->json([
                'status'  => 0,
                'message' => 'Liên kết xác thực không hợp lệ hoặc đã được sử dụng.',
            ]);
        }

        if (now()->gt($token->het_han_luc)) {
            return response()->json([
                'status'  => 0,
                'message' => 'Liên kết xác thực đã hết hạn. Vui lòng đăng ký lại.',
            ]);
        }

        // Cập nhật trạng thái xác thực
        DB::table('xac_thuc_emails')
            ->where('id', $token->id)
            ->update(['xac_thuc_luc' => now()]);

        $nguoi_dung = NguoiDung::find($token->nguoi_dung_id);
        if ($nguoi_dung) {
            $nguoi_dung->update([
                'xac_thuc_email_luc' => now(),
                'trang_thai'         => 'hoat_dong',
            ]);
        }

        return response()->json([
            'status'  => 1,
            'message' => 'Xác thực email thành công! Bạn có thể đăng nhập ngay.',
        ]);
    }

    // ======================== ĐĂNG NHẬP ========================
    public function dangNhap(DangNhapRequest $request)
    {
        $nguoi_dung = NguoiDung::where('email', $request->email)->first();

        // Kiểm tra tài khoản đã xác thực email chưa
        if (!$nguoi_dung->xac_thuc_email_luc) {
            return response()->json([
                'status'  => 0,
                'message' => 'Tài khoản chưa xác thực email. Vui lòng kiểm tra hộp thư.',
            ]);
        }

        // Kiểm tra tài khoản bị khóa
        if ($nguoi_dung->trang_thai == 'bi_khoa') {
            return response()->json([
                'status'  => 0,
                'message' => 'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.',
            ]);
        }

        // Xác thực đăng nhập
        $credentials = [
            'email'    => $request->email,
            'password' => $request->password,
        ];

        $token = auth('api')->attempt($credentials);

        if (!$token) {
            return response()->json([
                'status'  => 0,
                'message' => 'Email hoặc mật khẩu không đúng.',
            ]);
        }

        return $this->taoPhanHoiDangNhap($nguoi_dung, $token);
    }

    public function dangNhapGoogle(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string',
        ], [
            'code.required' => 'Thiếu mã xác thực Google.',
            'code.string'   => 'Mã xác thực Google không hợp lệ.',
        ]);

        $googleClientId = (string) config('services.google.client_id');
        $googleClientSecret = (string) config('services.google.client_secret');
        $googleRedirectUri = (string) config('services.google.redirect_uri', 'postmessage');

        if (!$googleClientId || !$googleClientSecret) {
            return response()->json([
                'status'  => 0,
                'message' => 'Hệ thống chưa cấu hình đăng nhập Google.',
            ], 500);
        }

        try {
            $googleClient = new GoogleClient([
                'client_id' => $googleClientId,
                'client_secret' => $googleClientSecret,
            ]);
            $googleClient->setRedirectUri($googleRedirectUri ?: 'postmessage');

            $oauthTokens = $googleClient->fetchAccessTokenWithAuthCode($validated['code']);
            if (isset($oauthTokens['error'])) {
                return response()->json([
                    'status'  => 0,
                    'message' => 'Không thể xác thực tài khoản Google. Vui lòng thử lại.',
                ], 422);
            }

            $idToken = $oauthTokens['id_token'] ?? null;
            if (!$idToken) {
                return response()->json([
                    'status'  => 0,
                    'message' => 'Google không trả về thông tin định danh hợp lệ.',
                ], 422);
            }

            $payload = $googleClient->verifyIdToken($idToken);
            if (!$payload) {
                return response()->json([
                    'status'  => 0,
                    'message' => 'Phiên đăng nhập Google không hợp lệ.',
                ], 422);
            }
        } catch (\Throwable $e) {
            return response()->json([
                'status'  => 0,
                'message' => 'Xác thực Google thất bại. Vui lòng thử lại sau.',
            ], 422);
        }

        $googleSub = (string) ($payload['sub'] ?? '');
        $email = mb_strtolower(trim((string) ($payload['email'] ?? '')));
        $hoTen = trim((string) ($payload['name'] ?? ''));
        $anhDaiDien = trim((string) ($payload['picture'] ?? ''));
        $emailVerified = (bool) ($payload['email_verified'] ?? false);

        if (!$googleSub || !$email || !$emailVerified) {
            return response()->json([
                'status'  => 0,
                'message' => 'Thông tin tài khoản Google không hợp lệ hoặc chưa xác thực email.',
            ], 422);
        }

        $nguoi_dung = DB::transaction(function () use ($googleSub, $email, $hoTen, $anhDaiDien) {
            $linkedAccount = TaiKhoanLienKet::query()
                ->where('nha_cung_cap', 'google')
                ->where('id_nha_cung_cap', $googleSub)
                ->first();

            $user = $linkedAccount?->nguoiDung;

            if (!$user) {
                $user = NguoiDung::where('email', $email)->first();
            }

            if ($user) {
                $updates = [];

                if (!$user->xac_thuc_email_luc) {
                    $updates['xac_thuc_email_luc'] = now();
                }

                if ($user->trang_thai !== 'bi_khoa' && $user->trang_thai !== 'hoat_dong') {
                    $updates['trang_thai'] = 'hoat_dong';
                }

                if ($anhDaiDien && !$user->anh_dai_dien) {
                    $updates['anh_dai_dien'] = $anhDaiDien;
                }

                if ($hoTen && (!$user->ho_ten || str_starts_with($user->ho_ten, 'Tình nguyện viên'))) {
                    $updates['ho_ten'] = $hoTen;
                }

                if (!empty($updates)) {
                    $user->update($updates);
                }

                TaiKhoanLienKet::query()->updateOrCreate(
                    [
                        'nha_cung_cap' => 'google',
                        'id_nha_cung_cap' => $googleSub,
                    ],
                    [
                        'nguoi_dung_id' => $user->id,
                    ]
                );

                return $user->fresh();
            }

            $newUser = NguoiDung::create([
                'ho_ten' => $hoTen ?: 'Tình nguyện viên #' . strtoupper(Str::random(6)),
                'email' => $email,
                'anh_dai_dien' => $anhDaiDien ?: null,
                'mat_khau' => null,
                'xac_thuc_email_luc' => now(),
                'trang_thai' => 'hoat_dong',
            ]);

            TaiKhoanLienKet::create([
                'nguoi_dung_id' => $newUser->id,
                'nha_cung_cap' => 'google',
                'id_nha_cung_cap' => $googleSub,
            ]);

            return $newUser;
        });

        if ($nguoi_dung->trang_thai === 'bi_khoa') {
            return response()->json([
                'status'  => 0,
                'message' => 'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.',
            ], 403);
        }

        $token = auth('api')->login($nguoi_dung);
        if (!$token) {
            return response()->json([
                'status'  => 0,
                'message' => 'Không thể tạo phiên đăng nhập. Vui lòng thử lại.',
            ], 500);
        }

        return $this->taoPhanHoiDangNhap($nguoi_dung->fresh(), $token);
    }

    private function taoPhanHoiDangNhap(NguoiDung $nguoi_dung, string $token)
    {
        $cookie = cookie(
            'token',           // name
            $token,            // value
            config('jwt.ttl'), // minutes
            '/',               // path
            null,              // domain
            false,             // secure (true cho production)
            true,              // httpOnly
            false,             // raw
            'Lax'              // sameSite
        );

        return response()->json([
            'status'  => 1,
            'message' => 'Đăng nhập thành công!',
            'data'    => [
                'id'           => $nguoi_dung->id,
                'ho_ten'       => $nguoi_dung->ho_ten,
                'email'        => $nguoi_dung->email,
                'vai_tro'      => $nguoi_dung->vai_tro,
                'trang_thai'   => $nguoi_dung->trang_thai,
                'anh_dai_dien' => $nguoi_dung->anh_dai_dien,
                'quyen_han'    => $nguoi_dung->layTatCaQuyen(),
                'permissions'  => $nguoi_dung->layTatCaQuyen(),
                'su_dung_mac_dinh' => $nguoi_dung->dangDungQuyenMacDinh(),
            ],
            'token'   => $token,
        ])->cookie($cookie);
    }

    // ======================== ĐĂNG XUẤT ========================
    public function dangXuat()
    {
        try {
            auth('api')->logout();
        } catch (\Exception $e) {
            // Token đã hết hạn hoặc không hợp lệ
        }

        // Xóa cookie
        $cookie = cookie()->forget('token');

        return response()->json([
            'status'  => 1,
            'message' => 'Đăng xuất thành công!',
        ])->cookie($cookie);
    }

    // ======================== LẤY THÔNG TIN ========================
    public function layThongTin()
    {
        $user = auth('api')->user();
        if (!$user) {
            return response()->json([
                'status'  => 0,
                'message' => 'Bạn cần đăng nhập hệ thống!',
            ], 401);
        }

        return response()->json([
            'status' => 1,
            'data'   => [
                'id'           => $user->id,
                'ho_ten'       => $user->ho_ten,
                'email'        => $user->email,
                'so_dien_thoai' => $user->so_dien_thoai,
                'anh_dai_dien' => $user->anh_dai_dien,
                'ngay_sinh'    => $user->ngay_sinh,
                'gioi_tinh'    => $user->gioi_tinh,
                'vai_tro'      => $user->vai_tro,
                'trang_thai'   => $user->trang_thai,
                'quyen_han'    => $user->layTatCaQuyen(),
                'permissions'  => $user->layTatCaQuyen(),
                'su_dung_mac_dinh' => $user->dangDungQuyenMacDinh(),
            ],
        ]);
    }

    // ======================== QUÊN MẬT KHẨU ========================
    public function quenMatKhau(QuenMatKhauRequest $request)
    {
        $nguoi_dung = NguoiDung::where('email', $request->email)->first();

        // Xóa token cũ (nếu có)
        DB::table('dat_lai_mat_khaus')->where('email', $request->email)->delete();

        // Tạo token mới (hết hạn sau 1h)
        $ma_xac_thuc = Str::uuid()->toString();
        DB::table('dat_lai_mat_khaus')->insert([
            'email'       => $request->email,
            'ma_xac_thuc' => $ma_xac_thuc,
            'het_han_luc'  => now()->addHour(),
            'tao_luc'      => now(),
        ]);

        // Gửi mail đặt lại mật khẩu
        $data_mail = [
            'ho_ten' => $nguoi_dung->ho_ten,
            'email'  => $nguoi_dung->email,
            'link'   => env('FRONTEND_URL', 'http://localhost:5173') . '/dat-lai-mat-khau/' . $ma_xac_thuc,
        ];
        SendMailJob::dispatch(
            $nguoi_dung->email,
            'Đặt Lại Mật Khẩu - VolunteerHub',
            'quen_mat_khau',
            $data_mail
        );

        return response()->json([
            'status'  => 1,
            'message' => 'Đã gửi liên kết đặt lại mật khẩu. Vui lòng kiểm tra email.',
        ]);
    }

    // ======================== ĐẶT LẠI MẬT KHẨU ========================
    public function datLaiMatKhau(DatLaiMatKhauRequest $request)
    {
        $token = DB::table('dat_lai_mat_khaus')
            ->where('ma_xac_thuc', $request->ma_xac_thuc)
            ->first();

        if (!$token) {
            return response()->json([
                'status'  => 0,
                'message' => 'Mã xác thực không hợp lệ.',
            ]);
        }

        if (now()->gt($token->het_han_luc)) {
            // Xóa token hết hạn
            DB::table('dat_lai_mat_khaus')->where('id', $token->id)->delete();
            return response()->json([
                'status'  => 0,
                'message' => 'Liên kết đặt lại mật khẩu đã hết hạn. Vui lòng gửi yêu cầu mới.',
            ]);
        }

        // Cập nhật mật khẩu
        $nguoi_dung = NguoiDung::where('email', $token->email)->first();
        if ($nguoi_dung) {
            $nguoi_dung->update([
                'mat_khau' => $request->password,
            ]);
        }

        // Xóa token đã sử dụng
        DB::table('dat_lai_mat_khaus')->where('id', $token->id)->delete();

        return response()->json([
            'status'  => 1,
            'message' => 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập với mật khẩu mới.',
        ]);
    }
}
