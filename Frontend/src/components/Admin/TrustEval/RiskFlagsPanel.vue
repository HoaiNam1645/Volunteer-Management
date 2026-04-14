<template>
	<div class="risk-flags-panel">
		<!-- Critical Errors -->
		<div v-if="criticalFlags.length" class="risk-section mb-3">
			<div class="risk-section-header mb-2">
				<i class="fa-solid fa-circle-exclamation text-danger me-2"></i>
				<span class="fw-bold small">{{ $t('trustEval.risk.criticalErrors') }}</span>
				<span class="badge bg-danger ms-2">{{ criticalFlags.length }}</span>
			</div>
			<div class="risk-flag-list">
				<div
					v-for="flag in criticalFlags"
					:key="flag.code"
					class="risk-flag-item risk-flag-critical"
				>
					<RiskFlagRow :flag="flag" />
				</div>
			</div>
		</div>

		<!-- Warnings -->
		<div v-if="warningFlags.length" class="risk-section">
			<div class="risk-section-header mb-2">
				<i class="fa-solid fa-triangle-exclamation text-warning me-2"></i>
				<span class="fw-bold small">{{ $t('trustEval.risk.warnings') }}</span>
				<span class="badge bg-warning text-dark ms-2">{{ warningFlags.length }}</span>
			</div>
			<div class="risk-flag-list">
				<div
					v-for="flag in warningFlags"
					:key="flag.code"
					class="risk-flag-item"
					:class="severityFlagClass(flag.severity)"
				>
					<RiskFlagRow :flag="flag" />
				</div>
			</div>
		</div>

		<!-- All Flags (flat view) -->
		<div v-if="!criticalFlags.length && !warningFlags.length" class="text-center text-muted py-3">
			<i class="fa-solid fa-check-circle text-success d-block fs-4 mb-2 opacity-25"></i>
			<span class="small">{{ $t('trustEval.risk.noFlags') }}</span>
		</div>
	</div>
</template>

<script>
import RiskFlagRow from './RiskFlagRow.vue';

export default {
	name: 'RiskFlagsPanel',
	components: { RiskFlagRow },
	props: {
		flags: {
			type: Array,
			default: () => [],
		},
	},
	computed: {
		criticalFlags() {
			return this.flags.filter(f => f.severity === 'CRITICAL');
		},
		warningFlags() {
			return this.flags.filter(f => f.severity !== 'CRITICAL');
		},
	},
	methods: {
		severityFlagClass(severity) {
			const map = {
				HIGH: 'risk-flag-high',
				MEDIUM: 'risk-flag-medium',
				LOW: 'risk-flag-low',
			};
			return map[severity] || '';
		},
	},
};
</script>

<style scoped>
.risk-flags-panel {
	display: flex;
	flex-direction: column;
	gap: 0;
}

.risk-section {
	width: 100%;
}

.risk-flag-list {
	display: flex;
	flex-direction: column;
	gap: 0.5rem;
}

.risk-flag-critical {
	border-left: 3px solid #dc3545;
	padding-left: 0.75rem;
}

.risk-flag-high {
	border-left: 3px solid #fd7e14;
	padding-left: 0.75rem;
}

.risk-flag-medium {
	border-left: 3px solid #f59f00;
	padding-left: 0.75rem;
}

.risk-flag-low {
	border-left: 3px solid #adb5bd;
	padding-left: 0.75rem;
}
</style>
