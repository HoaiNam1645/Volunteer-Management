<template>
	<div class="volunteer-trust-panel">
		<!-- Header -->
		<div class="panel-header d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
			<div>
				<h5 class="fw-bold mb-1">
					<i class="fa-solid fa-user-check text-primary me-2"></i>
					{{ $t('trustEval.volunteer.title') }}
				</h5>
				<p class="text-muted mb-0 small">{{ $t('trustEval.volunteer.subtitle') }}</p>
			</div>
		</div>

		<!-- Loading -->
		<div v-if="loading" class="text-center py-5">
			<div class="spinner-border text-primary mb-3"></div>
			<div class="text-muted">{{ $t('common.loading') }}</div>
		</div>

		<!-- Error -->
		<div v-else-if="error" class="alert alert-danger border-0 shadow-sm">
			<div class="d-flex align-items-start gap-3">
				<i class="fa-solid fa-circle-exclamation text-danger fs-5 mt-1"></i>
				<div>
					<div class="fw-bold">{{ $t('trustEval.panel.errorTitle') }}</div>
					<div class="small">{{ error }}</div>
				</div>
			</div>
		</div>

		<!-- Content -->
		<div v-else-if="evaluation" class="eval-content">
			<!-- Source & Time -->
			<div class="eval-source-badge mb-3">
				<span class="badge rounded-pill" :class="evaluation.evaluation_source === 'ml_service' ? 'bg-primary' : 'bg-secondary'">
					<i :class="evaluation.evaluation_source === 'ml_service' ? 'fa-solid fa-brain' : 'fa-solid fa-rule'" class="me-1"></i>
					{{ evaluation.evaluation_source === 'ml_service' ? $t('trustEval.panel.sourceML') : $t('trustEval.panel.sourceFallback') }}
				</span>
				<span class="text-muted small ms-2">
					<i class="fa-solid fa-clock me-1"></i>
					{{ formatDateTime(evaluation.evaluation_timestamp) }}
				</span>
			</div>

			<div class="row g-3">
				<!-- LEFT: Trust Score + Reliability -->
				<div class="col-lg-5">
					<!-- Trust Score Card -->
					<div class="eval-card mb-3">
						<div class="eval-card-header">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-chart-line text-primary me-2"></i>
								{{ $t('trustEval.panel.trustScore') }}
							</h6>
						</div>
						<div class="eval-card-body">
							<!-- Score Circle -->
							<div class="d-flex justify-content-center mb-3">
								<div class="text-center">
									<div class="eval-score-circle" :style="trustScoreCircleStyle">
										<span class="eval-score-value">{{ formatScore(evaluation.trust_score?.calibrated_probability) }}</span>
									</div>
									<div class="small text-muted mt-1">{{ $t('trustEval.volunteer.trustScoreLabel') }}</div>
								</div>
							</div>

							<!-- Trust Label -->
							<div class="d-flex align-items-center justify-content-center gap-2 mb-3">
								<span class="badge rounded-pill fs-6" :class="trustLabelBadgeClass">
									{{ trustLabelText }}
								</span>
							</div>

							<!-- Confidence -->
							<div class="text-center">
								<div class="small text-muted">{{ $t('trustEval.panel.confidence') }}:</div>
								<div class="fw-bold" :style="{ color: confidenceColor }">
									{{ confidenceText }}
								</div>
							</div>
						</div>
					</div>

					<!-- Reliability Summary Card -->
					<div class="eval-card mb-3" v-if="evaluation.reliability_summary">
						<div class="eval-card-header">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-chart-mixed text-info me-2"></i>
								{{ $t('trustEval.volunteer.reliabilityTitle') }}
							</h6>
						</div>
						<div class="eval-card-body">
							<!-- Registration Stats -->
							<div class="reliability-stats">
								<div class="rel-stat-row">
									<div class="rel-stat-icon bg-primary-subtle text-primary">
										<i class="fa-solid fa-clipboard-list"></i>
									</div>
									<div class="rel-stat-content">
										<div class="text-muted small">{{ $t('trustEval.volunteer.totalRegistrations') }}</div>
										<div class="fw-bold">{{ evaluation.reliability_summary.total_registrations }}</div>
									</div>
								</div>

								<div class="rel-stat-row">
									<div class="rel-stat-icon" :class="cancelledIconClass">
										<i class="fa-solid fa-xmark-circle"></i>
									</div>
									<div class="rel-stat-content">
										<div class="text-muted small">{{ $t('trustEval.volunteer.cancelledRegistrations') }}</div>
										<div class="fw-bold">{{ evaluation.reliability_summary.cancelled_registrations }}</div>
									</div>
								</div>

								<div class="rel-stat-row">
									<div class="rel-stat-icon" :class="cancelRateIconClass">
										<i class="fa-solid fa-chart-pie"></i>
									</div>
									<div class="rel-stat-content">
										<div class="text-muted small">{{ $t('trustEval.volunteer.cancellationRate') }}</div>
										<div class="fw-bold" :class="cancelRateValueClass">
											{{ formatPercent(evaluation.reliability_summary.cancellation_rate) }}
										</div>
									</div>
								</div>

								<div class="rel-stat-row">
									<div class="rel-stat-icon bg-success-subtle text-success">
										<i class="fa-solid fa-circle-check"></i>
									</div>
									<div class="rel-stat-content">
										<div class="text-muted small">{{ $t('trustEval.volunteer.completionRate') }}</div>
										<div class="fw-bold text-success">
											{{ formatPercent(evaluation.reliability_summary.completion_rate) }}
										</div>
									</div>
								</div>
							</div>

							<!-- Rating -->
							<div v-if="evaluation.reliability_summary.avg_rating_received !== null" class="rating-row mt-2 pt-2 border-top">
								<div class="d-flex align-items-center gap-3">
									<div class="d-flex align-items-center gap-1">
										<i class="fa-solid fa-star text-warning"></i>
										<span class="fw-bold">{{ evaluation.reliability_summary.avg_rating_received.toFixed(1) }}</span>
										<span class="text-muted small">/ 5.0</span>
									</div>
									<span class="text-muted small">({{ evaluation.reliability_summary.rating_count }} {{ $t('trustEval.volunteer.ratings') }})</span>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- RIGHT: Behavior Flags + SHAP -->
				<div class="col-lg-7">
					<!-- Behavior Flags -->
					<div class="eval-card mb-3" v-if="evaluation.behavior_flags?.length">
						<div class="eval-card-header d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-flag text-warning me-2"></i>
								{{ $t('trustEval.volunteer.behaviorFlags') }}
							</h6>
							<span class="badge bg-warning text-dark">{{ evaluation.behavior_flags.length }}</span>
						</div>
						<div class="eval-card-body">
							<div class="d-flex flex-column gap-2">
								<div
									v-for="flag in evaluation.behavior_flags"
									:key="flag.code"
									class="behavior-flag-item"
									:class="'severity-' + flag.severity.toLowerCase()"
								>
									<div class="d-flex align-items-start gap-2">
										<span class="badge flex-shrink-0" :class="severityBadgeClass(flag.severity)">
											{{ flag.severity }}
										</span>
										<div class="flex-grow-1">
											<div class="fw-semibold small">{{ flag.message }}</div>
											<div v-if="flag.suggestion" class="small text-muted mt-1">
												<i class="fa-solid fa-lightbulb text-warning me-1"></i>{{ flag.suggestion }}
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>

					<!-- No Flags -->
					<div v-else class="eval-card mb-3">
						<div class="eval-card-body text-center py-4 text-muted">
							<i class="fa-solid fa-circle-check text-success d-block fs-3 mb-2 opacity-25"></i>
							<span class="small">{{ $t('trustEval.risk.noFlags') }}</span>
						</div>
					</div>

					<!-- SHAP Explanation -->
					<div class="eval-card mb-3" v-if="evaluation.shap_explanation">
						<div class="eval-card-body">
							<SHAPExplanation
								:shap="evaluation.shap_explanation"
								score-type="probability"
							/>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Empty -->
		<div v-else class="eval-empty text-center py-5">
			<i class="fa-solid fa-user-shield text-muted d-block mb-3" style="font-size: 48px; opacity: 0.25;"></i>
			<h6 class="text-muted">{{ $t('trustEval.volunteer.noEvaluation') }}</h6>
			<p class="text-muted small">{{ $t('trustEval.volunteer.noEvaluationDesc') }}</p>
		</div>
	</div>
</template>

<script>
import SHAPExplanation from './SHAPExplanation.vue';
import * as trustEvalApi from '../../../services/trustEvalApi';

export default {
	name: 'VolunteerTrustPanel',
	components: { SHAPExplanation },
	props: {
		volunteerId: {
			type: Number,
			required: true,
		},
	},
	data() {
		return {
			evaluation: null,
			loading: false,
			error: null,
		};
	},
	computed: {
		trustScoreCircleStyle() {
			const score = this.evaluation?.trust_score?.calibrated_probability ?? 0.5;
			const color = this.getScoreColor(score, 'trust');
			return {
				'--score-color': color,
				background: `conic-gradient(${color} ${score * 360}deg, #e9ecef 0deg)`,
			};
		},
		trustLabelBadgeClass() {
			const map = {
				RELIABLE_HIGH: 'bg-success-subtle text-success border border-success',
				RELIABLE: 'bg-info-subtle text-info border border-info',
				NEUTRAL: 'bg-warning-subtle text-warning border border-warning',
				SUSPICIOUS: 'bg-orange-subtle text-orange border border-orange',
				SUSPICIOUS_HIGH: 'bg-danger-subtle text-danger border border-danger',
			};
			return map[this.evaluation?.trust_score?.label] || 'bg-secondary';
		},
		trustLabelText() {
			const labels = {
				RELIABLE_HIGH: this.$t('trustEval.labels.reliableHigh'),
				RELIABLE: this.$t('trustEval.labels.reliable'),
				NEUTRAL: this.$t('trustEval.labels.neutral'),
				SUSPICIOUS: this.$t('trustEval.labels.suspicious'),
				SUSPICIOUS_HIGH: this.$t('trustEval.labels.suspiciousHigh'),
			};
			return labels[this.evaluation?.trust_score?.label] || this.evaluation?.trust_score?.label || '—';
		},
		confidenceColor() {
			const colors = { HIGH: '#198754', MEDIUM: '#f59f00', LOW: '#dc3545' };
			return colors[this.evaluation?.trust_score?.confidence] || '#6c757d';
		},
		confidenceText() {
			const labels = { HIGH: 'Cao', MEDIUM: 'Trung bình', LOW: 'Thấp' };
			return labels[this.evaluation?.trust_score?.confidence] || '—';
		},
		cancelledIconClass() {
			const rate = this.evaluation?.reliability_summary?.cancellation_rate ?? 0;
			return rate > 0.3 ? 'bg-danger-subtle text-danger' : 'bg-secondary-subtle text-secondary';
		},
		cancelRateIconClass() {
			const rate = this.evaluation?.reliability_summary?.cancellation_rate ?? 0;
			return rate > 0.3 ? 'bg-danger-subtle text-danger' : 'bg-secondary-subtle text-secondary';
		},
		cancelRateValueClass() {
			const rate = this.evaluation?.reliability_summary?.cancellation_rate ?? 0;
			return rate > 0.3 ? 'text-danger' : rate > 0.1 ? 'text-warning' : 'text-success';
		},
	},
	async mounted() {
		await this.loadEvaluation();
	},
	methods: {
		async loadEvaluation() {
			this.loading = true;
			this.error = null;
			try {
				this.evaluation = await trustEvalApi.getVolunteerEvaluation(this.volunteerId);
			} catch (err) {
				this.error = err.response?.data?.message || err.message || this.$t('trustEval.panel.loadError');
			} finally {
				this.loading = false;
			}
		},
		severityBadgeClass(severity) {
			const map = {
				CRITICAL: 'bg-danger',
				HIGH: 'bg-warning text-dark',
				MEDIUM: 'bg-info text-white',
				LOW: 'bg-secondary text-white',
			};
			return map[severity] || 'bg-secondary';
		},
		formatScore(value) {
			if (value === null || value === undefined) return '—';
			return Number(value).toFixed(3);
		},
		formatPercent(value) {
			if (value === null || value === undefined) return '—';
			return (Number(value) * 100).toFixed(1) + '%';
		},
		formatDateTime(value) {
			if (!value) return '—';
			const date = new Date(value);
			if (Number.isNaN(date.getTime())) return value;
			return date.toLocaleDateString('vi-VN') + ' ' + date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
		},
		getScoreColor(value, type) {
			if (value === null || value === undefined) return '#adb5bd';
			if (type === 'trust') {
				if (value >= 0.7) return '#198754';
				if (value >= 0.4) return '#f59f00';
				return '#dc3545';
			}
			return '#6c757d';
		},
	},
};
</script>

<style scoped>
.volunteer-trust-panel {
	padding: 0.5rem 0;
}

.eval-card {
	background: #fff;
	border: 1px solid #e9ecef;
	border-radius: 12px;
	overflow: hidden;
}

.eval-card-header {
	padding: 0.75rem 1rem;
	background: #f8f9fa;
	border-bottom: 1px solid #e9ecef;
}

.eval-card-body {
	padding: 1rem;
}

.eval-score-circle {
	width: 100px;
	height: 100px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	position: relative;
	font-size: 0;
}

.eval-score-circle::before {
	content: '';
	position: absolute;
	inset: 8px;
	background: #fff;
	border-radius: 50%;
}

.eval-score-value {
	position: relative;
	font-size: 18px;
	font-weight: 700;
	color: var(--score-color, #6c757d);
}

.reliability-stats {
	display: flex;
	flex-direction: column;
	gap: 0.75rem;
}

.rel-stat-row {
	display: flex;
	align-items: center;
	gap: 0.75rem;
}

.rel-stat-icon {
	width: 36px;
	height: 36px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 14px;
	flex-shrink: 0;
}

.rel-stat-content {
	flex-grow: 1;
}

.behavior-flag-item {
	border-radius: 8px;
	padding: 0.625rem 0.75rem;
	background: #fff;
	border: 1px solid #e9ecef;
}

.severity-critical { border-left: 3px solid #dc3545; }
.severity-high { border-left: 3px solid #fd7e14; }
.severity-medium { border-left: 3px solid #f59f00; }
.severity-low { border-left: 3px solid #adb5bd; }

.eval-empty { padding: 2rem 0; }

/* Color utilities */
.bg-orange-subtle { background-color: rgba(253,126,20,0.1) !important; }
.text-orange { color: #fd7e14 !important; }
.border-orange { border-color: #fd7e14 !important; }
.bg-danger-subtle { background-color: rgba(220,53,69,0.1) !important; }
.bg-warning-subtle { background-color: rgba(245,159,0,0.1) !important; }
.bg-info-subtle { background-color: rgba(13,110,253,0.1) !important; }
.bg-success-subtle { background-color: rgba(25,135,84,0.1) !important; }
.bg-secondary-subtle { background-color: rgba(108,117,125,0.1) !important; }
</style>
