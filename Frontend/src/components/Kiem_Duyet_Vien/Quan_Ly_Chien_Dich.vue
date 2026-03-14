<template>
	<div class="admin-campaigns">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-flag text-primary me-2"></i>{{ $t('admin.campaignManagement.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.campaignManagement.subtitle') }}</p>
			</div>
			<div class="d-flex gap-2">
				<button class="btn btn-outline-success btn-sm rounded-pill px-3" @click="exportReport">
					<i class="fa-solid fa-file-export me-1"></i>{{ $t('admin.campaignManagement.exportReport') }}
				</button>
			</div>
		</div>

		<!-- Stats Cards -->
		<div class="row g-3 mb-4">
			<div class="col-xl-3 col-sm-6" v-for="stat in statsCards" :key="stat.label">
				<div class="card stat-card border-0 shadow-sm h-100">
					<div class="card-body p-3">
						<div class="d-flex align-items-start justify-content-between">
							<div>
								<p class="text-muted small mb-1">{{ stat.label }}</p>
								<h3 class="fw-bold mb-0">{{ stat.value }}</h3>
							</div>
							<div class="stat-icon" :class="stat.bgClass">
								<i :class="stat.icon"></i>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Tab Navigation -->
		<ul class="nav nav-tabs admin-tabs mb-4">
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'pending' }" href="#" @click.prevent="activeTab = 'pending'">
					<i class="fa-solid fa-hourglass-half me-1"></i>{{ $t('admin.campaignManagement.tabs.pending') }}
					<span class="badge bg-warning text-dark ms-1">{{ pendingCampaigns.length }}</span>
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'all' }" href="#" @click.prevent="activeTab = 'all'">
					<i class="fa-solid fa-list me-1"></i>{{ $t('admin.campaignManagement.tabs.all') }}
					<span class="badge bg-primary ms-1">{{ allCampaigns.length }}</span>
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'active' }" href="#" @click.prevent="activeTab = 'active'">
					<i class="fa-solid fa-circle-play me-1"></i>{{ $t('admin.campaignManagement.tabs.active') }}
					<span class="badge bg-success ms-1">{{ activeCampaigns.length }}</span>
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'completed' }" href="#" @click.prevent="activeTab = 'completed'">
					<i class="fa-solid fa-circle-check me-1"></i>{{ $t('admin.campaignManagement.tabs.completed') }}
					<span class="badge bg-secondary ms-1">{{ completedCampaigns.length }}</span>
				</a>
			</li>
		</ul>

		<!-- Filter Bar -->
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
							<option value="environment">{{ $t('admin.campaignManagement.categories.environment') }}</option>
							<option value="education">{{ $t('admin.campaignManagement.categories.education') }}</option>
							<option value="health">{{ $t('admin.campaignManagement.categories.health') }}</option>
							<option value="community">{{ $t('admin.campaignManagement.categories.community') }}</option>
							<option value="disaster">{{ $t('admin.campaignManagement.categories.disaster') }}</option>
						</select>
					</div>
					<div class="col-md-3">
						<select class="form-select" v-model="filterPriority">
							<option value="">{{ $t('admin.campaignManagement.filter.allPriorities') }}</option>
							<option value="urgent">{{ $t('admin.campaignManagement.priorities.urgent') }}</option>
							<option value="high">{{ $t('admin.campaignManagement.priorities.high') }}</option>
							<option value="medium">{{ $t('admin.campaignManagement.priorities.medium') }}</option>
							<option value="low">{{ $t('admin.campaignManagement.priorities.low') }}</option>
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

		<!-- Campaigns Table -->
		<div class="card border-0 shadow-sm">
			<div class="card-body p-0">
				<div class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead class="table-light">
							<tr>
								<th class="ps-4" style="width: 40px;">
									<input class="form-check-input" type="checkbox">
								</th>
								<th>{{ $t('admin.campaignManagement.table.campaign') }}</th>
								<th>{{ $t('admin.campaignManagement.table.coordinator') }}</th>
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
								<td class="ps-4">
									<input class="form-check-input" type="checkbox">
								</td>
								<td>
									<div class="d-flex align-items-center gap-3">
										<div class="campaign-table-icon" :style="{ background: c.color }">
											<i :class="c.icon" class="text-white"></i>
										</div>
										<div class="min-w-0">
											<h6 class="mb-0 small fw-bold text-truncate" style="max-width: 220px;">{{ c.title }}</h6>
											<span class="text-muted d-flex align-items-center gap-1" style="font-size: 11px;">
												<i class="fa-solid fa-location-dot text-danger"></i>{{ c.location.length > 35 ? c.location.substring(0, 35) + '...' : c.location }}
											</span>
										</div>
									</div>
								</td>
								<td>
									<div class="d-flex align-items-center gap-2">
										<div class="coordinator-avatar" :style="{ background: c.coordinatorColor }">{{ c.coordinator.charAt(0) }}</div>
										<div>
											<div class="small fw-semibold">{{ c.coordinator }}</div>
											<div class="text-muted" style="font-size: 11px;">{{ c.coordinatorEmail }}</div>
										</div>
									</div>
								</td>
								<td>
									<span class="badge rounded-pill" :class="getCategoryClass(c.category)">
										<i :class="getCategoryIcon(c.category)" class="me-1"></i>{{ getCategoryLabel(c.category) }}
									</span>
								</td>
								<td class="text-center">
									<span class="badge rounded-pill" :class="getPriorityClass(c.priority)">{{ getPriorityLabel(c.priority) }}</span>
								</td>
								<td class="text-center">
									<div class="d-flex flex-column align-items-center">
										<span class="fw-bold small">{{ c.registered }}/{{ c.maxVolunteers }}</span>
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
										<div><i class="fa-solid fa-play text-success me-1" style="font-size:9px"></i>{{ c.startDate }}</div>
										<div><i class="fa-solid fa-stop text-danger me-1" style="font-size:9px"></i>{{ c.endDate }}</div>
									</div>
								</td>
								<td class="text-center">
									<div class="btn-group">
										<button class="btn btn-sm btn-outline-primary" :title="$t('admin.campaignManagement.actions.view')" @click="openDetailModal(c)">
											<i class="fa-solid fa-eye"></i>
										</button>
										<button v-if="c.status === 'pending'" class="btn btn-sm btn-outline-success" :title="$t('admin.campaignManagement.actions.approve')" @click="confirmApprove(c)">
											<i class="fa-solid fa-check"></i>
										</button>
										<button v-if="c.status === 'pending'" class="btn btn-sm btn-outline-danger" :title="$t('admin.campaignManagement.actions.reject')" @click="openRejectModal(c)">
											<i class="fa-solid fa-xmark"></i>
										</button>
										<button v-if="c.status === 'active'" class="btn btn-sm btn-outline-warning" :title="$t('admin.campaignManagement.actions.suspend')" @click="confirmSuspend(c)">
											<i class="fa-solid fa-pause"></i>
										</button>
									</div>
								</td>
							</tr>
						</tbody>
					</table>
				</div>

				<!-- Empty State -->
				<div class="text-center py-5" v-if="filteredCampaigns.length === 0">
					<i class="fa-solid fa-flag text-muted" style="font-size: 48px;"></i>
					<p class="text-muted mt-3">{{ $t('admin.campaignManagement.emptyState') }}</p>
				</div>
			</div>

			<!-- Pagination -->
			<div class="card-footer bg-white border-top py-3" v-if="filteredCampaigns.length > 0">
				<div class="d-flex align-items-center justify-content-between">
					<span class="text-muted small" v-html="$t('admin.campaignManagement.pagination.showing', { count: `<strong>${filteredCampaigns.length}</strong>` })"></span>
					<nav>
						<ul class="pagination pagination-sm mb-0">
							<li class="page-item disabled"><a class="page-link" href="#">«</a></li>
							<li class="page-item active"><a class="page-link" href="#">1</a></li>
							<li class="page-item"><a class="page-link" href="#">2</a></li>
							<li class="page-item"><a class="page-link" href="#">»</a></li>
						</ul>
					</nav>
				</div>
			</div>
		</div>

		<!-- ===== Detail Modal ===== -->
		<div class="modal fade" :class="{ show: showDetailModal }" :style="showDetailModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
				<div class="modal-content border-0 shadow" v-if="detailTarget">
					<!-- Modal Header -->
					<div class="modal-header border-0" :style="{ background: detailTarget.color }">
						<div class="d-flex align-items-center gap-3">
							<div class="rounded-3 d-flex align-items-center justify-content-center" style="width:48px;height:48px; background-color: rgba(255,255,255,0.2);">
								<i :class="detailTarget.icon" class="text-white fs-5"></i>
							</div>
							<div class="text-white">
								<h5 class="fw-bold mb-0">{{ detailTarget.title }}</h5>
								<span class="small opacity-75">{{ getCategoryLabel(detailTarget.category) }}</span>
							</div>
						</div>
						<button type="button" class="btn-close btn-close-white" @click="showDetailModal = false"></button>
					</div>
					<!-- Modal Body -->
					<div class="modal-body p-4">
						<!-- Info Grid -->
						<div class="row g-3 mb-4">
							<div class="col-sm-6">
								<div class="detail-info-card">
									<div class="detail-icon bg-danger text-white"><i class="fa-solid fa-location-dot"></i></div>
									<div>
										<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.location') }}</div>
										<div class="fw-semibold small">{{ detailTarget.location }}</div>
									</div>
								</div>
							</div>
							<div class="col-sm-6">
								<div class="detail-info-card">
									<div class="detail-icon bg-primary text-white"><i class="fa-solid fa-calendar-days"></i></div>
									<div>
										<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.time') }}</div>
										<div class="fw-semibold small">{{ detailTarget.startDate }} — {{ detailTarget.endDate }}</div>
									</div>
								</div>
							</div>
							<div class="col-sm-6">
								<div class="detail-info-card">
									<div class="detail-icon bg-success text-white"><i class="fa-solid fa-users"></i></div>
									<div>
										<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.volunteersNeeded') }}</div>
										<div class="fw-semibold small">{{ detailTarget.maxVolunteers }} {{ $t('admin.campaignManagement.detailModal.people') }} ({{ detailTarget.registered }} {{ $t('admin.campaignManagement.detailModal.registered') }})</div>
									</div>
								</div>
							</div>
							<div class="col-sm-6">
								<div class="detail-info-card">
									<div class="detail-icon bg-warning text-dark"><i class="fa-solid fa-bolt"></i></div>
									<div>
										<div class="small text-muted">{{ $t('admin.campaignManagement.detailModal.priority') }}</div>
										<div class="fw-semibold small">
											<span class="badge rounded-pill" :class="getPriorityClass(detailTarget.priority)">{{ getPriorityLabel(detailTarget.priority) }}</span>
										</div>
									</div>
								</div>
							</div>
						</div>

						<!-- Coordinator -->
						<div class="d-flex align-items-center gap-3 mb-4 p-3 bg-light rounded-3">
							<div class="coordinator-avatar-lg" :style="{ background: detailTarget.coordinatorColor }">{{ detailTarget.coordinator.charAt(0) }}</div>
							<div>
								<div class="fw-bold">{{ detailTarget.coordinator }}</div>
								<div class="text-muted small">{{ detailTarget.coordinatorEmail }}</div>
							</div>
							<span class="badge bg-info ms-auto">{{ $t('admin.campaignManagement.detailModal.coordinatorLabel') }}</span>
						</div>

						<!-- Description -->
						<div class="mb-4">
							<h6 class="fw-bold small mb-2"><i class="fa-solid fa-file-lines text-primary me-2"></i>{{ $t('admin.campaignManagement.detailModal.description') }}</h6>
							<p class="text-muted small mb-0 lh-lg">{{ detailTarget.description }}</p>
						</div>

						<!-- Skills -->
						<div class="mb-4">
							<h6 class="fw-bold small mb-2"><i class="fa-solid fa-gears text-primary me-2"></i>{{ $t('admin.campaignManagement.detailModal.skills') }}</h6>
							<div class="d-flex flex-wrap gap-2">
								<span v-for="skill in detailTarget.skills" :key="skill"
									class="badge bg-white text-primary border border-primary px-3 py-2" style="font-size:12px">
									{{ skill }}
								</span>
							</div>
						</div>

						<!-- Map -->
						<div class="mb-3" v-if="detailTarget.location">
							<h6 class="fw-bold small mb-2"><i class="fa-solid fa-map-location-dot text-danger me-2"></i>{{ $t('admin.campaignManagement.detailModal.map') }}</h6>
							<div id="admin-detail-map" class="admin-detail-map-wrapper rounded-3 border"></div>
							<div class="d-flex gap-2 mt-2" v-if="adminMapLat">
								<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ $t('admin.campaignManagement.detailModal.lat') }}: {{ adminMapLat }}</span>
								<span class="badge bg-light text-muted border px-3 py-2"><i class="fa-solid fa-crosshairs me-1"></i>{{ $t('admin.campaignManagement.detailModal.lng') }}: {{ adminMapLng }}</span>
							</div>
						</div>
					</div>

					<!-- Modal Footer -->
					<div class="modal-footer border-0 bg-light py-3" v-if="detailTarget.status === 'pending'">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showDetailModal = false">{{ $t('admin.campaignManagement.detailModal.close') }}</button>
						<button type="button" class="btn btn-danger rounded-pill px-4" @click="showDetailModal = false; openRejectModal(detailTarget)">
							<i class="fa-solid fa-xmark me-1"></i>{{ $t('admin.campaignManagement.detailModal.reject') }}
						</button>
						<button type="button" class="btn btn-success rounded-pill px-4" @click="approveFromDetail">
							<i class="fa-solid fa-check me-1"></i>{{ $t('admin.campaignManagement.detailModal.approve') }}
						</button>
					</div>
					<div class="modal-footer border-0 py-3" v-else>
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showDetailModal = false">{{ $t('admin.campaignManagement.detailModal.close') }}</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showDetailModal" @click="showDetailModal = false"></div>

		<!-- ===== Reject Modal ===== -->
		<div class="modal fade" :class="{ show: showRejectModal }" :style="showRejectModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-ban text-danger me-2"></i>{{ $t('admin.campaignManagement.rejectModal.title') }}</h5>
						<button type="button" class="btn-close" @click="showRejectModal = false"></button>
					</div>
					<div class="modal-body" v-if="rejectTarget">
						<div class="bg-light rounded-3 p-3 mb-3">
							<div class="fw-bold">{{ rejectTarget.title }}</div>
							<div class="text-muted small">{{ $t('admin.campaignManagement.rejectModal.by') }}: {{ rejectTarget.coordinator }}</div>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('admin.campaignManagement.rejectModal.reason') }} <span class="text-danger">*</span></label>
							<textarea class="form-control" rows="4" :placeholder="$t('admin.campaignManagement.rejectModal.reasonPlaceholder')" v-model="rejectReason"></textarea>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showRejectModal = false">{{ $t('admin.campaignManagement.rejectModal.cancel') }}</button>
						<button type="button" class="btn btn-danger rounded-pill px-4" @click="confirmReject" :disabled="!rejectReason.trim()">
							<i class="fa-solid fa-ban me-1"></i>{{ $t('admin.campaignManagement.rejectModal.confirm') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showRejectModal" @click="showRejectModal = false"></div>

		<!-- Confirm Modal (reusable) -->
		<ConfirmModal ref="confirmModal" :modalId="'campaignConfirmModal'"
			:title="confirmConfig.title" :message="confirmConfig.message" :detail="confirmConfig.detail"
			:icon="confirmConfig.icon" :variant="confirmConfig.variant"
			:confirmText="confirmConfig.confirmText" :confirmIcon="confirmConfig.confirmIcon"
			@confirm="onConfirmAction" />
	</div>
</template>

<script>
import ConfirmModal from '../../components/ConfirmModal.vue';

export default {
	name: 'AdminQuanLyChienDich',
	components: { ConfirmModal },
	props: {
		toast: { type: Object, default: null }
	},
	data() {
		return {
			activeTab: 'pending',
			searchQuery: '',
			filterCategory: '',
			filterPriority: '',
			showDetailModal: false,
			showRejectModal: false,
			detailTarget: null,
			rejectTarget: null,
			rejectReason: '',
			confirmConfig: { title: '', message: '', detail: '', icon: '', variant: '', confirmText: '', confirmIcon: '' },
			pendingAction: null,
			actionTarget: null,
			adminMap: null,
			adminMarker: null,
			adminMapLat: '',
			adminMapLng: '',
			campaigns: [
				{
					id: 1, title: 'Trồng cây xanh Tây Nguyên', description: 'Chiến dịch trồng 5000 cây xanh tại các khu vực đồi trọc ở Tây Nguyên nhằm phục hồi rừng và chống biến đổi khí hậu. Tình nguyện viên sẽ tham gia trồng cây, chăm sóc cây con và giáo dục cộng đồng địa phương về bảo vệ môi trường.',
					category: 'environment', priority: 'high', status: 'pending',
					location: 'Buôn Ma Thuột, Đắk Lắk', startDate: '15/04/2026', endDate: '20/04/2026',
					maxVolunteers: 80, registered: 0,
					coordinator: 'Nguyễn Văn An', coordinatorEmail: 'an.nv@vms-ai.vn', coordinatorColor: '#0d6efd',
					skills: ['Chăm sóc cây', 'Làm việc nhóm', 'Chịu nắng', 'Đi bộ đường dài'],
					icon: 'fa-solid fa-tree', color: 'linear-gradient(135deg, #198754, #20c997)',
					submittedDate: '01/03/2026'
				},
				{
					id: 2, title: 'Dạy học miễn phí cho trẻ em vùng cao', description: 'Tổ chức các lớp học miễn phí cho trẻ em vùng cao tại Sa Pa bao gồm: Tiếng Anh cơ bản, Toán, Kỹ năng sống. Mỗi tình nguyện viên sẽ phụ trách 1 lớp học trong suốt thời gian chiến dịch.',
					category: 'education', priority: 'medium', status: 'pending',
					location: 'Ngũ Chỉ Sơn, Sa Pa, Lào Cai', startDate: '01/05/2026', endDate: '15/05/2026',
					maxVolunteers: 30, registered: 0,
					coordinator: 'Trần Thị Mai', coordinatorEmail: 'mai.tt@vms-ai.vn', coordinatorColor: '#6f42c1',
					skills: ['Sư phạm', 'Tiếng Anh', 'Kiên nhẫn', 'Giao tiếp'],
					icon: 'fa-solid fa-graduation-cap', color: 'linear-gradient(135deg, #0d6efd, #6610f2)',
					submittedDate: '05/03/2026'
				},
				{
					id: 3, title: 'Khám bệnh miễn phí cộng đồng', description: 'Chiến dịch khám bệnh tổng quát miễn phí cho bà con vùng sâu vùng xa tại Quảng Nam. Cần các TNV có chuyên môn y tế và hỗ trợ hậu cần.',
					category: 'health', priority: 'urgent', status: 'pending',
					location: 'Đại Lộc, Quảng Nam', startDate: '10/04/2026', endDate: '12/04/2026',
					maxVolunteers: 50, registered: 0,
					coordinator: 'Lê Hoàng Dũng', coordinatorEmail: 'dung.lh@vms-ai.vn', coordinatorColor: '#dc3545',
					skills: ['Y tế cơ bản', 'Sơ cứu', 'Hậu cần', 'Giao tiếp'],
					icon: 'fa-solid fa-heart-pulse', color: 'linear-gradient(135deg, #dc3545, #fd7e14)',
					submittedDate: '06/03/2026'
				},
				{
					id: 4, title: 'Mùa hè xanh 2026', description: 'Hoạt động tình nguyện mùa hè hàng năm với nhiều nội dung: tu sửa trường học, xây dựng sân chơi cho trẻ em, giáo dục vệ sinh.',
					category: 'community', priority: 'high', status: 'active',
					location: 'Tân Phú, TP.HCM', startDate: '01/06/2026', endDate: '30/06/2026',
					maxVolunteers: 120, registered: 95,
					coordinator: 'Phạm Minh Tuấn', coordinatorEmail: 'tuan.pm@vms-ai.vn', coordinatorColor: '#198754',
					skills: ['Xây dựng', 'Sơn vẽ', 'Tổ chức sự kiện'],
					icon: 'fa-solid fa-sun', color: 'linear-gradient(135deg, #fd7e14, #ffc107)',
					submittedDate: '15/01/2026', approvedDate: '20/01/2026'
				},
				{
					id: 5, title: 'Cứu trợ lũ lụt miền Trung', description: 'Hỗ trợ cứu trợ và tái thiết sau bão lụt tại các tỉnh miền Trung Việt Nam.',
					category: 'disaster', priority: 'urgent', status: 'active',
					location: 'Hương Khê, Hà Tĩnh', startDate: '01/03/2026', endDate: '15/03/2026',
					maxVolunteers: 200, registered: 180,
					coordinator: 'Nguyễn Văn An', coordinatorEmail: 'an.nv@vms-ai.vn', coordinatorColor: '#0d6efd',
					skills: ['Cứu hộ', 'Sơ cứu', 'Lái xe', 'Hậu cần'],
					icon: 'fa-solid fa-house-flood-water', color: 'linear-gradient(135deg, #0dcaf0, #0d6efd)',
					submittedDate: '20/02/2026', approvedDate: '21/02/2026'
				},
				{
					id: 6, title: 'Chiến dịch Xuân yêu thương 2026', description: 'Trao quà Tết cho các hộ gia đình khó khăn.',
					category: 'community', priority: 'medium', status: 'completed',
					location: 'Quận 8, TP.HCM', startDate: '10/01/2026', endDate: '25/01/2026',
					maxVolunteers: 60, registered: 60,
					coordinator: 'Trần Thị Mai', coordinatorEmail: 'mai.tt@vms-ai.vn', coordinatorColor: '#6f42c1',
					skills: ['Giao tiếp', 'Hậu cần'],
					icon: 'fa-solid fa-gift', color: 'linear-gradient(135deg, #e83e8c, #6f42c1)',
					submittedDate: '01/12/2025', approvedDate: '05/12/2025'
				},
				{
					id: 7, title: 'Chiến dịch dọn rác bãi biển', description: 'Thu gom rác thải nhựa tại các bãi biển Đà Nẵng.',
					category: 'environment', priority: 'low', status: 'cancelled',
					location: 'Mỹ Khê, Đà Nẵng', startDate: '20/02/2026', endDate: '22/02/2026',
					maxVolunteers: 40, registered: 8,
					coordinator: 'Lê Hoàng Dũng', coordinatorEmail: 'dung.lh@vms-ai.vn', coordinatorColor: '#dc3545',
					skills: ['Làm việc nhóm'],
					icon: 'fa-solid fa-water', color: 'linear-gradient(135deg, #17a2b8, #20c997)',
					submittedDate: '01/02/2026', approvedDate: '03/02/2026'
				}
			]
		}
	},
	computed: {
		allCampaigns() { return this.campaigns; },
		pendingCampaigns() { return this.campaigns.filter(c => c.status === 'pending'); },
		activeCampaigns() { return this.campaigns.filter(c => c.status === 'active'); },
		completedCampaigns() { return this.campaigns.filter(c => c.status === 'completed'); },
		statsCards() {
			return [
				{ label: this.$t('admin.campaignManagement.stats.total'), value: this.campaigns.length, icon: 'fa-solid fa-flag', bgClass: 'bg-primary bg-opacity-10 text-primary' },
				{ label: this.$t('admin.campaignManagement.stats.pending'), value: this.pendingCampaigns.length, icon: 'fa-solid fa-hourglass-half', bgClass: 'bg-warning bg-opacity-10 text-warning' },
				{ label: this.$t('admin.campaignManagement.stats.active'), value: this.activeCampaigns.length, icon: 'fa-solid fa-circle-play', bgClass: 'bg-success bg-opacity-10 text-success' },
				{ label: this.$t('admin.campaignManagement.stats.completed'), value: this.completedCampaigns.length, icon: 'fa-solid fa-circle-check', bgClass: 'bg-secondary bg-opacity-10 text-secondary' }
			];
		},
		filteredCampaigns() {
			let list = [];
			if (this.activeTab === 'pending') list = this.pendingCampaigns;
			else if (this.activeTab === 'active') list = this.activeCampaigns;
			else if (this.activeTab === 'completed') list = this.completedCampaigns;
			else list = this.allCampaigns;

			if (this.searchQuery) {
				const q = this.searchQuery.toLowerCase();
				list = list.filter(c => c.title.toLowerCase().includes(q) || c.location.toLowerCase().includes(q) || c.coordinator.toLowerCase().includes(q));
			}
			if (this.filterCategory) list = list.filter(c => c.category === this.filterCategory);
			if (this.filterPriority) list = list.filter(c => c.priority === this.filterPriority);
			return list;
		}
	},
	mounted() {
		// Load Leaflet
		if (!document.getElementById('leaflet-css')) {
			const link = document.createElement('link');
			link.id = 'leaflet-css'; link.rel = 'stylesheet';
			link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
			document.head.appendChild(link);
		}
		if (!window.L) {
			const script = document.createElement('script');
			script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
			document.head.appendChild(script);
		}
	},
	beforeUnmount() {
		if (this.adminMap) { this.adminMap.remove(); this.adminMap = null; }
	},
	methods: {
		// === Helpers ===
		getCategoryLabel(cat) { return { environment: this.$t('admin.campaignManagement.categories.environment'), education: this.$t('admin.campaignManagement.categories.education'), health: this.$t('admin.campaignManagement.categories.health'), community: this.$t('admin.campaignManagement.categories.community'), disaster: this.$t('admin.campaignManagement.categories.disaster') }[cat] || cat; },
		getCategoryIcon(cat) { return { environment: 'fa-solid fa-leaf', education: 'fa-solid fa-graduation-cap', health: 'fa-solid fa-heart-pulse', community: 'fa-solid fa-people-group', disaster: 'fa-solid fa-house-flood-water' }[cat] || ''; },
		getCategoryClass(cat) { return { environment: 'bg-success-subtle text-success', education: 'bg-primary-subtle text-primary', health: 'bg-danger-subtle text-danger', community: 'bg-info-subtle text-info', disaster: 'bg-warning-subtle text-warning' }[cat] || 'bg-secondary'; },
		getPriorityLabel(p) { return { urgent: this.$t('admin.campaignManagement.priorities.urgent'), high: this.$t('admin.campaignManagement.priorities.high'), medium: this.$t('admin.campaignManagement.priorities.medium'), low: this.$t('admin.campaignManagement.priorities.low') }[p] || p; },
		getPriorityClass(p) { return { urgent: 'bg-danger text-white', high: 'bg-warning text-dark', medium: 'bg-info text-white', low: 'bg-light text-muted border' }[p] || 'bg-secondary'; },
		getStatusLabel(s) { return { pending: this.$t('admin.campaignManagement.statuses.pending'), active: this.$t('admin.campaignManagement.statuses.active'), completed: this.$t('admin.campaignManagement.statuses.completed'), cancelled: this.$t('admin.campaignManagement.statuses.cancelled') }[s] || s; },
		getStatusClass(s) { return { pending: 'bg-warning text-dark', active: 'bg-success text-white', completed: 'bg-secondary text-white', cancelled: 'bg-danger text-white' }[s] || 'bg-secondary'; },
		getStatusIcon(s) { return { pending: 'fa-solid fa-clock', active: 'fa-solid fa-circle-play', completed: 'fa-solid fa-circle-check', cancelled: 'fa-solid fa-ban' }[s] || ''; },
		getProgress(c) { return c.maxVolunteers ? Math.round(c.registered / c.maxVolunteers * 100) : 0; },
		resetFilters() { this.searchQuery = ''; this.filterCategory = ''; this.filterPriority = ''; },

		// === Detail Modal ===
		openDetailModal(c) {
			this.detailTarget = c;
			this.showDetailModal = true;
			this.adminMapLat = '';
			this.adminMapLng = '';
			this.$nextTick(() => { setTimeout(() => this.geocodeAdminMap(), 300); });
		},

		// === Map ===
		initAdminMap(lat, lng) {
			this.$nextTick(() => {
				const container = document.getElementById('admin-detail-map');
				if (!container || !window.L) return;
				if (this.adminMap) { this.adminMap.remove(); this.adminMap = null; }

				this.adminMap = window.L.map(container, {
					center: [lat, lng], zoom: 15, zoomControl: true,
					attributionControl: false, scrollWheelZoom: false
				});
				window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(this.adminMap);

				const pinIcon = window.L.divIcon({
					html: '<div class="custom-pin"><i class="fa-solid fa-location-dot"></i></div>',
					iconSize: [36, 36], iconAnchor: [18, 36], className: 'custom-pin-wrapper'
				});
				this.adminMarker = window.L.marker([lat, lng], { draggable: false, icon: pinIcon }).addTo(this.adminMap);
				this.adminMapLat = lat.toFixed(7);
				this.adminMapLng = lng.toFixed(7);
				setTimeout(() => { this.adminMap.invalidateSize(); }, 300);
			});
		},
		async geocodeAdminMap() {
			if (!this.detailTarget) return;

			// Ưu tiên tọa độ đã lưu sẵn
			if (this.detailTarget.latitude && this.detailTarget.longitude) {
				this.initAdminMap(parseFloat(this.detailTarget.latitude), parseFloat(this.detailTarget.longitude));
				return;
			}
			if (!this.detailTarget.location) return;
			try {
				let address = this.detailTarget.location;
				address = address.replace(/^[A-Z0-9]{4,8}\+[A-Z0-9]{2,}\s*,?\s*/g, '');

				let query = encodeURIComponent(address);
				let url = `https://nominatim.openstreetmap.org/search?format=json&q=${query}&countrycodes=vn&limit=1`;
				let res = await fetch(url, { headers: { 'Accept-Language': 'vi' } });
				let data = await res.json();

				if ((!data || data.length === 0) && address.includes(',')) {
					const fallback = address.substring(address.indexOf(',') + 1).trim();
					res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(fallback)}&countrycodes=vn&limit=1`, { headers: { 'Accept-Language': 'vi' } });
					data = await res.json();
				}

				if (data && data.length > 0) {
					this.initAdminMap(parseFloat(data[0].lat), parseFloat(data[0].lon));
				} else {
					this.initAdminMap(16.0544, 108.2022);
				}
			} catch {
				this.initAdminMap(16.0544, 108.2022);
			}
		},

		// === Actions ===
		confirmApprove(c) {
			this.actionTarget = c;
			this.pendingAction = 'approve';
			this.confirmConfig = {
				title: this.$t('admin.campaignManagement.confirm.approveTitle'),
				message: this.$t('admin.campaignManagement.confirm.approveMessage', { title: c.title }),
				detail: this.$t('admin.campaignManagement.confirm.approveDetail'),
				icon: 'fa-solid fa-check-circle',
				variant: 'success',
				confirmText: this.$t('admin.campaignManagement.confirm.approveBtn'),
				confirmIcon: 'fa-solid fa-check'
			};
			this.$refs.confirmModal.show();
		},
		approveFromDetail() {
			if (this.detailTarget) {
				this.showDetailModal = false;
				this.confirmApprove(this.detailTarget);
			}
		},
		openRejectModal(c) {
			this.rejectTarget = c;
			this.rejectReason = '';
			this.showRejectModal = true;
		},
		confirmReject() {
			if (this.rejectTarget) {
				this.rejectTarget.status = 'cancelled';
				this.showRejectModal = false;
				if (this.toast) this.toast.show('success', this.$t('admin.campaignManagement.toast.rejectedTitle'), this.$t('admin.campaignManagement.toast.rejectedMessage'));
			}
		},
		confirmSuspend(c) {
			this.actionTarget = c;
			this.pendingAction = 'suspend';
			this.confirmConfig = {
				title: this.$t('admin.campaignManagement.confirm.suspendTitle'),
				message: this.$t('admin.campaignManagement.confirm.suspendMessage', { title: c.title }),
				detail: this.$t('admin.campaignManagement.confirm.suspendDetail'),
				icon: 'fa-solid fa-pause-circle',
				variant: 'warning',
				confirmText: this.$t('admin.campaignManagement.confirm.suspendBtn'),
				confirmIcon: 'fa-solid fa-pause'
			};
			this.$refs.confirmModal.show();
		},
		onConfirmAction() {
			if (!this.actionTarget) return;

			if (this.pendingAction === 'approve') {
				this.actionTarget.status = 'active';
				this.actionTarget.approvedDate = new Date().toLocaleDateString('vi-VN');
				if (this.toast) this.toast.show('success', this.$t('admin.campaignManagement.toast.success'), this.$t('admin.campaignManagement.toast.approveMessage', { title: this.actionTarget.title }));
			} else if (this.pendingAction === 'suspend') {
				this.actionTarget.status = 'cancelled';
				if (this.toast) this.toast.show('success', this.$t('admin.campaignManagement.toast.success'), this.$t('admin.campaignManagement.toast.suspendMessage', { title: this.actionTarget.title }));
			}

			this.actionTarget = null;
			this.pendingAction = null;
		},
		exportReport() {
			alert('Tính năng xuất báo cáo sẽ được kết nối API sau.');
		}
	}
}
</script>

<style scoped>
/* Stats Card */
.stat-card { transition: transform 0.2s; }
.stat-card:hover { transform: translateY(-2px); }
.stat-icon {
	width: 48px; height: 48px; border-radius: 12px;
	display: flex; align-items: center; justify-content: center;
	font-size: 20px;
}

/* Campaign Icon */
.campaign-table-icon {
	width: 40px; height: 40px; min-width: 40px; border-radius: 10px;
	display: flex; align-items: center; justify-content: center;
	font-size: 16px;
}

/* Coordinator Avatar */
.coordinator-avatar {
	width: 32px; height: 32px; min-width: 32px; border-radius: 50%;
	display: flex; align-items: center; justify-content: center;
	color: white; font-weight: 700; font-size: 13px;
}

.coordinator-avatar-lg {
	width: 48px; height: 48px; min-width: 48px; border-radius: 50%;
	display: flex; align-items: center; justify-content: center;
	color: white; font-weight: 700; font-size: 20px;
}

/* Detail Info Cards */
.detail-info-card {
	display: flex; align-items: flex-start; gap: 12px;
	padding: 14px; background: #f8f9fa; border-radius: 12px;
}
.detail-icon {
	width: 36px; height: 36px; min-width: 36px; border-radius: 10px;
	display: flex; align-items: center; justify-content: center;
	font-size: 14px;
}

/* Map */
.admin-detail-map-wrapper {
	height: 260px; width: 100%; z-index: 0;
}

/* Custom Pin */
.custom-pin-wrapper { background: none !important; border: none !important; }
.custom-pin {
	font-size: 32px; color: #dc3545; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
	animation: pin-bounce 0.6s ease;
}
@keyframes pin-bounce {
	0%, 100% { transform: translateY(0); }
	50% { transform: translateY(-8px); }
}

/* Tabs */
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
