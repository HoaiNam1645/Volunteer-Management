<!DOCTYPE html>
<html lang="vi" style="padding:0;Margin:0">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Nhắc nhở chiến dịch sắp bắt đầu</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>
<body style="margin:0;padding:0;background-color:#f3f4f6;font-family:'Inter','Helvetica Neue',Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f3f4f6;">
    <tr>
        <td align="center" style="padding:32px 16px;">
            <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;border-radius:16px;overflow:hidden;max-width:600px;width:100%;box-shadow:0 12px 32px rgba(15,23,42,0.08);">
                <tr>
                    <td style="padding:32px;background:#EEF2FF;border-bottom:1px solid #E5E7EB;">
                        <h1 style="margin:0;font-size:24px;line-height:32px;color:#4338CA;font-weight:700;">Chiến dịch sắp bắt đầu</h1>
                        <p style="margin:8px 0 0;font-size:14px;line-height:22px;color:#4B5563;">Nhắc nhở dành cho người tạo chiến dịch</p>
                    </td>
                </tr>
                <tr>
                    <td style="padding:28px 32px;">
                        <p style="margin:0 0 16px;font-size:15px;line-height:24px;color:#374151;">Xin chào <strong>{{ $data['ho_ten'] ?? 'bạn' }}</strong>,</p>
                        <p style="margin:0 0 20px;font-size:15px;line-height:24px;color:#4B5563;">
                            Chiến dịch của bạn sẽ bắt đầu trong vòng 72 giờ tới. Hãy kiểm tra lại công tác chuẩn bị, danh sách nhân sự và các hạng mục vận hành trước giờ diễn ra.
                        </p>

                        <div style="background:#F9FAFB;border:1px solid #E5E7EB;border-radius:12px;padding:18px 20px;margin-bottom:20px;">
                            <p style="margin:0 0 10px;font-size:14px;color:#6B7280;">Chiến dịch</p>
                            <p style="margin:0 0 10px;font-size:18px;font-weight:700;color:#111827;">{{ $data['ten_chien_dich'] ?? '' }}</p>
                            <p style="margin:0 0 6px;font-size:14px;color:#374151;">Địa điểm: {{ $data['dia_diem'] ?? '—' }}</p>
                            <p style="margin:0 0 6px;font-size:14px;color:#374151;">Thời gian: {{ $data['ngay_bat_dau'] ?? '—' }} — {{ $data['ngay_ket_thuc'] ?? '—' }}</p>
                            <p style="margin:0;font-size:14px;color:#374151;">Hạn đăng ký: <strong>{{ $data['han_dang_ky'] ?? '—' }}</strong></p>
                        </div>

                        <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="margin-bottom:20px;">
                            <tr>
                                <td width="33.33%" style="padding:0 6px 0 0;">
                                    <div style="background:#EFF6FF;border:1px solid #BFDBFE;border-radius:12px;padding:16px;text-align:center;">
                                        <p style="margin:0 0 8px;font-size:13px;color:#1D4ED8;">Đã đăng ký</p>
                                        <p style="margin:0;font-size:24px;font-weight:700;color:#1E3A8A;">{{ $data['so_dang_ky'] ?? 0 }}</p>
                                    </div>
                                </td>
                                <td width="33.33%" style="padding:0 3px;">
                                    <div style="background:#ECFDF5;border:1px solid #A7F3D0;border-radius:12px;padding:16px;text-align:center;">
                                        <p style="margin:0 0 8px;font-size:13px;color:#059669;">Đã xác nhận</p>
                                        <p style="margin:0;font-size:24px;font-weight:700;color:#065F46;">{{ $data['so_xac_nhan'] ?? 0 }}</p>
                                    </div>
                                </td>
                                <td width="33.33%" style="padding:0 0 0 6px;">
                                    <div style="background:#FFF7ED;border:1px solid #FED7AA;border-radius:12px;padding:16px;text-align:center;">
                                        <p style="margin:0 0 8px;font-size:13px;color:#C2410C;">Số lượng tối đa</p>
                                        <p style="margin:0;font-size:24px;font-weight:700;color:#9A3412;">{{ $data['so_luong_toi_da'] ?? 0 }}</p>
                                    </div>
                                </td>
                            </tr>
                        </table>

                        @if(isset($data['so_luong_con_thieu']))
                        <div style="background:#FFF7ED;border-left:4px solid #F97316;border-radius:8px;padding:14px 16px;margin-bottom:20px;">
                            <p style="margin:0 0 6px;font-size:13px;font-weight:600;color:#9A3412;">Lưu ý nhân sự</p>
                            <p style="margin:0;font-size:14px;line-height:22px;color:#7C2D12;">
                                @if(($data['so_luong_con_thieu'] ?? 0) > 0)
                                    Hiện còn thiếu <strong>{{ $data['so_luong_con_thieu'] }}</strong> tình nguyện viên so với số lượng tối đa mong muốn.
                                @else
                                    Chiến dịch hiện không thiếu nhân sự theo số lượng tối đa đã cấu hình.
                                @endif
                            </p>
                        </div>
                        @endif

                        <div style="text-align:center;margin-top:28px;">
                            <a href="{{ $data['link_chien_dich'] ?? '#' }}" style="display:inline-block;padding:14px 28px;background:#4338CA;color:#ffffff;text-decoration:none;border-radius:10px;font-size:15px;font-weight:700;">Vào quản lý chiến dịch</a>
                        </div>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
