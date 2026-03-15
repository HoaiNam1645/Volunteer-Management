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
					<p class="fw-semibold text-dark mb-4" v-if="detail">"{{ detail }}"</p>

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
