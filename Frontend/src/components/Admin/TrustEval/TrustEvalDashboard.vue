<template>
	<div class="trust-eval-dashboard">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1">
					<i class="fa-solid fa-chart-line text-primary me-2"></i>
					{{ $t('trustEval.dashboard.title') }}
				</h4>
				<p class="text-muted mb-0 small">{{ $t('trustEval.dashboard.subtitle') }}</p>
			</div>
			<div class="d-flex align-items-center gap-2">
				<!-- ML Service Status -->
				<div
					class="d-flex align-items-center gap-2 px-3 py-2 rounded-4 border"
					:class="mlHealth.healthy ? 'border-success bg-success-subtle' : 'border-danger bg-danger-subtle'"
				>
					<span
						class="ml-health-dot"
						:class="mlHealth.healthy ? 'healthy' : 'unhealthy'"
					></span>
					<span class="small fw-semibold" :class="mlHealth.healthy ? 'text-success' : 'text-danger'">
						{{ mlHealth.healthy ? $t('trustEval.dashboard.mlServiceOnline') : $t('trustEval.dashboard.mlServiceOffline') }}
					</span>
					<span v-if="mlHealth.healthy && mlHealth.data?.models_loaded" class="small text-muted">
						{{ Object.values(mlHealth.data.models_loaded).filter(Boolean).length }} {{ $t('trustEval.dashboard.modelsLoaded') }}
					</span>
				</div>
				<!-- Refresh -->
				<button class="btn btn-outline-primary btn-sm rounded-pill" @click="loadAll" :disabled="loading">
					<i class="fa-solid fa-rotate-right me-1" :class="loading ? 'fa-spin' : ''"></i>
					{{ $t('common.refresh') }}
				</button>
			</div>
		</div>

		<!-- Loading -->
		<div v-if="loading" class="text-center py-5">
			<div class="spinner-border text-primary mb-3"></div>
			<div class="text-muted">{{ $t('common.loading') }}</div>
		</div>

		<!-- Content -->
		<div v-else>
			<!-- KPI Row -->
			<div class="row g-3 mb-4">
				<div class="col-xl-3 col-sm-6" v-for="kpi in kpis" :key="kpi.label">
					<div class="card border-0 shadow-sm kpi-card h-100">
						<div class="card-body p-3">
							<div class="d-flex align-items-center justify-content-between mb-2">
								<span class="text-muted small">{{ kpi.label }}</span>
								<div class="kpi-icon" :style="{ background: kpi.bgColor, color: kpi.color }">
									<i :class="kpi.icon"></i>
								</div>
							</div>
							<h3 class="fw-bold mb-1">{{ kpi.value }}</h3>
							<div v-if="kpi.subValue" class="small text-muted">{{ kpi.subValue }}</div>
						</div>
					</div>
				</div>
			</div>

			<div class="row g-3">
				<!-- Risk Level Distribution -->
				<div class="col-lg-6">
					<div class="card border-0 shadow-sm h-100">
						<div class="card-header bg-white border-bottom py-3">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-chart-pie text-danger me-2"></i>
								{{ $t('trustEval.dashboard.riskDistribution') }}
							</h6>
						</div>
						<div class="card-body">
							<div class="risk-dist-list">
								<div
									v-for="item in riskDistribution"
									:key="item.level"
									class="risk-dist-item"
								>
									<div class="d-flex align-items-center justify-content-between mb-1">
										<div class="d-flex align-items-center gap-2">
											<span class="badge" :class="riskLevelBadgeClass(item.level)">
												{{ item.level }}
											</span>
											<span class="small text-muted">{{ item.label }}</span>
										</div>
										<div class="d-flex align-items-center gap-2">
											<span class="fw-bold">{{ item.count }}</span>
											<span class="small text-muted">({{ item.percent }}%)</span>
										</div>
									</div>
									<div class="progress" style="height: 6px;">
										<div
											class="progress-bar"
											:style="{ width: item.percent + '%', background: item.color }"
										></div>
									</div>
								</div>
							</div>

							<div v-if="!riskDistribution.length" class="text-center text-muted py-3">
								<span class="small">{{ $t('common.noData') }}</span>
							</div>
						</div>
					</div>
				</div>

				<!-- Trust Label Distribution -->
				<div class="col-lg-6">
					<div class="card border-0 shadow-sm h-100">
						<div class="card-header bg-white border-bottom py-3">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-shield-halved text-success me-2"></i>
								{{ $t('trustEval.dashboard.trustDistribution') }}
							</h6>
						</div>
						<div class="card-body">
							<div class="trust-dist-list">
								<div
									v-for="item in trustDistribution"
									:key="item.label"
									class="trust-dist-item"
								>
									<div class="d-flex align-items-center justify-content-between mb-1">
										<div class="d-flex align-items-center gap-2">
											<span class="badge" :class="trustLabelBadgeClass(item.label)">
												{{ item.shortLabel }}
											</span>
										</div>
										<div class="d-flex align-items-center gap-2">
											<span class="fw-bold">{{ item.count }}</span>
											<span class="small text-muted">({{ item.percent }}%)</span>
										</div>
									</div>
									<div class="progress" style="height: 6px;">
										<div
											class="progress-bar"
											:style="{ width: item.percent + '%', background: item.color }"
										></div>
									</div>
								</div>
							</div>

							<div v-if="!trustDistribution.length" class="text-center text-muted py-3">
								<span class="small">{{ $t('common.noData') }}</span>
							</div>
						</div>
					</div>
				</div>

				<!-- Recommended Actions -->
				<div class="col-lg-6">
					<div class="card border-0 shadow-sm h-100">
						<div class="card-header bg-white border-bottom py-3">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-gavel text-info me-2"></i>
								{{ $t('trustEval.dashboard.recommendedActions') }}
							</h6>
						</div>
						<div class="card-body">
							<div class="actions-list">
								<div
									v-for="item in actionDistribution"
									:key="item.action"
									class="action-item"
								>
									<div class="action-badge-wrapper">
										<span class="badge rounded-pill" :class="actionBadgeClass(item.action)">
											<i :class="actionIcon(item.action)" class="me-1"></i>
											{{ actionLabel(item.action) }}
										</span>
									</div>
									<div class="d-flex align-items-center gap-2">
										<span class="fw-bold">{{ item.count }}</span>
										<span class="small text-muted">({{ item.percent }}%)</span>
									</div>
								</div>
							</div>

							<div v-if="!actionDistribution.length" class="text-center text-muted py-3">
								<span class="small">{{ $t('common.noData') }}</span>
							</div>
						</div>
					</div>
				</div>

				<!-- Evaluation Source -->
				<div class="col-lg-6">
					<div class="card border-0 shadow-sm h-100">
						<div class="card-header bg-white border-bottom py-3">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-server text-secondary me-2"></i>
								{{ $t('trustEval.dashboard.evaluationSource') }}
							</h6>
						</div>
						<div class="card-body">
							<div class="source-list">
								<div
									v-for="item in sourceDistribution"
									:key="item.source"
									class="source-item"
								>
									<div class="d-flex align-items-center gap-2 mb-1">
										<span class="badge rounded-pill" :class="item.source === 'ml_service' ? 'bg-primary' : 'bg-secondary'">
											<i :class="item.source === 'ml_service' ? 'fa-solid fa-brain' : 'fa-solid fa-rule'" class="me-1"></i>
											{{ item.source === 'ml_service' ? $t('trustEval.dashboard.mlService') : $t('trustEval.dashboard.fallback') }}
										</span>
									</div>
									<div class="d-flex align-items-center gap-2">
										<div class="progress flex-grow-1" style="height: 8px;">
											<div
												class="progress-bar"
												:style="{ width: item.percent + '%', background: item.source === 'ml_service' ? '#0d6efd' : '#6c757d' }"
											></div>
										</div>
										<span class="fw-bold" style="min-width: 30px; text-align: right;">{{ item.count }}</span>
									</div>
								</div>
							</div>

							<div class="mt-3 pt-3 border-top">
								<div class="d-flex justify-content-between small text-muted">
									<span>{{ $t('trustEval.dashboard.totalEvaluations') }}:</span>
									<span class="fw-bold">{{ stats.total_evaluations || 0 }}</span>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Recent High-Risk Campaigns -->
				<div class="col-12">
					<div class="card border-0 shadow-sm">
						<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-triangle-exclamation text-danger me-2"></i>
								{{ $t('trustEval.dashboard.recentHighRisk') }}
							</h6>
							<span class="badge bg-danger">{{ recentHighRisk.length }}</span>
						</div>
						<div class="card-body p-0">
							<div v-if="recentHighRisk.length" class="table-responsive">
								<table class="table table-hover align-middle mb-0">
									<thead class="table-light">
										<tr>
											<th>{{ $t('trustEval.dashboard.table.campaign') }}</th>
											<th class="text-center">{{ $t('trustEval.dashboard.table.riskLevel') }}</th>
											<th class="text-center">{{ $t('trustEval.dashboard.table.trustScore') }}</th>
											<th class="text-center">{{ $t('trustEval.dashboard.table.anomaly') }}</th>
											<th class="text-center">{{ $t('trustEval.dashboard.table.evaluatedAt') }}</th>
										</tr>
									</thead>
									<tbody>
										<tr
											v-for="item in recentHighRisk"
											:key="item.campaign_id"
											class="high-risk-row"
											:class="{ 'anomaly-row': item.is_anomaly }"
										>
											<td class="ps-4">
												<div class="d-flex align-items-center gap-2">
													<i v-if="item.is_anomaly" class="fa-solid fa-flash text-warning"></i>
													<span class="fw-semibold small">{{ item.tieu_de || $t('trustEval.dashboard.campaignId', { id: item.campaign_id }) }}</span>
												</div>
											</td>
											<td class="text-center">
												<span class="badge" :class="riskLevelBadgeClass(item.risk_level)">
													{{ item.risk_level }}
												</span>
											</td>
											<td class="text-center">
												<span
													class="fw-bold small"
													:class="trustScoreValueClass(item.trust_score)"
												>
													{{ item.trust_score?.toFixed(3) || '—' }}
												</span>
											</td>
											<td class="text-center">
												<span v-if="item.is_anomaly" class="badge bg-warning text-dark">
													<i class="fa-solid fa-flash me-1"></i>{{ $t('trustEval.dashboard.yes') }}
												</span>
												<span v-else class="text-muted small">—</span>
											</td>
											<td class="text-center text-muted small">
												{{ formatDateTime(item.evaluated_at) }}
											</td>
										</tr>
									</tbody>
								</table>
							</div>
							<div v-else class="text-center text-muted py-4">
								<i class="fa-solid fa-check-circle text-success d-block fs-3 mb-2 opacity-25"></i>
								<span class="small">{{ $t('trustEval.dashboard.noHighRisk') }}</span>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
import * as trustEvalApi from '../../../services/trustEvalApi';

export default {
	name: 'TrustEvalDashboard',
	props: {
		toast: { type: Object, default: null },
	},
	data() {
		return {
			loading: false,
			stats: {},
			mlHealth: { healthy: false },
		};
	},
	computed: {
		kpis() {
			return [
				{
					label: this.$t('trustEval.dashboard.kpis.totalEvaluations'),
					value: this.stats.total_evaluations || 0,
					subValue: null,
					icon: 'fa-solid fa-shield-halved',
					color: '#0d6efd',
					bgColor: 'rgba(13,110,253,0.1)',
				},
				{
					label: this.$t('trustEval.dashboard.kpis.avgTrustScore'),
					value: this.stats.avg_trust_score != null
						? this.stats.avg_trust_score.toFixed(3)
						: '—',
					subValue: this.stats.avg_trust_score != null
						? this.trustScoreValueLabel(this.stats.avg_trust_score)
						: null,
					icon: 'fa-solid fa-chart-line',
					color: this.avgTrustColor,
					bgColor: this.avgTrustBgColor,
				},
				{
					label: this.$t('trustEval.dashboard.kpis.avgRiskScore'),
					value: this.stats.avg_risk_score != null
						? this.stats.avg_risk_score.toFixed(3)
						: '—',
					subValue: null,
					icon: 'fa-solid fa-chart-line',
					color: this.avgRiskColor,
					bgColor: this.avgRiskBgColor,
				},
				{
					label: this.$t('trustEval.dashboard.kpis.highRiskCount'),
					value: this.highRiskCount,
					subValue: this.highRiskPercent > 0
						? `${this.highRiskPercent}% ${this.$t('trustEval.dashboard.kpis.ofTotal')}`
						: null,
					icon: 'fa-solid fa-triangle-exclamation',
					color: '#dc3545',
					bgColor: 'rgba(220,53,69,0.1)',
				},
			];
		},
		riskDistribution() {
			const levels = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
			const colors = { LOW: '#198754', MEDIUM: '#f59f00', HIGH: '#dc3545', CRITICAL: '#7b1fa2' };
			const labels = {
				LOW: this.$t('trustEval.dashboard.riskLevels.low'),
				MEDIUM: this.$t('trustEval.dashboard.riskLevels.medium'),
				HIGH: this.$t('trustEval.dashboard.riskLevels.high'),
				CRITICAL: this.$t('trustEval.dashboard.riskLevels.critical'),
			};
			const total = Object.values(this.stats.by_risk_level || {}).reduce((s, v) => s + v, 0) || 1;
			return levels.map(level => ({
				level,
				label: labels[level],
				color: colors[level],
				count: this.stats.by_risk_level?.[level] || 0,
				percent: total > 0 ? Math.round(((this.stats.by_risk_level?.[level] || 0) / total) * 100) : 0,
			})).filter(item => item.count > 0);
		},
		trustDistribution() {
			const labels = {
				RELIABLE_HIGH: { short: 'R_HIGH', label: this.$t('trustEval.labels.reliableHigh') },
				RELIABLE: { short: 'RELIABLE', label: this.$t('trustEval.labels.reliable') },
				NEUTRAL: { short: 'NEUTRAL', label: this.$t('trustEval.labels.neutral') },
				SUSPICIOUS: { short: 'SUSPIC.', label: this.$t('trustEval.labels.suspicious') },
				SUSPICIOUS_HIGH: { short: 'S_HIGH', label: this.$t('trustEval.labels.suspiciousHigh') },
			};
			const colors = {
				RELIABLE_HIGH: '#198754',
				RELIABLE: '#0d6efd',
				NEUTRAL: '#f59f00',
				SUSPICIOUS: '#fd7e14',
				SUSPICIOUS_HIGH: '#dc3545',
			};
			const total = Object.values(this.stats.by_trust_label || {}).reduce((s, v) => s + v, 0) || 1;
			return Object.entries(labels).map(([key, meta]) => ({
				label: key,
				shortLabel: meta.short,
				label_full: meta.label,
				color: colors[key],
				count: this.stats.by_trust_label?.[key] || 0,
				percent: total > 0 ? Math.round(((this.stats.by_trust_label?.[key] || 0) / total) * 100) : 0,
			})).filter(item => item.count > 0);
		},
		actionDistribution() {
			const actions = ['APPROVE', 'APPROVE_WITH_NOTE', 'REQUEST_ADDITIONAL_INFO', 'REJECT'];
			const total = Object.values(this.stats.by_recommended_action || {}).reduce((s, v) => s + v, 0) || 1;
			return actions.map(action => ({
				action,
				count: this.stats.by_recommended_action?.[action] || 0,
				percent: total > 0 ? Math.round(((this.stats.by_recommended_action?.[action] || 0) / total) * 100) : 0,
			})).filter(item => item.count > 0);
		},
		sourceDistribution() {
			const sources = ['ml_service', 'fallback'];
			const total = Object.values(this.stats.by_evaluation_source || {}).reduce((s, v) => s + v, 0) || 1;
			return sources.map(source => ({
				source,
				count: this.stats.by_evaluation_source?.[source] || 0,
				percent: total > 0 ? Math.round(((this.stats.by_evaluation_source?.[source] || 0) / total) * 100) : 0,
			})).filter(item => item.count > 0);
		},
		recentHighRisk() {
			return this.stats.recent_high_risk || [];
		},
		highRiskCount() {
			return (this.stats.by_risk_level?.HIGH || 0) + (this.stats.by_risk_level?.CRITICAL || 0);
		},
		highRiskPercent() {
			const total = this.stats.total_evaluations || 0;
			if (!total) return 0;
			return Math.round((this.highRiskCount / total) * 100);
		},
		avgTrustColor() {
			if (this.stats.avg_trust_score == null) return '#6c757d';
			if (this.stats.avg_trust_score >= 0.7) return '#198754';
			if (this.stats.avg_trust_score >= 0.4) return '#f59f00';
			return '#dc3545';
		},
		avgTrustBgColor() {
			if (this.stats.avg_trust_score == null) return 'rgba(108,117,125,0.1)';
			if (this.stats.avg_trust_score >= 0.7) return 'rgba(25,135,84,0.1)';
			if (this.stats.avg_trust_score >= 0.4) return 'rgba(245,159,0,0.1)';
			return 'rgba(220,53,69,0.1)';
		},
		avgRiskColor() {
			if (this.stats.avg_risk_score == null) return '#6c757d';
			if (this.stats.avg_risk_score >= 0.7) return '#dc3545';
			if (this.stats.avg_risk_score >= 0.4) return '#f59f00';
			return '#198754';
		},
		avgRiskBgColor() {
			if (this.stats.avg_risk_score == null) return 'rgba(108,117,125,0.1)';
			if (this.stats.avg_risk_score >= 0.7) return 'rgba(220,53,69,0.1)';
			if (this.stats.avg_risk_score >= 0.4) return 'rgba(245,159,0,0.1)';
			return 'rgba(25,135,84,0.1)';
		},
	},
	async mounted() {
		await this.loadAll();
	},
	methods: {
		async loadAll() {
			this.loading = true;
			try {
				const [statsData, healthData] = await Promise.all([
					trustEvalApi.getStatistics(),
					trustEvalApi.getMlServiceHealth(),
				]);
				this.stats = statsData;
				this.mlHealth = healthData;
			} catch (err) {
				if (this.toast) {
					this.toast.showToast?.('error', this.$t('common.error'), this.$t('trustEval.dashboard.loadError'));
				}
			} finally {
				this.loading = false;
			}
		},
		riskLevelBadgeClass(level) {
			const map = {
				LOW: 'bg-success-subtle text-success',
				MEDIUM: 'bg-warning-subtle text-warning',
				HIGH: 'bg-danger-subtle text-danger',
				CRITICAL: 'bg-danger fw-bold',
			};
			return map[level] || 'bg-secondary';
		},
		trustLabelBadgeClass(label) {
			const map = {
				RELIABLE_HIGH: 'bg-success-subtle text-success',
				RELIABLE: 'bg-info-subtle text-info',
				NEUTRAL: 'bg-warning-subtle text-warning',
				SUSPICIOUS: 'bg-orange-subtle text-orange',
				SUSPICIOUS_HIGH: 'bg-danger-subtle text-danger',
			};
			return map[label] || 'bg-secondary';
		},
		trustScoreValueClass(score) {
			if (score == null) return 'text-muted';
			if (score >= 0.7) return 'text-success';
			if (score >= 0.4) return 'text-warning';
			return 'text-danger';
		},
		trustScoreValueLabel(score) {
			if (score >= 0.7) return this.$t('trustEval.dashboard.kpis.highTrust');
			if (score >= 0.4) return this.$t('trustEval.dashboard.kpis.mediumTrust');
			return this.$t('trustEval.dashboard.kpis.lowTrust');
		},
		actionBadgeClass(action) {
			const map = {
				APPROVE: 'bg-success-subtle text-success',
				APPROVE_WITH_NOTE: 'bg-warning-subtle text-warning',
				REQUEST_ADDITIONAL_INFO: 'bg-info-subtle text-info',
				REJECT: 'bg-danger-subtle text-danger',
			};
			return map[action] || 'bg-secondary';
		},
		actionIcon(action) {
			const icons = {
				APPROVE: 'fa-solid fa-circle-check',
				APPROVE_WITH_NOTE: 'fa-solid fa-circle-exclamation',
				REQUEST_ADDITIONAL_INFO: 'fa-solid fa-circle-info',
				REJECT: 'fa-solid fa-circle-xmark',
			};
			return icons[action] || 'fa-solid fa-circle';
		},
		actionLabel(action) {
			const labels = {
				APPROVE: this.$t('trustEval.decision.actions.approve'),
				APPROVE_WITH_NOTE: this.$t('trustEval.decision.actions.approveWithNote'),
				REQUEST_ADDITIONAL_INFO: this.$t('trustEval.decision.actions.requestInfo'),
				REJECT: this.$t('trustEval.decision.actions.reject'),
			};
			return labels[action] || action;
		},
		formatDateTime(value) {
			if (!value) return '—';
			const date = new Date(value);
			if (Number.isNaN(date.getTime())) return value;
			return date.toLocaleDateString('vi-VN') + ' ' + date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
		},
	},
};
</script>

<style scoped>
.trust-eval-dashboard {
	padding: 0.5rem 0;
}

.kpi-card {
	border-radius: 14px;
	transition: transform 0.2s ease;
}

.kpi-card:hover {
	transform: translateY(-2px);
}

.kpi-icon {
	width: 40px;
	height: 40px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 16px;
}

.risk-dist-list,
.trust-dist-list,
.actions-list,
.source-list {
	display: flex;
	flex-direction: column;
	gap: 0.875rem;
}

.risk-dist-item,
.trust-dist-item {
	width: 100%;
}

.action-item {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 1rem;
}

.source-item {
	padding: 0.5rem 0;
}

.high-risk-row:hover {
	background: rgba(220, 53, 69, 0.03);
}

.anomaly-row {
	background: rgba(255, 193, 7, 0.04);
}

/* Color utilities */
.bg-orange-subtle { background-color: rgba(253,126,20,0.1) !important; }
.text-orange { color: #fd7e14 !important; }
.bg-danger-subtle { background-color: rgba(220,53,69,0.1) !important; }
.bg-warning-subtle { background-color: rgba(245,159,0,0.1) !important; }
.bg-info-subtle { background-color: rgba(13,110,253,0.1) !important; }
.bg-success-subtle { background-color: rgba(25,135,84,0.1) !important; }

.ml-health-dot {
	width: 8px;
	height: 8px;
	border-radius: 50%;
	display: inline-block;
}
.ml-health-dot.healthy {
	background: #198754;
	box-shadow: 0 0 4px #198754;
}
.ml-health-dot.unhealthy {
	background: #dc3545;
	box-shadow: 0 0 4px #dc3545;
}
</style>
