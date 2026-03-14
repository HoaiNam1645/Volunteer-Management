<!DOCTYPE html>
<html lang="vi" style="padding:0;Margin:0">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Thông báo chiến dịch tiếp tục diễn ra</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>
<body style="margin:0;padding:0;background-color:#eff6ff;font-family:'Inter','Helvetica Neue',Helvetica,Arial,sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#eff6ff;">
        <tr>
            <td align="center" style="padding:40px 16px;">
                <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;border-radius:16px;box-shadow:0 8px 32px rgba(37,99,235,0.10);overflow:hidden;max-width:600px;width:100%;">
                    <tr>
                        <td align="center" style="background:linear-gradient(135deg,#3b82f6,#1d4ed8);padding:40px 30px 30px;">
                            <div style="width:64px;height:64px;background:rgba(255,255,255,0.2);border-radius:50%;display:inline-block;line-height:64px;text-align:center;">
                                <span style="font-size:32px;">📣</span>
                            </div>
                            <h1 style="font-size:24px;line-height:32px;color:#ffffff;margin:16px 0 0;font-weight:700;letter-spacing:-0.5px;">Chiến dịch tiếp tục diễn ra</h1>
                            <p style="font-size:14px;color:rgba(255,255,255,0.85);margin:8px 0 0;line-height:20px;">Thông báo cập nhật kết quả xử lý yêu cầu hủy chiến dịch</p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:32px 36px;">
                            <p style="font-size:16px;color:#374151;line-height:26px;margin:0 0 8px;">
                                Xin chào <strong style="color:#1d4ed8;">{{ $data['ho_ten'] }}</strong>,
                            </p>
                            <p style="font-size:15px;color:#6B7280;line-height:24px;margin:0 0 24px;">
                                Kiểm duyệt viên đã <strong>từ chối yêu cầu hủy</strong>. Chiến dịch bạn đăng ký tham gia sẽ <strong>tiếp tục diễn ra theo kế hoạch</strong>.
                            </p>

                            <div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:12px;padding:20px;margin:0 0 24px;">
                                <table width="100%" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#6b7280;display:inline-block;width:120px;">📋 Chiến dịch:</span>
                                            <strong style="font-size:14px;color:#111827;">{{ $data['ten_chien_dich'] }}</strong>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#6b7280;display:inline-block;width:120px;">📍 Địa điểm:</span>
                                            <span style="font-size:14px;color:#111827;">{{ $data['dia_diem'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#6b7280;display:inline-block;width:120px;">📅 Thời gian:</span>
                                            <span style="font-size:14px;color:#111827;">{{ $data['ngay_bat_dau'] }} — {{ $data['ngay_ket_thuc'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#6b7280;display:inline-block;width:120px;">📌 Trạng thái:</span>
                                            <span style="font-size:14px;color:#1d4ed8;font-weight:600;">{{ $data['trang_thai_hien_tai'] ?? 'Tiếp tục diễn ra' }}</span>
                                        </td>
                                    </tr>
                                    @if(!empty($data['ly_do']))
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#6b7280;display:inline-block;width:120px;">💬 Phản hồi:</span>
                                            <span style="font-size:14px;color:#1e3a8a;">{{ $data['ly_do'] }}</span>
                                        </td>
                                    </tr>
                                    @endif
                                </table>
                            </div>

                            <div style="border-left:3px solid #2563eb;padding:12px 16px;background:#eff6ff;border-radius:0 8px 8px 0;">
                                <p style="font-size:13px;color:#1e3a8a;margin:0;line-height:20px;">
                                    Bạn vẫn nằm trong danh sách tham gia chiến dịch. Hãy tiếp tục theo dõi các cập nhật mới nhất từ hệ thống.
                                </p>
                            </div>

                            <div style="text-align:center;margin:32px 0 0;">
                                <a href="{{ $data['link_chien_dich'] ?? '#' }}" target="_blank"
                                    style="display:inline-block;padding:14px 36px;background:linear-gradient(135deg,#2563eb,#1d4ed8);color:#ffffff;font-weight:700;font-size:15px;border-radius:12px;text-decoration:none;box-shadow:0 4px 16px rgba(37,99,235,0.3);letter-spacing:0.3px;">
                                    Xem danh sách chiến dịch
                                </a>
                            </div>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
