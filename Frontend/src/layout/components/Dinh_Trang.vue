<template>
	<div class="topbar d-flex align-items-center">
		<nav class="navbar navbar-expand">
			<div class="topbar-logo-header">
				<div>
					<div class="topbar-logo-box bg-primary">
						<i class="fa-solid fa-hands-holding-circle text-white"></i>
					</div>
				</div>
				<div>
					<h4 class="logo-text">VMS-AI</h4>
				</div>
			</div>
			<div class="mobile-toggle-menu"><i class='bx bx-menu'></i></div>
			<div class="search-bar flex-grow-1">
				<div class="position-relative search-bar-box">
					<input type="text" class="form-control search-control" :placeholder="$t('header.searchPlaceholder')">
					<span class="position-absolute top-50 search-show translate-middle-y"><i class='bx bx-search'></i></span>
					<span class="position-absolute top-50 search-close translate-middle-y"><i class='bx bx-x'></i></span>
				</div>
			</div>
			<div class="top-menu ms-auto d-flex align-items-center">
				<LanguageSwitcher />
				
				<!-- Khi đã đăng nhập -->
				<template v-if="isLoggedIn">
					<ul class="navbar-nav align-items-center">
						<li class="nav-item mobile-search-icon">
							<a class="nav-link" href="#"><i class='bx bx-search'></i></a>
						</li>
						<!-- Notifications -->
						<li class="nav-item dropdown dropdown-large">
							<a class="nav-link dropdown-toggle dropdown-toggle-nocaret position-relative" href="#"
								role="button" data-bs-toggle="dropdown" aria-expanded="false">
								<span class="alert-count">3</span>
								<i class='bx bx-bell'></i>
							</a>
							<div class="dropdown-menu dropdown-menu-end">
								<a href="javascript:;">
									<div class="msg-header">
										<p class="msg-header-title">{{ $t('header.notifications') }}</p>
										<p class="msg-header-clear ms-auto">{{ $t('header.markAllRead') }}</p>
									</div>
								</a>
								<div class="header-notifications-list">
									<a class="dropdown-item" href="javascript:;">
										<div class="d-flex align-items-center">
											<div class="notify bg-light-primary text-primary"><i class="fa-solid fa-flag"></i></div>
											<div class="flex-grow-1">
												<h6 class="msg-name">{{ $t('header.newCampaign') }}<span class="msg-time float-end">5 {{ $t('header.minutesAgo') }}</span></h6>
												<p class="msg-info">{{ $t('header.notification1Desc') }}</p>
											</div>
										</div>
									</a>
								</div>
								<a href="javascript:;">
									<div class="text-center msg-footer">{{ $t('header.viewAllNotifications') }}</div>
								</a>
							</div>
						</li>
					</ul>
				</template>
			</div>

			<!-- User Box: đã đăng nhập -->
			<div v-if="isLoggedIn" class="user-box dropdown px-3">
				<a class="d-flex align-items-center nav-link dropdown-toggle dropdown-toggle-nocaret" href="#"
					role="button" data-bs-toggle="dropdown" aria-expanded="false">
					<div class="user-avatar bg-primary">
						<i class="fa-solid fa-user text-white"></i>
					</div>
					<div class="user-info ps-3">
						<p class="user-name mb-0">{{ currentUser.ho_ten }}</p>
						<p class="designattion mb-0">{{ getRoleLabel(currentUser.vai_tro) }}</p>
					</div>
				</a>
				<ul class="dropdown-menu dropdown-menu-end">
					<li><router-link class="dropdown-item" to="/thong-tin-ca-nhan"><i class="bx bx-user"></i><span>{{ $t('header.myProfile') }}</span></router-link></li>
					<li><a class="dropdown-item" href="javascript:;"><i class="bx bx-cog"></i><span>{{ $t('header.settings') }}</span></a></li>
					<li><div class="dropdown-divider mb-0"></div></li>
					<li>
						<a class="dropdown-item" href="javascript:;" @click="handleLogout">
							<i class='bx bx-log-out-circle'></i><span>{{ $t('header.logout') }}</span>
						</a>
					</li>
				</ul>
			</div>

			<!-- Guest: chưa đăng nhập -->
			<div v-else class="d-flex align-items-center gap-2 px-3">
				<router-link to="/dang-nhap" class="btn btn-primary btn-sm px-3 py-2 fw-semibold rounded-3">
					<i class="fa-solid fa-right-to-bracket me-1"></i> {{ $t('header.loginBtn') }}
				</router-link>
				<router-link to="/dang-ky" class="btn btn-outline-primary btn-sm px-3 py-2 fw-semibold rounded-3 d-none d-md-inline-block">
					{{ $t('header.registerBtn') }}
				</router-link>
			</div>
		</nav>
	</div>
</template>
<script>
import LanguageSwitcher from '@/components/LanguageSwitcher.vue';
import api from '@/services/api.js';

export default {
	components: {
		LanguageSwitcher
	},
	data() {
		return {
			currentUser: null,
		}
	},
	computed: {
		isLoggedIn() {
			return !!this.currentUser;
		}
	},
	created() {
		this.loadUser();
	},
	methods: {
		loadUser() {
			const userData = localStorage.getItem('user');
			if (userData) {
				try {
					this.currentUser = JSON.parse(userData);
				} catch (e) {
					this.currentUser = null;
				}
			}
		},
		getRoleLabel(role) {
			const map = {
				'tinh_nguyen_vien': 'Tình nguyện viên',
				'dieu_phoi_vien': 'Điều phối viên',
				'quan_tri_vien': 'Quản trị viên',
			};
			return map[role] || role;
		},
		async handleLogout() {
			try {
				await api.post('/xac-thuc/dang-xuat');
			} catch (e) {
				// Ignore
			}
			localStorage.removeItem('token');
			localStorage.removeItem('user');
			this.currentUser = null;
			this.$router.push('/dang-nhap');
		}
	},
	watch: {
		'$route'() {
			this.loadUser();
		}
	}
}
</script>
<style scoped>
.topbar-logo-box {
	width: 34px;
	height: 34px;
	border-radius: 8px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 17px;
}

.user-avatar {
	width: 38px;
	height: 38px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 15px;
}
</style>