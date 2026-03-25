<!DOCTYPE html>
<html lang="vi" style="padding:0;Margin:0">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Cập nhật đăng ký chiến dịch</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>
<body style="margin:0;padding:0;background-color:#f3f4f6;font-family:'Inter','Helvetica Neue',Helvetica,Arial,sans-serif;">
@php
    $loai = $data['loai'] ?? 'xac_nhan_dang_ky';
    $themes = [
        'xac_nhan_dang_ky' => ['bg' => '#EFF6FF', 'accent' => '#2563EB', 'title' => 'Đăng ký chiến dịch thành công', 'message' => 'Bạn đã đăng ký thành công. Hãy chờ chủ chiến dịch duyệt trước, sau đó xác nhận tham gia khi đã sẵn sàng.'],
        'xac_nhan_tham_gia' => ['bg' => '#ECFDF5', 'accent' => '#059669', 'title' => 'Xác nhận tham gia thành công', 'message' => 'Bạn đã xác nhận tham gia chiến dịch. Hệ thống đã ghi nhận thông tin của bạn.'],
        'huy_dang_ky' => ['bg' => '#FEF2F2', 'accent' => '#DC2626', 'title' => 'Hủy đăng ký thành công', 'message' => 'Đăng ký tham gia của bạn đã được hủy thành công.'],
        'loi_moi_tham_gia' => ['bg' => '#EEF2FF', 'accent' => '#4F46E5', 'title' => 'Thư mời xác nhận tham gia chiến dịch', 'message' => 'Bạn đang được người điều phối mời tham gia chiến dịch này. Nếu phù hợp, hãy mở chi tiết chiến dịch và xác nhận tham gia để hệ thống ghi nhận chính thức.'],
        'nhac_xac_nhan_tham_gia' => ['bg' => '#FFF7ED', 'accent' => '#EA580C', 'title' => 'Nhắc nhở xác nhận tham gia', 'message' => 'Chiến dịch sắp bắt đầu trong 72 giờ tới. Nếu bạn vẫn tham gia, hãy xác nhận để ban tổ chức chủ động nhân sự.'],
        'nhac_chu_chien_dich_sap_bat_dau' => ['bg' => '#EEF2FF', 'accent' => '#4F46E5', 'title' => 'Nhắc nhở chiến dịch sắp bắt đầu', 'message' => 'Chiến dịch của bạn sắp bắt đầu trong vòng 72 giờ tới. Hãy kiểm tra lại nhân sự, địa điểm và các đầu việc cần chuẩn bị.'],
    ];
    $theme = $themes[$loai] ?? $themes['xac_nhan_dang_ky'];
@endphp
<table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f3f4f6;">
    <tr>
        <td align="center" style="padding:32px 16px;">
            <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;border-radius:16px;overflow:hidden;max-width:600px;width:100%;box-shadow:0 12px 32px rgba(15,23,42,0.08);">
                <tr>
                    <td style="padding:32px;background:{{ $theme['bg'] }};border-bottom:1px solid #E5E7EB;">
                        <h1 style="margin:0;font-size:24px;line-height:32px;color:{{ $theme['accent'] }};font-weight:700;">{{ $theme['title'] }}</h1>
                        <p style="margin:8px 0 0;font-size:14px;line-height:22px;color:#4B5563;">Cập nhật mới nhất từ hệ thống tình nguyện</p>
                    </td>
                </tr>
                <tr>
                    <td style="padding:28px 32px;">
                        <p style="margin:0 0 16px;font-size:15px;line-height:24px;color:#374151;">Xin chào <strong>{{ $data['ho_ten'] ?? 'bạn' }}</strong>,</p>
                        <p style="margin:0 0 20px;font-size:15px;line-height:24px;color:#4B5563;">{{ $theme['message'] }}</p>

                        @if(($data['loai'] ?? '') === 'loi_moi_tham_gia')
                        <div style="background:#EEF2FF;border-left:4px solid #4F46E5;border-radius:8px;padding:14px 16px;margin-bottom:20px;">
                            <p style="margin:0 0 6px;font-size:13px;font-weight:600;color:#3730A3;">Người gửi lời mời</p>
                            <p style="margin:0;font-size:14px;line-height:22px;color:#312E81;">{{ $data['nguoi_moi'] ?? 'Ban điều phối chiến dịch' }}</p>
                        </div>
                        @endif

                        <div style="background:#F9FAFB;border:1px solid #E5E7EB;border-radius:12px;padding:18px 20px;margin-bottom:20px;">
                            <p style="margin:0 0 10px;font-size:14px;color:#6B7280;">Chiến dịch</p>
                            <p style="margin:0 0 10px;font-size:18px;font-weight:700;color:#111827;">{{ $data['ten_chien_dich'] ?? '' }}</p>
                            <p style="margin:0 0 6px;font-size:14px;color:#374151;">Địa điểm: {{ $data['dia_diem'] ?? '—' }}</p>
                            <p style="margin:0 0 6px;font-size:14px;color:#374151;">Thời gian: {{ $data['ngay_bat_dau'] ?? '—' }} — {{ $data['ngay_ket_thuc'] ?? '—' }}</p>
                            @if(!empty($data['han_dang_ky']))
                            <p style="margin:0;font-size:14px;color:#374151;">Hạn đăng ký: <strong>{{ $data['han_dang_ky'] }}</strong></p>
                            @endif
                        </div>

                        @if(!empty($data['ly_do_huy']))
                        <div style="background:#FFF7ED;border-left:4px solid #F97316;border-radius:8px;padding:14px 16px;margin-bottom:20px;">
                            <p style="margin:0 0 6px;font-size:13px;font-weight:600;color:#9A3412;">Lý do hủy đăng ký</p>
                            <p style="margin:0;font-size:14px;line-height:22px;color:#7C2D12;">{{ $data['ly_do_huy'] }}</p>
                        </div>
                        @endif

                        <div style="text-align:center;margin-top:28px;">
                            <a href="{{ $data['link_chien_dich'] ?? '#' }}" style="display:inline-block;padding:14px 28px;background:{{ $theme['accent'] }};color:#ffffff;text-decoration:none;border-radius:10px;font-size:15px;font-weight:700;">Xem chi tiết chiến dịch</a>
                        </div>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
