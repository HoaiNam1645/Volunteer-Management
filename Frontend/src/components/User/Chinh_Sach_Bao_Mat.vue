<template>
	<div class="privacy-page py-5">
		<div class="container">
			<div class="row justify-content-center">
				<div class="col-lg-10">
					<div class="card border-0 shadow-sm rounded-4 overflow-hidden">
						<!-- Header -->
						<div class="bg-success bg-gradient p-5 text-center text-white">
							<div class="mb-3">
								<i class="fa-solid fa-shield-halved" style="font-size: 4rem; opacity: 0.9;"></i>
							</div>
							<h1 class="display-5 fw-bold mb-2">Chính sách bảo mật</h1>
							<p class="fs-5 opacity-75 mb-0">Cập nhật lần cuối: {{ currentDate }}</p>
						</div>

						<!-- Content -->
						<div class="card-body p-5">
							<div class="content-wrapper">
								<h3 class="fw-bold mb-4 text-success">1. Mục đích thu thập thông tin</h3>
								<p class="text-muted lh-lg mb-4">
									<strong>VMS-AI</strong> thu thập thông tin cá nhân của người dùng (bao gồm Họ tên, Số điện thoại, Email, Địa chỉ, Kỹ năng) nhằm mục đích:
								</p>
								<ul class="text-muted lh-lg mb-4">
									<li>Quản lý hồ sơ Tình nguyện viên và Kiểm duyệt viên.</li>
									<li>Gợi ý các chiến dịch tình nguyện phù hợp với năng lực và vị trí thông qua hệ thống AI.</li>
									<li>Liên hệ, gửi thông báo và điều phối trong các hoạt động tình nguyện.</li>
									<li>Phân tích dữ liệu ẩn danh để cải thiện chất lượng dịch vụ của nền tảng.</li>
								</ul>

								<h3 class="fw-bold mb-4 text-success">2. Bảo vệ và Lưu trữ dữ liệu</h3>
								<p class="text-muted lh-lg mb-4">
									Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn bằng các biện pháp an ninh mạng tiên tiến nhất:
								</p>
								<ul class="text-muted lh-lg mb-4">
									<li>Mật khẩu được mã hóa an toàn (Hashing) trước khi lưu vào cơ sở dữ liệu.</li>
									<li>Sử dụng giao thức HTTPS để mã hóa dữ liệu truyền tải trên mạng.</li>
									<li>Truy cập vào dữ liệu cá nhân bị hạn chế nghiêm ngặt, chỉ dành cho những nhân sự có thẩm quyền (Admin, Kiểm duyệt viên của chiến dịch bạn tham gia).</li>
								</ul>

								<h3 class="fw-bold mb-4 text-success">3. Chia sẻ thông tin</h3>
								<p class="text-muted lh-lg mb-4">
									Chúng tôi <strong>KHÔNG</strong> bán, trao đổi hoặc cho thuê thông tin cá nhân của bạn cho bên thứ ba. Thông tin của bạn chỉ được chia sẻ trong các trường hợp sau:
								</p>
								<ul class="text-muted lh-lg mb-4">
									<li>Với các Kiểm duyệt viên tổ chức chiến dịch mà bạn đăng ký tham gia (để phục vụ mục đích quản lý và liên lạc).</li>
									<li>Khi có yêu cầu hợp pháp từ cơ quan nhà nước có thẩm quyền.</li>
								</ul>

								<h3 class="fw-bold mb-4 text-success">4. Quyền lợi của bạn</h3>
								<p class="text-muted lh-lg mb-4">
									Bạn có toàn quyền kiểm soát dữ liệu cá nhân của mình, bao gồm:
								</p>
								<ul class="text-muted lh-lg mb-4">
									<li>Quyền truy cập và yêu cầu trích xuất dữ liệu cá nhân đang được lưu trữ.</li>
									<li>Quyền chỉnh sửa, cập nhật khi có sai sót về thông tin.</li>
									<li>Quyền yêu cầu xóa tài khoản và toàn bộ dữ liệu liên quan khỏi hệ thống VMS-AI.</li>
								</ul>

								<h3 class="fw-bold mb-4 text-success">5. Liên hệ</h3>
								<p class="text-muted lh-lg mb-0">
									Mọi thắc mắc về Chính sách bảo mật hoặc yêu cầu xử lý dữ liệu cá nhân, vui lòng liên hệ hệ thống qua email: <strong>contact@vms-ai.vn</strong>.
								</p>
							</div>

							<hr class="my-5">

							<div class="d-flex justify-content-between align-items-center">
								<router-link to="/dang-ky" class="btn btn-outline-success px-4 py-2 rounded-pill fw-medium">
									<i class="fa-solid fa-arrow-left me-2"></i>Quay lại trang Đăng ký
								</router-link>
								<router-link to="/" class="btn btn-link text-decoration-none text-muted">Về Trang chủ</router-link>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
export default {
	name: 'TrangChinhSachBaoMat',
	data() {
		return {
			currentDate: new Date().toLocaleDateString('vi-VN')
		}
	}
}
</script>

<style scoped>
.privacy-page {
	background-color: #f8f9fa;
	min-height: calc(100vh - 80px);
}

h3 {
	position: relative;
	padding-bottom: 10px;
}

h3::after {
	content: '';
	position: absolute;
	left: 0;
	bottom: 0;
	width: 40px;
	height: 3px;
	background-color: #198754; /* Success color */
	border-radius: 2px;
}

.content-wrapper p, .content-wrapper ul {
	font-size: 1.05rem;
}

.content-wrapper li {
	margin-bottom: 8px;
}
</style>
