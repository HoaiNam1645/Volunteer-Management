<template>
	<div class="nav-container primary-menu">
		<div class="mobile-topbar-header">
			<div>
					<img src="../../assets/images/logo-icon.png" class="logo-icon" alt="logo icon">
			</div>
			<div>
				<h4 class="logo-text">VMS-AI</h4>
			</div>
			<div class="toggle-icon ms-auto"><i class='bx bx-arrow-to-left'></i>
			</div>
		</div>
		<nav class="navbar navbar-expand-xl w-100">
			<ul class="navbar-nav justify-content-start flex-grow-1 gap-1">
				<!-- Home (always visible) -->
				<li class="nav-item">
					<router-link class="nav-link" to="/">
						<div class="parent-icon"><i class="fa-solid fa-home"></i></div>
						<div class="menu-title">{{ $t('nav.home') }}</div>
					</router-link>
				</li>

				<!-- Chiến dịch -->
				<li class="nav-item dropdown">
					<a href="/danh-sach-chien-dich" class="nav-link dropdown-toggle dropdown-toggle-nocaret"
						data-bs-toggle="dropdown">
						<div class="parent-icon"><i class="fa-solid fa-flag"></i></div>
						<div class="menu-title">{{ $t('nav.campaigns') }}</div>
					</a>
					<ul class="dropdown-menu">
						<li>
							<a class="dropdown-item" href="/danh-sach-chien-dich">
								<i class="bx bx-right-arrow-alt"></i>{{ $t('nav.campaignList') }}
							</a>
						</li>
						<li v-if="can('volunteer_campaigns.view')">
							<a class="dropdown-item" href="/quan-ly-chien-dich">
								<i class="bx bx-right-arrow-alt"></i>{{ $t('nav.myCampaigns') }}
							</a>
						</li>
					</ul>
				</li>

				<!-- Menu mở rộng cho tình nguyện viên -->
				<li class="nav-item dropdown" v-if="can('campaign_coordination.view') || can('campaign_report_monitoring.view')">
					<a href="javascript:;" class="nav-link dropdown-toggle dropdown-toggle-nocaret"
						data-bs-toggle="dropdown">
						<div class="parent-icon"><i class="fa-solid fa-people-arrows"></i></div>
						<div class="menu-title">{{ $t('nav.coordination') }}</div>
					</a>
					<ul class="dropdown-menu">
						<li v-if="can('campaign_coordination.view')">
							<a class="dropdown-item" href="/dieu-phoi-nhan-su">
								<i class="bx bx-right-arrow-alt"></i>{{ $t('nav.hrCoordination') }}
							</a>
						</li>
						<li v-if="can('campaign_report_monitoring.view')">
							<a class="dropdown-item" href="/giam-sat-bao-cao">
								<i class="bx bx-right-arrow-alt"></i>{{ $t('nav.monitorReport') }}
							</a>
						</li>
					</ul>
				</li>

				<!-- Hồ sơ (chỉ khi đã đăng nhập) -->
				<li class="nav-item dropdown" v-if="isLoggedIn && hasProfileMenu">
					<a href="javascript:;" class="nav-link dropdown-toggle dropdown-toggle-nocaret"
						data-bs-toggle="dropdown">
						<div class="parent-icon"><i class="fa-solid fa-id-card"></i></div>
						<div class="menu-title">{{ $t('nav.profile') }}</div>
					</a>
					<ul class="dropdown-menu">
						<li v-if="can('account_center.view')">
							<a class="dropdown-item" href="/thong-tin-ca-nhan">
								<i class="bx bx-right-arrow-alt"></i>{{ $t('nav.accountSettings') }}
							</a>
						</li>
						<li v-if="can('competency_profile.view')">
							<a class="dropdown-item" href="/ho-so-nang-luc">
								<i class="bx bx-right-arrow-alt"></i>{{ $t('nav.competencyProfile') }}
							</a>
						</li>
						<li v-if="can('feedback_tracking.view')">
							<a class="dropdown-item" href="/theo-doi-phan-hoi">
								<i class="bx bx-right-arrow-alt"></i>{{ $t('nav.trackingFeedback') }}
							</a>
						</li>
					</ul>
				</li>
			</ul>
		</nav>
	</div>
</template>
<script>
import { hasPermission } from '../../utils/permissions';

export default {
	data() {
		return {
			currentUser: null,
		}
	},
	computed: {
		isLoggedIn() {
			return !!this.currentUser;
		},
		userRole() {
			return this.currentUser ? this.currentUser.vai_tro : null;
		},
		hasProfileMenu() {
			return this.can('account_center.view')
				|| this.can('competency_profile.view')
				|| this.can('feedback_tracking.view');
		}
	},
	created() {
		this.loadUser();
	},
	mounted() {
		window.addEventListener('user-updated', this.loadUser);
	},
	beforeUnmount() {
		window.removeEventListener('user-updated', this.loadUser);
	},
	methods: {
		can(permission) {
			return hasPermission(this.currentUser, permission);
		},
		loadUser() {
			const userData = localStorage.getItem('user');
			if (userData) {
				try {
					this.currentUser = JSON.parse(userData);
				} catch (e) {
					this.currentUser = null;
				}
			}
		}
	},
	watch: {
		'$route'() {
			this.loadUser();
		}
	}
}
</script>
<style></style>
