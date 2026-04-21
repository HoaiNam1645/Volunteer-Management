<template>
	<div class="trust-eval-panel" v-if="isVisible">
		<!-- Header -->
		<div class="panel-header d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
			<div>
				<h5 class="fw-bold mb-1">
					<i class="fa-solid fa-shield-halved text-primary me-2"></i>
					{{ $t('trustEval.panel.title') }}
				</h5>
				<p class="text-muted mb-0 small">{{ $t('trustEval.panel.subtitle') }}</p>
			</div>
			<div class="d-flex align-items-center gap-2">
				<!-- ML Service Health Indicator -->
				<div class="d-flex align-items-center gap-1 small">
					<span class="ml-health-dot" :class="mlHealth.healthy ? 'healthy' : 'unhealthy'"></span>
					<span class="text-muted">{{ mlHealth.healthy ? 'ML Service' : 'ML Service offline' }}</span>
				</div>
				<!-- Refresh Button -->
				<button
					class="btn btn-sm btn-outline-primary rounded-pill"
					@click="handleRefresh"
					:disabled="loading"
				>
					<i class="fa-solid fa-rotate-right me-1" :class="loading ? 'fa-spin' : ''"></i>
					{{ loading ? $t('common.processing') : $t('trustEval.panel.refresh') }}
				</button>
			</div>
		</div>

		<!-- Loading State -->
		<div v-if="loading" class="eval-loading text-center py-5">
			<div class="spinner-border text-primary mb-3"></div>
			<div class="text-muted">{{ $t('trustEval.panel.loading') }}</div>
		</div>

		<!-- Error State -->
		<div v-else-if="error" class="eval-error alert alert-danger border-0 shadow-sm">
			<div class="d-flex align-items-start gap-3">
				<i class="fa-solid fa-circle-exclamation text-danger fs-5 mt-1"></i>
				<div>
					<div class="fw-bold">{{ $t('trustEval.panel.errorTitle') }}</div>
					<div class="small">{{ error }}</div>
				</div>
			</div>
		</div>

		<!-- Evaluation Content -->
		<div v-else-if="evaluation" class="eval-content">
			<!-- Evaluation Source Badge -->
			<div class="eval-source-badge mb-3">
				<span
					class="badge rounded-pill"
					:class="evaluation.evaluation_source === 'ml_service' ? 'bg-primary' : 'bg-secondary'"
				>
					<i :class="evaluation.evaluation_source === 'ml_service' ? 'fa-solid fa-brain' : 'fa-solid fa-rule'" class="me-1"></i>
					{{ evaluation.evaluation_source === 'ml_service'
						? $t('trustEval.panel.sourceML')
						: $t('trustEval.panel.sourceFallback') }}
				</span>
				<span class="text-muted small ms-2">
					<i class="fa-solid fa-clock me-1"></i>
					{{ formatDateTime(evaluation.evaluation_timestamp) }}
				</span>
			</div>

			<div class="row g-3">
				<!-- LEFT COLUMN: Trust Score + Risk -->
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
							<!-- Score Display -->
							<div class="trust-score-display mb-3">
								<div class="d-flex align-items-center justify-content-center gap-4">
									<div class="text-center">
										<div class="eval-score-circle" :style="trustScoreCircleStyle">
											<span class="eval-score-value">{{ formatScore(evaluation.trust_score?.calibrated_probability) }}</span>
										</div>
										<div class="small text-muted mt-1">{{ $t('trustEval.panel.trustScore') }}</div>
									</div>
									<div class="text-center">
										<div class="eval-score-circle risk-circle" :style="riskScoreCircleStyle">
											<span class="eval-score-value">{{ formatScore(evaluation.risk_assessment?.risk_score) }}</span>
										</div>
										<div class="small text-muted mt-1">{{ $t('trustEval.panel.riskScore') }}</div>
									</div>
								</div>
							</div>

							<!-- Trust Label & Confidence -->
							<div class="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
								<div class="d-flex align-items-center gap-2">
									<span class="badge rounded-pill fs-6" :class="trustLabelBadgeClass">
										{{ trustLabelText }}
									</span>
								</div>
								<div class="text-end">
									<div class="small text-muted">{{ $t('trustEval.panel.confidence') }}:</div>
									<div class="fw-bold" :style="{ color: confidenceColor }">
										{{ confidenceText }}
									</div>
								</div>
							</div>

							<!-- Volunteer Trust Score (if available) -->
							<div v-if="evaluation.volunteer_trust_score" class="volunteer-trust-mini mt-2 pt-2 border-top">
								<div class="d-flex align-items-center justify-content-between">
									<span class="small text-muted">
										<i class="fa-solid fa-users me-1"></i>
										{{ $t('trustEval.panel.volunteerTrust') }}
									</span>
									<div class="d-flex align-items-center gap-2">
										<span class="badge rounded-pill" :class="volunteerTrustBadgeClass">
											{{ volunteerTrustLabel }}
										</span>
									</div>
								</div>
							</div>

							<!-- Model Info -->
							<div v-if="evaluation.model_info?.campaign_model_version" class="model-info-row mt-2 pt-2 border-top">
								<span class="badge bg-light text-muted border small">
									<i class="fa-solid fa-database me-1"></i>
									v{{ evaluation.model_info.campaign_model_version }}
								</span>
							</div>
						</div>
					</div>

					<!-- Risk Assessment Card -->
					<div class="eval-card mb-3" v-if="evaluation.risk_assessment">
						<div class="eval-card-header d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-triangle-exclamation text-danger me-2"></i>
								{{ $t('trustEval.panel.riskAssessment') }}
							</h6>
							<div class="d-flex align-items-center gap-2">
								<span
									class="badge rounded-pill"
									:class="riskLevelBadgeClass"
								>
									{{ evaluation.risk_assessment.overall_risk_level }}
								</span>
								<span v-if="evaluation.risk_assessment.is_anomaly" class="badge bg-dark rounded-pill">
									<i class="fa-solid fa-flash me-1"></i>{{ $t('trustEval.risk.anomaly') }}
								</span>
							</div>
						</div>
						<div class="eval-card-body">
							<!-- Anomaly Detection -->
							<div v-if="evaluation.risk_assessment.is_anomaly" class="anomaly-alert mb-3">
								<div class="d-flex align-items-start gap-2">
									<i class="fa-solid fa-flash text-dark mt-1"></i>
									<div>
										<div class="fw-bold small">{{ $t('trustEval.risk.anomalyDetected') }}</div>
										<div class="small text-muted">
											{{ evaluation.risk_assessment.anomaly_types?.join(', ') || $t('trustEval.risk.unusualPattern') }}
										</div>
									</div>
								</div>
							</div>

							<!-- Risk Flags -->
							<RiskFlagsPanel
								:flags="evaluation.risk_assessment.flags || []"
							/>
						</div>
					</div>

					<!-- Validation Result Card -->
					<div class="eval-card mb-3" v-if="evaluation.validation_result">
						<div class="eval-card-header">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-clipboard-check text-success me-2"></i>
								{{ $t('trustEval.panel.validationResult') }}
							</h6>
						</div>
						<div class="eval-card-body">
							<div class="validation-status">
								<div class="d-flex align-items-center gap-2 mb-2">
									<i
										:class="evaluation.validation_result.passed
											? 'fa-solid fa-circle-check text-success'
											: 'fa-solid fa-circle-xmark text-danger'"
										class="fs-5"
									></i>
									<span class="fw-bold">
										{{ evaluation.validation_result.passed
											? $t('trustEval.validation.passed')
											: $t('trustEval.validation.failed') }}
									</span>
								</div>

								<div v-if="evaluation.validation_result.critical_errors?.length" class="mb-2">
									<div class="small text-muted mb-1">{{ $t('trustEval.validation.criticalErrors') }}:</div>
									<div
										v-for="err in evaluation.validation_result.critical_errors"
										:key="err.code"
										class="small text-danger"
									>
										<i class="fa-solid fa-xmark me-1"></i>{{ err.message }}
									</div>
								</div>

								<div v-if="evaluation.validation_result.warnings?.length">
									<div class="small text-muted mb-1">{{ $t('trustEval.validation.warnings') }}:</div>
									<div
										v-for="warn in evaluation.validation_result.warnings"
										:key="warn.code"
										class="small text-warning"
									>
										<i class="fa-solid fa-exclamation me-1"></i>{{ warn.message }}
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- RIGHT COLUMN: Decision Support + SHAP -->
				<div class="col-lg-7">
					<!-- Decision Support -->
					<div class="eval-card mb-3" v-if="evaluation.decision_support">
						<div class="eval-card-body">
							<DecisionSupport :decision="mergedDecision" />
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

					<!-- Content Analysis -->
					<div class="eval-card mb-3" v-if="evaluation.content_analysis">
						<div class="eval-card-header">
							<h6 class="fw-bold mb-0">
								<i class="fa-solid fa-file-lines text-info me-2"></i>
								{{ $t('trustEval.panel.contentAnalysis') }}
							</h6>
						</div>
						<div class="eval-card-body">
							<div class="row g-2">
								<div class="col-6 col-md-3">
									<div class="content-stat-card">
										<div class="text-muted small">{{ $t('trustEval.content.riskKeywords') }}</div>
										<div class="fw-bold text-danger">
											{{ evaluation.content_analysis.text_risk_keyword_count || 0 }}
										</div>
									</div>
								</div>
								<div class="col-6 col-md-3">
									<div class="content-stat-card">
										<div class="text-muted small">{{ $t('trustEval.content.vagueness') }}</div>
										<div class="fw-bold" :class="scoreClass(evaluation.content_analysis.vagueness_score)">
											{{ formatScore(evaluation.content_analysis.vagueness_score) }}
										</div>
									</div>
								</div>
								<div class="col-6 col-md-3">
									<div class="content-stat-card">
										<div class="text-muted small">{{ $t('trustEval.content.safetyDesc') }}</div>
										<div class="fw-bold text-success">
											{{ formatScore(evaluation.content_analysis.safety_description_score) }}
										</div>
									</div>
								</div>
								<div class="col-6 col-md-3">
									<div class="content-stat-card">
										<div class="text-muted small">{{ $t('trustEval.content.textRiskScore') }}</div>
										<div class="fw-bold" :class="scoreClass(evaluation.content_analysis.text_risk_score)">
											{{ formatScore(evaluation.content_analysis.text_risk_score) }}
										</div>
									</div>
								</div>
							</div>
							<div v-if="evaluation.content_analysis.risk_keywords_found?.length" class="mt-2">
								<div class="small text-muted mb-1">{{ $t('trustEval.content.foundKeywords') }}:</div>
								<div class="d-flex flex-wrap gap-1">
									<span
										v-for="kw in evaluation.content_analysis.risk_keywords_found"
										:key="kw"
										class="badge bg-danger-subtle text-danger border border-danger"
									>
										{{ kw }}
									</span>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Re-evaluation Notification Banner -->
			<div v-if="notificationMessage" class="notification-banner mt-3">
				<div class="d-flex align-items-center gap-3">
					<i :class="notificationType === 'success' ? 'fa-solid fa-circle-check text-success' : 'fa-solid fa-circle-info text-info'"></i>
					<span>{{ notificationMessage }}</span>
					<button class="btn btn-sm btn-link p-0 ms-auto" @click="notificationMessage = null">
						<i class="fa-solid fa-xmark"></i>
					</button>
				</div>
			</div>
		</div>

		<!-- No Evaluation Yet -->
		<div v-else class="eval-empty text-center py-5">
			<i class="fa-solid fa-shield text-muted d-block mb-3" style="font-size: 48px; opacity: 0.25;"></i>
			<h6 class="text-muted">{{ $t('trustEval.panel.notYetEvaluated') }}</h6>
			<p class="text-muted small mb-3">{{ $t('trustEval.panel.notYetEvaluatedDesc') }}</p>
			<button class="btn btn-primary rounded-pill" @click="handleRefresh" :disabled="loading">
				<i class="fa-solid fa-play me-1"></i>
				{{ $t('trustEval.panel.runFirstEval') }}
			</button>
		</div>
	</div>
</template>

<script>
import SHAPExplanation from './SHAPExplanation.vue';
import DecisionSupport from './DecisionSupport.vue';
import RiskFlagsPanel from './RiskFlagsPanel.vue';
import RiskFlagRow from './RiskFlagRow.vue';
import * as trustEvalApi from '../../../services/trustEvalApi';

export default {
	name: 'TrustEvalPanel',
	components: {
		SHAPExplanation,
		DecisionSupport,
		RiskFlagsPanel,
		RiskFlagRow,
	},
	props: {
		campaignId: {
			type: Number,
			required: true,
		},
		initialEvaluation: {
			type: Object,
			default: null,
		},
		autoRunOnMissing: {
			type: Boolean,
			default: true,
		},
	},
	data() {
		return {
			evaluation: null,
			loading: false,
			error: null,
			mlHealth: { healthy: false },
			notificationMessage: null,
			notificationType: 'success',
		};
	},
	computed: {
		isVisible() {
			return true;
		},
		mergedDecision() {
			if (!this.evaluation?.decision_support) return {};
			return {
				...this.evaluation.decision_support,
				_fallback: this.evaluation._fallback || this.evaluation.evaluation_source === 'fallback',
			};
		},
		trustScoreCircleStyle() {
			const score = this.evaluation?.trust_score?.calibrated_probability ?? 0.5;
			const color = this.getScoreColor(score, 'trust');
			const dashOffset = 226 - (score * 226);
			return {
				'--score-color': color,
				background: `conic-gradient(${color} ${score * 360}deg, #e9ecef 0deg)`,
			};
		},
		riskScoreCircleStyle() {
			const score = this.evaluation?.risk_assessment?.risk_score ?? 0;
			const color = this.getScoreColor(score, 'risk');
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
		volunteerTrustBadgeClass() {
			const map = {
				RELIABLE_HIGH: 'bg-success',
				RELIABLE: 'bg-info',
				NEUTRAL: 'bg-warning text-dark',
				SUSPICIOUS: 'bg-orange text-white',
				SUSPICIOUS_HIGH: 'bg-danger',
			};
			return map[this.evaluation?.volunteer_trust_score?.label] || 'bg-secondary';
		},
		volunteerTrustLabel() {
			return this.evaluation?.volunteer_trust_score?.label || '—';
		},
		confidenceColor() {
			const colors = { HIGH: '#198754', MEDIUM: '#f59f00', LOW: '#dc3545' };
			return colors[this.evaluation?.trust_score?.confidence] || '#6c757d';
		},
		confidenceText() {
			const labels = { HIGH: 'Cao', MEDIUM: 'Trung bình', LOW: 'Thấp' };
			return labels[this.evaluation?.trust_score?.confidence] || '—';
		},
		riskLevelBadgeClass() {
			const map = {
				LOW: 'bg-success-subtle text-success border border-success',
				MEDIUM: 'bg-warning-subtle text-warning border border-warning',
				HIGH: 'bg-danger-subtle text-danger border border-danger',
				CRITICAL: 'bg-danger fw-bold',
			};
			return map[this.evaluation?.risk_assessment?.overall_risk_level] || 'bg-secondary';
		},
	},
	watch: {
		campaignId: {
			immediate: true,
			async handler(newId) {
				if (this.initialEvaluation) {
					this.evaluation = this.initialEvaluation;
				}
				if (newId) {
					await this.loadEvaluation(newId);
				}
			},
		},
	},
	async mounted() {
		await this.checkMlHealth();
		if (!this.evaluation) {
			await this.loadEvaluation(this.campaignId);
		}
	},
	methods: {
		async loadEvaluation(campaignId) {
			this.loading = true;
			this.error = null;
			try {
				const eval_ = await trustEvalApi.getCampaignEvaluation(campaignId);
				this.evaluation = eval_;
			} catch (err) {
				if (err.response?.status === 404) {
					this.evaluation = null;
					if (this.autoRunOnMissing && campaignId) {
						await this.runInitialEvaluation(campaignId);
					}
				} else {
					this.error = err.response?.data?.message || err.message || this.$t('trustEval.panel.loadError');
				}
			} finally {
				this.loading = false;
			}
		},
		async runInitialEvaluation(campaignId) {
			try {
				const result = await trustEvalApi.refreshCampaignEvaluation(campaignId);
				this.evaluation = result;
				this.notificationMessage = this.$t('trustEval.panel.refreshSuccess');
				this.notificationType = 'success';
			} catch (err) {
				this.error = err.response?.data?.message || err.message || this.$t('trustEval.panel.refreshError');
			}
		},
		async handleRefresh() {
			this.loading = true;
			this.error = null;
			this.notificationMessage = null;
			try {
				const result = await trustEvalApi.refreshCampaignEvaluation(this.campaignId);
				this.evaluation = result;
				this.notificationMessage = this.$t('trustEval.panel.refreshSuccess');
				this.notificationType = 'success';
			} catch (err) {
				this.notificationMessage = err.response?.data?.message || this.$t('trustEval.panel.refreshError');
				this.notificationType = 'error';
			} finally {
				this.loading = false;
			}
		},
		async checkMlHealth() {
			try {
				this.mlHealth = await trustEvalApi.getMlServiceHealth();
			} catch (_) {
				this.mlHealth = { healthy: false };
			}
		},
		formatScore(value) {
			if (value === null || value === undefined) return '—';
			return Number(value).toFixed(3);
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
			if (type === 'risk') {
				if (value >= 0.7) return '#dc3545';
				if (value >= 0.4) return '#f59f00';
				return '#198754';
			}
			return '#6c757d';
		},
		scoreClass(value) {
			if (value === null || value === undefined) return 'text-muted';
			if (value >= 0.7) return 'text-danger';
			if (value >= 0.4) return 'text-warning';
			return 'text-success';
		},
	},
};
</script>

<style scoped>
.trust-eval-panel {
	padding: 0.5rem 0;
}

.eval-loading {
	padding: 2rem 0;
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

.trust-score-display {
	padding: 0.5rem 0;
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

.eval-source-badge {
	display: flex;
	align-items: center;
	gap: 0.25rem;
}

.anomaly-alert {
	background: #fff3cd;
	border: 1px solid #ffecb5;
	border-radius: 8px;
	padding: 0.625rem 0.75rem;
}

.model-info-row {
	display: flex;
	gap: 0.375rem;
}

.content-stat-card {
	background: #f8f9fa;
	border-radius: 8px;
	padding: 0.625rem;
	text-align: center;
}

.notification-banner {
	background: #d1e7dd;
	border: 1px solid #a3cfbb;
	border-radius: 8px;
	padding: 0.625rem 0.875rem;
	color: #0f5132;
	font-size: 13px;
}

.eval-empty {
	padding: 2rem 0;
}

/* Color variants */
.bg-orange-subtle { background-color: rgba(253,126,20,0.1) !important; }
.text-orange { color: #fd7e14 !important; }
.border-orange { border-color: #fd7e14 !important; }
.bg-danger-subtle { background-color: rgba(220,53,69,0.1) !important; }
.bg-warning-subtle { background-color: rgba(245,159,0,0.1) !important; }
.bg-info-subtle { background-color: rgba(13,110,253,0.1) !important; }
.bg-success-subtle { background-color: rgba(25,135,84,0.1) !important; }

/* ML Health Dot */
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
