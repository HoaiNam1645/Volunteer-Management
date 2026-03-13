<!DOCTYPE html>
<html lang="vi" style="padding:0;Margin:0">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="x-apple-disable-message-reformatting">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Xác thực email</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>

<body style="margin:0;padding:0;background-color:#f0fdf4;font-family:'Inter','Helvetica Neue',Helvetica,Arial,sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f0fdf4;">
        <tr>
            <td align="center" style="padding:40px 16px;">

                <!-- Wrapper -->
                <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;border-radius:16px;box-shadow:0 8px 32px rgba(16,185,129,0.10);overflow:hidden;max-width:600px;width:100%;">

                    <!-- Header Gradient -->
                    <tr>
                        <td align="center" style="background:linear-gradient(135deg,#10B981,#059669);padding:40px 30px 30px;">
                            <div style="width:64px;height:64px;background:rgba(255,255,255,0.2);border-radius:50%;display:inline-block;line-height:64px;text-align:center;">
                                <span style="font-size:32px;">✉️</span>
                            </div>
                            <h1 style="font-size:24px;line-height:32px;color:#ffffff;margin:16px 0 0;font-weight:700;letter-spacing:-0.5px;">
                                Xác Thực Email Của Bạn
                            </h1>
                            <p style="font-size:14px;color:rgba(255,255,255,0.85);margin:8px 0 0;line-height:20px;">
                                Chỉ còn một bước nữa để hoàn tất đăng ký
                            </p>
                        </td>
                    </tr>

                    <!-- Body -->
                    <tr>
                        <td style="padding:32px 36px;">
                            <p style="font-size:16px;color:#374151;line-height:26px;margin:0 0 8px;">
                                Xin chào <strong style="color:#059669;">{{ $data['ho_ten'] }}</strong>,
                            </p>
                            <p style="font-size:15px;color:#6B7280;line-height:24px;margin:0 0 24px;">
                                Cảm ơn bạn đã đăng ký tài khoản tại <strong>VolunteerHub</strong>.
                                Để hoàn tất quá trình đăng ký và bắt đầu hành trình tình nguyện,
                                vui lòng nhấn nút bên dưới để xác thực email:
                            </p>

                            <!-- CTA Button -->
                            <div style="text-align:center;margin:32px 0;">
                                <a href="{{ $data['link'] }}" target="_blank"
                                    style="display:inline-block;padding:16px 40px;background:linear-gradient(135deg,#10B981,#059669);
                         color:#ffffff;font-weight:700;font-size:16px;border-radius:12px;text-decoration:none;
                         box-shadow:0 4px 16px rgba(16,185,129,0.3);letter-spacing:0.3px;">
                                    ✅ XÁC THỰC EMAIL
                                </a>
                            </div>

                            <!-- Fallback link -->
                            <div style="background:#f0fdf4;border-radius:8px;padding:16px;margin:0 0 24px;">
                                <p style="font-size:13px;color:#6B7280;line-height:20px;margin:0 0 8px;">
                                    Nếu nút trên không hoạt động, hãy copy đường dẫn sau và dán vào trình duyệt:
                                </p>
                                <p style="font-size:13px;word-break:break-all;margin:0;">
                                    <a href="{{ $data['link'] }}" style="color:#059669;text-decoration:none;">{{ $data['link'] }}</a>
                                </p>
                            </div>

                            <!-- Warning -->
                            <div style="border-left:3px solid #F59E0B;padding:12px 16px;background:#FFFBEB;border-radius:0 8px 8px 0;">
                                <p style="font-size:13px;color:#92400E;margin:0;line-height:20px;">
                                    ⏰ <strong>Lưu ý:</strong> Liên kết xác thực sẽ hết hạn sau <strong>1 giờ</strong>.
                                </p>
                            </div>
                        </td>
                    </tr>

                    <!-- Divider -->
                    <tr>
                        <td style="padding:0 36px;">
                            <div style="border-top:1px solid #E5E7EB;"></div>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="padding:24px 36px 32px;text-align:center;">
                            <p style="margin:0;font-size:14px;color:#6B7280;line-height:22px;">Trân trọng,</p>
                            <p style="margin:4px 0 0;font-size:15px;font-weight:700;color:#059669;">Đội ngũ VolunteerHub 💚</p>
                            <p style="margin:16px 0 0;font-size:12px;color:#9CA3AF;line-height:18px;">
                                Nếu bạn không đăng ký tài khoản này, vui lòng bỏ qua email này.
                            </p>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>

</html>