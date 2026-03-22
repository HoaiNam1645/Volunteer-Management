<template>
	<div>
		<!-- Page Header -->
		<PageHeader
			:title="$t('coordinator.monitoringReport')"
			icon="fa-solid fa-chart-line"
			:breadcrumbs="[{ label: $t('common.home'), to: '/'}, { label: $t('coordinator.campaignManagement'), to: '/quan-ly-chien-dich'}, { label: $t('coordinator.monitoringReport') }]">
			<template #actions>
				<button class="btn btn-outline-success shadow-sm btn-sm" @click="exportReport" :disabled="!canManageReportMonitoring">
					<i class="fa-solid fa-file-export me-1"></i>{{ $t('coordinator.exportReportBtn') }}
				</button>
			</template>
		</PageHeader>

		<!-- Campaign Selector -->
		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body py-3">
				<div class="row g-3 align-items-center">
					<div class="col-md-5">
						<label class="form-label fw-semibold small mb-1"><i class="fa-solid fa-flag text-primary me-1"></i>{{ $t('coordinator.selectCampaignLabel') }}</label>
						<select class="form-select" v-model="selectedCampaignId" @change="loadCampaignData">
							<option value="">{{ $t('coordinator.selectCampaignPlaceholder') }}</option>
							<option v-for="c in campaigns" :key="c.id" :value="c.id">{{ c.name }}</option>
						</select>
					</div>
					<div class="col-md-4" v-if="activeCampaign">
						<div class="d-flex align-items-center gap-3 h-100 pt-3">
							<div class="camp-mini-stat">
								<span class="text-muted small">{{ $t('coordinator.totalVolsLabel') }}</span>
								<strong class="text-primary">{{ activeCampaign.totalVolunteers }}</strong>
							</div>
							<div class="camp-mini-stat">
								<span class="text-muted small">{{ $t('coordinator.confirmedLabel') }}</span>
								<strong class="text-success">{{ activeCampaign.confirmed }}</strong>
							</div>
							<div class="camp-mini-stat">
								<span class="text-muted small">{{ $t('coordinator.statusLabel') }}</span>
								<span class="badge rounded-pill" :class="getStatusClass(activeCampaign.status)">{{ getStatusLabel(activeCampaign.status) }}</span>
							</div>
						</div>
					</div>
					<div class="col-md-3 text-end" v-if="activeCampaign">
						<div class="pt-3">
							<div class="d-flex align-items-center justify-content-end gap-1 mb-1">
								<span class="small text-muted">{{ $t('coordinator.progressLabel') }}</span>
								<strong class="small text-primary">{{ Math.round(activeCampaign.confirmed / activeCampaign.totalVolunteers * 100) }}%</strong>
							</div>
							<div class="progress" style="height: 8px;">
								<div class="progress-bar bg-success" :style="{ width: (activeCampaign.confirmed / activeCampaign.totalVolunteers * 100) + '%' }"></div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Content Area (shown when campaign selected) -->
		<div v-if="activeCampaign">
			<!-- Stats Row -->
			<StatCards :cards="statsCards" />

			<!-- Tab Navigation -->
			<ul class="nav nav-tabs nav-tabs-custom border-bottom-0 flex-nowrap overflow-auto mb-0">
				<li class="nav-item" v-for="tab in tabs" :key="tab.value">
					<a class="nav-link px-3 px-md-4 py-2 fw-medium text-nowrap"
						:class="{ 'active text-primary': activeTab === tab.value, 'text-muted': activeTab !== tab.value }"
						href="#" @click.prevent="activeTab = tab.value">
						<i :class="tab.icon" class="me-1"></i>{{ tab.label }}
					</a>
				</li>
			</ul>

			<!-- TAB: Tracking -->
			<div class="card border-0 shadow-sm mb-4" v-if="activeTab === 'tracking'">
				<div class="card-header bg-white py-3">
					<div class="row g-2 align-items-center">
						<div class="col-md-4">
							<div class="input-group input-group-sm">
								<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
								<input type="text" class="form-control form-control-sm bg-light border-start-0 ps-0" :placeholder="$t('coordinator.searchVolunteerPlaceholder')" v-model="trackingSearch">
							</div>
						</div>
						<div class="col-md-3">
							<select class="form-select form-select-sm bg-light" v-model="trackingFilter">
								<option value="">{{ $t('coordinator.allStatusesOpt') }}</option>
								<option value="confirmed">{{ $t('coordinator.statusConfirmed') }}</option>
								<option value="pending">{{ $t('coordinator.statusPending') }}</option>
								<option value="declined">{{ $t('coordinator.statusDeclined') }}</option>
								<option value="attended">{{ $t('coordinator.statusAttended') }}</option>
								<option value="absent">{{ $t('coordinator.statusAbsent') }}</option>
							</select>
						</div>
						<div class="col-md-5 text-end">
							<button class="btn btn-sm btn-outline-success rounded-pill px-3" @click="sendBulkEmail" :disabled="!canManageReportMonitoring || selectedVolunteers.length === 0">
								<i class="fa-solid fa-envelope me-1"></i>{{ $t('coordinator.sendEmailBtn') }} <span v-if="selectedVolunteers.length > 0">({{ selectedVolunteers.length }})</span>
							</button>
						</div>
					</div>
				</div>
				<div class="card-body p-0">
					<div class="table-responsive">
						<table class="table table-hover align-middle mb-0">
							<thead>
								<tr class="bg-light">
									<th class="ps-3" style="width: 40px;">
										<input class="form-check-input mt-0" type="checkbox" :checked="isAllSelected && filteredTracking.length > 0" @change="toggleAllSelections">
									</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 ps-2 border-0">{{ $t('coordinator.volunteerCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-md-table-cell">{{ $t('coordinator.contactCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('coordinator.statusCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center d-none d-lg-table-cell">{{ $t('coordinator.confirmedDateCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center d-none d-lg-table-cell">{{ $t('coordinator.noteCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center" style="width:80px"></th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="v in filteredTracking" :key="v.id">
									<td class="ps-3">
										<input class="form-check-input" type="checkbox" :value="v.id" v-model="selectedVolunteers">
									</td>
									<td class="ps-2">
										<div class="d-flex align-items-center gap-2">
											<div class="user-avatar rounded-circle d-flex align-items-center justify-content-center text-white flex-shrink-0" :style="{ background: v.color }">{{ v.name.charAt(0) }}</div>
											<div class="min-w-0">
												<div class="fw-bold text-dark small text-truncate">{{ v.name }}</div>
												<div class="text-muted small d-block d-md-none">{{ v.phone }}</div>
											</div>
										</div>
									</td>
									<td class="d-none d-md-table-cell">
										<div class="small text-muted">
											<div><i class="fa-solid fa-envelope me-1 text-primary"></i>{{ v.email }}</div>
											<div><i class="fa-solid fa-phone me-1 text-success"></i>{{ v.phone }}</div>
										</div>
									</td>
									<td class="text-center">
										<select class="form-select form-select-sm d-inline-block" style="width: auto; font-size: 12px;"
											v-model="v.status" @change="updateParticipationStatus(v)">
											<option value="pending">{{ $t('coordinator.statusPending') }}</option>
											<option value="confirmed">{{ $t('coordinator.statusConfirmed') }}</option>
											<option value="declined">{{ $t('coordinator.statusDeclined') }}</option>
											<option value="attended">{{ $t('coordinator.statusAttended') }}</option>
											<option value="absent">{{ $t('coordinator.statusAbsent') }}</option>
										</select>
									</td>
									<td class="text-center d-none d-lg-table-cell">
										<span class="text-muted small">{{ v.confirmedDate || '—' }}</span>
									</td>
									<td class="text-center d-none d-lg-table-cell">
										<span class="text-muted small text-truncate d-inline-block" style="max-width:120px">{{ v.note || '—' }}</span>
									</td>
									<td class="text-center">
										<div class="dropdown">
											<button class="btn btn-sm btn-light border-0 rounded-circle" data-bs-toggle="dropdown" style="width:30px;height:30px">
												<i class="fa-solid fa-ellipsis-vertical small"></i>
											</button>
											<ul class="dropdown-menu dropdown-menu-end shadow border-0 py-2">
												<li v-if="canManageReportMonitoring"><a class="dropdown-item small py-2" href="#" @click.prevent="openEmailModal(v)"><i class="fa-solid fa-envelope me-2 text-primary"></i>{{ $t('coordinator.sendEmailBtn') }}</a></li>
												<li v-if="canManageReportMonitoring"><a class="dropdown-item small py-2" href="#" @click.prevent="openRatingModal(v)"><i class="fa-solid fa-star me-2 text-warning"></i>{{ $t('campaignDetail.ratingAction') }}</a></li>
											</ul>
										</div>
									</td>
								</tr>
								<tr v-if="filteredTracking.length === 0">
									<td colspan="6" class="text-center py-5 text-muted"><i class="fa-solid fa-inbox me-2 fs-4 d-block mb-2 opacity-25"></i>{{ $t('coordinator.noVolunteerFound') }}</td>
								</tr>
							</tbody>
						</table>
					</div>
				</div>
			</div>

			<!-- TAB: Rating -->
			<div class="card border-0 shadow-sm mb-4" v-if="activeTab === 'rating'">
				<div class="card-header bg-white py-3">
					<div class="d-flex align-items-center justify-content-between">
						<h6 class="fw-bold mb-0"><i class="fa-solid fa-star text-warning me-2"></i>{{ $t('campaignDetail.rateVolunteersTitle') }}</h6>
						<span class="badge bg-info rounded-pill"><i class="fa-solid fa-info-circle me-1"></i>{{ $t('coordinator.onlyCoordinatorCanRate') }}</span>
					</div>
				</div>
				<div class="card-body p-0">
					<div class="table-responsive">
						<table class="table table-hover align-middle mb-0">
							<thead>
								<tr class="bg-light">
									<th class="fw-semibold text-muted small text-uppercase py-3 ps-3 border-0">{{ $t('coordinator.volunteerCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('coordinator.starRatingCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-md-table-cell">{{ $t('coordinator.commentCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('coordinator.statusCol') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center" style="width:120px">{{ $t('coordinator.actionCol') }}</th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="v in attendedVolunteers" :key="v.id">
									<td class="ps-3">
										<div class="d-flex align-items-center gap-2">
											<div class="user-avatar rounded-circle d-flex align-items-center justify-content-center text-white flex-shrink-0" :style="{ background: v.color }">{{ v.name.charAt(0) }}</div>
											<div>
												<div class="fw-bold small">{{ v.name }}</div>
												<div class="text-muted small">{{ v.email }}</div>
											</div>
										</div>
									</td>
									<td class="text-center">
										<div class="star-rating">
											<i v-for="i in 5" :key="i" class="star-icon"
												:class="i <= (v.rating || 0) ? 'fa-solid fa-star text-warning' : 'fa-regular fa-star text-muted'"
												@click="setRating(v, i)"></i>
										</div>
									</td>
									<td class="d-none d-md-table-cell">
										<input type="text" class="form-control form-control-sm bg-light border-0" :placeholder="$t('campaignDetail.commentPlaceholder')"
											v-model="v.comment" style="font-size:12px;">
									</td>
									<td class="text-center">
										<span class="badge rounded-pill" :class="v.rated ? 'bg-success-subtle text-success' : 'bg-warning-subtle text-warning'">
											{{ v.rated ? $t('coordinator.ratedStatus') : $t('coordinator.notRatedStatus') }}
										</span>
									</td>
									<td class="text-center">
										<button class="btn btn-sm btn-primary rounded-pill px-3" @click="saveRating(v)" :disabled="!canManageReportMonitoring || !v.rating">
											<i class="fa-solid fa-save me-1"></i>{{ $t('coordinator.saveBtn') }}
										</button>
									</td>
								</tr>
								<tr v-if="attendedVolunteers.length === 0">
									<td colspan="5" class="text-center py-5 text-muted">
										<i class="fa-solid fa-user-slash d-block mb-2 fs-4 opacity-25"></i>
										{{ $t('coordinator.noVolunteerAttended') }}
									</td>
								</tr>
							</tbody>
						</table>
					</div>
				</div>
				<div class="card-footer bg-white border-top py-3 d-flex flex-wrap gap-2 justify-content-between align-items-center" v-if="attendedVolunteers.length > 0">
					<span class="text-muted small">{{ $t('coordinator.ratedCountLabel') }} <strong>{{ attendedVolunteers.filter(v => v.rated).length }}</strong> / {{ attendedVolunteers.length }} {{ $t('campaignDetail.volunteerCol') }}</span>
					<div class="d-flex gap-2">
						<button class="btn btn-sm btn-outline-warning rounded-pill px-3" @click="sendRatingEmails" :disabled="!canManageReportMonitoring">
							<i class="fa-solid fa-envelope me-1"></i>{{ $t('coordinator.sendResultEmailBtn') }}
						</button>
					</div>
				</div>
			</div>

			<!-- TAB: Report -->
			<div v-if="activeTab === 'report'">
				<!-- Report Summary Cards -->
				<div class="row g-3 mb-4">
					<div class="col-lg-4">
						<div class="card border-0 shadow-sm h-100">
							<div class="card-body">
								<h6 class="fw-bold small mb-3"><i class="fa-solid fa-users text-primary me-2"></i>{{ $t('coordinator.participationStatsTitle') }}</h6>
								<div class="d-flex flex-column gap-3">
									<div class="report-stat-row" v-for="item in participationStats" :key="item.label">
										<div class="d-flex align-items-center justify-content-between mb-1">
											<span class="small">{{ item.label }}</span>
											<span class="small fw-bold">{{ item.count }}</span>
										</div>
										<div class="progress" style="height:5px">
											<div class="progress-bar" :class="item.barClass" :style="{ width: item.percent + '%' }"></div>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-lg-4">
						<div class="card border-0 shadow-sm h-100">
							<div class="card-body">
								<h6 class="fw-bold small mb-3"><i class="fa-solid fa-star text-warning me-2"></i>{{ $t('coordinator.ratingStatsTitle') }}</h6>
								<div class="text-center mb-3">
									<div class="rating-big-number">{{ avgRating }}</div>
									<div class="d-flex align-items-center justify-content-center gap-1 mb-1">
										<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= Math.round(avgRating) ? 'text-warning' : 'text-muted'" style="font-size:14px"></i>
									</div>
									<span class="text-muted small">{{ ratedCount }} {{ $t('campaignDetail.ratingAction') }}</span>
								</div>
								<div class="d-flex flex-column gap-2">
									<div class="d-flex align-items-center gap-2" v-for="i in [5,4,3,2,1]" :key="i">
										<span class="small text-muted" style="width:20px">{{ i }}★</span>
										<div class="progress flex-grow-1" style="height:5px">
											<div class="progress-bar bg-warning" :style="{ width: getRatingPercent(i) + '%' }"></div>
										</div>
										<span class="small text-muted" style="width:15px">{{ getRatingCount(i) }}</span>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-lg-4">
						<div class="card border-0 shadow-sm h-100">
							<div class="card-body">
								<h6 class="fw-bold small mb-3"><i class="fa-solid fa-chart-pie text-success me-2"></i>{{ $t('coordinator.campaignInfoTitle') }}</h6>
								<div class="d-flex flex-column gap-3">
									<div class="d-flex align-items-center justify-content-between">
										<span class="text-muted small">{{ $t('coordinator.campaignLabel') }}</span>
										<span class="fw-bold small">{{ activeCampaign.name }}</span>
									</div>
									<div class="d-flex align-items-center justify-content-between">
										<span class="text-muted small">{{ $t('coordinator.locationLabel') }}</span>
										<span class="fw-bold small"><i class="fa-solid fa-location-dot text-danger me-1"></i>{{ activeCampaign.location }}</span>
									</div>
									<div class="d-flex align-items-center justify-content-between">
										<span class="text-muted small">{{ $t('coordinator.timeLabel') }}</span>
										<span class="fw-bold small">{{ activeCampaign.startDate }} — {{ activeCampaign.endDate }}</span>
									</div>
									<div class="d-flex align-items-center justify-content-between">
										<span class="text-muted small">{{ $t('coordinator.completionRateLabel') }}</span>
										<span class="fw-bold small text-success">{{ Math.round(activeCampaign.confirmed / activeCampaign.totalVolunteers * 100) }}%</span>
									</div>
									<hr class="my-1">
									<button class="btn btn-success btn-sm w-100 rounded-pill" @click="exportReport" :disabled="!canManageReportMonitoring">
										<i class="fa-solid fa-download me-1"></i>{{ $t('coordinator.downloadPdfBtn') }}
									</button>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Placeholder -->
		<div class="card border-0 shadow-sm" v-if="!activeCampaign">
			<div class="card-body text-center py-5">
				<div class="placeholder-icon mx-auto mb-3">
					<i class="fa-solid fa-chart-line"></i>
				</div>
				<h5 class="fw-bold text-muted">{{ $t('coordinator.selectCampaignToStart') }}</h5>
				<p class="text-muted small mb-0" v-html="$t('coordinator.selectCampaignDesc')"></p>
			</div>
		</div>

		<!-- Rating Modal -->
		<div class="modal fade" :class="{ show: showRatingModal }" :style="showRatingModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-star text-warning me-2"></i>{{ $t('coordinator.rateModalTitle') }}</h5>
						<button type="button" class="btn-close" @click="showRatingModal = false"></button>
					</div>
					<div class="modal-body" v-if="ratingTarget">
						<div class="text-center mb-4">
							<div class="user-avatar-lg mx-auto mb-2" :style="{ background: ratingTarget.color }">{{ ratingTarget.name.charAt(0) }}</div>
							<h6 class="fw-bold">{{ ratingTarget.name }}</h6>
							<span class="text-muted small">{{ ratingTarget.email }}</span>
						</div>
						<div class="text-center mb-3">
							<div class="star-rating-lg">
								<i v-for="i in 5" :key="i" class="star-icon-lg"
									:class="i <= modalRating ? 'fa-solid fa-star text-warning' : 'fa-regular fa-star text-muted'"
									@click="modalRating = i"></i>
							</div>
							<span class="text-muted small mt-1 d-block">{{ getRatingText(modalRating) }}</span>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('coordinator.commentLabel') }}</label>
							<textarea class="form-control" rows="3" :placeholder="$t('campaignDetail.commentPlaceholder')" v-model="modalComment"></textarea>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showRatingModal = false">{{ $t('common.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="confirmModalRating" :disabled="!canManageReportMonitoring || !modalRating">
							<i class="fa-solid fa-save me-1"></i>{{ $t('coordinator.saveRatingBtn') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showRatingModal" @click="showRatingModal = false"></div>

		<!-- Email Modal -->
		<div class="modal fade" :class="{ show: showEmailModal }" :style="showEmailModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-envelope text-primary me-2"></i>{{ $t('coordinator.emailModalTitle') }}</h5>
						<button type="button" class="btn-close" @click="showEmailModal = false"></button>
					</div>
					<div class="modal-body">
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('coordinator.sendToLabel') }}</label>
							<input type="text" class="form-control bg-light" :value="emailTargetText" disabled>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('coordinator.subjectLabel') }}</label>
							<input type="text" class="form-control" v-model="emailSubject">
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('coordinator.contentLabel') }}</label>
							<textarea class="form-control" rows="5" v-model="emailBody"></textarea>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showEmailModal = false">{{ $t('common.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="confirmSendEmail" :disabled="!canManageReportMonitoring">
							<i class="fa-solid fa-paper-plane me-1"></i>{{ $t('coordinator.sendEmailBtn') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showEmailModal" @click="showEmailModal = false"></div>
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue'
import StatCards from '../../components/StatCards.vue'
import { hasPermission } from '../../utils/permissions'

export default {
	name: 'GiamSatBaoCao',
	components: { PageHeader, StatCards },
	data() {
		return {
			selectedCampaignId: '',
			activeTab: 'tracking',
			trackingSearch: '',
			trackingFilter: '',
			showRatingModal: false,
			showEmailModal: false,
			ratingTarget: null,
			emailTarget: null,
			selectedVolunteers: [],
			modalRating: 0,
			modalComment: '',
			modalComment: '',
			emailSubject: '',
			emailBody: '',
			campaigns: [
				{ id: 1, name: 'Trồng cây xanh Tây Nguyên', location: 'Đắk Lắk', startDate: '15/03/2026', endDate: '20/03/2026', totalVolunteers: 45, confirmed: 38, status: 'active' },
				{ id: 2, name: 'Dạy học miễn phí Sa Pa', location: 'Lào Cai', startDate: '20/03/2026', endDate: '03/04/2026', totalVolunteers: 20, confirmed: 20, status: 'completed' },
				{ id: 3, name: 'Khám bệnh cộng đồng Quảng Nam', location: 'Quảng Nam', startDate: '25/03/2026', endDate: '27/03/2026', totalVolunteers: 15, confirmed: 8, status: 'active' }
			],
			volunteers: []
		}
	},
	computed: {
		canManageReportMonitoring() {
			try {
				const user = JSON.parse(localStorage.getItem('user') || 'null');
				return hasPermission(user, 'campaign_report_monitoring.manage');
			} catch (_error) {
				return false;
			}
		},
		isAllSelected() {
			if (this.filteredTracking.length === 0) return false;
			return this.filteredTracking.every(v => this.selectedVolunteers.includes(v.id));
		},
		tabs() {
			return [
				{ label: this.$t('coordinator.trackingTab'), value: 'tracking', icon: 'fa-solid fa-clipboard-list' },
				{ label: this.$t('coordinator.ratingTab'), value: 'rating', icon: 'fa-solid fa-star' },
				{ label: this.$t('coordinator.reportTab'), value: 'report', icon: 'fa-solid fa-chart-bar' }
			];
		},
		emailTargetText() {
			if (this.emailTarget) return this.emailTarget.email;
			if (this.selectedVolunteers.length > 0) return `${this.selectedVolunteers.length} ${this.$t('coordinator.selectedVolunteersLabel')}`;
			return this.$t('coordinator.allVolunteersLabel');
		},
		activeCampaign() {
			return this.campaigns.find(c => c.id === Number(this.selectedCampaignId));
		},
		filteredTracking() {
			let list = this.volunteers;
			if (this.trackingSearch) {
				const q = this.trackingSearch.toLowerCase();
				list = list.filter(v => v.name.toLowerCase().includes(q) || v.email.toLowerCase().includes(q));
			}
			if (this.trackingFilter) list = list.filter(v => v.status === this.trackingFilter);
			return list;
		},
		attendedVolunteers() {
			return this.volunteers.filter(v => v.status === 'attended' || v.status === 'confirmed');
		},
		statsCards() {
			if (!this.activeCampaign) return [];
			const total = this.volunteers.length;
			return [
				{ label: this.$t('coordinator.totalAssignedVolsLabel'), value: total, icon: 'fa-solid fa-users', color: 'primary' },
				{ label: this.$t('coordinator.confirmedLabel'), value: this.volunteers.filter(v => v.status === 'confirmed').length, icon: 'fa-solid fa-circle-check', color: 'success' },
				{ label: this.$t('coordinator.attendedLabel'), value: this.volunteers.filter(v => v.status === 'attended').length, icon: 'fa-solid fa-user-check', color: 'info' },
				{ label: this.$t('coordinator.ratedLabel'), value: this.volunteers.filter(v => v.rated).length, icon: 'fa-solid fa-star', color: 'warning' }
			];
		},
		participationStats() {
			const total = this.volunteers.length || 1;
			return [
				{ label: this.$t('coordinator.confirmedLabel'), count: this.volunteers.filter(v => v.status === 'confirmed').length, percent: this.volunteers.filter(v => v.status === 'confirmed').length / total * 100, barClass: 'bg-success' },
				{ label: this.$t('coordinator.attendedLabel'), count: this.volunteers.filter(v => v.status === 'attended').length, percent: this.volunteers.filter(v => v.status === 'attended').length / total * 100, barClass: 'bg-info' },
				{ label: this.$t('coordinator.pendingLabel'), count: this.volunteers.filter(v => v.status === 'pending').length, percent: this.volunteers.filter(v => v.status === 'pending').length / total * 100, barClass: 'bg-warning' },
				{ label: this.$t('coordinator.declinedLabel'), count: this.volunteers.filter(v => v.status === 'declined').length, percent: this.volunteers.filter(v => v.status === 'declined').length / total * 100, barClass: 'bg-danger' },
				{ label: this.$t('coordinator.absentLabel'), count: this.volunteers.filter(v => v.status === 'absent').length, percent: this.volunteers.filter(v => v.status === 'absent').length / total * 100, barClass: 'bg-secondary' }
			];
		},
		avgRating() {
			const rated = this.volunteers.filter(v => v.rating);
			if (rated.length === 0) return '0.0';
			return (rated.reduce((s, v) => s + v.rating, 0) / rated.length).toFixed(1);
		},
		ratedCount() {
			return this.volunteers.filter(v => v.rated).length;
		}
	},
	methods: {
		getStatusLabel(s) {
			return this.$t(`statuses.${s}`);
		},
		getStatusClass(s) {
			return { active: 'bg-success text-white', completed: 'bg-secondary text-white', pending: 'bg-warning text-dark' }[s] || 'bg-secondary';
		},
		getRatingText(r) {
			return { 1: this.$t('ratings.1'), 2: this.$t('ratings.2'), 3: this.$t('ratings.3'), 4: this.$t('ratings.4'), 5: this.$t('ratings.5') }[r] || this.$t('coordinator.notRatedStatus');
		},
		getRatingCount(stars) {
			return this.volunteers.filter(v => v.rating === stars).length;
		},
		getRatingPercent(stars) {
			const total = this.volunteers.filter(v => v.rated).length || 1;
			return (this.getRatingCount(stars) / total) * 100;
		},
		loadCampaignData() {
			this.selectedVolunteers = [];
			if (!this.activeCampaign) { this.volunteers = []; return; }
			this.volunteers = [
				{ id: 1, name: 'Nguyễn Minh Tuấn', email: 'tuan.nm@gmail.com', phone: '0901234567', status: 'attended', confirmedDate: '16/03/2026', note: '', color: '#0d6efd', rating: 5, comment: 'Xuất sắc, nhiệt tình', rated: true },
				{ id: 2, name: 'Trần Văn Sơn', email: 'son.tv@gmail.com', phone: '0912345678', status: 'attended', confirmedDate: '16/03/2026', note: '', color: '#198754', rating: 4, comment: 'Tích cực tham gia', rated: true },
				{ id: 3, name: 'Lê Hải Yến', email: 'yen.lh@gmail.com', phone: '0923456789', status: 'confirmed', confirmedDate: '17/03/2026', note: 'Sẽ đến trễ', color: '#dc3545', rating: 0, comment: '', rated: false },
				{ id: 4, name: 'Phạm Thị Lan', email: 'lan.pt@gmail.com', phone: '0934567890', status: 'confirmed', confirmedDate: '16/03/2026', note: '', color: '#6f42c1', rating: 0, comment: '', rated: false },
				{ id: 5, name: 'Hoàng Đức Minh', email: 'minh.hd@gmail.com', phone: '0945678901', status: 'pending', confirmedDate: '', note: '', color: '#fd7e14', rating: 0, comment: '', rated: false },
				{ id: 6, name: 'Vũ Quốc Bảo', email: 'bao.vq@gmail.com', phone: '0956789012', status: 'declined', confirmedDate: '', note: 'Bận lịch cá nhân', color: '#20c997', rating: 0, comment: '', rated: false },
				{ id: 7, name: 'Đặng Thị Hoa', email: 'hoa.dt@gmail.com', phone: '0967890123', status: 'attended', confirmedDate: '16/03/2026', note: '', color: '#e83e8c', rating: 4, comment: 'Chăm chỉ', rated: true },
				{ id: 8, name: 'Ngô Thanh Tùng', email: 'tung.nt@gmail.com', phone: '0978901234', status: 'absent', confirmedDate: '17/03/2026', note: 'Không liên lạc được', color: '#17a2b8', rating: 0, comment: '', rated: false }
			];
		},
		updateParticipationStatus(v) {
			// will call API later
		},
		setRating(v, rating) {
			v.rating = rating;
		},
		saveRating(v) {
			v.rated = true;
		},
		openRatingModal(v) {
			this.ratingTarget = v;
			this.modalRating = v.rating || 0;
			this.modalComment = v.comment || '';
			this.showRatingModal = true;
		},
		confirmModalRating() {
			if (this.ratingTarget) {
				this.ratingTarget.rating = this.modalRating;
				this.ratingTarget.comment = this.modalComment;
				this.ratingTarget.rated = true;
			}
			this.showRatingModal = false;
		},
		openEmailModal(v) {
			this.emailTarget = v || null;
			this.emailSubject = `[VMS-AI] ${this.activeCampaign?.name || ''}`;
			const nameOrFriend = v ? v.name : this.$t('coordinator.friendText');
			this.emailBody = this.$t('coordinator.personalEmailBody', { name: nameOrFriend, campaign: this.activeCampaign?.name || '' });
			this.showEmailModal = true;
		},
		sendBulkEmail() {
			this.emailTarget = null;
			this.emailSubject = `[VMS-AI] ${this.$t('coordinator.notificationLabel')}: ${this.activeCampaign?.name || ''}`;
			this.emailBody = this.$t('coordinator.bulkEmailBody', { campaign: this.activeCampaign?.name || '' });
			this.showEmailModal = true;
		},
		confirmSendEmail() {
			this.showEmailModal = false;
			this.selectedVolunteers = [];
		},
		toggleAllSelections(e) {
			if (e.target.checked) {
				this.selectedVolunteers = this.filteredTracking.map(v => v.id);
			} else {
				this.selectedVolunteers = [];
			}
		},
		sendRatingEmails() {
			// will call API later
		},
		exportReport() {
			// will call API later
		}
	}
}
</script>

<style scoped>
.user-avatar { width: 36px; height: 36px; min-width: 36px; font-weight: 700; font-size: 14px; }
.user-avatar-lg { width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 24px; }
.min-w-0 { min-width: 0; }

.camp-mini-stat {
	display: flex;
	flex-direction: column;
	align-items: flex-start;
}

.placeholder-icon {
	width: 80px;
	height: 80px;
	border-radius: 50%;
	background: #f0f2f5;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 32px;
	color: #adb5bd;
}

/* Star Rating */
.star-rating { display: flex; gap: 4px; justify-content: center; }
.star-rating .star-icon { font-size: 18px; cursor: pointer; transition: transform 0.15s; }
.star-rating .star-icon:hover { transform: scale(1.2); }

.star-rating-lg { display: flex; gap: 8px; justify-content: center; }
.star-rating-lg .star-icon-lg { font-size: 32px; cursor: pointer; transition: all 0.2s; }
.star-rating-lg .star-icon-lg:hover { transform: scale(1.15); }

.rating-big-number {
	font-size: 42px;
	font-weight: 800;
	color: #fd7e14;
	line-height: 1;
}

/* Tabs */
.nav-tabs-custom .nav-link { border: none; border-bottom: 3px solid transparent; border-radius: 0; font-size: 13px; }
.nav-tabs-custom .nav-link.active { border-bottom-color: #0d6efd; background: transparent; }
.nav-tabs-custom .nav-link:hover:not(.active) { border-bottom-color: #dee2e6; }

.report-stat-row + .report-stat-row { margin-top: 8px; }

@media (max-width: 575.98px) {
	.user-avatar { width: 32px; height: 32px; font-size: 12px; }
	.star-rating .star-icon { font-size: 16px; }
	.camp-mini-stat { font-size: 12px; }
}
</style>
