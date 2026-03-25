<template>
	<div class="modal fade" :id="modalId" tabindex="-1" ref="modalEl">
		<div class="modal-dialog modal-dialog-centered modal-dialog-scrollable" :class="sizeClass">
			<div class="modal-content border-0 shadow">
				<div class="modal-body text-center p-4 p-md-5">
					<div class="d-inline-flex align-items-center justify-content-center rounded-circle mb-3"
						:class="`bg-${variant} bg-opacity-10 text-${variant}`"
						style="width: 70px; height: 70px;">
						<i :class="icon" class="fs-2"></i>
					</div>
					<h5 class="fw-bold mb-2">{{ title || $t('common.confirm') }}</h5>
					<p class="text-muted mb-1" v-if="message">{{ message }}</p>
					<p class="fw-semibold text-dark mb-4" v-if="detail && !hasDetailList">"{{ detail }}"</p>
					<div v-if="hasDetailList" class="confirm-detail-card text-start mb-4">
						<div class="confirm-detail-title">{{ detailListTitle || 'Các lưu ý cần biết' }}</div>
						<ul class="confirm-detail-list mb-0">
							<li v-for="(item, index) in detailList" :key="`${modalId}-detail-${index}`">
								<i class="fa-solid fa-circle-exclamation text-warning"></i>
								<span>{{ item }}</span>
							</li>
						</ul>
					</div>

					<slot name="warning"></slot>

					<div class="d-flex gap-3 justify-content-center mt-4">
						<button class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">
							{{ cancelText || $t('common.cancel') }}
						</button>
						<button v-if="dismissOnConfirm" class="btn px-4 shadow-sm"
							:class="`btn-${variant}`"
							@click="$emit('confirm')"
							data-bs-dismiss="modal">
							<i v-if="confirmIcon" :class="confirmIcon" class="me-1"></i>{{ confirmText || $t('common.confirm') }}
						</button>
						<button v-else class="btn px-4 shadow-sm"
							:class="`btn-${variant}`"
							@click="$emit('confirm')">
							<i v-if="confirmIcon" :class="confirmIcon" class="me-1"></i>{{ confirmText || $t('common.confirm') }}
						</button>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
export default {
	name: 'ConfirmModal',
	props: {
		modalId: { type: String, required: true },
		title: { type: String, default: '' },
		message: { type: String, default: '' },
		detail: { type: String, default: '' },
		detailList: { type: Array, default: () => [] },
		detailListTitle: { type: String, default: '' },
		icon: { type: String, default: 'fa-solid fa-triangle-exclamation' },
		variant: { type: String, default: 'danger' },
		confirmText: { type: String, default: '' },
		confirmIcon: { type: String, default: '' },
		cancelText: { type: String, default: '' },
		size: { type: String, default: '' },
		dismissOnConfirm: { type: Boolean, default: true }
	},
	emits: ['confirm'],
	data() {
		return {
			modalInstance: null
		};
	},
	computed: {
		sizeClass() {
			return this.size ? `modal-${this.size}` : '';
		},
		hasDetailList() {
			return Array.isArray(this.detailList) && this.detailList.length > 0;
		}
	},
	mounted() {
		this.modalInstance = bootstrap.Modal.getOrCreateInstance(this.$refs.modalEl);
		this.$refs.modalEl.addEventListener('hidden.bs.modal', this.cleanupBackdropState);
	},
	beforeUnmount() {
		this.$refs.modalEl?.removeEventListener('hidden.bs.modal', this.cleanupBackdropState);
		this.modalInstance?.dispose?.();
		this.modalInstance = null;
	},
	methods: {
		show() {
			this.modalInstance = bootstrap.Modal.getOrCreateInstance(this.$refs.modalEl);
			this.modalInstance.show();
		},
		hide() {
			this.modalInstance = bootstrap.Modal.getOrCreateInstance(this.$refs.modalEl);
			this.modalInstance.hide();
		},
		cleanupBackdropState() {
			if (document.querySelector('.modal.show')) {
				return;
			}

			document.body.classList.remove('modal-open');
			document.body.style.removeProperty('overflow');
			document.body.style.removeProperty('padding-right');
			document.querySelectorAll('.modal-backdrop').forEach((backdrop) => backdrop.remove());
		}
	}
}
</script>

<style scoped>
.confirm-detail-card {
	background: rgba(255, 193, 7, 0.08);
	border: 1px solid rgba(255, 193, 7, 0.22);
	border-radius: 1rem;
	padding: 1rem 1.1rem;
}

.confirm-detail-title {
	font-size: 0.95rem;
	font-weight: 700;
	color: #856404;
	margin-bottom: 0.75rem;
}

.confirm-detail-list {
	list-style: none;
	padding: 0;
}

.confirm-detail-list li {
	display: flex;
	align-items: flex-start;
	gap: 0.65rem;
	color: #495057;
	font-size: 0.95rem;
	line-height: 1.55;
}

.confirm-detail-list li + li {
	margin-top: 0.65rem;
}
</style>
