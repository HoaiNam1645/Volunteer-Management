<template>
	<div class="bg-light min-vh-100 pb-5">
		<div class="container pt-4">
			<!-- Page Header -->
			<PageHeader
				:title="$t('settings.title')"
				icon="fa-solid fa-gear"
				:breadcrumbs="[{ label: $t('common.home'), to: '/'}, { label: $t('settings.title') }]">
			</PageHeader>

			<!-- Alert -->
			<div v-if="localAlertMessage" class="alert alert-dismissible fade show mb-3" :class="localAlertSuccess ? 'alert-success' : 'alert-danger'" role="alert">
				<i :class="localAlertSuccess ? 'fa-solid fa-circle-check' : 'fa-solid fa-exclamation-triangle'" class="me-2"></i>
				{{ localAlertMessage }}
				<button type="button" class="btn-close" @click="localAlertMessage = ''"></button>
			</div>

			<div class="row g-4">
				<!-- LEFT: Sidebar Tabs -->
				<div class="col-lg-3">
					<div class="card border-0 shadow-sm">
						<div class="card-body p-3">
							<!-- Avatar -->
							<div class="text-center mb-3 pb-3 border-bottom">
								<div class="avatar-wrapper mx-auto mb-2 position-relative">
									<div class="avatar-circle">
										<img v-if="form.avatarPreview" :src="form.avatarPreview" class="rounded-circle w-100 h-100 object-fit-cover" alt="">
										<i v-else class="fa-solid fa-user"></i>
									</div>
									<label class="avatar-edit-btn" for="avatar-upload">
										<i class="fa-solid fa-camera"></i>
									</label>
									<input type="file" id="avatar-upload" class="d-none" accept="image/*" @change="onAvatarChange">
								</div>
								<h6 class="fw-bold mb-0">{{ form.fullName }}</h6>
								<span class="text-muted small">{{ form.email }}</span>
							</div>
							<!-- Tabs -->
							<div class="nav flex-column gap-1">
								<a v-for="tab in sidebarTabs" :key="tab.value"
									href="#" @click.prevent="activeTab = tab.value"
									class="nav-link rounded-3 px-3 py-2 d-flex align-items-center gap-2 sidebar-tab"
									:class="activeTab === tab.value ? 'active-tab' : 'text-dark'">
									<i :class="tab.icon" class="flex-shrink-0" style="width: 18px; text-align: center;"></i>
									<span class="small fw-medium">{{ tab.label }}</span>
								</a>
							</div>
						</div>
					</div>
				</div>

				<!-- RIGHT: Content -->
				<div class="col-lg-9">
					<!-- TAB: Thông tin cá nhân -->
					<div v-if="activeTab === 'personal'">
						<div class="card border-0 shadow-sm mb-4">
							<div class="card-header bg-white py-3 border-bottom">
								<h6 class="fw-bold mb-0"><i class="fa-solid fa-user-pen text-primary me-2"></i>{{ $t('settings.basicInfo') }}</h6>
							</div>
							<div class="card-body p-4">
								<div class="row g-3">
									<div class="col-md-6">
										<label class="form-label small fw-bold">{{ $t('settings.fullName') }} <span class="text-danger">*</span></label>
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-user text-muted small"></i></span>
											<input type="text" class="form-control" v-model="form.fullName" :placeholder="$t('settings.fullNamePlaceholder')">
										</div>
									</div>
									<div class="col-md-6">
										<label class="form-label small fw-bold">{{ $t('settings.dob') }}</label>
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-cake-candles text-muted small"></i></span>
											<input type="date" class="form-control" v-model="form.dob">
										</div>
									</div>
									<div class="col-md-6">
										<label class="form-label small fw-bold">{{ $t('settings.gender') }}</label>
										<select class="form-select" v-model="form.gender">
											<option value="">{{ $t('settings.selectGender') }}</option>
											<option value="nam">{{ $t('settings.genderOptions.male') }}</option>
											<option value="nu">{{ $t('settings.genderOptions.female') }}</option>
											<option value="khac">{{ $t('settings.genderOptions.other') }}</option>
										</select>
									</div>
									<div class="col-md-6">
										<label class="form-label small fw-bold">{{ $t('settings.idNumber') }}</label>
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-id-card text-muted small"></i></span>
											<input type="text" class="form-control" v-model="form.idNumber" :placeholder="$t('settings.idPlaceholder')">
										</div>
									</div>
								</div>
							</div>
						</div>

						<!-- Liên hệ -->
						<div class="card border-0 shadow-sm mb-4">
							<div class="card-header bg-white py-3 border-bottom">
								<h6 class="fw-bold mb-0"><i class="fa-solid fa-address-book text-success me-2"></i>{{ $t('settings.contactInfo') }}</h6>
							</div>
							<div class="card-body p-4">
								<div class="row g-3">
									<div class="col-md-6">
										<label class="form-label small fw-bold">{{ $t('settings.email') }} <span class="text-danger">*</span></label>
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-envelope text-muted small"></i></span>
											<input
												type="email"
												class="form-control bg-light"
												v-model="form.email"
												:placeholder="$t('settings.email')"
												readonly
												disabled>
										</div>
										<div class="form-text small">
											<i class="fa-solid fa-lock text-muted me-1"></i>{{ $t('settings.emailReadonlyHint') }}
										</div>
										<div class="form-text small"><i class="fa-solid fa-circle-check text-success me-1"></i>{{ $t('settings.verified') }}</div>
									</div>
									<div class="col-md-6">
										<label class="form-label small fw-bold">{{ $t('settings.phone') }} <span class="text-danger">*</span></label>
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-phone text-muted small"></i></span>
											<input type="tel" class="form-control" v-model="form.phone" :placeholder="$t('settings.phone')">
										</div>
									</div>
								</div>
							</div>
						</div>

						<!-- Địa chỉ -->
						<div class="card border-0 shadow-sm mb-4">
							<div class="card-header bg-white py-3 border-bottom">
								<div class="d-flex align-items-center justify-content-between">
									<h6 class="fw-bold mb-0"><i class="fa-solid fa-map-location-dot text-danger me-2"></i>{{ $t('settings.addressTitle') }}</h6>
									<span class="badge bg-info-subtle text-info px-3 py-2 small">
										<i class="fa-solid fa-robot me-1"></i>{{ $t('settings.aiBadge') }}
									</span>
								</div>
							</div>
							<div class="card-body p-4">
								<div class="alert alert-light border rounded-3 d-flex align-items-start gap-2 mb-4" role="alert">
									<i class="fa-solid fa-circle-info text-primary mt-1 flex-shrink-0"></i>
									<div class="small" v-html="$t('settings.addressAlert')">
									</div>
								</div>
								<div class="row g-3">
									<div class="col-md-6">
										<label class="form-label small fw-bold">{{ $t('settings.province') }} <span class="text-danger">*</span></label>
										<select class="form-select" v-model="form.province" @change="onProvinceChange">
											<option value="">{{ $t('settings.selectProvince') }}</option>
											<option v-for="p in provinces" :key="p.code" :value="p.code">{{ p.name }}</option>
										</select>
									</div>
									<div class="col-md-6">
										<label class="form-label small fw-bold">{{ $t('settings.ward') }}</label>
										<select class="form-select" v-model="form.ward">
											<option value="">{{ $t('settings.selectWard') }}</option>
											<option v-for="w in filteredWards" :key="w.code" :value="w.code">{{ w.name }}</option>
										</select>
									</div>
									<div class="col-md-12">
										<label class="form-label small fw-bold">{{ $t('settings.street') }}</label>
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-road text-muted small"></i></span>
											<input type="text" class="form-control" v-model="form.street" :placeholder="$t('settings.streetPlaceholder')">
											<span class="input-group-text bg-white" v-if="geocoding">
												<span class="spinner-border spinner-border-sm text-primary" role="status"></span>
											</span>
										</div>
										<div class="form-text small" v-if="geocodeStatus">
											<i :class="geocodeStatus === 'success' ? 'fa-solid fa-check-circle text-success' : 'fa-solid fa-info-circle text-warning'" class="me-1"></i>
											<span :class="geocodeStatus === 'success' ? 'text-success' : 'text-warning'">{{ geocodeMessage }}</span>
										</div>
									</div>
									<div class="col-12">
										<label class="form-label small fw-bold">{{ $t('settings.fullAddress') }}</label>
										<div class="bg-light rounded-3 p-3 border">
											<i class="fa-solid fa-location-dot text-danger me-2"></i>
											<span class="small" :class="fullAddress ? 'text-dark' : 'text-muted'">{{ fullAddress || $t('settings.addressIncomplete') }}</span>
										</div>
									</div>

									<!-- Mini Map -->
									<div class="col-12" v-if="form.province">
										<label class="form-label small fw-bold">
											<i class="fa-solid fa-map me-1 text-success"></i>{{ $t('settings.mapPin') }}
											<span class="text-muted fw-normal ms-1">{{ $t('settings.dragPin') }}</span>
										</label>
										<div id="map-container" class="map-wrapper rounded-3 border overflow-hidden"></div>
									</div>

									<!-- Tọa độ (Readonly) -->
									<div class="col-md-6" v-if="form.latitude">
										<label class="form-label small fw-bold">
											<i class="fa-solid fa-crosshairs text-primary me-1"></i>{{ $t('settings.latitude') }}
										</label>
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-lock text-muted small"></i></span>
											<input type="text" class="form-control bg-light" :value="form.latitude" readonly>
										</div>
									</div>
									<div class="col-md-6" v-if="form.longitude">
										<label class="form-label small fw-bold">
											<i class="fa-solid fa-crosshairs text-primary me-1"></i>{{ $t('settings.longitude') }}
										</label>
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-lock text-muted small"></i></span>
											<input type="text" class="form-control bg-light" :value="form.longitude" readonly>
										</div>
									</div>
								</div>
							</div>
						</div>

						<!-- Giới thiệu bản thân -->
						<div class="card border-0 shadow-sm mb-4">
							<div class="card-header bg-white py-3 border-bottom">
								<h6 class="fw-bold mb-0"><i class="fa-solid fa-pen-nib text-info me-2"></i>{{ $t('settings.bioTitle') }}</h6>
							</div>
							<div class="card-body p-4">
								<textarea class="form-control" rows="4" v-model="form.bio" :placeholder="$t('settings.bioPlaceholder')" maxlength="500"></textarea>
								<div class="form-text text-end small">{{ $t('settings.charCount', { count: form.bio.length }) }}</div>
							</div>
						</div>

						<!-- Save -->
						<div class="d-flex justify-content-end gap-2">
							<button type="button" class="btn btn-light rounded-pill px-4" @click="resetForm">
								<i class="fa-solid fa-rotate-left me-1"></i>{{ $t('common.reset') }}
							</button>
							<button type="button" class="btn btn-primary rounded-pill px-4 shadow-sm" @click="savePersonalInfo" :disabled="!canManageAccount || savingPersonal">
								<i class="fa-solid fa-save me-1"></i>{{ savingPersonal ? $t('settings.saving') : $t('settings.saveInfo') }}
							</button>
						</div>
					</div>

					<!-- TAB: Đổi mật khẩu -->
					<div v-if="activeTab === 'password'">
						<div class="card border-0 shadow-sm">
							<div class="card-header bg-white py-3 border-bottom">
								<h6 class="fw-bold mb-0"><i class="fa-solid fa-shield-halved text-warning me-2"></i>{{ $t('settings.tabs.password') }}</h6>
							</div>
							<div class="card-body p-4">
								<div class="row justify-content-center">
									<div class="col-md-8 col-lg-7">
										<div class="text-center mb-4">
											<div class="password-icon mx-auto mb-3">
												<i class="fa-solid fa-lock"></i>
											</div>
											<p class="text-muted small">{{ $t('settings.passwordHint') }}</p>
										</div>

										<div class="mb-3" v-if="hasExistingPassword">
											<label class="form-label small fw-bold">{{ $t('settings.currentPassword') }} <span class="text-danger">*</span></label>
											<div class="input-group">
												<span class="input-group-text bg-light"><i class="fa-solid fa-key text-muted small"></i></span>
												<input :type="showCurrentPw ? 'text' : 'password'" class="form-control" v-model="passwordForm.current" :placeholder="$t('settings.currentPwPlaceholder')">
												<button class="btn btn-light border" type="button" @click="showCurrentPw = !showCurrentPw">
													<i :class="showCurrentPw ? 'fa-solid fa-eye-slash' : 'fa-solid fa-eye'" class="text-muted small"></i>
												</button>
											</div>
										</div>

										<div class="mb-3">
											<label class="form-label small fw-bold">{{ $t('settings.newPassword') }} <span class="text-danger">*</span></label>
											<div class="input-group">
												<span class="input-group-text bg-light"><i class="fa-solid fa-lock text-muted small"></i></span>
												<input :type="showNewPw ? 'text' : 'password'" class="form-control" v-model="passwordForm.newPassword" :placeholder="$t('settings.newPwPlaceholder')">
												<button class="btn btn-light border" type="button" @click="showNewPw = !showNewPw">
													<i :class="showNewPw ? 'fa-solid fa-eye-slash' : 'fa-solid fa-eye'" class="text-muted small"></i>
												</button>
											</div>
											<!-- Strength -->
											<div class="mt-2" v-if="passwordForm.newPassword && (!hasExistingPassword || passwordForm.newPassword !== passwordForm.current)">
												<div class="d-flex gap-1 mb-1">
													<div v-for="i in 4" :key="i" class="flex-grow-1 rounded-pill" style="height:4px"
														:class="i <= passwordStrength.level ? passwordStrength.colorClass : 'bg-light'"></div>
												</div>
												<span class="small" :class="passwordStrength.textClass">{{ passwordStrength.label }}</span>
											</div>
											<div class="form-text small text-danger" v-if="hasExistingPassword && passwordForm.newPassword && passwordForm.newPassword === passwordForm.current">
												<i class="fa-solid fa-exclamation-triangle me-1"></i>{{ $t('settings.pwSameAsCurrent') }}
											</div>
										</div>

										<div class="mb-4">
											<label class="form-label small fw-bold">{{ $t('settings.confirmPassword') }} <span class="text-danger">*</span></label>
											<div class="input-group">
												<span class="input-group-text bg-light"><i class="fa-solid fa-lock text-muted small"></i></span>
												<input :type="showConfirmPw ? 'text' : 'password'" class="form-control" v-model="passwordForm.confirm" :placeholder="$t('settings.confirmPwPlaceholder')">
												<button class="btn btn-light border" type="button" @click="showConfirmPw = !showConfirmPw">
													<i :class="showConfirmPw ? 'fa-solid fa-eye-slash' : 'fa-solid fa-eye'" class="text-muted small"></i>
												</button>
											</div>
											<div class="form-text small text-danger" v-if="passwordForm.confirm && passwordForm.confirm !== passwordForm.newPassword">
												<i class="fa-solid fa-exclamation-triangle me-1"></i>{{ $t('settings.pwNotMatch') }}
											</div>
											<div class="form-text small text-success" v-if="passwordForm.confirm && passwordForm.confirm === passwordForm.newPassword && passwordForm.newPassword">
												<i class="fa-solid fa-check-circle me-1"></i>{{ $t('settings.pwMatch') }}
											</div>
										</div>

										<button type="button" class="btn btn-warning rounded-pill px-4 w-100 shadow-sm" @click="changePassword" :disabled="!canManageAccount || !canChangePassword || savingPassword">
											<i class="fa-solid fa-shield-halved me-1"></i>{{ savingPassword ? $t('settings.processing') : $t('settings.changePasswordBtn') }}
										</button>
									</div>
								</div>
							</div>
						</div>
					</div>

					<!-- TAB: Tùy chọn thông báo -->
					<div v-if="activeTab === 'notifications'">
						<div class="card border-0 shadow-sm">
							<div class="card-header bg-white py-3 border-bottom">
								<h6 class="fw-bold mb-0"><i class="fa-solid fa-bell text-info me-2"></i>{{ $t('settings.notiOptions') }}</h6>
							</div>
							<div class="card-body p-4">
								<div class="notification-item d-flex align-items-center justify-content-between py-3 border-bottom" v-for="noti in notificationSettings" :key="noti.key">
									<div class="d-flex align-items-center gap-3">
										<div class="noti-icon rounded-circle d-flex align-items-center justify-content-center flex-shrink-0" :style="{ background: noti.bgColor }">
											<i :class="noti.icon" :style="{ color: noti.iconColor }"></i>
										</div>
										<div>
											<div class="fw-bold small">{{ $t(`settings.notiTitles.${noti.key}`) }}</div>
											<div class="text-muted" style="font-size: 12px;">{{ $t(`settings.notiDesc.${noti.key}`) }}</div>
										</div>
									</div>
									<div class="form-check form-switch mb-0">
										<input class="form-check-input" type="checkbox" role="switch" v-model="noti.enabled" style="width: 42px; height: 22px;">
									</div>
								</div>
								<div class="mt-4 text-end">
									<button class="btn btn-primary rounded-pill px-4 shadow-sm" @click="saveNotifications" :disabled="!canManageAccount">
										<i class="fa-solid fa-save me-1"></i>{{ $t('settings.saveNoti') }}
									</button>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue';
import api from '@/services/api.js';
import { hasPermission } from '@/utils/permissions';

const createInitialForm = () => ({
	fullName: '',
	email: '',
	phone: '',
	dob: '',
	gender: '',
	idNumber: '',
	province: '',
	ward: '',
	street: '',
	latitude: null,
	longitude: null,
	bio: '',
	avatarPreview: null,
});

export default {
	name: 'ThongTinCaNhan',
	inject: ['toast'],
	components: { PageHeader },
	data() {
		return {
			activeTab: 'personal',
			savingPersonal: false,
			savingPassword: false,
			showCurrentPw: false,
			showNewPw: false,
			showConfirmPw: false,
			map: null,
			marker: null,
			geocoding: false,
			geocodeStatus: '',
			geocodeMessage: '',
			geocodeTimer: null,
			localAlertMessage: '',
			localAlertSuccess: false,
			isDataLoading: true,
			form: createInitialForm(),
			avatarFile: null,
			passwordForm: {
				current: '',
				newPassword: '',
				confirm: '',
			},
			hasExistingPassword: true,
			provinces: [],
			wards: [],
			notificationSettings: [
				{ key: 'campaign_new', title: 'Chiến dịch mới', description: 'Nhận thông báo khi có chiến dịch mới phù hợp với kỹ năng', enabled: true, icon: 'fa-solid fa-bullhorn', bgColor: '#dbeafe', iconColor: '#2563eb' },
				{ key: 'campaign_assign', title: 'Phân công chiến dịch', description: 'Nhận thông báo khi được phân công vào chiến dịch', enabled: true, icon: 'fa-solid fa-clipboard-check', bgColor: '#d1fae5', iconColor: '#059669' },
				{ key: 'campaign_remind', title: 'Nhắc nhở chiến dịch', description: 'Nhận nhắc nhở trước khi chiến dịch bắt đầu', enabled: true, icon: 'fa-solid fa-clock', bgColor: '#fef3c7', iconColor: '#d97706' },
				{ key: 'rating', title: 'Đánh giá mới', description: 'Nhận thông báo khi có đánh giá mới từ kiểm duyệt viên', enabled: true, icon: 'fa-solid fa-star', bgColor: '#fce7f3', iconColor: '#db2777' },
				{ key: 'email_digest', title: 'Email tổng hợp hàng tuần', description: 'Nhận email tổng hợp hoạt động mỗi tuần', enabled: false, icon: 'fa-solid fa-envelope', bgColor: '#e0e7ff', iconColor: '#4f46e5' },
				{ key: 'ai_suggest', title: 'Gợi ý AI', description: 'Nhận thông báo khi AI gợi ý chiến dịch phù hợp', enabled: true, icon: 'fa-solid fa-robot', bgColor: '#f3e8ff', iconColor: '#7c3aed' },
			],
		};
	},
	watch: {
		activeTab(newValue) {
			if (newValue === 'personal') {
				this.$nextTick(() => {
					setTimeout(() => this.ensureMapReady(), 100);
				});
			}
		},
		'form.ward'(newVal) {
			if (!this.isDataLoading) this.updateMapFromWard(newVal);
		},
		'form.province'() {
			if (!this.isDataLoading) {
				this.$nextTick(() => {
					if (!this.form.ward) {
						const prov = this.provinces.find((item) => item.code === this.form.province);
						if (prov) this.updateMapPosition(prov.lat, prov.lng);
					}
				});
			}
		},
		fullAddress(newVal) {
			if (this.isDataLoading) return;
			if (this.geocodeTimer) clearTimeout(this.geocodeTimer);
			if (newVal && this.form.street && this.form.province) {
				this.geocodeTimer = setTimeout(() => {
					this.geocodeAddress();
				}, 800);
			}
		},
	},
	computed: {
		sidebarTabs() {
			return [
				{ label: this.$t('settings.tabs.personal'), value: 'personal', icon: 'fa-solid fa-user' },
				{ label: this.$t('settings.tabs.password'), value: 'password', icon: 'fa-solid fa-lock' },
				{ label: this.$t('settings.tabs.notifications'), value: 'notifications', icon: 'fa-solid fa-bell' },
			];
		},
		filteredWards() {
			return this.wards;
		},
		fullAddress() {
			const parts = [];
			if (this.form.street) parts.push(this.form.street);
			const ward = this.wards.find((item) => item.code === this.form.ward);
			if (ward) parts.push(ward.name);
			const province = this.provinces.find((item) => item.code === this.form.province);
			if (province) parts.push(province.name);
			return parts.join(', ');
		},
		passwordStrength() {
			const pw = this.passwordForm.newPassword;
			if (!pw) return { level: 0, label: '', colorClass: '', textClass: '' };

			let score = 0;
			if (pw.length >= 8) score++;
			if (/[A-Z]/.test(pw)) score++;
			if (/[0-9]/.test(pw)) score++;
			if (/[^A-Za-z0-9]/.test(pw)) score++;

			return {
				level: score,
				label: this.$t(`settings.pwStrength.${score}`),
				colorClass: score <= 1 ? 'bg-danger' : score === 2 ? 'bg-warning' : score === 3 ? 'bg-info' : 'bg-success',
				textClass: score <= 1 ? 'text-danger' : score === 2 ? 'text-warning' : score === 3 ? 'text-info' : 'text-success',
			};
		},
		canChangePassword() {
			const hasCurrentPassword = this.hasExistingPassword ? Boolean(this.passwordForm.current) : true;
			const isDifferentFromCurrent = this.hasExistingPassword
				? this.passwordForm.newPassword !== this.passwordForm.current
				: true;

			return hasCurrentPassword
				&& this.passwordForm.newPassword
				&& this.passwordForm.newPassword.length >= 8
				&& this.passwordForm.confirm === this.passwordForm.newPassword
				&& isDifferentFromCurrent;
		},
		canManageAccount() {
			try {
				const user = JSON.parse(localStorage.getItem('user') || 'null');
				return hasPermission(user, 'account_center.manage');
			} catch (_error) {
				return false;
			}
		},
	},
	async mounted() {
		await this.loadCatalogs();
		await this.loadUserData();

		if (!document.getElementById('leaflet-css')) {
			const link = document.createElement('link');
			link.id = 'leaflet-css';
			link.rel = 'stylesheet';
			link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
			document.head.appendChild(link);
		}

		if (!window.L) {
			const script = document.createElement('script');
			script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
			script.onload = () => {
				this.$nextTick(() => this.ensureMapReady());
			};
			document.head.appendChild(script);
		} else {
			this.$nextTick(() => this.ensureMapReady());
		}
	},
	beforeUnmount() {
		if (this.map) {
			this.map.remove();
			this.map = null;
		}
	},
	methods: {
		async loadUserData() {
			this.isDataLoading = true;
			try {
				const res = await api.get('/nguoi-dung/thong-tin');
				if (res.data.status === 1) {
					const d = res.data.data;
					this.form.fullName = d.ho_ten || '';
					this.form.email = d.email || '';
					this.form.phone = d.so_dien_thoai || '';
					this.form.dob = d.ngay_sinh || '';
					this.form.gender = d.gioi_tinh || '';
					this.form.idNumber = d.so_cccd || '';
					this.form.bio = d.gioi_thieu || '';
					this.form.street = d.dia_chi_duong || '';
					this.form.latitude = d.vi_do;
					this.form.longitude = d.kinh_do;
					this.form.avatarPreview = d.anh_dai_dien || null;
					this.hasExistingPassword = Boolean(d.co_mat_khau);
					this.avatarFile = null;

					if (d.tinh_thanh_id) {
						this.form.province = String(d.tinh_thanh_id);
						await this.loadWards(this.form.province);
					}
					if (d.phuong_xa_id) {
						this.form.ward = String(d.phuong_xa_id);
					}
					if (d.tuy_chon_thong_bao) {
						this.notificationSettings.forEach((noti) => {
							if (d.tuy_chon_thong_bao[noti.key] !== undefined) {
								noti.enabled = Boolean(Number(d.tuy_chon_thong_bao[noti.key]) || d.tuy_chon_thong_bao[noti.key] === true);
							}
						});
					}
				}
			} catch (e) {
				console.error('Lỗi tải thông tin:', e);
			} finally {
				setTimeout(() => {
					this.isDataLoading = false;
					this.ensureMapReady();
				}, 300);
			}
		},
		ensureMapReady() {
			if (!this.form.province) return;

			if (!this.map) {
				this.initMap();
				return;
			}

			setTimeout(() => {
				if (this.map) {
					this.map.invalidateSize();
					if (this.form.latitude && this.form.longitude) {
						this.updateMapPosition(parseFloat(this.form.latitude), parseFloat(this.form.longitude));
					}
				}
			}, 250);
		},
		initMap() {
			if (this.map) {
				setTimeout(() => this.map?.invalidateSize(), 250);
				return;
			}
			const container = document.getElementById('map-container');
			if (!container || !window.L) return;

			let lat = 16.0544;
			let lng = 108.2022;

			if (this.form.latitude && this.form.longitude) {
				lat = parseFloat(this.form.latitude);
				lng = parseFloat(this.form.longitude);
			} else {
				const ward = this.wards.find((item) => item.code === this.form.ward);
				if (ward) {
					lat = ward.lat;
					lng = ward.lng;
				} else {
					const prov = this.provinces.find((item) => item.code === this.form.province);
					if (prov) {
						lat = prov.lat;
						lng = prov.lng;
					}
				}
			}

			this.map = window.L.map(container, {
				center: [lat, lng],
				zoom: 15,
				zoomControl: true,
				attributionControl: false,
			});

			window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
				maxZoom: 19,
			}).addTo(this.map);

			const pinIcon = window.L.divIcon({
				html: '<div class="custom-pin"><i class="fa-solid fa-location-dot"></i></div>',
				iconSize: [36, 36],
				iconAnchor: [18, 36],
				className: 'custom-pin-wrapper',
			});

			this.marker = window.L.marker([lat, lng], {
				draggable: true,
				icon: pinIcon,
			}).addTo(this.map);

			this.form.latitude = lat.toFixed(7);
			this.form.longitude = lng.toFixed(7);

			this.marker.on('dragend', (e) => {
				const pos = e.target.getLatLng();
				this.form.latitude = pos.lat.toFixed(7);
				this.form.longitude = pos.lng.toFixed(7);
			});

			setTimeout(() => {
				if (this.map) {
					this.map.invalidateSize();
				}
			}, 300);
		},
		updateMapPosition(lat, lng) {
			if (this.map && this.marker && Number.isFinite(lat) && Number.isFinite(lng)) {
				this.map.setView([lat, lng], 15, { animate: true });
				this.marker.setLatLng([lat, lng]);
				this.form.latitude = lat.toFixed(7);
				this.form.longitude = lng.toFixed(7);
				this.$nextTick(() => {
					setTimeout(() => this.map?.invalidateSize(), 100);
				});
			}
		},
		updateMapFromWard(wardCode) {
			const ward = this.wards.find((item) => item.code === wardCode);
			if (ward) {
				this.$nextTick(() => this.updateMapPosition(ward.lat, ward.lng));
			}
		},
		async geocodeAddress() {
			this.geocoding = true;
			this.geocodeStatus = '';
			this.geocodeMessage = '';

			try {
				const street = this.form.street.trim();
				const cleanStreet = street.replace(/^(?:[sS]ố|[nN]gõ|[hH]ẻm|[kK]iệt|[nN]gách|[lL]ô)?\s*\d+[a-zA-Z]?(\/\d+[a-zA-Z]?)*\s*,?\s*/, '').trim();
				const ward = this.wards.find((item) => item.code === this.form.ward);
				const province = this.provinces.find((item) => item.code === this.form.province);
				const wardName = ward ? ward.name : '';
				const cityName = province ? province.name : '';

				const queries = [];
				if (street && wardName && cityName) queries.push(`${street}, ${wardName}, ${cityName}`);
				if (cleanStreet && cleanStreet !== street && wardName && cityName) queries.push(`${cleanStreet}, ${wardName}, ${cityName}`);
				if (cleanStreet && cityName) queries.push(`${cleanStreet}, ${cityName}`);
				if (wardName && cityName) queries.push(`${wardName}, ${cityName}`);
				if (cityName) queries.push(cityName);

				let data = null;
				for (const query of queries) {
					const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&countrycodes=vn&limit=3`;
					const res = await fetch(url, { headers: { 'Accept-Language': 'vi' } });
					data = await res.json();
					if (data?.length) break;
				}

				if (data?.length) {
					const lat = parseFloat(data[0].lat);
					const lng = parseFloat(data[0].lon);
					this.updateMapPosition(lat, lng);
					if (this.map) this.map.setZoom(17);
					this.geocodeStatus = 'success';
					this.geocodeMessage = `${this.$t('settings.geocodeFound')} ${data[0].display_name.substring(0, 100)}`;
				} else {
					this.geocodeStatus = 'fallback';
					this.geocodeMessage = this.$t('settings.geocodeFallbackMap');
				}
			} catch (_error) {
				this.geocodeStatus = 'fallback';
				this.geocodeMessage = this.$t('settings.geocodeError');
			} finally {
				this.geocoding = false;
			}
		},
		async onProvinceChange() {
			this.form.ward = '';
			if (this.form.province) {
				await this.loadWards(this.form.province);
				this.$nextTick(() => this.ensureMapReady());
			} else {
				this.wards = [];
			}
		},
		async loadCatalogs() {
			try {
				const res = await api.get('/danh-muc/tinh-thanh');
				if (res.data.status === 1) {
					this.provinces = res.data.data.map((item) => ({
						code: String(item.id),
						name: item.ten,
						lat: parseFloat(item.vi_do || 0),
						lng: parseFloat(item.kinh_do || 0),
					}));
				}
			} catch (e) {
				console.error('Lỗi tải danh mục tĩnh(thành):', e);
			}
		},
		async loadWards(tinhThanhId) {
			try {
				const res = await api.get('/danh-muc/phuong-xa', { params: { tinh_thanh_id: tinhThanhId } });
				if (res.data.status === 1) {
					this.wards = res.data.data.map((item) => ({
						code: String(item.id),
						name: item.ten,
						lat: parseFloat(item.vi_do || 0),
						lng: parseFloat(item.kinh_do || 0),
					}));
				}
			} catch (e) {
				console.error('Lỗi tải danh mục phường/xã:', e);
			}
		},
		onAvatarChange(e) {
			const file = e.target.files[0];
			if (!file) return;

			this.avatarFile = file;
			const reader = new FileReader();
			reader.onload = (ev) => {
				this.form.avatarPreview = ev.target.result;
			};
			reader.readAsDataURL(file);
		},
		async savePersonalInfo() {
			this.savingPersonal = true;
			this.localAlertMessage = '';

			try {
				const notiPrefs = {};
				this.notificationSettings.forEach((item) => {
					notiPrefs[item.key] = item.enabled;
				});

				const formData = new FormData();
				formData.append('ho_ten', this.form.fullName);
				formData.append('so_dien_thoai', this.form.phone || '');
				formData.append('ngay_sinh', this.form.dob || '');
				formData.append('gioi_tinh', this.form.gender || '');
				formData.append('so_cccd', this.form.idNumber || '');
				formData.append('gioi_thieu', this.form.bio || '');
				formData.append('tinh_thanh_id', this.form.province || '');
				formData.append('phuong_xa_id', this.form.ward || '');
				formData.append('dia_chi_duong', this.form.street || '');
				formData.append('vi_do', this.form.latitude || '');
				formData.append('kinh_do', this.form.longitude || '');
				Object.entries(notiPrefs).forEach(([key, value]) => {
					formData.append(`tuy_chon_thong_bao[${key}]`, value ? '1' : '0');
				});
				if (this.avatarFile) {
					formData.append('anh_dai_dien', this.avatarFile);
				}

				const res = await api.post('/nguoi-dung/cap-nhat-thong-tin', formData);
				if (res.data.status === 1) {
					const freshUser = res.data.data || {};
					this.form.avatarPreview = freshUser.anh_dai_dien || this.form.avatarPreview;
					this.avatarFile = null;

					if (this.toast) {
						this.toast.showToast('success', 'Thành công!', res.data.message);
					} else {
						this.localAlertMessage = res.data.message;
						this.localAlertSuccess = true;
					}

					const user = JSON.parse(localStorage.getItem('user') || '{}');
					user.ho_ten = this.form.fullName;
					if (freshUser.anh_dai_dien) user.anh_dai_dien = freshUser.anh_dai_dien;
					localStorage.setItem('user', JSON.stringify(user));
				}
			} catch (error) {
				this.localAlertSuccess = false;
				let errMsg = 'Không thể kết nối server.';
				if (error.response?.data) {
					const data = error.response.data;
					if (data.errors) {
						const firstKey = Object.keys(data.errors)[0];
						errMsg = data.errors[firstKey][0];
					} else {
						errMsg = data.message || 'Lỗi cập nhật.';
					}
				}

				if (this.toast) {
					this.toast.showToast('error', 'Lỗi', errMsg);
				} else {
					this.localAlertMessage = errMsg;
				}
			} finally {
				this.savingPersonal = false;
			}
		},
		async changePassword() {
			this.savingPassword = true;
			this.localAlertMessage = '';

			try {
				const payload = {
					mat_khau_moi: this.passwordForm.newPassword,
					mat_khau_moi_confirmation: this.passwordForm.confirm,
				};

				if (this.hasExistingPassword) {
					payload.mat_khau_cu = this.passwordForm.current;
				}

				const res = await api.post('/nguoi-dung/doi-mat-khau', payload);
				if (res.data.status === 1) {
					if (this.toast) {
						this.toast.showToast('success', 'Thành công!', res.data.message);
					} else {
						this.localAlertMessage = res.data.message;
						this.localAlertSuccess = true;
					}
					this.hasExistingPassword = true;
					this.passwordForm = { current: '', newPassword: '', confirm: '' };
				}
			} catch (error) {
				if (error.response?.data) {
					const data = error.response.data;
					if (data.errors) {
						const firstKey = Object.keys(data.errors)[0];
						this.localAlertMessage = data.errors[firstKey][0];
					} else {
						this.localAlertMessage = data.message || 'Lỗi đổi mật khẩu.';
					}
				} else {
					this.localAlertMessage = 'Không thể kết nối server.';
				}
				this.localAlertSuccess = false;
			} finally {
				this.savingPassword = false;
			}
		},
		saveNotifications() {
			this.savePersonalInfo();
		},
		async resetForm() {
			this.form = createInitialForm();
			this.avatarFile = null;
			await this.loadUserData();
			this.$nextTick(() => this.ensureMapReady());
		},
	},
};
</script>

<style scoped>
/* Avatar */
.avatar-wrapper {
	width: 90px;
	height: 90px;
}

.avatar-circle {
	width: 90px;
	height: 90px;
	border-radius: 50%;
	background: linear-gradient(135deg, #0d6efd, #6610f2);
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-size: 32px;
	overflow: hidden;
}

.avatar-edit-btn {
	position: absolute;
	bottom: 0;
	right: 0;
	width: 30px;
	height: 30px;
	border-radius: 50%;
	background: #0d6efd;
	color: white;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	cursor: pointer;
	border: 3px solid white;
	transition: transform 0.2s;
}
.avatar-edit-btn:hover { transform: scale(1.1); }

/* Sidebar Tabs */
.sidebar-tab {
	transition: all 0.15s ease;
	text-decoration: none;
}
.sidebar-tab:hover { background: rgba(13, 110, 253, 0.05); }
.active-tab {
	background: rgba(13, 110, 253, 0.08) !important;
	color: #0d6efd !important;
	font-weight: 600 !important;
}

/* Password Icon */
.password-icon {
	width: 72px;
	height: 72px;
	border-radius: 50%;
	background: linear-gradient(135deg, #ffc107, #fd7e14);
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-size: 28px;
}

/* Notification */
.noti-icon {
	width: 40px;
	height: 40px;
	min-width: 40px;
	font-size: 16px;
}

.notification-item { transition: background 0.15s; }
.notification-item:hover { background: rgba(0,0,0,0.015); }
.notification-item:last-child { border-bottom: none !important; }

/* Object fit */
.object-fit-cover { object-fit: cover; }

/* Map */
.map-wrapper {
	height: 300px;
	width: 100%;
	z-index: 0;
}
</style>

<style>
/* Leaflet custom pin - needs to be global (not scoped) */
.custom-pin-wrapper {
	background: none !important;
	border: none !important;
}
.custom-pin {
	font-size: 36px;
	color: #dc3545;
	filter: drop-shadow(0 2px 4px rgba(0,0,0,0.4));
	animation: pin-bounce 0.4s ease;
	transition: transform 0.15s;
	cursor: grab;
}
.custom-pin:hover {
	transform: scale(1.2);
}
@keyframes pin-bounce {
	0% { transform: translateY(-20px); opacity: 0; }
	60% { transform: translateY(4px); }
	100% { transform: translateY(0); opacity: 1; }
}
</style>
