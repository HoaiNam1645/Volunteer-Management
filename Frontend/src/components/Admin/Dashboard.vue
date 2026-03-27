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
									<div class="chart-bar bg-primary bg-opacity-75" :style="{ height: item.regHeight + '%' }"
										v-bs-tooltip :title="item.reg + ' ' + $t('admin.dashboard.charts.newRegistrations').toLowerCase()"></div>
									<div class="chart-bar bg-success bg-opacity-75" :style="{ height: item.campHeight + '%' }"
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

		<!-- Lower Section -->
		<div class="row g-3">
			<!-- Recent Users -->
			<div class="col-lg-6">
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
						<h6 class="fw-bold mb-0">
							<i class="fa-solid fa-user-plus text-primary me-2"></i>Người dùng đăng ký gần đây
							<span class="badge bg-primary-subtle text-primary ms-2">{{ recentUsers.length }}</span>
						</h6>
						<router-link v-if="canViewUsers" to="/admin/nguoi-dung" class="btn btn-sm btn-outline-primary rounded-pill">Xem tất cả</router-link>
					</div>
					<div class="card-body p-0">
						<div v-if="!recentUsers.length" class="text-muted small p-3">Chưa có người dùng đăng ký gần đây.</div>
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
						<div v-if="!recentCampaigns.length" class="text-muted small p-3">Chưa có chiến dịch gần đây.</div>
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
	</div>
</template>

<script>
import api from '../../services/api';
import { hasPermission } from '../../utils/permissions';

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
			roleDistribution: [],
			recentUsers: [],
			recentCampaigns: [],
		}
	},
	async created() {
		this.loadCurrentUser();
		await this.fetchDashboard();
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
			return this.stats.find((item) => item.key === 'active_campaigns')?.badge_label || '0 đang hoạt động';
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
				}));

				this.roleDistribution = payload.role_distribution || [];
				this.recentUsers = payload.recent_users || [];
				this.recentCampaigns = payload.recent_campaigns || [];
			} catch (error) {
				if (this.toast) {
					this.toast.error('Không thể tải dashboard', error?.response?.data?.message || 'Vui lòng thử lại sau.');
				}
			}
		},
		getTrendText(stat) {
			return stat?.trend?.text || 'Không đổi';
		},
		trendBadgeClass(stat) {
			return stat?.trend?.positive
				? 'bg-success-subtle text-success'
				: 'bg-warning-subtle text-warning';
		},
		trendIcon(stat) {
			return stat?.trend?.positive ? 'fa-arrow-up' : 'fa-circle-exclamation';
		},
		formatNumber(value) {
			return new Intl.NumberFormat('vi-VN').format(Number(value || 0));
		},
		campaignThumbStyle(campaign) {
			if (campaign.image) {
				return { backgroundImage: `url(${campaign.image})` };
			}
			return { background: 'linear-gradient(135deg, #4f8cf7, #77a6ff)' };
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
