<template>
	<div class="decision-support" :class="'decision-' + action">
		<!-- Header -->
		<div class="decision-header mb-3">
			<div class="d-flex align-items-center gap-3">
				<div class="decision-icon" :style="iconStyle">
					<i :class="actionIcon"></i>
				</div>
				<div>
					<h6 class="fw-bold mb-0">
						{{ $t('trustEval.decision.title') }}
					</h6>
					<div class="small text-muted">{{ $t('trustEval.decision.subtitle') }}</div>
				</div>
				<div class="ms-auto text-end">
					<div class="badge rounded-pill" :class="actionBadgeClass">
						<i :class="actionIcon" class="me-1"></i>
						{{ actionLabel }}
					</div>
				</div>
			</div>
		</div>

		<!-- Confidence -->
		<div v-if="decision.confidence" class="confidence-row mb-3">
			<div class="d-flex align-items-center gap-2 small">
				<span class="text-muted">{{ $t('trustEval.decision.confidence') }}:</span>
				<div class="confidence-dots d-flex gap-1">
					<span
						v-for="i in 3"
						:key="i"
						class="confidence-dot"
						:class="i <= confidenceLevel ? 'active' : ''"
						:style="i <= confidenceLevel ? { background: confidenceColor } : {}"
					></span>
				</div>
				<span class="fw-semibold small" :style="{ color: confidenceColor }">
					{{ confidenceLabel }}
				</span>
			</div>
		</div>

		<!-- Reason -->
		<div v-if="decision.reason" class="decision-reason mb-3">
			<div class="small text-muted mb-1 fw-semibold">
				<i class="fa-solid fa-comment-dots me-1"></i>
				{{ $t('trustEval.decision.reasonLabel') }}
			</div>
			<div class="decision-reason-text">
				{{ decision.reason }}
			</div>
		</div>

		<!-- Questions to Verify -->
		<div v-if="decision.questions_to_verify && decision.questions_to_verify.length" class="questions-section">
			<div class="small text-muted mb-2 fw-semibold">
				<i class="fa-solid fa-clipboard-check me-1"></i>
				{{ $t('trustEval.decision.questionsToVerify') }}
			</div>
			<ul class="questions-list mb-0">
				<li
					v-for="(q, idx) in decision.questions_to_verify"
					:key="idx"
					class="question-item"
				>
					{{ q }}
				</li>
			</ul>
		</div>

		<!-- Source Badge -->
		<div class="mt-3 pt-2 border-top">
			<span
				class="badge rounded-pill"
				:class="decision._fallback ? 'bg-secondary' : 'bg-primary'"
			>
				<i :class="decision._fallback ? 'fa-solid fa-rule' : 'fa-solid fa-brain'" class="me-1"></i>
				{{ decision._fallback ? $t('trustEval.decision.sourceFallback') : $t('trustEval.decision.sourceML') }}
			</span>
		</div>
	</div>
</template>

<script>
export default {
	name: 'DecisionSupport',
	props: {
		/** @type {import('../../../services/trustEvalTypes').DecisionSupport} */
		decision: {
			type: Object,
			required: true,
		},
	},
	computed: {
		action() {
			return this.decision.recommended_action || 'REQUEST_ADDITIONAL_INFO';
		},
		actionLabel() {
			const labels = {
				APPROVE: this.$t('trustEval.decision.actions.approve'),
				APPROVE_WITH_NOTE: this.$t('trustEval.decision.actions.approveWithNote'),
				REQUEST_ADDITIONAL_INFO: this.$t('trustEval.decision.actions.requestInfo'),
				REJECT: this.$t('trustEval.decision.actions.reject'),
			};
			return labels[this.action] || this.action;
		},
		actionIcon() {
			const icons = {
				APPROVE: 'fa-solid fa-circle-check',
				APPROVE_WITH_NOTE: 'fa-solid fa-circle-exclamation',
				REQUEST_ADDITIONAL_INFO: 'fa-solid fa-circle-info',
				REJECT: 'fa-solid fa-circle-xmark',
			};
			return icons[this.action] || 'fa-solid fa-circle';
		},
		actionBadgeClass() {
			const classes = {
				APPROVE: 'bg-success-subtle text-success border border-success',
				APPROVE_WITH_NOTE: 'bg-warning-subtle text-warning border border-warning',
				REQUEST_ADDITIONAL_INFO: 'bg-info-subtle text-info border border-info',
				REJECT: 'bg-danger-subtle text-danger border border-danger',
			};
			return classes[this.action] || 'bg-secondary';
		},
		iconStyle() {
			const colors = {
				APPROVE: { background: 'rgba(25,135,84,0.1)', color: '#198754' },
				APPROVE_WITH_NOTE: { background: 'rgba(245,159,0,0.1)', color: '#f59f00' },
				REQUEST_ADDITIONAL_INFO: { background: 'rgba(13,110,253,0.1)', color: '#0d6efd' },
				REJECT: { background: 'rgba(220,53,69,0.1)', color: '#dc3545' },
			};
			return {
				width: '40px',
				height: '40px',
				borderRadius: '10px',
				display: 'flex',
				alignItems: 'center',
				justifyContent: 'center',
				fontSize: '16px',
				...colors[this.action],
			};
		},
		confidenceLevel() {
			const map = { HIGH: 3, MEDIUM: 2, LOW: 1 };
			return map[this.decision.confidence] || 0;
		},
		confidenceLabel() {
			const labels = { HIGH: 'Cao', MEDIUM: 'Trung bình', LOW: 'Thấp' };
			return labels[this.decision.confidence] || '—';
		},
		confidenceColor() {
			const colors = { HIGH: '#198754', MEDIUM: '#f59f00', LOW: '#dc3545' };
			return colors[this.decision.confidence] || '#6c757d';
		},
	},
};
</script>

<style scoped>
.decision-support {
	border-radius: 12px;
	padding: 1rem;
	border: 1px solid #e9ecef;
	background: #fff;
}

.decision-support.decision-APPROVE {
	border-color: rgba(25, 135, 84, 0.3);
	background: linear-gradient(135deg, rgba(25,135,84,0.03), rgba(255,255,255,1));
}

.decision-support.decision-REJECT {
	border-color: rgba(220, 53, 69, 0.3);
	background: linear-gradient(135deg, rgba(220,53,69,0.03), rgba(255,255,255,1));
}

.decision-icon {
	flex-shrink: 0;
}

.decision-reason-text {
	background: #f8f9fa;
	border-radius: 8px;
	padding: 0.625rem 0.75rem;
	font-size: 13px;
	line-height: 1.5;
	color: #212529;
	border-left: 3px solid #0d6efd;
}

.questions-list {
	list-style: none;
	padding: 0;
	margin: 0;
}

.question-item {
	font-size: 13px;
	padding: 0.375rem 0.75rem;
	background: #f8f9fa;
	border-radius: 6px;
	margin-bottom: 0.375rem;
	color: #212529;
	position: relative;
	padding-left: 1.5rem;
}

.question-item::before {
	content: '';
	position: absolute;
	left: 0.5rem;
	top: 50%;
	transform: translateY(-50%);
	width: 6px;
	height: 6px;
	border-radius: 50%;
	background: #0d6efd;
}

.question-item:last-child {
	margin-bottom: 0;
}

.confidence-dot {
	width: 10px;
	height: 10px;
	border-radius: 50%;
	background: #e9ecef;
	border: 1px solid #ced4da;
	transition: background 0.2s;
}

.confidence-dot.active {
	border-color: transparent;
}
</style>
