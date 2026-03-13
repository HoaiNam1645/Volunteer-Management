<template>
	<div class="toast-container-wrapper">
		<TransitionGroup name="toast" tag="div">
			<div v-for="toast in toasts" :key="toast.id" class="toast-notification" :class="'toast-' + toast.type">
				<div class="toast-icon-area">
					<i :class="getIcon(toast.type)"></i>
				</div>
				<div class="toast-body-area">
					<strong class="toast-title">{{ toast.title }}</strong>
					<p class="toast-message mb-0" v-if="toast.message">{{ toast.message }}</p>
				</div>
				<button class="toast-close-btn" @click="removeToast(toast.id)">
					<i class="fa-solid fa-xmark"></i>
				</button>
				<div class="toast-progress">
					<div class="toast-progress-bar" :class="'bar-' + toast.type"
						:style="{ animationDuration: toast.duration + 'ms' }"></div>
				</div>
			</div>
		</TransitionGroup>
	</div>
</template>

<script>
export default {
	name: 'ToastNotification',
	data() {
		return {
			toasts: [],
			nextId: 0
		}
	},
	methods: {
		getIcon(type) {
			const icons = {
				success: 'fa-solid fa-circle-check',
				error: 'fa-solid fa-circle-xmark',
				warning: 'fa-solid fa-triangle-exclamation',
				info: 'fa-solid fa-circle-info'
			};
			return icons[type] || icons.info;
		},
		addToast({ title = '', message = '', type = 'info', duration = 3500 }) {
			const id = this.nextId++;
			this.toasts.push({ id, title, message, type, duration });
			setTimeout(() => this.removeToast(id), duration);
		},
		removeToast(id) {
			this.toasts = this.toasts.filter(t => t.id !== id);
		},
		success(title, message = '') {
			this.addToast({ title, message, type: 'success' });
		},
		error(title, message = '') {
			this.addToast({ title, message, type: 'error', duration: 5000 });
		},
		warning(title, message = '') {
			this.addToast({ title, message, type: 'warning' });
		},
		info(title, message = '') {
			this.addToast({ title, message, type: 'info' });
		}
	}
}
</script>

<style scoped>
.toast-container-wrapper {
	position: fixed;
	top: 20px;
	right: 20px;
	z-index: 9999;
	display: flex;
	flex-direction: column;
	gap: 10px;
	max-width: 400px;
	width: 100%;
	pointer-events: none;
}

.toast-notification {
	display: flex;
	align-items: stretch;
	background: white;
	border-radius: 12px;
	box-shadow: 0 8px 30px rgba(0, 0, 0, 0.12), 0 2px 8px rgba(0, 0, 0, 0.06);
	overflow: hidden;
	position: relative;
	pointer-events: all;
	min-height: 58px;
}

.toast-icon-area {
	width: 50px;
	min-width: 50px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 20px;
}

.toast-success .toast-icon-area { background: rgba(25, 135, 84, 0.1); color: #198754; }
.toast-error .toast-icon-area { background: rgba(220, 53, 69, 0.1); color: #dc3545; }
.toast-warning .toast-icon-area { background: rgba(253, 126, 20, 0.1); color: #fd7e14; }
.toast-info .toast-icon-area { background: rgba(13, 110, 253, 0.1); color: #0d6efd; }

.toast-body-area {
	flex: 1;
	padding: 10px 12px;
	display: flex;
	flex-direction: column;
	justify-content: center;
}

.toast-title {
	font-size: 13px;
	font-weight: 700;
	color: #212529;
	line-height: 1.3;
}

.toast-message {
	font-size: 12px;
	color: #6c757d;
	line-height: 1.3;
	margin-top: 2px;
}

.toast-close-btn {
	background: none;
	border: none;
	color: #adb5bd;
	padding: 0 14px;
	cursor: pointer;
	font-size: 14px;
	transition: color 0.2s;
	align-self: stretch;
	display: flex;
	align-items: center;
}
.toast-close-btn:hover { color: #495057; }

.toast-progress {
	position: absolute;
	bottom: 0;
	left: 0;
	right: 0;
	height: 3px;
	background: rgba(0, 0, 0, 0.05);
}

.toast-progress-bar {
	height: 100%;
	border-radius: 0 0 0 12px;
	animation: shrink linear forwards;
}

.bar-success { background: #198754; }
.bar-error { background: #dc3545; }
.bar-warning { background: #fd7e14; }
.bar-info { background: #0d6efd; }

@keyframes shrink {
	from { width: 100%; }
	to { width: 0%; }
}

/* Transitions */
.toast-enter-active {
	animation: slideInRight 0.35s ease;
}
.toast-leave-active {
	animation: slideOutRight 0.3s ease forwards;
}

@keyframes slideInRight {
	from {
		opacity: 0;
		transform: translateX(60px);
	}
	to {
		opacity: 1;
		transform: translateX(0);
	}
}
@keyframes slideOutRight {
	from {
		opacity: 1;
		transform: translateX(0);
	}
	to {
		opacity: 0;
		transform: translateX(60px);
	}
}
</style>
