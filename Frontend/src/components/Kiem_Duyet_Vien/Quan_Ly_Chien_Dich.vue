<template>
	<div class="admin-campaigns">
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-flag text-primary me-2"></i>{{ $t('admin.campaignManagement.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.campaignManagement.subtitle') }}</p>
			</div>
		</div>

		<div class="row g-3 mb-4">
			<div class="col-xl col-lg-4 col-sm-6" v-for="stat in statsCards" :key="stat.label">
				<div class="card stat-card border-0 shadow-sm h-100">
					<div class="card-body p-3">
						<div class="d-flex align-items-start justify-content-between">
							<div>
								<p class="text-muted small mb-1">{{ stat.label }}</p>
								<h3 class="fw-bold mb-0">{{ stat.value }}</h3>
							</div>
							<div class="stat-icon" :style="stat.iconStyle">
								<i :class="stat.icon"></i>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<ul class="nav nav-tabs admin-tabs mb-4">
			<li class="nav-item" v-for="tab in filterMeta.tabs" :key="tab.value">
				<a class="nav-link" :class="{ active: activeTab === tab.value }" href="#" @click.prevent="activeTab = tab.value">
					<i :class="getTabIcon(tab.value)" class="me-1"></i>{{ getTabLabel(tab.value) }}
					<span class="badge ms-1" :class="getTabBadgeClass(tab.value)">{{ tab.count }}</span>
				</a>
			</li>
		</ul>

		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body py-3">
				<div class="row g-3 align-items-center">
					<div class="col-md-4">
						<div class="position-relative">
							<input type="text" class="form-control ps-5" :placeholder="$t('admin.campaignManagement.filter.searchPlaceholder')" v-model="searchQuery">
							<i class="fa-solid fa-search position-absolute" style="left: 16px; top: 50%; transform: translateY(-50%); color: #adb5bd;"></i>
						</div>
					</div>
					<div class="col-md-3">
						<select class="form-select" v-model="filterCategory">
							<option value="">{{ $t('admin.campaignManagement.filter.allCategories') }}</option>
							<option v-for="item in filterMeta.categories" :key="item.value" :value="item.value">{{ item.label }}</option>
						</select>
					</div>
					<div class="col-md-3">
						<select class="form-select" v-model="filterPriority">
							<option value="">{{ $t('admin.campaignManagement.filter.allPriorities') }}</option>
							<option v-for="priority in filterMeta.priorities" :key="priority.value" :value="priority.value">{{ getPriorityLabel(priority.value) }}</option>
						</select>
					</div>
					<div class="col-md-2 text-end">
						<button class="btn btn-outline-secondary btn-sm" @click="resetFilters">
							<i class="fa-solid fa-rotate-left me-1"></i>{{ $t('admin.campaignManagement.filter.reset') }}
						</button>
					</div>
				</div>
			</div>
		</div>

		<div class="card border-0 shadow-sm">
			<div class="card-body p-0">
				<div v-if="isLoading" class="p-5 text-center text-muted">
					<div class="spinner-border text-primary mb-3"></div>
					<div>{{ $t('common.loading') }}</div>
				</div>
				<div v-else class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead class="table-light">
							<tr>
								<th>{{ $t('admin.campaignManagement.table.campaign') }}</th>
								<th>{{ $t('admin.campaignManagement.table.creator') }}</th>
								<th>{{ $t('admin.campaignManagement.table.type') }}</th>
								<th class="text-center">{{ $t('admin.campaignManagement.table.priority') }}</th>
								<th class="text-center">{{ $t('admin.campaignManagement.table.volunteers') }}</th>
								<th class="text-center">{{ $t('admin.campaignManagement.table.status') }}</th>
								<th>{{ $t('admin.campaignManagement.table.time') }}</th>
								<th class="text-center">{{ $t('admin.campaignManagement.table.actions') }}</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="c in filteredCampaigns" :key="c.id">
								<td>
									<div class="d-flex align-items-center gap-3 ps-3">
										<div class="campaign-table-icon" :style="{ background: c.color }">
											<i :class="c.icon" class="text-white"></i>
										</div>
										<div class="min-w-0">
											<h6 class="mb-0 small fw-bold text-truncate" style="max-width: 250px;">{{ c.title }}</h6>
											<span class="text-muted d-flex align-items-center gap-1" style="font-size: 11px;">
												<i class="fa-solid fa-location-dot text-danger"></i>{{ c.location }}
											</span>
										</div>
									</div>
								</td>
								<td>
									<div class="d-flex align-items-center gap-2">
										<div class="coordinator-avatar" :style="{ background: c.creatorColor }">{{ c.creatorInitial }}</div>
										<div>
											<div class="small fw-semibold">{{ c.creator }}</div>
											<div class="text-muted" style="font-size: 11px;">{{ c.creatorEmail }}</div>
										</div>
									</div>
								</td>
								<td>
									<span class="badge rounded-pill" :class="getCategoryClass(c.categoryKey)">
										<i :class="c.icon" class="me-1"></i>{{ c.categoryName }}
									</span>
								</td>
								<td class="text-center">
									<span class="badge rounded-pill" :class="getPriorityClass(c.priority)">{{ getPriorityLabel(c.priority) }}</span>
								</td>
								<td class="text-center">
									<div class="d-flex flex-column align-items-center">
										<button type="button" class="btn btn-sm p-0 border-0 bg-transparent shadow-none volunteer-count-btn" @click="openVolunteerListModal(c)">
											<span class="fw-bold small text-dark">{{ c.registered }}/{{ c.maxVolunteers }}</span>
										</button>
										<div class="progress mt-1" style="width: 50px; height: 4px;">
											<div class="progress-bar bg-success" :style="{ width: getProgress(c) + '%' }"></div>
										</div>
									</div>
								</td>
								<td class="text-center">
									<span class="badge rounded-pill" :class="getStatusClass(c.status)">
										<i :class="getStatusIcon(c.status)" class="me-1"></i>{{ getStatusLabel(c.status) }}
									</span>
								</td>
								<td>
									<div class="small text-muted">
										<div><i class="fa-solid fa-play text-success me-1" style="font-size:9px"></i>{{ formatDate(c.startDate) }}</div>
										<div><i class="fa-solid fa-stop text-danger me-1" style="font-size:9px"></i>{{ formatDate(c.endDate) }}</div>
									</div>
								</td>
								<td class="text-center">
									<div class="btn-group flex-wrap justify-content-center">
										<button class="btn btn-sm btn-outline-primary" :title="$t('admin.campaignManagement.actions.view')" @click="openDetailModal(c)">
											<i class="fa-solid fa-eye"></i>
										</button>
										<button v-if="c.rawStatus === 'cho_duyet'" class="btn btn-sm btn-outline-success" :title="$t('admin.campaignManagement.actions.approve')" @click="confirmApprove(c)">
											<i class="fa-solid fa-check"></i>
										</button>
										<button v-if="c.rawStatus === 'cho_duyet'" class="btn btn-sm btn-outline-danger" :title="$t('admin.campaignManagement.actions.reject')" @click="openRejectModal(c, 'campaign')">
											<i class="fa-solid fa-xmark"></i>
										</button>
										<button v-if="c.rawStatus === 'yeu_cau_huy'" class="btn btn-sm btn-outline-danger" :title="$t('admin.campaignManagement.actions.approveCancel')" @click="confirmApproveCancel(c)">
											<i class="fa-solid fa-ban"></i>
										</button>
										<button v-if="c.rawStatus === 'yeu_cau_huy'" class="btn btn-sm btn-outline-secondary" :title="$t('admin.campaignManagement.actions.rejectCancel')" @click="openRejectModal(c, 'cancel_request')">
											<i class="fa-solid fa-rotate-left"></i>
										</button>
									</div>
								</td>
							</tr>
						</tbody>
					</table>
				</div>

				<div class="text-center py-5" v-if="!isLoading && filteredCampaigns.length === 0">
					<i class="fa-solid fa-flag text-muted" style="font-size: 48px;"></i>
					<p class="text-muted mt-3">{{ $t('admin.campaignManagement.emptyState') }}</p>
				</div>
			</div>
		</div>

		<div class="modal fade" :class="{ show: showDetailModal }" :style="showDetailModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
				<div class="modal-content border-0 shadow" v-if="detailTarget">
					<div class="modal-header border-0" :style="{ background: detailTarget.color }">
						<div class="d-flex align-items-center gap-3">
							<div class="rounded-3 d-flex align-items-center justify-content-center" style="width:48px;height:48px; background-color: rgba(255,255,255,0.2);">
								<i :class="detailTarget.icon" class="text-white fs-5"></i>
							</div>
							<div class="text-white">
								<h5 class="fw-bold mb-0">{{ detailTarget.title }}</h5>
								<span class="small opacity-75">{{ detailTarget.categoryName }}</span>
							</div>
						</div>
						<button type="button" class="btn-close btn-close-white" @click="closeDetailModal"></button>
					</div>
					<div class="modal-body p-4">
						<div class="row g-3 mb-4">
							<div class="col-sm-6 col-xl-3">
								<div class="detail-info-card">
									<div class="detail-icon bg-danger text-white"><i class="fa-solid fa-location-dot"></i></div>
									<div>
										<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.location') }}</div>
										<div class="fw-semibold small">{{ detailTarget.location }}</div>
									</div>
								</div>
							</div>
							<div class="col-sm-6 col-xl-3">
								<div class="detail-info-card">
									<div class="detail-icon bg-primary text-white"><i class="fa-solid fa-calendar-days"></i></div>
									<div>
										<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.time') }}</div>
										<div class="fw-semibold small">{{ formatDate(detailTarget.startDate) }} — {{ formatDate(detailTarget.endDate) }}</div>
									</div>
								</div>
							</div>
							<div class="col-sm-6 col-xl-3">
								<div class="detail-info-card">
									<div class="detail-icon bg-success text-white"><i class="fa-solid fa-users"></i></div>
									<div>
										<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.requiredVolunteers') }}</div>
										<div class="fw-semibold small">{{ detailTarget.maxVolunteers }} {{ $t('admin.campaignManagement.detailModal.people') }} ({{ detailTarget.registered }} {{ $t('admin.campaignManagement.detailModal.registered') }})</div>
									</div>
								</div>
							</div>
							<div class="col-sm-6 col-xl-3">
								<div class="detail-info-card">
									<div class="detail-icon bg-warning text-dark"><i class="fa-solid fa-bolt"></i></div>
									<div>
										<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.priority') }}</div>
										<div class="fw-semibold small"><span class="badge rounded-pill" :class="getPriorityClass(detailTarget.priority)">{{ getPriorityLabel(detailTarget.priority) }}</span></div>
									</div>
								</div>
							</div>
						</div>

						<div class="d-flex align-items-center gap-3 mb-4 p-3 bg-light rounded-3">
							<div class="coordinator-avatar-lg" :style="{ background: detailTarget.creatorColor }">{{ detailTarget.creatorInitial }}</div>
							<div>
								<div class="fw-bold">{{ detailTarget.creator }}</div>
								<div class="text-muted small">{{ detailTarget.creatorEmail }}</div>
							</div>
							<span class="badge bg-info ms-auto">{{ $t('admin.campaignManagement.detailModal.creatorLabel') }}</span>
						</div>

						<div class="mb-4">
							<h6 class="fw-bold small mb-2"><i class="fa-solid fa-file-lines text-primary me-2"></i>{{ $t('admin.campaignManagement.detailModal.description') }}</h6>
							<p class="text-muted small mb-0 lh-lg">{{ detailTarget.description || '—' }}</p>
						</div>

						<div v-if="detailTarget.cancelReason" class="alert alert-danger border-0 shadow-sm mb-4 cancel-reason-alert">
							<div class="d-flex align-items-start gap-3">
								<div class="detail-icon bg-danger text-white flex-shrink-0">
									<i class="fa-solid fa-ban"></i>
								</div>
								<div>
									<div class="fw-bold small text-danger mb-1">{{ $t('admin.campaignManagement.detailModal.cancelReasonTitle') }}</div>
									<div class="small text-dark mb-1">{{ $t('admin.campaignManagement.detailModal.cancelRequestLabel') }}</div>
									<div class="small lh-lg mb-0">{{ detailTarget.cancelReason }}</div>
								</div>
							</div>
						</div>

						<div class="mb-4">
							<h6 class="fw-bold small mb-2"><i class="fa-solid fa-gears text-primary me-2"></i>{{ $t('admin.campaignManagement.detailModal.skills') }}</h6>
							<div class="d-flex flex-wrap gap-2">
								<span v-for="skill in detailTarget.skills" :key="skill.id || skill.ten || skill"
									class="badge bg-white text-primary border border-primary px-3 py-2" style="font-size:12px">
									{{ skill.ten || skill }}
								</span>
							</div>
						</div>

						<div class="mb-4" v-if="detailTarget.location">
							<h6 class="fw-bold small mb-2"><i class="fa-solid fa-map-location-dot text-danger me-2"></i>{{ $t('admin.campaignManagement.detailModal.map') }}</h6>
							<div id="admin-detail-map" class="admin-detail-map-wrapper rounded-3 border"></div>
							<div class="d-flex gap-2 mt-2" v-if="adminMapLat">
								<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ $t('admin.campaignManagement.detailModal.lat') }}: {{ adminMapLat }}</span>
								<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ $t('admin.campaignManagement.detailModal.lng') }}: {{ adminMapLng }}</span>
							</div>
						</div>

						<div class="row g-4">
							<div class="col-lg-6">
								<div class="detail-section-card h-100">
									<div class="d-flex align-items-center justify-content-between mb-3">
										<h6 class="fw-bold mb-0"><i class="fa-solid fa-comments text-warning me-2"></i>{{ $t('admin.campaignManagement.feedback.title') }}</h6>
										<span class="badge bg-light text-dark">{{ detailTarget.feedbacks.length }}</span>
									</div>
									<div v-if="detailTarget.feedbacks.length === 0" class="text-muted small">{{ $t('admin.campaignManagement.feedback.empty') }}</div>
									<div v-for="feedback in detailTarget.feedbacks" :key="feedback.id" class="feedback-item border rounded-3 p-3 mb-2">
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
										<span class="badge bg-light text-dark">{{ detailTarget.reports.length }}</span>
									</div>
									<div v-if="detailTarget.reports.length === 0" class="text-muted small">{{ $t('admin.campaignManagement.reports.empty') }}</div>
									<div v-for="report in detailTarget.reports" :key="report.id" class="feedback-item border rounded-3 p-3 mb-2">
										<div class="d-flex justify-content-between align-items-start gap-3 flex-wrap mb-2">
											<div>
												<div class="fw-semibold small">{{ report.tieu_de }}</div>
												<div class="text-muted" style="font-size: 12px;">{{ report.nguoi_gui?.ho_ten || '—' }} • {{ formatDateTime(report.tao_luc) }}</div>
											</div>
											<span class="badge rounded-pill" :class="getReportStatusClass(report.trang_thai)">{{ getReportStatusLabel(report.trang_thai) }}</span>
										</div>
										<div class="small text-muted mb-2">{{ report.noi_dung }}</div>
										<div class="small mb-2" v-if="report.phan_hoi_xu_ly">
											<strong>{{ $t('admin.campaignManagement.reports.responseLabel') }}:</strong> {{ report.phan_hoi_xu_ly }}
										</div>
										<button v-if="report.trang_thai !== 'da_xu_ly' && report.trang_thai !== 'tu_choi'" class="btn btn-sm btn-outline-primary rounded-pill" @click="openProcessReportModal(report)">
											<i class="fa-solid fa-screwdriver-wrench me-1"></i>{{ $t('admin.campaignManagement.reports.processAction') }}
										</button>
									</div>
								</div>
							</div>
						</div>

						<div class="detail-section-card mt-4">
							<div class="d-flex align-items-center justify-content-between mb-3">
								<h6 class="fw-bold mb-0"><i class="fa-solid fa-clock-rotate-left text-secondary me-2"></i>{{ $t('admin.campaignManagement.history.title') }}</h6>
								<span class="badge bg-light text-dark">{{ detailTarget.history.length }}</span>
							</div>
							<div v-if="detailTarget.history.length === 0" class="text-muted small">{{ $t('admin.campaignManagement.history.empty') }}</div>
							<div v-for="item in detailTarget.history" :key="item.id" class="history-item d-flex gap-3 py-2 border-bottom">
								<div class="history-dot"></div>
								<div class="flex-grow-1">
									<div class="d-flex justify-content-between gap-3 flex-wrap">
										<div class="fw-semibold small">{{ getHistoryLabel(item.hanh_dong) }}</div>
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
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeDetailModal">{{ $t('admin.campaignManagement.detailModal.close') }}</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showDetailModal" @click="closeDetailModal"></div>

		<div class="modal fade" :class="{ show: showVolunteerListModal }" :style="showVolunteerListModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<div>
							<h5 class="modal-title fw-bold"><i class="fa-solid fa-user-group text-success me-2"></i>{{ $t('admin.campaignManagement.volunteerModal.title') }}</h5>
							<div class="text-muted small" v-if="volunteerListTarget">{{ volunteerListTarget.title }}</div>
						</div>
						<button type="button" class="btn-close" @click="closeVolunteerListModal"></button>
					</div>
					<div class="modal-body pt-3">
						<div v-if="volunteerListLoading" class="text-center py-4 text-muted">
							<div class="spinner-border text-primary mb-3"></div>
							<div>{{ $t('common.loading') }}</div>
						</div>
						<div v-else-if="!volunteerRegistrations.length" class="text-center py-4 text-muted">
							<i class="fa-solid fa-user-slash d-block fs-3 mb-2 opacity-25"></i>
							{{ $t('admin.campaignManagement.volunteerModal.empty') }}
						</div>
						<div v-else class="table-responsive">
							<table class="table table-hover align-middle mb-0">
								<thead class="table-light">
									<tr>
										<th>{{ $t('admin.campaignManagement.volunteerModal.table.volunteer') }}</th>
										<th>{{ $t('admin.campaignManagement.volunteerModal.table.skills') }}</th>
										<th>{{ $t('admin.campaignManagement.volunteerModal.table.area') }}</th>
										<th>{{ $t('admin.campaignManagement.volunteerModal.table.status') }}</th>
										<th>{{ $t('admin.campaignManagement.volunteerModal.table.time') }}</th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="item in volunteerRegistrations" :key="item.id">
										<td>
											<div class="fw-semibold small">{{ item.name }}</div>
											<div class="text-muted" style="font-size: 12px;">{{ item.email }}</div>
										</td>
										<td>
											<div class="d-flex flex-wrap gap-1">
												<span v-for="skill in item.skills" :key="`${item.id}-${skill}`" class="badge bg-light text-dark border">{{ skill }}</span>
												<span v-if="!item.skills.length" class="text-muted small">—</span>
											</div>
										</td>
										<td><span class="text-muted small">{{ item.area }}</span></td>
										<td>
											<span class="badge rounded-pill" :class="getRegistrationStatusClass(item.status)">{{ getRegistrationStatusLabel(item.status) }}</span>
											<div v-if="item.cancelReason" class="small text-muted mt-1">{{ item.cancelReason }}</div>
										</td>
										<td><span class="text-muted small">{{ formatDateTime(item.statusTime || item.registeredAt) }}</span></td>
									</tr>
								</tbody>
							</table>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeVolunteerListModal">{{ $t('common.close') }}</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showVolunteerListModal" @click="closeVolunteerListModal"></div>

		<div class="modal fade" :class="{ show: showRejectModal }" :style="showRejectModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-ban text-danger me-2"></i>{{ rejectMode === 'cancel_request' ? $t('admin.campaignManagement.rejectModal.cancelTitle') : $t('admin.campaignManagement.rejectModal.title') }}</h5>
						<button type="button" class="btn-close" @click="showRejectModal = false"></button>
					</div>
					<div class="modal-body" v-if="rejectTarget">
						<div class="bg-light rounded-3 p-3 mb-3">
							<div class="fw-bold">{{ rejectTarget.title }}</div>
							<div class="text-muted small">{{ $t('admin.campaignManagement.rejectModal.by') }}: {{ rejectTarget.creator }}</div>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('admin.campaignManagement.rejectModal.reason') }} <span class="text-danger">*</span></label>
							<textarea class="form-control" rows="4" :placeholder="$t('admin.campaignManagement.rejectModal.reasonPlaceholder')" v-model="rejectReason"></textarea>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showRejectModal = false">{{ $t('admin.campaignManagement.rejectModal.cancel') }}</button>
						<button type="button" class="btn btn-danger rounded-pill px-4" @click="confirmReject" :disabled="!rejectReason.trim() || actionLoading">
							<i class="fa-solid fa-ban me-1"></i>{{ $t('admin.campaignManagement.rejectModal.confirm') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showRejectModal" @click="showRejectModal = false"></div>

		<div class="modal fade" :class="{ show: showReportModal }" :style="showReportModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-screwdriver-wrench text-primary me-2"></i>{{ $t('admin.campaignManagement.reports.processTitle') }}</h5>
						<button type="button" class="btn-close" @click="showReportModal = false"></button>
					</div>
					<div class="modal-body" v-if="reportTarget">
						<div class="bg-light rounded-3 p-3 mb-3">
							<div class="fw-bold">{{ reportTarget.tieu_de }}</div>
							<div class="text-muted small">{{ reportTarget.nguoi_gui?.ho_ten || '—' }}</div>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('admin.campaignManagement.reports.statusLabel') }}</label>
							<select class="form-select" v-model="reportStatus">
								<option value="dang_xu_ly">{{ $t('admin.campaignManagement.reports.statuses.processing') }}</option>
								<option value="da_xu_ly">{{ $t('admin.campaignManagement.reports.statuses.done') }}</option>
								<option value="tu_choi">{{ $t('admin.campaignManagement.reports.statuses.rejected') }}</option>
							</select>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('admin.campaignManagement.reports.responseLabel') }}</label>
							<textarea class="form-control" rows="4" v-model="reportResponse" :placeholder="$t('admin.campaignManagement.reports.responsePlaceholder')"></textarea>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showReportModal = false">{{ $t('common.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="submitReportProcessing" :disabled="actionLoading">
							<i class="fa-solid fa-check me-1"></i>{{ $t('common.confirm') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showReportModal" @click="showReportModal = false"></div>

		<ConfirmModal ref="confirmModal" :modalId="'reviewCampaignConfirmModal'"
			:title="confirmConfig.title" :message="confirmConfig.message" :detail="confirmConfig.detail"
			:detailList="confirmConfig.detailList" :detailListTitle="confirmConfig.detailListTitle"
			:icon="confirmConfig.icon" :variant="confirmConfig.variant"
			:confirmText="confirmConfig.confirmText" :confirmIcon="confirmConfig.confirmIcon"
			:dismissOnConfirm="false"
			@confirm="onConfirmAction" />
	</div>
</template>

<script>
import ConfirmModal from '../../components/ConfirmModal.vue';
import api from '../../services/api';

const PRIORITY_MAP = { khan_cap: 'urgent', cao: 'high', trung_binh: 'medium', thap: 'low' };
const STATUS_MAP = {
	cho_duyet: 'pending',
	tu_choi: 'rejected',
	da_duyet: 'approved',
	dang_dien_ra: 'active',
	hoan_thanh: 'completed',
	yeu_cau_huy: 'pending_cancel',
	da_huy: 'cancelled',
	nhap: 'draft'
};

export default {
	name: 'AdminQuanLyChienDich',
	components: { ConfirmModal },
	inject: ['toast'],
	data() {
		return {
			isLoading: true,
			actionLoading: false,
			activeTab: 'pending',
			searchQuery: '',
			filterCategory: '',
			filterPriority: '',
			filterMeta: {
				tabs: [],
				categories: [],
				priorities: [],
			},
			campaigns: [],
			searchDebounceTimer: null,
			suspendFilterReload: false,
			suspendRouteWatcher: false,
			stats: {
				tong: 0,
				cho_duyet: 0,
				da_duyet: 0,
				yeu_cau_huy: 0,
				dang_dien_ra: 0,
				hoan_thanh: 0,
			},
			showDetailModal: false,
			showVolunteerListModal: false,
			showRejectModal: false,
			showReportModal: false,
			detailTarget: null,
			volunteerListTarget: null,
			volunteerListLoading: false,
			volunteerRegistrations: [],
			rejectTarget: null,
			rejectMode: 'campaign',
			rejectReason: '',
			reportTarget: null,
			reportStatus: 'dang_xu_ly',
			reportResponse: '',
			confirmConfig: { title: '', message: '', detail: '', detailList: [], detailListTitle: '', icon: '', variant: '', confirmText: '', confirmIcon: '' },
			pendingAction: null,
			actionTarget: null,
			adminMap: null,
			adminMarker: null,
			adminMapLat: '',
			adminMapLng: '',
		};
	},
	computed: {
		statsCards() {
			return [
				{ label: this.$t('admin.campaignManagement.stats.total'), value: this.stats.tong || 0, icon: 'fa-solid fa-flag', iconStyle: this.getStatIconStyle('#0d6efd') },
				{ label: this.$t('admin.campaignManagement.stats.pending'), value: this.stats.cho_duyet || 0, icon: 'fa-solid fa-hourglass-half', iconStyle: this.getStatIconStyle('#f59f00') },
				{ label: this.$t('admin.campaignManagement.stats.approved'), value: this.stats.da_duyet || 0, icon: 'fa-solid fa-check-circle', iconStyle: this.getStatIconStyle('#22b8cf') },
				{ label: this.$t('admin.campaignManagement.stats.pendingCancel'), value: this.stats.yeu_cau_huy || 0, icon: 'fa-solid fa-times-circle', iconStyle: this.getStatIconStyle('#ff4d6d') },
				{ label: this.$t('admin.campaignManagement.stats.active'), value: this.stats.dang_dien_ra || 0, icon: 'fa-solid fa-play', iconStyle: this.getStatIconStyle('#22c55e') },
			];
		},
		filteredCampaigns() {
			return this.campaigns;
		},
	},
	async mounted() {
		this.ensureLeaflet();
		this.syncFiltersFromRoute();
		await Promise.all([this.loadFilterMeta(), this.loadCampaigns()]);
		await this.openDetailFromRouteQuery();
	},
	beforeUnmount() {
		if (this.searchDebounceTimer) {
			clearTimeout(this.searchDebounceTimer);
		}
		if (this.adminMap) {
			this.adminMap.remove();
			this.adminMap = null;
		}
	},
	watch: {
		'$route.query': {
			deep: true,
			async handler() {
				if (this.suspendRouteWatcher) return;
				this.syncFiltersFromRoute();
				await this.loadCampaigns();
				await this.openDetailFromRouteQuery();
			},
		},
		activeTab() {
			if (this.suspendFilterReload) return;
			this.loadCampaigns();
		},
		filterCategory() {
			if (this.suspendFilterReload) return;
			this.loadCampaigns();
		},
		filterPriority() {
			if (this.suspendFilterReload) return;
			this.loadCampaigns();
		},
		searchQuery() {
			if (this.suspendFilterReload) return;
			if (this.searchDebounceTimer) {
				clearTimeout(this.searchDebounceTimer);
			}
			this.searchDebounceTimer = setTimeout(() => {
				this.loadCampaigns();
			}, 300);
		},
	},
	methods: {
		async loadFilterMeta() {
			try {
				const res = await api.get('/kiem-duyet/chien-dich/bo-loc');
				if (res.data?.status === 1) {
					this.filterMeta = {
						tabs: res.data.data?.tabs || [],
						categories: res.data.data?.categories || [],
						priorities: res.data.data?.priorities || [],
					};
				}
			} catch (error) {
				this.showError(error.response?.data?.message || 'Không tải được bộ lọc chiến dịch.');
			}
		},
		syncFiltersFromRoute() {
			const query = this.$route.query || {};
			this.suspendFilterReload = true;
			this.activeTab = typeof query.tab === 'string' && query.tab.trim() ? query.tab : 'pending';
			this.searchQuery = typeof query.search === 'string' ? query.search : '';
			this.filterCategory = typeof query.category === 'string' ? query.category : '';
			this.filterPriority = typeof query.priority === 'string' ? query.priority : '';
			this.$nextTick(() => {
				this.suspendFilterReload = false;
			});
		},
		async openDetailFromRouteQuery() {
			const detailId = Number(this.$route.query?.detail || 0);
			if (!detailId) return;
			if (this.detailTarget?.id === detailId && this.showDetailModal) return;
			const existing = this.campaigns.find((item) => item.id === detailId);
			await this.openDetailModal(existing || { id: detailId });
		},
		buildRouteQuery() {
			const query = {};
			if (this.activeTab && this.activeTab !== 'pending') query.tab = this.activeTab;
			if (this.searchQuery.trim()) query.search = this.searchQuery.trim();
			if (this.filterCategory) query.category = this.filterCategory;
			if (this.filterPriority) query.priority = this.filterPriority;
			const currentDetailId = this.$route.query?.detail;
			if (this.showDetailModal && this.detailTarget?.id) query.detail = String(this.detailTarget.id);
			else if (typeof currentDetailId === 'string' && currentDetailId.trim()) query.detail = currentDetailId;
			return query;
		},
		async syncRouteQuery() {
			const currentQuery = JSON.stringify(this.$route.query || {});
			const nextQuery = JSON.stringify(this.buildRouteQuery());
			if (currentQuery === nextQuery) return;
			this.suspendRouteWatcher = true;
			try {
				await this.$router.replace({ path: this.$route.path, query: JSON.parse(nextQuery) });
			} finally {
				this.suspendRouteWatcher = false;
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
				document.head.appendChild(script);
			}
		},
		async loadCampaigns() {
			this.isLoading = true;
			try {
				await this.syncRouteQuery();

				const params = {};
				if (this.activeTab && this.activeTab !== 'all') {
					params.trang_thai = {
						pending: 'cho_duyet',
						approved: 'da_duyet',
						pending_cancel: 'yeu_cau_huy',
						active: 'dang_dien_ra',
						completed: 'hoan_thanh',
					}[this.activeTab] || this.activeTab;
				}
				if (this.searchQuery.trim()) params.tu_khoa = this.searchQuery.trim();
				if (this.filterCategory) params.loai_chien_dich_id = this.filterCategory;
				if (this.filterPriority) {
					params.muc_do_uu_tien = {
						urgent: 'khan_cap',
						high: 'cao',
						medium: 'trung_binh',
						low: 'thap',
					}[this.filterPriority] || this.filterPriority;
				}

				const res = await api.get('/kiem-duyet/chien-dich', { params });
				if (res.data.status === 1) {
					this.campaigns = (res.data.data || []).map(this.mapCampaignFromApi);
					this.stats = res.data.thong_ke || this.stats;
				}
			} catch (error) {
				this.showError(error.response?.data?.message || 'Không tải được danh sách chiến dịch.');
			} finally {
				this.isLoading = false;
			}
		},
		mapCampaignFromApi(item) {
			const loai = item.loai_chien_dich || {};
			const rawStatus = item.trang_thai;
			const status = STATUS_MAP[rawStatus] || rawStatus;
			const priority = PRIORITY_MAP[item.muc_do_uu_tien] || 'medium';
			const creatorName = item.nguoi_tao?.ho_ten || '—';
			return {
				id: item.id,
				title: item.tieu_de || '—',
				description: item.mo_ta || '',
				location: item.dia_diem || '—',
				latitude: item.vi_do,
				longitude: item.kinh_do,
				startDate: item.ngay_bat_dau,
				endDate: item.ngay_ket_thuc,
				maxVolunteers: item.so_luong_toi_da || 0,
				registered: item.so_dang_ky || 0,
				priority,
				status,
				rawStatus,
				categoryId: item.loai_chien_dich_id || loai.id || null,
				categoryName: loai.ten || this.$t('admin.campaignManagement.filter.allCategories'),
				categoryKey: this.getCategoryKey(loai.ten),
				creator: creatorName,
				creatorEmail: item.nguoi_tao?.email || '—',
				creatorInitial: creatorName.charAt(0).toUpperCase(),
				creatorColor: this.pickAvatarColor(item.nguoi_tao?.id || item.id),
				skills: item.ky_nangs || [],
				color: loai.mau_sac ? `linear-gradient(135deg, ${loai.mau_sac}, ${this.lightenColor(loai.mau_sac)})` : 'linear-gradient(135deg, #0d6efd, #6610f2)',
				icon: loai.bieu_tuong ? `fa-solid ${loai.bieu_tuong}` : 'fa-solid fa-flag',
				lyDo: item.ly_do_tu_choi || '',
				cancelReason: item.ly_do_huy_yeu_cau || item.ly_do_tu_choi || '',
				registrations: item.danh_sach_dang_ky || [],
				feedbacks: item.feedbacks || [],
				reports: item.bao_caos || [],
				history: item.lich_su_kiem_duyet || [],
			};
		},
		async openDetailModal(campaign) {
			if (!campaign?.id) return;
			this.showDetailModal = true;
			this.detailTarget = { ...campaign, feedbacks: [], reports: [], history: [] };
			this.adminMapLat = '';
			this.adminMapLng = '';
			try {
				const res = await api.get(`/kiem-duyet/chien-dich/${campaign.id}`);
				if (res.data.status === 1) {
					this.detailTarget = this.mapCampaignFromApi(res.data.data);
					this.detailTarget.feedbacks = res.data.data.feedbacks || [];
					this.detailTarget.reports = res.data.data.bao_caos || [];
					this.detailTarget.history = res.data.data.lich_su_kiem_duyet || [];
					await this.syncRouteQuery();
					this.$nextTick(() => setTimeout(() => this.geocodeAdminMap(), 300));
				}
			} catch (error) {
				this.showError(error.response?.data?.message || 'Không tải được chi tiết chiến dịch.');
			}
		},
		async closeDetailModal() {
			this.showDetailModal = false;
			this.detailTarget = null;
			this.adminMapLat = '';
			this.adminMapLng = '';
			await this.syncRouteQuery();
		},
		mapRegistrationForModal(item) {
			const volunteer = item?.nguoi_dung || {};
			return {
				id: item?.id,
				name: volunteer.ho_ten || '—',
				email: volunteer.email || '—',
				skills: (volunteer.ky_nangs || []).map((skill) => skill.ten).filter(Boolean),
				area: (volunteer.khu_vucs || []).map((area) => area.ten).filter(Boolean).join(', ') || '—',
				status: item?.trang_thai || '',
				registeredAt: item?.dang_ky_luc || null,
				statusTime: item?.xac_nhan_luc || item?.duyet_luc || item?.huy_luc || item?.dang_ky_luc || null,
				cancelReason: item?.ly_do_huy || item?.ghi_chu || '',
			};
		},
		getRegistrationStatusLabel(status) {
			return this.$t(`campaignRegistration.statuses.${status}`);
		},
		getRegistrationStatusClass(status) {
			return {
				da_dang_ky: 'bg-warning text-dark',
				da_duyet: 'bg-info text-white',
				da_xac_nhan: 'bg-success text-white',
				tu_choi: 'bg-danger text-white',
				dang_tham_gia: 'bg-primary text-white',
				hoan_thanh: 'bg-secondary text-white',
				da_huy: 'bg-light text-muted border',
			}[status] || 'bg-light text-dark border';
		},
		async openVolunteerListModal(campaign) {
			if (!campaign?.id) return;
			this.showVolunteerListModal = true;
			this.volunteerListTarget = campaign;
			this.volunteerRegistrations = [];
			this.volunteerListLoading = true;
			try {
				const res = await api.get(`/kiem-duyet/chien-dich/${campaign.id}`);
				if (res.data.status === 1) {
					const mappedCampaign = this.mapCampaignFromApi(res.data.data);
					this.volunteerListTarget = mappedCampaign;
					this.volunteerRegistrations = (res.data.data.danh_sach_dang_ky || []).map((item) => this.mapRegistrationForModal(item));
				}
			} catch (error) {
				this.showError(error.response?.data?.message || 'Không tải được danh sách TNV đăng ký.');
			} finally {
				this.volunteerListLoading = false;
			}
		},
		closeVolunteerListModal() {
			this.showVolunteerListModal = false;
			this.volunteerListTarget = null;
			this.volunteerRegistrations = [];
			this.volunteerListLoading = false;
		},
		openRejectModal(campaign, mode) {
			this.rejectTarget = campaign;
			this.rejectMode = mode;
			this.rejectReason = '';
			this.showRejectModal = true;
		},
		async confirmReject() {
			if (!this.rejectTarget || !this.rejectReason.trim()) return;
			this.actionLoading = true;
			try {
				const url = this.rejectMode === 'cancel_request'
					? `/kiem-duyet/chien-dich/${this.rejectTarget.id}/yeu-cau-huy/tu-choi`
					: `/kiem-duyet/chien-dich/${this.rejectTarget.id}/tu-choi`;
				const res = await api.put(url, { ly_do: this.rejectReason.trim() });
				if (res.data.status === 1) {
					this.showRejectModal = false;
					this.showSuccess(res.data.message);
					await this.refreshAfterAction(this.rejectTarget.id);
				}
			} catch (error) {
				this.showError(error.response?.data?.message || 'Không thể thực hiện thao tác từ chối.');
			} finally {
				this.actionLoading = false;
			}
		},
		openProcessReportModal(report) {
			this.reportTarget = report;
			this.reportStatus = report.trang_thai === 'moi' ? 'dang_xu_ly' : report.trang_thai;
			this.reportResponse = report.phan_hoi_xu_ly || '';
			this.showReportModal = true;
		},
		async submitReportProcessing() {
			if (!this.reportTarget) return;
			this.actionLoading = true;
			try {
				const res = await api.put(`/kiem-duyet/bao-cao/${this.reportTarget.id}/xu-ly`, {
					trang_thai: this.reportStatus,
					phan_hoi_xu_ly: this.reportResponse,
				});
				if (res.data.status === 1) {
					this.showReportModal = false;
					this.showSuccess(res.data.message);
					if (this.detailTarget) {
						await this.openDetailModal(this.detailTarget);
					}
					await this.loadCampaigns();
				}
			} catch (error) {
				this.showError(error.response?.data?.message || 'Không thể xử lý báo cáo.');
			} finally {
				this.actionLoading = false;
			}
		},
		confirmApprove(c) {
			this.actionTarget = c;
			this.pendingAction = 'approve';
			this.confirmConfig = {
				title: this.$t('admin.campaignManagement.confirm.approveTitle'),
				message: this.$t('admin.campaignManagement.confirm.approveMessage', { title: c.title }),
				detail: this.$t('admin.campaignManagement.confirm.approveDetail'),
				detailList: [],
				detailListTitle: '',
				icon: 'fa-solid fa-check-circle',
				variant: 'success',
				confirmText: this.$t('admin.campaignManagement.confirm.approveBtn'),
				confirmIcon: 'fa-solid fa-check'
			};
			this.$refs.confirmModal.show();
		},
		confirmApproveCancel(c) {
			this.actionTarget = c;
			this.pendingAction = 'approve_cancel';
			const detailList = [this.$t('admin.campaignManagement.confirm.approveCancelDetail')];
			if (c.cancelReason) {
				detailList.push(this.$t('admin.campaignManagement.confirm.cancelReasonDetail', { reason: c.cancelReason }));
			}
			this.confirmConfig = {
				title: this.$t('admin.campaignManagement.confirm.approveCancelTitle'),
				message: this.$t('admin.campaignManagement.confirm.approveCancelMessage', { title: c.title }),
				detail: '',
				detailList,
				detailListTitle: this.$t('admin.campaignManagement.confirm.cancelReasonTitle'),
				icon: 'fa-solid fa-ban',
				variant: 'danger',
				confirmText: this.$t('admin.campaignManagement.confirm.approveCancelBtn'),
				confirmIcon: 'fa-solid fa-ban'
			};
			this.$refs.confirmModal.show();
		},
		async onConfirmAction() {
			if (!this.actionTarget) return;
			this.actionLoading = true;
			try {
				if (this.pendingAction === 'approve') {
					await api.put(`/kiem-duyet/chien-dich/${this.actionTarget.id}/duyet`);
					this.showSuccess(this.$t('admin.campaignManagement.toast.approveSuccessMessage', { title: this.actionTarget.title }));
				} else if (this.pendingAction === 'approve_cancel') {
					await api.put(`/kiem-duyet/chien-dich/${this.actionTarget.id}/yeu-cau-huy/duyet`);
					this.showSuccess(this.$t('admin.campaignManagement.toast.approveCancelSuccessMessage', { title: this.actionTarget.title }));
				}
				this.$refs.confirmModal.hide();
				await this.refreshAfterAction(this.actionTarget.id);
			} catch (error) {
				this.showError(error.response?.data?.message || 'Không thể thực hiện thao tác.');
			} finally {
				this.actionLoading = false;
				this.pendingAction = null;
				this.actionTarget = null;
				this.confirmConfig.detailList = [];
				this.confirmConfig.detailListTitle = '';
			}
		},
		async refreshAfterAction(detailId = null) {
			await this.loadCampaigns();
			if (this.showDetailModal && detailId) {
				const updated = this.campaigns.find(item => item.id === detailId) || { id: detailId };
				await this.openDetailModal(updated);
			}
		},
		getCategoryKey(name) {
			const normalized = (name || '').toLowerCase();
			if (normalized.includes('môi')) return 'environment';
			if (normalized.includes('giáo')) return 'education';
			if (normalized.includes('y tế') || normalized.includes('sức khỏe')) return 'health';
			if (normalized.includes('thiên tai') || normalized.includes('cứu trợ')) return 'disaster';
			return 'community';
		},
		getCategoryClass(cat) {
			return { environment: 'bg-success-subtle text-success', education: 'bg-primary-subtle text-primary', health: 'bg-danger-subtle text-danger', community: 'bg-info-subtle text-info', disaster: 'bg-warning-subtle text-warning' }[cat] || 'bg-secondary';
		},
		getPriorityLabel(priority) {
			return this.$t(`admin.campaignManagement.priorities.${priority}`);
		},
		getTabLabel(tab) {
			return this.$t(`admin.campaignManagement.tabs.${tab}`);
		},
		getTabIcon(tab) {
			return {
				pending: 'fa-solid fa-hourglass-half',
				approved: 'fa-solid fa-circle-check',
				pending_cancel: 'fa-solid fa-ban',
				all: 'fa-solid fa-list',
				active: 'fa-solid fa-circle-play',
				completed: 'fa-solid fa-circle-check',
			}[tab] || 'fa-solid fa-list';
		},
		getTabBadgeClass(tab) {
			return {
				pending: 'bg-warning text-dark',
				approved: 'bg-info text-white',
				pending_cancel: 'bg-danger',
				all: 'bg-primary',
				active: 'bg-success',
				completed: 'bg-secondary',
			}[tab] || 'bg-primary';
		},
		getPriorityClass(priority) {
			return { urgent: 'bg-danger text-white', high: 'bg-warning text-dark', medium: 'bg-info text-white', low: 'bg-light text-muted border' }[priority] || 'bg-secondary';
		},
		getStatusLabel(status) {
			return this.$t(`admin.campaignManagement.statuses.${status}`);
		},
		getStatusClass(status) {
			return {
				pending: 'bg-warning text-dark',
				pending_cancel: 'bg-danger text-white',
				approved: 'bg-info text-white',
				active: 'bg-success text-white',
				completed: 'bg-secondary text-white',
				rejected: 'bg-dark text-white',
				cancelled: 'bg-danger text-white',
				draft: 'bg-light text-dark border',
			}[status] || 'bg-secondary';
		},
		getStatusIcon(status) {
			return {
				pending: 'fa-solid fa-clock',
				pending_cancel: 'fa-solid fa-ban',
				approved: 'fa-solid fa-circle-check',
				active: 'fa-solid fa-circle-play',
				completed: 'fa-solid fa-circle-check',
				rejected: 'fa-solid fa-circle-xmark',
				cancelled: 'fa-solid fa-trash-can',
				draft: 'fa-solid fa-file-lines',
			}[status] || 'fa-solid fa-circle';
		},
		getStatIconStyle(color) {
			return {
				backgroundColor: `${color}1a`,
				color,
			};
		},
		getProgress(campaign) {
			return campaign.maxVolunteers ? Math.round((campaign.registered / campaign.maxVolunteers) * 100) : 0;
		},
		getReportStatusLabel(status) {
			return this.$t(`admin.campaignManagement.reports.statuses.${status}`);
		},
		getReportStatusClass(status) {
			return {
				moi: 'bg-warning text-dark',
				dang_xu_ly: 'bg-info text-white',
				da_xu_ly: 'bg-success text-white',
				tu_choi: 'bg-secondary text-white',
			}[status] || 'bg-light text-dark';
		},
		getHistoryLabel(action) {
			return this.$t(`admin.campaignManagement.history.actions.${action}`);
		},
		pickAvatarColor(seed) {
			const colors = ['#0d6efd', '#198754', '#6f42c1', '#dc3545', '#fd7e14', '#0dcaf0'];
			return colors[seed % colors.length];
		},
		formatDate(value) {
			if (!value) return '—';
			const date = new Date(value);
			return Number.isNaN(date.getTime()) ? value : date.toLocaleDateString('vi-VN');
		},
		formatDateTime(value) {
			if (!value) return '—';
			const date = new Date(value);
			return Number.isNaN(date.getTime()) ? value : `${date.toLocaleDateString('vi-VN')} ${date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}`;
		},
		resetFilters() {
			this.suspendFilterReload = true;
			this.activeTab = 'pending';
			this.searchQuery = '';
			this.filterCategory = '';
			this.filterPriority = '';
			this.$nextTick(() => {
				this.suspendFilterReload = false;
				this.loadCampaigns();
			});
		},
		showSuccess(message) {
			this.toast?.showToast('success', this.$t('admin.campaignManagement.toast.successTitle'), message);
		},
		showError(message) {
			this.toast?.showToast('error', this.$t('admin.campaignManagement.toast.errorTitle'), message);
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
		initAdminMap(lat, lng) {
			this.$nextTick(() => {
				const container = document.getElementById('admin-detail-map');
				if (!container || !window.L) return;
				if (this.adminMap) {
					this.adminMap.remove();
					this.adminMap = null;
				}
				this.adminMap = window.L.map(container, { center: [lat, lng], zoom: 15, zoomControl: true, attributionControl: false, scrollWheelZoom: false });
				window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(this.adminMap);
				const pinIcon = window.L.divIcon({ html: '<div class="custom-pin"><i class="fa-solid fa-location-dot"></i></div>', iconSize: [36, 36], iconAnchor: [18, 36], className: 'custom-pin-wrapper' });
				this.adminMarker = window.L.marker([lat, lng], { draggable: false, icon: pinIcon }).addTo(this.adminMap);
				this.adminMapLat = lat.toFixed(7);
				this.adminMapLng = lng.toFixed(7);
				setTimeout(() => this.adminMap.invalidateSize(), 250);
			});
		},
		async geocodeAdminMap() {
			if (!this.detailTarget) return;
			if (this.detailTarget.latitude && this.detailTarget.longitude) {
				this.initAdminMap(parseFloat(this.detailTarget.latitude), parseFloat(this.detailTarget.longitude));
				return;
			}
			if (!this.detailTarget.location) return;
			try {
				const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(this.detailTarget.location)}&countrycodes=vn&limit=1`;
				const res = await fetch(url, { headers: { 'Accept-Language': 'vi' } });
				const data = await res.json();
				if (data && data.length > 0) {
					this.initAdminMap(parseFloat(data[0].lat), parseFloat(data[0].lon));
				} else {
					this.initAdminMap(16.0544, 108.2022);
				}
			} catch (_error) {
				this.initAdminMap(16.0544, 108.2022);
			}
		},
	}
};
</script>

<style scoped>
.stat-card { transition: transform 0.2s; }
.stat-card:hover { transform: translateY(-2px); }
.stat-icon {
	width: 48px; height: 48px; border-radius: 12px;
	display: flex; align-items: center; justify-content: center;
	font-size: 20px;
}
.campaign-table-icon {
	width: 40px; height: 40px; min-width: 40px; border-radius: 10px;
	display: flex; align-items: center; justify-content: center;
	font-size: 16px;
}
.volunteer-count-btn {
	color: inherit;
	text-decoration: none;
}
.volunteer-count-btn:hover .fw-bold,
.volunteer-count-btn:focus .fw-bold {
	color: #0d6efd !important;
	text-decoration: underline;
}
.coordinator-avatar,
.coordinator-avatar-lg {
	display: flex; align-items: center; justify-content: center;
	color: white; font-weight: 700; border-radius: 50%;
}
.coordinator-avatar { width: 32px; height: 32px; min-width: 32px; font-size: 13px; }
.coordinator-avatar-lg { width: 48px; height: 48px; min-width: 48px; font-size: 20px; }
.detail-info-card {
	display: flex; align-items: flex-start; gap: 12px;
	padding: 14px; background: #f8f9fa; border-radius: 12px;
}
.detail-icon {
	width: 36px; height: 36px; min-width: 36px; border-radius: 10px;
	display: flex; align-items: center; justify-content: center;
	font-size: 14px;
}
.detail-section-card {
	background: #fff;
	border: 1px solid #e9ecef;
	border-radius: 16px;
	padding: 1rem;
}
.cancel-reason-alert {
	background: linear-gradient(135deg, rgba(220, 53, 69, 0.1), rgba(220, 53, 69, 0.04));
}
.feedback-item:last-child { margin-bottom: 0 !important; }
.history-item:last-child { border-bottom: none !important; }
.history-dot {
	width: 10px; height: 10px; min-width: 10px; border-radius: 50%;
	background: #0d6efd; margin-top: 8px;
}
.admin-detail-map-wrapper {
	height: 260px; width: 100%; z-index: 0;
}
.custom-pin-wrapper { background: none !important; border: none !important; }
.custom-pin {
	font-size: 32px; color: #dc3545; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
	animation: pin-bounce 0.6s ease;
}
@keyframes pin-bounce {
	0%, 100% { transform: translateY(0); }
	50% { transform: translateY(-8px); }
}
.admin-tabs .nav-link {
	color: #6c757d; border: none; border-bottom: 3px solid transparent;
	font-weight: 500; font-size: 14px; padding: 10px 16px;
}
.admin-tabs .nav-link.active {
	color: #0d6efd; border-bottom-color: #0d6efd; background: transparent;
}
.admin-tabs .nav-link:hover:not(.active) { border-bottom-color: #dee2e6; }
.min-w-0 { min-width: 0; }
@media (max-width: 767.98px) {
	.campaign-table-icon { width: 32px; height: 32px; font-size: 13px; }
	.coordinator-avatar { width: 28px; height: 28px; font-size: 11px; }
	.admin-detail-map-wrapper { height: 200px; }
}
</style>
