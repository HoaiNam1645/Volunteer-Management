<template>
	<div class="bg-light min-vh-100 pb-5">
		<div class="container pt-4">
			<div v-if="searchKeyword" class="card border-0 shadow-sm mb-4 search-result-banner overflow-hidden">
				<div class="card-body p-4 p-lg-5 position-relative">
					<div class="search-banner-shape search-banner-shape-1"></div>
					<div class="search-banner-shape search-banner-shape-2"></div>
					<div class="position-relative d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-3">
						<div>
							<div class="d-inline-flex align-items-center gap-2 badge rounded-pill text-bg-primary px-3 py-2 mb-3">
								<i class="fa-solid fa-magnifying-glass"></i>
								<span>{{ $t('campaignList.searchResultBadge') }}</span>
							</div>
							<h3 class="fw-bold mb-2">{{ $t('campaignList.searchResultTitle', { keyword: searchKeyword }) }}</h3>
							<p class="text-muted mb-0">{{ $t('campaignList.searchResultDesc', { count: sortedCampaigns.length }) }}</p>
						</div>
						<button class="btn btn-outline-secondary rounded-pill px-4 align-self-start align-self-lg-center" @click="clearSearchQuery">
							<i class="fa-solid fa-xmark me-2"></i>{{ $t('campaignList.clearSearchQuery') }}
						</button>
					</div>
				</div>
			</div>

			<!-- Mobile Filter Toggle -->
			<div class="d-lg-none mb-3">
				<button class="btn btn-primary w-100 fw-medium d-flex align-items-center justify-content-center gap-2" type="button" data-bs-toggle="offcanvas" data-bs-target="#filterOffcanvas">
					<i class="fa-solid fa-filter"></i> {{ $t('campaignList.filterCampaigns') }}
				</button>
			</div>

			<div class="row g-4">
				<!-- LEFT: Filters (Sidebar for Desktop) -->
				<div class="col-lg-3 d-none d-lg-block">
					<div class="card border-0 shadow-sm position-sticky" style="top: 20px;">
						<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-filter me-2 text-primary"></i>{{ $t('campaignList.filters') }}</h6>
							<a href="#" class="small text-muted text-decoration-none" @click.prevent="clearFilters">{{ $t('campaignList.clearFilter') }}</a>
						</div>
						<div class="card-body p-0">
							<!-- Search -->
							<div class="p-3 border-bottom">
								<div class="input-group">
									<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
									<input type="text" class="form-control bg-light border-start-0 ps-0" :placeholder="$t('campaignList.campaignNamePlaceholder')" v-model="filters.search">
								</div>
							</div>

							<!-- Trạng thái -->
							<div class="p-3 border-bottom">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.status') }}</h6>
								<div class="form-check mb-2" v-for="status in filterMeta.statuses" :key="status.value">
									<input class="form-check-input" type="checkbox" :id="'status-' + status.value" :value="status.value" v-model="filters.status">
									<label class="form-check-label small d-flex justify-content-between align-items-center w-100" :for="'status-' + status.value">
										<span>{{ getFilterStatusLabel(status.value) }}</span>
										<span class="badge bg-light text-muted fw-normal rounded-pill">{{ status.count }}</span>
									</label>
								</div>
							</div>

							<!-- Loại chiến dịch -->
							<div class="p-3 border-bottom">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.field') }}</h6>
								<div class="form-check mb-2" v-for="cat in filterMeta.categories" :key="cat.value">
									<input class="form-check-input" type="checkbox" :id="'cat-'+cat.value" :value="cat.value" v-model="filters.category">
									<label class="form-check-label small d-flex justify-content-between align-items-center w-100" :for="'cat-'+cat.value">
										<span>{{ cat.label }}</span>
										<span class="badge bg-light text-muted fw-normal rounded-pill">{{ cat.count }}</span>
									</label>
								</div>
							</div>

							<!-- Địa điểm -->
							<div class="p-3 border-bottom">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.location') }}</h6>
								<select class="form-select form-select-sm" v-model="filters.location">
									<option value="">{{ $t('campaignList.allAreas') }}</option>
									<option v-for="location in filterMeta.locations" :key="location.value" :value="location.value">{{ location.value }}</option>
								</select>
							</div>

							<!-- Người điều phối -->
							<div class="p-3">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.creatorLabel') }}</h6>
								<select class="form-select form-select-sm" v-model="filters.coordinator">
									<option value="">{{ $t('common.all') }}</option>
									<option v-for="coord in filterMeta.creators" :key="coord.value" :value="coord.value">
										{{ coord.label }}
									</option>
								</select>
							</div>
						</div>
					</div>
				</div>

				<!-- RIGHT: Main Content -->
				<div class="col-lg-9">
					<!-- Top Sort Bar -->
					<div class="card border-0 shadow-sm mb-4">
						<div class="card-body p-3 d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3">
							<div class="text-muted small">
								{{ $t('campaignList.showingResults') }} <strong>{{ sortedCampaigns.length }}</strong> {{ $t('campaignList.resultsLabel') }}
							</div>
							<div class="d-flex align-items-center gap-2">
								<span class="text-muted small fw-medium text-nowrap">{{ $t('campaignList.sortBy') }}</span>
								<select class="form-select form-select-sm bg-light border-0" style="width: 160px;" v-model="sortBy">
									<option value="newest">{{ $t('campaignList.newest') }}</option>
									<option value="urgent">{{ $t('campaignList.urgentFirst') }}</option>
									<option value="soonest">{{ $t('campaignList.soonest') }}</option>
								</select>
							</div>
						</div>
					</div>

					<div v-if="loading" class="row g-4">
						<div class="col-md-6 col-xl-4" v-for="n in 6" :key="n">
							<div class="card h-100 border-0 shadow-sm placeholder-glow">
								<div class="placeholder campaign-banner-img"></div>
								<div class="card-body p-4">
									<span class="placeholder col-9 mb-3 d-block"></span>
									<span class="placeholder col-12 mb-2 d-block"></span>
									<span class="placeholder col-8 mb-4 d-block"></span>
									<span class="placeholder col-6 d-block"></span>
								</div>
							</div>
						</div>
					</div>

					<!-- Campaigns Grid -->
					<div v-else class="row g-4">
						<div class="col-md-6 col-xl-4" v-for="campaign in sortedCampaigns" :key="campaign.id">
							<div class="card h-100 border-0 shadow-sm campaign-card">
								<!-- Image/Banner Placeholder -->
								<div class="campaign-banner-img position-relative" :style="getCampaignBannerStyle(campaign)">
									<div class="position-absolute top-0 start-0 m-3 d-flex flex-column gap-2">
										<span class="badge bg-white text-dark shadow-sm">{{ campaign.categoryLabel }}</span>
										<span class="badge" :class="getPriorityClassBadge(campaign.priority)">{{ getPriorityLabel(campaign.priority) }}</span>
									</div>
									<div class="position-absolute bottom-0 end-0 m-3 d-flex flex-column align-items-end gap-2">
										<span class="badge shadow-sm" :class="getStatusClassBadge(campaign.status)">
											<i class="me-1" :class="getStatusIconBadge(campaign.status)"></i>{{ getStatusLabel(campaign.status) }}
										</span>
										<span v-if="campaign.personalRegistrationLabel" class="badge bg-light text-dark border shadow-sm">{{ campaign.personalRegistrationLabel }}</span>
									</div>
								</div>

								<div class="card-body p-4 d-flex flex-column">
									<div class="d-flex align-items-center gap-2 mb-3">
										<div class="avatar-sm bg-primary bg-opacity-10 text-primary rounded-circle d-flex align-items-center justify-content-center fw-bold small">
											{{ getCoordinatorInitial(campaign.coordinatorName) }}
										</div>
										<span class="small text-muted text-truncate">{{ campaign.coordinatorName }}</span>
									</div>

									<!-- Title & Desc -->
									<h5 class="fw-bold mb-2 text-truncate-2" style="min-height: 48px;"><router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="text-dark text-decoration-none stretched-link">{{ campaign.title }}</router-link></h5>
									<p class="text-muted small mb-3 text-truncate-2 flex-grow-1">{{ campaign.description }}</p>

									<!-- Meta -->
									<div class="d-flex flex-column gap-2 small text-muted mb-4">
										<div class="d-flex align-items-center gap-2 text-truncate">
											<i class="fa-solid fa-location-dot text-danger" style="width: 16px;"></i>
											<span class="text-truncate">{{ campaign.location }}</span>
										</div>
										<div class="d-flex align-items-center gap-2">
											<i class="fa-regular fa-calendar text-primary" style="width: 16px;"></i>
											<span>{{ campaign.startDate }} — {{ campaign.endDate }}</span>
										</div>
									</div>

									<!-- Progress -->
									<div class="mt-auto">
										<div class="d-flex justify-content-between align-items-end mb-1 small">
											<span class="fw-medium text-dark">{{ campaign.registered }} <span class="text-muted fw-normal">/ {{ campaign.maxVolunteers }} {{ $t('common.volunteerShort') }}</span></span>
											<span class="fw-bold" :class="getProgressColor(campaign)">{{ getProgress(campaign) }}%</span>
										</div>
										<div class="progress" style="height: 6px;">
											<div class="progress-bar" :class="`bg-${getProgressColorClass(campaign)}`" :style="{ width: getProgress(campaign) + '%' }"></div>
										</div>
									</div>
								</div>
							</div>
						</div>

						<!-- Empty State -->
						<div class="col-12" v-if="sortedCampaigns.length === 0">
							<div class="card border-0 shadow-sm text-center py-5">
								<div class="card-body">
									<i class="fa-solid fa-search fs-1 text-muted opacity-25 mb-3"></i>
									<h5 class="fw-bold">{{ $t('campaignList.noCampaignFound') }}</h5>
									<p class="text-muted">{{ $t('campaignList.noCampaignFoundDesc') }}</p>
									<button class="btn btn-outline-primary mt-2" @click="clearFilters">{{ $t('campaignList.clearFilters') }}</button>
								</div>
							</div>
						</div>
					</div>

					<!-- Pagination -->
					<nav class="mt-5" v-if="sortedCampaigns.length > 0">
						<ul class="pagination justify-content-center border-0">
							<li class="page-item disabled"><a class="page-link border-0 shadow-sm rounded-start-pill px-3" href="#">{{ $t('campaignList.prev') }}</a></li>
							<li class="page-item active"><a class="page-link border-0 shadow-sm" href="#">1</a></li>
							<li class="page-item disabled"><a class="page-link border-0 shadow-sm rounded-end-pill px-3" href="#">{{ $t('campaignList.nextPage') }}</a></li>
						</ul>
					</nav>
				</div>
			</div>
		</div>

		<!-- Mobile Filter Offcanvas -->
		<div class="offcanvas offcanvas-bottom rounded-top-4" style="height: 85vh;" tabindex="-1" id="filterOffcanvas">
			<div class="offcanvas-header border-bottom py-3">
				<h5 class="offcanvas-title fw-bold"><i class="fa-solid fa-filter me-2 text-primary"></i>{{ $t('campaignList.filters') }}</h5>
				<button type="button" class="btn-close" data-bs-dismiss="offcanvas"></button>
			</div>
			<div class="offcanvas-body">
				<!-- Search -->
				<div class="mb-4">
					<label class="form-label fw-bold small text-muted text-uppercase">{{ $t('campaignList.search') }}</label>
					<div class="input-group">
						<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
						<input type="text" class="form-control bg-light border-start-0 ps-0" :placeholder="$t('campaignList.campaignNamePlaceholder')" v-model="filters.search">
					</div>
				</div>

				<!-- Trạng thái -->
				<div class="mb-4">
					<label class="form-label fw-bold small text-muted text-uppercase">{{ $t('campaignList.status') }}</label>
					<div class="d-flex flex-wrap gap-2">
						<div v-for="status in filterMeta.statuses" :key="'mob-' + status.value">
							<input type="checkbox" class="btn-check" :id="'mob-st-' + status.value" :value="status.value" v-model="filters.status">
							<label class="btn btn-outline-secondary btn-sm rounded-pill" :for="'mob-st-' + status.value">{{ getFilterStatusLabel(status.value) }}</label>
						</div>
					</div>
				</div>

				<!-- Lĩnh vực -->
				<div class="mb-4">
					<label class="form-label fw-bold small text-muted text-uppercase">{{ $t('campaignList.field') }}</label>
					<div class="d-flex flex-wrap gap-2">
						<div v-for="cat in filterMeta.categories" :key="'mob-'+cat.value">
							<input type="checkbox" class="btn-check" :id="'mob-cat-'+cat.value" :value="cat.value" v-model="filters.category">
							<label class="btn btn-outline-secondary btn-sm rounded-pill" :for="'mob-cat-'+cat.value">{{ cat.label }}</label>
						</div>
					</div>
				</div>

				<!-- Footer Buttons -->
				<div class="d-flex gap-2 mt-5">
					<button class="btn btn-light w-50" @click="clearFilters">{{ $t('campaignList.clearFilter') }}</button>
					<button class="btn btn-primary w-50" data-bs-dismiss="offcanvas">{{ $t('common.apply') }} ({{ sortedCampaigns.length }})</button>
				</div>
			</div>
		</div>

	</div>
</template>

<script>
import api from '@/services/api.js';

export default {
	name: 'DanhSachChienDich',
	inject: ['toast'],
	data() {
		return {
			loading: false,
			sortBy: 'newest',
			searchKeyword: '',
			filterMeta: {
				statuses: [],
				categories: [],
				locations: [],
				creators: [],
			},
			filters: {
				search: '',
				status: [],
				category: [],
				location: '',
				coordinator: ''
			},
			campaigns: [],
			searchDebounceTimer: null,
			suspendFilterReload: false,
			suspendRouteWatcher: false,
		}
	},
	computed: {
		sortedCampaigns() {
			const arr = [...this.campaigns];
			if (this.sortBy === 'urgent') {
				const priorityVal = { urgent: 3, high: 2, medium: 1, low: 0 };
				arr.sort((a, b) => priorityVal[b.priority] - priorityVal[a.priority]);
			} else if (this.sortBy === 'soonest') {
				arr.sort((a, b) => a.startDateRaw.localeCompare(b.startDateRaw));
			} else {
				arr.sort((a, b) => b.id - a.id);
			}
			return arr;
		}
	},
	async mounted() {
		this.syncFiltersFromRoute();
		await Promise.all([this.loadFilterMeta(), this.loadCampaigns()]);
	},
	beforeUnmount() {
		if (this.searchDebounceTimer) {
			clearTimeout(this.searchDebounceTimer);
		}
	},
	watch: {
		'$route.query': {
			deep: true,
			handler() {
				if (this.suspendRouteWatcher) return;
				this.syncFiltersFromRoute();
				this.loadCampaigns();
			},
		},
		'filters.status': {
			deep: true,
			handler() {
				if (this.suspendFilterReload) return;
				this.loadCampaigns();
			},
		},
		'filters.category': {
			deep: true,
			handler() {
				if (this.suspendFilterReload) return;
				this.loadCampaigns();
			},
		},
		'filters.location'() {
			if (this.suspendFilterReload) return;
			this.loadCampaigns();
		},
		'filters.coordinator'() {
			if (this.suspendFilterReload) return;
			this.loadCampaigns();
		},
		'filters.search'(value, oldValue) {
			if (this.suspendFilterReload) return;
			if (value === this.searchKeyword && oldValue === undefined) {
				return;
			}
			if (this.searchDebounceTimer) {
				clearTimeout(this.searchDebounceTimer);
			}
			this.searchDebounceTimer = setTimeout(() => {
				this.loadCampaigns();
			}, 300);
		},
		sortBy() {
			this.syncRouteQuery();
		},
	},
	methods: {
		async loadFilterMeta() {
			try {
				const res = await api.get('/chien-dich/bo-loc');
				if (res.data?.status === 1) {
					this.filterMeta = {
						statuses: res.data.data?.statuses || [],
						categories: res.data.data?.categories || [],
						locations: res.data.data?.locations || [],
						creators: res.data.data?.creators || [],
					};
				}
			} catch (error) {
				this.showToast(
					'error',
					this.$t('common.error'),
					error.response?.data?.message || this.$t('campaignList.loadErrorMessage')
				);
			}
		},
		syncFiltersFromRoute() {
			const query = this.$route.query || {};
			const keyword = typeof query.name === 'string' ? query.name.trim() : '';
			const statuses = typeof query.status === 'string' && query.status.trim()
				? query.status.split(',').map(item => item.trim()).filter(Boolean)
				: [];
			const categories = typeof query.category === 'string' && query.category.trim()
				? query.category.split(',').map(item => item.trim()).filter(Boolean)
				: [];

			this.suspendFilterReload = true;
			this.searchKeyword = keyword;
			this.sortBy = typeof query.sort === 'string' && query.sort.trim() ? query.sort : 'newest';
			this.filters = {
				search: keyword,
				status: statuses,
				category: categories,
				location: typeof query.location === 'string' ? query.location : '',
				coordinator: typeof query.coordinator === 'string' ? query.coordinator : '',
			};
			this.$nextTick(() => {
				this.suspendFilterReload = false;
			});
		},
		buildRouteQuery() {
			const query = {};
			const keyword = this.filters.search.trim() || this.searchKeyword.trim();
			if (keyword) query.name = keyword;
			if (this.filters.status.length) query.status = this.filters.status.join(',');
			if (this.filters.category.length) query.category = this.filters.category.join(',');
			if (this.filters.location) query.location = this.filters.location;
			if (this.filters.coordinator) query.coordinator = this.filters.coordinator;
			if (this.sortBy && this.sortBy !== 'newest') query.sort = this.sortBy;
			return query;
		},
		async syncRouteQuery() {
			const currentQuery = JSON.stringify(this.$route.query || {});
			const nextQuery = JSON.stringify(this.buildRouteQuery());
			if (currentQuery === nextQuery) return;
			this.suspendRouteWatcher = true;
			try {
				await this.$router.replace({ path: this.$route.path, query: JSON.parse(nextQuery) });
			} finally {
				this.suspendRouteWatcher = false;
			}
		},
		async loadCampaigns() {
			this.loading = true;
			try {
				await this.syncRouteQuery();

				const params = {};
				const routeKeyword = this.searchKeyword.trim();
				const filterKeyword = this.filters.search.trim();
				const effectiveKeyword = filterKeyword || routeKeyword;

				if (effectiveKeyword) params.tu_khoa = effectiveKeyword;
				if (this.filters.status.length) {
					params.trang_thai = this.filters.status.map(this.mapStatusToApi).join(',');
				}
				if (this.filters.category.length) {
					params.loai_chien_dich_ids = this.filters.category.join(',');
				}
				if (this.filters.location) params.dia_diem = this.filters.location;
				if (this.filters.coordinator) params.nguoi_tao_id = this.filters.coordinator;

				const res = await api.get('/chien-dich', { params });
				this.campaigns = (res.data?.data || []).map(item => this.mapCampaignFromApi(item));
			} catch (error) {
				this.showToast(
					'error',
					this.$t('common.error'),
					error.response?.data?.message || this.$t('campaignList.loadErrorMessage')
				);
			} finally {
				this.loading = false;
			}
		},
		mapCampaignFromApi(item) {
			const status = this.mapCampaignStatus(item.trang_thai);
			const priority = this.mapPriority(item.muc_do_uu_tien);
			const coordinatorId = String(item.nguoi_tao?.id || item.duyet_boi?.id || item.id);
			const coordinatorName = item.nguoi_tao?.ho_ten || item.duyet_boi?.ho_ten || this.$t('campaignList.unknownCreator');
			return {
				id: item.id,
				coordinatorId,
				coordinatorName,
				title: item.tieu_de || this.$t('common.notAvailable'),
				description: item.mo_ta || '',
				category: String(item.loai_chien_dich?.id || item.id),
				categoryLabel: item.loai_chien_dich?.ten || this.$t('campaignList.defaultCategory'),
				priority,
				location: item.dia_diem || this.$t('common.notAvailable'),
				startDate: this.formatDate(item.ngay_bat_dau),
				endDate: this.formatDate(item.ngay_ket_thuc),
				startDateRaw: item.ngay_bat_dau || '',
				endDateRaw: item.ngay_ket_thuc || '',
				maxVolunteers: item.so_luong_toi_da || 0,
				registered: item.so_dang_ky || 0,
				confirmed: item.so_xac_nhan || 0,
				status,
				color: this.getBannerColor(priority),
				coverUrl: item.anh_bia || null,
				personalRegistrationLabel: this.getRegistrationLabel(item.dang_ky_hien_tai?.trang_thai),
			};
		},
		mapCampaignStatus(status) {
			return {
				da_duyet: 'registering',
				dang_dien_ra: 'upcoming',
				hoan_thanh: 'completed',
			}[status] || 'registering';
		},
		mapStatusToApi(status) {
			return {
				registering: 'da_duyet',
				upcoming: 'dang_dien_ra',
				completed: 'hoan_thanh',
			}[status] || status;
		},
		mapPriority(priority) {
			return {
				thap: 'low',
				trung_binh: 'medium',
				cao: 'high',
				khan_cap: 'urgent',
			}[priority] || 'medium';
		},
		getBannerColor(priority) {
			return {
				urgent: 'linear-gradient(135deg, #dc3545, #e35d6a)',
				high: 'linear-gradient(135deg, #fd7e14, #ffc107)',
				medium: 'linear-gradient(135deg, #0d6efd, #0dcaf0)',
				low: 'linear-gradient(135deg, #6c757d, #adb5bd)',
			}[priority] || 'linear-gradient(135deg, #0d6efd, #0dcaf0)';
		},
		getCampaignBannerStyle(campaign) {
			if (campaign.coverUrl) {
				return {
					background: `linear-gradient(rgba(15,23,42,.28), rgba(15,23,42,.28)), url(${campaign.coverUrl}) center/cover`,
				};
			}
			return { background: campaign.color };
		},
		formatDate(date) {
			if (!date) return this.$t('common.notAvailable');
			const d = new Date(date);
			if (Number.isNaN(d.getTime())) return date;
			return d.toLocaleDateString('vi-VN');
		},
		getRegistrationLabel(status) {
			if (!status) return '';
			const translated = this.$t(`campaignRegistration.statuses.${status}`);
			if (translated !== `campaignRegistration.statuses.${status}`) return translated;
			const fallback = this.$t(`statuses.${status}`);
			return fallback !== `statuses.${status}` ? fallback : status;
		},
		getCoordinatorInitial(name) {
			return name.charAt(0).toUpperCase();
		},
		clearSearchQuery() {
			this.$router.push({ path: '/danh-sach-chien-dich' });
		},
		clearFilters() {
			this.suspendFilterReload = true;
			this.filters = { search: this.searchKeyword || '', status: [], category: [], location: '', coordinator: '' };
			this.$nextTick(() => {
				this.suspendFilterReload = false;
				this.loadCampaigns();
			});
		},
		getFilterStatusLabel(status) {
			return {
				registering: this.$t('campaignList.registering'),
				upcoming: this.$t('campaignList.upcoming'),
				completed: this.$t('campaignList.ended'),
			}[status] || status;
		},
		getPriorityLabel(p) { return this.$t(`priorities.${p}`) || p; },
		getPriorityClassBadge(p) { return { urgent: 'bg-danger text-white', high: 'bg-warning text-dark', medium: 'bg-info text-dark', low: 'bg-light text-muted' }[p] || 'bg-secondary'; },
		getStatusLabel(s) { return this.$t(`statuses.${s}`) || s; },
		getStatusClassBadge(s) { return { registering: 'bg-success text-white', upcoming: 'bg-primary text-white', completed: 'bg-secondary text-white' }[s] || 'bg-secondary'; },
		getStatusIconBadge(s) { return { registering: 'fa-regular fa-clock', upcoming: 'fa-solid fa-hourglass-start', completed: 'fa-solid fa-check' }[s] || ''; },
		getProgress(c) { return c.maxVolunteers ? Math.round(c.registered / c.maxVolunteers * 100) : 0; },
		getProgressColorClass(c) {
			const p = this.getProgress(c);
			if (p >= 100) return 'secondary';
			if (p >= 80) return 'warning';
			return 'primary';
		},
		getProgressColor(c) {
			const p = this.getProgress(c);
			if (p >= 100) return 'text-secondary';
			if (p >= 80) return 'text-warning';
			return 'text-primary';
		},
		showToast(type, title, message) {
			if (this.toast?.showToast) {
				this.toast.showToast(type, title, message);
			}
		}
	}
}
</script>

<style scoped>
.campaign-hero {
	min-height: 250px;
}
.hero-shape {
	position: absolute;
	border-radius: 50%;
	background: rgba(255, 255, 255, 0.1);
}
.shape-1 {
	width: 500px;
	height: 500px;
	top: -200px;
	right: -100px;
}
.shape-2 {
	width: 300px;
	height: 300px;
	bottom: -150px;
	left: 10%;
}

.campaign-card {
	transition: all 0.3s ease;
}
.campaign-card:hover {
	transform: translateY(-5px);
	box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1) !important;
}
.campaign-card:hover h5 a {
	color: #0d6efd !important;
}

.campaign-banner-img {
	height: 160px;
	border-radius: 0.5rem 0.5rem 0 0;
}

.avatar-sm {
	width: 24px;
	height: 24px;
	min-width: 24px;
	flex-shrink: 0;
}

.text-truncate-2 {
	display: -webkit-box;
	-webkit-line-clamp: 2;
	line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
}

.btn-check:checked + .btn-outline-secondary {
	background-color: #6c757d;
	color: white;
	border-color: #6c757d;
}

.search-result-banner {
	background:
		radial-gradient(circle at top right, rgba(13, 110, 253, 0.12), transparent 35%),
		linear-gradient(135deg, #ffffff, #f8fbff);
}

.search-banner-shape {
	position: absolute;
	border-radius: 50%;
	background: rgba(13, 110, 253, 0.08);
}

.search-banner-shape-1 {
	width: 220px;
	height: 220px;
	top: -120px;
	right: -60px;
}

.search-banner-shape-2 {
	width: 140px;
	height: 140px;
	bottom: -80px;
	left: 18%;
}
</style>
