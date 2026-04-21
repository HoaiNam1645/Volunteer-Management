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
							<div v-if="campaign.cancelReason && ['yeu_cau_huy', 'da_huy'].includes(campaign.status)" class="alert alert-warning border-0 mb-3">
								<div class="fw-semibold mb-1">
									<i class="fa-solid fa-triangle-exclamation me-2"></i>{{ $t('campaignDetail.cancelReasonTitle') }}
								</div>
								<div class="small mb-0">{{ campaign.cancelReason }}</div>
							</div>
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
							<div class="campaign-gallery-main rounded-4 overflow-hidden border mb-3">
								<img :src="activeCampaignImage" alt="Hình ảnh chiến dịch" class="campaign-gallery-main-image">
							</div>
							<div class="row g-2" v-if="campaign.images.length > 1">
								<div v-for="(image, index) in campaign.images" :key="`${campaign.id}-image-${index}`" class="col-4 col-md-3">
									<button type="button" class="btn p-0 w-100 border rounded-3 overflow-hidden gallery-thumb" :class="{ active: activeImageIndex === index }" @click="activeImageIndex = index">
										<img :src="image" alt="Ảnh thu nhỏ chiến dịch" class="campaign-gallery-thumb-image">
									</button>
								</div>
							</div>
						</div>
					</div>

					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<h4 class="fw-bold mb-3"><i class="fa-solid fa-circle-info text-info me-2"></i>{{ $t('campaignDetail.aboutTitle') }}</h4>
							<div v-if="campaignDescriptionSections.length" class="row g-3">
								<div v-for="section in campaignDescriptionSections" :key="section.key" class="col-md-6">
									<div class="campaign-description-card h-100">
										<div class="small fw-bold text-primary mb-2">{{ section.label }}</div>
										<div class="text-muted lh-lg mb-0">{{ section.value }}</div>
									</div>
								</div>
							</div>
							<ul v-else-if="campaignDescriptionItems.length > 1" class="text-muted lh-lg mb-0 ps-3 campaign-description-list">
								<li v-for="(item, index) in campaignDescriptionItems" :key="`campaign-public-description-${index}`" class="mb-2">
									{{ item }}
								</li>
							</ul>
							<p v-else class="text-muted lh-lg mb-0">{{ campaignDescriptionItems[0] || campaign.description || $t('common.notAvailable') }}</p>
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
									<button v-if="canLoadComparison" class="btn btn-outline-dark btn-lg fw-bold rounded-pill" @click="openCampaignCompare">
										<i class="fa-solid fa-table-columns me-2"></i>{{ $t('campaignList.compare.open') }}
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

		<div v-if="showCompareModal" class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
			<div class="modal-dialog modal-dialog-centered modal-xl">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<div>
							<div class="small text-muted">{{ $t('campaignList.compare.modalSubtitle') }}</div>
							<h5 class="modal-title fw-bold mt-1">{{ compareCampaign?.title || campaign.title }}</h5>
						</div>
						<button type="button" class="btn-close" @click="closeCampaignCompare"></button>
					</div>
					<div class="modal-body pt-3">
						<div v-if="compareLoading" class="text-center py-5">
							<div class="spinner-border text-primary mb-3" role="status"></div>
							<div class="text-muted">{{ $t('campaignList.compare.preparing') }}</div>
						</div>
						<template v-else-if="compareCampaign">
							<div class="compare-overview mb-4">
								<div class="compare-overview-title">{{ $t('campaignList.compare.overview') }}</div>
								<div class="compare-overview-text">{{ compareCampaign.compareSummary }}</div>
							</div>

							<div class="compare-table-wrap">
								<table class="compare-table">
									<thead>
										<tr>
											<th>{{ $t('campaignList.compare.criteria') }}</th>
											<th>{{ $t('campaignList.compare.campaign') }}</th>
											<th>{{ $t('campaignList.compare.matchLevel') }}</th>
											<th>{{ $t('campaignList.compare.profile') }}</th>
										</tr>
									</thead>
									<tbody>
										<tr v-for="row in compareRows" :key="row.label">
											<td class="compare-cell-label">{{ row.label }}</td>
											<td class="compare-cell-main">
												<div class="compare-main">{{ row.campaign }}</div>
												<div v-if="row.campaignHelper" class="compare-helper">{{ row.campaignHelper }}</div>
											</td>
											<td class="compare-cell-status">
												<span class="compare-badge" :class="getCompareBadgeClass(row.percent)">{{ row.statusLabel }}</span>
											</td>
											<td class="compare-cell-main">
												<div class="compare-main">{{ row.profile }}</div>
												<div v-if="row.profileHelper" class="compare-helper">{{ row.profileHelper }}</div>
											</td>
										</tr>
									</tbody>
								</table>
							</div>

							<div class="compare-detail-grid mt-3">
								<div class="compare-detail-card">
									<div class="compare-detail-title">{{ $t('campaignList.compare.matchedSkills') }}</div>
									<div v-if="compareSkillSummary.noRequirement" class="small text-muted">
										{{ $t('campaignList.compare.noSkillRequirement') }}
									</div>
									<div v-else-if="compareSkillSummary.matched.length" class="compare-chip-wrap">
										<span v-for="skill in compareSkillSummary.matched" :key="'detail-cmp-skill-' + skill" class="compare-chip compare-chip-good">{{ skill }}</span>
									</div>
									<div v-else class="small text-muted">{{ $t('campaignList.compare.noMatchedSkills') }}</div>
								</div>

								<div class="compare-detail-card">
									<div class="compare-detail-title">{{ $t('campaignList.compare.missingSkills') }}</div>
									<div v-if="compareSkillSummary.noRequirement" class="small text-muted">
										{{ $t('campaignList.compare.noMissingSkillsBecauseNoRequirement') }}
									</div>
									<div v-else-if="compareSkillSummary.missing.length" class="compare-chip-wrap">
										<span v-for="skill in compareSkillSummary.missing" :key="'detail-cmp-missing-' + skill" class="compare-chip compare-chip-warn">{{ skill }}</span>
									</div>
									<div v-else class="small text-muted">{{ $t('campaignList.compare.hasAllSkills') }}</div>
								</div>

								<div class="compare-detail-card">
									<div class="compare-detail-title">{{ $t('campaignList.compare.matchedDays') }}</div>
									<div v-if="compareDaySummary.matched.length" class="compare-chip-wrap">
										<span v-for="day in compareDaySummary.matched" :key="'detail-cmp-day-' + day" class="compare-chip compare-chip-good">{{ day }}</span>
									</div>
									<div v-else class="small text-muted">{{ $t('campaignList.compare.noMatchedDays') }}</div>
								</div>

								<div class="compare-detail-card">
									<div class="compare-detail-title">{{ $t('campaignList.compare.missingDays') }}</div>
									<div v-if="compareDaySummary.missing.length" class="compare-chip-wrap">
										<span v-for="day in compareDaySummary.missing" :key="'detail-cmp-missing-day-' + day" class="compare-chip compare-chip-warn">{{ day }}</span>
									</div>
									<div v-else class="small text-muted">{{ $t('campaignList.compare.allDaysMatched') }}</div>
								</div>
							</div>

							<div v-if="compareHighlights.length" class="compare-highlights mt-3">
								<div class="fw-semibold mb-2">{{ $t('campaignList.compare.highlights') }}</div>
								<div v-for="highlight in compareHighlights" :key="highlight" class="small text-muted mb-1">
									<i class="fa-solid fa-circle-info text-primary me-2"></i>{{ highlight }}
								</div>
							</div>
						</template>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeCampaignCompare">{{ $t('common.close') }}</button>
					</div>
				</div>
			</div>
		</div>
		<div v-if="showCompareModal" class="modal-backdrop fade show" @click="closeCampaignCompare"></div>
	</div>
</template>

<script>
import api from '@/services/api.js';
import { hasPermission } from '@/utils/permissions';
import { extractCampaignDescriptionSections, parseCampaignDescription } from '@/utils/campaignDescription';

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
			showCompareModal: false,
			pendingAction: '',
			submittingAction: false,
			cancelReason: '',
			showAllReviews: false,
			activeImageIndex: 0,
			compareLoading: false,
			compareCampaign: null,
			volunteerProfile: null,
			skillCatalog: [],
			areaCatalog: [],
			campaign: {
				id: null,
				title: '',
				description: '',
				location: '',
				dateRange: '',
				startDateRaw: '',
				endDateRaw: '',
				deadline: '',
				status: '',
				statusLabel: '',
				priority: '',
				priorityLabel: '',
				categoryLabel: '',
				creatorName: '',
				creatorEmail: '',
				areaText: '',
				minVolunteers: 1,
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
				cancelReason: '',
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
		campaignDescriptionSections() {
			return extractCampaignDescriptionSections(this.campaign.description || '');
		},
		campaignDescriptionItems() {
			return parseCampaignDescription(this.campaign.description || '');
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
		canLoadComparison() {
			return !!localStorage.getItem('token')
				&& this.currentUser?.vai_tro === 'tinh_nguyen_vien'
				&& hasPermission(this.currentUser, 'ai_recommendation.view');
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
		compareSkillSummary() {
			if (!this.compareCampaign || !this.volunteerProfile) return { matched: [], missing: [], noRequirement: false };
			const campaignSkills = this.compareCampaign.skills || [];
			const profileSkills = this.volunteerProfile.skillNames || [];
			return {
				noRequirement: campaignSkills.length === 0,
				matched: profileSkills.filter((skill) => campaignSkills.includes(skill)),
				missing: campaignSkills.filter((skill) => !profileSkills.includes(skill)),
			};
		},
		compareDaySummary() {
			if (!this.compareCampaign || !this.volunteerProfile) return { matched: [], missing: [] };
			const campaignDays = this.getCampaignWeekdayLabels(this.compareCampaign.startDateRaw, this.compareCampaign.endDateRaw);
			const volunteerDays = this.normalizeVolunteerDayLabels(this.volunteerProfile.availability || []);
			return {
				matched: campaignDays.filter((day) => volunteerDays.includes(day)),
				missing: campaignDays.filter((day) => !volunteerDays.includes(day)),
			};
		},
		compareRows() {
			if (!this.compareCampaign || !this.volunteerProfile) return [];

			const skillPercent = this.compareCampaign.skills.length
				? Math.round((this.compareSkillSummary.matched.length / this.compareCampaign.skills.length) * 100)
				: 100;
			const availabilityPercent = this.compareCampaign.dayLabels.length
				? Math.round((this.compareDaySummary.matched.length / this.compareCampaign.dayLabels.length) * 100)
				: 100;
			const distancePercent = this.compareCampaign.distanceScore;
			const overallPercent = this.compareCampaign.matchScore ?? this.buildCompareOverallScore(skillPercent, availabilityPercent, distancePercent);

			return [
				{
					label: this.$t('campaignList.compare.skillLabel'),
					campaign: this.compareCampaign.skills.length ? this.compareCampaign.skills.join(', ') : this.$t('campaignList.compare.noSpecificSkillRequirement'),
					campaignHelper: this.compareCampaign.skills.length ? this.$t('campaignList.compare.campaignNeedsSkills', { count: this.compareCampaign.skills.length }) : '',
					profile: this.volunteerProfile.skillNames.length ? this.volunteerProfile.skillNames.join(', ') : this.$t('campaignList.compare.profileNoSkills'),
					profileHelper: this.compareSkillSummary.noRequirement
						? this.$t('campaignList.compare.skillNotRestricted')
						: this.$t('campaignList.compare.skillMatchFraction', { matched: this.compareSkillSummary.matched.length, total: this.compareCampaign.skills.length }),
					percent: skillPercent,
					statusLabel: this.$t('campaignList.compare.percentMatch', { percent: skillPercent }),
				},
				{
					label: this.$t('campaignList.compare.locationLabel'),
					campaign: this.compareCampaign.location || this.$t('campaignList.compare.noLocation'),
					campaignHelper: this.compareCampaign.areaText || '',
					profile: this.volunteerProfile.areaText || this.$t('campaignList.compare.profileNoArea'),
					profileHelper: this.compareCampaign.distanceText
						? this.$t('campaignList.compare.distanceToCampaign', { distance: this.compareCampaign.distanceText })
						: this.$t('campaignList.compare.distanceUnavailable'),
					percent: distancePercent,
					statusLabel: this.$t('campaignList.compare.percentNear', { percent: this.compareCampaign.distanceText ? distancePercent : 0 }),
				},
				{
					label: this.$t('campaignList.compare.timeLabel'),
					campaign: this.compareCampaign.dateText,
					campaignHelper: this.compareCampaign.weekdayRangeText,
					profile: this.volunteerProfile.availabilityText || this.$t('campaignList.compare.profileNoAvailability'),
					profileHelper: this.$t('campaignList.compare.dayMatchSummary', { matched: this.compareDaySummary.matched.length, missing: this.compareDaySummary.missing.length }),
					percent: availabilityPercent,
					statusLabel: this.$t('campaignList.compare.percentMatch', { percent: availabilityPercent }),
				},
				{
					label: this.$t('campaignList.compare.overallLabel'),
					campaign: this.compareCampaign.priorityLabel || this.$t('campaignList.compare.notSpecified'),
					campaignHelper: this.$t('campaignList.compare.capacityText', { min: this.compareCampaign.minVolunteers, max: this.compareCampaign.maxVolunteers }),
					profile: this.$t('campaignList.compare.currentProfile'),
					profileHelper: this.$t('campaignList.compare.profileOverallFit', { percent: overallPercent }),
					percent: overallPercent,
					statusLabel: this.$t('campaignList.compare.percentOverall', { percent: overallPercent }),
				},
			];
		},
		compareHighlights() {
			if (!this.compareCampaign || !this.volunteerProfile) return [];
			const highlights = [];
			if (this.compareSkillSummary.noRequirement) {
				highlights.push(this.$t('campaignList.compare.highlightNoSkillRequirement'));
			} else if (this.compareSkillSummary.matched.length) {
				highlights.push(this.$t('campaignList.compare.highlightMatchedSkills', { skills: this.compareSkillSummary.matched.join(', ') }));
			}
			if (!this.compareSkillSummary.noRequirement && this.compareSkillSummary.missing.length) {
				highlights.push(this.$t('campaignList.compare.highlightMissingSkills', { skills: this.compareSkillSummary.missing.join(', ') }));
			}
			if (this.compareCampaign.distanceText) {
				highlights.push(this.$t('campaignList.compare.highlightDistance', { distance: this.compareCampaign.distanceText }));
			}
			if (this.compareDaySummary.missing.length) {
				highlights.push(this.$t('campaignList.compare.highlightMissingDays', { days: this.compareDaySummary.missing.join(', ') }));
			}
			return highlights.slice(0, 4);
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
				startDateRaw: item.ngay_bat_dau || '',
				endDateRaw: item.ngay_ket_thuc || '',
				deadline: this.formatDate(item.han_dang_ky),
				status: item.trang_thai,
				statusLabel: this.getCampaignStatusLabel(item.trang_thai),
				cancelReason: item.ly_do_huy || '',
				priority: item.muc_do_uu_tien,
				priorityLabel: this.getPriorityLabel(item.muc_do_uu_tien),
				categoryLabel: item.loai_chien_dich?.ten || this.$t('campaignDetail.defaultCategory'),
				creatorName: item.nguoi_tao?.ho_ten || item.duyet_boi?.ho_ten || this.$t('campaignDetail.unknownCreator'),
				creatorEmail: item.nguoi_tao?.email || item.duyet_boi?.email || '',
				areaText: item.khu_vuc?.ten || '',
				minVolunteers: item.so_luong_toi_thieu || 1,
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
				yeu_cau_huy: 'pending_cancel',
				da_huy: 'cancelled',
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
				yeu_cau_huy: 'bg-warning text-dark',
				da_huy: 'bg-danger text-white',
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
		async loadVolunteerComparisonProfile() {
			try {
				const [profileRes, infoRes, skillRes, areaRes] = await Promise.all([
					api.get('/nguoi-dung/ho-so-nang-luc'),
					api.get('/nguoi-dung/thong-tin'),
					api.get('/danh-muc/ky-nang'),
					api.get('/danh-muc/khu-vuc'),
				]);

				this.skillCatalog = Array.isArray(skillRes.data?.data) ? skillRes.data.data : [];
				this.areaCatalog = Array.isArray(areaRes.data?.data) ? areaRes.data.data : [];

				const profile = profileRes.data?.data || {};
				const info = infoRes.data?.data || {};
				const skillNames = (profile.ky_nang_ids || [])
					.map((id) => this.skillCatalog.find((item) => Number(item.id) === Number(id))?.ten)
					.filter(Boolean);
				const areaNames = (profile.khu_vuc_ids || [])
					.map((id) => this.areaCatalog.find((item) => Number(item.id) === Number(id))?.ten)
					.filter(Boolean);

				this.volunteerProfile = {
					skillIds: profile.ky_nang_ids || [],
					skillNames,
					areaIds: profile.khu_vuc_ids || [],
					areaText: areaNames.join(', '),
					availability: profile.lich_ranh || [],
					availabilityText: this.normalizeVolunteerDayLabels(profile.lich_ranh || []).join(', '),
					viDo: info.vi_do !== null && info.vi_do !== undefined ? Number(info.vi_do) : null,
					kinhDo: info.kinh_do !== null && info.kinh_do !== undefined ? Number(info.kinh_do) : null,
				};
			} catch (_error) {
				this.volunteerProfile = null;
			}
		},
		async openCampaignCompare() {
			this.showCompareModal = true;
			this.compareLoading = true;
			this.compareCampaign = null;
			try {
				if (!this.volunteerProfile) {
					await this.loadVolunteerComparisonProfile();
				}
				if (!this.volunteerProfile) {
					throw new Error('comparison_profile_unavailable');
				}

				const skillNames = (this.campaign.skills || []).map((skill) => skill.ten).filter(Boolean);
				const distanceValue = this.calculateDistanceKm(
					this.volunteerProfile?.viDo,
					this.volunteerProfile?.kinhDo,
					this.campaign.latitude !== null && this.campaign.latitude !== undefined ? Number(this.campaign.latitude) : null,
					this.campaign.longitude !== null && this.campaign.longitude !== undefined ? Number(this.campaign.longitude) : null,
				);

				this.compareCampaign = {
					id: this.campaign.id,
					title: this.campaign.title,
					location: this.campaign.location,
					areaText: this.campaign.areaText || '',
					skills: skillNames,
					startDateRaw: this.campaign.startDateRaw || '',
					endDateRaw: this.campaign.endDateRaw || '',
					dateText: this.buildCampaignDateText(this.campaign.startDateRaw, this.campaign.endDateRaw),
					weekdayRangeText: this.buildCampaignWeekdayRangeText(this.campaign.startDateRaw, this.campaign.endDateRaw),
					dayLabels: this.getCampaignWeekdayLabels(this.campaign.startDateRaw, this.campaign.endDateRaw),
					priorityLabel: this.campaign.priorityLabel || this.$t('campaignList.compare.notSpecified'),
					minVolunteers: this.campaign.minVolunteers || 1,
					maxVolunteers: this.campaign.capacity || 0,
					matchScore: null,
					distanceValue,
					distanceText: distanceValue !== null ? `${distanceValue.toFixed(2)} km` : '',
					distanceScore: this.distanceToPercent(distanceValue),
					compareSummary: this.$t('campaignList.compare.summaryWithoutScore'),
				};
			} catch (error) {
				this.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('campaignList.compare.loadError'));
				this.showCompareModal = false;
			} finally {
				this.compareLoading = false;
			}
		},
		closeCampaignCompare() {
			this.showCompareModal = false;
			this.compareLoading = false;
			this.compareCampaign = null;
		},
		getCompareBadgeClass(percent) {
			if (percent >= 80) return 'compare-badge-good';
			if (percent >= 50) return 'compare-badge-warn';
			if (percent > 0) return 'compare-badge-bad';
			return 'compare-badge-muted';
		},
		getWeekdayLabel(dateString) {
			if (!dateString) return '';
			const date = new Date(dateString);
			if (Number.isNaN(date.getTime())) return '';
			return [
				this.$t('common.weekdays.sunday'),
				this.$t('common.weekdays.monday'),
				this.$t('common.weekdays.tuesday'),
				this.$t('common.weekdays.wednesday'),
				this.$t('common.weekdays.thursday'),
				this.$t('common.weekdays.friday'),
				this.$t('common.weekdays.saturday'),
			][date.getDay()] || '';
		},
		buildCampaignDateText(startDate, endDate) {
			const start = this.formatShortDate(startDate);
			const end = this.formatShortDate(endDate);
			if (start && end) return `${start} - ${end}`;
			return start || end || this.$t('campaignList.compare.noSpecificDate');
		},
		buildCampaignWeekdayRangeText(startDate, endDate) {
			const start = this.formatShortDate(startDate);
			const end = this.formatShortDate(endDate);
			const startWeekday = this.getWeekdayLabel(startDate);
			const endWeekday = this.getWeekdayLabel(endDate);
			if (start && end && startWeekday && endWeekday) {
				return `${start} (${startWeekday}) đến ${end} (${endWeekday})`;
			}
			return '';
		},
		formatShortDate(dateString) {
			if (!dateString) return '';
			const date = new Date(dateString);
			if (Number.isNaN(date.getTime())) return '';
			return `${String(date.getDate()).padStart(2, '0')}-${String(date.getMonth() + 1).padStart(2, '0')}-${date.getFullYear()}`;
		},
		getCampaignWeekdayLabels(startDate, endDate) {
			if (!startDate || !endDate) return [];
			const current = new Date(startDate);
			const end = new Date(endDate);
			if (Number.isNaN(current.getTime()) || Number.isNaN(end.getTime()) || current > end) return [];
			const labels = [];
			const seen = new Set();
			while (current <= end) {
				const label = this.getWeekdayLabel(current.toISOString().slice(0, 10));
				if (label && !seen.has(label)) {
					seen.add(label);
					labels.push(label);
				}
				current.setDate(current.getDate() + 1);
			}
			return labels;
		},
		normalizeVolunteerDayLabels(days = []) {
			const dayMap = {
				thu_hai: this.$t('common.weekdays.monday'),
				thu_ba: this.$t('common.weekdays.tuesday'),
				thu_tu: this.$t('common.weekdays.wednesday'),
				thu_nam: this.$t('common.weekdays.thursday'),
				thu_sau: this.$t('common.weekdays.friday'),
				thu_bay: this.$t('common.weekdays.saturday'),
				chu_nhat: this.$t('common.weekdays.sunday'),
			};
			return [...new Set((days || []).map((day) => dayMap[String(day || '').trim().toLowerCase()] || '').filter(Boolean))];
		},
		distanceToPercent(distanceKm) {
			if (distanceKm === null || distanceKm === undefined || Number.isNaN(distanceKm)) return 0;
			if (distanceKm <= 3) return 100;
			if (distanceKm <= 10) return Math.round(100 - ((distanceKm - 3) / 7) * 30);
			if (distanceKm <= 20) return Math.round(70 - ((distanceKm - 10) / 10) * 30);
			return 10;
		},
		buildCompareOverallScore(skillPercent, availabilityPercent, distancePercent) {
			return Math.round((distancePercent * 0.4) + (skillPercent * 0.3) + (availabilityPercent * 0.2) + 5);
		},
		calculateDistanceKm(lat1, lon1, lat2, lon2) {
			if ([lat1, lon1, lat2, lon2].some((value) => value === null || value === undefined || Number.isNaN(Number(value)))) {
				return null;
			}
			const toRad = (value) => (value * Math.PI) / 180;
			const earthRadiusKm = 6371;
			const dLat = toRad(lat2 - lat1);
			const dLon = toRad(lon2 - lon1);
			const a = Math.sin(dLat / 2) ** 2
				+ Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
			const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
			return earthRadiusKm * c;
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
.campaign-description-list li:last-child {
	margin-bottom: 0 !important;
}
.campaign-gallery-main {
	height: clamp(220px, 36vw, 300px);
	background: #f8f9fa;
}
.campaign-gallery-main-image {
	width: 100%;
	height: 100%;
	object-fit: contain;
	background: #f8f9fa;
}
.campaign-gallery-thumb-image {
	width: 100%;
	height: 82px;
	object-fit: contain;
	background: #f8f9fa;
}
.compare-overview {
	padding: 14px 16px;
	border-radius: 16px;
	background: #f8fafc;
	border: 1px solid #e2e8f0;
}
.compare-overview-title {
	font-size: 13px;
	font-weight: 700;
	color: #334155;
	margin-bottom: 6px;
	text-transform: uppercase;
	letter-spacing: 0.04em;
}
.compare-overview-text {
	color: #0f172a;
	font-size: 15px;
	line-height: 1.6;
}
.compare-table-wrap {
	overflow-x: auto;
	border: 1px solid #e2e8f0;
	border-radius: 16px;
	background: #fff;
}
.compare-table {
	width: 100%;
	border-collapse: collapse;
	min-width: 760px;
}
.compare-table th,
.compare-table td {
	padding: 1rem;
	border-bottom: 1px solid #e2e8f0;
	vertical-align: top;
}
.compare-table thead th {
	background: #f8fafc;
	font-size: 0.78rem;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	color: #64748b;
}
.compare-table tbody tr:last-child td {
	border-bottom: 0;
}
.compare-cell-label {
	width: 140px;
	font-size: 0.95rem;
	font-weight: 700;
	color: #0f172a;
}
.compare-cell-main {
	min-width: 0;
}
.compare-cell-status {
	width: 150px;
	text-align: center;
}
.compare-main {
	font-size: 0.96rem;
	font-weight: 600;
	color: #0f172a;
	line-height: 1.5;
	word-break: break-word;
}
.compare-helper {
	margin-top: 0.2rem;
	font-size: 0.83rem;
	color: #64748b;
	line-height: 1.45;
}
.compare-badge {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.45rem 0.8rem;
	border-radius: 999px;
	font-size: 0.8rem;
	font-weight: 700;
	white-space: nowrap;
}
.compare-badge-good {
	background: #dcfce7;
	color: #166534;
}
.compare-badge-warn {
	background: #fef3c7;
	color: #92400e;
}
.compare-badge-bad {
	background: #fee2e2;
	color: #991b1b;
}
.compare-badge-muted {
	background: #e5e7eb;
	color: #4b5563;
}
.compare-detail-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 1rem;
}
.compare-detail-card {
	padding: 1rem;
	border-radius: 16px;
	border: 1px solid #e2e8f0;
	background: #f8fafc;
}
.compare-detail-title {
	font-size: 0.9rem;
	font-weight: 700;
	color: #0f172a;
	margin-bottom: 0.75rem;
}
.compare-chip-wrap {
	display: flex;
	flex-wrap: wrap;
	gap: 0.5rem;
}
.compare-chip {
	display: inline-flex;
	align-items: center;
	padding: 0.4rem 0.75rem;
	border-radius: 999px;
	font-size: 0.82rem;
	font-weight: 600;
}
.compare-chip-good {
	background: #dcfce7;
	color: #166534;
}
.compare-chip-warn {
	background: #fef3c7;
	color: #92400e;
}
.compare-highlights {
	padding: 1rem;
	border-radius: 16px;
	border: 1px dashed #cbd5e1;
	background: #f8fafc;
}
.campaign-description-card {
	border: 1px solid rgba(13, 110, 253, 0.12);
	border-radius: 1rem;
	padding: 1rem 1.1rem;
	background: linear-gradient(180deg, rgba(13, 110, 253, 0.04), rgba(13, 110, 253, 0.01));
}
.gallery-thumb {
	opacity: 0.75;
	transition: all 0.2s ease;
	background: #f8f9fa;
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
@media (max-width: 767.98px) {
	.compare-detail-grid {
		grid-template-columns: 1fr;
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
