<template>
	<div>
		<!-- Page Header -->
		<PageHeader
			:title="$t('campaignDetail.title')"
			icon="fa-solid fa-flag"
			:breadcrumbs="[
				{ label: $t('common.home'), to: '/' },
				{ label: $t('coordinator.campaignManagement'), to: '/quan-ly-chien-dich' },
				{ label: campaign.title }
			]">
			<template #actions>
				<router-link to="/quan-ly-chien-dich" class="btn btn-outline-secondary btn-sm">
					<i class="fa-solid fa-arrow-left me-1"></i>{{ $t('common.back') }}
				</router-link>
				<button class="btn btn-primary btn-sm" @click="isEditing = true" v-if="!isEditing && canManageCampaigns">
					<i class="fa-regular fa-pen-to-square me-1"></i>{{ $t('common.edit') }}
				</button>
			</template>
		</PageHeader>

		<!-- Status Banner -->
		<div class="alert d-flex align-items-center gap-2 mb-4 border-0 shadow-sm" :class="statusAlertClass">
			<i :class="getStatusIcon(campaign.status)" class="fs-5"></i>
			<div>
				<strong>{{ getStatusLabel(campaign.status) }}</strong>
				<span class="ms-2 opacity-75" v-if="campaign.status === 'pending'">{{ $t('campaignDetail.pendingNote') }}</span>
				<span class="ms-2 opacity-75" v-if="campaign.status === 'active'">{{ $t('campaignDetail.activeNote') }}</span>
				<span class="ms-2 opacity-75" v-if="campaign.status === 'completed'">{{ $t('campaignDetail.completedNote') }}</span>
			</div>
		</div>

		<div class="row g-4">
			<!-- LEFT: Main Info -->
			<div class="col-lg-8">
				<!-- Overview Card -->
				<div class="card border-0 shadow-sm mb-4">
					<div class="campaign-banner d-flex align-items-end p-4" :style="getCampaignBannerStyle()">
						<div class="d-flex align-items-center gap-3">
							<div class="rounded-3 d-flex align-items-center justify-content-center border border-white border-opacity-25" style="width:56px;height:56px; background-color: rgba(255, 255, 255, 0.25);">
								<i :class="campaign.icon" class="text-white fs-4"></i>
							</div>
							<div class="text-white">
								<h4 class="fw-bold mb-1">{{ campaign.title }}</h4>
								<div class="d-flex flex-wrap gap-2">
									<span class="badge bg-white text-dark fw-semibold small">{{ getCategoryLabel(campaign.category) }}</span>
									<span class="badge rounded-pill" :class="getPriorityClass(campaign.priority)">{{ getPriorityLabel(campaign.priority) }}</span>
								</div>
							</div>
						</div>
					</div>
					<div class="card-body p-4">
						<h6 class="fw-bold text-dark mb-2"><i class="fa-solid fa-align-left me-2 text-primary"></i>{{ $t('campaignDetail.campaignDescription') }}</h6>
						<p class="text-muted mb-0 lh-lg">{{ campaign.description }}</p>
					</div>
				</div>

				<!-- Details Grid -->
				<div class="row g-3 mb-4">
					<div class="col-sm-6">
						<div class="card border-0 shadow-sm h-100">
							<div class="card-body p-3">
								<div class="d-flex align-items-start gap-3">
									<div class="detail-icon rounded-3 bg-danger text-white d-flex align-items-center justify-content-center flex-shrink-0 shadow-sm">
										<i class="fa-solid fa-location-dot"></i>
									</div>
									<div>
										<div class="text-muted small fw-medium mb-1">{{ $t('campaignDetail.location') }}</div>
										<div class="fw-semibold text-dark">{{ campaign.location }}</div>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-sm-6">
						<div class="card border-0 shadow-sm h-100">
							<div class="card-body p-3">
								<div class="d-flex align-items-start gap-3">
									<div class="detail-icon rounded-3 bg-primary text-white d-flex align-items-center justify-content-center flex-shrink-0 shadow-sm">
										<i class="fa-regular fa-calendar"></i>
									</div>
									<div>
										<div class="text-muted small fw-medium mb-1">{{ $t('campaignDetail.time') }}</div>
										<div class="fw-semibold text-dark">{{ campaign.startDate }} — {{ campaign.endDate }}</div>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-sm-6">
						<div class="card border-0 shadow-sm h-100">
							<div class="card-body p-3">
								<div class="d-flex align-items-start gap-3">
									<div class="detail-icon rounded-3 bg-success text-white d-flex align-items-center justify-content-center flex-shrink-0 shadow-sm">
										<i class="fa-solid fa-users"></i>
									</div>
									<div>
										<div class="text-muted small fw-medium mb-1">{{ $t('campaignDetail.volunteers') }}</div>
										<div class="fw-semibold text-dark">{{ campaign.registered }} / {{ campaign.maxVolunteers }} {{ $t('common.people') }}</div>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-sm-6">
						<div class="card border-0 shadow-sm h-100">
							<div class="card-body p-3">
								<div class="d-flex align-items-start gap-3">
									<div class="detail-icon rounded-3 bg-warning text-dark d-flex align-items-center justify-content-center flex-shrink-0 shadow-sm">
										<i class="fa-solid fa-bolt"></i>
									</div>
									<div>
										<div class="text-muted small fw-medium mb-1">{{ $t('campaignDetail.priorityLevel') }}</div>
										<div class="fw-semibold text-dark">{{ getPriorityLabel(campaign.priority) }}</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Required Skills -->
				<div class="card border-0 shadow-sm mb-4">
					<div class="card-body p-4">
						<h6 class="fw-bold text-dark mb-3"><i class="fa-solid fa-screwdriver-wrench me-2 text-primary"></i>{{ $t('campaignDetail.requiredSkills') }}</h6>
						<div class="d-flex flex-wrap gap-2" v-if="campaign.requiredSkills && campaign.requiredSkills.length > 0">
							<span v-for="skillId in campaign.requiredSkills" :key="skillId"
								class="badge bg-white text-primary border border-primary px-3 py-2 shadow-sm" style="font-size:13px">
								<i :class="getSkillIcon(skillId)" class="me-1"></i>{{ getSkillName(skillId) }}
							</span>
						</div>
						<div v-else class="text-muted small"><i class="fa-solid fa-info-circle me-1"></i>{{ $t('campaignDetail.noSpecialSkills') }}</div>
					</div>
				</div>

				<!-- Địa điểm chiến dịch (Map) -->
				<div class="card border-0 shadow-sm mb-4">
					<div class="card-body p-4">
						<h6 class="fw-bold text-dark mb-3"><i class="fa-solid fa-map-location-dot me-2 text-danger"></i>{{ $t('campaignDetail.campaignLocation') }}</h6>
						<div class="d-flex align-items-center gap-2 mb-3">
							<i class="fa-solid fa-location-dot text-danger"></i>
							<span class="fw-medium text-dark">{{ campaign.location }}</span>
						</div>
						<div id="dpv-detail-map" class="detail-map-wrapper rounded-3 border overflow-hidden mb-2"></div>
						<div class="d-flex gap-3" v-if="mapLatitude">
							<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ $t('campaignDetail.latitude') }}: {{ mapLatitude }}</span>
							<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ $t('campaignDetail.longitude') }}: {{ mapLongitude }}</span>
						</div>
					</div>
				</div>

				<!-- Registered Volunteers List -->
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom px-4 py-3">
						<div class="d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-user-group me-2 text-success"></i>{{ $t('campaignDetail.registeredVolunteers') }}</h6>
							<span class="badge bg-success text-white shadow-sm">{{ volunteers.length }} {{ $t('common.people') }}</span>
						</div>
					</div>
					<div class="card-body p-0">
						<div class="table-responsive">
							<table class="table table-hover align-middle mb-0">
								<thead class="bg-light">
									<tr>
										<th class="fw-semibold text-muted small text-uppercase py-3 ps-4 border-0">{{ $t('campaignDetail.volunteerCol') }}</th>
										<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-md-table-cell">{{ $t('campaignDetail.skillsCol') }}</th>
										<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-sm-table-cell">{{ $t('campaignDetail.areaCol') }}</th>
										<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('campaignDetail.statusCol') }}</th>
										<th v-if="canManageCampaigns" class="fw-semibold text-muted small text-uppercase py-3 pe-4 border-0 text-end">{{ $t('campaignDetail.actionCol') }}</th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="vol in volunteers" :key="vol.registrationId">
										<td class="ps-4">
											<div class="d-flex align-items-center gap-2">
												<div class="avatar-circle bg-primary text-white d-flex align-items-center justify-content-center rounded-circle fw-bold shadow-sm" style="width:36px;height:36px;font-size:13px">
													{{ vol.name.charAt(0) }}
												</div>
												<div>
													<div class="fw-semibold text-dark small">{{ vol.name }}</div>
													<div class="text-muted" style="font-size:11px">{{ vol.email }}</div>
												</div>
											</div>
										</td>
										<td class="d-none d-md-table-cell">
											<div class="d-flex flex-wrap gap-1">
												<span v-for="s in vol.skills" :key="s" class="badge bg-light text-muted border" style="font-size:11px">{{ s }}</span>
											</div>
										</td>
										<td class="d-none d-sm-table-cell"><span class="text-muted small">{{ vol.area }}</span></td>
										<td class="text-center">
											<span class="badge rounded-pill" :class="getVolunteerStatusClass(vol.status)">
												{{ getVolunteerStatusLabel(vol.status) }}
											</span>
											<div class="text-muted mt-1" style="font-size:11px" v-if="getVolunteerStatusTime(vol)">
												{{ formatDateTime(getVolunteerStatusTime(vol)) }}
											</div>
										</td>
										<td v-if="canManageCampaigns" class="text-end pe-4">
											<div v-if="shouldShowVolunteerStatusSelect(vol)" class="d-flex justify-content-end align-items-center gap-2">
												<select class="form-select form-select-sm volunteer-status-select" style="min-width: 180px;" v-model="vol.pendingStatus" :disabled="vol.updating || !canEditVolunteerStatus(vol)">
													<option v-for="option in getVolunteerStatusOptions(vol)" :key="option.value" :value="option.value">
														{{ option.label }}
													</option>
												</select>
												<button
													v-if="canEditVolunteerStatus(vol)"
													class="btn btn-sm btn-outline-primary"
													@click="updateVolunteerStatus(vol)"
													:disabled="vol.updating || vol.pendingStatus === vol.status"
												>
													<i :class="vol.updating ? 'fa-solid fa-spinner fa-spin' : 'fa-solid fa-floppy-disk'" class="me-1"></i>{{ $t('campaignDetail.saveStatusBtn') }}
												</button>
											</div>
											<span v-else class="text-muted small">—</span>
										</td>
									</tr>
									<tr v-if="volunteers.length === 0">
										<td :colspan="canManageCampaigns ? 5 : 4" class="text-center py-4 text-muted">
											<i class="fa-solid fa-user-slash d-block fs-3 mb-2 opacity-25"></i>
											{{ $t('campaignDetail.noVolunteers') }}
										</td>
									</tr>
								</tbody>
							</table>
						</div>
					</div>
				</div>

				<!-- Rate Volunteers (only for completed campaigns) -->
				<div class="card border-0 shadow-sm mt-4" v-if="campaign.status === 'completed'">
					<div class="card-header bg-white border-bottom px-4 py-3">
						<div class="d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-star me-2 text-warning"></i>{{ $t('campaignDetail.rateVolunteers') }}</h6>
							<span class="badge bg-warning text-dark px-3 py-2">{{ ratedCount }}/{{ volunteers.length }} {{ $t('campaignDetail.rated') }}</span>
						</div>
					</div>
					<div class="card-body p-0">
						<div class="table-responsive">
							<table class="table table-hover align-middle mb-0">
								<thead class="bg-light">
									<tr>
										<th class="fw-semibold text-muted small text-uppercase py-3 ps-4 border-0">{{ $t('campaignDetail.tnvCol') }}</th>
										<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('campaignDetail.ratingCol') }}</th>
										<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-md-table-cell">{{ $t('campaignDetail.commentCol') }}</th>
										<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center" style="width:100px"></th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="vol in volunteers" :key="'rate-'+vol.id">
										<td class="ps-4">
											<div class="d-flex align-items-center gap-2">
												<div class="avatar-circle bg-primary text-white d-flex align-items-center justify-content-center rounded-circle fw-bold shadow-sm" style="width:32px;height:32px;font-size:12px">{{ vol.name.charAt(0) }}</div>
												<span class="fw-semibold small">{{ vol.name }}</span>
											</div>
										</td>
										<td class="text-center">
											<div class="d-flex justify-content-center gap-1">
												<i v-for="i in 5" :key="i" class="rating-star"
													:class="i <= (vol.rating || 0) ? 'fa-solid fa-star text-warning' : 'fa-regular fa-star text-muted'"
													@click="setVolRating(vol, i)" style="font-size:16px; cursor:pointer"></i>
											</div>
										</td>
										<td class="d-none d-md-table-cell">
											<span class="text-muted small text-truncate d-inline-block" style="max-width:160px" v-if="vol.ratingComment">{{ vol.ratingComment }}</span>
											<span class="text-muted small opacity-50" v-else>—</span>
										</td>
										<td class="text-center">
											<button class="btn btn-sm btn-outline-primary rounded-pill px-3" @click="openRateModal(vol)">
												<i class="fa-solid fa-pen-to-square me-1"></i>{{ vol.rating ? $t('campaignDetail.editRateBtn') : $t('campaignDetail.rateBtn') }}
											</button>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
					</div>
					<div class="card-footer bg-white border-top text-end py-3 px-4">
						<button class="btn btn-success rounded-pill px-4" :disabled="ratedCount === 0" @click="saveAllRatings">
							<i class="fa-solid fa-floppy-disk me-1"></i>{{ $t('campaignDetail.saveAllRatings') }}
						</button>
					</div>
				</div>
			</div>

			<!-- RIGHT: Sidebar -->
			<div class="col-lg-4">
				<!-- Progress Card -->
				<div class="card border-0 shadow-sm mb-4">
					<div class="card-body p-4 text-center">
						<h6 class="fw-bold text-dark mb-3">{{ $t('campaignDetail.registrationProgress') }}</h6>
						<div class="progress-circle-wrapper mx-auto mb-3">
							<svg viewBox="0 0 120 120" class="progress-circle">
								<circle cx="60" cy="60" r="52" fill="none" stroke="#e9ecef" stroke-width="10" />
								<circle cx="60" cy="60" r="52" fill="none" stroke="#0d6efd" stroke-width="10"
									stroke-linecap="round"
									:stroke-dasharray="circumference"
									:stroke-dashoffset="circumference - (circumference * progressPercent / 100)"
									transform="rotate(-90 60 60)" />
							</svg>
							<div class="progress-circle-text">
								<div class="fs-3 fw-bold text-primary">{{ progressPercent }}%</div>
								<div class="text-muted small">{{ $t('campaignDetail.complete') }}</div>
							</div>
						</div>
						<div class="bg-light rounded-3 p-3">
							<div class="row text-center">
								<div class="col-6 border-end">
									<div class="fs-5 fw-bold text-success">{{ campaign.registered }}</div>
									<div class="text-muted" style="font-size:11px">{{ $t('campaignDetail.registered') }}</div>
								</div>
								<div class="col-6">
									<div class="fs-5 fw-bold text-dark">{{ campaign.maxVolunteers }}</div>
									<div class="text-muted" style="font-size:11px">{{ $t('campaignDetail.needed') }}</div>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Coordinator Info -->
				<div class="card border-0 shadow-sm mb-4">
					<div class="card-body p-4">
						<h6 class="fw-bold text-dark mb-3"><i class="fa-solid fa-user-tie me-2 text-primary"></i>{{ $t('campaignDetail.coordinatorInfo') }}</h6>
						<div class="d-flex align-items-center gap-3">
							<div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center fw-bold" style="width:44px;height:44px">
								{{ campaign.coordinatorName ? campaign.coordinatorName.charAt(0) : 'Đ' }}
							</div>
							<div>
								<div class="fw-semibold text-dark">{{ campaign.coordinatorName || '—' }}</div>
								<div class="text-muted small">{{ campaign.coordinatorEmail || '—' }}</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Quick Actions -->
				<div class="card border-0 shadow-sm">
					<div class="card-body p-4">
						<h6 class="fw-bold text-dark mb-3"><i class="fa-solid fa-bolt me-2 text-warning"></i>{{ $t('campaignDetail.quickActions') }}</h6>
						<div class="d-grid gap-2">
							<button v-if="canManageCampaigns && campaign.status === 'approved'" class="btn btn-outline-warning btn-sm d-flex align-items-center gap-2" @click="confirmStatusChange('dang_dien_ra')">
								<i class="fa-solid fa-play" style="width:16px"></i><span>{{ $t('coordinator.startCampaignBtn') }}</span>
							</button>
							<button v-if="canManageCampaigns && campaign.status === 'active'" class="btn btn-outline-success btn-sm d-flex align-items-center gap-2" @click="confirmStatusChange('hoan_thanh')">
								<i class="fa-solid fa-flag-checkered" style="width:16px"></i><span>{{ $t('coordinator.completeCampaignBtn') }}</span>
							</button>
							<button v-if="canViewCoordination" class="btn btn-outline-primary btn-sm d-flex align-items-center gap-2" @click="$router.push({ path: '/dieu-phoi-nhan-su', query: { campaign_id: String(campaign.id) } })">
								<i class="fa-solid fa-people-arrows" style="width:16px"></i><span>Đi đến màn điều phối</span>
							</button>
							<button class="btn btn-outline-success btn-sm d-flex align-items-center gap-2">
								<i class="fa-solid fa-bell" style="width:16px"></i><span>{{ $t('campaignDetail.sendAssignmentNotification') }}</span>
							</button>
							<button class="btn btn-outline-secondary btn-sm d-flex align-items-center gap-2">
								<i class="fa-solid fa-file-export" style="width:16px"></i><span>{{ $t('campaignDetail.exportReport') }}</span>
							</button>
							<button class="btn btn-outline-danger btn-sm d-flex align-items-center gap-2" v-if="campaign.status !== 'cancelled' && campaign.status !== 'completed'">
								<i class="fa-solid fa-ban" style="width:16px"></i><span>{{ $t('campaignDetail.cancelCampaign') }}</span>
							</button>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Rate Modal -->
		<div class="modal fade" :class="{ show: showRateModal }" :style="showRateModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-star text-warning me-2"></i>{{ $t('campaignDetail.rateVolunteersTitle') }}</h5>
						<button type="button" class="btn-close" @click="showRateModal = false"></button>
					</div>
					<div class="modal-body" v-if="rateTarget">
						<div class="bg-light rounded-3 p-3 mb-3 d-flex align-items-center gap-3">
							<div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center fw-bold" style="width:44px;height:44px;font-size:16px">{{ rateTarget.name.charAt(0) }}</div>
							<div>
								<div class="fw-bold">{{ rateTarget.name }}</div>
								<div class="text-muted small">{{ rateTarget.email }}</div>
							</div>
						</div>
						<div class="text-center mb-3">
							<label class="form-label small fw-bold d-block">{{ $t('campaignDetail.ratingLabel') }}</label>
							<div class="d-flex justify-content-center gap-2">
								<i v-for="i in 5" :key="i" class="rating-star-lg"
									:class="i <= modalRating ? 'fa-solid fa-star text-warning' : 'fa-regular fa-star text-muted'"
									@click="modalRating = i"></i>
							</div>
							<span class="text-muted small mt-1 d-block">{{ getRatingLabel(modalRating) }}</span>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('campaignDetail.commentLabel') }}</label>
							<textarea class="form-control" rows="3" :placeholder="$t('campaignDetail.commentPlaceholder')" v-model="modalComment"></textarea>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showRateModal = false">{{ $t('common.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="confirmRateModal" :disabled="!modalRating">
							<i class="fa-solid fa-check me-1"></i>{{ $t('common.confirm') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showRateModal" @click="showRateModal = false"></div>

		<ConfirmModal
			ref="statusModal"
			modalId="detailStatusCampaignModal"
			:title="statusConfirmConfig.title"
			:message="statusConfirmConfig.message"
			:detail="statusConfirmConfig.detail"
			:detailList="statusConfirmConfig.detailList"
			:detailListTitle="statusConfirmConfig.detailListTitle"
			:icon="statusConfirmConfig.icon"
			:variant="statusConfirmConfig.variant"
			:confirmText="statusConfirmConfig.confirmText"
			confirmIcon="fa-solid fa-check"
			:dismissOnConfirm="false"
			@confirm="updateCampaignStatus" />
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue'
import ConfirmModal from '../../components/ConfirmModal.vue'
import api from '../../services/api'
import { hasPermission } from '../../utils/permissions'

const PRIORITY_MAP = { khan_cap: 'urgent', cao: 'high', trung_binh: 'medium', thap: 'low' };
const STATUS_MAP = { cho_duyet: 'pending', tu_choi: 'rejected', da_duyet: 'approved', dang_dien_ra: 'active', hoan_thanh: 'completed', da_huy: 'cancelled', yeu_cau_huy: 'pending_cancel', nhap: 'draft' };

export default {
	name: 'ChiTietChienDich',
	components: { PageHeader, ConfirmModal },
	inject: ['toast'],
	data() {
		return {
			isEditing: false,
			isLoading: true,
			circumference: 2 * Math.PI * 52,
			detailMap: null,
			detailMarker: null,
			mapLatitude: null,
			mapLongitude: null,
			campaign: {
				id: 0, title: '', description: '', category: '', priority: 'medium',
				location: '', latitude: null, longitude: null,
				startDate: '', endDate: '', maxVolunteers: 0, minVolunteers: 1,
				registered: 0, status: 'pending', requiredSkills: [],
				icon: 'fa-solid fa-flag',
				color: 'linear-gradient(135deg, #0d6efd, #6610f2)',
				coverUrl: null,
				coordinatorName: '', coordinatorEmail: '',
			},
			campaignTypes: [],
			skillsList: [],
			volunteers: [],
			showRateModal: false,
			rateTarget: null,
			modalRating: 0,
			modalComment: '',
			statusTarget: null,
			nextStatusTarget: null,
			statusForceProceed: false,
			statusConfirmConfig: {
				title: '',
				message: '',
				detail: '',
				detailList: [],
				detailListTitle: '',
				icon: '',
				variant: '',
				confirmText: '',
			},
		}
	},
	computed: {
		campaignId() { return this.$route.params.id; },
		availableSkills() {
			if (this.skillsList.length > 0) {
				return this.skillsList.map(s => ({
					id: s.id,
					name: s.ten,
					icon: s.bieu_tuong ? `fa-solid ${s.bieu_tuong}` : 'fa-solid fa-star'
				}));
			}
			return Array.from({ length: 10 }, (_, i) => ({
				id: i + 1,
				name: this.$t(`skillNames.${i + 1}`),
				icon: ['fa-solid fa-calendar-check','fa-solid fa-boxes-stacked','fa-solid fa-kit-medical','fa-solid fa-bullhorn','fa-solid fa-chalkboard-teacher','fa-solid fa-laptop-code','fa-solid fa-utensils','fa-solid fa-truck','fa-solid fa-brain','fa-solid fa-camera'][i]
			}));
		},
		progressPercent() { return this.campaign.maxVolunteers ? Math.round(this.campaign.registered / this.campaign.maxVolunteers * 100) : 0; },
		ratedCount() { return this.volunteers.filter(v => v.rating > 0).length; },
		canManageCampaigns() {
			try {
				const user = JSON.parse(localStorage.getItem('user') || 'null');
				return hasPermission(user, 'volunteer_campaigns.manage');
			} catch (_error) {
				return false;
			}
		},
		canViewCoordination() {
			try {
				const user = JSON.parse(localStorage.getItem('user') || 'null');
				return hasPermission(user, 'campaign_coordination.view');
			} catch (_error) {
				return false;
			}
		},
		statusAlertClass() {
				const m = { approved: 'alert-info', active: 'alert-success', pending: 'alert-warning', pending_cancel: 'alert-danger', completed: 'alert-secondary', cancelled: 'alert-danger', rejected: 'alert-dark', draft: 'alert-light' };
				return m[this.campaign.status] || 'alert-info';
		}
	},
	methods: {
		getCategoryLabel(cat) {
			const found = this.campaignTypes.find(t => t.id === cat || String(t.id) === String(cat));
			return found ? found.ten : (cat || '—');
		},
		getPriorityLabel(p) { return this.$t(`priorities.${p}`); },
		getPriorityClass(p) { return { urgent: 'bg-danger text-white', high: 'bg-warning text-dark', medium: 'bg-info text-white', low: 'bg-light text-muted border' }[p] || 'bg-secondary'; },
		getStatusLabel(s) { return this.$t(`statuses.${s}`); },
			getStatusIcon(s) { return { approved: 'fa-solid fa-badge-check', active: 'fa-solid fa-circle-play', pending: 'fa-solid fa-hourglass-half', completed: 'fa-solid fa-circle-check', cancelled: 'fa-solid fa-ban', rejected: 'fa-solid fa-circle-xmark', pending_cancel: 'fa-solid fa-clock-rotate-left', draft: 'fa-solid fa-file-lines' }[s] || ''; },
		getCampaignBannerStyle() {
			if (this.campaign.coverUrl) {
				return {
					background: `linear-gradient(rgba(15,23,42,.28), rgba(15,23,42,.28)), url(${this.campaign.coverUrl}) center/cover`,
				};
			}
			return { background: this.campaign.color };
		},
		getSkillName(id) { const s = this.availableSkills.find(s => s.id === id); return s ? s.name : ''; },
		getSkillIcon(id) { const s = this.availableSkills.find(s => s.id === id); return s ? s.icon : ''; },
		getRatingLabel(r) { return { 1: this.$t('ratings.1'), 2: this.$t('ratings.2'), 3: this.$t('ratings.3'), 4: this.$t('ratings.4'), 5: this.$t('ratings.5') }[r] || ''; },
		getVolunteerStatusLabel(status) {
			return this.$t(`campaignRegistration.statuses.${status}`);
		},
		getVolunteerStatusClass(status) {
			return {
				da_dang_ky: 'bg-warning text-dark',
				da_duyet: 'bg-info text-white',
				da_xac_nhan: 'bg-success text-white',
				tu_choi: 'bg-danger text-white',
				dang_tham_gia: 'bg-primary text-white',
				hoan_thanh: 'bg-secondary text-white',
				da_huy: 'bg-light text-muted border',
			}[status] || 'bg-light text-muted border';
		},
		getVolunteerStatusTime(volunteer) {
			if (volunteer.status === 'da_huy') return volunteer.cancelledAt || volunteer.registeredAt || null;
			if (volunteer.status === 'tu_choi') return volunteer.cancelledAt || volunteer.reviewedAt || volunteer.registeredAt || null;
			if (volunteer.status === 'da_duyet') return volunteer.reviewedAt || volunteer.registeredAt || null;
			if (volunteer.status === 'da_xac_nhan') return volunteer.confirmedAt || volunteer.reviewedAt || volunteer.registeredAt || null;
			return volunteer.reviewedAt || volunteer.registeredAt || null;
		},
		canEditVolunteerStatus(volunteer) {
			if (!this.canManageCampaigns) return false;
			if (!['approved', 'pending', 'draft'].includes(this.campaign.status)) return false;
			return volunteer.status === 'da_xac_nhan';
		},
		shouldShowVolunteerStatusSelect(volunteer) {
			if (!this.canManageCampaigns) return false;
			if (!['approved', 'pending', 'draft'].includes(this.campaign.status)) return false;
			return ['da_dang_ky', 'da_xac_nhan', 'tu_choi'].includes(volunteer.status);
		},
		getVolunteerStatusOptions(volunteer) {
			const currentStatus = volunteer?.status || 'da_dang_ky';
			const currentOption = {
				value: currentStatus,
				label: this.getVolunteerStatusLabel(currentStatus),
			};

			if (currentStatus !== 'da_xac_nhan') {
				return [currentOption];
			}

			return [
				currentOption,
				...['da_duyet', 'tu_choi'].map((value) => ({
					value,
					label: this.getVolunteerStatusLabel(value),
				})),
			];
		},
		getDefaultPendingStatus(status) {
			return status || 'da_dang_ky';
		},
		formatDateTime(value) {
			if (!value) return '';
			const normalized = String(value).replace(' ', 'T');
			const date = new Date(normalized);
			if (Number.isNaN(date.getTime())) return value;
			return date.toLocaleString('vi-VN');
		},
		setVolRating(vol, star) { vol.rating = star; },
		confirmStatusChange(nextStatus) {
			this.statusTarget = this.campaign;
			this.nextStatusTarget = nextStatus;
			this.statusForceProceed = false;
			this.statusConfirmConfig = {
				title: nextStatus === 'dang_dien_ra' ? this.$t('coordinator.startCampaignTitle') : this.$t('coordinator.completeCampaignTitle'),
				message: nextStatus === 'dang_dien_ra'
					? this.$t('coordinator.startCampaignMsg', { title: this.campaign.title })
					: this.$t('coordinator.completeCampaignMsg', { title: this.campaign.title }),
				detail: nextStatus === 'dang_dien_ra'
					? this.$t('coordinator.startCampaignDetail')
					: this.$t('coordinator.completeCampaignDetail'),
				detailList: [],
				detailListTitle: '',
				icon: nextStatus === 'dang_dien_ra' ? 'fa-solid fa-play-circle' : 'fa-solid fa-flag-checkered',
				variant: nextStatus === 'dang_dien_ra' ? 'warning' : 'success',
				confirmText: nextStatus === 'dang_dien_ra' ? this.$t('coordinator.startCampaignBtn') : this.$t('coordinator.completeCampaignBtn'),
			};
			this.$refs.statusModal.show();
		},
		async updateCampaignStatus() {
			if (!this.statusTarget || !this.nextStatusTarget) return;
			let shouldResetState = true;
			try {
				const res = await api.put(`/tinh-nguyen-vien/chien-dich/${this.statusTarget.id}/trang-thai`, {
					trang_thai: this.nextStatusTarget,
					bo_qua_canh_bao: this.statusForceProceed,
				});
				if (res.data.status === 1) {
					this.toast?.showToast('success', this.$t('common.success'), res.data.message);
					this.$refs.statusModal.hide();
					await this.loadCampaignDetail();
				}
			} catch (err) {
				const warning = err.response?.data?.warning;
				if (warning && this.nextStatusTarget === 'dang_dien_ra') {
					shouldResetState = false;
					this.statusForceProceed = true;
					const detailParts = [];
					(warning?.warning_items || []).forEach((item) => {
						if (item?.message) {
							detailParts.push(item.message);
						}
					});
					if (warning?.so_luong_toi_thieu && Number.isFinite(Number(warning?.so_xac_nhan))) {
						detailParts.push(this.$t('coordinator.startCampaignWarningMsg', {
							confirmed: warning.so_xac_nhan ?? 0,
							minimum: warning.so_luong_toi_thieu ?? 0,
						}));
					}
					if (warning?.so_chua_xac_nhan) {
						detailParts.push(this.$t('coordinator.startCampaignWarningDetail', {
							pending: warning.so_chua_xac_nhan ?? 0,
						}));
					}
					if (warning?.bat_dau_som_hon_du_kien && warning?.ngay_bat_dau_du_kien) {
						detailParts.push(this.$t('coordinator.startCampaignEarlyWarningDetail', {
							date: warning.ngay_bat_dau_du_kien,
						}));
					}
					if (warning?.chi_tiet) {
						detailParts.push(warning.chi_tiet);
					}
					this.statusConfirmConfig = {
						title: warning?.bat_dau_som_hon_du_kien
							? this.$t('coordinator.startCampaignEarlyWarningTitle')
							: this.$t('coordinator.startCampaignWarningTitle'),
						message: warning?.message || this.$t('coordinator.startCampaignWarningTitle'),
						detail: '',
						detailList: detailParts,
						detailListTitle: 'Các cảnh báo cần lưu ý',
						icon: 'fa-solid fa-triangle-exclamation',
						variant: 'warning',
						confirmText: this.$t('coordinator.startCampaignProceedBtn'),
					};
					this.$refs.statusModal.show();
					return;
				}

				const msg = err.response?.data?.message || 'Có lỗi xảy ra.';
				this.toast?.showToast('error', this.$t('common.error'), msg);
			} finally {
				if (shouldResetState) {
					this.statusTarget = null;
					this.nextStatusTarget = null;
					this.statusForceProceed = false;
				}
			}
		},
		async updateVolunteerStatus(volunteer) {
			if (!volunteer?.registrationId || volunteer.pendingStatus === volunteer.status) return;
			volunteer.updating = true;
			try {
				const response = await api.put(`/tinh-nguyen-vien/chien-dich/${this.campaignId}/dang-ky/${volunteer.registrationId}/trang-thai`, {
					trang_thai: volunteer.pendingStatus,
				});
				if (response.data.status === 1) {
					this.toast?.showToast('success', this.$t('common.success'), response.data.message);
					await this.loadCampaignDetail();
				}
			} catch (error) {
				const message = error.response?.data?.message || 'Không thể cập nhật trạng thái tham gia.';
				this.toast?.showToast('error', this.$t('common.error'), message);
				volunteer.pendingStatus = volunteer.status;
			} finally {
				volunteer.updating = false;
			}
		},
		openRateModal(vol) {
			this.rateTarget = vol;
			this.modalRating = vol.rating || 0;
			this.modalComment = vol.ratingComment || '';
			this.showRateModal = true;
		},
		confirmRateModal() {
			if (this.rateTarget) {
				this.rateTarget.rating = this.modalRating;
				this.rateTarget.ratingComment = this.modalComment;
			}
			this.showRateModal = false;
		},
		saveAllRatings() {
			let savedMsg = this.$t('campaignDetail.savedRatings');
			savedMsg = savedMsg.replace('{0}', this.ratedCount);
			alert(savedMsg);
		},
		lightenColor(hex) {
			if (!hex || hex.length < 7) return '#6ea8fe';
			let r = parseInt(hex.slice(1, 3), 16);
			let g = parseInt(hex.slice(3, 5), 16);
			let b = parseInt(hex.slice(5, 7), 16);
			r = Math.min(255, r + 40);
			g = Math.min(255, g + 40);
			b = Math.min(255, b + 40);
			return `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
		},

		// ===== API =====
		async loadCampaignDetail() {
			this.isLoading = true;
			try {
				const res = await api.get(`/tinh-nguyen-vien/chien-dich/${this.campaignId}`);
				if (res.data.status === 1) {
					const cd = res.data.data;
					const loai = cd.loai_chien_dich;
					this.campaign = {
						id: cd.id,
						title: cd.tieu_de,
						description: cd.mo_ta || '',
						category: cd.loai_chien_dich_id || '',
						priority: PRIORITY_MAP[cd.muc_do_uu_tien] || 'medium',
						location: cd.dia_diem,
						latitude: cd.vi_do,
						longitude: cd.kinh_do,
						startDate: cd.ngay_bat_dau,
						endDate: cd.ngay_ket_thuc,
						actualStartAt: cd.thoi_gian_bat_dau_thuc_te,
						actualEndAt: cd.thoi_gian_ket_thuc_thuc_te,
						maxVolunteers: cd.so_luong_toi_da,
						minVolunteers: cd.so_luong_toi_thieu || 1,
						registered: cd.so_dang_ky || 0,
						status: STATUS_MAP[cd.trang_thai] || cd.trang_thai,
						requiredSkills: cd.ky_nang_ids || [],
						coverUrl: cd.anh_bia || null,
						icon: loai ? `fa-solid ${loai.bieu_tuong || 'fa-flag'}` : 'fa-solid fa-flag',
						color: loai ? `linear-gradient(135deg, ${loai.mau_sac || '#0d6efd'}, ${this.lightenColor(loai.mau_sac || '#0d6efd')})` : 'linear-gradient(135deg, #0d6efd, #6610f2)',
						coordinatorName: cd.kiem_duyet_vien?.ho_ten || '',
						coordinatorEmail: cd.kiem_duyet_vien?.email || '',
					};
					this.volunteers = (cd.danh_sach_dang_ky || []).map((item) => {
						const nguoiDung = item.nguoi_dung || {};
						return {
							id: item.nguoi_dung_id || item.id,
							registrationId: item.id,
							name: nguoiDung.ho_ten || '—',
							email: nguoiDung.email || '—',
							skills: (nguoiDung.ky_nangs || []).map((kyNang) => kyNang.ten),
							area: (nguoiDung.khu_vucs || []).map((khuVuc) => khuVuc.ten).join(', ') || '—',
							confirmed: ['da_duyet', 'dang_tham_gia', 'hoan_thanh'].includes(item.trang_thai),
							status: item.trang_thai,
							pendingStatus: this.getDefaultPendingStatus(item.trang_thai),
							registeredAt: item.dang_ky_luc || null,
							reviewedAt: item.duyet_luc || null,
							confirmedAt: item.xac_nhan_luc || null,
							cancelledAt: item.huy_luc || null,
							note: item.ghi_chu || '',
							updating: false,
							rating: 0,
							ratingComment: ''
						};
					});
					this.$nextTick(() => this.geocodeAndShowMap());
				}
			} catch (err) {
				console.error('Lỗi tải chi tiết chiến dịch:', err);
				if (this.toast) this.toast.showToast('error', 'Lỗi', 'Không tải được chi tiết chiến dịch.');
			} finally {
				this.isLoading = false;
			}
		},
		async loadCampaignTypes() {
			try {
				const res = await api.get('/danh-muc/loai-chien-dich');
				if (res.data.status === 1) this.campaignTypes = res.data.data;
			} catch (err) { console.error(err); }
		},
		async loadSkills() {
			try {
				const res = await api.get('/danh-muc/ky-nang');
				if (res.data.status === 1) this.skillsList = res.data.data;
			} catch (err) { console.error(err); }
		},
		// ===== Map =====
		initDetailMap(lat, lng) {
			this.$nextTick(() => {
				const container = document.getElementById('dpv-detail-map');
				if (!container || !window.L) return;
				if (this.detailMap) { this.detailMap.remove(); this.detailMap = null; }

				this.detailMap = window.L.map(container, {
					center: [lat, lng],
					zoom: 15,
					zoomControl: true,
					attributionControl: false,
					scrollWheelZoom: false
				});

				window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
					maxZoom: 19
				}).addTo(this.detailMap);

				const pinIcon = window.L.divIcon({
					html: '<div class="custom-pin"><i class="fa-solid fa-location-dot"></i></div>',
					iconSize: [36, 36],
					iconAnchor: [18, 36],
					className: 'custom-pin-wrapper'
				});

				this.detailMarker = window.L.marker([lat, lng], {
					draggable: false,
					icon: pinIcon
				}).addTo(this.detailMap);

				this.mapLatitude = lat.toFixed(7);
				this.mapLongitude = lng.toFixed(7);
			});
		},
		async geocodeAndShowMap() {
			if (!this.campaign) return;

			if (this.campaign.latitude && this.campaign.longitude) {
				this.initDetailMap(parseFloat(this.campaign.latitude), parseFloat(this.campaign.longitude));
				return;
			}

			if (!this.campaign.location) return;
			try {
				let address = this.campaign.location;
				address = address.replace(/^[A-Z0-9]{4,8}\+[A-Z0-9]{2,}\s*,?\s*/g, '');

				let query = encodeURIComponent(address);
				let url = `https://nominatim.openstreetmap.org/search?format=json&q=${query}&countrycodes=vn&limit=1`;
				let res = await fetch(url, { headers: { 'Accept-Language': 'vi' } });
				let data = await res.json();

				if ((!data || data.length === 0) && address.includes(',')) {
					const fallbackAddress = address.substring(address.indexOf(',') + 1).trim();
					const fallbackUrl = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(fallbackAddress)}&countrycodes=vn&limit=1`;
					res = await fetch(fallbackUrl, { headers: { 'Accept-Language': 'vi' } });
					data = await res.json();
				}

				if (data && data.length > 0) {
					this.initDetailMap(parseFloat(data[0].lat), parseFloat(data[0].lon));
				} else {
					this.initDetailMap(16.0544, 108.2022);
				}
			} catch {
				this.initDetailMap(16.0544, 108.2022);
			}
		}
	},
	mounted() {
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
			script.onload = () => this.geocodeAndShowMap();
			document.head.appendChild(script);
		}
		this.loadCampaignTypes();
		this.loadSkills();
		this.loadCampaignDetail();
	},
	beforeUnmount() {
		if (this.detailMap) { this.detailMap.remove(); this.detailMap = null; }
	}
}
</script>

<style scoped>
.campaign-banner {
	min-height: 140px;
	border-radius: 0.5rem 0.5rem 0 0;
}

.detail-icon {
	width: 40px;
	height: 40px;
}

.progress-circle-wrapper {
	width: 130px;
	height: 130px;
	position: relative;
}

.progress-circle {
	width: 100%;
	height: 100%;
}

.progress-circle circle:last-child {
	transition: stroke-dashoffset 0.6s ease;
}

.progress-circle-text {
	position: absolute;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -50%);
	text-align: center;
}

.detail-map-wrapper {
	height: 280px;
	width: 100%;
	z-index: 0;
}

.volunteer-status-select {
	padding-right: 2.25rem;
}

.rating-star {
	transition: transform 0.15s ease;
}
.rating-star:hover {
	transform: scale(1.2);
}

.rating-star-lg {
	font-size: 28px;
	cursor: pointer;
	transition: transform 0.15s ease;
}
.rating-star-lg:hover {
	transform: scale(1.15);
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
	animation: detail-pin-bounce 0.4s ease;
}
@keyframes detail-pin-bounce {
	0% { transform: translateY(-20px); opacity: 0; }
	60% { transform: translateY(4px); }
	100% { transform: translateY(0); opacity: 1; }
}
</style>
