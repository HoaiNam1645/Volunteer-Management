<template>
	<div class="bg-light min-vh-100 pb-5">
		<!-- Hero Cover Banner -->
		<div class="campaign-cover position-relative" :style="{ background: campaign.color }">
			<!-- Overlay for readability -->
			<div class="position-absolute top-0 start-0 w-100 h-100 bg-dark opacity-25"></div>
			
			<div class="container h-100 position-relative z-1 d-flex flex-column justify-content-end pb-5">
				<nav aria-label="breadcrumb" class="mb-3">
					<ol class="breadcrumb mb-0">
						<li class="breadcrumb-item"><router-link to="/" class="text-white opacity-75 text-decoration-none">{{ $t('common.home') }}</router-link></li>
						<li class="breadcrumb-item"><router-link to="/danh-sach-chien-dich" class="text-white opacity-75 text-decoration-none">{{ $t('campaignDetail.explore') }}</router-link></li>
						<li class="breadcrumb-item active text-white" aria-current="page">{{ $t('campaignDetail.title') }}</li>
					</ol>
				</nav>
			</div>
		</div>

		<div class="container campaign-content">
			<div class="row g-4">
				<!-- L E F T : M A I N  C O N T E N T -->
				<div class="col-lg-8">
					<!-- Title Card (Overlapping cover) -->
					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<div class="d-flex flex-wrap gap-2 mb-3">
								<span class="badge border border-primary text-primary px-3 py-2 rounded-pill">{{ getCategoryLabel(campaign.category) }}</span>
								<span class="badge px-3 py-2 rounded-pill" :class="getStatusClassBadge(campaign.status)"><i :class="getStatusIconBadge(campaign.status)" class="me-1"></i> {{ getStatusLabel(campaign.status) }}</span>
							</div>
							
							<h1 class="fw-bold mb-3 display-6 lh-base">{{ campaign.title }}</h1>
							
							<!-- Quick info strip -->
							<div class="row g-3 text-muted mt-2">
								<div class="col-sm-6 d-flex align-items-center gap-3">
									<div class="bg-danger text-white rounded-circle d-flex align-items-center justify-content-center shadow-sm" style="width:40px; height:40px;">
										<i class="fa-solid fa-location-dot"></i>
									</div>
									<div>
										<div class="small fw-semibold text-dark">{{ $t('campaignDetail.locationLabel') }}</div>
										<div class="small">{{ campaign.location }}</div>
									</div>
								</div>
								<div class="col-sm-6 d-flex align-items-center gap-3">
									<div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center shadow-sm" style="width:40px; height:40px;">
										<i class="fa-regular fa-calendar"></i>
									</div>
									<div>
										<div class="small fw-semibold text-dark">{{ $t('campaignDetail.startDateLabel') }}</div>
										<div class="small">{{ campaign.startDate }}</div>
									</div>
								</div>
							</div>
						</div>
					</div>

					<!-- Description Section -->
					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<h4 class="fw-bold mb-4"><i class="fa-solid fa-circle-info me-2 text-info"></i>{{ $t('campaignDetail.aboutTitle') }}</h4>
							<div class="text-muted lh-lg" style="font-size: 15px;">
								<p>
									{{ $t('campaignDetail.aboutDesc1') }}
								</p>
								<p>
									{{ campaign.description }}
								</p>
								<p>
									{{ $t('campaignDetail.aboutDesc2') }}
								</p>
							</div>

							<!-- Highlight Box -->
							<!-- <div class="bg-light rounded-3 p-4 mt-4 border-start border-4 border-primary shadow-sm">
								<h6 class="fw-bold text-primary mb-2">Quyền lợi tình nguyện viên:</h6>
								<ul class="text-muted small mb-0 ps-3">
									<li class="mb-1">Được cấp giấy chứng nhận tham gia chiến dịch tình nguyện hợp lệ.</li>
									<li class="mb-1">Được hỗ trợ chi phí đi lại và ăn uống (tùy chiến dịch).</li>
									<li>Giao lưu, kết bạn và trau dồi kỹ năng mềm làm việc nhóm.</li>
								</ul>
							</div> -->
						</div>
					</div>

					<!-- Campaign Gallery -->
					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<h4 class="fw-bold mb-4"><i class="fa-regular fa-images me-2 text-success"></i>{{ $t('campaignDetail.imagesTitle') }}</h4>
							<div class="row g-3" v-if="campaign.images && campaign.images.length > 0">
								<div v-for="(img, idx) in campaign.images" :key="idx" :class="getImageColClass(campaign.images.length)">
									<img :src="img" class="img-fluid rounded-3 w-100 object-fit-cover shadow-sm" 
										:style="{ height: campaign.images.length === 1 ? '400px' : (campaign.images.length === 2 ? '300px' : '200px') }" 
										style="cursor: pointer; transition: transform 0.2s;" 
										onmouseover="this.style.transform='scale(1.02)'" 
										onmouseout="this.style.transform='scale(1)'"
										@click="openLightbox(idx)"
										:alt="`${$t('campaignDetail.imagesTitle')} ${idx + 1}`">
								</div>
							</div>
							<div v-else class="text-center py-4 bg-light rounded-3 text-muted">
								<i class="fa-regular fa-images fs-3 mb-2 opacity-50"></i>
								<p class="mb-0 small">{{ $t('campaignDetail.noImages') }}</p>
							</div>
						</div>
					</div>

					<!-- Skills Requirements -->
					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<h4 class="fw-bold mb-4"><i class="fa-solid fa-screwdriver-wrench me-2 text-primary"></i>{{ $t('campaignDetail.skillsTitle') }}</h4>
							<div class="d-flex flex-wrap gap-2">
								<span class="badge border border-secondary text-secondary px-3 py-2 fw-normal" style="font-size:14px"><i class="fa-solid fa-users me-2"></i>{{ $t('skills.teamwork') }}</span>
								<span class="badge border border-secondary text-secondary px-3 py-2 fw-normal" style="font-size:14px"><i class="fa-solid fa-heart me-2"></i>{{ $t('skills.enthusiastic') }}</span>
								<span class="badge border border-secondary text-secondary px-3 py-2 fw-normal" style="font-size:14px"><i class="fa-regular fa-clock me-2"></i>{{ $t('skills.punctual') }}</span>
							</div>
						</div>
					</div>

					<!-- Địa điểm chiến dịch (Map) -->
					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<h4 class="fw-bold mb-4"><i class="fa-solid fa-map-location-dot me-2 text-danger"></i>{{ $t('campaignDetail.mapTitle') }}</h4>
							<div class="d-flex align-items-center gap-2 mb-3">
								<div class="bg-danger text-white rounded-circle d-flex align-items-center justify-content-center shadow-sm" style="width:36px;height:36px">
									<i class="fa-solid fa-location-dot"></i>
								</div>
								<span class="fw-medium text-dark" style="font-size:15px">{{ campaign.location }}</span>
							</div>
							<div id="user-detail-map" class="user-detail-map-wrapper rounded-3 border overflow-hidden mb-3"></div>
							<div class="d-flex gap-3" v-if="mapLatitude">
								<span class="badge bg-light text-muted border px-3 py-2" style="font-size:12px"><i class="fa-solid fa-crosshairs me-1"></i>{{ mapLatitude }}, {{ mapLongitude }}</span>
							</div>
						</div>
					</div>

					<!-- Reviews Section -->
					<div class="card border-0 shadow-sm rounded-4 mb-4">
						<div class="card-body p-4 p-md-5">
							<div class="d-flex align-items-center justify-content-between mb-4">
								<h4 class="fw-bold mb-0"><i class="fa-solid fa-comments me-2 text-warning"></i>{{ $t('campaignDetail.feedbackTitle') }}</h4>
								<span class="badge bg-warning text-dark rounded-pill px-3 py-2" v-if="campaign.avgRating">
									<i class="fa-solid fa-star me-1"></i>{{ campaign.avgRating }} / 5
								</span>
							</div>

							<!-- Rating Summary -->
							<div class="row g-4 mb-4" v-if="reviews.length > 0">
								<div class="col-md-4">
									<div class="text-center p-3 bg-light rounded-3">
										<div class="fw-bold text-warning" style="font-size: 48px;">{{ campaign.avgRating }}</div>
										<div class="d-flex justify-content-center gap-1 mb-2">
											<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= Math.round(campaign.avgRating) ? 'text-warning' : 'text-muted'" style="font-size:18px"></i>
										</div>
										<div class="text-muted small">{{ campaign.reviewCount }} {{ $t('campaignDetail.reviewsCount') }}</div>
									</div>
								</div>
								<div class="col-md-8">
									<div class="d-flex align-items-center gap-2 mb-2" v-for="star in [5,4,3,2,1]" :key="star">
										<span class="small fw-medium text-muted" style="min-width:15px">{{ star }}</span>
										<i class="fa-solid fa-star text-warning" style="font-size:12px"></i>
										<div class="progress flex-grow-1" style="height:8px">
											<div class="progress-bar bg-warning" :style="{ width: getStarPercent(star) + '%' }"></div>
										</div>
										<span class="small text-muted" style="min-width:28px">{{ getStarCount(star) }}</span>
									</div>
								</div>
							</div>

							<!-- Review List -->
							<div class="border-top pt-4" v-if="reviews.length > 0">
								<div class="review-item mb-4" v-for="r in displayedReviews" :key="r.id">
									<div class="d-flex align-items-start gap-3">
										<div class="review-avatar rounded-circle d-flex align-items-center justify-content-center text-white fw-bold flex-shrink-0" :style="{ background: r.color }">{{ r.name.charAt(0) }}</div>
										<div class="flex-grow-1 min-w-0">
											<div class="d-flex align-items-center justify-content-between flex-wrap gap-1 mb-1">
												<span class="fw-bold small">{{ r.name }}</span>
												<span class="text-muted" style="font-size:12px">{{ r.date }}</span>
											</div>
											<div class="d-flex gap-0 mb-2">
												<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= r.rating ? 'text-warning' : 'text-muted'" style="font-size:12px"></i>
											</div>
											<p class="text-muted small mb-2 lh-lg" v-if="r.comment">{{ r.comment }}</p>
											<div class="d-flex flex-wrap gap-1" v-if="r.tags && r.tags.length > 0">
												<span v-for="tag in r.tags" :key="tag" class="badge bg-light text-muted border px-2 py-1" style="font-size:11px">{{ tag }}</span>
											</div>
										</div>
									</div>
								</div>
								<button class="btn btn-outline-primary btn-sm rounded-pill px-4 w-100" v-if="reviews.length > 3 && !showAllReviews" @click="showAllReviews = true">
									<i class="fa-solid fa-chevron-down me-1"></i>{{ $t('campaignDetail.viewAllReviews', { count: reviews.length }) }}
								</button>
							</div>

							<!-- Empty -->
							<div class="text-center py-4" v-if="reviews.length === 0">
								<i class="fa-regular fa-comment-dots text-muted fs-1 mb-3 d-block opacity-25"></i>
								<p class="text-muted mb-0">{{ $t('campaignDetail.noReviews') }}</p>
							</div>
						</div>
					</div>
				</div>

				<!-- R I G H T : S I D E B A R -->
				<div class="col-lg-4">
					<div class="position-sticky" style="top: 20px;">
						
						<!-- Action Card (Registration) -->
						<div class="card border-0 shadow-sm rounded-4 mb-4 action-card">
							<div class="card-body p-4">
								<h5 class="fw-bold mb-4 text-center">{{ $t('campaignDetail.registrationStatus') }}</h5>
								
								<!-- Progress Block -->
								<div class="d-flex justify-content-between align-items-end mb-2">
									<div>
										<span class="fs-4 fw-bold text-primary">{{ campaign.registered }}</span><span class="text-muted"> / {{ campaign.maxVolunteers }}</span>
										<div class="small text-muted">{{ $t('campaignDetail.volunteerLabel') }}</div>
									</div>
									<div class="fs-5 fw-bold" :class="getProgressColor(campaign)">
										{{ getProgress(campaign) }}%
									</div>
								</div>
								
								<div class="progress mb-4" style="height: 10px; border-radius: 10px;">
									<div class="progress-bar progress-bar-striped progress-bar-animated bg-primary" :style="{ width: getProgress(campaign) + '%' }"></div>
								</div>

								<div class="bg-light rounded-3 p-3 mb-4 text-center">
									<i class="fa-regular fa-clock text-warning fs-4 mb-2"></i>
									<div class="small fw-medium">{{ $t('campaignDetail.deadlineLabel') }}</div>
									<div class="fw-bold text-dark">{{ campaign.endDate }}</div>
								</div>

								<button class="btn btn-primary btn-lg w-100 fw-bold rounded-pill p-3 shadow-sm btn-register" 
									:disabled="campaign.status !== 'registering'">
									{{ campaign.status === 'registering' ? $t('campaignDetail.registerNow') : $t('campaignDetail.registrationClosed') }}
								</button>
								
								<div class="text-center mt-3 small text-muted">
									{{ $t('campaignDetail.agreeText1') }} <a href="#" class="text-decoration-none">{{ $t('campaignDetail.agreeText2') }}</a> {{ $t('campaignDetail.agreeText3') }}
								</div>
							</div>
						</div>

						<!-- Coordinator Card -->
						<div class="card border-0 shadow-sm rounded-4">
							<div class="card-body p-4">
								<h6 class="fw-bold mb-4 text-uppercase small text-muted">{{ $t('campaignDetail.coordinatorTitle') }}</h6>
								<div class="d-flex align-items-center gap-3 mb-3">
									<div class="avatar-bg bg-primary text-white d-flex align-items-center justify-content-center fw-bold fs-4 rounded-circle shadow-sm" style="width: 60px; height: 60px;">
										{{ getCoordinatorInitial() }}
									</div>
									<div>
										<h6 class="fw-bold mb-1">{{ campaign.coordinatorName }}</h6>
										<div class="small text-muted mb-1"><i class="fa-regular fa-envelope me-1"></i> coordinator@email.com</div>
										<div class="small text-primary fw-medium"><i class="fa-solid fa-star text-warning"></i> {{ campaign.avgRating }} ({{ campaign.reviewCount }} {{ $t('campaignDetail.reviewsCount') }})</div>
									</div>
								</div>
								<button class="btn btn-outline-secondary w-100 rounded-pill"><i class="fa-regular fa-comment-dots me-2"></i>{{ $t('campaignDetail.sendMessage') }}</button>
							</div>
						</div>

					</div>
				</div>
			</div>
		</div>

		<!-- Mobile Sticky Bottom Bar -->
		<div class="fixed-bottom d-lg-none bg-white border-top p-3 shadow-lg d-flex align-items-center gap-3 z-3">
			<div class="flex-grow-1">
				<div class="fw-bold small">{{ campaign.registered }}/{{ campaign.maxVolunteers }} <span class="fw-normal text-muted">{{ $t('campaignDetail.people') }}</span></div>
				<div class="progress mt-1" style="height: 4px;">
					<div class="progress-bar bg-primary" :style="{ width: getProgress(campaign) + '%' }"></div>
				</div>
			</div>
			<button class="btn btn-primary flex-shrink-0 fw-bold rounded-pill px-4" :disabled="campaign.status !== 'registering'">
				{{ campaign.status === 'registering' ? $t('campaignDetail.registerNowShort') : $t('campaignDetail.closedShort') }}
			</button>
		</div>

		<!-- Image Lightbox Modal -->
		<div class="modal fade" id="imageLightboxModal" tabindex="-1" aria-hidden="true">
			<div class="modal-dialog modal-dialog-centered modal-xl">
				<div class="modal-content bg-transparent border-0">
					<div class="modal-header border-0 pb-0 justify-content-end">
						<button type="button" class="btn-close btn-close-white fs-4" data-bs-dismiss="modal" aria-label="Close"></button>
					</div>
					<div class="modal-body text-center position-relative p-0">
						<!-- Prev Button -->
						<button v-if="campaign.images && campaign.images.length > 1" @click="prevImage" 
								class="btn btn-dark position-absolute top-50 start-0 translate-middle-y ms-2 ms-md-4 rounded-circle shadow" 
								style="width: 48px; height: 48px; border: none; z-index: 10; opacity: 0.8;">
							<i class="fa-solid fa-chevron-left text-white"></i>
						</button>
						
						<!-- The Image -->
						<img v-if="campaign.images && campaign.images.length > 0" 
							 :src="campaign.images[selectedImageIndex]" 
							 class="img-fluid rounded shadow-lg" 
							 style="max-height: 85vh; object-fit: contain;">
						
						<!-- Next Button -->
						<button v-if="campaign.images && campaign.images.length > 1" @click="nextImage" 
								class="btn btn-dark position-absolute top-50 end-0 translate-middle-y me-2 me-md-4 rounded-circle shadow" 
								style="width: 48px; height: 48px; border: none; z-index: 10; opacity: 0.8;">
							<i class="fa-solid fa-chevron-right text-white"></i>
						</button>
					</div>
				</div>
			</div>
		</div>

	</div>
</template>

<script>
export default {
	name: 'ChiTietChienDichPublic',
	data() {
		return {
			selectedImageIndex: 0,
			detailMap: null,
			detailMarker: null,
			mapLatitude: null,
			mapLongitude: null,
			// Mock data cho giao diện
			campaign: {
				id: 1, 
				title: 'Chiến dịch Mùa Hè Xanh Vùng Cao 2026', 
				description: 'Chiến dịch Mùa Hè Xanh là hoạt động thường niên nhằm mang tri thức, sự giúp đỡ thiết thực đến với đồng bào các dân tộc thiểu số. Năm nay, chúng tôi tập trung vào việc tu sửa điểm trường, dạy học tiếng Anh cơ bản và hướng dẫn vệ sinh phòng dịch cho trẻ em.', 
				category: 'community', 
				priority: 'high', 
				location: 'CQ4Q+MMG, ĐT155, Ngũ Chỉ Sơn, Sa Pa, Lào Cai, Việt Nam', 
				startDate: '20/06/2026', 
				endDate: '15/06/2026', // Request deadline
				maxVolunteers: 120, 
				registered: 85, 
				status: 'registering', 
				color: 'linear-gradient(135deg, #0d6efd, #0dcaf0)',
				coordinatorName: 'Tổ chức Thanh Niên Tình Nguyện',
				avgRating: 4.7,
				reviewCount: 23,
				images: [
					'https://picsum.photos/id/119/800/600',
					'https://picsum.photos/id/120/400/300',
					'https://picsum.photos/id/122/400/300',
					'https://picsum.photos/id/124/400/300'
				]
			},
			showAllReviews: false,
			reviews: [
				{ id: 1, name: 'Nguyễn Minh Tuấn', rating: 5, date: '22/03/2026', color: '#0d6efd', comment: 'Trải nghiệm tuyệt vời! Tổ chức rất bài bản, đồ ăn ngon, leader nhiệt tình. Chắc chắn sẽ tham gia lần sau.', tags: ['Tổ chức tốt', 'Leader nhiệt tình'] },
				{ id: 2, name: 'Trần Thị Mai', rating: 5, date: '21/03/2026', color: '#6f42c1', comment: 'Mình rất vui khi được góp sức vào chiến dịch ý nghĩa này. Các em nhỏ rất dễ thương và hiếu học.', tags: ['Ý nghĩa', 'Trải nghiệm tốt'] },
				{ id: 3, name: 'Lê Hoàng Dũng', rating: 4, date: '20/03/2026', color: '#dc3545', comment: 'Chiến dịch rất tốt, chỉ cần cải thiện thêm phần logistics rửi về sớm hơn.', tags: ['Hỗ trợ hậu cần'] },
				{ id: 4, name: 'Phạm Thị Lan', rating: 5, date: '19/03/2026', color: '#198754', comment: 'Mình thấy đây là 1 trong những chiến dịch tình nguyện hay nhất mình từng tham gia!', tags: [] },
				{ id: 5, name: 'Hoàng Đức Minh', rating: 4, date: '18/03/2026', color: '#fd7e14', comment: '', tags: ['Tổ chức tốt', 'Thời gian hợp lý'] }
			]
		}
	},
	computed: {
		displayedReviews() {
			return this.showAllReviews ? this.reviews : this.reviews.slice(0, 3);
		}
	},
	methods: {
		getCategoryLabel(cat) { return this.$t(`categories.${cat}`) || cat; },
		getStatusLabel(s) { return this.$t(`statuses.${s}`) || s; },
		getStatusClassBadge(s) { return { registering: 'bg-success text-white', upcoming: 'bg-primary text-white', completed: 'bg-secondary text-white' }[s] || 'bg-light text-muted'; },
		getStatusIconBadge(s) { return { registering: 'fa-regular fa-circle-check', upcoming: 'fa-regular fa-clock', completed: 'fa-solid fa-flag-checkered' }[s] || ''; },
		getProgress(c) { return c.maxVolunteers ? Math.round(c.registered / c.maxVolunteers * 100) : 0; },
		getProgressColor(c) {
			const p = this.getProgress(c);
			if (p >= 100) return 'text-secondary';
			if (p >= 80) return 'text-warning';
			return 'text-primary';
		},
		getCoordinatorInitial() {
			return this.campaign.coordinatorName.charAt(0).toUpperCase();
		},
		getStarCount(star) {
			return this.reviews.filter(r => r.rating === star).length;
		},
		getStarPercent(star) {
			if (this.reviews.length === 0) return 0;
			return Math.round(this.getStarCount(star) / this.reviews.length * 100);
		},
		getImageColClass(total) {
			if (total === 1) return 'col-12';
			if (total === 2) return 'col-sm-6';
			if (total === 3) return 'col-sm-4';
			if (total === 4) return 'col-sm-6 col-md-3';
			return 'col-sm-6 col-md-4 col-lg-3'; // Default for 5+ images
		},
		openLightbox(index) {
			this.selectedImageIndex = index;
			const modal = new window.bootstrap.Modal(document.getElementById('imageLightboxModal'));
			modal.show();
		},
		nextImage() {
			if (!this.campaign.images) return;
			this.selectedImageIndex = (this.selectedImageIndex + 1) % this.campaign.images.length;
		},
		prevImage() {
			if (!this.campaign.images) return;
			this.selectedImageIndex = (this.selectedImageIndex - 1 + this.campaign.images.length) % this.campaign.images.length;
		},
		initDetailMap(lat, lng) {
			this.$nextTick(() => {
				const container = document.getElementById('user-detail-map');
				if (!container || !window.L) return;
				if (this.detailMap) { this.detailMap.remove(); this.detailMap = null; }

				this.detailMap = window.L.map(container, {
					center: [lat, lng],
					zoom: 15,
					zoomControl: true,
					attributionControl: false,
					scrollWheelZoom: false
				});

				window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
					maxZoom: 19
				}).addTo(this.detailMap);

				const pinIcon = window.L.divIcon({
					html: '<div class="custom-pin"><i class="fa-solid fa-location-dot"></i></div>',
					iconSize: [36, 36],
					iconAnchor: [18, 36],
					className: 'custom-pin-wrapper'
				});

				this.detailMarker = window.L.marker([lat, lng], {
					draggable: false,
					icon: pinIcon
				}).addTo(this.detailMap);

				this.mapLatitude = lat.toFixed(7);
				this.mapLongitude = lng.toFixed(7);
			});
		},
		async geocodeAndShowMap() {
			if (!this.campaign) return;

			// Ưu tiên sử dụng Kinh độ & Vĩ độ đã được lưu sẵn (nếu có)
			if (this.campaign.latitude && this.campaign.longitude) {
				this.initDetailMap(parseFloat(this.campaign.latitude), parseFloat(this.campaign.longitude));
				return;
			}

			if (!this.campaign.location) return;
			try {
				let address = this.campaign.location;
				// Loại bỏ Google Plus Code (VD: "CQ4Q+MMG, ") do Nominatim không hỗ trợ
				address = address.replace(/^[A-Z0-9]{4,8}\+[A-Z0-9]{2,}\s*,?\s*/g, '');
				
				let query = encodeURIComponent(address);
				let url = `https://nominatim.openstreetmap.org/search?format=json&q=${query}&countrycodes=vn&limit=1`;
				let res = await fetch(url, { headers: { 'Accept-Language': 'vi' } });
				let data = await res.json();

				// Fallback: Nếu không tìm thấy, thử bỏ đi phần đầu tiên của địa chỉ (VD: số nhà/tên đường cụ thể)
				if ((!data || data.length === 0) && address.includes(',')) {
					const fallbackAddress = address.substring(address.indexOf(',') + 1).trim();
					const fallbackUrl = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(fallbackAddress)}&countrycodes=vn&limit=1`;
					res = await fetch(fallbackUrl, { headers: { 'Accept-Language': 'vi' } });
					data = await res.json();
				}

				if (data && data.length > 0) {
					this.initDetailMap(parseFloat(data[0].lat), parseFloat(data[0].lon));
				} else {
					this.initDetailMap(16.0544, 108.2022);
				}
			} catch {
				this.initDetailMap(16.0544, 108.2022);
			}
		}
	},
	mounted() {
		if (!document.getElementById('leaflet-css')) {
			const link = document.createElement('link');
			link.id = 'leaflet-css';
			link.rel = 'stylesheet';
			link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
			document.head.appendChild(link);
		}
		if (!window.L) {
			const script = document.createElement('script');
			script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
			script.onload = () => this.geocodeAndShowMap();
			document.head.appendChild(script);
		} else {
			this.geocodeAndShowMap();
		}
	},
	beforeUnmount() {
		if (this.detailMap) { this.detailMap.remove(); this.detailMap = null; }
	}
}
</script>

<style scoped>
.campaign-cover {
	height: 350px;
	width: 100%;
}

.campaign-content {
	margin-top: -80px;
}

.action-card {
	border-top: 5px solid #0d6efd !important;
}

.btn-register {
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.btn-register:hover:not(:disabled) {
	transform: translateY(-2px);
	box-shadow: 0 .5rem 1rem rgba(13, 110, 253, .25) !important;
}

@media (max-width: 991px) {
	.campaign-content {
		margin-top: -40px;
	}
}

.more-images-overlay {
	background: rgba(0, 0, 0, 0.4);
	cursor: pointer;
	transition: background 0.3s ease;
}

.more-images-overlay:hover {
	background: rgba(0, 0, 0, 0.6);
}

.user-detail-map-wrapper {
	height: 300px;
	width: 100%;
	z-index: 0;
}

/* Reviews */
.review-avatar {
	width: 40px;
	height: 40px;
	min-width: 40px;
	font-size: 15px;
}
.review-item {
	padding-bottom: 16px;
	border-bottom: 1px solid #f0f0f0;
}
.review-item:last-child {
	border-bottom: none;
	padding-bottom: 0;
	margin-bottom: 0 !important;
}
.min-w-0 { min-width: 0; }
</style>

<style>
.custom-pin-wrapper {
	background: none !important;
	border: none !important;
}
.custom-pin {
	font-size: 36px;
	color: #dc3545;
	filter: drop-shadow(0 2px 4px rgba(0,0,0,0.4));
	animation: user-pin-bounce 0.4s ease;
}
@keyframes user-pin-bounce {
	0% { transform: translateY(-20px); opacity: 0; }
	60% { transform: translateY(4px); }
	100% { transform: translateY(0); opacity: 1; }
}
</style>
