<template>
	<div class="row g-3 mb-4">
		<div :class="colClass" v-for="(card, index) in cards" :key="index">
			<div class="card border-0 shadow-sm h-100">
				<div class="card-body d-flex align-items-center gap-3 py-3">
					<div class="stat-icon rounded-circle d-flex align-items-center justify-content-center flex-shrink-0"
						:class="`bg-${card.color} bg-opacity-10 text-${card.color}`">
						<i :class="card.icon" class="fs-5"></i>
					</div>
					<div class="min-w-0">
						<div class="text-muted small fw-medium text-truncate">{{ card.label }}</div>
						<h4 class="fw-bold mb-0">{{ card.value }}</h4>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
export default {
	name: 'StatCards',
	props: {
		cards: {
			type: Array,
			required: true,
			// Each card: { label, value, icon, color }
		},
		columns: {
			type: Number,
			default: 4
		}
	},
	computed: {
		colClass() {
			const map = { 2: 'col-md-6', 3: 'col-lg-4 col-md-6', 4: 'col-xl-3 col-md-6' };
			return map[this.columns] || 'col-xl-3 col-md-6';
		}
	}
}
</script>

<style scoped>
.stat-icon {
	width: 48px;
	height: 48px;
}
.min-w-0 {
	min-width: 0;
}
</style>
