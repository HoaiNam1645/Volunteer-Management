<template>
	<div class="shap-explanation">
		<!-- Header with base value and prediction -->
		<div class="shap-header mb-3">
			<div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
				<div>
					<h6 class="fw-bold mb-1">
						<i class="fa-solid fa-chart-bar text-primary me-2"></i>
						{{ $t('trustEval.shap.title') }}
					</h6>
					<p class="text-muted small mb-0">{{ $t('trustEval.shap.subtitle') }}</p>
				</div>
				<div class="text-end">
					<div class="d-flex align-items-center gap-3">
						<div>
							<div class="small text-muted">{{ $t('trustEval.shap.baseValue') }}</div>
							<div class="fw-bold text-secondary">{{ formatScore(shap.base_value) }}</div>
						</div>
						<i class="fa-solid fa-arrow-right text-muted"></i>
						<div>
							<div class="small text-muted">{{ $t('trustEval.shap.prediction') }}</div>
							<div class="fw-bold" :class="predictionColorClass">{{ formatScore(shap.prediction) }}</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Score Bar -->
		<div class="shap-score-bar mb-4">
			<div class="d-flex align-items-center gap-2">
				<span class="small text-muted fw-semibold">0</span>
				<div class="flex-grow-1 position-relative">
					<div class="shap-bar-track">
						<!-- Base value marker -->
						<div
							class="shap-bar-base"
							:style="{ left: baseValuePercent + '%' }"
							:title="$t('trustEval.shap.baseValue') + ': ' + formatScore(shap.base_value)"
						>
							<div class="shap-bar-base-line"></div>
							<div class="shap-bar-base-label">{{ formatScore(shap.base_value) }}</div>
						</div>
						<!-- Prediction marker -->
						<div
							class="shap-bar-prediction"
							:style="{ left: predictionPercent + '%', background: predictionColor }"
							:title="$t('trustEval.shap.prediction') + ': ' + formatScore(shap.prediction)"
						>
							<div class="shap-bar-prediction-dot"></div>
						</div>
						<!-- Contribution fill -->
						<div
							class="shap-bar-fill"
							:style="fillStyle"
						></div>
					</div>
				</div>
				<span class="small text-muted fw-semibold">1</span>
			</div>
		</div>

		<!-- Positive Factors -->
		<div v-if="shap.top_positive_factors && shap.top_positive_factors.length" class="mb-3">
			<div class="fw-semibold small text-success mb-2">
				<i class="fa-solid fa-arrow-up me-1"></i>
				{{ $t('trustEval.shap.positiveFactors') }}
			</div>
			<div class="shap-factors-list">
				<div
					v-for="(factor, idx) in shap.top_positive_factors"
					:key="'pos-' + idx"
					class="shap-factor-item shap-factor-positive"
				>
					<div class="shap-factor-content">
						<div class="d-flex align-items-start justify-content-between gap-2 mb-1">
							<span class="fw-semibold small">
								{{ factor.feature_display_name || factor.feature }}
							</span>
							<span class="shap-factor-value small text-muted">
								{{ formatFeatureValue(factor.value) }}
							</span>
						</div>
						<div class="shap-factor-bar-wrapper">
							<div
								class="shap-factor-bar shap-factor-bar-positive"
								:style="{ width: getBarWidth(factor.contribution) + '%' }"
							></div>
						</div>
						<div class="shap-factor-contribution small text-success mt-1">
							+{{ formatScore(factor.contribution) }}
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Negative Factors -->
		<div v-if="shap.top_negative_factors && shap.top_negative_factors.length">
			<div class="fw-semibold small text-danger mb-2">
				<i class="fa-solid fa-arrow-down me-1"></i>
				{{ $t('trustEval.shap.negativeFactors') }}
			</div>
			<div class="shap-factors-list">
				<div
					v-for="(factor, idx) in shap.top_negative_factors"
					:key="'neg-' + idx"
					class="shap-factor-item shap-factor-negative"
				>
					<div class="shap-factor-content">
						<div class="d-flex align-items-start justify-content-between gap-2 mb-1">
							<span class="fw-semibold small">
								{{ factor.feature_display_name || factor.feature }}
							</span>
							<span class="shap-factor-value small text-muted">
								{{ formatFeatureValue(factor.value) }}
							</span>
						</div>
						<div class="shap-factor-bar-wrapper">
							<div
								class="shap-factor-bar shap-factor-bar-negative"
								:style="{ width: getBarWidth(Math.abs(factor.contribution)) + '%' }"
							></div>
						</div>
						<div class="shap-factor-contribution small text-danger mt-1">
							{{ formatScore(factor.contribution) }}
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Empty State -->
		<div v-if="!shap.top_positive_factors?.length && !shap.top_negative_factors?.length" class="text-center text-muted py-3">
			<i class="fa-solid fa-chart-simple d-block fs-4 mb-2 opacity-25"></i>
			<span class="small">{{ $t('trustEval.shap.noFactors') }}</span>
		</div>
	</div>
</template>

<script>
export default {
	name: 'SHAPExplanation',
	props: {
		/** @type {import('../../../services/trustEvalTypes').SHAPExplanation} */
		shap: {
			type: Object,
			required: true,
		},
		/** Score range: 'probability' (0-1) or 'risk' (0-1) */
		scoreType: {
			type: String,
			default: 'probability',
		},
	},
	computed: {
		predictionColor() {
			if (this.scoreType === 'risk') {
				if (this.shap.prediction >= 0.7) return '#dc3545';
				if (this.shap.prediction >= 0.4) return '#f59f00';
				return '#198754';
			}
			if (this.shap.prediction >= 0.7) return '#198754';
			if (this.shap.prediction >= 0.4) return '#f59f00';
			return '#dc3545';
		},
		predictionColorClass() {
			if (this.scoreType === 'risk') {
				if (this.shap.prediction >= 0.7) return 'text-danger';
				if (this.shap.prediction >= 0.4) return 'text-warning';
				return 'text-success';
			}
			if (this.shap.prediction >= 0.7) return 'text-success';
			if (this.shap.prediction >= 0.4) return 'text-warning';
			return 'text-danger';
		},
		baseValuePercent() {
			return Math.min(100, Math.max(0, this.shap.base_value * 100));
		},
		predictionPercent() {
			return Math.min(100, Math.max(0, this.shap.prediction * 100));
		},
		fillStyle() {
			const start = this.baseValuePercent;
			const end = this.predictionPercent;
			const left = Math.min(start, end);
			const width = Math.abs(end - start);
			const color = this.prediction >= this.base_value ? '#198754' : '#dc3545';
			return {
				position: 'absolute',
				left: left + '%',
				width: width + '%',
				top: 0,
				height: '100%',
				background: color,
				opacity: 0.2,
				borderRadius: '4px',
				transition: 'width 0.5s ease',
			};
		},
	},
	methods: {
		formatScore(value) {
			if (value === null || value === undefined) return '—';
			return Number(value).toFixed(4);
		},
		formatFeatureValue(value) {
			if (value === null || value === undefined) return '—';
			if (typeof value === 'boolean') return value ? 'Có' : 'Không';
			if (typeof value === 'number') {
				if (Number.isInteger(value)) return value.toString();
				return value.toFixed(2);
			}
			if (typeof value === 'string') return value;
			return JSON.stringify(value);
		},
		getBarWidth(contribution) {
			return Math.min(100, Math.abs(contribution) * 100);
		},
	},
};
</script>

<style scoped>
.shap-explanation {
	background: #f8f9fa;
	border-radius: 12px;
	padding: 1rem;
	border: 1px solid #e9ecef;
}

.shap-score-bar {
	padding: 0.5rem 0;
}

.shap-bar-track {
	position: relative;
	height: 12px;
	background: #e9ecef;
	border-radius: 6px;
	margin: 12px 0 4px;
}

.shap-bar-fill {
	position: absolute;
	top: 0;
	height: 100%;
	border-radius: 6px;
}

.shap-bar-base {
	position: absolute;
	top: -4px;
	transform: translateX(-50%);
	z-index: 2;
}

.shap-bar-base-line {
	width: 2px;
	height: 20px;
	background: #6c757d;
	margin: 0 auto;
	border-radius: 1px;
}

.shap-bar-base-label {
	font-size: 9px;
	color: #6c757d;
	white-space: nowrap;
	text-align: center;
	margin-top: 2px;
	font-weight: 600;
}

.shap-bar-prediction {
	position: absolute;
	top: -4px;
	transform: translateX(-50%);
	z-index: 3;
	transition: left 0.5s ease;
}

.shap-bar-prediction-dot {
	width: 20px;
	height: 20px;
	border-radius: 50%;
	border: 3px solid white;
	box-shadow: 0 1px 4px rgba(0,0,0,0.2);
}

.shap-factors-list {
	display: flex;
	flex-direction: column;
	gap: 0.5rem;
}

.shap-factor-item {
	border-radius: 8px;
	padding: 0.625rem 0.75rem;
}

.shap-factor-positive {
	background: rgba(25, 135, 84, 0.06);
	border: 1px solid rgba(25, 135, 84, 0.15);
}

.shap-factor-negative {
	background: rgba(220, 53, 69, 0.06);
	border: 1px solid rgba(220, 53, 69, 0.15);
}

.shap-factor-bar-wrapper {
	height: 6px;
	background: rgba(0,0,0,0.08);
	border-radius: 3px;
	overflow: hidden;
}

.shap-factor-bar {
	height: 100%;
	border-radius: 3px;
	transition: width 0.5s ease;
}

.shap-factor-bar-positive {
	background: linear-gradient(90deg, #198754, #52d68a);
}

.shap-factor-bar-negative {
	background: linear-gradient(90deg, #dc3545, #f0808f);
}

.shap-factor-contribution {
	text-align: right;
	font-weight: 600;
}
</style>
