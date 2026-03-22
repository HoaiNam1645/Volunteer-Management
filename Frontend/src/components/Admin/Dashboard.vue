<template>
	<div class="admin-dashboard">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-gauge-high text-primary me-2"></i>{{ $t('admin.dashboard.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.dashboard.subtitle') }}</p>
			</div>
			<div class="d-flex gap-2">
				<select class="form-select form-select-sm" style="width: auto;">
					<option>{{ $t('admin.dashboard.period.week') }}</option>
					<option>{{ $t('admin.dashboard.period.month') }}</option>
					<option>{{ $t('admin.dashboard.period.quarter') }}</option>
					<option>{{ $t('admin.dashboard.period.year') }}</option>
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
								<p class="text-muted small mb-1">{{ $t(stat.labelKey) }}</p>
								<h3 class="fw-bold mb-0">{{ stat.value }}</h3>
								<div class="mt-2">
									<span class="badge rounded-pill" :class="stat.trendClass">
										<i class="fa-solid" :class="stat.trendIcon"></i> {{ getTrendText(stat) }}
									</span>
								</div>
							</div>
							<div class="stat-icon" :class="stat.bgClass">
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
									<div class="chart-bar bg-primary bg-opacity-75" :style="{ height: item.reg + '%' }" 
										v-bs-tooltip :title="item.reg + ' ' + $t('admin.dashboard.charts.newRegistrations').toLowerCase()"></div>
									<div class="chart-bar bg-success bg-opacity-75" :style="{ height: item.camp + '%' }"
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
								<h4 class="fw-bold mb-0">1,248</h4>
								<span class="small text-muted">{{ $t('admin.dashboard.charts.total') }}</span>
							</div>
						</div>
						<div class="d-flex flex-column gap-3">
							<div class="d-flex align-items-center justify-content-between" v-for="role in roleDistribution" :key="role.label">
								<div class="d-flex align-items-center gap-2">
									<span class="role-dot" :style="{ background: role.color }"></span>
									<span class="small">{{ $t(role.labelKey) }}</span>
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

		<!-- Lower Section -->
		<div class="row g-3">
			<!-- Pending Approvals -->
			<div class="col-lg-6">
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
						<h6 class="fw-bold mb-0">
							<i class="fa-solid fa-user-clock text-warning me-2"></i>{{ $t('admin.dashboard.approval.title') }}
							<span class="badge bg-warning text-dark ms-2">5</span>
						</h6>
						<router-link v-if="canViewUsers" to="/admin/nguoi-dung" class="btn btn-sm btn-outline-primary rounded-pill">{{ $t('admin.dashboard.approval.viewAll') }}</router-link>
					</div>
					<div class="card-body p-0">
						<div class="approval-item d-flex align-items-center gap-3 p-3 border-bottom" v-for="user in pendingUsers" :key="user.id">
							<div class="user-avatar-sm" :style="{ background: user.color }">
								{{ user.name.charAt(0) }}
							</div>
							<div class="flex-grow-1">
								<h6 class="mb-0 small fw-bold">{{ user.name }}</h6>
								<span class="text-muted" style="font-size: 12px;">{{ user.email }} · {{ user.time }}</span>
							</div>
							<div v-if="canManageUsers" class="d-flex gap-1">
								<button class="btn btn-sm btn-success rounded-pill px-3" @click="approveUser(user)">
									<i class="fa-solid fa-check me-1"></i>{{ $t('admin.dashboard.approval.approve') }}
								</button>
								<button class="btn btn-sm btn-outline-danger rounded-pill px-2" @click="rejectUser(user)">
									<i class="fa-solid fa-xmark"></i>
								</button>
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
						<span class="badge bg-success rounded-pill">{{ $t('admin.dashboard.campaigns.activeCount', { count: 12 }) }}</span>
					</div>
					<div class="card-body p-0">
						<div class="campaign-item d-flex align-items-center gap-3 p-3 border-bottom" v-for="campaign in recentCampaigns" :key="campaign.id">
							<div class="campaign-thumb" :style="{ backgroundImage: `url(${campaign.image})` }"></div>
							<div class="flex-grow-1">
								<h6 class="mb-1 small fw-bold campaign-title-text">{{ campaign.title }}</h6>
								<div class="d-flex align-items-center gap-3 text-muted" style="font-size: 12px;">
									<span><i class="fa-solid fa-users me-1"></i>{{ campaign.volunteers }}/{{ campaign.target }}</span>
									<span><i class="fa-solid fa-location-dot me-1"></i>{{ campaign.location }}</span>
								</div>
							</div>
							<span class="badge rounded-pill" :class="campaign.statusClass">{{ $t(campaign.statusKey) }}</span>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
import { hasPermission } from '../../utils/permissions';

export default {
	name: 'AdminDashboard',
	props: {
		toast: { type: Object, default: null }
	},
	data() {
		return {
			currentUser: null,
			stats: [
				{ labelKey: 'admin.dashboard.stats.totalUsers', value: '1,248', trend: '+12.5%', trendType: 'text', trendIcon: 'fa-arrow-up', trendClass: 'bg-success-subtle text-success', icon: 'fa-solid fa-users', bgClass: 'bg-primary-subtle text-primary' },
				{ labelKey: 'admin.dashboard.stats.activeCampaigns', value: '24', trend: '+3', trendType: 'text', trendIcon: 'fa-arrow-up', trendClass: 'bg-success-subtle text-success', icon: 'fa-solid fa-flag', bgClass: 'bg-success-subtle text-success' },
				{ labelKey: 'admin.dashboard.stats.pendingApprovals', value: '5', trendKey: 'admin.dashboard.stats.needsAction', trendType: 'i18n', trendIcon: 'fa-circle-exclamation', trendClass: 'bg-warning-subtle text-warning', icon: 'fa-solid fa-user-clock', bgClass: 'bg-warning-subtle text-warning' },
				{ labelKey: 'admin.dashboard.stats.publishedArticles', value: '87', trendCount: 8, trendType: 'i18nWeek', trendIcon: 'fa-arrow-up', trendClass: 'bg-info-subtle text-info', icon: 'fa-solid fa-newspaper', bgClass: 'bg-info-subtle text-info' }
			],
			chartData: [
				{ label: 'T2', reg: 45, camp: 30 },
				{ label: 'T3', reg: 60, camp: 45 },
				{ label: 'T4', reg: 35, camp: 55 },
				{ label: 'T5', reg: 80, camp: 40 },
				{ label: 'T6', reg: 55, camp: 65 },
				{ label: 'T7', reg: 70, camp: 50 },
				{ label: 'CN', reg: 90, camp: 75 }
			],
			roleDistribution: [
				{ labelKey: 'admin.dashboard.charts.roles.volunteer', count: 985, percent: 79, color: '#4f8cf7' },
				{ labelKey: 'admin.dashboard.charts.roles.coordinator', count: 198, percent: 16, color: '#28a745' },
				{ labelKey: 'admin.dashboard.charts.roles.admin', count: 5, percent: 0.4, color: '#fd7e14' },
				{ labelKey: 'admin.dashboard.charts.roles.pending', count: 60, percent: 5, color: '#dc3545' }
			],
			pendingUsers: [
				{ id: 1, name: 'Nguyễn Văn Bình', email: 'binh.nv@gmail.com', time: '2 giờ trước', color: '#dc3545' },
				{ id: 2, name: 'Trần Thị Mai', email: 'mai.tt@gmail.com', time: '5 giờ trước', color: '#6f42c1' },
				{ id: 3, name: 'Lê Hòa Phúc', email: 'phuc.lh@gmail.com', time: '1 ngày trước', color: '#198754' },
				{ id: 4, name: 'Phạm Quốc Huy', email: 'huy.pq@gmail.com', time: '1 ngày trước', color: '#fd7e14' },
				{ id: 5, name: 'Hoàng Yến Nhi', email: 'nhi.hy@gmail.com', time: '2 ngày trước', color: '#0d6efd' }
			],
			recentCampaigns: [
				{ id: 1, title: 'Trồng cây xanh Tây Nguyên 2026', volunteers: 45, target: 80, location: 'Đắk Lắk', statusKey: 'admin.stats.status.recruiting', statusClass: 'bg-success-subtle text-success', image: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=100&q=80' },
				{ id: 2, title: 'Dạy học miễn phí Sapa', volunteers: 20, target: 20, location: 'Lào Cai', statusKey: 'admin.stats.status.completed', statusClass: 'bg-primary-subtle text-primary', image: 'https://images.unsplash.com/photo-1529390079861-591de354faf5?w=100&q=80' },
				{ id: 3, title: 'Khám bệnh cộng đồng Quảng Nam', volunteers: 12, target: 30, location: 'Quảng Nam', statusKey: 'admin.stats.status.recruiting', statusClass: 'bg-success-subtle text-success', image: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=100&q=80' },
				{ id: 4, title: 'Xây cầu vùng lũ Quảng Bình', volunteers: 50, target: 50, location: 'Quảng Bình', statusKey: 'admin.stats.status.completed', statusClass: 'bg-secondary-subtle text-secondary', image: 'https://images.unsplash.com/photo-1469571486292-0ba58a3f068b?w=100&q=80' }
			]
		}
	},
	created() {
		this.loadCurrentUser();
	},
	computed: {
		canManageUsers() {
			return hasPermission(this.currentUser, 'user_management.manage');
		},
		canViewUsers() {
			return hasPermission(this.currentUser, 'user_management.view');
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
		getTrendText(stat) {
			if (stat.trendType === 'i18nWeek') {
				return this.$t('admin.dashboard.stats.thisWeekCount', { count: stat.trendCount });
			} else if (stat.trendType === 'i18n') {
				return this.$t(stat.trendKey);
			}
			return stat.trend;
		},
		approveUser(user) {
			this.pendingUsers = this.pendingUsers.filter(u => u.id !== user.id);
			this.stats[2].value = String(this.pendingUsers.length);
			if (this.toast) this.toast.success(this.$t('admin.dashboard.approval.toast.approveSuccess'), this.$t('admin.dashboard.approval.toast.approveMsg', { name: user.name }));
		},
		rejectUser(user) {
			this.pendingUsers = this.pendingUsers.filter(u => u.id !== user.id);
			this.stats[2].value = String(this.pendingUsers.length);
			if (this.toast) this.toast.warning(this.$t('admin.dashboard.approval.toast.rejectSuccess'), this.$t('admin.dashboard.approval.toast.rejectMsg', { name: user.name }));
		}
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

@media (max-width: 575px) {
	.stat-icon {
		width: 40px;
		height: 40px;
		font-size: 16px;
	}
}
</style>
