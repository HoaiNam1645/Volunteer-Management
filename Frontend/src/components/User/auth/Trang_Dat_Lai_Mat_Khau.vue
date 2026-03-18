<template>
	<div class="auth-wrapper">
		<div class="container-fluid p-0 h-100">
			<div class="row g-0 h-100">
				<!-- Left Visual Banner -->
				<div class="col-lg-7 d-none d-lg-flex align-items-end banner-section" style="background-image: url('');">
					<div class="banner-overlay w-100">
						<div class="p-5 text-white">
							<div class="d-flex align-items-center mb-3">
								<i class="fa-solid fa-shield-halved fs-1 me-3 text-warning"></i>
								<h1 class="display-6 fw-bold mb-0">VMS-AI</h1>
							</div>
							<p class="fs-5 mb-0 opacity-75 fw-light" style="max-width: 500px;">
								{{ $t('auth.resetPassword.bannerText') }}
							</p>
						</div>
					</div>
				</div>

				<!-- Right Form Panel -->
				<div class="col-12 col-lg-5 d-flex align-items-center justify-content-center bg-white shadow-soft z-1">
					<div class="w-100 p-4 p-md-5" style="max-width: 480px;">

						<!-- Success State -->
						<div v-if="resetSuccess" class="text-center animation-fade-in">
							<div class="bg-success bg-opacity-10 text-success d-inline-flex align-items-center justify-content-center rounded-circle mb-4"
								style="width: 80px; height: 80px;">
								<i class="fa-solid fa-circle-check fs-1"></i>
							</div>
							<h3 class="fw-bold text-dark mb-3">{{ $t('auth.resetPassword.successTitle') }}</h3>
							<p class="text-muted mb-4">{{ $t('auth.resetPassword.successDesc') }}</p>
							<router-link :to="loginRoute" class="btn btn-primary w-100 py-3 fw-bold rounded-3 shadow-primary transition-hover">
								{{ $t('auth.resetPassword.goToLogin') }}
							</router-link>
						</div>

						<!-- Form State -->
						<div v-else>
							<div class="text-center mb-4">
								<div class="bg-primary bg-opacity-10 text-primary d-inline-flex align-items-center justify-content-center rounded-circle mb-3"
									style="width: 70px; height: 70px;">
									<i class="fa-solid fa-lock fs-2"></i>
								</div>
								<h3 class="fw-bold fs-2 text-dark mb-2">{{ $t('auth.resetPassword.title') }}</h3>
								<p class="text-muted">{{ $t('auth.resetPassword.subtitle') }}</p>
							</div>

							<!-- Alert -->
							<div v-if="alertMessage" class="alert alert-danger alert-dismissible fade show" role="alert">
								<i class="fa-solid fa-exclamation-circle me-1"></i> {{ alertMessage }}
								<button type="button" class="btn-close" @click="alertMessage = ''"></button>
							</div>

							<form @submit.prevent="handleReset">
								<div class="mb-4">
									<label class="form-label fw-semibold text-dark">{{ $t('auth.resetPassword.newPasswordLabel') }}</label>
									<div class="input-group">
										<span class="input-group-text bg-light border-end-0 rounded-start-3"><i class="fa-solid fa-lock text-muted"></i></span>
										<input :type="showPw1 ? 'text' : 'password'" class="form-control bg-light border-start-0 border-end-0 ps-0 input-focus" v-model="password" :placeholder="$t('auth.resetPassword.newPasswordPlaceholder')" required minlength="6">
										<button class="btn btn-light bg-light border border-start-0 rounded-end-3 px-3 text-muted" type="button" @click="showPw1 = !showPw1">
											<i :class="showPw1 ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye'"></i>
										</button>
									</div>
								</div>

								<div class="mb-4">
									<label class="form-label fw-semibold text-dark">{{ $t('auth.resetPassword.confirmPasswordLabel') }}</label>
									<input type="password" class="form-control bg-light border-0 py-2 px-3 input-focus rounded-3" v-model="passwordConfirmation" :placeholder="$t('auth.resetPassword.confirmPasswordPlaceholder')" required minlength="6">
								</div>

								<button type="submit" class="btn btn-primary w-100 py-3 fw-bold rounded-3 shadow-primary transition-hover" :disabled="isLoading">
									<span v-if="isLoading" class="spinner-border spinner-border-sm me-2"></span>
									{{ isLoading ? $t('auth.resetPassword.processing') : $t('auth.resetPassword.submitBtn') }}
								</button>
							</form>
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
const RESET_EMAIL_KEY = 'reset_password_email';

export default {
	name: "TrangDatLaiMatKhau",
	data() {
		return {
			password: '',
			passwordConfirmation: '',
			email: '',
			showPw1: false,
			isLoading: false,
			alertMessage: '',
			resetSuccess: false,
		}
	},
	mounted() {
		this.email = localStorage.getItem(RESET_EMAIL_KEY) || '';
	},
	computed: {
		loginRoute() {
			return { path: '/dang-nhap', query: { prefill: '1' } };
		},
	},
	methods: {
		async handleReset() {
			if (this.password !== this.passwordConfirmation) {
				this.alertMessage = this.$t('auth.resetPassword.passwordMismatch');
				return;
			}
			this.isLoading = true;
			this.alertMessage = '';
			try {
				const res = await api.post('/xac-thuc/dat-lai-mat-khau', {
					ma_xac_thuc: this.$route.params.token,
					password: this.password,
					password_confirmation: this.passwordConfirmation,
				});
				if (res.data.status === 1) {
					localStorage.setItem(REGISTER_PREFILL_KEY, JSON.stringify({
						email: this.email,
						password: this.password,
					}));
					localStorage.removeItem(RESET_EMAIL_KEY);
					this.resetSuccess = true;
					setTimeout(() => {
						this.$router.push(this.loginRoute);
					}, 1500);
				} else {
					this.alertMessage = res.data.message;
				}
			} catch (error) {
				if (error.response && error.response.data) {
					const data = error.response.data;
					if (data.errors) {
						const firstKey = Object.keys(data.errors)[0];
						this.alertMessage = data.errors[firstKey][0];
					} else {
						this.alertMessage = data.message || 'Có lỗi xảy ra.';
					}
				} else {
					this.alertMessage = 'Không thể kết nối server.';
				}
			} finally {
				this.isLoading = false;
			}
		}
	}
}
</script>

<style scoped>
.auth-wrapper {
	height: 100vh;
	width: 100%;
	overflow: hidden;
}
.banner-section {
	background-size: cover;
	background-position: center;
	position: relative;
}
.banner-overlay {
	background: linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(99, 102, 241, 0.9) 100%);
	height: 50%;
	display: flex;
	align-items: flex-end;
}
.shadow-soft {
	box-shadow: -10px 0 40px rgba(0,0,0,0.08);
}
.shadow-primary {
	box-shadow: 0 8px 20px rgba(13, 110, 253, 0.25);
}
.transition-hover {
	transition: all 0.2s ease;
}
.transition-hover:hover {
	opacity: 0.85;
	transform: translateY(-1px);
}
.input-focus:focus {
	background-color: #fff !important;
	box-shadow: none !important;
}
.input-group:focus-within .input-group-text,
.input-group:focus-within .form-control,
.input-group:focus-within .btn {
	background-color: #fff !important;
	border-color: #0d6efd !important;
}
.input-group:focus-within .input-group-text i {
	color: #0d6efd !important;
}
.animation-fade-in {
	animation: fadeIn 0.4s ease forwards;
}
@keyframes fadeIn {
	from { opacity: 0; transform: translateY(10px); }
	to { opacity: 1; transform: translateY(0); }
}
</style>
