<template>
	<div>
		<PageHeader
			:title="$t('coordinator.monitoringReport')"
			icon="fa-solid fa-chart-line"
			:breadcrumbs="[
				{ label: $t('common.home'), to: '/' },
				{ label: $t('coordinator.campaignManagement'), to: '/quan-ly-chien-dich' },
				{ label: $t('coordinator.monitoringReport') },
			]"
		/>

		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body py-3">
				<div class="row g-3 align-items-end">
					<div class="col-lg-5">
						<label class="form-label fw-semibold small mb-1">
							<i class="fa-solid fa-flag text-primary me-1"></i>Chọn chiến dịch cần theo dõi
						</label>
						<select class="form-select" v-model="selectedCampaignId" @change="loadMonitoringData">
							<option value="">Chọn chiến dịch</option>
							<option v-for="campaign in campaigns" :key="campaign.id" :value="campaign.id">
								{{ campaign.name }}
							</option>
						</select>
					</div>
					<div class="col-lg-5" v-if="activeCampaign">
						<div class="campaign-summary-strip">
							<div>
								<div class="summary-label">Trạng thái</div>
								<span class="badge rounded-pill" :class="getCampaignStatusClass(activeCampaign.status)">
									{{ getCampaignStatusLabel(activeCampaign.status) }}
								</span>
							</div>
							<div>
								<div class="summary-label">Thời gian</div>
								<div class="summary-value">{{ activeCampaign.timeRange }}</div>
							</div>
							<div>
								<div class="summary-label">Địa điểm</div>
								<div class="summary-value text-truncate">{{ activeCampaign.location }}</div>
							</div>
						</div>
					</div>
					<div class="col-lg-2 text-lg-end">
						<button class="btn btn-outline-primary w-100" @click="refreshCurrentCampaign" :disabled="!selectedCampaignId || isLoadingDetail">
							<i :class="isLoadingDetail ? 'fa-solid fa-spinner fa-spin' : 'fa-solid fa-rotate-right'" class="me-1"></i>Làm mới
						</button>
					</div>
				</div>
			</div>
		</div>

		<div v-if="activeCampaign">
			<StatCards :cards="statsCards" />

			<div class="card border-0 shadow-sm mb-4">
				<div class="card-body py-0">
					<ul class="nav nav-tabs nav-tabs-clean border-0">
						<li class="nav-item" v-for="tab in tabs" :key="tab.value">
							<button
								type="button"
								class="nav-link"
								:class="{ active: activeTab === tab.value }"
								@click="activeTab = tab.value"
							>
								<i :class="tab.icon" class="me-2"></i>{{ tab.label }}
							</button>
						</li>
					</ul>
				</div>
			</div>

			<div v-if="activeTab === 'participants'" class="card border-0 shadow-sm mb-4">
				<div class="card-header bg-white border-0 pb-0">
					<div class="row g-3 align-items-center">
						<div class="col-lg-4">
							<div class="input-group">
								<span class="input-group-text bg-light border-end-0">
									<i class="fa-solid fa-search text-muted small"></i>
								</span>
								<input
									v-model.trim="participantSearch"
									type="text"
									class="form-control bg-light border-start-0"
									placeholder="Tìm theo tên hoặc email TNV"
								>
							</div>
						</div>
						<div class="col-lg-3">
							<select class="form-select bg-light" v-model="participantStatusFilter">
								<option value="">Tất cả trạng thái</option>
								<option value="da_dang_ky">Chờ TNV xác nhận</option>
								<option value="da_xac_nhan">Đã xác nhận, chờ duyệt</option>
								<option value="da_duyet">Đã duyệt</option>
								<option value="dang_tham_gia">Đang tham gia</option>
								<option value="hoan_thanh">Hoàn thành</option>
								<option value="tu_choi">Từ chối</option>
								<option value="da_huy">Đã hủy</option>
							</select>
						</div>
						<div class="col-lg-5 text-muted small text-lg-end">
							Hiển thị {{ filteredParticipants.length }}/{{ participants.length }} bản ghi tham gia
						</div>
					</div>
				</div>
				<div class="card-body pt-3">
					<div v-if="filteredParticipants.length" class="table-responsive">
						<table class="table align-middle mb-0">
							<thead>
								<tr>
									<th>Tình nguyện viên</th>
									<th>Trạng thái</th>
									<th>Đăng ký</th>
									<th>Xác nhận</th>
									<th>Ghi chú</th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="participant in filteredParticipants" :key="participant.id">
									<td>
										<div class="d-flex align-items-center gap-3">
											<div class="participant-avatar bg-primary-subtle text-primary">
												<img
													v-if="participant.avatar"
													:src="participant.avatar"
													:alt="participant.name"
													class="participant-avatar-image"
												>
												<span v-else>{{ getInitials(participant.name) }}</span>
											</div>
											<div class="min-w-0">
												<div class="fw-semibold text-dark text-truncate">{{ participant.name }}</div>
												<div class="text-muted small text-truncate">{{ participant.email }}</div>
											</div>
										</div>
									</td>
									<td>
										<span class="badge rounded-pill" :class="getParticipationStatusClass(participant.status)">
											{{ getParticipationStatusLabel(participant.status) }}
										</span>
									</td>
									<td class="text-muted small">{{ formatDateTime(participant.registeredAt) }}</td>
									<td class="text-muted small">{{ formatDateTime(participant.confirmedAt) }}</td>
									<td class="text-muted small">{{ participant.note || '—' }}</td>
								</tr>
							</tbody>
						</table>
					</div>
					<div v-else class="empty-state py-5">
						<i class="fa-solid fa-users-slash d-block mb-3"></i>
						<p class="mb-0">Chưa có dữ liệu tình nguyện viên phù hợp với bộ lọc.</p>
					</div>
				</div>
			</div>

			<div v-if="activeTab === 'feedback'" class="card border-0 shadow-sm mb-4">
				<div class="card-header bg-white border-0 pb-0">
					<div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
						<div>
							<h6 class="fw-bold mb-1">Phản hồi từ tình nguyện viên</h6>
							<p class="text-muted small mb-0">Theo dõi đánh giá và nhận xét sau chiến dịch.</p>
						</div>
						<div class="text-muted small">Tổng {{ feedbacks.length }} phản hồi</div>
					</div>
				</div>
				<div class="card-body pt-3">
					<div v-if="feedbacks.length" class="feedback-list">
						<div v-for="feedback in feedbacks" :key="feedback.id" class="feedback-card">
							<div class="d-flex justify-content-between align-items-start gap-3 mb-2">
								<div>
									<div class="fw-semibold">{{ feedback.author }}</div>
									<div class="text-muted small">{{ feedback.email }}</div>
								</div>
								<div class="text-end">
									<div class="d-flex justify-content-end gap-1 mb-1">
										<i
											v-for="star in 5"
											:key="star"
											class="fa-solid fa-star small"
											:class="star <= feedback.rating ? 'text-warning' : 'text-muted opacity-25'"
										></i>
									</div>
									<div class="text-muted small">{{ formatDateTime(feedback.createdAt) }}</div>
								</div>
							</div>
							<p class="mb-2 text-dark">{{ feedback.comment || 'Không có nhận xét chi tiết.' }}</p>
							<div v-if="feedback.tags.length" class="d-flex flex-wrap gap-2">
								<span v-for="tag in feedback.tags" :key="tag.id" class="badge text-bg-light border">{{ tag.ten }}</span>
							</div>
						</div>
					</div>
					<div v-else class="empty-state py-5">
						<i class="fa-solid fa-comment-slash d-block mb-3"></i>
						<p class="mb-0">Chưa có phản hồi nào từ tình nguyện viên.</p>
					</div>
				</div>
			</div>

			<div v-if="activeTab === 'reports'" class="card border-0 shadow-sm mb-4">
				<div class="card-header bg-white border-0 pb-0">
					<div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
						<div>
							<h6 class="fw-bold mb-1">Báo cáo sự cố và phản ánh</h6>
							<p class="text-muted small mb-0">Danh sách báo cáo TNV đã gửi trong chiến dịch này.</p>
						</div>
						<div class="text-muted small">Tổng {{ reports.length }} báo cáo</div>
					</div>
				</div>
				<div class="card-body pt-3">
					<div v-if="reports.length" class="report-list">
						<div v-for="report in reports" :key="report.id" class="report-card">
							<div class="d-flex justify-content-between align-items-start gap-3 mb-2">
								<div>
									<div class="d-flex flex-wrap align-items-center gap-2 mb-1">
										<h6 class="mb-0 fw-semibold">{{ report.title }}</h6>
										<span class="badge rounded-pill" :class="getReportStatusClass(report.status)">
											{{ getReportStatusLabel(report.status) }}
										</span>
									</div>
									<div class="text-muted small">
										{{ report.author }} · {{ report.category }} · {{ formatDateTime(report.createdAt) }}
									</div>
								</div>
							</div>
							<p class="mb-2 text-dark">{{ report.content }}</p>
							<div v-if="report.response || report.resolvedAt || report.processor" class="report-response">
								<div class="fw-semibold small text-uppercase text-muted mb-1">Phản hồi xử lý</div>
								<div class="small text-dark">{{ report.response || 'Đã cập nhật trạng thái nhưng chưa có phản hồi chi tiết.' }}</div>
								<div class="small text-muted mt-1">
									<span v-if="report.processor">{{ report.processor }}</span>
									<span v-if="report.processor && report.resolvedAt"> · </span>
									<span v-if="report.resolvedAt">{{ formatDateTime(report.resolvedAt) }}</span>
								</div>
							</div>
						</div>
					</div>
					<div v-else class="empty-state py-5">
						<i class="fa-solid fa-file-circle-check d-block mb-3"></i>
						<p class="mb-0">Chưa có báo cáo nào trong chiến dịch này.</p>
					</div>
				</div>
			</div>
		</div>

		<div v-else class="card border-0 shadow-sm">
			<div class="card-body text-center py-5">
				<div class="placeholder-icon mx-auto mb-3">
					<i class="fa-solid fa-chart-line"></i>
				</div>
				<h5 class="fw-bold text-muted">Chọn chiến dịch để bắt đầu theo dõi</h5>
				<p class="text-muted small mb-0">Màn này sẽ hiển thị danh sách tham gia, phản hồi và báo cáo của chiến dịch bạn chọn.</p>
			</div>
		</div>
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue';
import StatCards from '../../components/StatCards.vue';
import api from '../../services/api';
import { hasPermission } from '../../utils/permissions';

const CAMPAIGN_STATUS_LABELS = {
	cho_duyet: 'Chờ duyệt',
	da_duyet: 'Đã duyệt',
	dang_dien_ra: 'Đang diễn ra',
	hoan_thanh: 'Hoàn thành',
	yeu_cau_huy: 'Yêu cầu hủy',
	da_huy: 'Đã hủy',
	tu_choi: 'Từ chối',
	nhap: 'Nháp',
};

const PARTICIPATION_STATUS_LABELS = {
	da_dang_ky: 'Chờ TNV xác nhận',
	da_xac_nhan: 'Đã xác nhận, chờ duyệt',
	da_duyet: 'Đã duyệt',
	dang_tham_gia: 'Đang tham gia',
	hoan_thanh: 'Hoàn thành',
	tu_choi: 'Từ chối',
	da_huy: 'Đã hủy',
};

const REPORT_STATUS_LABELS = {
	moi: 'Mới',
	dang_xu_ly: 'Đang xử lý',
	da_xu_ly: 'Đã xử lý',
	tu_choi: 'Từ chối',
};

export default {
	name: 'GiamSatBaoCao',
	components: { PageHeader, StatCards },
	inject: ['toast'],
	data() {
		return {
			campaigns: [],
			selectedCampaignId: '',
			activeCampaign: null,
			participants: [],
			feedbacks: [],
			reports: [],
			stats: {
				totalValidRegistrations: 0,
				totalApproved: 0,
				totalInProgress: 0,
				totalFeedbacks: 0,
				totalReports: 0,
				pendingReports: 0,
			},
			activeTab: 'participants',
			participantSearch: '',
			participantStatusFilter: '',
			isLoadingList: false,
			isLoadingDetail: false,
		};
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
		statsCards() {
			return [
				{ label: 'Đăng ký hợp lệ', value: this.stats.totalValidRegistrations, icon: 'fa-solid fa-users', color: 'primary' },
				{ label: 'Đã duyệt', value: this.stats.totalApproved, icon: 'fa-solid fa-user-check', color: 'success' },
				{ label: 'Phản hồi', value: this.stats.totalFeedbacks, icon: 'fa-solid fa-star', color: 'warning' },
				{ label: 'Báo cáo chờ xử lý', value: this.stats.pendingReports, icon: 'fa-solid fa-triangle-exclamation', color: 'danger' },
			];
		},
		tabs() {
			return [
				{ value: 'participants', label: 'Tham gia', icon: 'fa-solid fa-users' },
				{ value: 'feedback', label: 'Phản hồi', icon: 'fa-solid fa-comments' },
				{ value: 'reports', label: 'Báo cáo', icon: 'fa-solid fa-file-lines' },
			];
		},
		filteredParticipants() {
			return this.participants.filter((participant) => {
				const matchesStatus = !this.participantStatusFilter || participant.status === this.participantStatusFilter;
				if (!matchesStatus) {
					return false;
				}

				if (!this.participantSearch) {
					return true;
				}

				const keyword = this.participantSearch.toLowerCase();
				return participant.name.toLowerCase().includes(keyword)
					|| participant.email.toLowerCase().includes(keyword);
			});
		},
	},
	created() {
		this.loadCampaigns();
	},
	methods: {
		async loadCampaigns() {
			this.isLoadingList = true;
			try {
				const response = await api.get('/tinh-nguyen-vien/chien-dich', {
					params: {
						per_page: 100,
					},
				});
				const items = Array.isArray(response.data?.data) ? response.data.data : [];
				this.campaigns = items.map((campaign) => ({
					id: campaign.id,
					name: campaign.tieu_de,
					status: campaign.trang_thai,
				}));

				if (!this.selectedCampaignId && this.campaigns.length) {
					this.selectedCampaignId = this.campaigns[0].id;
					await this.loadMonitoringData();
				}
			} catch (error) {
				this.showToast('error', 'Lỗi', error.response?.data?.message || 'Không tải được danh sách chiến dịch.');
			} finally {
				this.isLoadingList = false;
			}
		},
		async loadMonitoringData() {
			if (!this.selectedCampaignId) {
				this.resetDetailState();
				return;
			}

			this.isLoadingDetail = true;
			try {
				const response = await api.get(`/tinh-nguyen-vien/chien-dich/${this.selectedCampaignId}/giam-sat-bao-cao`);
				const payload = response.data?.data || {};
				const campaign = payload.chien_dich || {};
				this.activeCampaign = {
					id: campaign.id,
					name: campaign.tieu_de || '—',
					status: campaign.trang_thai || 'nhap',
					location: campaign.dia_diem || '—',
					timeRange: this.buildCampaignTimeRange(campaign),
				};
				this.stats = {
					totalValidRegistrations: Number(payload.thong_ke?.tong_dang_ky_hop_le || 0),
					totalApproved: Number(payload.thong_ke?.tong_da_duyet || 0),
					totalInProgress: Number(payload.thong_ke?.tong_dang_tham_gia || 0),
					totalFeedbacks: Number(payload.thong_ke?.tong_phan_hoi || 0),
					totalReports: Number(payload.thong_ke?.tong_bao_cao || 0),
					pendingReports: Number(payload.thong_ke?.bao_cao_chua_xu_ly || 0),
				};
				this.participants = Array.isArray(payload.danh_sach_tham_gia)
					? payload.danh_sach_tham_gia.map((item) => ({
						id: item.id,
						name: item.nguoi_dung?.ho_ten || 'Không xác định',
						email: item.nguoi_dung?.email || '—',
						avatar: item.nguoi_dung?.anh_dai_dien || '',
						status: item.trang_thai,
						registeredAt: item.dang_ky_luc,
						confirmedAt: item.xac_nhan_luc,
						note: item.ghi_chu || item.ly_do_huy || '',
					}))
					: [];
				this.feedbacks = Array.isArray(payload.phan_hoi)
					? payload.phan_hoi.map((item) => ({
						id: item.id,
						author: item.nguoi_dung?.ho_ten || 'Ẩn danh',
						email: item.nguoi_dung?.email || '—',
						rating: Number(item.so_sao || 0),
						comment: item.nhan_xet || '',
						createdAt: item.tao_luc,
						tags: Array.isArray(item.the_phan_hoi) ? item.the_phan_hoi : [],
					}))
					: [];
				this.reports = Array.isArray(payload.bao_cao)
					? payload.bao_cao.map((item) => ({
						id: item.id,
						title: item.tieu_de,
						category: item.phan_loai || 'Khác',
						content: item.noi_dung,
						status: item.trang_thai,
						response: item.phan_hoi_xu_ly || '',
						createdAt: item.tao_luc,
						resolvedAt: item.xu_ly_luc,
						author: item.nguoi_gui?.ho_ten || 'Không xác định',
						processor: item.nguoi_xu_ly?.ho_ten || '',
					}))
					: [];
			} catch (error) {
				this.resetDetailState();
				this.showToast('error', 'Lỗi', error.response?.data?.message || 'Không tải được dữ liệu giám sát báo cáo.');
			} finally {
				this.isLoadingDetail = false;
			}
		},
		refreshCurrentCampaign() {
			this.loadMonitoringData();
		},
		resetDetailState() {
			this.activeCampaign = null;
			this.participants = [];
			this.feedbacks = [];
			this.reports = [];
			this.stats = {
				totalValidRegistrations: 0,
				totalApproved: 0,
				totalInProgress: 0,
				totalFeedbacks: 0,
				totalReports: 0,
				pendingReports: 0,
			};
		},
		buildCampaignTimeRange(campaign) {
			const start = this.formatDate(campaign.thoi_gian_bat_dau_thuc_te || campaign.ngay_bat_dau);
			const end = this.formatDate(campaign.thoi_gian_ket_thuc_thuc_te || campaign.ngay_ket_thuc);
			if (start === '—' && end === '—') {
				return '—';
			}
			return `${start} - ${end}`;
		},
		formatDate(value) {
			if (!value) {
				return '—';
			}
			const date = new Date(value);
			if (Number.isNaN(date.getTime())) {
				return value;
			}
			return date.toLocaleDateString('vi-VN');
		},
		formatDateTime(value) {
			if (!value) {
				return '—';
			}
			const date = new Date(value);
			if (Number.isNaN(date.getTime())) {
				return value;
			}
			return date.toLocaleString('vi-VN');
		},
		getInitials(name) {
			const fullName = (name || '').trim();
			if (!fullName) {
				return 'U';
			}
			return fullName
				.split(/\s+/)
				.slice(0, 2)
				.map((part) => part.charAt(0).toUpperCase())
				.join('');
		},
		getCampaignStatusLabel(status) {
			return CAMPAIGN_STATUS_LABELS[status] || status || 'Không xác định';
		},
		getCampaignStatusClass(status) {
			return {
				'bg-warning text-dark': status === 'cho_duyet' || status === 'nhap' || status === 'yeu_cau_huy',
				'bg-primary text-white': status === 'da_duyet',
				'bg-success text-white': status === 'dang_dien_ra' || status === 'hoan_thanh',
				'bg-danger text-white': status === 'da_huy' || status === 'tu_choi',
			};
		},
		getParticipationStatusLabel(status) {
			return PARTICIPATION_STATUS_LABELS[status] || status || 'Không xác định';
		},
		getParticipationStatusClass(status) {
			return {
				'bg-warning-subtle text-warning': status === 'da_dang_ky' || status === 'da_xac_nhan',
				'bg-info-subtle text-info': status === 'da_duyet',
				'bg-primary-subtle text-primary': status === 'dang_tham_gia',
				'bg-success-subtle text-success': status === 'hoan_thanh',
				'bg-danger-subtle text-danger': status === 'tu_choi' || status === 'da_huy',
			};
		},
		getReportStatusLabel(status) {
			return REPORT_STATUS_LABELS[status] || status || 'Không xác định';
		},
		getReportStatusClass(status) {
			return {
				'bg-warning-subtle text-warning': status === 'moi' || status === 'dang_xu_ly',
				'bg-success-subtle text-success': status === 'da_xu_ly',
				'bg-danger-subtle text-danger': status === 'tu_choi',
			};
		},
		showToast(type, title, message) {
			if (this.toast?.showToast) {
				this.toast.showToast(type, title, message);
			}
		},
	},
};
</script>

<style scoped>
.campaign-summary-strip {
	display: grid;
	grid-template-columns: repeat(3, minmax(0, 1fr));
	gap: 1rem;
	padding: 0.85rem 1rem;
	background: #f8fafc;
	border: 1px solid #e2e8f0;
	border-radius: 14px;
}

.summary-label {
	font-size: 12px;
	font-weight: 600;
	color: #64748b;
	margin-bottom: 0.35rem;
	text-transform: uppercase;
	letter-spacing: 0.04em;
}

.summary-value {
	font-size: 14px;
	font-weight: 600;
	color: #0f172a;
}

.nav-tabs-clean .nav-link {
	border: 0;
	border-bottom: 3px solid transparent;
	border-radius: 0;
	padding: 0.95rem 1rem;
	color: #64748b;
	font-weight: 600;
	background: transparent;
}

.nav-tabs-clean .nav-link.active {
	color: #0d6efd;
	border-bottom-color: #0d6efd;
}

.participant-avatar {
	width: 42px;
	height: 42px;
	min-width: 42px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-weight: 700;
	overflow: hidden;
}

.participant-avatar-image {
	width: 100%;
	height: 100%;
	object-fit: cover;
	display: block;
}

.feedback-list,
.report-list {
	display: grid;
	gap: 1rem;
}

.feedback-card,
.report-card {
	border: 1px solid #e5e7eb;
	border-radius: 16px;
	padding: 1rem 1.1rem;
	background: #ffffff;
}

.report-response {
	margin-top: 0.75rem;
	padding: 0.85rem 0.95rem;
	border-radius: 12px;
	background: #f8fafc;
	border: 1px solid #e2e8f0;
}

.placeholder-icon {
	width: 80px;
	height: 80px;
	border-radius: 50%;
	background: #f0f4f8;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 32px;
	color: #94a3b8;
}

.empty-state {
	text-align: center;
	color: #6b7280;
}

.empty-state i {
	font-size: 34px;
	opacity: 0.35;
}

.min-w-0 {
	min-width: 0;
}

@media (max-width: 991.98px) {
	.campaign-summary-strip {
		grid-template-columns: 1fr;
	}
}
</style>
