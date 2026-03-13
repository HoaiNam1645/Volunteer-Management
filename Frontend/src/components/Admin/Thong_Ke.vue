<template>
	<div class="admin-stats">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-chart-pie text-primary me-2"></i>{{ $t('admin.stats.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.stats.subtitle') }}</p>
			</div>
			<div class="d-flex gap-2">
				<select class="form-select form-select-sm" style="width: auto;" v-model="period">
					<option value="week">{{ $t('admin.stats.period.week') }}</option>
					<option value="month">{{ $t('admin.stats.period.month') }}</option>
					<option value="quarter">{{ $t('admin.stats.period.quarter') }}</option>
					<option value="year">{{ $t('admin.stats.period.year') }}</option>
				</select>
				<button class="btn btn-outline-primary btn-sm rounded-pill px-3" @click="exportReport">
					<i class="fa-solid fa-download me-1"></i>{{ $t('admin.stats.exportReport') }}
				</button>
			</div>
		</div>

		<!-- KPIs -->
		<div class="row g-3 mb-4">
			<div class="col-xl-3 col-sm-6" v-for="kpi in kpis" :key="kpi.labelKey">
				<div class="card border-0 shadow-sm kpi-card">
					<div class="card-body p-3">
						<div class="d-flex align-items-center justify-content-between mb-2">
							<span class="text-muted small">{{ $t(kpi.labelKey) }}</span>
							<div class="kpi-icon" :style="{ background: kpi.bgColor, color: kpi.color }">
								<i :class="kpi.icon"></i>
							</div>
						</div>
						<h3 class="fw-bold mb-1">{{ kpi.value }}</h3>
						<div class="d-flex align-items-center gap-2">
							<span class="small" :class="kpi.trendUp ? 'text-success' : 'text-danger'">
								<i class="fa-solid" :class="kpi.trendUp ? 'fa-arrow-up' : 'fa-arrow-down'"></i>
								{{ kpi.trendValue }}
							</span>
							<span class="text-muted small">{{ $t('admin.stats.compare') }}</span>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Charts Row 1 -->
		<div class="row g-3 mb-4">
			<!-- Campaign Stats -->
			<div class="col-lg-8">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
						<h6 class="fw-bold mb-0"><i class="fa-solid fa-chart-bar text-primary me-2"></i>{{ $t('admin.stats.charts.campaignMonth') }}</h6>
						<div class="btn-group btn-group-sm">
							<button class="btn" :class="chartView === 'campaigns' ? 'btn-primary' : 'btn-outline-secondary'" @click="chartView = 'campaigns'">{{ $t('admin.stats.charts.campaigns') }}</button>
							<button class="btn" :class="chartView === 'volunteers' ? 'btn-primary' : 'btn-outline-secondary'" @click="chartView = 'volunteers'">{{ $t('admin.stats.charts.volunteers') }}</button>
						</div>
					</div>
					<div class="card-body">
						<div class="d-flex align-items-end gap-3 justify-content-between" style="height: 220px;">
							<div class="text-center flex-grow-1" v-for="month in monthlyData" :key="month.label">
								<div class="d-flex align-items-end justify-content-center" style="height: 180px;">
									<div class="month-bar" :style="{ 
										height: (chartView === 'campaigns' ? month.campaigns : month.volunteers) / maxValue * 100 + '%',
										background: chartView === 'campaigns' ? '#4f8cf7' : '#28a745'
									}">
										<span class="bar-value">{{ chartView === 'campaigns' ? month.campaigns : month.volunteers }}</span>
									</div>
								</div>
								<span class="text-muted small mt-2 d-block">{{ month.label }}</span>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Campaign Status Distribution -->
			<div class="col-lg-4">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3">
						<h6 class="fw-bold mb-0"><i class="fa-solid fa-circle-nodes text-primary me-2"></i>{{ $t('admin.stats.charts.campaignStatus') }}</h6>
					</div>
					<div class="card-body">
						<div class="status-item d-flex align-items-center gap-3 mb-3" v-for="item in campaignStatuses" :key="item.labelKey">
							<div class="status-icon" :style="{ background: item.bgColor, color: item.color }">
								<i :class="item.icon"></i>
							</div>
							<div class="flex-grow-1">
								<div class="d-flex align-items-center justify-content-between mb-1">
									<span class="small fw-bold">{{ $t(item.labelKey) }}</span>
									<span class="small fw-bold">{{ item.count }}</span>
								</div>
								<div class="progress" style="height: 6px;">
									<div class="progress-bar" :style="{ width: item.percent + '%', background: item.color }"></div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Charts Row 2 -->
		<div class="row g-3">
			<!-- Top Regions -->
			<div class="col-lg-6">
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom py-3">
						<h6 class="fw-bold mb-0"><i class="fa-solid fa-map text-primary me-2"></i>{{ $t('admin.stats.charts.topRegions') }}</h6>
					</div>
					<div class="card-body p-0">
						<div class="region-item d-flex align-items-center gap-3 p-3 border-bottom" v-for="(region, idx) in topRegions" :key="idx">
							<div class="region-rank" :class="idx < 3 ? 'rank-top' : ''">{{ idx + 1 }}</div>
							<div class="flex-grow-1">
								<div class="d-flex align-items-center justify-content-between mb-1">
									<span class="small fw-bold">{{ region.name }}</span>
									<span class="text-muted small">{{ region.volunteers }} {{ $t('admin.stats.charts.volunteersUnit') }}</span>
								</div>
								<div class="progress" style="height: 5px;">
									<div class="progress-bar bg-primary" :style="{ width: region.percent + '%' }"></div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Top Skills -->
			<div class="col-lg-6">
				<div class="card border-0 shadow-sm">
					<div class="card-header bg-white border-bottom py-3">
						<h6 class="fw-bold mb-0"><i class="fa-solid fa-star text-primary me-2"></i>{{ $t('admin.stats.charts.topSkills') }}</h6>
					</div>
					<div class="card-body p-0">
						<div class="skill-item d-flex align-items-center gap-3 p-3 border-bottom" v-for="(skill, idx) in topSkills" :key="idx">
							<div class="skill-rank-icon" :style="{ background: skill.color + '20', color: skill.color }">
								<i :class="skill.icon"></i>
							</div>
							<div class="flex-grow-1">
								<div class="d-flex align-items-center justify-content-between mb-1">
									<span class="small fw-bold">{{ skill.name }}</span>
									<span class="text-muted small">{{ skill.count }} {{ $t('admin.stats.charts.peopleUnit') }}</span>
								</div>
								<div class="progress" style="height: 5px;">
									<div class="progress-bar" :style="{ width: skill.percent + '%', background: skill.color }"></div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
export default {
	name: 'ThongKeTongHop',
	props: {
		toast: { type: Object, default: null }
	},
	data() {
		return {
			period: 'month',
			chartView: 'campaigns',
			kpis: [
				{ labelKey: 'admin.stats.kpi.totalUsers', value: '1,248', trendUp: true, trendValue: '+12.5%', icon: 'fa-solid fa-users', bgColor: 'rgba(79,140,247,0.1)', color: '#4f8cf7' },
				{ labelKey: 'admin.stats.kpi.totalCampaigns', value: '156', trendUp: true, trendValue: '+8.3%', icon: 'fa-solid fa-flag', bgColor: 'rgba(40,167,69,0.1)', color: '#28a745' },
				{ labelKey: 'admin.stats.kpi.completionRate', value: '84%', trendUp: true, trendValue: '+5.2%', icon: 'fa-solid fa-check-circle', bgColor: 'rgba(253,126,20,0.1)', color: '#fd7e14' },
				{ labelKey: 'admin.stats.kpi.avgRating', value: '4.6', trendUp: false, trendValue: '-0.1', icon: 'fa-solid fa-star', bgColor: 'rgba(220,53,69,0.1)', color: '#dc3545' }
			],
			monthlyData: [
				{ label: 'T1', campaigns: 8, volunteers: 120 },
				{ label: 'T2', campaigns: 12, volunteers: 180 },
				{ label: 'T3', campaigns: 15, volunteers: 245 },
				{ label: 'T4', campaigns: 10, volunteers: 165 },
				{ label: 'T5', campaigns: 18, volunteers: 310 },
				{ label: 'T6', campaigns: 22, volunteers: 380 },
				{ label: 'T7', campaigns: 28, volunteers: 450 },
				{ label: 'T8', campaigns: 25, volunteers: 410 },
				{ label: 'T9', campaigns: 20, volunteers: 340 },
				{ label: 'T10', campaigns: 16, volunteers: 260 },
				{ label: 'T11', campaigns: 14, volunteers: 220 },
				{ label: 'T12', campaigns: 10, volunteers: 185 }
			],
			campaignStatuses: [
				{ labelKey: 'admin.stats.status.recruiting', count: 12, percent: 32, icon: 'fa-solid fa-bullhorn', color: '#28a745', bgColor: 'rgba(40,167,69,0.1)' },
				{ labelKey: 'admin.stats.status.active', count: 8, percent: 21, icon: 'fa-solid fa-play', color: '#0d6efd', bgColor: 'rgba(13,110,253,0.1)' },
				{ labelKey: 'admin.stats.status.completed', count: 128, percent: 82, icon: 'fa-solid fa-check', color: '#6c757d', bgColor: 'rgba(108,117,125,0.1)' },
				{ labelKey: 'admin.stats.status.cancelled', count: 8, percent: 5, icon: 'fa-solid fa-ban', color: '#dc3545', bgColor: 'rgba(220,53,69,0.1)' }
			],
			topRegions: [
				{ name: 'TP. Hồ Chí Minh', volunteers: 320, percent: 100 },
				{ name: 'Hà Nội', volunteers: 285, percent: 89 },
				{ name: 'Đà Nẵng', volunteers: 198, percent: 62 },
				{ name: 'Lào Cai', volunteers: 145, percent: 45 },
				{ name: 'Quảng Nam', volunteers: 120, percent: 38 },
				{ name: 'Đắk Lắk', volunteers: 95, percent: 30 }
			],
			topSkills: [
				{ name: 'Dạy học', count: 245, percent: 100, color: '#4f8cf7', icon: 'fa-solid fa-chalkboard-user' },
				{ name: 'Truyền thông', count: 156, percent: 64, color: '#e83e8c', icon: 'fa-solid fa-bullhorn' },
				{ name: 'Y tế / Sơ cứu', count: 128, percent: 52, color: '#dc3545', icon: 'fa-solid fa-kit-medical' },
				{ name: 'IT / Công nghệ', count: 112, percent: 46, color: '#6f42c1', icon: 'fa-solid fa-laptop-code' },
				{ name: 'Nấu ăn', count: 98, percent: 40, color: '#fd7e14', icon: 'fa-solid fa-utensils' },
				{ name: 'Xây dựng', count: 89, percent: 36, color: '#198754', icon: 'fa-solid fa-hammer' }
			]
		}
	},
	computed: {
		maxValue() {
			return Math.max(...this.monthlyData.map(m => this.chartView === 'campaigns' ? m.campaigns : m.volunteers));
		}
	},
	methods: {
		exportReport() {
			if (this.toast) this.toast.success(this.$t('admin.stats.toast.exportSuccess'), this.$t('admin.stats.toast.exportMsg'));
		}
	}
}
</script>

<style scoped>
.kpi-card {
	border-radius: 14px;
	transition: transform 0.2s ease;
}
.kpi-card:hover {
	transform: translateY(-2px);
}

.kpi-icon {
	width: 42px;
	height: 42px;
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 18px;
}

.month-bar {
	width: 28px;
	border-radius: 4px 4px 0 0;
	transition: height 0.5s ease;
	min-height: 4px;
	position: relative;
}

.bar-value {
	position: absolute;
	top: -20px;
	left: 50%;
	transform: translateX(-50%);
	font-size: 10px;
	font-weight: 700;
	white-space: nowrap;
}

.status-icon {
	width: 38px;
	height: 38px;
	min-width: 38px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 14px;
}

.region-rank {
	width: 28px;
	height: 28px;
	min-width: 28px;
	border-radius: 50%;
	background: #f0f2f5;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	font-weight: 700;
	color: #6c757d;
}

.rank-top {
	background: linear-gradient(135deg, #4f8cf7, #3b6de7);
	color: white;
}

.region-item { transition: background 0.2s; }
.region-item:hover { background: #f8f9fa; }
.region-item:last-child { border-bottom: none !important; }

.skill-rank-icon {
	width: 38px;
	height: 38px;
	min-width: 38px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 15px;
}

.skill-item { transition: background 0.2s; }
.skill-item:hover { background: #f8f9fa; }
.skill-item:last-child { border-bottom: none !important; }
</style>
