<template>
	<div class="auth-wrapper">
		<div class="container-fluid p-0 h-100">
			<div class="row g-0 h-100">
				<!-- Left Visual Banner -->
				<div class="col-lg-7 d-none d-lg-flex align-items-end banner-section" style="background-image: url('');">
					<div class="banner-overlay w-100">
						<div class="p-5 text-white">
							<div class="d-flex align-items-center mb-3">
								<i class="fa-solid fa-hands-holding-circle fs-1 me-3 text-warning"></i>
								<h1 class="display-6 fw-bold mb-0">VMS-AI</h1>
							</div>
							<p class="fs-5 mb-0 opacity-75 fw-light" style="max-width: 500px;">
								{{ $t('auth.login.bannerText') }}
							</p>
						</div>
					</div>
				</div>

				<!-- Right Form Panel -->
				<div class="col-12 col-lg-5 d-flex align-items-center justify-content-center bg-white shadow-soft z-1">
					<div class="w-100 p-4 p-md-5" style="max-width: 480px;">
						<!-- Logo Mobile (hidden on Desktop) -->
						<div class="text-center mb-5 d-block d-lg-none">
							<div class="bg-primary text-white d-inline-flex align-items-center justify-content-center rounded-circle mb-2"
								style="width: 60px; height: 60px;">
								<i class="fa-solid fa-hands-holding-circle fs-3"></i>
							</div>
							<h4 class="fw-bold text-primary">VMS-AI</h4>
						</div>

						<div class="text-center mb-4">
							<h3 class="fw-bold fs-2 text-dark mb-2">{{ $t('auth.login.title') }}</h3>
							<p class="text-muted">{{ $t('auth.login.subtitle') }}</p>
						</div>

						<!-- Alert Message -->
						<div v-if="alertMessage" class="alert alert-dismissible fade show" :class="alertSuccess ? 'alert-success' : 'alert-danger'" role="alert">
							<i :class="alertSuccess ? 'fa-solid fa-check-circle' : 'fa-solid fa-exclamation-circle'" class="me-1"></i> {{ alertMessage }}
							<button type="button" class="btn-close" @click="alertMessage = ''"></button>
						</div>

						<!-- Social Login -->
						<button class="btn btn-outline-light text-dark w-100 py-2 fw-semibold d-flex align-items-center justify-content-center border rounded-3 mb-4 transition-hover" type="button">
							<img src="https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg" alt="Google" width="20" class="me-2">
							{{ $t('auth.common.googleLogin') }}
						</button>

						<!-- Divider -->
						<div class="d-flex align-items-center my-4">
							<div class="flex-grow-1 border-bottom"></div>
							<span class="px-3 text-muted small fw-medium">{{ $t('auth.login.orEmail') }}</span>
							<div class="flex-grow-1 border-bottom"></div>
						</div>

						<!-- Form -->
						<form @submit.prevent="handleLogin" class="needs-validation">
							<!-- Email -->
							<div class="mb-4">
								<label for="email" class="form-label fw-semibold text-dark">{{ $t('auth.common.emailLabel') }}</label>
								<div class="input-group">
									<span class="input-group-text bg-light border-end-0 rounded-start-3"><i class="fa-regular fa-envelope text-muted"></i></span>
									<input type="email" class="form-control bg-light border-start-0 ps-0 rounded-end-3 input-focus" id="email" v-model="email" placeholder="example@gmail.com" required>
								</div>
							</div>

							<!-- Password -->
							<div class="mb-4">
								<div class="d-flex justify-content-between align-items-center mb-1">
									<label for="password" class="form-label fw-semibold text-dark mb-0">{{ $t('auth.common.passwordLabel') }}</label>
									<router-link to="/quen-mat-khau" class="small text-primary text-decoration-none fw-medium transition-hover">{{ $t('auth.login.forgotPassword') }}</router-link>
								</div>
								<div class="input-group">
									<span class="input-group-text bg-light border-end-0 rounded-start-3"><i class="fa-solid fa-lock text-muted"></i></span>
									<input :type="showPassword ? 'text' : 'password'" class="form-control bg-light border-start-0 border-end-0 ps-0 input-focus" id="password" v-model="password" placeholder="••••••••" required>
									<button class="btn btn-light bg-light border border-start-0 rounded-end-3 px-3 border-start-0 text-muted" type="button" @click="showPassword = !showPassword">
										<i :class="showPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye'"></i>
									</button>
								</div>
							</div>

							<!-- Remember Me -->
							<div class="mb-4 form-check user-select-none">
								<input type="checkbox" class="form-check-input shadow-none cursor-pointer" id="remember" v-model="rememberMe">
								<label class="form-check-label text-muted cursor-pointer" for="remember">{{ $t('auth.login.rememberMe') }}</label>
							</div>

							<!-- Submit -->
							<button type="submit" class="btn btn-primary w-100 py-3 fw-bold rounded-3 shadow-primary transition-hover" :disabled="isLoading">
								<span v-if="isLoading" class="spinner-border spinner-border-sm me-2"></span>
								{{ isLoading ? $t('auth.login.loggingIn') : $t('auth.login.loginBtn') }}
							</button>

							<p class="text-center mt-4 mb-0 text-muted">
								{{ $t('auth.login.noAccount') }} <router-link to="/dang-ky" class="text-primary fw-bold text-decoration-none transition-hover ms-1">{{ $t('auth.login.registerNow') }}</router-link>
							</p>
						</form>
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
	name: "TrangDangNhap",
	data() {
		return {
			email: '',
			password: '',
			showPassword: false,
			rememberMe: true,
			isLoading: false,
			alertMessage: '',
			alertSuccess: false,
		}
	},
	mounted() {
		const shouldPrefill = this.$route.query.prefill === '1';
		const rawPrefill = localStorage.getItem(REGISTER_PREFILL_KEY);
		if (!shouldPrefill || !rawPrefill) {
			return;
		}

		try {
			const prefill = JSON.parse(rawPrefill);
			this.email = prefill?.email || '';
			this.password = prefill?.password || '';
		} catch (_error) {
			localStorage.removeItem(REGISTER_PREFILL_KEY);
		}
	},
	methods: {
		async handleLogin() {
			this.isLoading = true;
			this.alertMessage = '';
			try {
				const res = await api.post('/xac-thuc/dang-nhap', {
					email: this.email,
					password: this.password,
				});
				if (res.data.status === 1) {
					localStorage.removeItem(REGISTER_PREFILL_KEY);
					// Lưu token & user vào localStorage
					localStorage.setItem('token', res.data.token);
					localStorage.setItem('user', JSON.stringify(res.data.data));
					const role = res.data.data?.vai_tro;
					const redirect = typeof this.$route.query.redirect === 'string' ? this.$route.query.redirect : '';
					if (role === 'kiem_duyet_vien') {
						this.$router.push('/kiem-duyet-vien/chien-dich');
					} else if (role === 'quan_tri_vien') {
						this.$router.push('/admin');
					} else if (redirect) {
						this.$router.push(redirect);
					} else {
						this.$router.push('/');
					}
				} else {
					this.alertMessage = res.data.message;
					this.alertSuccess = false;
				}
			} catch (error) {
				if (error.response && error.response.data) {
					const data = error.response.data;
					if (data.errors) {
						// Validation errors
						const firstKey = Object.keys(data.errors)[0];
						this.alertMessage = data.errors[firstKey][0];
					} else {
						this.alertMessage = data.message || 'Đăng nhập thất bại.';
					}
				} else {
					this.alertMessage = 'Không thể kết nối server. Vui lòng thử lại.';
				}
				this.alertSuccess = false;
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
	background-repeat: no-repeat;
	position: relative;
}

.banner-overlay {
	background: linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(13, 110, 253, 0.9) 100%);
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
a.transition-hover:hover {
	text-decoration: underline !important;
	transform: none;
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

.cursor-pointer {
	cursor: pointer;
}
</style>
