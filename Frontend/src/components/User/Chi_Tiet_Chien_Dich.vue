<template>
	<div class="bg-light min-vh-100 pb-5">
		<div class="campaign-cover" :style="{ background: campaign.bannerStyle }">
			<div class="container h-100 d-flex align-items-end pb-4">
				<nav aria-label="breadcrumb">
					<ol class="breadcrumb mb-0">
						<li class="breadcrumb-item"><router-link to="/" class="text-white text-decoration-none opacity-75">{{ $t('common.home') }}</router-link></li>
						<li class="breadcrumb-item"><router-link to="/danh-sach-chien-dich" class="text-white text-decoration-none opacity-75">{{ $t('campaignDetail.explore') }}</router-link></li>
						<li class="breadcrumb-item active text-white" aria-current="page">{{ $t('campaignDetail.title') }}</li>
					</ol>
				</nav>
			</div>
		</div>

		<div class="container campaign-content">
			<div v-if="loading" class="card border-0 shadow-sm rounded-4 p-5 text-center">
				<div class="spinner-border text-primary mb-3" role="status"></div>
				<p class="mb-0 text-muted">{{ $t('common.loading') }}</p>
			</div>

			<div v-else-if="!campaign.id" class="card border-0 shadow-sm rounded-4 p-5 text-center">
				<i class="fa-solid fa-circle-exclamation fs-1 text-warning mb-3"></i>
				<h4 class="fw-bold mb-2">{{ $t('campaignDetail.notFoundTitle') }}</h4>
				<p class="text-muted mb-3">{{ errorMessage || $t('campaignDetail.notFoundDesc') }}</p>
				<router-link to="/danh-sach-chien-dich" class="btn btn-primary rounded-pill px-4">{{ $t('campaignDetail.backToList') }}</router-link>
			</div>

			<div v-else class="row g-4">
				<div class="col-lg-8">
					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<div class="d-flex flex-wrap gap-2 mb-3">
								<span class="badge border border-primary text-primary px-3 py-2 rounded-pill">{{ campaign.categoryLabel }}</span>
								<span class="badge px-3 py-2 rounded-pill" :class="statusBadgeClass(campaign.status)">{{ campaign.statusLabel }}</span>
								<span v-if="registration.statusLabel" class="badge bg-light text-dark border px-3 py-2 rounded-pill">{{ registration.statusLabel }}</span>
							</div>
							<h1 class="fw-bold mb-3 display-6 lh-base">{{ campaign.title }}</h1>
							<div class="row g-3 text-muted mt-1">
								<div class="col-sm-6 d-flex align-items-center gap-3">
									<div class="icon-circle bg-danger text-white"><i class="fa-solid fa-location-dot"></i></div>
									<div>
										<div class="small fw-semibold text-dark">{{ $t('campaignDetail.locationLabel') }}</div>
										<div class="small">{{ campaign.location }}</div>
									</div>
								</div>
								<div class="col-sm-6 d-flex align-items-center gap-3">
									<div class="icon-circle bg-primary text-white"><i class="fa-regular fa-calendar"></i></div>
									<div>
										<div class="small fw-semibold text-dark">{{ $t('campaignDetail.startDateLabel') }}</div>
										<div class="small">{{ campaign.dateRange }}</div>
									</div>
								</div>
							</div>
						</div>
					</div>

					<div v-if="campaign.images.length > 0" class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<div class="d-flex align-items-center justify-content-between mb-3">
								<h4 class="fw-bold mb-0"><i class="fa-regular fa-images text-primary me-2"></i>Hình ảnh chiến dịch</h4>
								<span class="badge bg-light text-dark border">{{ campaign.images.length }} ảnh</span>
							</div>
							<div class="rounded-4 overflow-hidden border mb-3">
								<img :src="activeCampaignImage" alt="Hình ảnh chiến dịch" class="w-100 object-fit-cover" style="height: 360px;">
							</div>
							<div class="row g-2" v-if="campaign.images.length > 1">
								<div v-for="(image, index) in campaign.images" :key="`${campaign.id}-image-${index}`" class="col-4 col-md-3">
									<button type="button" class="btn p-0 w-100 border rounded-3 overflow-hidden gallery-thumb" :class="{ active: activeImageIndex === index }" @click="activeImageIndex = index">
										<img :src="image" alt="Ảnh thu nhỏ chiến dịch" class="w-100 object-fit-cover" style="height: 96px;">
									</button>
								</div>
							</div>
						</div>
					</div>

					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<h4 class="fw-bold mb-3"><i class="fa-solid fa-circle-info text-info me-2"></i>{{ $t('campaignDetail.aboutTitle') }}</h4>
							<p class="text-muted lh-lg mb-0">{{ campaign.description || $t('common.notAvailable') }}</p>
						</div>
					</div>

					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<h4 class="fw-bold mb-3"><i class="fa-solid fa-screwdriver-wrench text-primary me-2"></i>{{ $t('campaignDetail.skillsTitle') }}</h4>
							<div v-if="campaign.skills.length > 0" class="d-flex flex-wrap gap-2">
								<span v-for="skill in campaign.skills" :key="skill.id || skill.ten" class="badge border border-secondary text-secondary px-3 py-2 fw-normal">{{ skill.ten }}</span>
							</div>
							<p v-else class="text-muted mb-0">{{ $t('campaignDetail.noSpecialSkills') }}</p>
						</div>
					</div>

					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<h4 class="fw-bold mb-3"><i class="fa-solid fa-map-location-dot text-danger me-2"></i>{{ $t('campaignDetail.mapTitle') }}</h4>
							<div class="small text-muted mb-3">{{ campaign.location }}</div>
							<div id="user-detail-map" class="user-detail-map-wrapper rounded-3 border overflow-hidden mb-3"></div>
							<div v-if="mapLatitude && mapLongitude" class="d-flex gap-2 flex-wrap">
								<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ mapLatitude }}, {{ mapLongitude }}</span>
							</div>
						</div>
					</div>

					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<div class="d-flex align-items-center justify-content-between mb-4">
								<h4 class="fw-bold mb-0"><i class="fa-solid fa-comments text-warning me-2"></i>{{ $t('campaignDetail.feedbackTitle') }}</h4>
								<span class="badge bg-warning text-dark rounded-pill px-3 py-2" v-if="avgRating">
									<i class="fa-solid fa-star me-1"></i>{{ avgRating }} / 5
								</span>
							</div>

							<div class="row g-4 mb-4" v-if="reviews.length > 0">
								<div class="col-md-4">
									<div class="text-center p-3 bg-light rounded-3">
										<div class="fw-bold text-warning" style="font-size: 48px;">{{ avgRating }}</div>
										<div class="d-flex justify-content-center gap-1 mb-2">
											<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= Math.round(avgRating) ? 'text-warning' : 'text-muted'" style="font-size:18px"></i>
										</div>
										<div class="text-muted small">{{ reviews.length }} {{ $t('campaignDetail.reviewsCount') }}</div>
									</div>
								</div>
								<div class="col-md-8">
									<div class="d-flex align-items-center gap-2 mb-2" v-for="star in [5,4,3,2,1]" :key="star">
										<span class="small fw-medium text-muted" style="min-width:15px">{{ star }}</span>
										<i class="fa-solid fa-star text-warning" style="font-size:12px"></i>
										<div class="progress flex-grow-1" style="height:8px">
											<div class="progress-bar bg-warning" :style="{ width: getStarPercent(star) + '%' }"></div>
										</div>
										<span class="small text-muted" style="min-width:28px">{{ getStarCount(star) }}</span>
									</div>
								</div>
							</div>

							<div class="border-top pt-4" v-if="reviews.length > 0">
								<div class="review-item mb-4" v-for="review in displayedReviews" :key="review.id">
									<div class="d-flex align-items-start gap-3">
										<div class="review-avatar rounded-circle d-flex align-items-center justify-content-center text-white fw-bold flex-shrink-0" :style="{ background: review.color }">
											{{ review.name.charAt(0).toUpperCase() }}
										</div>
										<div class="flex-grow-1 min-w-0">
											<div class="d-flex align-items-center justify-content-between flex-wrap gap-1 mb-1">
												<span class="fw-bold small">{{ review.name }}</span>
												<span class="text-muted" style="font-size:12px">{{ review.date }}</span>
											</div>
											<div class="d-flex gap-0 mb-2">
												<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= review.rating ? 'text-warning' : 'text-muted'" style="font-size:12px"></i>
											</div>
											<p class="text-muted small mb-2 lh-lg" v-if="review.comment">{{ review.comment }}</p>
											<div class="d-flex flex-wrap gap-1" v-if="review.tags && review.tags.length > 0">
												<span v-for="tag in review.tags" :key="tag" class="badge bg-light text-muted border px-2 py-1" style="font-size:11px">{{ tag }}</span>
											</div>
										</div>
									</div>
								</div>
								<button class="btn btn-outline-primary btn-sm rounded-pill px-4 w-100" v-if="reviews.length > 3 && !showAllReviews" @click="showAllReviews = true">
									<i class="fa-solid fa-chevron-down me-1"></i>{{ $t('campaignDetail.viewAllReviews', { count: reviews.length }) }}
								</button>
							</div>

							<div v-if="reviews.length === 0" class="text-center py-4 text-muted">
								<i class="fa-regular fa-comment-dots fs-1 mb-3 opacity-25 d-block"></i>
								<p class="mb-0">{{ $t('campaignDetail.noReviews') }}</p>
							</div>
						</div>
					</div>
				</div>

				<div class="col-lg-4">
					<div class="position-sticky" style="top: 20px;">
						<div class="card border-0 shadow-sm rounded-4 mb-4 action-card">
							<div class="card-body p-4">
								<h5 class="fw-bold text-center mb-4">{{ $t('campaignDetail.registrationStatus') }}</h5>
								<div class="d-flex justify-content-between align-items-end mb-2">
									<div>
										<span class="fs-4 fw-bold text-primary">{{ campaign.registered }}</span>
										<span class="text-muted"> / {{ campaign.capacity }}</span>
										<div class="small text-muted">{{ $t('campaignDetail.volunteerLabel') }}</div>
									</div>
									<div class="fs-5 fw-bold text-primary">{{ campaign.progress }}%</div>
								</div>
								<div class="progress mb-4" style="height: 10px;">
									<div class="progress-bar progress-bar-striped progress-bar-animated bg-primary" :style="{ width: campaign.progress + '%' }"></div>
								</div>
								<div class="bg-light rounded-3 p-3 mb-3 text-center">
									<div class="small fw-medium text-muted mb-1">{{ $t('campaignDetail.deadlineLabel') }}</div>
									<div class="fw-bold">{{ campaign.deadline }}</div>
								</div>
								<div class="bg-light rounded-3 p-3 mb-4 text-center" v-if="registration.statusLabel">
									<div class="small text-muted mb-1">{{ $t('campaignRegistration.yourRegistration') }}</div>
									<div class="fw-bold">{{ registration.statusLabel }}</div>
								</div>

								<div class="d-grid gap-2">
									<button v-if="!isLoggedIn" class="btn btn-primary btn-lg fw-bold rounded-pill" @click="goToLogin">
										{{ $t('campaignRegistration.loginToRegister') }}
									</button>
									<button v-else-if="canManageParticipation && campaign.canRegister" class="btn btn-primary btn-lg fw-bold rounded-pill" @click="openActionModal('register')">
										{{ $t('campaignDetail.registerNow') }}
									</button>
									<button v-else-if="canManageParticipation && campaign.canConfirm" class="btn btn-success btn-lg fw-bold rounded-pill" @click="openActionModal('confirm')">
										{{ $t('campaignRegistration.confirmJoin') }}
									</button>
									<button v-if="isLoggedIn && canManageParticipation && campaign.canCancelRegistration" class="btn btn-outline-danger btn-lg fw-bold rounded-pill" @click="openActionModal('cancel')">
										{{ $t('campaignRegistration.cancelRegistration') }}
									</button>
									<button v-if="isLoggedIn && (!canManageParticipation || (!campaign.canRegister && !campaign.canConfirm && !campaign.canCancelRegistration))" class="btn btn-light btn-lg fw-bold rounded-pill" disabled>
										{{ actionStateLabel }}
									</button>
								</div>
							</div>
						</div>

						<div class="card border-0 shadow-sm rounded-4">
							<div class="card-body p-4">
								<h6 class="fw-bold mb-4 text-uppercase small text-muted">{{ $t('campaignDetail.coordinatorTitle') }}</h6>
								<div class="d-flex align-items-center gap-3">
									<div class="avatar-bg bg-primary text-white rounded-circle d-flex align-items-center justify-content-center fw-bold fs-4">{{ creatorInitial }}</div>
									<div>
										<h6 class="fw-bold mb-1">{{ campaign.creatorName }}</h6>
										<div class="small text-muted"><i class="fa-regular fa-envelope me-1"></i>{{ campaign.creatorEmail || $t('common.notAvailable') }}</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<div v-if="showActionModal" class="modal-overlay" @click.self="closeActionModal">
			<div class="modal-card shadow-lg">
				<div class="d-flex justify-content-between align-items-start gap-3 mb-3">
					<div>
						<h5 class="fw-bold mb-1">{{ actionModalTitle }}</h5>
						<p class="text-muted mb-0">{{ actionModalMessage }}</p>
					</div>
					<button class="btn btn-sm btn-light rounded-circle" @click="closeActionModal"><i class="fa-solid fa-xmark"></i></button>
				</div>
				<div v-if="pendingAction === 'cancel'" class="mb-3">
					<label class="form-label fw-semibold">{{ $t('campaignRegistration.cancelReason') }}</label>
					<textarea v-model.trim="cancelReason" rows="4" class="form-control" :placeholder="$t('campaignRegistration.cancelReasonPlaceholder')"></textarea>
				</div>
				<div class="d-flex justify-content-end gap-2">
					<button class="btn btn-light rounded-pill px-4" @click="closeActionModal">{{ $t('common.cancel') }}</button>
					<button class="btn rounded-pill px-4" :class="actionButtonClass" :disabled="submittingAction" @click="submitAction">
						{{ submittingAction ? $t('common.processing') : actionConfirmLabel }}
					</button>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
import api from '@/services/api.js';
import { hasPermission } from '@/utils/permissions';

export default {
	name: 'ChiTietChienDichPublic',
	inject: ['toast'],
	data() {
		return {
			loading: false,
			errorMessage: '',
			detailMap: null,
			detailMarker: null,
			mapLatitude: null,
			mapLongitude: null,
			showActionModal: false,
			pendingAction: '',
			submittingAction: false,
			cancelReason: '',
			showAllReviews: false,
			activeImageIndex: 0,
			campaign: {
				id: null,
				title: '',
				description: '',
				location: '',
				dateRange: '',
				deadline: '',
				status: '',
				statusLabel: '',
				priority: '',
				priorityLabel: '',
				categoryLabel: '',
				creatorName: '',
				creatorEmail: '',
				capacity: 0,
				registered: 0,
				confirmed: 0,
				progress: 0,
				bannerStyle: '',
				images: [],
				latitude: null,
				longitude: null,
				skills: [],
				canRegister: false,
				canConfirm: false,
				canCancelRegistration: false,
			},
			registration: {
				status: '',
				statusLabel: '',
			},
			feedbacks: [],
		};
	},
	computed: {
		activeCampaignImage() {
			return this.campaign.images[this.activeImageIndex] || this.campaign.images[0] || '';
		},
		currentUser() {
			try {
				return JSON.parse(localStorage.getItem('user') || 'null');
			} catch (_error) {
				return null;
			}
		},
		isLoggedIn() {
			return !!localStorage.getItem('token') && !!this.currentUser;
		},
		canManageParticipation() {
			return hasPermission(this.currentUser, 'campaign_participation.manage');
		},
		creatorInitial() {
			return (this.campaign.creatorName || this.$t('campaignDetail.creatorInitialFallback')).charAt(0).toUpperCase();
		},
		reviews() {
			return this.feedbacks.map((feedback, index) => ({
				id: feedback.id,
				name: feedback.nguoi_dung?.ho_ten || this.$t('campaignDetail.unknownVolunteer'),
				rating: Number(feedback.danh_gia_sao || 0),
				date: this.formatDateTime(feedback.tao_luc),
				comment: feedback.noi_dung || '',
				tags: feedback.the_phan_hoi || [],
				color: this.getReviewColor(index),
			}));
		},
		displayedReviews() {
			return this.showAllReviews ? this.reviews : this.reviews.slice(0, 3);
		},
		avgRating() {
			if (this.reviews.length === 0) return 0;
			const total = this.reviews.reduce((sum, review) => sum + review.rating, 0);
			return Number((total / this.reviews.length).toFixed(1));
		},
		actionModalTitle() {
			return {
				register: this.$t('campaignRegistration.registerTitle'),
				confirm: this.$t('campaignRegistration.confirmTitle'),
				cancel: this.$t('campaignRegistration.cancelTitle'),
			}[this.pendingAction] || '';
		},
		actionModalMessage() {
			return {
				register: this.$t('campaignRegistration.registerMessage', { campaign: this.campaign.title }),
				confirm: this.$t('campaignRegistration.confirmMessage', { campaign: this.campaign.title }),
				cancel: this.$t('campaignRegistration.cancelMessage', { campaign: this.campaign.title }),
			}[this.pendingAction] || '';
		},
		actionConfirmLabel() {
			return {
				register: this.$t('campaignRegistration.registerAction'),
				confirm: this.$t('campaignRegistration.confirmAction'),
				cancel: this.$t('campaignRegistration.cancelAction'),
			}[this.pendingAction] || this.$t('common.confirm');
		},
		actionButtonClass() {
			return {
				register: 'btn-primary',
				confirm: 'btn-success',
				cancel: 'btn-danger',
			}[this.pendingAction] || 'btn-primary';
		},
		actionStateLabel() {
			if (this.registration.statusLabel) return this.registration.statusLabel;
			if (this.campaign.status === 'dang_dien_ra') return this.$t('campaignRegistration.campaignInProgress');
			if (this.campaign.status === 'hoan_thanh') return this.$t('campaignRegistration.campaignCompleted');
			return this.$t('campaignDetail.registrationClosed');
		},
	},
	async mounted() {
		await this.loadCampaignDetail();
		this.ensureLeaflet();
	},
	beforeUnmount() {
		if (this.detailMap) {
			this.detailMap.remove();
			this.detailMap = null;
		}
		if (this.leafletPoll) {
			clearTimeout(this.leafletPoll);
		}
	},
	methods: {
		async loadCampaignDetail() {
			this.loading = true;
			this.errorMessage = '';
			try {
				const res = await api.get(`/chien-dich/${this.$route.params.id}`);
				const payload = res.data?.data;
				this.campaign = this.mapCampaign(payload);
				this.activeImageIndex = 0;
				this.registration = this.mapRegistration(payload?.dang_ky_hien_tai);
				this.feedbacks = payload?.feedbacks || [];
				this.renderMapIfPossible();
			} catch (error) {
				this.errorMessage = error.response?.data?.message || this.$t('campaignDetail.loadErrorMessage');
				this.showToast('error', this.$t('common.error'), this.errorMessage);
			} finally {
				this.loading = false;
			}
		},
		mapCampaign(item = {}) {
			const images = Array.isArray(item.danh_sach_anh) && item.danh_sach_anh.length
				? item.danh_sach_anh
				: (Array.isArray(item.images) && item.images.length ? item.images : (item.anh_bia ? [item.anh_bia] : []));
			const bannerStyle = images[0] ? `linear-gradient(rgba(15,23,42,.35), rgba(15,23,42,.35)), url(${images[0]}) center/cover` : this.getPriorityGradient(item.muc_do_uu_tien);
			return {
				id: item.id,
				title: item.tieu_de || this.$t('common.notAvailable'),
				description: item.mo_ta || '',
				location: item.dia_diem || this.$t('common.notAvailable'),
				dateRange: `${this.formatDate(item.ngay_bat_dau)} — ${this.formatDate(item.ngay_ket_thuc)}`,
				deadline: this.formatDate(item.han_dang_ky),
				status: item.trang_thai,
				statusLabel: this.getCampaignStatusLabel(item.trang_thai),
				priority: item.muc_do_uu_tien,
				priorityLabel: this.getPriorityLabel(item.muc_do_uu_tien),
				categoryLabel: item.loai_chien_dich?.ten || this.$t('campaignDetail.defaultCategory'),
				creatorName: item.nguoi_tao?.ho_ten || item.duyet_boi?.ho_ten || this.$t('campaignDetail.unknownCreator'),
				creatorEmail: item.nguoi_tao?.email || item.duyet_boi?.email || '',
				capacity: item.so_luong_toi_da || 0,
				registered: item.so_dang_ky || 0,
				confirmed: item.so_xac_nhan || 0,
				progress: item.so_luong_toi_da ? Math.min(100, Math.round(((item.so_dang_ky || 0) / item.so_luong_toi_da) * 100)) : 0,
				bannerStyle,
				images,
				latitude: item.vi_do,
				longitude: item.kinh_do,
				skills: item.ky_nangs || [],
				canRegister: !!item.co_the_dang_ky,
				canConfirm: !!item.co_the_xac_nhan,
				canCancelRegistration: !!item.co_the_huy_dang_ky,
			};
		},
		mapRegistration(registration) {
			if (!registration) {
				return { status: '', statusLabel: '' };
			}
			return {
				status: registration.trang_thai,
				statusLabel: this.getRegistrationStatusLabel(registration.trang_thai),
			};
		},
		getCampaignStatusLabel(status) {
			const key = {
				da_duyet: 'approved',
				dang_dien_ra: 'active',
				hoan_thanh: 'completed',
			}[status] || status;
			return this.$t(`statuses.${key}`) || status;
		},
		getRegistrationStatusLabel(status) {
			if (!status) return '';
			const translated = this.$t(`campaignRegistration.statuses.${status}`);
			if (translated !== `campaignRegistration.statuses.${status}`) return translated;
			const fallback = this.$t(`statuses.${status}`);
			return fallback !== `statuses.${status}` ? fallback : status;
		},
		getPriorityLabel(priority) {
			const key = { thap: 'low', trung_binh: 'medium', cao: 'high', khan_cap: 'urgent' }[priority] || priority;
			return this.$t(`priorities.${key}`) || priority;
		},
		getPriorityGradient(priority) {
			return {
				thap: 'linear-gradient(135deg, #94a3b8, #64748b)',
				trung_binh: 'linear-gradient(135deg, #0ea5e9, #2563eb)',
				cao: 'linear-gradient(135deg, #f59e0b, #f97316)',
				khan_cap: 'linear-gradient(135deg, #ef4444, #b91c1c)',
			}[priority] || 'linear-gradient(135deg, #2563eb, #1d4ed8)';
		},
		statusBadgeClass(status) {
			return {
				da_duyet: 'bg-success text-white',
				dang_dien_ra: 'bg-primary text-white',
				hoan_thanh: 'bg-secondary text-white',
			}[status] || 'bg-light text-dark';
		},
		formatDate(date) {
			if (!date) return this.$t('common.notAvailable');
			const d = new Date(date);
			if (Number.isNaN(d.getTime())) return date;
			return d.toLocaleDateString('vi-VN');
		},
		formatDateTime(date) {
			if (!date) return this.$t('common.notAvailable');
			const d = new Date(date);
			if (Number.isNaN(d.getTime())) return date;
			return d.toLocaleString('vi-VN');
		},
		getReviewColor(index) {
			return ['#0d6efd', '#6f42c1', '#dc3545', '#198754', '#fd7e14'][index % 5];
		},
		getStarCount(star) {
			return this.reviews.filter(review => review.rating === star).length;
		},
		getStarPercent(star) {
			if (this.reviews.length === 0) return 0;
			return Math.round((this.getStarCount(star) / this.reviews.length) * 100);
		},
		goToLogin() {
			this.$router.push({ path: '/dang-nhap', query: { redirect: this.$route.fullPath } });
		},
		openActionModal(action) {
			this.pendingAction = action;
			this.showActionModal = true;
			this.cancelReason = '';
		},
		closeActionModal() {
			this.showActionModal = false;
			this.pendingAction = '';
			this.cancelReason = '';
		},
		async submitAction() {
			if (!this.pendingAction) return;
			if (this.pendingAction === 'cancel' && !this.cancelReason) {
				this.showToast('warning', this.$t('common.warning'), this.$t('campaignRegistration.cancelReasonRequired'));
				return;
			}

			this.submittingAction = true;
			try {
				if (this.pendingAction === 'register') {
					await api.post(`/chien-dich/${this.campaign.id}/dang-ky`);
				} else if (this.pendingAction === 'confirm') {
					await api.put(`/chien-dich/${this.campaign.id}/xac-nhan-tham-gia`);
				} else if (this.pendingAction === 'cancel') {
					await api.put(`/chien-dich/${this.campaign.id}/huy-dang-ky`, { ly_do_huy: this.cancelReason });
				}
				this.showToast('success', this.$t('common.success'), this.successMessageByAction(this.pendingAction));
				this.closeActionModal();
				await this.loadCampaignDetail();
			} catch (error) {
				this.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('campaignRegistration.actionError'));
			} finally {
				this.submittingAction = false;
			}
		},
		successMessageByAction(action) {
			return {
				register: this.$t('campaignRegistration.registeredSuccess'),
				confirm: this.$t('campaignRegistration.confirmedSuccess'),
				cancel: this.$t('campaignRegistration.cancelledSuccess'),
			}[action] || this.$t('campaignRegistration.defaultSuccessMessage');
		},
		showToast(type, title, message) {
			if (this.toast?.showToast) {
				this.toast.showToast(type, title, message);
			}
		},
		ensureLeaflet() {
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
				script.onload = () => this.renderMapIfPossible();
				document.head.appendChild(script);
			} else {
				this.renderMapIfPossible();
			}
		},
		renderMapIfPossible() {
			if (!this.campaign.id) return;
			if (!window.L) {
				this.leafletPoll = setTimeout(() => this.renderMapIfPossible(), 300);
				return;
			}
			this.$nextTick(() => {
				const container = document.getElementById('user-detail-map');
				if (!container) return;
				let lat = parseFloat(this.campaign.latitude);
				let lng = parseFloat(this.campaign.longitude);
				if (Number.isNaN(lat) || Number.isNaN(lng)) {
					lat = 16.0544;
					lng = 108.2022;
				}
				if (this.detailMap) {
					this.detailMap.remove();
					this.detailMap = null;
				}
				this.detailMap = window.L.map(container, {
					center: [lat, lng],
					zoom: 15,
					zoomControl: true,
					attributionControl: false,
					scrollWheelZoom: false,
				});
				window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(this.detailMap);
				const pinIcon = window.L.divIcon({
					html: '<div class="custom-pin"><i class="fa-solid fa-location-dot"></i></div>',
					iconSize: [36, 36],
					iconAnchor: [18, 36],
					className: 'custom-pin-wrapper'
				});
				this.detailMarker = window.L.marker([lat, lng], { draggable: false, icon: pinIcon }).addTo(this.detailMap);
				this.mapLatitude = lat.toFixed(7);
				this.mapLongitude = lng.toFixed(7);
			});
		},
	},
};
</script>

<style scoped>
.campaign-cover {
	height: 320px;
	background: linear-gradient(135deg, #2563eb, #1d4ed8);
}
.campaign-content {
	margin-top: -72px;
}
.icon-circle {
	width: 40px;
	height: 40px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	box-shadow: 0 0.5rem 1rem rgba(15, 23, 42, 0.12);
}
.action-card {
	border-top: 5px solid #2563eb !important;
}
.user-detail-map-wrapper {
	height: 300px;
	width: 100%;
}
.avatar-bg {
	width: 56px;
	height: 56px;
	min-width: 56px;
}
.gallery-thumb {
	opacity: 0.75;
	transition: all 0.2s ease;
}
.gallery-thumb.active,
.gallery-thumb:hover {
	opacity: 1;
	border-color: #0d6efd !important;
	box-shadow: 0 0 0 2px rgba(13, 110, 253, 0.12);
}
.modal-overlay {
	position: fixed;
	inset: 0;
	background: rgba(15, 23, 42, 0.55);
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 1rem;
	z-index: 2000;
}
.modal-card {
	width: 100%;
	max-width: 540px;
	background: #fff;
	border-radius: 1rem;
	padding: 1.5rem;
}
@media (max-width: 991px) {
	.campaign-content {
		margin-top: -40px;
	}
}
</style>

<style>
.custom-pin-wrapper {
	background: none !important;
	border: none !important;
}
.custom-pin {
	font-size: 36px;
	color: #dc3545;
	filter: drop-shadow(0 2px 4px rgba(0,0,0,0.4));
}
</style>
