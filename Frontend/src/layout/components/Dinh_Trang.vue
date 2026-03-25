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
					
					<input
						ref="searchInput"
						type="text"
						class="form-control header-search-input"
						:placeholder="$t('header.searchPlaceholder')"
						v-model.trim="searchKeyword"
						@focus="handleSearchFocus"
						@input="handleSearchInput"
						@keyup.enter="submitSearch"
					>

					<div v-if="shouldShowSuggestions" class="search-suggestion-panel card border-0 shadow-lg">
						<div class="card-body p-0">
							<div class="search-suggestion-header d-flex align-items-center justify-content-between px-3 py-2 border-bottom">
								<span class="small fw-semibold text-muted">{{ $t('header.searchSuggestionsTitle') }}</span>
								<span class="badge rounded-pill text-bg-light">{{ suggestionItems.length }}</span>
							</div>

							<div v-if="isSearching" class="px-3 py-4 text-center text-muted small">
								<div class="spinner-border spinner-border-sm text-primary me-2" role="status"></div>
								{{ $t('header.searchingCampaigns') }}
							</div>

							<div v-else-if="suggestionItems.length > 0" class="list-group list-group-flush">
								<button
									v-for="campaign in suggestionItems"
									:key="campaign.id"
									type="button"
									class="list-group-item list-group-item-action px-3 py-3"
									@click="selectSuggestion(campaign)"
								>
									<div class="d-flex align-items-center gap-3">
										<div class="suggestion-cover rounded-3 overflow-hidden flex-shrink-0" :style="getSuggestionCoverStyle(campaign)"></div>
										<div class="min-w-0 flex-grow-1 text-start">
											<div class="fw-semibold text-dark text-truncate mb-1">{{ campaign.tieu_de }}</div>
											<div class="small text-muted text-truncate mb-1">
												<i class="fa-solid fa-location-dot text-danger me-1"></i>{{ campaign.dia_diem || $t('common.notAvailable') }}
											</div>
											<div class="d-flex flex-wrap align-items-center gap-2 small text-muted">
												<span class="badge rounded-pill text-bg-light">{{ campaign.loai_chien_dich?.ten || $t('campaignList.defaultCategory') }}</span>
												<span>{{ formatDate(campaign.ngay_bat_dau) }}</span>
											</div>
										</div>
									</div>
								</button>
							</div>

							<div v-else-if="searchKeyword.trim().length >= minKeywordLength" class="px-3 py-4 text-center text-muted small">
								<i class="fa-solid fa-magnifying-glass d-block mb-2 opacity-50"></i>
								{{ $t('header.noCampaignSuggestions') }}
							</div>

							<div v-if="searchKeyword.trim().length >= minKeywordLength" class="border-top px-3 py-2 bg-light-subtle">
								<button type="button" class="btn btn-primary btn-sm w-100 rounded-pill" @click="submitSearch">
									<i class="fa-solid fa-arrow-right me-2"></i>{{ $t('header.viewAllSearchResults', { keyword: searchKeyword.trim() }) }}
								</button>
							</div>
						</div>
					</div>
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
					<div class="user-avatar bg-primary overflow-hidden">
						<img
							v-if="currentUser?.anh_dai_dien"
							:src="currentUser.anh_dai_dien"
							:alt="currentUser?.ho_ten || 'Avatar'"
							class="user-avatar-image"
						>
						<span v-else class="user-avatar-fallback text-white">{{ userInitials }}</span>
					</div>
					<div class="user-info ps-3">
						<p class="user-name mb-0">{{ currentUser.ho_ten }}</p>
						<p class="designattion mb-0">{{ getRoleLabel(currentUser.vai_tro) }}</p>
					</div>
				</a>
				<ul class="dropdown-menu dropdown-menu-end">
					<li v-if="can('account_center.view')"><router-link class="dropdown-item" to="/thong-tin-ca-nhan"><i class="bx bx-user"></i><span>{{ $t('header.myProfile') }}</span></router-link></li>
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
import { hasPermission } from '@/utils/permissions';

export default {
	components: {
		LanguageSwitcher
	},
	data() {
		return {
			currentUser: null,
			searchKeyword: '',
			suggestionItems: [],
			isSearching: false,
			isSearchFocused: false,
			searchDebounceTimer: null,
			minKeywordLength: 2,
		}
	},
	computed: {
		isLoggedIn() {
			return !!this.currentUser;
		},
		userInitials() {
			const fullName = (this.currentUser?.ho_ten || '').trim();
			if (!fullName) {
				return 'U';
			}
			return fullName
				.split(/\s+/)
				.slice(0, 2)
				.map((word) => word.charAt(0).toUpperCase())
				.join('');
		},
		shouldShowSuggestions() {
			return this.isSearchFocused && this.searchKeyword.trim().length >= this.minKeywordLength;
		},
	},
	created() {
		this.loadUser();
		this.syncSearchKeywordFromRoute();
	},
	mounted() {
		document.addEventListener('click', this.handleOutsideClick);
		window.addEventListener('user-updated', this.loadUser);
	},
	beforeUnmount() {
		document.removeEventListener('click', this.handleOutsideClick);
		window.removeEventListener('user-updated', this.loadUser);
		if (this.searchDebounceTimer) {
			clearTimeout(this.searchDebounceTimer);
		}
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
		},
		getRoleLabel(role) {
			const map = {
				'tinh_nguyen_vien': 'Tình nguyện viên',
				'kiem_duyet_vien': 'Kiểm duyệt viên',
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
		},
		syncSearchKeywordFromRoute() {
			const routeKeyword = typeof this.$route.query.name === 'string' ? this.$route.query.name.trim() : '';
			this.searchKeyword = routeKeyword;
			this.suggestionItems = [];
		},
		async fetchSearchSuggestions() {
			const keyword = this.searchKeyword.trim();
			if (keyword.length < this.minKeywordLength) {
				this.suggestionItems = [];
				this.isSearching = false;
				return;
			}

			this.isSearching = true;
			try {
				const res = await api.get('/chien-dich/tim-kiem', {
					params: {
						name: keyword,
						limit: 5,
					},
				});
				this.suggestionItems = Array.isArray(res.data?.data) ? res.data.data : [];
			} catch (_error) {
				this.suggestionItems = [];
			} finally {
				this.isSearching = false;
			}
		},
		handleSearchFocus() {
			this.isSearchFocused = true;
			if (this.searchKeyword.trim().length >= this.minKeywordLength && this.suggestionItems.length === 0) {
				this.fetchSearchSuggestions();
			}
		},
		handleSearchInput() {
			if (this.searchDebounceTimer) {
				clearTimeout(this.searchDebounceTimer);
			}
			if (this.searchKeyword.trim().length < this.minKeywordLength) {
				this.suggestionItems = [];
				this.isSearching = false;
				return;
			}
			this.searchDebounceTimer = setTimeout(() => {
				this.fetchSearchSuggestions();
			}, 250);
		},
		handleOutsideClick(event) {
			if (!this.$el.contains(event.target)) {
				this.isSearchFocused = false;
			}
		},
		submitSearch() {
			const keyword = this.searchKeyword.trim();
			this.isSearchFocused = false;
			if (!keyword) {
				this.$router.push({ path: '/danh-sach-chien-dich' });
				return;
			}
			this.$router.push({
				path: '/danh-sach-chien-dich',
				query: { name: keyword },
			});
		},
		selectSuggestion(campaign) {
			const keyword = (campaign?.tieu_de || '').trim();
			if (!keyword) {
				return;
			}
			this.searchKeyword = keyword;
			this.submitSearch();
		},
		clearSearch() {
			this.searchKeyword = '';
			this.suggestionItems = [];
			this.isSearchFocused = false;
			if (this.$route.path === '/danh-sach-chien-dich' && this.$route.query.name) {
				this.$router.push({ path: '/danh-sach-chien-dich' });
			}
		},
		getSuggestionCoverStyle(campaign) {
			if (campaign?.anh_bia) {
				return {
					background: `linear-gradient(rgba(15,23,42,.18), rgba(15,23,42,.18)), url(${campaign.anh_bia}) center/cover`,
				};
			}
			return {
				background: 'linear-gradient(135deg, #0d6efd, #0dcaf0)',
			};
		},
		formatDate(date) {
			if (!date) return this.$t('common.notAvailable');
			const parsed = new Date(date);
			if (Number.isNaN(parsed.getTime())) return date;
			return parsed.toLocaleDateString('vi-VN');
		}
	},
	watch: {
		'$route'() {
			this.loadUser();
			this.syncSearchKeywordFromRoute();
		}
	}
}
</script>
<style scoped>
.search-bar-box {
	position: relative;
	width: 100%;
	max-width: 720px;
}

.header-search-input {
	height: 52px;
	padding-left: 1.25rem !important;
	padding-right: 1.25rem !important;
	border-radius: 16px;
	background-color: #fff;
	border: 1px solid #d8e2f0;
	box-shadow: 0 8px 24px rgba(15, 23, 42, 0.06);
}

.header-search-input:focus {
	border-color: #86b7fe;
	box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.15);
}

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
	flex-shrink: 0;
}

.user-avatar-image {
	width: 100%;
	height: 100%;
	object-fit: cover;
	display: block;
}

.user-avatar-fallback {
	font-size: 13px;
	font-weight: 700;
	letter-spacing: 0.04em;
}

.search-suggestion-panel {
	position: absolute;
	top: calc(100% + 10px);
	left: 0;
	right: 0;
	width: 100%;
	min-width: 100%;
	max-width: 100%;
	margin: 0;
	box-sizing: border-box;
	z-index: 1200;
	border-radius: 18px;
	overflow: hidden;
}

.search-suggestion-header {
	background: linear-gradient(135deg, #f8fbff, #ffffff);
}

.suggestion-cover {
	width: 68px;
	height: 68px;
	background: linear-gradient(135deg, #0d6efd, #0dcaf0);
}

.min-w-0 {
	min-width: 0;
}

@media (max-width: 991.98px) {
	.search-suggestion-panel {
		width: 100%;
		max-width: 100%;
	}
}
</style>
