<template>
	<div class="admin-wrapper" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
		<!-- Sidebar -->
		<aside class="admin-sidebar">
			<div class="sidebar-header">
				<div class="d-flex align-items-center gap-2">
					<div class="admin-logo-box">
						<i class="fa-solid fa-shield-halved"></i>
					</div>
					<div class="sidebar-brand" v-show="!sidebarCollapsed">
						<h5 class="mb-0 fw-bold text-white">VMS-AI</h5>
						<span class="small text-white-50">{{ $t('admin.layout.panel') }}</span>
					</div>
				</div>
				<button class="btn btn-link text-white-50 sidebar-toggle d-none d-lg-block" @click="toggleSidebar">
					<i class="fa-solid" :class="sidebarCollapsed ? 'fa-angles-right' : 'fa-angles-left'"></i>
				</button>
			</div>

			<nav class="sidebar-nav">
				<div class="nav-section">
					<span class="nav-section-title" v-show="!sidebarCollapsed">{{ $t('admin.layout.overview') }}</span>
					<ul class="nav flex-column">
						<li class="nav-item" v-if="can('dashboard.view') && !isReviewer">
							<router-link to="/admin" class="nav-link" :class="{ active: $route.path === '/admin' }">
								<i class="fa-solid fa-gauge-high"></i>
								<span v-show="!sidebarCollapsed">{{ $t('admin.layout.dashboard') }}</span>
							</router-link>
						</li>
						<li class="nav-item" v-if="can('statistics.view')">
							<router-link to="/admin/thong-ke" class="nav-link" :class="{ active: $route.path.startsWith('/admin/thong-ke') || (isReviewer && $route.path === '/admin') }">
								<i class="fa-solid fa-chart-pie"></i>
								<span v-show="!sidebarCollapsed">{{ $t('admin.layout.statistics') }}</span>
							</router-link>
						</li>
					</ul>
				</div>

				<div class="nav-section" v-if="can('user_management.view') || can('campaign_review.view') || can('category_management.view')">
					<span class="nav-section-title" v-show="!sidebarCollapsed">{{ $t('admin.layout.management') }}</span>
					<ul class="nav flex-column">
						<li class="nav-item" v-if="can('user_management.view')">
							<router-link to="/admin/nguoi-dung" class="nav-link" :class="{ active: $route.path.startsWith('/admin/nguoi-dung') }">
								<i class="fa-solid fa-users"></i>
								<span v-show="!sidebarCollapsed">{{ $t('admin.layout.users') }}</span>
							</router-link>
						</li>
						<li class="nav-item" v-if="can('campaign_review.view')">
							<router-link to="/admin/chien-dich" class="nav-link" :class="{ active: $route.path.startsWith('/admin/chien-dich') }">
								<i class="fa-solid fa-flag"></i>
								<span v-show="!sidebarCollapsed">{{ $t('admin.layout.campaigns') }}</span>
							</router-link>
						</li>
						<li class="nav-item" v-if="can('category_management.view')">
							<router-link to="/admin/danh-muc" class="nav-link" :class="{ active: $route.path.startsWith('/admin/danh-muc') }">
								<i class="fa-solid fa-layer-group"></i>
								<span v-show="!sidebarCollapsed">{{ $t('admin.layout.categories') }}</span>
							</router-link>
						</li>
					</ul>
				</div>

				<div class="nav-section" v-if="can('permission_management.view')">
					<span class="nav-section-title" v-show="!sidebarCollapsed">{{ $t('admin.layout.permissionSection') }}</span>
					<ul class="nav flex-column">
						<li class="nav-item">
							<router-link to="/admin/phan-quyen" class="nav-link" :class="{ active: $route.path === '/admin/phan-quyen' }">
								<i class="fa-solid fa-shield-keyhole"></i>
								<span v-show="!sidebarCollapsed">{{ $t('admin.layout.permissions') }}</span>
							</router-link>
						</li>
						<li class="nav-item">
							<router-link to="/admin/phan-quyen-nguoi-dung" class="nav-link" :class="{ active: $route.path === '/admin/phan-quyen-nguoi-dung' }">
								<i class="fa-solid fa-user-lock"></i>
								<span v-show="!sidebarCollapsed">{{ $t('admin.layout.userPermissions') }}</span>
							</router-link>
						</li>
					</ul>
				</div>
			</nav>

			<div class="sidebar-footer" v-show="!sidebarCollapsed">
				<div class="admin-profile d-flex align-items-center gap-2">
					<div class="admin-avatar">
						<i class="fa-solid fa-user-shield"></i>
					</div>
					<div>
						<p class="mb-0 small fw-bold text-white">{{ profileName }}</p>
						<p class="mb-0 text-white-50" style="font-size: 11px;">{{ profileRole }}</p>
					</div>
				</div>
			</div>
		</aside>

		<!-- Main Content -->
		<div class="admin-main">
			<!-- Top Header -->
			<header class="admin-header">
				<div class="d-flex align-items-center gap-3">
					<button class="btn btn-link text-muted d-lg-none" @click="toggleSidebar">
						<i class="fa-solid fa-bars fs-5"></i>
					</button>
					<div class="admin-search d-none d-md-block">
						<div class="position-relative">
							<input type="text" class="form-control" :placeholder="$t('admin.layout.searchPlaceholder')">
							<i class="fa-solid fa-search search-icon"></i>
						</div>
					</div>
				</div>
				<div class="d-flex align-items-center gap-3">
					<LanguageSwitcher />
					<div class="dropdown">
						<button class="btn btn-link text-muted position-relative" data-bs-toggle="dropdown" aria-expanded="false">
							<i class="fa-solid fa-bell fs-5"></i>
							<span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 10px;">3</span>
						</button>
						<ul class="dropdown-menu dropdown-menu-end p-0 shadow overflow-hidden" style="width: 300px;">
							<li class="bg-light p-3 border-bottom d-flex justify-content-between align-items-center">
								<h6 class="mb-0 fw-bold">{{ $t('admin.layout.notifications.title') }}</h6>
								<small class="text-primary cursor-pointer">{{ $t('admin.layout.notifications.markAllRead') }}</small>
							</li>
							<li>
								<a class="dropdown-item p-3 border-bottom text-wrap" href="#">
									<div class="d-flex gap-3">
										<div class="bg-primary-subtle text-primary rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px; flex-shrink: 0;">
											<i class="fa-solid fa-flag"></i>
										</div>
										<div>
											<p class="mb-1 fw-medium small">{{ $t('admin.layout.notifications.pendingCampaign') }}</p>
											<p class="mb-0 text-muted" style="font-size: 11px;">{{ $t('admin.layout.notifications.pendingCampaignTime') }}</p>
										</div>
									</div>
								</a>
							</li>
							<li>
								<a class="dropdown-item p-3 border-bottom text-wrap" href="#">
									<div class="d-flex gap-3">
										<div class="bg-success-subtle text-success rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px; flex-shrink: 0;">
											<i class="fa-solid fa-user-plus"></i>
										</div>
										<div>
											<p class="mb-1 fw-medium small">{{ $t('admin.layout.notifications.newRegistrations') }}</p>
											<p class="mb-0 text-muted" style="font-size: 11px;">{{ $t('admin.layout.notifications.newRegistrationsTime') }}</p>
										</div>
									</div>
								</a>
							</li>
							<li><a class="dropdown-item text-center text-primary py-2 small fw-bold bg-light" href="#">{{ $t('admin.layout.notifications.viewAll') }}</a></li>
						</ul>
					</div>
					<router-link to="/" class="btn btn-outline-primary btn-sm rounded-pill px-3">
						<i class="fa-solid fa-globe me-1"></i> {{ $t('admin.layout.homeView') }}
					</router-link>
					<div class="dropdown">
						<a class="d-flex align-items-center text-decoration-none dropdown-toggle" href="#"
							role="button" data-bs-toggle="dropdown">
							<div class="admin-header-avatar">
								<i class="fa-solid fa-user-shield"></i>
							</div>
						</a>
						<ul class="dropdown-menu dropdown-menu-end">
							<li><a class="dropdown-item" href="#"><i class="fa-solid fa-gear me-2"></i>{{ $t('admin.layout.settings') }}</a></li>
							<li><hr class="dropdown-divider"></li>
							<li>
								<button type="button" class="dropdown-item text-danger" @click="handleLogout">
									<i class="fa-solid fa-right-from-bracket me-2"></i>{{ $t('admin.layout.logout') }}
								</button>
							</li>
						</ul>
					</div>
				</div>
			</header>

			<!-- Page Content -->
			<div class="admin-content">
				<router-view></router-view>
			</div>
		</div>

		<!-- Mobile overlay -->
		<div class="sidebar-overlay" v-if="!sidebarCollapsed" @click="toggleSidebar"></div>

		<!-- Toast Notification -->
		<ToastNotification ref="toast" />
	</div>
</template>

<script>
import ToastNotification from '../../components/ToastNotification.vue';
import LanguageSwitcher from '../../components/LanguageSwitcher.vue';
import api from '../../services/api';
import { hasPermission } from '../../utils/permissions';

export default {
	name: 'BoCucAdmin',
	components: { ToastNotification, LanguageSwitcher },
	data() {
		return {
			sidebarCollapsed: false,
			toastRef: null,
			currentUser: null
		}
	},
	computed: {
		isReviewer() {
			return this.currentUser?.vai_tro === 'kiem_duyet_vien';
		},
		profileName() {
			return this.currentUser?.ho_ten || this.$t('admin.layout.admin');
		},
		profileRole() {
			return this.isReviewer ? this.$t('admin.layout.reviewerRole') : this.$t('admin.layout.adminRole');
		}
	},
	provide() {
		return {
			toast: {
				showToast: (type, title, message) => {
					if (this.$refs.toast && typeof this.$refs.toast[type] === 'function') {
						this.$refs.toast[type](title, message);
					}
				}
			}
		}
	},
	created() {
		this.loadCurrentUser();
	},
	mounted() {
		window.addEventListener('user-updated', this.handleUserUpdated);
	},
	beforeUnmount() {
		window.removeEventListener('user-updated', this.handleUserUpdated);
	},
	methods: {
		can(permission) {
			return hasPermission(this.currentUser, permission);
		},
		handleUserUpdated() {
			this.loadCurrentUser();
		},
		async handleLogout() {
			try {
				await api.post('/xac-thuc/dang-xuat');
			} catch (_error) {
				// Ignore logout API errors and clear client state anyway.
			}
			localStorage.removeItem('token');
			localStorage.removeItem('user');
			this.currentUser = null;
			window.dispatchEvent(new CustomEvent('user-updated'));
			this.$router.replace('/dang-nhap');
		},
		loadCurrentUser() {
			try {
				this.currentUser = JSON.parse(localStorage.getItem('user') || 'null');
			} catch (_error) {
				this.currentUser = null;
			}
		},
		toggleSidebar() {
			this.sidebarCollapsed = !this.sidebarCollapsed;
		}
	},
	watch: {
		'$route'() {
			this.loadCurrentUser();
		}
	}
}
</script>

<style>
@import "../../assets/plugins/simplebar/css/simplebar.css";
@import "../../assets/plugins/perfect-scrollbar/css/perfect-scrollbar.css";
@import "../../assets/plugins/metismenu/css/metisMenu.min.css";
@import "../../assets/css/pace.min.css";
@import "../../assets/css/bootstrap.min.css";
@import "../../assets/css/bootstrap-extended.css";
@import url("https://fonts.googleapis.com/css2?family=Roboto:wght@400;500&display=swap");
@import url("https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css");
</style>

<style scoped>
/* ===== Layout ===== */
.admin-wrapper {
	display: flex;
	min-height: 100vh;
	width: 100%;
	max-width: 100%;
	overflow-x: hidden;
	background: #f0f2f5;
}

/* ===== Sidebar ===== */
.admin-sidebar {
	width: 260px;
	background: linear-gradient(180deg, #1a1f36 0%, #1e2745 100%);
	display: flex;
	flex-direction: column;
	flex-shrink: 0;
	position: fixed;
	top: 0;
	left: 0;
	bottom: 0;
	z-index: 1040;
	transition: width 0.3s ease;
	overflow: hidden;
}

.sidebar-collapsed .admin-sidebar {
	width: 72px;
}

.sidebar-header {
	padding: 20px 16px;
	display: flex;
	align-items: center;
	justify-content: space-between;
	border-bottom: 1px solid rgba(255,255,255,0.08);
}

.sidebar-collapsed .sidebar-header {
	padding: 20px 0;
	flex-direction: column;
	gap: 15px;
	justify-content: center;
}

.admin-logo-box {
	width: 38px;
	height: 38px;
	min-width: 38px;
	border-radius: 10px;
	background: linear-gradient(135deg, #4f8cf7, #3b6de7);
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-size: 18px;
}

.sidebar-toggle {
	padding: 4px;
	font-size: 14px;
	text-decoration: none !important;
}

.sidebar-toggle:hover {
	color: white !important;
}

/* ===== Nav ===== */
.sidebar-nav {
	flex-grow: 1;
	padding: 10px 0;
	overflow-y: auto;
	overflow-x: hidden;
}

.sidebar-nav .nav-section-title {
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.nav-section {
	margin-bottom: 6px;
}

.nav-section-title {
	display: block;
	font-size: 10px;
	font-weight: 700;
	color: rgba(255,255,255,0.3);
	text-transform: uppercase;
	letter-spacing: 1.2px;
	padding: 12px 20px 6px;
}

.sidebar-nav .nav-link {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 10px 20px;
	color: rgba(255,255,255,0.6);
	font-size: 14px;
	font-weight: 500;
	border-radius: 0;
	transition: all 0.2s ease;
	white-space: nowrap;
	text-decoration: none;
	overflow: hidden;
}

.sidebar-nav .nav-link span:first-of-type {
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
	flex: 1;
}

.sidebar-nav .nav-link i {
	font-size: 17px;
	width: 24px;
	text-align: center;
	flex-shrink: 0;
}

.sidebar-nav .nav-link:hover {
	color: white;
	background: rgba(255,255,255,0.06);
}

.sidebar-nav .nav-link.active {
	color: white;
	background: linear-gradient(90deg, rgba(79,140,247,0.25), transparent);
	border-left: 3px solid #4f8cf7;
}

.nav-badge {
	margin-left: auto;
	font-size: 10px;
	padding: 2px 8px;
	border-radius: 10px;
	font-weight: 700;
}

/* ===== Sidebar Footer ===== */
.sidebar-footer {
	padding: 16px 20px;
	border-top: 1px solid rgba(255,255,255,0.08);
}

.admin-avatar {
	width: 34px;
	height: 34px;
	min-width: 34px;
	border-radius: 50%;
	background: linear-gradient(135deg, #4f8cf7, #3b6de7);
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-size: 14px;
}

/* ===== Main Content ===== */
.admin-main {
	flex: 0 0 calc(100% - 260px);
	width: calc(100% - 260px);
	max-width: calc(100% - 260px);
	min-width: 0;
	margin-left: 260px;
	display: flex;
	flex-direction: column;
	transition: margin-left 0.3s ease, width 0.3s ease, max-width 0.3s ease;
}

.sidebar-collapsed .admin-main {
	margin-left: 72px;
	flex-basis: calc(100% - 72px);
	width: calc(100% - 72px);
	max-width: calc(100% - 72px);
}

/* ===== Header ===== */
.admin-header {
	background: white;
	padding: 12px 24px;
	display: flex;
	align-items: center;
	justify-content: space-between;
	min-width: 0;
	border-bottom: 1px solid #e9ecef;
	position: sticky;
	top: 0;
	z-index: 1030;
}

.admin-search .form-control {
	width: 300px;
	border-radius: 20px;
	padding-left: 40px;
	background: #f8f9fa;
	border: 1px solid #e9ecef;
	height: 38px;
	font-size: 14px;
}

.admin-search .search-icon {
	position: absolute;
	left: 14px;
	top: 50%;
	transform: translateY(-50%);
	color: #adb5bd;
	font-size: 14px;
}

.admin-header-avatar {
	width: 36px;
	height: 36px;
	border-radius: 50%;
	background: linear-gradient(135deg, #4f8cf7, #3b6de7);
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-size: 14px;
}

/* ===== Page Content ===== */
.admin-content {
	flex-grow: 1;
	padding: 24px;
	min-width: 0;
	max-width: 100%;
	overflow-x: hidden;
}

/* ===== Mobile Overlay ===== */
.sidebar-overlay {
	display: none;
}

/* ===== Responsive ===== */
@media (max-width: 991px) {
	.admin-sidebar {
		transform: translateX(-100%);
	}

	.admin-wrapper:not(.sidebar-collapsed) .admin-sidebar {
		transform: translateX(0);
		width: 260px;
	}

	.admin-main {
		margin-left: 0 !important;
		flex-basis: 100%;
		width: 100%;
		max-width: 100%;
	}

	.sidebar-overlay {
		display: block;
		position: fixed;
		inset: 0;
		background: rgba(0,0,0,0.4);
		z-index: 1039;
	}

	.sidebar-collapsed .admin-sidebar {
		width: 260px;
		transform: translateX(-100%);
	}
}
</style>

<!-- Global admin button/icon fixes -->
<style>
/* Fix action button icon alignment across all admin pages */
.admin-content .btn-group .btn {
	padding: 5px 10px;
	font-size: 13px;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	line-height: 1;
	min-width: 32px;
	min-height: 30px;
}

.admin-content .btn-group .btn i {
	font-size: 12px;
	line-height: 1;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	width: auto;
	height: auto;
}

.admin-content .btn-group .btn .fa-solid,
.admin-content .btn-group .btn .fa-regular {
	vertical-align: middle;
}

/* Ensure all icon-only buttons are centered */
.admin-content .btn i:only-child {
	margin: 0;
}

/* Fix btn with icon + text alignment */
.admin-content .btn i + span,
.admin-content .btn i:not(:only-child) {
	vertical-align: middle;
}

/* Consistent table action button sizing */
.admin-content table .btn-group {
	gap: 0;
	display: inline-flex;
	align-items: stretch;
}

.admin-content table .btn-group .btn {
	border-radius: 0;
}

.admin-content table .btn-group .btn:first-child {
	border-top-left-radius: 20px;
	border-bottom-left-radius: 20px;
}

.admin-content table .btn-group .btn:last-child {
	border-top-right-radius: 20px;
	border-bottom-right-radius: 20px;
}
</style>
