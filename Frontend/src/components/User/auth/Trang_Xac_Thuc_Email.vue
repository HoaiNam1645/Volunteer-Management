<template>
	<div class="auth-wrapper">
		<div class="container-fluid p-0 h-100">
			<div class="row g-0 h-100 justify-content-center align-items-center">
				<div class="col-12 col-md-6 col-lg-4">
					<div class="card border-0 shadow-lg rounded-4 overflow-hidden">
						<div v-if="isLoading" class="card-body text-center p-5">
							<div class="spinner-border text-primary mb-4" style="width: 3rem; height: 3rem;" role="status"></div>
							<h4 class="fw-bold text-dark mb-2">Đang xác thực email...</h4>
							<p class="text-muted">Vui lòng đợi trong giây lát</p>
						</div>

						<div v-else-if="success" class="card-body text-center p-5 animation-fade-in">
							<div class="bg-success bg-opacity-10 text-success d-inline-flex align-items-center justify-content-center rounded-circle mb-4" style="width: 90px; height: 90px;">
								<i class="fa-solid fa-circle-check fs-1"></i>
							</div>
							<h3 class="fw-bold text-dark mb-3">Xác thực thành công! 🎉</h3>
							<p class="text-muted mb-4">Email của bạn đã được xác thực. Bạn có thể đăng nhập ngay bây giờ.</p>
							<router-link :to="loginRoute" class="btn btn-primary w-100 py-3 fw-bold rounded-3">
								<i class="fa-solid fa-right-to-bracket me-2"></i> Đăng nhập ngay
							</router-link>
						</div>

						<div v-else class="card-body text-center p-5 animation-fade-in">
							<div class="bg-danger bg-opacity-10 text-danger d-inline-flex align-items-center justify-content-center rounded-circle mb-4" style="width: 90px; height: 90px;">
								<i class="fa-solid fa-circle-xmark fs-1"></i>
							</div>
							<h3 class="fw-bold text-dark mb-3">Xác thực thất bại</h3>
							<p class="text-muted mb-4">{{ errorMessage }}</p>
							<router-link to="/dang-ky" class="btn btn-primary w-100 py-3 fw-bold rounded-3">
								Đăng ký lại
							</router-link>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
import api from '@/services/api.js';

const REGISTER_PREFILL_KEY = 'register_prefill_login';

export default {
	name: 'TrangXacThucEmail',
	data() {
		return {
			isLoading: true,
			success: false,
			errorMessage: '',
			hasPrefill: false,
		};
	},
	async mounted() {
		try {
			this.hasPrefill = Boolean(localStorage.getItem(REGISTER_PREFILL_KEY));
			const token = this.$route.params.token;
			const res = await api.post('/xac-thuc/xac-thuc-email', { ma_xac_thuc: token });
			if (res.data.status === 1) {
				this.success = true;
				if (this.hasPrefill) {
					setTimeout(() => {
						this.$router.push(this.loginRoute);
					}, 1500);
				}
			} else {
				this.success = false;
				this.errorMessage = res.data.message;
			}
		} catch (_error) {
			this.success = false;
			this.errorMessage = 'Có lỗi xảy ra. Vui lòng thử lại.';
		} finally {
			this.isLoading = false;
		}
	},
	computed: {
		loginRoute() {
			return this.hasPrefill
				? { path: '/dang-nhap', query: { prefill: '1' } }
				: { path: '/dang-nhap' };
		},
	},
};
</script>

<style scoped>
.auth-wrapper {
	min-height: 100vh;
	background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
	display: flex;
	align-items: center;
}

.animation-fade-in {
	animation: fadeIn 0.5s ease forwards;
}

@keyframes fadeIn {
	from { opacity: 0; transform: translateY(20px); }
	to { opacity: 1; transform: translateY(0); }
}
</style>
