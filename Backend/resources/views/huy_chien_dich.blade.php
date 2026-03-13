<!DOCTYPE html>
<html lang="vi" style="padding:0;Margin:0">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="x-apple-disable-message-reformatting">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Thông báo hủy chiến dịch</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>

<body style="margin:0;padding:0;background-color:#fef2f2;font-family:'Inter','Helvetica Neue',Helvetica,Arial,sans-serif;">
    @php
    $isPending = ($data['trang_thai_huy'] ?? 'da_huy') === 'yeu_cau_huy';
    $bgGradient = $isPending ? 'linear-gradient(135deg, #F59E0B, #D97706)' : 'linear-gradient(135deg, #EF4444, #DC2626)';
    $boxBg = $isPending ? '#FFFBEB' : '#FEF2F2';
    $boxBorder = $isPending ? '#FDE68A' : '#FECACA';
    $headerStyle = "background: " . $bgGradient . "; padding:40px 30px 30px;";
    $boxStyle = "background: " . $boxBg . "; border: 1px solid " . $boxBorder . "; border-radius:12px; padding:20px; margin:0 0 24px;";
    $iconStr = $isPending ? '⚠️' : '🚫';
    $titleStr = $isPending ? 'Chiến Dịch Đang Chờ Xét Duyệt Hủy' : 'Chiến Dịch Đã Bị Hủy';
    @endphp
    <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#fef2f2;">
        <tr>
            <td align="center" style="padding:40px 16px;">

                <!-- Wrapper -->
                <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;border-radius:16px;box-shadow:0 8px 32px rgba(239,68,68,0.10);overflow:hidden;max-width:600px;width:100%;">

                    <!-- Header Gradient -->
                    <tr>
                        <td align="center" style="<?php echo $headerStyle; ?>">
                            <div style="width:64px;height:64px;background:rgba(255,255,255,0.2);border-radius:50%;display:inline-block;line-height:64px;text-align:center;">
                                <span style="font-size:32px;">{{ $iconStr }}</span>
                            </div>
                            <h1 style="font-size:24px;line-height:32px;color:#ffffff;margin:16px 0 0;font-weight:700;letter-spacing:-0.5px;">
                                {{ $titleStr }}
                            </h1>
                            <p style="font-size:14px;color:rgba(255,255,255,0.85);margin:8px 0 0;line-height:20px;">
                                Thông báo quan trọng về chiến dịch bạn đã đăng ký
                            </p>
                        </td>
                    </tr>

                    <!-- Body -->
                    <tr>
                        <td style="padding:32px 36px;">
                            <p style="font-size:16px;color:#374151;line-height:26px;margin:0 0 8px;">
                                Xin chào <strong style="color:#DC2626;">{{ $data['ho_ten'] }}</strong>,
                            </p>

                            @if($isPending)
                            <p style="font-size:15px;color:#6B7280;line-height:24px;margin:0 0 24px;">
                                Chúng tôi xin thông báo rằng kiểm duyệt viên đã gửi <strong>yêu cầu hủy</strong> chiến dịch mà bạn đã đăng ký tham gia.
                                Yêu cầu này hiện đang được <strong>Admin xét duyệt</strong>. Chúng tôi sẽ thông báo lại khi có kết quả.
                            </p>
                            @else
                            <p style="font-size:15px;color:#6B7280;line-height:24px;margin:0 0 24px;">
                                Chúng tôi rất tiếc phải thông báo rằng chiến dịch bạn đã đăng ký tham gia đã được <strong>xét duyệt hủy bỏ</strong>.
                                Đăng ký tham gia của bạn đã được hủy tự động.
                            </p>
                            @endif

                            <!-- Campaign Info Box -->
                            <div style="<?php echo $boxStyle; ?>">
                                <table width="100%" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#9CA3AF;display:inline-block;width:120px;">📋 Chiến dịch:</span>
                                            <strong style="font-size:14px;color:#374151;">{{ $data['ten_chien_dich'] }}</strong>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#9CA3AF;display:inline-block;width:120px;">📍 Địa điểm:</span>
                                            <span style="font-size:14px;color:#374151;">{{ $data['dia_diem'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#9CA3AF;display:inline-block;width:120px;">📅 Thời gian:</span>
                                            <span style="font-size:14px;color:#374151;">{{ $data['ngay_bat_dau'] }} — {{ $data['ngay_ket_thuc'] }}</span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#9CA3AF;display:inline-block;width:120px;">📌 Trạng thái:</span>
                                            @if($isPending)
                                            <span style="font-size:14px;color:#D97706;font-weight:600;">⏳ Đang chờ Admin duyệt hủy</span>
                                            @else
                                            <span style="font-size:14px;color:#DC2626;font-weight:600;">❌ Đã hủy</span>
                                            @endif
                                        </td>
                                    </tr>
                                    @if(!empty($data['ly_do']))
                                    <tr>
                                        <td style="padding:6px 0;">
                                            <span style="font-size:13px;color:#9CA3AF;display:inline-block;width:120px;">💬 Lý do:</span>
                                            <span style="font-size:14px;color:#DC2626;">{{ $data['ly_do'] }}</span>
                                        </td>
                                    </tr>
                                    @endif
                                </table>
                            </div>

                            <!-- Note / Encouragement -->
                            @if($isPending)
                            <div style="border-left:3px solid #F59E0B;padding:12px 16px;background:#FFFBEB;border-radius:0 8px 8px 0;">
                                <p style="font-size:13px;color:#92400E;margin:0;line-height:20px;">
                                    ⏰ <strong>Lưu ý:</strong> Đăng ký của bạn vẫn đang được giữ nguyên. Nếu Admin <strong>không duyệt hủy</strong>,
                                    chiến dịch sẽ tiếp tục hoạt động bình thường và bạn vẫn tham gia như dự kiến.
                                </p>
                            </div>
                            @else
                            <div style="border-left:3px solid #10B981;padding:12px 16px;background:#F0FDF4;border-radius:0 8px 8px 0;">
                                <p style="font-size:13px;color:#065F46;margin:0;line-height:20px;">
                                    💚 <strong>Đừng nản lòng!</strong> Vẫn còn rất nhiều chiến dịch tình nguyện khác đang cần sự tham gia của bạn.
                                    Hãy truy cập trang web để tìm kiếm cơ hội mới nhé!
                                </p>
                            </div>
                            @endif

                            <!-- CTA Button -->
                            <div style="text-align:center;margin:32px 0 0;">
                                <a href="{{ $data['link_chien_dich'] ?? '#' }}" target="_blank"
                                    style="display:inline-block;padding:14px 36px;background:linear-gradient(135deg,#10B981,#059669);
                                     color:#ffffff;font-weight:700;font-size:15px;border-radius:12px;text-decoration:none;
                                     box-shadow:0 4px 16px rgba(16,185,129,0.3);letter-spacing:0.3px;">
                                    🔍 Xem Chiến Dịch Khác
                                </a>
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
                                Đây là email tự động, vui lòng không trả lời email này.
                            </p>
                        </td>
                    </tr>
                </table>

            </td>
        </tr>
    </table>
</body>

</html>