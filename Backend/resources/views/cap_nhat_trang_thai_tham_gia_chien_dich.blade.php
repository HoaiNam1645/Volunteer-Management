<!DOCTYPE html>
<html lang="vi" style="padding:0;Margin:0">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Cập nhật trạng thái tham gia chiến dịch</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>
<body style="margin:0;padding:0;background-color:#f3f4f6;font-family:'Inter','Helvetica Neue',Helvetica,Arial,sans-serif;">
@php
    $loai = $data['loai'] ?? 'chien_dich_bat_dau';
    $themes = [
        'chien_dich_bat_dau' => [
            'bg' => '#ECFDF5',
            'accent' => '#059669',
            'title' => 'Chiến dịch đã bắt đầu',
            'message' => 'Chiến dịch bạn đã xác nhận tham gia hiện chính thức bắt đầu.',
            'cta' => 'Xem chi tiết chiến dịch',
        ],
        'tu_dong_tu_choi_do_chua_xac_nhan' => [
            'bg' => '#FEF2F2',
            'accent' => '#DC2626',
            'title' => 'Đăng ký tham gia không còn hiệu lực',
            'message' => 'Bạn chưa xác nhận tham gia trước thời điểm bắt đầu, nên đăng ký đã được đóng lại.',
            'cta' => 'Xem chiến dịch',
        ],
        'chien_dich_hoan_thanh' => [
            'bg' => '#EFF6FF',
            'accent' => '#2563EB',
            'title' => 'Chiến dịch đã hoàn thành',
            'message' => 'Chiến dịch bạn tham gia đã kết thúc. Cảm ơn bạn đã đồng hành.',
            'cta' => 'Xem lại chiến dịch',
        ],
    ];
    $theme = $themes[$loai] ?? $themes['chien_dich_bat_dau'];
@endphp
<table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background:#f3f4f6;">
    <tr>
        <td align="center" style="padding:32px 16px;">
            <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background:#ffffff;border-radius:16px;overflow:hidden;max-width:600px;width:100%;box-shadow:0 12px 32px rgba(15,23,42,0.08);">
                <tr>
                    <td style="padding:32px;background:{{ $theme['bg'] }};border-bottom:1px solid #E5E7EB;">
                        <h1 style="margin:0;font-size:24px;line-height:32px;color:{{ $theme['accent'] }};font-weight:700;">{{ $theme['title'] }}</h1>
                        <p style="margin:8px 0 0;font-size:14px;line-height:22px;color:#4B5563;">Thông báo liên quan đến trạng thái tham gia chiến dịch</p>
                    </td>
                </tr>
                <tr>
                    <td style="padding:28px 32px;">
                        <p style="margin:0 0 16px;font-size:15px;line-height:24px;color:#374151;">Xin chào <strong>{{ $data['ho_ten'] ?? 'bạn' }}</strong>,</p>
                        <p style="margin:0 0 20px;font-size:15px;line-height:24px;color:#4B5563;">{{ $theme['message'] }}</p>

                        <div style="background:#F9FAFB;border:1px solid #E5E7EB;border-radius:12px;padding:18px 20px;margin-bottom:20px;">
                            <p style="margin:0 0 10px;font-size:14px;color:#6B7280;">Chiến dịch</p>
                            <p style="margin:0 0 10px;font-size:18px;font-weight:700;color:#111827;">{{ $data['ten_chien_dich'] ?? '' }}</p>
                            <p style="margin:0 0 6px;font-size:14px;color:#374151;">Địa điểm: {{ $data['dia_diem'] ?? '—' }}</p>
                            <p style="margin:0 0 6px;font-size:14px;color:#374151;">Thời gian: {{ $data['ngay_bat_dau'] ?? '—' }} — {{ $data['ngay_ket_thuc'] ?? '—' }}</p>
                            @if(!empty($data['ghi_chu']))
                            <p style="margin:0;font-size:14px;color:#374151;">Ghi chú: {{ $data['ghi_chu'] }}</p>
                            @endif
                        </div>

                        <div style="text-align:center;margin-top:28px;">
                            <a href="{{ $data['link_chien_dich'] ?? '#' }}" style="display:inline-block;padding:14px 28px;background:{{ $theme['accent'] }};color:#ffffff;text-decoration:none;border-radius:10px;font-size:15px;font-weight:700;">{{ $theme['cta'] }}</a>
                        </div>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
