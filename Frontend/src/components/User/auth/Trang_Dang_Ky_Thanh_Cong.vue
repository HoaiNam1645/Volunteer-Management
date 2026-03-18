<template>
	<div class="auth-wrapper">
		<div class="container-fluid p-0 h-100">
			<div class="row g-0 h-100 justify-content-center align-items-center">
				<div class="col-12 col-md-6 col-lg-4">
						<div class="card border-0 shadow-lg rounded-4 overflow-hidden">
							<div class="card-body text-center p-5 animation-fade-in">
								<h3 class="fw-bold text-dark mb-3">Đăng ký thành công</h3>
								<p class="text-muted mb-4">Tài khoản của bạn đã được tạo. Vui lòng kiểm tra email để xác thực trước khi đăng nhập.</p>
								<router-link :to="{ path: '/dang-nhap', query: { prefill: '1' } }" class="btn btn-outline-primary w-100 py-3 fw-bold rounded-3">
									<i class="fa-solid fa-right-to-bracket me-2"></i> Về trang đăng nhập
								</router-link>
							</div>
						</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
export default {
	name: 'TrangDangKyThanhCong',
};
</script>

<style scoped>
.auth-wrapper {
	min-height: 100vh;
	background: linear-gradient(135deg, #f4fbf7 0%, #eef7ff 100%);
	display: flex;
	align-items: center;
}

.animation-fade-in {
	animation: fadeIn 0.45s ease forwards;
}

@keyframes fadeIn {
	from { opacity: 0; transform: translateY(18px); }
	to { opacity: 1; transform: translateY(0); }
}
</style>
