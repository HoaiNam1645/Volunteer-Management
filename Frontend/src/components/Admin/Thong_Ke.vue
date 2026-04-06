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
			</div>
		</div>

		<!-- KPIs -->
		<div class="row g-3 mb-4">
			<div class="col-xl-3 col-sm-6" v-for="kpi in kpis" :key="kpi.label">
				<div class="card border-0 shadow-sm kpi-card">
					<div class="card-body p-3">
						<div class="d-flex align-items-center justify-content-between mb-2">
							<span class="text-muted small">{{ kpi.label }}</span>
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
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-chart-bar text-primary me-2"></i>{{ chartTitle }}</h6>
							<div class="btn-group btn-group-sm">
								<button class="btn" :class="chartView === 'campaigns' ? 'btn-primary' : 'btn-outline-secondary'" @click="chartView = 'campaigns'">{{ $t('admin.stats.charts.campaigns') }}</button>
								<button class="btn" :class="chartView === 'volunteers' ? 'btn-primary' : 'btn-outline-secondary'" @click="chartView = 'volunteers'">{{ $t('admin.stats.charts.volunteers') }}</button>
							</div>
						</div>
						<div class="card-body">
							<div class="small text-muted mb-3">
								{{ $t('admin.stats.charts.periodSummary', { campaigns: periodSummary.campaigns, volunteers: periodSummary.volunteers }) }}
							</div>
							<div class="d-flex align-items-end gap-3 justify-content-between" style="height: 220px;">
								<div class="text-center flex-grow-1" v-for="month in monthlyData" :key="`${period}-${month.label}`">
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
						<div class="status-item d-flex align-items-center gap-3 mb-3" v-for="item in campaignStatuses" :key="item.label">
							<div class="status-icon" :style="{ background: item.bgColor, color: item.color }">
								<i :class="item.icon"></i>
							</div>
							<div class="flex-grow-1">
								<div class="d-flex align-items-center justify-content-between mb-1">
									<span class="small fw-bold">{{ item.label }}</span>
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
import api from '../../services/api';

export default {
	name: 'ThongKeTongHop',
	props: {
		toast: { type: Object, default: null }
	},
	data() {
			return {
				period: 'month',
				chartView: 'campaigns',
				kpis: [],
				monthlyData: [],
				periodSummary: {
					campaigns: 0,
					volunteers: 0,
				},
				campaignStatuses: [],
				topRegions: [],
				topSkills: []
			}
	},
	async created() {
		await this.fetchStatistics();
	},
	watch: {
		period() {
			this.fetchStatistics();
		}
	},
	computed: {
		maxValue() {
			return Math.max(1, ...this.monthlyData.map(m => this.chartView === 'campaigns' ? m.campaigns : m.volunteers), 1);
		},
		chartTitle() {
			const key = {
				week: 'campaignWeek',
				month: 'campaignMonth',
				quarter: 'campaignQuarter',
				year: 'campaignYear',
			}[this.period] || 'campaignMonth';

			return this.$t(`admin.stats.charts.${key}`);
		}
	},
	methods: {
		async fetchStatistics() {
			try {
				const { data } = await api.get('/kiem-duyet/thong-ke', { params: { period: this.period } });
				const payload = data?.data || {};
				this.kpis = Object.values(payload.kpis || {}).map((item) => ({
					label: item.label,
					value: item.value,
					trendUp: item.trend?.positive ?? true,
					trendValue: item.trend?.text || 'Không đổi',
					icon: item.icon,
					bgColor: item.bg_color,
					color: item.color,
				}));

					this.monthlyData = payload.monthly_data || [];
					this.periodSummary = payload.period_summary || { campaigns: 0, volunteers: 0 };
					this.campaignStatuses = (payload.campaign_statuses || []).map((item) => ({
						label: item.label,
						count: item.count,
					percent: item.percent,
					icon: item.icon,
					color: item.color,
					bgColor: item.bg_color,
				}));
				this.topRegions = payload.top_regions || [];
				this.topSkills = payload.top_skills || [];
			} catch (error) {
				if (this.toast) {
					this.toast.error('Không thể tải thống kê', error?.response?.data?.message || 'Vui lòng thử lại sau.');
				}
			}
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
