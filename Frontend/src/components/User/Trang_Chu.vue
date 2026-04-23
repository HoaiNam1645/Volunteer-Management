<template>
	<div class="home-page">
		<section class="hero-section">
			<div class="hero-mesh"></div>
			<div class="container hero-content">
				<div class="row g-4 align-items-center">
					<div class="col-lg-7">
						<span class="hero-pill">
							<i class="fa-solid fa-shield-heart me-2"></i>
							Mạng lưới thiện nguyện minh bạch và đáng tin cậy
						</span>
						<h1 class="hero-title">
							{{ $t('home.heroTitle') }}
							<span>{{ $t('home.heroBold') }}</span>
						</h1>
						<p class="hero-description">{{ $t('home.heroDesc') }}</p>
						<div class="hero-actions">
							<router-link to="/dang-ky" class="btn btn-warning btn-lg fw-bold text-dark">
								<i class="fa-solid fa-user-plus me-2"></i>{{ $t('home.joinNow') }}
							</router-link>
							<a href="#campaigns" class="btn btn-outline-light btn-lg">
								<i class="fa-solid fa-compass me-2"></i>{{ $t('home.viewCampaigns') }}
							</a>
						</div>
						<div class="hero-mini-grid">
							<div class="hero-mini-item">
								<i class="fa-solid fa-users"></i>
								<div>
									<p class="hero-mini-label">{{ $t('home.counterVolunteers') }}</p>
									<strong>{{ formatCompactNumber(heroStats.volunteerCount) }}+</strong>
								</div>
							</div>
							<div class="hero-mini-item">
								<i class="fa-solid fa-people-group"></i>
								<div>
									<p class="hero-mini-label">Lượt tham gia</p>
									<strong>{{ formatCompactNumber(impactStats.totalRegistrations) }}+</strong>
								</div>
							</div>
							<div class="hero-mini-item">
								<i class="fa-solid fa-map-location-dot"></i>
								<div>
									<p class="hero-mini-label">{{ $t('home.counterProvinces') }}</p>
									<strong>{{ formatCompactNumber(heroStats.provinceCount) }}+</strong>
								</div>
							</div>
							<div class="hero-mini-item">
								<i class="fa-solid fa-star"></i>
								<div>
									<p class="hero-mini-label">Tỉ lệ lấp đầy</p>
									<strong>{{ impactStats.fillRate }}%</strong>
								</div>
							</div>
						</div>
					</div>
					<div class="col-lg-5">
						<div class="hero-panel">
							<div class="hero-panel-head">
								<div>
									<p class="mb-1">Toàn cảnh hoạt động</p>
									<h5 class="mb-0">Cập nhật theo thời gian thực</h5>
								</div>
								<span class="hero-live-dot">LIVE</span>
							</div>
							<div class="hero-progress-list">
								<div class="hero-progress-item">
									<div class="d-flex justify-content-between">
										<span>{{ $t('home.counterCampaigns') }}</span>
										<strong>{{ formatCompactNumber(heroStats.campaignCount) }}</strong>
									</div>
									<div class="progress">
										<div class="progress-bar bg-info" :style="{ width: Math.min(100, heroStats.campaignCount) + '%' }"></div>
									</div>
								</div>
								<div class="hero-progress-item">
									<div class="d-flex justify-content-between">
										<span>Chiến dịch đang mở</span>
										<strong>{{ impactStats.activeCampaigns }}</strong>
									</div>
									<div class="progress">
										<div class="progress-bar bg-warning" :style="{ width: impactStats.activeRate + '%' }"></div>
									</div>
								</div>
								<div class="hero-progress-item">
									<div class="d-flex justify-content-between">
										<span>Tỉ lệ hoàn thành</span>
										<strong>{{ impactStats.completedRate }}%</strong>
									</div>
									<div class="progress">
										<div class="progress-bar bg-success" :style="{ width: impactStats.completedRate + '%' }"></div>
									</div>
								</div>
							</div>
							<router-link to="/danh-sach-chien-dich" class="hero-panel-link">
								Khám phá toàn bộ chiến dịch
								<i class="fa-solid fa-arrow-right-long"></i>
							</router-link>
						</div>
					</div>
				</div>
			</div>
		</section>

		<section class="overview-section">
			<div class="container">
				<div class="section-head">
					<div>
						<h4>Trung tâm thông tin nhanh</h4>
						<p>Nhìn nhanh các chỉ số quan trọng trước khi điều phối nhân sự.</p>
					</div>
					<router-link to="/danh-sach-chien-dich" class="btn btn-outline-primary btn-sm">
						Xem danh sách chiến dịch
					</router-link>
				</div>
				<div class="row g-3">
					<div class="col-lg-3 col-sm-6" v-for="card in overviewCards" :key="card.title">
						<div class="overview-card">
							<div class="overview-icon" :class="card.iconClass">
								<i :class="card.icon"></i>
							</div>
							<p class="overview-label">{{ card.title }}</p>
							<h5 class="overview-value">{{ card.value }}</h5>
							<p class="overview-subtitle">{{ card.subtitle }}</p>
						</div>
					</div>
				</div>
			</div>
		</section>

		<section class="featured-section py-5" id="campaigns">
			<div class="container">
				<div class="section-head mb-4">
					<div>
						<h4><i class="fa-solid fa-fire text-danger me-2"></i>{{ $t('home.featuredCampaigns') }}</h4>
						<p>{{ $t('home.featuredCampaignsDesc') }}</p>
					</div>
					<router-link to="/danh-sach-chien-dich" class="btn btn-outline-primary btn-sm">
						{{ $t('common.viewAll') }} <i class="fa-solid fa-arrow-right ms-1"></i>
					</router-link>
				</div>
				<div v-if="campaigns.length" class="row g-4">
					<div class="col-lg-7">
						<div class="feature-spotlight" v-if="featuredSpotlight">
							<div class="feature-spotlight-banner" :style="{ backgroundImage: featuredSpotlight.image ? `url(${featuredSpotlight.image})` : featuredSpotlight.color }">
								<span class="badge bg-light text-dark">{{ featuredSpotlight.tag }}</span>
								<span class="spotlight-chip">
									<i class="fa-solid fa-bullseye me-1"></i>
									Tâm điểm tuần này
								</span>
							</div>
							<div class="feature-spotlight-body">
								<div>
									<h4>{{ featuredSpotlight.title }}</h4>
									<p>{{ featuredSpotlight.description }}</p>
								</div>
								<div class="spotlight-meta">
									<span><i class="fa-solid fa-location-dot me-2"></i>{{ featuredSpotlight.location }}</span>
									<span><i class="fa-regular fa-calendar me-2"></i>{{ featuredSpotlight.date }}</span>
									<span><i class="fa-solid fa-users me-2"></i>{{ featuredSpotlight.registered }}/{{ featuredSpotlight.total }}</span>
								</div>
								<div class="progress mt-2">
									<div class="progress-bar" :class="featuredSpotlight.progressClass" :style="{ width: getProgressWidth(featuredSpotlight) + '%' }"></div>
								</div>
								<router-link :to="`/chi-tiet-chien-dich/${featuredSpotlight.id}`" class="btn btn-primary mt-3">
									{{ $t('common.viewDetails') }}
								</router-link>
							</div>
						</div>
					</div>
					<div class="col-lg-5">
						<div class="compact-campaign-list">
							<div v-for="campaign in featuredSecondary" :key="campaign.id" class="compact-campaign-item">
								<div class="compact-thumb" :style="{ backgroundImage: campaign.image ? `url(${campaign.image})` : campaign.color }"></div>
								<div class="compact-content">
									<h6 class="mb-1">{{ campaign.title }}</h6>
									<p class="mb-2">{{ campaign.location }} • {{ campaign.date }}</p>
									<div class="d-flex align-items-center justify-content-between">
										<small>{{ campaign.registered }}/{{ campaign.total }} đăng ký</small>
										<router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="compact-link">Xem</router-link>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
				<div v-else class="card border-0 shadow-sm">
					<div class="card-body py-5 text-center text-muted">
						<div v-if="isLoading" class="spinner-border text-primary mb-3" role="status"></div>
						<i v-else class="fa-solid fa-fire-flame-curved d-block fs-1 mb-3 text-danger opacity-50"></i>
						<p class="mb-0">Chưa có chiến dịch nổi bật để hiển thị.</p>
					</div>
				</div>
			</div>
		</section>

		<section class="py-5 upcoming-section" id="upcoming-campaigns">
			<div class="container">
				<div class="section-head mb-4">
					<div>
						<h4><i class="fa-solid fa-calendar-day text-primary me-2"></i>{{ $t('home.upcomingCampaigns') }}</h4>
						<p>{{ $t('home.upcomingCampaignsDesc') }}</p>
					</div>
				</div>
				<div v-if="upcomingCampaigns.length" class="row g-4">
					<div class="col-lg-4 col-md-6" v-for="(campaign, index) in upcomingCampaigns" :key="`upcoming-${index}`">
						<div class="card h-100 campaign-card upcoming-card">
							<div class="card-img-top campaign-banner" :style="{ backgroundImage: campaign.image ? `url(${campaign.image})` : campaign.color, backgroundSize: 'cover', backgroundPosition: 'center' }">
								<span class="badge upcoming-badge">{{ $t('home.startsOn') }} {{ campaign.date }}</span>
							</div>
							<div class="card-body">
								<h5 class="card-title fw-bold">{{ campaign.title }}</h5>
								<p class="card-text text-muted small">{{ campaign.description }}</p>
								<div class="d-flex gap-3 text-muted small mb-3 flex-wrap">
									<span><i class="fa-solid fa-location-dot me-1"></i>{{ campaign.location }}</span>
									<span><i class="fa-solid fa-hourglass-start me-1"></i>{{ getTimeLabel(campaign.dateRaw) }}</span>
								</div>
								<div class="mb-3">
									<div class="d-flex justify-content-between mb-1">
										<small class="text-muted">{{ $t('home.registered') }}</small>
										<small class="fw-bold">{{ campaign.registered }}/{{ campaign.total }}</small>
									</div>
									<div class="progress" style="height: 6px;">
										<div class="progress-bar bg-primary" role="progressbar" :style="{ width: getProgressWidth(campaign) + '%' }"></div>
									</div>
								</div>
							</div>
							<div class="card-footer bg-transparent border-top">
								<router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="btn btn-primary btn-sm w-100 d-flex align-items-center justify-content-center">
									{{ $t('common.viewDetails') }}
								</router-link>
							</div>
						</div>
					</div>
				</div>
				<div v-else class="card border-0 shadow-sm">
					<div class="card-body py-5 text-center text-muted">
						<div v-if="isLoading" class="spinner-border text-primary mb-3" role="status"></div>
						<i v-else class="fa-solid fa-calendar-plus d-block fs-1 mb-3 text-primary opacity-50"></i>
						<p class="mb-0">{{ $t('home.noUpcomingCampaigns') }}</p>
					</div>
				</div>
			</div>
		</section>

		<section class="py-5" id="completed-campaigns">
			<div class="container">
				<div class="section-head mb-4">
					<div>
						<h4><i class="fa-solid fa-check-circle text-success me-2"></i>{{ $t('home.completedCampaigns') }}</h4>
						<p>{{ $t('home.completedCampaignsDesc') }}</p>
					</div>
				</div>
				<div v-if="completedCampaigns.length" class="row g-4">
					<div class="col-lg-4 col-md-6" v-for="(campaign, index) in completedCampaigns" :key="index">
						<div class="card h-100 campaign-card opacity-75">
							<div class="card-img-top campaign-banner" :style="{ backgroundImage: campaign.image ? `url(${campaign.image})` : campaign.color, backgroundSize: 'cover', backgroundPosition: 'center', filter: 'grayscale(30%)' }">
								<span class="badge bg-success text-white">{{ $t('common.completed') }}</span>
							</div>
							<div class="card-body">
								<h5 class="card-title fw-bold text-muted">{{ campaign.title }}</h5>
								<p class="card-text text-muted small">{{ campaign.description }}</p>
								<div class="d-flex gap-3 text-muted small mb-3">
									<span><i class="fa-solid fa-location-dot me-1"></i>{{ campaign.location }}</span>
									<span><i class="fa-solid fa-users me-1"></i>{{ campaign.total }} {{ $t('common.volunteerShort') }}</span>
								</div>
							</div>
							<div class="card-footer bg-transparent border-top text-center">
								<div class="d-flex gap-2">
									<button class="btn btn-light btn-sm flex-fill text-muted d-flex align-items-center justify-content-center" disabled>
										<i class="fa-solid fa-lock me-1"></i>{{ $t('common.closed') }}
									</button>
									<router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="btn btn-outline-secondary btn-sm flex-fill d-flex align-items-center justify-content-center">
										{{ $t('common.viewDetails') }}
									</router-link>
								</div>
							</div>
						</div>
					</div>
				</div>
				<div v-else class="card border-0 shadow-sm">
					<div class="card-body py-5 text-center text-muted">
						<div v-if="isLoading" class="spinner-border text-success mb-3" role="status"></div>
						<i v-else class="fa-solid fa-circle-check d-block fs-1 mb-3 text-success opacity-50"></i>
						<p class="mb-0">Chưa có chiến dịch đã hoàn thành để hiển thị.</p>
					</div>
				</div>
			</div>
		</section>

		<section class="impact-section py-5">
			<div class="container">
				<div class="section-head mb-4">
					<div>
						<h4><i class="fa-solid fa-chart-line text-success me-2"></i>Bản đồ tác động cộng đồng</h4>
						<p>Đo lường hiệu quả triển khai để ban điều phối ra quyết định nhanh hơn.</p>
					</div>
				</div>
				<div class="row g-4">
					<div class="col-lg-4">
						<div class="impact-card">
							<p class="impact-label">Năng lực phủ chiến dịch</p>
							<h3>{{ impactStats.activeCampaigns }}</h3>
							<p class="impact-desc">Chiến dịch đang vận hành trên toàn hệ thống.</p>
							<div class="impact-bar"><span :style="{ width: impactStats.activeRate + '%' }"></span></div>
						</div>
					</div>
					<div class="col-lg-4">
						<div class="impact-card">
							<p class="impact-label">Lượng tình nguyện viên đã phục vụ</p>
							<h3>{{ formatCompactNumber(impactStats.totalRegistrations) }}</h3>
							<p class="impact-desc">Lượt phân bổ nhân sự vào các nhiệm vụ cụ thể.</p>
							<div class="impact-bar"><span :style="{ width: impactStats.fillRate + '%' }"></span></div>
						</div>
					</div>
					<div class="col-lg-4">
						<div class="impact-card">
							<p class="impact-label">Chiến dịch hoàn tất</p>
							<h3>{{ completedCampaigns.length }}</h3>
							<p class="impact-desc">Đã khép lại với báo cáo tổng kết và đánh giá.</p>
							<div class="impact-bar"><span :style="{ width: impactStats.completedRate + '%' }"></span></div>
						</div>
					</div>
				</div>
			</div>
		</section>

		<section class="py-5 recent-volunteer-section">
			<div class="container">
				<div class="section-head mb-4">
					<div>
						<h4><i class="fa-solid fa-user-clock text-primary me-2"></i>Các TNV tham gia gần đây</h4>
						<p>Những lượt đăng ký mới nhất để đội ngũ điều phối theo dõi nhanh.</p>
					</div>
				</div>
				<div v-if="recentVolunteers.length" class="row g-3">
					<div class="col-lg-4 col-md-6" v-for="item in recentVolunteers" :key="item.id">
						<div class="recent-volunteer-card">
							<div class="recent-volunteer-head">
								<div class="recent-volunteer-avatar">
									<img v-if="item.avatar" :src="item.avatar" :alt="item.name">
									<i v-else class="fa-solid fa-user"></i>
								</div>
								<div class="recent-volunteer-meta">
									<h6 class="mb-0">{{ item.name }}</h6>
									<small>{{ item.relativeTime }}</small>
								</div>
								<span class="recent-volunteer-status">{{ item.statusLabel }}</span>
							</div>
							<div class="recent-volunteer-body">
								<p class="mb-1">{{ item.campaignTitle }}</p>
								<small><i class="fa-solid fa-location-dot me-1"></i>{{ item.location }}</small>
							</div>
						</div>
					</div>
				</div>
				<div v-else class="card border-0 shadow-sm">
					<div class="card-body py-4 text-center text-muted">
						<div v-if="isLoading" class="spinner-border text-primary mb-3" role="status"></div>
						<i v-else class="fa-solid fa-users-viewfinder d-block fs-1 mb-3 text-primary opacity-50"></i>
						<p class="mb-0">Chưa có lượt tham gia gần đây để hiển thị.</p>
					</div>
				</div>
			</div>
		</section>

		<section class="py-5 ai-support-section">
			<div class="container">
				<div class="section-head mb-4">
					<div>
						<h4><i class="fa-solid fa-brain text-warning me-2"></i>AI hỗ trợ vận hành</h4>
						<p>Tách bạch rõ hỗ trợ điều phối và hỗ trợ duyệt chiến dịch để dùng đúng ngữ cảnh.</p>
					</div>
				</div>
				<div class="row g-4">
					<div class="col-lg-6" v-for="card in aiSupportCards" :key="card.title">
						<div class="ai-support-card">
							<div class="ai-support-header">
								<span class="ai-support-badge">{{ card.badge }}</span>
								<i :class="card.icon"></i>
							</div>
							<h5>{{ card.title }}</h5>
							<p>{{ card.description }}</p>
							<ul class="ai-support-list">
								<li v-for="point in card.points" :key="point">{{ point }}</li>
							</ul>
						</div>
					</div>
				</div>
			</div>
		</section>

		<section class="py-5 join-flow-section">
			<div class="container">
				<div class="section-head mb-4">
					<div>
						<h4>{{ $t('home.howToJoin') }}</h4>
						<p>{{ $t('home.howToJoinDesc') }}</p>
					</div>
				</div>
				<div class="row g-4">
					<div class="col-lg-3 col-md-6" v-for="(step, index) in steps" :key="index">
						<div class="step-card h-100">
							<div class="step-card-head">
								<span class="step-number">{{ index + 1 }}</span>
								<div class="step-icon">
									<i :class="step.icon"></i>
								</div>
							</div>
							<h6 class="fw-bold mt-3">{{ step.title }}</h6>
							<p class="text-muted small mb-0">{{ step.description }}</p>
						</div>
					</div>
				</div>
			</div>
		</section>
	</div>
</template>

<script>
import api from '@/services/api';
import { buildCampaignDescriptionPreview } from '@/utils/campaignDescription';

export default {
	name: "TrangChu",
	data() {
		return {
			heroStats: {
				volunteerCount: 0,
				campaignCount: 0,
				provinceCount: 0,
			},
			upcomingCampaigns: [],
			completedCampaigns: [],
			campaigns: [],
			recentVolunteers: [],
			isLoading: false,
		}
	},
	computed: {
		featuredSpotlight() {
			return this.campaigns[0] || null;
		},
		featuredSecondary() {
			return this.campaigns.slice(1, 4);
		},
		overviewCards() {
			return [
				{
					title: 'Tình nguyện viên',
					value: `${this.formatCompactNumber(this.heroStats.volunteerCount)}+`,
					subtitle: 'Đã xác thực tài khoản trên hệ thống',
					icon: 'fa-solid fa-user-group',
					iconClass: 'overview-icon-blue',
				},
				{
					title: 'Chiến dịch đang mở',
					value: this.formatCompactNumber(this.impactStats.activeCampaigns),
					subtitle: `${this.impactStats.activeRate}% trên tổng chiến dịch`,
					icon: 'fa-solid fa-bullhorn',
					iconClass: 'overview-icon-orange',
				},
				{
					title: 'Lượt đăng ký',
					value: this.formatCompactNumber(this.impactStats.totalRegistrations),
					subtitle: 'Đã được tiếp nhận và xử lý',
					icon: 'fa-solid fa-clipboard-check',
					iconClass: 'overview-icon-green',
				},
				{
					title: 'Tỉ lệ lấp đầy',
					value: `${this.impactStats.fillRate}%`,
					subtitle: 'Mức đáp ứng nhân sự theo chỉ tiêu',
					icon: 'fa-solid fa-chart-pie',
					iconClass: 'overview-icon-purple',
				},
			];
		},
		impactStats() {
			const featuredAndUpcoming = [...this.campaigns, ...this.upcomingCampaigns];
			const allCampaigns = [...featuredAndUpcoming, ...this.completedCampaigns];
			const totalCapacity = allCampaigns.reduce((sum, item) => sum + Number(item.total || 0), 0);
			const totalRegistrations = allCampaigns.reduce((sum, item) => sum + Number(item.registered || 0), 0);
			const activeCampaigns = featuredAndUpcoming.length;
			const totalCampaigns = allCampaigns.length || 1;
			const fillRate = totalCapacity > 0 ? Math.round((totalRegistrations / totalCapacity) * 100) : 0;
			const completedRate = Math.round((this.completedCampaigns.length / totalCampaigns) * 100);
			const activeRate = Math.round((activeCampaigns / totalCampaigns) * 100);
			return {
				totalRegistrations,
				fillRate: Math.min(100, Math.max(0, fillRate)),
				completedRate: Math.min(100, Math.max(0, completedRate)),
				activeCampaigns,
				activeRate: Math.min(100, Math.max(0, activeRate)),
			};
		},
		aiSupportCards() {
			return [
				{
					badge: 'Điều phối (Recommend)',
					title: 'AI hỗ trợ điều phối nhân sự',
					description: 'Dùng để gợi ý TNV phù hợp cho từng chiến dịch dựa trên kỹ năng, khu vực và mức độ phù hợp.',
					icon: 'fa-solid fa-people-arrows text-primary',
					points: [
						'Ưu tiên đúng khu vực và kỹ năng đang cần.',
						'Giảm thời gian lọc danh sách thủ công.',
						'Hỗ trợ mời TNV ngay tại màn điều phối.',
					],
				},
				{
					badge: 'Duyệt chiến dịch (AI)',
					title: 'AI hỗ trợ ra quyết định duyệt chiến dịch',
					description: 'Dùng để phân tích độ tin cậy chiến dịch mới, cảnh báo rủi ro và đề xuất hành động cho kiểm duyệt viên.',
					icon: 'fa-solid fa-shield-halved text-success',
					points: [
						'Phân tích nội dung và điểm tin cậy campaign.',
						'Gợi ý hành động duyệt/từ chối/đòi bổ sung.',
						'Hiển thị chỉ dấu rủi ro từ trust-eval-service.',
					],
				},
			];
		},
		steps() {
			return [
				{ icon: 'fa-solid fa-user-plus', title: this.$t('home.step1Title'), description: this.$t('home.step1Desc') },
				{ icon: 'fa-solid fa-magnifying-glass', title: 'Tìm chiến dịch', description: this.$t('home.step2Desc') },
				{ icon: 'fa-solid fa-clipboard-check', title: 'Đăng ký tham gia', description: this.$t('home.step3Desc') },
				{ icon: 'fa-solid fa-award', title: 'Nhận đánh giá', description: this.$t('home.step4Desc') }
			]
		},
	},
	created() {
		this.fetchHomeData();
	},
	methods: {
		async fetchHomeData() {
			this.isLoading = true;
			try {
				const response = await api.get('/trang-chu');
				const payload = response.data?.data || {};
				this.heroStats = {
					volunteerCount: Number(payload.hero?.volunteer_count || 0),
					campaignCount: Number(payload.hero?.campaign_count || 0),
					provinceCount: Number(payload.hero?.province_count || 0),
				};
				this.campaigns = Array.isArray(payload.featured_campaigns)
					? payload.featured_campaigns.map((campaign) => this.mapCampaignForUi(campaign))
					: [];
				this.upcomingCampaigns = Array.isArray(payload.upcoming_campaigns)
					? payload.upcoming_campaigns.map((campaign) => this.mapCampaignForUi(campaign))
					: [];
				this.completedCampaigns = Array.isArray(payload.completed_campaigns)
					? payload.completed_campaigns.map((campaign) => this.mapCampaignForUi(campaign, true))
					: [];
				this.recentVolunteers = Array.isArray(payload.recent_volunteers)
					? payload.recent_volunteers.map((entry) => this.mapRecentVolunteer(entry))
					: [];
			} catch (_error) {
				this.heroStats = {
					volunteerCount: 0,
					campaignCount: 0,
					provinceCount: 0,
				};
				this.campaigns = [];
				this.upcomingCampaigns = [];
				this.completedCampaigns = [];
				this.recentVolunteers = [];
			} finally {
				this.isLoading = false;
			}
		},
		mapRecentVolunteer(entry) {
			return {
				id: entry?.id,
				name: entry?.nguoi_dung?.ho_ten || 'Tình nguyện viên',
				avatar: entry?.nguoi_dung?.anh_dai_dien || '',
				campaignTitle: entry?.chien_dich?.tieu_de || this.$t('common.notAvailable'),
				location: entry?.chien_dich?.dia_diem || this.$t('common.notAvailable'),
				statusLabel: this.resolveVolunteerStatusLabel(entry?.trang_thai),
				relativeTime: this.formatRelativeTime(entry?.dang_ky_luc),
			};
		},
		mapCampaignForUi(campaign, completed = false) {
			const totalSlots = Number(campaign?.so_luong_toi_da || 0);
			const registered = Number(campaign?.so_dang_ky || 0);
			const confirmed = Number(campaign?.so_xac_nhan || 0);
			return {
				id: campaign.id,
				icon: this.resolveCampaignIcon(campaign),
				title: campaign.tieu_de,
				description: buildCampaignDescriptionPreview(campaign.mo_ta) || this.$t('common.notAvailable'),
				location: campaign.dia_diem || this.$t('common.notAvailable'),
				date: this.formatDate(campaign.ngay_bat_dau),
				dateRaw: campaign.ngay_bat_dau || null,
				tag: completed ? this.$t('common.completed') : (campaign?.loai_chien_dich?.ten || 'Chiến dịch'),
				color: this.resolveCampaignGradient(campaign, completed),
				image: campaign.anh_bia,
				progressClass: this.resolveProgressClass(campaign?.muc_do_uu_tien),
				registered,
				total: totalSlots > 0 ? totalSlots : Math.max(registered, confirmed, 1),
			};
		},
		resolveCampaignIcon(campaign) {
			const icon = (campaign?.loai_chien_dich?.bieu_tuong || '').trim();
			if (icon) {
				return icon.startsWith('fa-') ? icon : `fa-solid ${icon}`;
			}

			const typeName = (campaign?.loai_chien_dich?.ten || '').toLowerCase();
			if (typeName.includes('y tế')) return 'fa-solid fa-hand-holding-medical';
			if (typeName.includes('giáo dục')) return 'fa-solid fa-book-open';
			if (typeName.includes('môi trường')) return 'fa-solid fa-tree';
			return 'fa-solid fa-hands-holding-circle';
		},
		resolveCampaignGradient(campaign, completed = false) {
			if (completed) {
				return 'linear-gradient(135deg, #6c757d, #adb5bd)';
			}

			const priority = campaign?.muc_do_uu_tien;
			if (priority === 'khan_cap') return 'linear-gradient(135deg, #dc3545, #fd7e14)';
			if (priority === 'cao') return 'linear-gradient(135deg, #0d6efd, #6610f2)';
			if (priority === 'thap') return 'linear-gradient(135deg, #198754, #20c997)';
			return 'linear-gradient(135deg, #0dcaf0, #0d6efd)';
		},
		resolveProgressClass(priority) {
			if (priority === 'khan_cap') return 'bg-danger';
			if (priority === 'cao') return 'bg-primary';
			if (priority === 'thap') return 'bg-success';
			return 'bg-info';
		},
		formatDate(date) {
			if (!date) return this.$t('common.notAvailable');
			const parsed = new Date(date);
			if (Number.isNaN(parsed.getTime())) return date;
			return parsed.toLocaleDateString('vi-VN');
		},
		formatCompactNumber(value) {
			const numericValue = Number(value || 0);
			return numericValue.toLocaleString('vi-VN');
		},
		getTimeLabel(date) {
			if (!date) {
				return this.$t('common.notAvailable');
			}
			const target = new Date(date);
			if (Number.isNaN(target.getTime())) {
				return this.$t('home.startsOn') + ' ' + this.formatDate(date);
			}
			const now = new Date();
			const dayDiff = Math.ceil((target - now) / (1000 * 60 * 60 * 24));
			if (dayDiff <= 0) {
				return 'Sắp bắt đầu';
			}
			if (dayDiff === 1) {
				return 'Bắt đầu sau 1 ngày';
			}
			return `Bắt đầu sau ${dayDiff} ngày`;
		},
		formatRelativeTime(dateTime) {
			if (!dateTime) return this.$t('common.notAvailable');
			const parsed = new Date(dateTime);
			if (Number.isNaN(parsed.getTime())) {
				return this.formatDate(dateTime);
			}
			const now = new Date();
			const diffMs = now.getTime() - parsed.getTime();
			const diffMinutes = Math.floor(diffMs / 60000);
			if (diffMinutes < 1) return 'Vừa xong';
			if (diffMinutes < 60) return `${diffMinutes} phút trước`;
			const diffHours = Math.floor(diffMinutes / 60);
			if (diffHours < 24) return `${diffHours} giờ trước`;
			const diffDays = Math.floor(diffHours / 24);
			if (diffDays < 30) return `${diffDays} ngày trước`;
			return this.formatDate(dateTime);
		},
		resolveVolunteerStatusLabel(status) {
			const labelMap = {
				da_dang_ky: 'Đã đăng ký',
				da_duyet: 'Đã duyệt',
				da_xac_nhan: 'Đã xác nhận',
				dang_tham_gia: 'Đang tham gia',
				hoan_thanh: 'Hoàn thành',
			};
			return labelMap[status] || 'Cập nhật mới';
		},
		getProgressWidth(campaign) {
			if (!campaign?.total) {
				return 0;
			}
			return Math.min(100, Math.round((campaign.registered / campaign.total) * 100));
		},
	},
}
</script>

<style scoped>
.home-page {
	--accent-primary: #0f4c81;
	--accent-secondary: #198754;
	--accent-warm: #f59f00;
	--text-soft: #516070;
	--border-soft: #dbe4ef;
	--surface-soft: #f4f8fc;
}

.hero-section {
	position: relative;
	padding: 72px 0 52px;
	overflow: hidden;
	border-radius: 6px;
	background:
		radial-gradient(circle at 15% 20%, rgba(255, 199, 100, 0.28), transparent 36%),
		radial-gradient(circle at 85% 75%, rgba(57, 182, 141, 0.28), transparent 34%),
		linear-gradient(140deg, #12375b, #0f4c81 55%, #114677);
}

.hero-mesh {
	position: absolute;
	inset: 0;
	background-image: linear-gradient(rgba(255, 255, 255, 0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, 0.05) 1px, transparent 1px);
	background-size: 24px 24px;
	mix-blend-mode: soft-light;
}

.hero-content {
	position: relative;
	z-index: 1;
}

.hero-pill {
	display: inline-flex;
	align-items: center;
	padding: 8px 14px;
	border-radius: 6px;
	background: rgba(255, 255, 255, 0.14);
	color: #f6fbff;
	font-weight: 600;
	font-size: 13px;
	backdrop-filter: blur(2px);
}

.hero-title {
	margin-top: 18px;
	color: #f8fbff;
	font-size: 43px;
	font-weight: 800;
	letter-spacing: -0.02em;
	line-height: 1.2;
}

.hero-title span {
	display: block;
	color: #ffd46b;
}

.hero-description {
	margin-top: 16px;
	max-width: 620px;
	color: rgba(248, 251, 255, 0.92);
	font-size: 16px;
	line-height: 1.7;
}

.hero-actions {
	display: flex;
	flex-wrap: wrap;
	gap: 12px;
	margin-top: 24px;
}

.hero-mini-grid {
	margin-top: 30px;
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 12px;
}

.hero-mini-item {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 12px;
	background: rgba(255, 255, 255, 0.12);
	border: 1px solid rgba(255, 255, 255, 0.14);
	border-radius: 6px;
	color: #f8fbff;
}

.hero-mini-item i {
	width: 34px;
	height: 34px;
	border-radius: 4px;
	background: rgba(255, 255, 255, 0.17);
	display: inline-flex;
	align-items: center;
	justify-content: center;
}

.hero-mini-label {
	margin-bottom: 2px;
	font-size: 12px;
	opacity: 0.85;
}

.hero-panel {
	background: #ffffff;
	border-radius: 6px;
	padding: 20px;
	box-shadow: 0 18px 40px rgba(7, 28, 54, 0.28);
	border: 1px solid rgba(255, 255, 255, 0.4);
}

.hero-panel-head {
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	gap: 12px;
}

.hero-panel-head p {
	font-size: 12px;
	text-transform: uppercase;
	color: #6f7f91;
	letter-spacing: 0.05em;
}

.hero-live-dot {
	font-size: 11px;
	font-weight: 700;
	color: #198754;
	background: rgba(25, 135, 84, 0.15);
	padding: 6px 10px;
	border-radius: 4px;
}

.hero-progress-list {
	margin-top: 14px;
	display: grid;
	gap: 14px;
}

.hero-progress-item span {
	color: #425263;
	font-size: 14px;
}

.hero-progress-item strong {
	color: #1d2a36;
	font-size: 15px;
}

.hero-progress-item .progress {
	margin-top: 8px;
	height: 7px;
	background: #edf2f8;
}

.hero-panel-link {
	margin-top: 18px;
	display: inline-flex;
	align-items: center;
	gap: 8px;
	color: var(--accent-primary);
	font-weight: 700;
	text-decoration: none;
}

.section-head {
	display: flex;
	gap: 20px;
	justify-content: space-between;
	align-items: end;
	flex-wrap: wrap;
}

.section-head h4 {
	margin-bottom: 6px;
	font-weight: 800;
	color: #213244;
}

.section-head p {
	margin-bottom: 0;
	color: var(--text-soft);
}

.overview-section {
	padding: 42px 0 18px;
}

.overview-card {
	height: 100%;
	padding: 18px 16px;
	border-radius: 6px;
	border: 1px solid var(--border-soft);
	background: #fff;
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.overview-card:hover {
	transform: translateY(-3px);
	box-shadow: 0 12px 28px rgba(28, 68, 109, 0.12);
}

.overview-icon {
	width: 42px;
	height: 42px;
	border-radius: 4px;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	margin-bottom: 12px;
}

.overview-icon i {
	color: #fff;
}

.overview-icon-blue { background: linear-gradient(135deg, #1a6ec2, #2ea2ff); }
.overview-icon-orange { background: linear-gradient(135deg, #f08c00, #ffc078); }
.overview-icon-green { background: linear-gradient(135deg, #2f9e44, #69db7c); }
.overview-icon-purple { background: linear-gradient(135deg, #7048e8, #b197fc); }

.overview-label {
	margin-bottom: 4px;
	color: #6b7b8b;
	font-size: 13px;
}

.overview-value {
	margin-bottom: 6px;
	color: #1a2e44;
	font-weight: 800;
}

.overview-subtitle {
	margin-bottom: 0;
	color: #607284;
	font-size: 13px;
}

.featured-section {
	padding-top: 34px;
}

.feature-spotlight {
	border-radius: 6px;
	background: #fff;
	border: 1px solid var(--border-soft);
	overflow: hidden;
	height: 100%;
}

.feature-spotlight-banner {
	min-height: 220px;
	padding: 18px;
	background-size: cover;
	background-position: center;
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	gap: 8px;
}

.spotlight-chip {
	background: rgba(8, 26, 45, 0.72);
	color: #fff;
	padding: 6px 10px;
	border-radius: 4px;
	font-size: 12px;
	font-weight: 600;
}

.feature-spotlight-body {
	padding: 18px;
}

.feature-spotlight-body h4 {
	color: #213244;
	font-weight: 800;
}

.feature-spotlight-body p {
	color: #5d6f81;
}

.spotlight-meta {
	display: flex;
	flex-wrap: wrap;
	gap: 12px;
	color: #55687b;
	font-size: 13px;
}

.compact-campaign-list {
	display: grid;
	gap: 14px;
}

.compact-campaign-item {
	display: flex;
	gap: 12px;
	padding: 12px;
	background: #fff;
	border: 1px solid var(--border-soft);
	border-radius: 6px;
	transition: box-shadow 0.2s ease, transform 0.2s ease;
}

.compact-campaign-item:hover {
	transform: translateY(-2px);
	box-shadow: 0 10px 22px rgba(26, 63, 99, 0.12);
}

.compact-thumb {
	width: 88px;
	height: 88px;
	border-radius: 4px;
	background-size: cover;
	background-position: center;
	flex-shrink: 0;
}

.compact-content h6 {
	color: #27384a;
	font-weight: 700;
}

.compact-content p {
	color: #6a7d90;
	font-size: 13px;
}

.compact-content small {
	color: #5f7082;
}

.compact-link {
	font-weight: 700;
	color: var(--accent-primary);
	text-decoration: none;
}

.impact-section {
	background: transparent;
}

.recent-volunteer-card {
	height: 100%;
	background: #fff;
	border: 1px solid var(--border-soft);
	border-radius: 6px;
	padding: 14px;
}

.recent-volunteer-head {
	display: flex;
	align-items: center;
	gap: 10px;
}

.recent-volunteer-avatar {
	width: 40px;
	height: 40px;
	border-radius: 4px;
	background: #e7edf5;
	color: #4d5d6f;
	display: flex;
	align-items: center;
	justify-content: center;
	overflow: hidden;
	flex-shrink: 0;
}

.recent-volunteer-avatar img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.recent-volunteer-meta h6 {
	color: #24384e;
	font-weight: 700;
}

.recent-volunteer-meta small {
	color: #6f8093;
}

.recent-volunteer-status {
	margin-left: auto;
	font-size: 11px;
	font-weight: 700;
	color: #0f4c81;
	background: #e7f1ff;
	border-radius: 4px;
	padding: 5px 8px;
}

.recent-volunteer-body {
	margin-top: 12px;
	padding-top: 10px;
	border-top: 1px dashed #d7e3f0;
}

.recent-volunteer-body p {
	color: #2d3f52;
	font-weight: 600;
}

.recent-volunteer-body small {
	color: #6c7f93;
}

.ai-support-section {
	padding-top: 8px;
}

.ai-support-card {
	height: 100%;
	border: 1px solid var(--border-soft);
	border-radius: 6px;
	background: #fff;
	padding: 16px;
}

.ai-support-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 12px;
}

.ai-support-badge {
	font-size: 12px;
	font-weight: 700;
	color: #334d65;
	background: #edf3fb;
	border-radius: 4px;
	padding: 5px 8px;
}

.ai-support-header i {
	font-size: 20px;
}

.ai-support-card h5 {
	font-weight: 800;
	color: #23364c;
}

.ai-support-card p {
	color: #5e7285;
}

.ai-support-list {
	margin: 0;
	padding-left: 18px;
	color: #4f6478;
}

.ai-support-list li {
	margin-bottom: 6px;
}

.impact-card {
	height: 100%;
	background: #fff;
	border: 1px solid var(--border-soft);
	border-radius: 6px;
	padding: 18px;
}

.impact-label {
	color: #607184;
	margin-bottom: 8px;
}

.impact-card h3 {
	font-weight: 800;
	color: #223649;
	margin-bottom: 8px;
}

.impact-desc {
	color: #607184;
	font-size: 14px;
	margin-bottom: 14px;
}

.impact-bar {
	width: 100%;
	height: 8px;
	border-radius: 4px;
	background: #edf2f8;
	overflow: hidden;
}

.impact-bar span {
	display: block;
	height: 100%;
	border-radius: inherit;
	background: linear-gradient(90deg, #198754, #4dabf7);
}

.campaign-card {
	border: 1px solid #e9eef5;
	border-radius: 6px;
	overflow: hidden;
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.campaign-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 10px 28px rgba(13, 34, 56, 0.1);
}

.campaign-banner {
	height: 140px;
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	padding: 16px;
}

.upcoming-section {
	background: transparent;
}

.upcoming-card {
	border-color: rgba(15, 76, 129, 0.12);
}

.upcoming-badge {
	background: rgba(255, 255, 255, 0.94);
	color: #0f4c81;
	font-weight: 700;
}

.join-flow-section {
	background: #fff;
}

.step-card {
	background: #fff;
	border: 1px solid var(--border-soft);
	border-radius: 6px;
	padding: 16px;
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.step-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 10px 24px rgba(31, 67, 102, 0.12);
}

.step-card-head {
	display: flex;
	align-items: center;
	justify-content: space-between;
}

.step-number {
	width: 28px;
	height: 28px;
	border-radius: 4px;
	background: #eaf2ff;
	color: #0f4c81;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-weight: 700;
	font-size: 13px;
}

.step-icon {
	width: 48px;
	height: 48px;
	border-radius: 4px;
	background: rgba(15, 76, 129, 0.1);
	color: #0f4c81;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 20px;
}

@media (max-width: 991px) {
	.hero-title {
		font-size: 32px;
	}

	.hero-section {
		padding: 56px 0 42px;
	}

	.hero-mini-grid {
		grid-template-columns: 1fr;
	}
}

@media (max-width: 575px) {
	.hero-actions {
		flex-direction: column;
	}

	.hero-actions .btn {
		width: 100%;
	}

	.compact-campaign-item {
		flex-direction: column;
	}

	.compact-thumb {
		width: 100%;
		height: 130px;
	}
}
</style>
