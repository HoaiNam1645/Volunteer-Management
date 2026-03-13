<!DOCTYPE html>
<html lang="vi" style="padding:0;Margin:0">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="x-apple-disable-message-reformatting">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Đặt lại mật khẩu</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>

<body style="margin:0;padding:0;background-color:#EEF2FF;font-family:'Inter','Helvetica Neue',Helvetica,Arial,sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#EEF2FF;">
        <tr>
            <td align="center" style="padding:40px 16px;">

                <!-- Wrapper -->
                <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;border-radius:16px;box-shadow:0 8px 32px rgba(99,102,241,0.12);overflow:hidden;max-width:600px;width:100%;">

                    <!-- Header Gradient -->
                    <tr>
                        <td align="center" style="background:linear-gradient(135deg,#6366F1,#8B5CF6,#A855F7);padding:40px 30px 30px;">
                            <div style="width:72px;height:72px;background:rgba(255,255,255,0.15);border-radius:50%;display:inline-block;line-height:72px;text-align:center;backdrop-filter:blur(10px);">
                                <span style="font-size:36px;">🔐</span>
                            </div>
                            <h1 style="font-size:24px;line-height:32px;color:#ffffff;margin:16px 0 0;font-weight:700;letter-spacing:-0.5px;">
                                Đặt Lại Mật Khẩu
                            </h1>
                            <p style="font-size:14px;color:rgba(255,255,255,0.85);margin:8px 0 0;line-height:20px;">
                                Yêu cầu đặt lại mật khẩu cho tài khoản của bạn
                            </p>
                        </td>
                    </tr>

                    <!-- Body -->
                    <tr>
                        <td style="padding:32px 36px;">
                            <p style="font-size:16px;color:#374151;line-height:26px;margin:0 0 8px;">
                                Xin chào <strong style="color:#6366F1;">{{ $data['ho_ten'] }}</strong>,
                            </p>
                            <p style="font-size:15px;color:#6B7280;line-height:24px;margin:0 0 16px;">
                                Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản
                                <strong>VolunteerHub</strong> của bạn. Nhấn nút bên dưới để tạo mật khẩu mới:
                            </p>

                            <!-- Security Info Box -->
                            <div style="background:linear-gradient(135deg,#EEF2FF,#E0E7FF);border-radius:12px;padding:20px;margin:0 0 24px;">
                                <table cellpadding="0" cellspacing="0" width="100%">
                                    <tr>
                                        <td width="36" valign="top">
                                            <span style="font-size:20px;">📧</span>
                                        </td>
                                        <td style="padding-left:12px;">
                                            <p style="margin:0;font-size:13px;color:#4338CA;font-weight:600;">Email yêu cầu</p>
                                            <p style="margin:4px 0 0;font-size:14px;color:#6366F1;">{{ $data['email'] }}</p>
                                        </td>
                                    </tr>
                                </table>
                            </div>

                            <!-- CTA Button -->
                            <div style="text-align:center;margin:32px 0;">
                                <a href="{{ $data['link'] }}" target="_blank"
                                    style="display:inline-block;padding:16px 48px;
                         background:linear-gradient(135deg,#6366F1,#8B5CF6);
                         color:#ffffff;font-weight:700;font-size:16px;border-radius:12px;text-decoration:none;
                         box-shadow:0 6px 20px rgba(99,102,241,0.35);letter-spacing:0.3px;">
                                    🔑 ĐẶT LẠI MẬT KHẨU
                                </a>
                            </div>

                            <!-- Fallback link -->
                            <div style="background:#F5F3FF;border-radius:8px;padding:16px;margin:0 0 24px;">
                                <p style="font-size:13px;color:#6B7280;line-height:20px;margin:0 0 8px;">
                                    Nếu nút trên không hoạt động, hãy copy đường dẫn sau và dán vào trình duyệt:
                                </p>
                                <p style="font-size:13px;word-break:break-all;margin:0;">
                                    <a href="{{ $data['link'] }}" style="color:#6366F1;text-decoration:none;">{{ $data['link'] }}</a>
                                </p>
                            </div>

                            <!-- Warning -->
                            <div style="border-left:3px solid #EF4444;padding:12px 16px;background:#FEF2F2;border-radius:0 8px 8px 0;margin:0 0 24px;">
                                <p style="font-size:13px;color:#991B1B;margin:0;line-height:20px;">
                                    ⏰ <strong>Quan trọng:</strong> Liên kết đặt lại mật khẩu sẽ hết hạn sau <strong>1 giờ</strong>.
                                    Sau thời gian này bạn cần gửi yêu cầu mới.
                                </p>
                            </div>

                            <!-- Security Tips -->
                            <div style="background:#F9FAFB;border-radius:12px;padding:20px;">
                                <p style="margin:0 0 12px;font-size:14px;font-weight:600;color:#374151;">🛡️ Mẹo bảo mật:</p>
                                <table cellpadding="0" cellspacing="0" width="100%">
                                    <tr>
                                        <td style="padding:4px 0;">
                                            <p style="margin:0;font-size:13px;color:#6B7280;line-height:20px;">
                                                • Sử dụng mật khẩu mạnh (ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số)
                                            </p>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding:4px 0;">
                                            <p style="margin:0;font-size:13px;color:#6B7280;line-height:20px;">
                                                • Không sử dụng mật khẩu giống với các tài khoản khác
                                            </p>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding:4px 0;">
                                            <p style="margin:0;font-size:13px;color:#6B7280;line-height:20px;">
                                                • Không chia sẻ mật khẩu với bất kỳ ai
                                            </p>
                                        </td>
                                    </tr>
                                </table>
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
                            <p style="margin:4px 0 0;font-size:15px;font-weight:700;color:#6366F1;">Đội ngũ VolunteerHub 💜</p>
                            <p style="margin:16px 0 0;font-size:12px;color:#9CA3AF;line-height:18px;">
                                Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.
                                Tài khoản của bạn vẫn an toàn.
                            </p>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>

</html>