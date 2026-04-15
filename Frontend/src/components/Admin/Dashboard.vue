<template>
	<div class="admin-dashboard">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-gauge-high text-primary me-2"></i>{{ $t('admin.dashboard.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.dashboard.subtitle') }}</p>
			</div>
			<div class="d-flex gap-2">
				<select class="form-select form-select-sm" style="width: auto;" v-model="period" @change="fetchDashboard">
					<option value="week">{{ $t('admin.dashboard.period.week') }}</option>
					<option value="month">{{ $t('admin.dashboard.period.month') }}</option>
					<option value="quarter">{{ $t('admin.dashboard.period.quarter') }}</option>
					<option value="year">{{ $t('admin.dashboard.period.year') }}</option>
				</select>
			</div>
		</div>

		<!-- Stats Cards Row -->
		<div class="row g-3 mb-4">
			<div class="col-xl-3 col-sm-6" v-for="stat in stats" :key="stat.label">
				<div class="card stat-card border-0 shadow-sm h-100">
					<div class="card-body p-3">
						<div class="d-flex align-items-start justify-content-between">
							<div>
								<p class="text-muted small mb-1">{{ stat.label }}</p>
								<h3 class="fw-bold mb-0">{{ formatNumber(stat.value) }}</h3>
								<div class="mt-2">
									<span class="badge rounded-pill" :class="trendBadgeClass(stat)">
										<i class="fa-solid" :class="trendIcon(stat)"></i> {{ getTrendText(stat) }}
									</span>
								</div>
							</div>
							<div class="stat-icon" :class="stat.bg_class">
								<i :class="stat.icon"></i>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Charts Row -->
		<div class="row g-3 mb-4">
			<div class="col-lg-8">
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
						<h6 class="fw-bold mb-0"><i class="fa-solid fa-chart-area text-primary me-2"></i>{{ $t('admin.dashboard.charts.systemActivity') }}</h6>
						<div class="d-flex gap-2">
							<span class="chart-legend"><span class="legend-dot bg-primary"></span> {{ $t('admin.dashboard.charts.newRegistrations') }}</span>
								<span class="chart-legend"><span class="legend-dot bg-success"></span> {{ $t('admin.dashboard.charts.campaigns') }}</span>
							</div>
						</div>
					<div class="card-body">
						<div class="chart-placeholder d-flex align-items-end gap-2 justify-content-around" style="height: 250px;">
							<div class="chart-bar-pair" v-for="(item, idx) in chartData" :key="idx">
								<div class="d-flex align-items-end gap-1" style="height: 200px;">
									<div class="chart-bar bg-primary bg-opacity-75 clickable-bar" :style="{ height: item.regHeight + '%' }"
										@click="selectActivityBucket(item, 'registrations')"
										v-bs-tooltip :title="item.reg + ' ' + $t('admin.dashboard.charts.newRegistrations').toLowerCase()"></div>
									<div class="chart-bar bg-success bg-opacity-75 clickable-bar" :style="{ height: item.campHeight + '%' }"
										@click="selectActivityBucket(item, 'campaigns')"
										v-bs-tooltip :title="item.camp + ' ' + $t('admin.dashboard.charts.campaigns').toLowerCase()"></div>
								</div>
								<div class="text-center text-muted small mt-2">{{ item.label }}</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<div class="col-lg-4">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3">
						<h6 class="fw-bold mb-0"><i class="fa-solid fa-pie-chart text-primary me-2"></i>{{ $t('admin.dashboard.charts.usersDistribution') }}</h6>
					</div>
					<div class="card-body d-flex flex-column justify-content-center">
						<!-- Donut chart visual -->
						<div class="donut-chart mx-auto mb-4">
							<div class="donut-hole">
								<h4 class="fw-bold mb-0">{{ formatNumber(totalUsers) }}</h4>
								<span class="small text-muted">{{ $t('admin.dashboard.charts.total') }}</span>
							</div>
						</div>
						<div class="d-flex flex-column gap-3">
							<div class="d-flex align-items-center justify-content-between" v-for="role in roleDistribution" :key="role.label">
								<div class="d-flex align-items-center gap-2">
									<span class="role-dot" :style="{ background: role.color }"></span>
									<span class="small">{{ role.label }}</span>
								</div>
								<div class="d-flex align-items-center gap-2">
									<span class="fw-bold small">{{ role.count }}</span>
									<div class="progress" style="width: 60px; height: 4px;">
										<div class="progress-bar" :style="{ width: role.percent + '%', background: role.color }"></div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<div class="row g-3 mb-4" v-if="selectedActivity">
			<div class="col-12">
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
						<h6 class="fw-bold mb-0">
							<i class="fa-solid fa-table-list text-primary me-2"></i>{{ selectedActivityTitle }}
							<span class="badge bg-primary-subtle text-primary ms-2">{{ selectedActivityItems.length }}</span>
						</h6>
						<button type="button" class="btn btn-sm btn-light rounded-pill" @click="selectedActivity = null">
							<i class="fa-solid fa-xmark me-1"></i>{{ $t('admin.dashboard.activity.close') }}
						</button>
					</div>
					<div class="card-body p-0">
						<div v-if="selectedActivityItems.length === 0" class="p-4 text-muted small">
							{{ $t('admin.dashboard.activity.empty') }}
						</div>
						<div v-else class="table-responsive">
							<table class="table table-hover align-middle mb-0">
								<thead class="table-light">
									<tr v-if="selectedActivity.type === 'registrations'">
										<th>{{ $t('admin.dashboard.activity.table.user') }}</th>
										<th>{{ $t('admin.dashboard.activity.table.role') }}</th>
										<th>{{ $t('admin.dashboard.activity.table.status') }}</th>
										<th>{{ $t('admin.dashboard.activity.table.time') }}</th>
										<th class="text-center">{{ $t('admin.dashboard.activity.table.detail') }}</th>
									</tr>
									<tr v-else>
										<th>{{ $t('admin.dashboard.activity.table.campaign') }}</th>
										<th>{{ $t('admin.dashboard.activity.table.creator') }}</th>
										<th>{{ $t('admin.dashboard.activity.table.status') }}</th>
										<th>{{ $t('admin.dashboard.activity.table.time') }}</th>
										<th class="text-center">{{ $t('admin.dashboard.activity.table.detail') }}</th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="item in paginatedSelectedActivityItems" :key="`${selectedActivity.type}-${item.id}`">
										<template v-if="selectedActivity.type === 'registrations'">
											<td>
												<div class="d-flex align-items-center gap-2">
													<div class="user-avatar-sm overflow-hidden bg-primary-subtle text-primary">
														<img v-if="item.avatar" :src="item.avatar" alt="" class="w-100 h-100 object-fit-cover" />
														<span v-else>{{ (item.name || '?').charAt(0) }}</span>
													</div>
													<div>
														<div class="fw-semibold small">{{ item.name }}</div>
														<div class="text-muted" style="font-size: 12px;">{{ item.email }}</div>
													</div>
												</div>
											</td>
											<td><span class="badge rounded-pill text-bg-light">{{ item.role_label }}</span></td>
											<td><span class="badge rounded-pill" :class="item.status_badge_class">{{ item.status_label }}</span></td>
											<td><span class="text-muted small">{{ formatDateTime(item.created_at) }}</span></td>
											<td class="text-center">
												<button type="button" class="btn btn-sm btn-outline-primary" @click="openUserDetail(item)">
													<i class="fa-solid fa-eye"></i>
												</button>
											</td>
										</template>
										<template v-else>
											<td>
												<div class="fw-semibold small">{{ item.title }}</div>
												<div class="text-muted" style="font-size: 12px;">{{ item.location }}</div>
											</td>
											<td>
												<div class="small fw-semibold">{{ item.creator_name || '—' }}</div>
												<div class="text-muted" style="font-size: 12px;">{{ item.creator_email || '—' }}</div>
											</td>
											<td><span class="badge rounded-pill" :class="item.status_badge_class">{{ item.status_label }}</span></td>
											<td><span class="text-muted small">{{ formatDateTime(item.created_at) }}</span></td>
											<td class="text-center">
												<button type="button" class="btn btn-sm btn-outline-primary" @click="openCampaignDetail(item)">
													<i class="fa-solid fa-eye"></i>
												</button>
											</td>
										</template>
									</tr>
								</tbody>
							</table>
						</div>
						<div v-if="selectedActivityTotalPages > 1" class="d-flex align-items-center justify-content-between flex-wrap gap-2 px-3 py-3 border-top bg-light-subtle">
							<div class="text-muted small">
								{{ $t('admin.dashboard.activity.pagination', {
									page: selectedActivityPage,
									totalPages: selectedActivityTotalPages,
									from: selectedActivityRange.from,
									to: selectedActivityRange.to,
									total: selectedActivityItems.length
								}) }}
							</div>
							<div class="d-flex align-items-center gap-2">
								<button type="button" class="btn btn-sm btn-outline-secondary" :disabled="selectedActivityPage === 1" @click="changeSelectedActivityPage(selectedActivityPage - 1)">
									{{ $t('pagination.prev') }}
								</button>
								<button
									v-for="page in visibleSelectedActivityPages"
									:key="`activity-page-${page}`"
									type="button"
									class="btn btn-sm"
									:class="page === selectedActivityPage ? 'btn-primary' : 'btn-outline-secondary'"
									@click="changeSelectedActivityPage(page)"
								>
									{{ page }}
								</button>
								<button type="button" class="btn btn-sm btn-outline-secondary" :disabled="selectedActivityPage === selectedActivityTotalPages" @click="changeSelectedActivityPage(selectedActivityPage + 1)">
									{{ $t('pagination.next') }}
								</button>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Lower Section -->
		<div class="row g-3">
			<!-- Recent Users -->
			<div class="col-lg-6">
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
						<h6 class="fw-bold mb-0">
							<i class="fa-solid fa-user-plus text-primary me-2"></i>{{ $t('admin.dashboard.recentUsers.title') }}
							<span class="badge bg-primary-subtle text-primary ms-2">{{ recentUsers.length }}</span>
						</h6>
						<router-link v-if="canViewUsers" to="/admin/nguoi-dung" class="btn btn-sm btn-outline-primary rounded-pill">{{ $t('common.viewAll') }}</router-link>
					</div>
					<div class="card-body p-0">
						<div v-if="!recentUsers.length" class="text-muted small p-3">{{ $t('admin.dashboard.recentUsers.empty') }}</div>
						<div class="approval-item d-flex align-items-center gap-3 p-3 border-bottom" v-for="user in recentUsers" :key="user.id">
							<div class="user-avatar-sm overflow-hidden bg-primary-subtle text-primary">
								<img v-if="user.avatar" :src="user.avatar" alt="" class="w-100 h-100 object-fit-cover" />
								<span v-else>{{ user.name.charAt(0) }}</span>
							</div>
							<div class="flex-grow-1">
								<h6 class="mb-0 small fw-bold">{{ user.name }}</h6>
								<span class="text-muted d-block" style="font-size: 12px;">{{ user.email }} · {{ user.time }}</span>
								<div class="d-flex align-items-center gap-2 mt-1">
									<span class="badge rounded-pill text-bg-light">{{ user.role_label }}</span>
									<span class="badge rounded-pill" :class="user.status_badge_class">{{ user.status_label }}</span>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Recent Campaigns -->
			<div class="col-lg-6">
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
						<h6 class="fw-bold mb-0"><i class="fa-solid fa-flag text-primary me-2"></i>{{ $t('admin.dashboard.campaigns.title') }}</h6>
						<span class="badge bg-success rounded-pill">{{ activeCampaignsLabel }}</span>
					</div>
					<div class="card-body p-0">
						<div v-if="!recentCampaigns.length" class="text-muted small p-3">{{ $t('admin.dashboard.campaigns.empty') }}</div>
						<div class="campaign-item d-flex align-items-center gap-3 p-3 border-bottom" v-for="campaign in recentCampaigns" :key="campaign.id">
							<div class="campaign-thumb" :style="campaignThumbStyle(campaign)"></div>
							<div class="flex-grow-1">
								<h6 class="mb-1 small fw-bold campaign-title-text">{{ campaign.title }}</h6>
								<div class="d-flex align-items-center gap-3 text-muted" style="font-size: 12px;">
									<span><i class="fa-solid fa-users me-1"></i>{{ campaign.volunteers }}/{{ campaign.target }}</span>
									<span><i class="fa-solid fa-location-dot me-1"></i>{{ campaign.location }}</span>
								</div>
							</div>
							<span class="badge rounded-pill" :class="campaign.status_badge_class">{{ campaign.status_label }}</span>
						</div>
					</div>
				</div>
			</div>
		</div>

		<div class="modal fade" :class="{ show: showUserDetailModal }" :style="showUserDetailModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow" v-if="detailUser">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-user text-primary me-2"></i>{{ $t('admin.dashboard.modals.userTitle') }}</h5>
						<button type="button" class="btn-close" @click="showUserDetailModal = false"></button>
					</div>
					<div class="modal-body">
						<div class="text-center mb-4">
							<div class="user-view-avatar mx-auto mb-3 overflow-hidden bg-primary-subtle text-primary">
								<img v-if="detailUser.avatar" :src="detailUser.avatar" alt="" class="w-100 h-100 object-fit-cover" />
								<span v-else>{{ (detailUser.name || '?').charAt(0) }}</span>
							</div>
							<h5 class="fw-bold mb-1">{{ detailUser.name }}</h5>
							<div class="text-muted small">{{ detailUser.email }}</div>
						</div>
						<div class="row g-3">
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center h-100">
									<span class="text-muted small d-block">{{ $t('admin.dashboard.modals.role') }}</span>
									<span class="fw-semibold small">{{ detailUser.role_label }}</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center h-100">
									<span class="text-muted small d-block">{{ $t('admin.dashboard.modals.status') }}</span>
									<span class="badge rounded-pill mt-1" :class="detailUser.status_badge_class">{{ detailUser.status_label }}</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center h-100">
									<span class="text-muted small d-block">{{ $t('admin.dashboard.modals.phone') }}</span>
									<span class="fw-semibold small">{{ detailUser.phone || $t('admin.dashboard.modals.notUpdated') }}</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center h-100">
									<span class="text-muted small d-block">{{ $t('admin.dashboard.modals.registeredAt') }}</span>
									<span class="fw-semibold small">{{ formatDateTime(detailUser.created_at) }}</span>
								</div>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showUserDetailModal = false">{{ $t('common.close') }}</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showUserDetailModal" @click="showUserDetailModal = false"></div>

		<div class="modal fade" :class="{ show: showCampaignDetailModal }" :style="showCampaignDetailModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
				<div class="modal-content border-0 shadow">
					<div v-if="showCampaignDetailLoading" class="p-5 text-center text-muted">
						<div class="spinner-border text-primary mb-3"></div>
						<div>{{ $t('common.loading') }}</div>
					</div>
					<template v-else-if="detailCampaign">
						<div class="modal-header border-0" :style="{ background: detailCampaign.color }">
							<div class="d-flex align-items-center gap-3">
								<div class="rounded-3 d-flex align-items-center justify-content-center" style="width:48px;height:48px; background-color: rgba(255,255,255,0.2);">
									<i :class="detailCampaign.icon" class="text-white fs-5"></i>
								</div>
								<div class="text-white">
									<h5 class="fw-bold mb-0">{{ detailCampaign.title }}</h5>
									<span class="small opacity-75">{{ detailCampaign.categoryName }}</span>
								</div>
							</div>
							<button type="button" class="btn-close btn-close-white" @click="closeCampaignDetailModal"></button>
						</div>
						<div class="modal-body p-4">
							<div class="row g-3 mb-4">
								<div class="col-sm-6 col-xl-3">
									<div class="detail-info-card">
										<div class="detail-icon bg-danger text-white"><i class="fa-solid fa-location-dot"></i></div>
										<div>
											<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.location') }}</div>
											<div class="fw-semibold small">{{ detailCampaign.location }}</div>
										</div>
									</div>
								</div>
								<div class="col-sm-6 col-xl-3">
									<div class="detail-info-card">
										<div class="detail-icon bg-primary text-white"><i class="fa-solid fa-calendar-days"></i></div>
										<div>
											<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.time') }}</div>
											<div class="fw-semibold small">{{ formatDate(detailCampaign.startDate) }} — {{ formatDate(detailCampaign.endDate) }}</div>
										</div>
									</div>
								</div>
								<div class="col-sm-6 col-xl-3">
									<div class="detail-info-card">
										<div class="detail-icon bg-success text-white"><i class="fa-solid fa-users"></i></div>
										<div>
											<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.requiredVolunteers') }}</div>
											<div class="fw-semibold small">{{ detailCampaign.maxVolunteers }} {{ $t('admin.campaignManagement.detailModal.people') }} ({{ detailCampaign.registered }} {{ $t('admin.campaignManagement.detailModal.registered') }})</div>
										</div>
									</div>
								</div>
								<div class="col-sm-6 col-xl-3">
									<div class="detail-info-card">
										<div class="detail-icon bg-warning text-dark"><i class="fa-solid fa-bolt"></i></div>
										<div>
											<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.priority') }}</div>
											<div class="fw-semibold small"><span class="badge rounded-pill" :class="getCampaignPriorityClass(detailCampaign.priority)">{{ getCampaignPriorityLabel(detailCampaign.priority) }}</span></div>
										</div>
									</div>
								</div>
							</div>

							<div class="d-flex align-items-center gap-3 mb-4 p-3 bg-light rounded-3">
								<div class="coordinator-avatar-lg" :style="{ background: detailCampaign.creatorColor }">{{ detailCampaign.creatorInitial }}</div>
								<div>
									<div class="fw-bold">{{ detailCampaign.creator }}</div>
									<div class="text-muted small">{{ detailCampaign.creatorEmail }}</div>
								</div>
								<span class="badge bg-info ms-auto">{{ $t('admin.campaignManagement.detailModal.creatorLabel') }}</span>
							</div>

							<div class="mb-4">
								<h6 class="fw-bold small mb-2"><i class="fa-solid fa-file-lines text-primary me-2"></i>{{ $t('admin.campaignManagement.detailModal.description') }}</h6>
								<div v-if="detailCampaignDescriptionSections.length" class="row g-3">
									<div v-for="section in detailCampaignDescriptionSections" :key="section.key" class="col-md-6">
										<div class="campaign-description-card h-100">
											<div class="small fw-bold text-primary mb-2">{{ section.label }}</div>
											<div class="text-muted small lh-lg mb-0">{{ section.value }}</div>
										</div>
									</div>
								</div>
								<ul v-else-if="detailCampaignDescriptionItems.length > 1" class="text-muted small mb-0 ps-3 lh-lg campaign-description-list">
									<li v-for="(item, index) in detailCampaignDescriptionItems" :key="`admin-dashboard-campaign-description-${index}`" class="mb-2">
										{{ item }}
									</li>
								</ul>
								<p v-else class="text-muted small mb-0 lh-lg">{{ detailCampaignDescriptionItems[0] || detailCampaign.description || '—' }}</p>
							</div>

							<div class="mb-4">
								<h6 class="fw-bold small mb-2"><i class="fa-solid fa-gears text-primary me-2"></i>{{ $t('admin.campaignManagement.detailModal.skills') }}</h6>
								<div class="d-flex flex-wrap gap-2">
									<span v-for="skill in detailCampaign.skills" :key="skill.id || skill.ten || skill" class="badge bg-white text-primary border border-primary px-3 py-2" style="font-size:12px">
										{{ skill.ten || skill }}
									</span>
									<span v-if="!detailCampaign.skills.length" class="text-muted small">—</span>
								</div>
							</div>

							<div class="mb-4" v-if="detailCampaign.location">
								<h6 class="fw-bold small mb-2"><i class="fa-solid fa-map-location-dot text-danger me-2"></i>{{ $t('admin.campaignManagement.detailModal.map') }}</h6>
								<div id="dashboard-campaign-detail-map" class="admin-detail-map-wrapper rounded-3 border"></div>
								<div class="d-flex gap-2 mt-2" v-if="campaignDetailMapLat">
									<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ $t('admin.campaignManagement.detailModal.lat') }}: {{ campaignDetailMapLat }}</span>
									<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ $t('admin.campaignManagement.detailModal.lng') }}: {{ campaignDetailMapLng }}</span>
								</div>
							</div>

							<div class="row g-4">
								<div class="col-lg-6">
									<div class="detail-section-card h-100">
										<div class="d-flex align-items-center justify-content-between mb-3">
											<h6 class="fw-bold mb-0"><i class="fa-solid fa-comments text-warning me-2"></i>{{ $t('admin.campaignManagement.feedback.title') }}</h6>
											<span class="badge bg-light text-dark">{{ detailCampaign.feedbacks.length }}</span>
										</div>
										<div v-if="detailCampaign.feedbacks.length === 0" class="text-muted small">{{ $t('admin.campaignManagement.feedback.empty') }}</div>
										<div v-for="feedback in detailCampaign.feedbacks" :key="feedback.id" class="feedback-item border rounded-3 p-3 mb-2">
											<div class="d-flex justify-content-between gap-3 flex-wrap mb-2">
												<div>
													<div class="fw-semibold small">{{ feedback.nguoi_dung?.ho_ten || '—' }}</div>
													<div class="text-muted" style="font-size: 12px;">{{ feedback.nguoi_dung?.email || '—' }}</div>
												</div>
												<div class="text-warning small fw-semibold">
													<i class="fa-solid fa-star me-1"></i>{{ feedback.so_sao }}/5
												</div>
											</div>
											<div class="small text-muted mb-2">{{ feedback.nhan_xet || '—' }}</div>
											<div class="d-flex flex-wrap gap-1">
												<span v-for="tag in feedback.the_phan_hoi" :key="tag.id" class="badge bg-light text-dark border">{{ tag.ten }}</span>
											</div>
										</div>
									</div>
								</div>

								<div class="col-lg-6">
									<div class="detail-section-card h-100">
										<div class="d-flex align-items-center justify-content-between mb-3">
											<h6 class="fw-bold mb-0"><i class="fa-solid fa-triangle-exclamation text-danger me-2"></i>{{ $t('admin.campaignManagement.reports.title') }}</h6>
											<span class="badge bg-light text-dark">{{ detailCampaign.reports.length }}</span>
										</div>
										<div v-if="detailCampaign.reports.length === 0" class="text-muted small">{{ $t('admin.campaignManagement.reports.empty') }}</div>
										<div v-for="report in detailCampaign.reports" :key="report.id" class="feedback-item border rounded-3 p-3 mb-2">
											<div class="d-flex justify-content-between align-items-start gap-3 flex-wrap mb-2">
												<div>
													<div class="fw-semibold small">{{ report.tieu_de }}</div>
													<div class="text-muted" style="font-size: 12px;">{{ report.nguoi_gui?.ho_ten || '—' }} • {{ formatDateTime(report.tao_luc) }}</div>
												</div>
												<span class="badge rounded-pill" :class="getCampaignReportStatusClass(report.trang_thai)">{{ getCampaignReportStatusLabel(report.trang_thai) }}</span>
											</div>
											<div class="small text-muted mb-2">{{ report.noi_dung }}</div>
											<div class="small mb-2" v-if="report.phan_hoi_xu_ly">
												<strong>{{ $t('admin.campaignManagement.reports.responseLabel') }}:</strong> {{ report.phan_hoi_xu_ly }}
											</div>
										</div>
									</div>
								</div>
							</div>

							<div class="detail-section-card mt-4">
								<div class="d-flex align-items-center justify-content-between mb-3">
									<h6 class="fw-bold mb-0"><i class="fa-solid fa-clock-rotate-left text-secondary me-2"></i>{{ $t('admin.campaignManagement.history.title') }}</h6>
									<span class="badge bg-light text-dark">{{ detailCampaign.history.length }}</span>
								</div>
								<div v-if="detailCampaign.history.length === 0" class="text-muted small">{{ $t('admin.campaignManagement.history.empty') }}</div>
								<div v-for="item in detailCampaign.history" :key="item.id" class="history-item d-flex gap-3 py-2 border-bottom">
									<div class="history-dot"></div>
									<div class="flex-grow-1">
										<div class="d-flex justify-content-between gap-3 flex-wrap">
											<div class="fw-semibold small">{{ getCampaignHistoryLabel(item.hanh_dong) }}</div>
											<div class="text-muted" style="font-size: 12px;">{{ formatDateTime(item.tao_luc) }}</div>
										</div>
										<div class="small text-muted" v-if="item.nguoi_thuc_hien">{{ item.nguoi_thuc_hien.ho_ten }}</div>
										<div class="small mt-1" v-if="item.tu_trang_thai || item.den_trang_thai">
											<span class="badge bg-light text-dark border">{{ item.tu_trang_thai || '—' }}</span>
											<i class="fa-solid fa-arrow-right mx-2 text-muted"></i>
											<span class="badge bg-light text-dark border">{{ item.den_trang_thai || '—' }}</span>
										</div>
										<div class="small text-muted mt-1" v-if="item.ghi_chu">{{ item.ghi_chu }}</div>
									</div>
								</div>
							</div>
						</div>
						<div class="modal-footer border-0 bg-light py-3">
							<button type="button" class="btn btn-light rounded-pill px-4" @click="closeCampaignDetailModal">{{ $t('admin.campaignManagement.detailModal.close') }}</button>
						</div>
					</template>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showCampaignDetailModal" @click="closeCampaignDetailModal"></div>
	</div>
</template>

<script>
import api from '../../services/api';
import { hasPermission } from '../../utils/permissions';
import { extractCampaignDescriptionSections, parseCampaignDescription } from '../../utils/campaignDescription';

export default {
	name: 'AdminDashboard',
	props: {
		toast: { type: Object, default: null }
	},
	data() {
		return {
			currentUser: null,
			period: 'month',
			stats: [],
			chartData: [],
			selectedActivity: null,
			selectedActivityPage: 1,
			selectedActivityPageSize: 10,
			showUserDetailModal: false,
			showCampaignDetailModal: false,
			showCampaignDetailLoading: false,
			detailUser: null,
			detailCampaign: null,
			campaignDetailMap: null,
			campaignDetailMapLat: '',
			campaignDetailMapLng: '',
			roleDistribution: [],
			recentUsers: [],
			recentCampaigns: [],
		}
	},
	async created() {
		this.loadCurrentUser();
		await this.fetchDashboard();
	},
	beforeUnmount() {
		if (this.campaignDetailMap) {
			this.campaignDetailMap.remove();
			this.campaignDetailMap = null;
		}
	},
	computed: {
		canManageUsers() {
			return hasPermission(this.currentUser, 'user_management.manage');
		},
		canViewUsers() {
			return hasPermission(this.currentUser, 'user_management.view');
		},
		totalUsers() {
			return this.stats.find((item) => item.key === 'total_users')?.value || 0;
		},
		activeCampaignsLabel() {
			return this.stats.find((item) => item.key === 'active_campaigns')?.badge_label
				|| this.$t('admin.dashboard.campaigns.activeCountLabel', { count: 0 });
		},
		selectedActivityItems() {
			if (!this.selectedActivity) return [];
			return this.selectedActivity.type === 'registrations'
				? (this.selectedActivity.registration_items || [])
				: (this.selectedActivity.campaign_items || []);
		},
		selectedActivityTitle() {
			if (!this.selectedActivity) return '';
			return this.selectedActivity.type === 'registrations'
				? this.$t('admin.dashboard.activity.registrationsTitle', { label: this.selectedActivity.label })
				: this.$t('admin.dashboard.activity.campaignsTitle', { label: this.selectedActivity.label });
		},
		selectedActivityTotalPages() {
			return Math.max(1, Math.ceil(this.selectedActivityItems.length / this.selectedActivityPageSize));
		},
		paginatedSelectedActivityItems() {
			const currentPage = Math.min(this.selectedActivityPage, this.selectedActivityTotalPages);
			const start = (currentPage - 1) * this.selectedActivityPageSize;
			return this.selectedActivityItems.slice(start, start + this.selectedActivityPageSize);
		},
		selectedActivityRange() {
			if (!this.selectedActivityItems.length) {
				return { from: 0, to: 0 };
			}
			const currentPage = Math.min(this.selectedActivityPage, this.selectedActivityTotalPages);
			const from = (currentPage - 1) * this.selectedActivityPageSize + 1;
			const to = Math.min(currentPage * this.selectedActivityPageSize, this.selectedActivityItems.length);
			return { from, to };
		},
		visibleSelectedActivityPages() {
			const total = this.selectedActivityTotalPages;
			const current = Math.min(this.selectedActivityPage, total);
			const start = Math.max(1, current - 1);
			const end = Math.min(total, start + 2);
			const adjustedStart = Math.max(1, end - 2);
			return Array.from({ length: end - adjustedStart + 1 }, (_, index) => adjustedStart + index);
		},
		detailCampaignDescriptionSections() {
			return extractCampaignDescriptionSections(this.detailCampaign?.description || '');
		},
		detailCampaignDescriptionItems() {
			return parseCampaignDescription(this.detailCampaign?.description || '');
		},
	},
	watch: {
		selectedActivityItems() {
			if (this.selectedActivityPage > this.selectedActivityTotalPages) {
				this.selectedActivityPage = this.selectedActivityTotalPages;
			}
		},
	},
	methods: {
		loadCurrentUser() {
			try {
				this.currentUser = JSON.parse(localStorage.getItem('user') || 'null');
			} catch (_error) {
				this.currentUser = null;
			}
		},
		async fetchDashboard() {
			try {
				const { data } = await api.get('/admin/dashboard', { params: { period: this.period } });
				const payload = data?.data || {};
				const summary = payload.summary || {};
				this.stats = Object.values(summary);

				const chartRows = payload.activity_chart || [];
				const chartMax = Math.max(1, ...chartRows.flatMap((item) => [Number(item.registrations || 0), Number(item.campaigns || 0)]));
				this.chartData = chartRows.map((item) => ({
					label: item.label,
					reg: Number(item.registrations || 0),
					camp: Number(item.campaigns || 0),
					regHeight: Math.max(4, Math.round((Number(item.registrations || 0) / chartMax) * 100)),
					campHeight: Math.max(4, Math.round((Number(item.campaigns || 0) / chartMax) * 100)),
					registration_items: item.registration_items || [],
					campaign_items: item.campaign_items || [],
				}));

				this.roleDistribution = payload.role_distribution || [];
				this.recentUsers = payload.recent_users || [];
				this.recentCampaigns = payload.recent_campaigns || [];
			} catch (error) {
				if (this.toast) {
					this.toast.error(
						this.$t('admin.dashboard.messages.loadFailed'),
						error?.response?.data?.message || this.$t('common.pleaseTryAgain')
					);
				}
			}
		},
		selectActivityBucket(item, type) {
			this.selectedActivity = { ...item, type };
			this.selectedActivityPage = 1;
		},
		changeSelectedActivityPage(page) {
			if (page < 1 || page > this.selectedActivityTotalPages) return;
			this.selectedActivityPage = page;
		},
		openUserDetail(user) {
			this.detailUser = user;
			this.showUserDetailModal = true;
		},
		async openCampaignDetail(campaign) {
			if (!campaign?.id) return;
			this.ensureLeaflet();
			this.showCampaignDetailModal = true;
			this.showCampaignDetailLoading = true;
			this.detailCampaign = null;
			this.campaignDetailMapLat = '';
			this.campaignDetailMapLng = '';
			try {
				const { data } = await api.get(`/kiem-duyet/chien-dich/${campaign.id}`);
				if (data?.status === 1 && data?.data) {
					this.detailCampaign = this.mapCampaignDetail(data.data);
					this.$nextTick(() => setTimeout(() => this.geocodeCampaignDetailMap(), 250));
				}
			} catch (error) {
				this.showCampaignDetailModal = false;
				if (this.toast) {
					this.toast.error(
						this.$t('admin.dashboard.messages.loadFailed'),
						error?.response?.data?.message || this.$t('common.pleaseTryAgain')
					);
				}
			} finally {
				this.showCampaignDetailLoading = false;
			}
		},
		closeCampaignDetailModal() {
			this.showCampaignDetailModal = false;
			this.showCampaignDetailLoading = false;
			this.detailCampaign = null;
			this.campaignDetailMapLat = '';
			this.campaignDetailMapLng = '';
			if (this.campaignDetailMap) {
				this.campaignDetailMap.remove();
				this.campaignDetailMap = null;
			}
		},
		mapCampaignDetail(item) {
			const campaignType = item.loai_chien_dich || {};
			const creatorName = item.nguoi_tao?.ho_ten || item.creator_name || '—';
			const priority = {
				khan_cap: 'urgent',
				cao: 'high',
				trung_binh: 'medium',
				thap: 'low',
			}[item.muc_do_uu_tien] || 'medium';
			const baseColor = campaignType.mau_sac || '#0d6efd';

			return {
				id: item.id,
				title: item.tieu_de || item.title || '—',
				description: item.mo_ta || '',
				location: item.dia_diem || item.location || '—',
				latitude: item.vi_do || null,
				longitude: item.kinh_do || null,
				startDate: item.ngay_bat_dau || null,
				endDate: item.ngay_ket_thuc || null,
				maxVolunteers: Number(item.so_luong_toi_da || item.target || 0),
				registered: Number(item.so_dang_ky || item.volunteers || 0),
				priority,
				status: item.trang_thai || item.status || '',
				categoryName: campaignType.ten || this.$t('admin.campaignManagement.filter.allCategories'),
				creator: creatorName,
				creatorEmail: item.nguoi_tao?.email || item.creator_email || '—',
				creatorInitial: creatorName.charAt(0).toUpperCase(),
				creatorColor: this.pickAvatarColor(item.nguoi_tao?.id || item.id),
				skills: item.ky_nangs || [],
				color: `linear-gradient(135deg, ${baseColor}, ${this.lightenColor(baseColor)})`,
				icon: campaignType.bieu_tuong ? `fa-solid ${campaignType.bieu_tuong}` : 'fa-solid fa-flag',
				feedbacks: item.feedbacks || [],
				reports: item.bao_caos || [],
				history: item.lich_su_kiem_duyet || [],
			};
		},
		getCampaignPriorityLabel(priority) {
			return this.$t(`admin.campaignManagement.priorities.${priority}`);
		},
		getCampaignPriorityClass(priority) {
			return { urgent: 'bg-danger text-white', high: 'bg-warning text-dark', medium: 'bg-info text-white', low: 'bg-light text-muted border' }[priority] || 'bg-secondary';
		},
		getCampaignReportStatusLabel(status) {
			return this.$t(`admin.campaignManagement.reports.statuses.${status}`);
		},
		getCampaignReportStatusClass(status) {
			return {
				moi: 'bg-warning text-dark',
				dang_xu_ly: 'bg-info text-white',
				da_xu_ly: 'bg-success text-white',
				tu_choi: 'bg-secondary text-white',
			}[status] || 'bg-light text-dark';
		},
		getCampaignHistoryLabel(action) {
			return this.$t(`admin.campaignManagement.history.actions.${action}`);
		},
		pickAvatarColor(seed) {
			const colors = ['#0d6efd', '#198754', '#6f42c1', '#dc3545', '#fd7e14', '#0dcaf0'];
			return colors[seed % colors.length];
		},
		lightenColor(hex) {
			if (!hex || !hex.startsWith('#') || hex.length < 7) return '#6ea8fe';
			let r = parseInt(hex.slice(1, 3), 16);
			let g = parseInt(hex.slice(3, 5), 16);
			let b = parseInt(hex.slice(5, 7), 16);
			r = Math.min(255, r + 40);
			g = Math.min(255, g + 40);
			b = Math.min(255, b + 40);
			return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
		},
		getTrendText(stat) {
			const rawText = `${stat?.trend?.text || ''}`.trim();
			if (!rawText) {
				return this.$t('admin.dashboard.trend.noChange');
			}

			if (rawText === '0') {
				return this.$t('admin.dashboard.trend.noChange');
			}

			if (/^[+-]?\d+([.,]\d+)?$/.test(rawText)) {
				const value = Number(rawText.replace(',', '.'));
				if (value > 0) {
					return this.$t('admin.dashboard.trend.increase', { value: this.formatNumber(value) });
				}
				if (value < 0) {
					return this.$t('admin.dashboard.trend.decrease', { value: this.formatNumber(Math.abs(value)) });
				}
				return this.$t('admin.dashboard.trend.noChange');
			}

			return rawText;
		},
		trendBadgeClass(stat) {
			return stat?.trend?.positive
				? 'bg-success-subtle text-success'
				: 'bg-warning-subtle text-warning';
		},
		trendIcon(stat) {
			const rawText = `${stat?.trend?.text || ''}`.trim();
			if (rawText === '0') {
				return 'fa-minus';
			}
			return stat?.trend?.positive ? 'fa-arrow-up' : 'fa-arrow-down';
		},
		formatNumber(value) {
			return new Intl.NumberFormat('vi-VN').format(Number(value || 0));
		},
		formatDateTime(value) {
			if (!value) return '—';
			const date = new Date(value);
			return Number.isNaN(date.getTime()) ? value : `${date.toLocaleDateString('vi-VN')} ${date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}`;
		},
		formatDate(value) {
			if (!value) return '—';
			const date = new Date(value);
			return Number.isNaN(date.getTime()) ? value : date.toLocaleDateString('vi-VN');
		},
		campaignThumbStyle(campaign) {
			if (campaign.image) {
				return { backgroundImage: `url(${campaign.image})` };
			}
			return { background: 'linear-gradient(135deg, #4f8cf7, #77a6ff)' };
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
				document.head.appendChild(script);
			}
		},
		initCampaignDetailMap(lat, lng) {
			this.$nextTick(() => {
				const container = document.getElementById('dashboard-campaign-detail-map');
				if (!container || !window.L) return;
				if (this.campaignDetailMap) {
					this.campaignDetailMap.remove();
					this.campaignDetailMap = null;
				}

				this.campaignDetailMap = window.L.map(container, {
					center: [lat, lng],
					zoom: 13,
					zoomControl: true,
					scrollWheelZoom: false,
				});

				window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
					maxZoom: 19,
					attribution: '&copy; OpenStreetMap contributors'
				}).addTo(this.campaignDetailMap);

				window.L.marker([lat, lng]).addTo(this.campaignDetailMap);
				setTimeout(() => this.campaignDetailMap?.invalidateSize(), 200);
			});
		},
		async geocodeCampaignDetailMap() {
			if (!this.detailCampaign?.location) return;
			try {
				const query = encodeURIComponent(this.detailCampaign.location);
				const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${query}&limit=1`);
				const data = await response.json();
				if (data && data.length > 0) {
					this.campaignDetailMapLat = parseFloat(data[0].lat).toFixed(6);
					this.campaignDetailMapLng = parseFloat(data[0].lon).toFixed(6);
					this.initCampaignDetailMap(parseFloat(data[0].lat), parseFloat(data[0].lon));
				} else {
					this.initCampaignDetailMap(16.0544, 108.2022);
				}
			} catch (_error) {
				this.initCampaignDetailMap(16.0544, 108.2022);
			}
		},
	}
}
</script>

<style scoped>
/* ===== Stat Cards ===== */
.stat-card {
	border-radius: 14px;
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}
.stat-card:hover {
	transform: translateY(-2px);
	box-shadow: 0 6px 20px rgba(0,0,0,0.08) !important;
}

.stat-icon {
	width: 48px;
	height: 48px;
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 20px;
	flex-shrink: 0;
}

/* ===== Chart ===== */
.chart-bar {
	width: 18px;
	border-radius: 4px 4px 0 0;
	transition: height 0.5s ease;
	min-height: 4px;
}

.clickable-bar {
	cursor: pointer;
}

.clickable-bar:hover {
	filter: brightness(0.95);
}

.chart-legend {
	font-size: 12px;
	color: #6c757d;
	display: flex;
	align-items: center;
	gap: 4px;
}

.legend-dot {
	width: 8px;
	height: 8px;
	border-radius: 50%;
	display: inline-block;
}

/* ===== Donut Chart ===== */
.donut-chart {
	width: 155px;
	height: 155px;
	border-radius: 50%;
	background: conic-gradient(
		#4f8cf7 0% 79%,
		#28a745 79% 95%,
		#fd7e14 95% 95.4%,
		#dc3545 95.4% 100%
	);
	display: flex;
	align-items: center;
	justify-content: center;
	position: relative;
}

.donut-hole {
	width: 105px;
	height: 105px;
	border-radius: 50%;
	background: white;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
}

.role-dot {
	width: 10px;
	height: 10px;
	min-width: 10px;
	border-radius: 50%;
}

/* ===== Pending / Campaigns ===== */
.user-avatar-sm {
	width: 38px;
	height: 38px;
	min-width: 38px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 15px;
}

.user-view-avatar {
	width: 72px;
	height: 72px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 28px;
	font-weight: 700;
}

.approval-item {
	transition: background 0.2s ease;
}
.approval-item:hover {
	background: #f8f9fa;
}

.campaign-thumb {
	width: 52px;
	height: 52px;
	min-width: 52px;
	border-radius: 10px;
	background-size: cover;
	background-position: center;
}

.campaign-item {
	transition: background 0.2s ease;
}
.campaign-item:hover {
	background: #f8f9fa;
}

.campaign-title-text {
	display: -webkit-box;
	-webkit-line-clamp: 1;
	line-clamp: 1;
	-webkit-box-orient: vertical;
	overflow: hidden;
}

.coordinator-avatar-lg {
	width: 48px;
	height: 48px;
	min-width: 48px;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	border-radius: 50%;
	font-size: 20px;
}

.detail-info-card {
	display: flex;
	align-items: flex-start;
	gap: 12px;
	padding: 14px;
	background: #f8f9fa;
	border-radius: 12px;
}

.detail-icon {
	width: 36px;
	height: 36px;
	min-width: 36px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 14px;
}

.detail-section-card {
	background: #fff;
	border: 1px solid #e9ecef;
	border-radius: 16px;
	padding: 1rem;
}

.feedback-item:last-child {
	margin-bottom: 0 !important;
}

.history-item:last-child {
	border-bottom: none !important;
}

.campaign-description-card {
	border: 1px solid rgba(13, 110, 253, 0.12);
	border-radius: 1rem;
	padding: 0.9rem 1rem;
	background: linear-gradient(180deg, rgba(13, 110, 253, 0.04), rgba(13, 110, 253, 0.01));
}

.campaign-description-list li:last-child {
	margin-bottom: 0 !important;
}

.history-dot {
	width: 10px;
	height: 10px;
	min-width: 10px;
	border-radius: 50%;
	background: #0d6efd;
	margin-top: 8px;
}

.admin-detail-map-wrapper {
	height: 260px;
	width: 100%;
	z-index: 0;
}

@media (max-width: 575px) {
	.stat-icon {
		width: 40px;
		height: 40px;
		font-size: 16px;
	}
}
</style>
