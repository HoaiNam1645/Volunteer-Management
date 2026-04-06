# Permission Backend Flow

## 1. Permission là gì trong dự án này

Hiểu đơn giản:

- `vai_tro` = bạn là ai
- `permission` = bạn được làm gì

Ví dụ:

- `tinh_nguyen_vien` là vai trò
- `feedback_tracking.manage` là quyền

Nghĩa là một tài khoản có thể là `tinh_nguyen_vien`, nhưng chỉ làm được một số chức năng nếu có đúng permission.

## 2. Permission được khai báo ở đâu

File chính là [PermissionRegistry.php](/Users/admin/Volunteer-Management/Backend/app/Support/PermissionRegistry.php).

Trong file này có 2 phần quan trọng:

- `GROUPS`: danh sách toàn bộ quyền của hệ thống
- `ROLE_DEFAULTS`: bộ quyền mặc định theo từng vai trò

Nói ngắn gọn:

- muốn thêm quyền mới thì thêm ở đây trước
- muốn vai trò nào có quyền đó mặc định thì thêm tiếp vào `ROLE_DEFAULTS`

## 3. Quyền của user được lưu ở đâu

Quyền nằm trong cột `quyen_han` của bảng `nguoi_dungs`.

Model xử lý là [NguoiDung.php](/Users/admin/Volunteer-Management/Backend/app/Models/NguoiDung.php).

Điểm rất quan trọng:

- nếu `quyen_han = null` thì không phải là “không có quyền”
- mà là “dùng bộ quyền mặc định theo vai trò”

Ví dụ:

- user có vai trò `quan_tri_vien`
- `quyen_han = null`
- backend sẽ tự hiểu user này đang dùng toàn bộ quyền mặc định của `quan_tri_vien`

## 4. Backend lấy quyền thật của user như thế nào

Trong [NguoiDung.php](/Users/admin/Volunteer-Management/Backend/app/Models/NguoiDung.php) có 3 hàm cần nhớ:

- `dangDungQuyenMacDinh()`
- `layTatCaQuyen()`
- `coQuyen()`

### `dangDungQuyenMacDinh()`

Hàm này chỉ kiểm tra:

- `quyen_han` trong DB có đang là `null` không

Nếu là `null` thì user đang dùng quyền mặc định.

### `layTatCaQuyen()`

Đây là hàm quan trọng nhất.

Nó hoạt động như sau:

1. Nếu user đang dùng mặc định:
   - lấy quyền từ `ROLE_DEFAULTS`
2. Nếu user đang dùng custom:
   - lấy quyền từ cột `quyen_han`
3. Sau đó lọc lại bằng `PermissionRegistry::normalize(...)`

Kết quả cuối cùng của hàm này là:

- bộ quyền thật sự backend dùng để kiểm tra

### `coQuyen()`

Hàm này chỉ làm một việc:

- kiểm tra xem một quyền cụ thể có nằm trong `layTatCaQuyen()` không

Ví dụ:

- `coQuyen('account_center.view')`

## 5. Permission đi ra frontend như thế nào

Khi đăng nhập thành công, [XacThucController.php](/Users/admin/Volunteer-Management/Backend/app/Http/Controllers/XacThucController.php) trả về:

- `vai_tro`
- `quyen_han`
- `permissions`
- `su_dung_mac_dinh`

`quyen_han` và `permissions` đều lấy từ `layTatCaQuyen()`.

Nghĩa là frontend luôn nhận:

- quyền đang có hiệu lực thật

Ngoài ra trong JWT, model [NguoiDung.php](/Users/admin/Volunteer-Management/Backend/app/Models/NguoiDung.php) cũng nhúng thêm:

- `vai_tro`
- `quyen_han`

## 6. Middleware permission được đăng ký ở đâu

Trong [app.php](/Users/admin/Volunteer-Management/Backend/bootstrap/app.php), project đăng ký alias middleware:

- `tinhNguyenVien`
- `kiemDuyetVien`
- `quanTriVien`
- `permission`

Nghĩa là route có thể viết như sau:

```php
Route::middleware('permission:account_center.view')
```

## 7. `permission:account_center.view` nghĩa là gì

Ví dụ này nên hiểu như sau:

- `permission` là tên middleware
- `account_center.view` là tham số truyền vào middleware đó

Khi request chạy vào route:

1. Laravel gọi middleware `permission`
2. Middleware nhận chuỗi `account_center.view`
3. Middleware hỏi user hiện tại:
   - “bạn có quyền này không?”
4. Nếu có thì cho qua
5. Nếu không có thì trả `403`

## 8. Nếu route có nhiều permission thì sao

Ví dụ:

```php
Route::middleware('permission:volunteer_campaigns.view,campaign_coordination.view')
```

Trong project hiện tại, middleware check theo kiểu OR.

Nghĩa là:

- có `volunteer_campaigns.view` là qua
- hoặc có `campaign_coordination.view` là qua

Không cần phải có cả hai.

## 9. Middleware permission chạy ở file nào

File là [PermissionMiddleware.php](/Users/admin/Volunteer-Management/Backend/app/Http/Middleware/PermissionMiddleware.php).

Luồng chạy rất đơn giản:

1. Lấy user từ `auth('api')->user()`
2. Nếu không có user:
   - trả `401`
3. Nếu route không truyền permission:
   - cho qua
4. Nếu có truyền permission:
   - gọi `coQuyen(...)`
5. Nếu có ít nhất 1 quyền khớp:
   - cho qua
6. Nếu không khớp:
   - trả `403`

## 10. Middleware vai trò khác gì middleware permission

Project này đang dùng 2 lớp kiểm tra:

- middleware vai trò
- middleware permission

Ví dụ:

- `TinhNguyenVienMiddleware` kiểm tra user có phải `tinh_nguyen_vien` không
- `PermissionMiddleware` kiểm tra user có quyền cụ thể không

Nghĩa là backend thường chặn theo 2 tầng:

1. đúng nhóm người dùng
2. đúng chức năng

## 11. Request đi qua route như thế nào

Ví dụ một route trong [api.php](/Users/admin/Volunteer-Management/Backend/routes/api.php):

```php
Route::middleware(['auth:api', 'tinhNguyenVien'])->group(function () {
    Route::middleware('permission:account_center.view')->group(function () {
        Route::get('/nguoi-dung/thong-tin', ...);
    });
});
```

Request sẽ đi theo thứ tự:

1. `auth:api`
2. `tinhNguyenVien`
3. `permission:account_center.view`
4. controller

Nếu rớt ở đâu thì dừng ở đó.

## 12. Khi nào trả 401, 403, 422

- `401`: chưa đăng nhập hoặc token sai
- `403`: đúng token nhưng sai vai trò hoặc thiếu permission
- `422`: dữ liệu gửi lên không hợp lệ, hoặc thao tác cập nhật quyền bị backend chặn

## 13. Admin tạo user thì quyền được gán thế nào

Trong [NguoiDungController.php](/Users/admin/Volunteer-Management/Backend/app/Http/Controllers/NguoiDungController.php):

- `taoQuanLy()` tạo user mới với `quyen_han = null`

Ý nghĩa:

- user mới dùng bộ quyền mặc định theo vai trò luôn

## 14. Admin đổi vai trò user thì chuyện gì xảy ra

Trong `capNhatQuanLy()`:

- nếu đổi `vai_tro`
- backend sẽ reset `quyen_han = null`

Ý nghĩa:

- user sẽ quay về bộ quyền mặc định của vai trò mới
- tránh giữ lại quyền cũ không còn phù hợp

## 15. Admin sửa permission riêng cho user thế nào

Trong [NguoiDungController.php](/Users/admin/Volunteer-Management/Backend/app/Http/Controllers/NguoiDungController.php), hàm `capNhatPhanQuyen()` xử lý việc này.

Luồng dễ hiểu như sau:

1. Xác định đang sửa scope `admin` hay `user`
2. Validate danh sách permission FE gửi lên
3. Nếu chọn “dùng mặc định”:
   - lấy bộ quyền mặc định theo role trong scope đó
4. Nếu chọn “tùy chỉnh”:
   - lấy danh sách FE gửi lên
   - lọc lại cho đúng scope
5. Giữ nguyên các quyền ngoài scope đang sửa
6. Gộp lại và normalize
7. Nếu bộ quyền mới trùng hoàn toàn với default theo role:
   - lưu `quyen_han = null`
8. Nếu khác:
   - lưu mảng quyền thật vào DB

## 16. Tại sao backend phải giữ quyền ngoài scope

Ví dụ:

- bạn đang sửa scope `user`
- user đó đang có một số quyền `admin`

Khi lưu lại, backend không xóa nhầm quyền `admin`.

Nó chỉ thay phần quyền trong scope đang sửa, còn phần ngoài scope thì giữ nguyên.

## 17. Có cơ chế chống tự khóa hệ thống không

Có.

Trong [NguoiDungController.php](/Users/admin/Volunteer-Management/Backend/app/Http/Controllers/NguoiDungController.php) có hàm `assertSystemPermissionCoverage()`.

Hàm này đảm bảo:

- hệ thống luôn còn ít nhất 1 tài khoản active có quyền `permission_management.manage`

Nếu một thao tác làm mất toàn bộ tài khoản giữ quyền này:

- backend chặn lại bằng `422`

## 18. Cách hiểu nhanh toàn bộ flow

Bạn có thể nhớ theo câu này:

- quyền được khai báo trong `PermissionRegistry`
- user có quyền hiệu lực qua `layTatCaQuyen()`
- route dùng middleware `permission:...` để hỏi “user có quyền này không?”
- admin có thể sửa quyền riêng, nhưng backend luôn lọc và bảo vệ để hệ thống không bị hỏng

## 19. File nên đọc khi cần debug permission

- [PermissionRegistry.php](/Users/admin/Volunteer-Management/Backend/app/Support/PermissionRegistry.php)
- [NguoiDung.php](/Users/admin/Volunteer-Management/Backend/app/Models/NguoiDung.php)
- [PermissionMiddleware.php](/Users/admin/Volunteer-Management/Backend/app/Http/Middleware/PermissionMiddleware.php)
- [NguoiDungController.php](/Users/admin/Volunteer-Management/Backend/app/Http/Controllers/NguoiDungController.php)
- [XacThucController.php](/Users/admin/Volunteer-Management/Backend/app/Http/Controllers/XacThucController.php)
- [api.php](/Users/admin/Volunteer-Management/Backend/routes/api.php)
- [app.php](/Users/admin/Volunteer-Management/Backend/bootstrap/app.php)
