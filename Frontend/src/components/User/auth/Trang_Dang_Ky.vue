<template>
	<div class="auth-wrapper">
		<div class="container-fluid p-0 h-100">
			<div class="row g-0 h-100">
				<div class="col-lg-6 d-none d-lg-flex align-items-end banner-section" style="background-image: url('https://ccptnt.vn/vnt_upload/File/Image/trong_cay_Chi_doan_1.png');">
					<div class="banner-overlay w-100">
						<div class="p-5 text-white">
							<div class="d-flex align-items-center mb-3">
								<i class="fa-solid fa-seedling fs-1 me-3 text-warning"></i>
								<h1 class="display-6 fw-bold mb-0">VMS-AI</h1>
							</div>
							<p class="fs-5 mb-0 opacity-75 fw-light" style="max-width: 500px;">
								{{ $t('auth.register.bannerText') }}
							</p>
						</div>
					</div>
				</div>

				<div class="col-12 col-lg-6 d-flex flex-column bg-white shadow-soft z-1 overflow-auto custom-scrollbar">
					<div class="flex-grow-1 d-flex align-items-center justify-content-center p-4 p-md-5 my-auto">
						<div class="w-100" style="max-width: 550px;">
							<div class="text-center mb-5 d-block d-lg-none">
								<div class="bg-primary text-white d-inline-flex align-items-center justify-content-center rounded-circle mb-2" style="width: 60px; height: 60px;">
									<i class="fa-solid fa-hands-holding-circle fs-3"></i>
								</div>
								<h4 class="fw-bold text-primary">VMS-AI</h4>
							</div>

							<div class="text-center mb-4">
								<h3 class="fw-bold fs-2 text-dark mb-2">{{ $t('auth.register.title') }}</h3>
								<p class="text-muted">{{ $t('auth.register.subtitle') }} <router-link to="/dang-nhap" class="text-primary fw-bold text-decoration-none transition-hover ms-1">{{ $t('auth.register.loginHere') }}</router-link></p>
							</div>

							<div v-if="alertMessage" class="alert alert-dismissible fade show" :class="alertSuccess ? 'alert-success' : 'alert-danger'" role="alert">
								<i :class="alertSuccess ? 'fa-solid fa-check-circle' : 'fa-solid fa-exclamation-circle'" class="me-1"></i> {{ alertMessage }}
								<button type="button" class="btn-close" @click="alertMessage = ''"></button>
							</div>

							<div class="d-flex align-items-center justify-content-between mb-5 px-3 position-relative">
								<div class="progress position-absolute w-100" style="height: 3px; top: 50%; left: 0; transform: translateY(-50%); z-index: 0; opacity: 0.15;">
									<div class="progress-bar bg-primary transition-all" :style="{ width: ((currentStep - 1) * 50) + '%' }"></div>
								</div>

								<div class="step-badge-wrapper text-center z-1">
									<div class="step-badge rounded-circle d-flex align-items-center justify-content-center mx-auto mb-1 transition-all" :class="currentStep >= 1 ? 'bg-primary text-white shadow-primary' : 'bg-light text-muted border'">
										1
									</div>
									<small class="fw-semibold" :class="currentStep >= 1 ? 'text-primary' : 'text-muted'">{{ $t('auth.register.steps.personal') }}</small>
								</div>

								<div class="step-badge-wrapper text-center z-1">
									<div class="step-badge rounded-circle d-flex align-items-center justify-content-center mx-auto mb-1 transition-all" :class="currentStep >= 2 ? 'bg-primary text-white shadow-primary' : 'bg-light text-muted border'">
										2
									</div>
									<small class="fw-semibold" :class="currentStep >= 2 ? 'text-primary' : 'text-muted'">{{ $t('auth.register.steps.skills') }}</small>
								</div>

								<div class="step-badge-wrapper text-center z-1">
									<div class="step-badge rounded-circle d-flex align-items-center justify-content-center mx-auto mb-1 transition-all" :class="currentStep >= 3 ? 'bg-primary text-white shadow-primary' : 'bg-light text-muted border'">
										3
									</div>
									<small class="fw-semibold" :class="currentStep >= 3 ? 'text-primary' : 'text-muted'">{{ $t('auth.register.steps.finish') }}</small>
								</div>
							</div>

							<form @submit.prevent="handleRegister" class="needs-validation">
								<div v-show="currentStep === 1" class="animation-fade-in">
									<button class="btn btn-outline-light text-dark w-100 py-2 fw-semibold d-flex align-items-center justify-content-center border rounded-3 mb-4 transition-hover" type="button" :disabled="isLoading" @click="handleGoogleRegister">
										<img src="https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg" alt="Google" width="20" class="me-2">
										{{ $t('auth.common.googleRegister') }}
									</button>

									<div class="d-flex align-items-center my-4">
										<div class="flex-grow-1 border-bottom"></div>
										<span class="px-3 text-muted small fw-medium">{{ $t('auth.register.orEmail') }}</span>
										<div class="flex-grow-1 border-bottom"></div>
									</div>

									<div class="row g-3">
										<div class="col-12">
											<label for="ho_ten" class="form-label fw-semibold text-dark">{{ $t('auth.register.fullName') }}</label>
											<input id="ho_ten" v-model="form.ho_ten" type="text" class="form-control bg-light border-0 py-2 px-3 input-focus" :class="{ 'is-invalid': fieldErrors.ho_ten }" :placeholder="$t('auth.register.fullNamePlaceholder')" required>
											<div v-if="fieldErrors.ho_ten" class="inline-error">{{ fieldErrors.ho_ten }}</div>
										</div>
										<div class="col-12">
											<label for="email" class="form-label fw-semibold text-dark">{{ $t('auth.common.emailLabel') }}</label>
											<input id="email" v-model="form.email" type="email" class="form-control bg-light border-0 py-2 px-3 input-focus" :class="{ 'is-invalid': fieldErrors.email }" placeholder="example@email.com" required>
											<div v-if="fieldErrors.email" class="inline-error">{{ fieldErrors.email }}</div>
										</div>
										<div class="col-12">
											<label for="phone" class="form-label fw-semibold text-dark">{{ $t('auth.common.phoneLabel') }}</label>
											<input id="phone" v-model="form.so_dien_thoai" type="tel" class="form-control bg-light border-0 py-2 px-3 input-focus" :class="{ 'is-invalid': fieldErrors.so_dien_thoai }" :placeholder="$t('auth.register.phonePlaceholder')">
											<div v-if="fieldErrors.so_dien_thoai" class="inline-error">{{ fieldErrors.so_dien_thoai }}</div>
										</div>
										<div class="col-12">
											<label for="pw1" class="form-label fw-semibold text-dark">{{ $t('auth.common.passwordLabel') }}</label>
											<div class="input-group">
												<input id="pw1" v-model="form.password" :type="showPassword ? 'text' : 'password'" class="form-control bg-light border-start-0 border-top-0 border-bottom-0 border-end-0 py-2 px-3 input-focus border-light" :class="{ 'is-invalid': fieldErrors.password }" :placeholder="$t('auth.register.pwPlaceholder')" required style="border-radius: 8px 0 0 8px;">
												<button class="btn btn-light bg-light" type="button" @click="showPassword = !showPassword" style="border-radius: 0 8px 8px 0;">
													<i :class="showPassword ? 'fa-regular fa-eye-slash' : 'fa-regular fa-eye'" class="text-muted"></i>
												</button>
											</div>
											<div v-if="fieldErrors.password" class="inline-error">{{ fieldErrors.password }}</div>
										</div>
										<div class="col-12">
											<label class="form-label fw-semibold text-dark">{{ $t('auth.common.confirmPasswordLabel') }}</label>
											<input v-model="form.password_confirmation" type="password" class="form-control bg-light border-0 py-2 px-3 input-focus" :class="{ 'is-invalid': fieldErrors.password_confirmation }" :placeholder="$t('auth.register.confirmPwPlaceholder')" required>
											<div v-if="fieldErrors.password_confirmation" class="inline-error">{{ fieldErrors.password_confirmation }}</div>
										</div>
										<div class="col-12 mt-4">
											<button type="button" class="btn btn-primary w-100 py-3 fw-bold rounded-3 shadow-primary transition-hover" @click="nextStep">
												{{ $t('auth.register.nextBtn') }} <i class="fa-solid fa-arrow-right ms-2"></i>
											</button>
										</div>
									</div>
								</div>

								<div v-show="currentStep === 2" class="animation-fade-in">
									<div class="mb-4">
										<h5 class="fw-bold text-dark mb-1">{{ $t('auth.register.skillsTitle') }}</h5>
										<p class="text-muted small">{{ $t('auth.register.skillsSubtitle') }}</p>

										<div v-if="loadingData" class="text-center py-4">
											<div class="spinner-border text-primary" role="status"></div>
											<p class="text-muted mt-2 small">Đang tải dữ liệu...</p>
										</div>
										<div v-else>
											<div class="d-flex flex-wrap gap-2 mt-3">
												<span v-for="skill in availableSkills" :key="skill.id" class="badge rounded-pill px-3 py-2 cursor-pointer transition-hover user-select-none" :class="form.ky_nang_ids.includes(skill.id) ? 'bg-primary text-white shadow-sm' : 'bg-light text-dark text-opacity-75'" style="font-size: 14px; border: 1px solid var(--bs-gray-200);" @click="toggleSkill(skill.id)">
													<i :class="skill.bieu_tuong" class="me-1"></i> {{ skill.ten }}
												</span>
												<span class="badge rounded-pill px-3 py-2 cursor-pointer transition-hover user-select-none" :class="showOtherSkillInput ? 'bg-warning text-dark shadow-sm' : 'bg-light text-dark text-opacity-75'" style="font-size: 14px; border: 1px solid var(--bs-gray-200);" @click="toggleOtherSkillInput">
													<i class="fa-solid fa-plus me-1"></i> KHÁC
												</span>
											</div>
											<div v-if="showOtherSkillInput" class="mt-3">
												<div class="input-group">
													<input v-model.trim="otherSkillInput" type="text" class="form-control" :class="{ 'is-invalid': fieldErrors.otherSkillInput }" placeholder="Nhập kỹ năng khác">
													<button type="button" class="btn btn-outline-primary" @click="addOtherSkill">Thêm</button>
												</div>
												<div v-if="fieldErrors.otherSkillInput" class="inline-error">{{ fieldErrors.otherSkillInput }}</div>
												<div v-if="form.ky_nang_khac.length" class="d-flex flex-wrap gap-2 mt-2">
													<span v-for="skill in form.ky_nang_khac" :key="skill" class="badge bg-warning text-dark rounded-pill px-3 py-2">
														<i :class="getDefaultSkillIcon()" class="me-1"></i>
														{{ skill }}
														<button type="button" class="btn btn-sm p-0 ms-2 text-dark" @click="removeOtherSkill(skill)">
															<i class="fa-solid fa-xmark"></i>
														</button>
													</span>
												</div>
											</div>
											<div v-if="fieldErrors.ky_nang_ids" class="inline-error mt-2">{{ fieldErrors.ky_nang_ids }}</div>
										</div>
									</div>

									<div class="mb-4">
										<label class="form-label fw-bold text-dark">{{ $t('auth.register.areaLabel') }}</label>
										<div class="d-flex flex-wrap gap-2">
											<span v-for="area in availableAreas" :key="area.id" class="badge rounded-pill px-3 py-2 cursor-pointer transition-hover user-select-none" :class="form.khu_vuc_ids.includes(area.id) ? 'bg-success text-white shadow-sm' : 'bg-light text-dark text-opacity-75'" style="font-size: 14px; border: 1px solid var(--bs-gray-200);" @click="toggleArea(area.id)">
												<i class="fa-solid fa-map-marker-alt me-1"></i> {{ area.ten }}
											</span>
											<span class="badge rounded-pill px-3 py-2 cursor-pointer transition-hover user-select-none" :class="showOtherAreaInput ? 'bg-warning text-dark shadow-sm' : 'bg-light text-dark text-opacity-75'" style="font-size: 14px; border: 1px solid var(--bs-gray-200);" @click="toggleOtherAreaInput">
												<i class="fa-solid fa-plus me-1"></i> KHÁC
											</span>
										</div>
										<div v-if="showOtherAreaInput" class="mt-3">
											<div class="input-group">
												<input v-model.trim="otherAreaInput" type="text" class="form-control" :class="{ 'is-invalid': fieldErrors.otherAreaInput }" placeholder="Nhập khu vực khác">
												<button type="button" class="btn btn-outline-success" @click="addOtherArea">Thêm</button>
											</div>
											<div v-if="fieldErrors.otherAreaInput" class="inline-error">{{ fieldErrors.otherAreaInput }}</div>
											<div v-if="form.khu_vuc_khac.length" class="d-flex flex-wrap gap-2 mt-2">
												<span v-for="area in form.khu_vuc_khac" :key="area" class="badge bg-warning text-dark rounded-pill px-3 py-2">
													<i class="fa-solid fa-map-marker-alt me-1"></i>
													{{ area }}
													<button type="button" class="btn btn-sm p-0 ms-2 text-dark" @click="removeOtherArea(area)">
														<i class="fa-solid fa-xmark"></i>
													</button>
												</span>
											</div>
										</div>
										<div v-if="fieldErrors.khu_vuc_ids" class="inline-error mt-2">{{ fieldErrors.khu_vuc_ids }}</div>
									</div>

									<div class="row g-3 mt-2">
										<div class="col-6">
											<button type="button" class="btn btn-outline-secondary w-100 py-3 fw-bold rounded-3 transition-hover" @click="prevStep">
												<i class="fa-solid fa-arrow-left me-2"></i> {{ $t('auth.register.prevBtn') }}
											</button>
										</div>
										<div class="col-6">
											<button type="button" class="btn btn-primary w-100 py-3 fw-bold rounded-3 shadow-primary transition-hover" @click="nextStep">
												{{ $t('auth.register.nextBtn') }} <i class="fa-solid fa-arrow-right ms-2"></i>
											</button>
										</div>
									</div>
								</div>

								<div v-show="currentStep === 3" class="animation-fade-in">
									<div class="text-center mb-4">
										<div class="bg-success bg-opacity-10 text-success d-inline-flex align-items-center justify-content-center rounded-circle mb-3" style="width: 70px; height: 70px;">
											<i class="fa-solid fa-clipboard-check fs-2"></i>
										</div>
										<h4 class="fw-bold text-dark">{{ $t('auth.register.reviewTitle') }}</h4>
									</div>

									<div class="bg-light rounded-4 p-4 mb-4">
										<div class="row mb-3 pb-3 border-bottom border-light-subtle">
											<div class="col-5 text-muted small fw-semibold text-uppercase">{{ $t('auth.register.reviewName') }}</div>
											<div class="col-7 text-end fw-bold text-dark">{{ form.ho_ten }}</div>
										</div>
										<div class="row mb-3 pb-3 border-bottom border-light-subtle">
											<div class="col-5 text-muted small fw-semibold text-uppercase">{{ $t('auth.register.reviewEmail') }}</div>
											<div class="col-7 text-end fw-medium text-dark text-break">{{ form.email }}</div>
										</div>
										<div class="row mb-3 pb-3 border-bottom border-light-subtle">
											<div class="col-5 text-muted small fw-semibold text-uppercase">{{ $t('auth.register.reviewPhone') }}</div>
											<div class="col-7 text-end fw-medium text-dark">{{ form.so_dien_thoai || $t('auth.register.unprovided') }}</div>
										</div>
										<div class="row mb-3 pb-3 border-bottom border-light-subtle">
											<div class="col-12 text-muted small fw-semibold text-uppercase mb-2">{{ $t('auth.register.reviewArea') }}</div>
											<div class="col-12">
												<div class="d-flex flex-wrap gap-1">
													<span v-for="aid in form.khu_vuc_ids" :key="aid" class="badge bg-success text-white bg-opacity-75">{{ getAreaName(aid) }}</span>
													<span v-for="area in form.khu_vuc_khac" :key="`custom-area-${area}`" class="badge bg-warning text-dark"><i class="fa-solid fa-map-marker-alt me-1"></i>{{ area }}</span>
													<span v-if="form.khu_vuc_ids.length === 0 && form.khu_vuc_khac.length === 0" class="badge bg-secondary opacity-50">Chưa chọn</span>
												</div>
											</div>
										</div>
										<div class="row">
											<div class="col-12 text-muted small fw-semibold text-uppercase mb-2">{{ $t('auth.register.reviewSkills') }}</div>
											<div class="col-12">
												<div class="d-flex flex-wrap gap-1">
													<span v-for="sid in form.ky_nang_ids" :key="sid" class="badge bg-primary text-white bg-opacity-75">{{ getSkillName(sid) }}</span>
													<span v-for="skill in form.ky_nang_khac" :key="`custom-skill-${skill}`" class="badge bg-warning text-dark"><i :class="getDefaultSkillIcon()" class="me-1"></i>{{ skill }}</span>
													<span v-if="form.ky_nang_ids.length === 0 && form.ky_nang_khac.length === 0" class="badge bg-secondary opacity-50">{{ $t('auth.register.noSkills') }}</span>
												</div>
											</div>
										</div>
									</div>

									<div class="mb-4 form-check user-select-none">
										<input id="agreeTerms" v-model="form.agreeTerms" type="checkbox" class="form-check-input shadow-none cursor-pointer" :class="{ 'is-invalid': fieldErrors.agreeTerms }" required>
										<label class="form-check-label text-muted cursor-pointer" for="agreeTerms">
											{{ $t('auth.register.termsAgree') }}
											<router-link to="/dieu-khoan" class="text-primary text-decoration-none fw-semibold transition-hover">{{ $t('auth.register.termsLink') }}</router-link> {{ $t('auth.register.termsAnd') }}
											<router-link to="/chinh-sach-bao-mat" class="text-primary text-decoration-none fw-semibold transition-hover">{{ $t('auth.register.privacyLink') }}</router-link> {{ $t('auth.register.termsPlatform') }}
										</label>
										<div v-if="fieldErrors.agreeTerms" class="inline-error">{{ fieldErrors.agreeTerms }}</div>
									</div>

									<div class="row g-3">
										<div class="col-5">
											<button type="button" class="btn btn-outline-secondary w-100 py-3 fw-bold rounded-3 transition-hover" @click="prevStep">
												{{ $t('auth.register.prevBtn') }}
											</button>
										</div>
										<div class="col-7">
											<button type="submit" class="btn btn-primary w-100 py-3 fw-bold rounded-3 shadow-primary transition-hover d-flex align-items-center justify-content-center gap-2" :disabled="!form.agreeTerms || isLoading">
												<span v-if="isLoading" class="spinner-border spinner-border-sm"></span>
												<span>{{ isLoading ? 'Đang xử lý...' : $t('auth.register.completeBtn') }}</span>
												<i v-if="!isLoading" class="fa-solid fa-flag-checkered"></i>
											</button>
										</div>
									</div>
								</div>
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
import { requestGoogleAuthCode } from '@/services/googleAuth';

const REGISTER_DRAFT_KEY = 'register_draft';
const REGISTER_PREFILL_KEY = 'register_prefill_login';

const createInitialForm = () => ({
	ho_ten: '',
	email: '',
	so_dien_thoai: '',
	password: '',
	password_confirmation: '',
	ky_nang_ids: [],
	khu_vuc_ids: [],
	ky_nang_khac: [],
	khu_vuc_khac: [],
	agreeTerms: false,
});

export default {
	name: 'TrangDangKy',
	data() {
		return {
			currentStep: 1,
			showPassword: false,
			isLoading: false,
			loadingData: false,
			alertMessage: '',
			alertSuccess: false,
			fieldErrors: {},
			form: createInitialForm(),
			availableSkills: [],
			availableAreas: [],
			showOtherSkillInput: false,
			showOtherAreaInput: false,
			otherSkillInput: '',
			otherAreaInput: '',
		};
	},
	watch: {
		form: {
			deep: true,
			handler() {
				this.persistDraft();
			},
		},
		currentStep() {
			this.persistDraft();
		},
	},
	async mounted() {
		this.restoreDraft();
		await this.loadCatalogData();
	},
	methods: {
		persistDraft() {
			sessionStorage.setItem(REGISTER_DRAFT_KEY, JSON.stringify({
				currentStep: this.currentStep,
				form: this.form,
				showOtherSkillInput: this.showOtherSkillInput || this.form.ky_nang_khac.length > 0,
				showOtherAreaInput: this.showOtherAreaInput || this.form.khu_vuc_khac.length > 0,
			}));
		},
		restoreDraft() {
			const rawDraft = sessionStorage.getItem(REGISTER_DRAFT_KEY);
			if (!rawDraft) return;

			try {
				const draft = JSON.parse(rawDraft);
				if (draft?.form) {
					this.form = {
						...createInitialForm(),
						...draft.form,
						ky_nang_ids: Array.isArray(draft.form.ky_nang_ids) ? draft.form.ky_nang_ids : [],
						khu_vuc_ids: Array.isArray(draft.form.khu_vuc_ids) ? draft.form.khu_vuc_ids : [],
						ky_nang_khac: Array.isArray(draft.form.ky_nang_khac) ? draft.form.ky_nang_khac : [],
						khu_vuc_khac: Array.isArray(draft.form.khu_vuc_khac) ? draft.form.khu_vuc_khac : [],
					};
				}
				if ([1, 2, 3].includes(draft?.currentStep)) {
					this.currentStep = draft.currentStep;
				}
				this.showOtherSkillInput = Boolean(draft?.showOtherSkillInput || this.form.ky_nang_khac.length);
				this.showOtherAreaInput = Boolean(draft?.showOtherAreaInput || this.form.khu_vuc_khac.length);
			} catch (_error) {
				sessionStorage.removeItem(REGISTER_DRAFT_KEY);
			}
		},
		clearDraft() {
			sessionStorage.removeItem(REGISTER_DRAFT_KEY);
		},
		async loadCatalogData() {
			this.loadingData = true;
			try {
				const [skillRes, areaRes] = await Promise.all([
					api.get('/danh-muc/ky-nang'),
					api.get('/danh-muc/khu-vuc'),
				]);
				this.availableSkills = skillRes.data.data || [];
				this.availableAreas = areaRes.data.data || [];
			} catch (e) {
				console.error('Lỗi tải danh mục:', e);
			} finally {
				this.loadingData = false;
			}
		},
		nextStep() {
			if (this.currentStep === 1 && !this.validateStepOne()) {
				return;
			}
			if (this.currentStep === 2 && !this.validateStepTwo()) {
				return;
			}
			if (this.currentStep < 3) this.currentStep++;
		},
		prevStep() {
			if (this.currentStep > 1) this.currentStep--;
		},
		validateStepOne() {
			const email = this.form.email.trim();
			const phone = this.form.so_dien_thoai.trim();
			const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
			const phonePattern = /^(0|\+84)\d{9,10}$/;
			this.fieldErrors = {
				...Object.fromEntries(
					Object.entries(this.fieldErrors).filter(([key]) => ![
						'ho_ten',
						'email',
						'so_dien_thoai',
						'password',
						'password_confirmation',
					].includes(key))
				),
			};
			this.alertMessage = '';
			let isValid = true;

			if (!this.form.ho_ten.trim()) {
				this.fieldErrors.ho_ten = 'Vui lòng nhập họ và tên.';
				isValid = false;
			} else if (this.form.ho_ten.trim().length < 2) {
				this.fieldErrors.ho_ten = 'Họ và tên phải có ít nhất 2 ký tự.';
				isValid = false;
			}

			if (!email) {
				this.fieldErrors.email = 'Vui lòng nhập email.';
				isValid = false;
			} else if (!emailPattern.test(email)) {
				this.fieldErrors.email = 'Email không đúng định dạng.';
				isValid = false;
			}

			if (phone && !phonePattern.test(phone)) {
				this.fieldErrors.so_dien_thoai = 'Số điện thoại không hợp lệ.';
				isValid = false;
			}

			if (!this.form.password) {
				this.fieldErrors.password = 'Vui lòng nhập mật khẩu.';
				isValid = false;
			} else if (this.form.password.length < 8) {
				this.fieldErrors.password = 'Mật khẩu phải có ít nhất 8 ký tự.';
				isValid = false;
			}

			if (!this.form.password_confirmation) {
				this.fieldErrors.password_confirmation = 'Vui lòng xác nhận mật khẩu.';
				isValid = false;
			} else if (this.form.password !== this.form.password_confirmation) {
				this.fieldErrors.password_confirmation = 'Xác nhận mật khẩu không khớp.';
				isValid = false;
			}

			this.form.email = email;
			this.form.so_dien_thoai = phone;
			return isValid;
		},
		validateStepTwo() {
			this.fieldErrors = {
				...Object.fromEntries(
					Object.entries(this.fieldErrors).filter(([key]) => ![
						'ky_nang_ids',
						'khu_vuc_ids',
						'otherSkillInput',
						'otherAreaInput',
					].includes(key))
				),
			};

			let isValid = true;

			if (this.showOtherSkillInput && this.otherSkillInput.trim()) {
				this.fieldErrors.otherSkillInput = 'Bạn đang nhập dở một kỹ năng khác. Hãy bấm "Thêm" hoặc xóa nội dung này.';
				isValid = false;
			}

			if (this.showOtherAreaInput && this.otherAreaInput.trim()) {
				this.fieldErrors.otherAreaInput = 'Bạn đang nhập dở một khu vực khác. Hãy bấm "Thêm" hoặc xóa nội dung này.';
				isValid = false;
			}

			if (this.form.ky_nang_ids.length === 0 && this.form.ky_nang_khac.length === 0) {
				this.fieldErrors.ky_nang_ids = 'Vui lòng chọn ít nhất 1 kỹ năng.';
				isValid = false;
			}

			if (this.form.khu_vuc_ids.length === 0 && this.form.khu_vuc_khac.length === 0) {
				this.fieldErrors.khu_vuc_ids = 'Vui lòng chọn ít nhất 1 khu vực hoạt động.';
				isValid = false;
			}

			return isValid;
		},
		validateStepThree() {
			this.fieldErrors = {
				...Object.fromEntries(
					Object.entries(this.fieldErrors).filter(([key]) => key !== 'agreeTerms')
				),
			};

			if (!this.form.agreeTerms) {
				this.fieldErrors.agreeTerms = 'Bạn cần đồng ý điều khoản trước khi hoàn tất đăng ký.';
				return false;
			}

			return true;
		},
		toggleOtherSkillInput() {
			this.showOtherSkillInput = !this.showOtherSkillInput;
			if (!this.showOtherSkillInput) this.otherSkillInput = '';
		},
		toggleOtherAreaInput() {
			this.showOtherAreaInput = !this.showOtherAreaInput;
			if (!this.showOtherAreaInput) this.otherAreaInput = '';
		},
		addOtherSkill() {
			const value = this.otherSkillInput.trim();
			delete this.fieldErrors.otherSkillInput;
			if (!value) {
				this.fieldErrors.otherSkillInput = 'Vui lòng nhập kỹ năng khác.';
				return;
			}
			if (value.length > 100) {
				this.fieldErrors.otherSkillInput = 'Kỹ năng khác không được quá 100 ký tự.';
				return;
			}
			const existed = this.form.ky_nang_khac.some((skill) => skill.toLowerCase() === value.toLowerCase());
			if (existed) {
				this.fieldErrors.otherSkillInput = 'Kỹ năng này đã được thêm rồi.';
				return;
			}
			this.form.ky_nang_khac.push(value);
			delete this.fieldErrors.ky_nang_ids;
			this.otherSkillInput = '';
		},
		removeOtherSkill(value) {
			this.form.ky_nang_khac = this.form.ky_nang_khac.filter((skill) => skill !== value);
		},
		addOtherArea() {
			const value = this.otherAreaInput.trim();
			delete this.fieldErrors.otherAreaInput;
			if (!value) {
				this.fieldErrors.otherAreaInput = 'Vui lòng nhập khu vực khác.';
				return;
			}
			if (value.length > 150) {
				this.fieldErrors.otherAreaInput = 'Khu vực khác không được quá 150 ký tự.';
				return;
			}
			const existed = this.form.khu_vuc_khac.some((area) => area.toLowerCase() === value.toLowerCase());
			if (existed) {
				this.fieldErrors.otherAreaInput = 'Khu vực này đã được thêm rồi.';
				return;
			}
			this.form.khu_vuc_khac.push(value);
			delete this.fieldErrors.khu_vuc_ids;
			this.otherAreaInput = '';
		},
		removeOtherArea(value) {
			this.form.khu_vuc_khac = this.form.khu_vuc_khac.filter((area) => area !== value);
		},
		toggleSkill(id) {
			const i = this.form.ky_nang_ids.indexOf(id);
			if (i > -1) this.form.ky_nang_ids.splice(i, 1);
			else this.form.ky_nang_ids.push(id);
			if (this.form.ky_nang_ids.length > 0 || this.form.ky_nang_khac.length > 0) delete this.fieldErrors.ky_nang_ids;
		},
		toggleArea(id) {
			const i = this.form.khu_vuc_ids.indexOf(id);
			if (i > -1) this.form.khu_vuc_ids.splice(i, 1);
			else this.form.khu_vuc_ids.push(id);
			if (this.form.khu_vuc_ids.length > 0 || this.form.khu_vuc_khac.length > 0) delete this.fieldErrors.khu_vuc_ids;
		},
		getSkillName(id) {
			const skill = this.availableSkills.find((item) => item.id === id);
			return skill ? skill.ten : '';
		},
		getDefaultSkillIcon() {
			return this.availableSkills[0]?.bieu_tuong || 'fa-solid fa-bars-staggered';
		},
		getAreaName(id) {
			const area = this.availableAreas.find((item) => item.id === id);
			return area ? area.ten : '';
		},
		async handleGoogleRegister() {
			this.isLoading = true;
			this.alertMessage = '';
			this.alertSuccess = false;

			try {
				const code = await requestGoogleAuthCode();
				const res = await api.post('/xac-thuc/google', { code });

				if (res.data?.status === 1 && res.data?.token && res.data?.data) {
					localStorage.setItem('token', res.data.token);
					localStorage.setItem('user', JSON.stringify(res.data.data));
					this.clearDraft();
					this.$router.push('/');
					return;
				}

				this.alertMessage = res.data?.message || 'Đăng ký bằng Google thất bại.';
			} catch (error) {
				this.alertMessage = error?.response?.data?.message || error?.message || 'Đăng ký bằng Google thất bại.';
			} finally {
				this.isLoading = false;
			}
		},
		async handleRegister() {
			if (!this.validateStepOne() || !this.validateStepTwo() || !this.validateStepThree()) {
				return;
			}

			this.isLoading = true;
			this.alertMessage = '';

			try {
				const res = await api.post('/xac-thuc/dang-ky', {
					ho_ten: this.form.ho_ten,
					email: this.form.email,
					so_dien_thoai: this.form.so_dien_thoai,
					password: this.form.password,
					password_confirmation: this.form.password_confirmation,
					ky_nang_ids: this.form.ky_nang_ids,
					ky_nang_khac: this.form.ky_nang_khac,
					khu_vuc_ids: this.form.khu_vuc_ids,
					khu_vuc_khac: this.form.khu_vuc_khac,
				});

				if (res.data.status === 1) {
					localStorage.setItem(REGISTER_PREFILL_KEY, JSON.stringify({
						email: this.form.email,
						password: this.form.password,
					}));

					this.form = createInitialForm();
					this.showOtherSkillInput = false;
					this.showOtherAreaInput = false;
					this.otherSkillInput = '';
					this.otherAreaInput = '';
					this.currentStep = 1;
					this.clearDraft();
					this.$router.push('/dang-ky/thanh-cong');
				} else {
					this.alertMessage = res.data.message;
					this.alertSuccess = false;
				}
			} catch (error) {
				if (error.response?.data) {
					const data = error.response.data;
					if (data.errors) {
						const firstKey = Object.keys(data.errors)[0];
						this.fieldErrors = {
							...this.fieldErrors,
							...Object.fromEntries(
								Object.entries(data.errors).map(([key, messages]) => [key, messages?.[0] || 'Dữ liệu không hợp lệ.'])
							),
						};
						this.alertMessage = data.errors[firstKey][0];
					} else {
						this.alertMessage = data.message || 'Đăng ký thất bại.';
					}
				} else {
					this.alertMessage = 'Không thể kết nối server.';
				}
				this.alertSuccess = false;
			} finally {
				this.isLoading = false;
			}
		},
	},
};
</script>

<style scoped>
.auth-wrapper {
	min-height: 100vh;
	min-height: 100dvh;
	width: 100%;
	overflow-x: hidden;
	overflow-y: auto;
}

.banner-section {
	background-size: cover;
	background-position: center;
	background-repeat: no-repeat;
	position: relative;
	min-height: 100vh;
	min-height: 100dvh;
}

.container-fluid,
.row {
	min-height: inherit;
}

.banner-overlay {
	background: linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(13, 110, 253, 0.9) 100%);
	height: 60%;
	display: flex;
	align-items: flex-end;
}

.shadow-soft {
	box-shadow: -10px 0 40px rgba(0,0,0,0.08);
}

.shadow-primary {
	box-shadow: 0 8px 20px rgba(13, 110, 253, 0.25);
}

.step-badge {
	width: 36px;
	height: 36px;
	font-weight: 700;
	font-size: 15px;
}

.transition-all {
	transition: all 0.25s ease;
}

.transition-hover {
	transition: all 0.2s ease;
}

.transition-hover:hover {
	opacity: 0.9;
	transform: translateY(-1px);
}

.input-focus:focus {
	background-color: #fff !important;
	box-shadow: none !important;
}

.inline-error {
	margin-top: 6px;
	font-size: 13px;
	line-height: 1.35;
	color: #dc3545;
}

.is-invalid {
	border: 1px solid rgba(220, 53, 69, 0.35) !important;
	background-color: #fff5f5 !important;
}

.cursor-pointer {
	cursor: pointer;
}

.custom-scrollbar {
	scrollbar-width: thin;
	scrollbar-color: rgba(13, 110, 253, 0.35) transparent;
}

.animation-fade-in {
	animation: fadeIn 0.35s ease forwards;
}

@keyframes fadeIn {
	from {
		opacity: 0;
		transform: translateY(12px);
	}
	to {
		opacity: 1;
		transform: translateY(0);
	}
}
</style>
