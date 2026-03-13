<template>
	<div class="terms-page py-5">
		<div class="container">
			<div class="row justify-content-center">
				<div class="col-lg-10">
					<div class="card border-0 shadow-sm rounded-4 overflow-hidden">
						<!-- Header -->
						<div class="bg-primary bg-gradient p-5 text-center text-white">
							<div class="mb-3">
								<i class="fa-solid fa-file-contract" style="font-size: 4rem; opacity: 0.9;"></i>
							</div>
							<h1 class="display-5 fw-bold mb-2">Điều khoản sử dụng</h1>
							<p class="fs-5 opacity-75 mb-0">Cập nhật lần cuối: {{ currentDate }}</p>
						</div>

						<!-- Content -->
						<div class="card-body p-5">
							<div class="content-wrapper">
								<h3 class="fw-bold mb-4 text-primary">1. Giới thiệu</h3>
								<p class="text-muted lh-lg mb-4">
									Chào mừng bạn đến với <strong>VMS-AI</strong>. Bằng việc truy cập và sử dụng nền tảng của chúng tôi, bạn đồng ý tuân thủ các Điều khoản sử dụng này. Vui lòng đọc kỹ trước khi sử dụng dịch vụ.
								</p>

								<h3 class="fw-bold mb-4 text-primary">2. Tài khoản người dùng</h3>
								<ul class="text-muted lh-lg mb-4">
									<li>Bạn phải cung cấp thông tin chính xác, đầy đủ khi đăng ký tài khoản.</li>
									<li>Bạn chịu trách nhiệm bảo mật thông tin đăng nhập của mình.</li>
									<li>Không được chia sẻ tài khoản hoặc sử dụng tài khoản của người khác.</li>
									<li>Ban quản trị có quyền đình chỉ hoặc xóa tài khoản nếu phát hiện vi phạm.</li>
								</ul>

								<h3 class="fw-bold mb-4 text-primary">3. Trách nhiệm của Tình nguyện viên</h3>
								<ul class="text-muted lh-lg mb-4">
									<li>Tuân thủ các quy định, hướng dẫn của Kiểm duyệt viên trong mỗi chiến dịch.</li>
									<li>Tham gia đầy đủ và có trách nhiệm với các hoạt động đã đăng ký.</li>
									<li>Giữ gìn hình ảnh, uy tín của tổ chức và cộng đồng tình nguyện.</li>
									<li>Thông báo trước nếu không thể tham gia chiến dịch đã đăng ký.</li>
								</ul>

								<h3 class="fw-bold mb-4 text-primary">4. Quyền sở hữu trí tuệ</h3>
								<p class="text-muted lh-lg mb-4">
									Toàn bộ nội dung, hình ảnh, mã nguồn và dữ liệu trên hệ thống VMS-AI thuộc quyền sở hữu của chúng tôi. Việc sao chép, phân phối hoặc sử dụng trái phép đều bị nghiêm cấm.
								</p>

								<h3 class="fw-bold mb-4 text-primary">5. Thay đổi điều khoản</h3>
								<p class="text-muted lh-lg mb-0">
									Chúng tôi có quyền cập nhật và thay đổi các Điều khoản này bất kỳ lúc nào. Những thay đổi sẽ có hiệu lực ngay khi được đăng tải trên hệ thống. Tiếp tục sử dụng dịch vụ đồng nghĩa với việc bạn chấp nhận các điều khoản sửa đổi.
								</p>
							</div>

							<hr class="my-5">

							<div class="d-flex justify-content-between align-items-center">
								<router-link to="/dang-ky" class="btn btn-outline-primary px-4 py-2 rounded-pill fw-medium">
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
	name: 'TrangDieuKhoan',
	data() {
		return {
			currentDate: new Date().toLocaleDateString('vi-VN')
		}
	}
}
</script>

<style scoped>
.terms-page {
	background-color: #f8f9fa;
	min-height: calc(100vh - 80px); /* Adjust based on your header height */
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
	background-color: #0d6efd;
	border-radius: 2px;
}

.content-wrapper p, .content-wrapper ul {
	font-size: 1.05rem;
}

.content-wrapper li {
	margin-bottom: 8px;
}
</style>
