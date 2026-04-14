<template>
	<div class="risk-flag-row d-flex gap-2">
		<div class="risk-flag-severity">
			<span class="badge" :class="severityBadgeClass">
				{{ severityLabel }}
			</span>
		</div>
		<div class="risk-flag-content flex-grow-1">
			<div class="d-flex align-items-start justify-content-between gap-2 mb-1">
				<span class="fw-semibold small">{{ flag.message }}</span>
				<span v-if="flag.auto_resolvable" class="badge bg-light text-muted border ms-auto flex-shrink-0" style="font-size: 10px;">
					<i class="fa-solid fa-wand-magic-sparkles me-1"></i>{{ $t('trustEval.risk.autoResolvable') }}
				</span>
			</div>
			<div class="small text-muted mb-1">
				<span class="badge bg-light text-dark border me-1" style="font-size: 10px;">
					{{ flag.category }}
				</span>
				<code class="text-muted" style="font-size: 10px;">{{ flag.code }}</code>
			</div>
			<div v-if="flag.suggestion" class="suggestion-box mt-1">
				<i class="fa-solid fa-lightbulb text-warning me-1"></i>
				<span class="small">{{ flag.suggestion }}</span>
			</div>
		</div>
	</div>
</template>

<script>
export default {
	name: 'RiskFlagRow',
	props: {
		flag: {
			type: Object,
			required: true,
		},
	},
	computed: {
		severityBadgeClass() {
			const map = {
				CRITICAL: 'bg-danger',
				HIGH: 'bg-warning text-dark',
				MEDIUM: 'bg-info text-white',
				LOW: 'bg-secondary text-white',
			};
			return map[this.flag.severity] || 'bg-secondary';
		},
		severityLabel() {
			const map = {
				CRITICAL: 'CRITICAL',
				HIGH: 'HIGH',
				MEDIUM: 'MEDIUM',
				LOW: 'LOW',
			};
			return map[this.flag.severity] || this.flag.severity;
		},
	},
};
</script>

<style scoped>
.risk-flag-row {
	padding: 0.5rem 0.625rem;
	background: #fff;
	border-radius: 8px;
	border: 1px solid #e9ecef;
}

.risk-flag-severity {
	flex-shrink: 0;
}

.risk-flag-content {
	min-width: 0;
}

.suggestion-box {
	background: rgba(245, 159, 0, 0.06);
	border: 1px solid rgba(245, 159, 0, 0.2);
	border-radius: 6px;
	padding: 0.375rem 0.5rem;
	font-size: 12px;
	line-height: 1.4;
	color: #495057;
}
</style>
