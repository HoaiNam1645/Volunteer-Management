# Login/Logout với HttpOnly Cookie

- Khi đăng nhập thành công, backend tạo JWT token.
- Token được set vào cookie `token` với `HttpOnly=true`.
- `HttpOnly` nghĩa là JavaScript phía frontend không đọc được cookie này.
- Trình duyệt tự động gửi cookie kèm theo các request phù hợp.
- Backend đọc token từ cookie để xác thực người dùng.

- Cơ chế này giảm nguy cơ lộ token qua XSS.
- Nếu frontend bị chèn script độc hại, script đó không thể đọc `document.cookie` để lấy token.
- Tuy nhiên `HttpOnly` không tự động chống CSRF, nên vẫn cần cấu hình `SameSite`, `Secure` và CORS đúng cách.

- Khi đăng xuất, backend gọi `auth('api')->logout()` để hủy phiên/token hiện tại.
- Backend đồng thời trả về cookie `forget('token')` để trình duyệt xóa cookie.
- Sau đăng xuất, request tiếp theo sẽ không còn cookie hợp lệ nên bị từ chối.

## Giải thích về đoạn mã setup cookie

```php
$cookie = cookie(
    'token',
    $token,
    config('jwt.ttl'),
    '/',
    null,
    false,
    true,
    false,
    'Lax'
);
```

Đoạn mã trên dùng để tạo cookie `token` và lưu JWT token sau khi đăng nhập thành công.

- `'token'`: Tên của cookie.
- `$token`: Giá trị của cookie, chính là JWT token.
- `config('jwt.ttl')`: Thời gian sống của cookie, tính theo phút.
- `'/'`: Cookie có hiệu lực trên toàn bộ website/API.
- `null`: Không giới hạn domain riêng, dùng domain hiện tại.
- `false` ở `secure`: Cookie chưa bắt buộc đi qua HTTPS. Ở production nên đặt `true`.
- `true` ở `httpOnly`: JavaScript phía frontend không thể đọc cookie này.
- `false` ở `raw`: Sử dụng cách xử lý cookie mặc định của Laravel.
- `'Lax'` ở `sameSite`: Giảm một phần rủi ro CSRF nhưng vẫn hỗ trợ các điều hướng thông thường.
