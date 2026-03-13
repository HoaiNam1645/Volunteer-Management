<template>
	<div class="d-flex flex-column flex-sm-row align-items-start align-items-sm-center justify-content-between mb-4 gap-3">
		<div>
			<h4 class="fw-bold mb-1">
				<i v-if="icon" :class="icon" class="text-primary me-2"></i>{{ title }}
			</h4>
			<nav aria-label="breadcrumb" v-if="breadcrumbs.length > 0">
				<ol class="breadcrumb mb-0 small">
					<li class="breadcrumb-item" v-for="(crumb, i) in breadcrumbs" :key="i"
						:class="{ active: i === breadcrumbs.length - 1 }">
						<router-link v-if="crumb.to" :to="crumb.to" class="text-decoration-none">{{ crumb.label }}</router-link>
						<span v-else>{{ crumb.label }}</span>
					</li>
				</ol>
			</nav>
		</div>
		<div class="d-flex gap-2 flex-shrink-0">
			<slot name="actions"></slot>
		</div>
	</div>
</template>

<script>
export default {
	name: 'PageHeader',
	props: {
		title: { type: String, required: true },
		icon: { type: String, default: '' },
		breadcrumbs: { type: Array, default: () => [] }
	}
}
</script>
