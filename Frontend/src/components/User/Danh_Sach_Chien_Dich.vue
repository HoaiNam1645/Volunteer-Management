<template>
	<div class="bg-light min-vh-100 pb-5">
		<div class="container pt-4">
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
								<div class="form-check mb-2">
									<input class="form-check-input" type="checkbox" id="status-registering" value="registering" v-model="filters.status">
									<label class="form-check-label small" for="status-registering">{{ $t('campaignList.registering') }}</label>
								</div>
								<div class="form-check mb-2">
									<input class="form-check-input" type="checkbox" id="status-upcoming" value="upcoming" v-model="filters.status">
									<label class="form-check-label small" for="status-upcoming">{{ $t('campaignList.upcoming') }}</label>
								</div>
								<div class="form-check">
									<input class="form-check-input" type="checkbox" id="status-completed" value="completed" v-model="filters.status">
									<label class="form-check-label small" for="status-completed">{{ $t('campaignList.ended') }}</label>
								</div>
							</div>

							<!-- Loại chiến dịch -->
							<div class="p-3 border-bottom">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.field') }}</h6>
								<div class="form-check mb-2" v-for="cat in categories" :key="cat.value">
									<input class="form-check-input" type="checkbox" :id="'cat-'+cat.value" :value="cat.value" v-model="filters.category">
									<label class="form-check-label small d-flex justify-content-between align-items-center w-100" :for="'cat-'+cat.value">
										<span>{{ cat.label }}</span>
										<span class="badge bg-light text-muted fw-normal rounded-pill">{{ getCategoryCount(cat.value) }}</span>
									</label>
								</div>
							</div>

							<!-- Địa điểm -->
							<div class="p-3 border-bottom">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.location') }}</h6>
								<select class="form-select form-select-sm" v-model="filters.location">
									<option value="">{{ $t('campaignList.allAreas') }}</option>
									<option value="TP.HCM">TP.HCM</option>
									<option value="Hà Nội">Hà Nội</option>
									<option value="Đà Nẵng">Đà Nẵng</option>
									<option value="Khác">{{ $t('campaignList.otherArea') }}</option>
								</select>
							</div>

							<!-- Người điều phối -->
							<div class="p-3">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.coordinatorLabel') }}</h6>
								<select class="form-select form-select-sm" v-model="filters.coordinator">
									<option value="">{{ $t('common.all') }}</option>
									<option v-for="coord in coordinators" :key="coord.id" :value="coord.id">
										{{ coord.name }}
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
								{{ $t('campaignList.showingResults') }} <strong>{{ filteredCampaigns.length }}</strong> {{ $t('campaignList.resultsLabel') }}
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

					<!-- Campaigns Grid -->
					<div class="row g-4">
						<div class="col-md-6 col-xl-4" v-for="campaign in sortedCampaigns" :key="campaign.id">
							<div class="card h-100 border-0 shadow-sm campaign-card">
								<!-- Image/Banner Placeholder -->
								<div class="campaign-banner-img position-relative" :style="{ background: campaign.color }">
									<div class="position-absolute top-0 start-0 m-3 d-flex flex-column gap-2">
										<span class="badge bg-white text-dark shadow-sm">{{ getCategoryLabel(campaign.category) }}</span>
										<span class="badge" :class="getPriorityClassBadge(campaign.priority)">{{ getPriorityLabel(campaign.priority) }}</span>
									</div>
									<div class="position-absolute bottom-0 end-0 m-3">
										<span class="badge shadow-sm" :class="getStatusClassBadge(campaign.status)">
											<i class="me-1" :class="getStatusIconBadge(campaign.status)"></i>{{ getStatusLabel(campaign.status) }}
										</span>
									</div>
								</div>

								<div class="card-body p-4 d-flex flex-column">
									<div class="d-flex align-items-center gap-2 mb-3">
										<div class="avatar-sm bg-primary bg-opacity-10 text-primary rounded-circle d-flex align-items-center justify-content-center fw-bold small">
											{{ getCoordinatorInitial(campaign.coordinatorId) }}
										</div>
										<span class="small text-muted text-truncate">{{ getCoordinatorName(campaign.coordinatorId) }}</span>
										<span class="ms-auto d-flex align-items-center gap-1 small text-nowrap" v-if="campaign.avgRating">
											<i class="fa-solid fa-star text-warning" style="font-size:11px"></i>
											<span class="fw-bold text-dark">{{ campaign.avgRating }}</span>
											<span class="text-muted">({{ campaign.reviewCount }})</span>
										</span>
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
						<div class="col-12" v-if="filteredCampaigns.length === 0">
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
					<nav class="mt-5" v-if="filteredCampaigns.length > 0">
						<ul class="pagination justify-content-center border-0">
							<li class="page-item disabled"><a class="page-link border-0 shadow-sm rounded-start-pill px-3" href="#">{{ $t('campaignList.prev') }}</a></li>
							<li class="page-item active"><a class="page-link border-0 shadow-sm" href="#">1</a></li>
							<li class="page-item"><a class="page-link border-0 shadow-sm" href="#">2</a></li>
							<li class="page-item"><a class="page-link border-0 shadow-sm" href="#">3</a></li>
							<li class="page-item"><a class="page-link border-0 shadow-sm rounded-end-pill px-3" href="#">{{ $t('campaignList.nextPage') }}</a></li>
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
						<input type="checkbox" class="btn-check" id="mob-st-registering" value="registering" v-model="filters.status">
						<label class="btn btn-outline-secondary btn-sm rounded-pill" for="mob-st-registering">{{ $t('campaignList.registeringShort') }}</label>
						
						<input type="checkbox" class="btn-check" id="mob-st-upcoming" value="upcoming" v-model="filters.status">
						<label class="btn btn-outline-secondary btn-sm rounded-pill" for="mob-st-upcoming">{{ $t('campaignList.upcoming') }}</label>
						
						<input type="checkbox" class="btn-check" id="mob-st-completed" value="completed" v-model="filters.status">
						<label class="btn btn-outline-secondary btn-sm rounded-pill" for="mob-st-completed">{{ $t('campaignList.ended') }}</label>
					</div>
				</div>

				<!-- Lĩnh vực -->
				<div class="mb-4">
					<label class="form-label fw-bold small text-muted text-uppercase">{{ $t('campaignList.field') }}</label>
					<div class="d-flex flex-wrap gap-2">
						<div v-for="cat in categories" :key="'mob-'+cat.value">
							<input type="checkbox" class="btn-check" :id="'mob-cat-'+cat.value" :value="cat.value" v-model="filters.category">
							<label class="btn btn-outline-secondary btn-sm rounded-pill" :for="'mob-cat-'+cat.value">{{ cat.label }}</label>
						</div>
					</div>
				</div>

				<!-- Footer Buttons -->
				<div class="d-flex gap-2 mt-5">
					<button class="btn btn-light w-50" @click="clearFilters">{{ $t('campaignList.clearFilter') }}</button>
					<button class="btn btn-primary w-50" data-bs-dismiss="offcanvas">{{ $t('common.apply') }} ({{ filteredCampaigns.length }})</button>
				</div>
			</div>
		</div>

	</div>
</template>

<script>
export default {
	name: 'DanhSachChienDich',
	data() {
		return {
			sortBy: 'newest',
			filters: {
				search: '',
				status: [],
				category: [],
				location: '',
				coordinator: ''
			},
			coordinators: [
				{ id: '1', name: 'Tổ chức Thanh Niên Tình Nguyện' },
				{ id: '2', name: 'Nguyễn Điều Phối' },
				{ id: '3', name: 'Quỹ Bảo Trợ Trẻ Em' }
			],
			// Tương đương product mock data
			campaigns: [
				{ id: 1, coordinatorId: '2', title: 'Trồng cây xanh tại TP.HCM', description: 'Chiến dịch trồng 1000 cây xanh tại các tuyến đường trọng điểm, hướng tới thành phố xanh sạch đẹp.', category: 'environment', priority: 'high', location: 'TP.HCM', startDate: '15/03/2026', endDate: '20/03/2026', maxVolunteers: 80, registered: 45, status: 'registering', color: 'linear-gradient(135deg, #198754, #20c997)', avgRating: 4.7, reviewCount: 23 },
				{ id: 2, coordinatorId: '1', title: 'Dạy tiếng Anh cho trẻ em Sapa', description: 'Dạy tiếng Anh và kỹ năng sống cho trẻ em tại Sa Pa, Lào Cai kết hợp giao lưu văn hóa.', category: 'education', priority: 'medium', location: 'Khác', startDate: '20/04/2026', endDate: '03/05/2026', maxVolunteers: 40, registered: 38, status: 'registering', color: 'linear-gradient(135deg, #0d6efd, #6610f2)', avgRating: 4.9, reviewCount: 15 },
				{ id: 3, coordinatorId: '3', title: 'Khám bệnh miễn phí vùng sâu', description: 'Đoàn y bác sĩ khám phát thuốc miễn phí cho bà con nghèo tại các xã vùng sâu.', category: 'health', priority: 'urgent', location: 'Khác', startDate: '25/03/2026', endDate: '27/03/2026', maxVolunteers: 30, registered: 30, status: 'upcoming', color: 'linear-gradient(135deg, #dc3545, #e35d6a)', avgRating: 4.8, reviewCount: 31 },
				{ id: 4, coordinatorId: '1', title: 'Mùa hè xanh Bến Tre', description: 'Tình nguyện mùa hè cho sinh viên, hỗ trợ xây dựng cầu đường nông thôn mới.', category: 'community', priority: 'medium', location: 'Khác', startDate: '01/06/2026', endDate: '30/06/2026', maxVolunteers: 120, registered: 20, status: 'registering', color: 'linear-gradient(135deg, #fd7e14, #ffc107)', avgRating: 0, reviewCount: 0 },
				{ id: 5, coordinatorId: '2', title: 'Phân phát nhu yếu phẩm bão lũ', description: 'Cứu trợ khẩn cấp gạo và mì tôm cho hộ dân bị ảnh hưởng bởi bão tại miền Trung.', category: 'disaster', priority: 'urgent', location: 'Khác', startDate: '01/02/2026', endDate: '10/02/2026', maxVolunteers: 200, registered: 200, status: 'completed', color: 'linear-gradient(135deg, #6c757d, #adb5bd)', avgRating: 4.5, reviewCount: 87 },
				{ id: 6, coordinatorId: '2', title: 'Phát cháo đêm cho người vô gia cư', description: 'Nấu và phát 300 suất cháo miễn phí tại các con hẼm nhỏ trung tâm.', category: 'community', priority: 'low', location: 'TP.HCM', startDate: '10/11/2025', endDate: '10/11/2025', maxVolunteers: 50, registered: 50, status: 'completed', color: 'linear-gradient(135deg, #6c757d, #adb5bd)', avgRating: 4.3, reviewCount: 42 },
				{ id: 7, coordinatorId: '1', title: 'Ngày hội Hiến máu nhân đạo', description: 'Cùng chung tay hiến máu cứu người, một giọt máu cho đi một cuộc đời ở lại.', category: 'health', priority: 'high', location: 'Hà Nội', startDate: '05/04/2026', endDate: '05/04/2026', maxVolunteers: 200, registered: 156, status: 'registering', color: 'linear-gradient(135deg, #dc3545, #fd7e14)', avgRating: 4.6, reviewCount: 8 },
				{ id: 8, coordinatorId: '3', title: 'Làm sạch bãi biển Sơn Trà', description: 'Thu gom rác ven biển, bảo vệ hệ sinh thái biển và lan tỏa ý thức cộng đồng.', category: 'environment', priority: 'medium', location: 'Đà Nẵng', startDate: '01/05/2026', endDate: '02/05/2026', maxVolunteers: 100, registered: 20, status: 'registering', color: 'linear-gradient(135deg, #0dcaf0, #0d6efd)', avgRating: 0, reviewCount: 0 }
			]
		}
	},
	computed: {
		categories() {
			return [
				{ label: this.$t('categories.environment'), value: 'environment' },
				{ label: this.$t('categories.education'), value: 'education' },
				{ label: this.$t('categories.health'), value: 'health' },
				{ label: this.$t('categories.community'), value: 'community' },
				{ label: this.$t('categories.disaster'), value: 'disaster' }
			];
		},
		filteredCampaigns() {
			return this.campaigns.filter(c => {
				// Search
				if (this.filters.search && !c.title.toLowerCase().includes(this.filters.search.toLowerCase())) return false;
				// Status
				if (this.filters.status.length > 0 && !this.filters.status.includes(c.status)) return false;
				// Category
				if (this.filters.category.length > 0 && !this.filters.category.includes(c.category)) return false;
				// Location
				if (this.filters.location && c.location !== this.filters.location) return false;
				// Coordinator
				if (this.filters.coordinator && c.coordinatorId !== this.filters.coordinator) return false;
				return true;
			});
		},
		sortedCampaigns() {
			let arr = [...this.filteredCampaigns];
			if (this.sortBy === 'urgent') {
				// Đưa urgent lên đầu, đăng ký chưa đầy lên đầu
				const priorityVal = { 'urgent': 3, 'high': 2, 'medium': 1, 'low': 0 };
				arr.sort((a, b) => priorityVal[b.priority] - priorityVal[a.priority]);
			} else if (this.sortBy === 'soonest') {
				// So sánh startDate (giả lập đơn giản)
				arr.sort((a, b) => a.startDate.localeCompare(b.startDate));
			}
			// newest (mặc định id giảm dần)
			else {
				arr.sort((a, b) => b.id - a.id);
			}
			return arr;
		}
	},
	methods: {
		getCategoryCount(cat) {
			return this.campaigns.filter(c => c.category === cat).length;
		},
		getCoordinatorName(id) {
			const c = this.coordinators.find(x => x.id === id);
			return c ? c.name : 'Chưa rõ';
		},
		getCoordinatorInitial(id) {
			const name = this.getCoordinatorName(id);
			return name.charAt(0).toUpperCase();
		},
		clearFilters() {
			this.filters = { search: '', status: [], category: [], location: '', coordinator: '' };
		},
		getCategoryLabel(cat) { return this.$t(`categories.${cat}`) || cat; },
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
</style>
