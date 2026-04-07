<template>
	<div class="home-page">
		<!-- Hero Section với background -->
		<section class="hero-section">
			<div class="container position-relative" style="z-index:1;">
				<div class="row align-items-center min-vh-hero">
					<div class="col-lg-7">
						<h1 class="hero-title text-white">{{ $t('home.heroTitle') }} <br><span class="text-warning">{{ $t('home.heroBold') }}</span></h1>
						<p class="hero-description text-white">
							{{ $t('home.heroDesc') }}
						</p>
						<div class="d-flex gap-3 mt-4">
							<router-link to="/dang-ky" class="btn btn-warning fw-bold text-dark btn-lg px-4 shadow-sm">
								<i class="fa-solid fa-user-plus me-2"></i>{{ $t('home.joinNow') }}
							</router-link>
							<a href="#campaigns" class="btn btn-light btn-lg px-4 shadow-sm text-primary fw-bold border-0">
								<i class="fa-solid fa-eye me-2"></i>{{ $t('home.viewCampaigns') }}
							</a>
						</div>
						<div class="row mt-5 hero-counters">
							<div class="col-auto">
								<h3 class="mb-0 text-warning fw-bold">{{ formatCompactNumber(heroStats.volunteerCount) }}+</h3>
								<small class="text-white">{{ $t('home.counterVolunteers') }}</small>
							</div>
							<div class="col-auto border-start border-light border-opacity-50">
								<h3 class="mb-0 text-white fw-bold">{{ formatCompactNumber(heroStats.campaignCount) }}+</h3>
								<small class="text-white">{{ $t('home.counterCampaigns') }}</small>
							</div>
							<div class="col-auto border-start border-light border-opacity-50">
								<h3 class="mb-0 text-white fw-bold">{{ formatCompactNumber(heroStats.provinceCount) }}+</h3>
								<small class="text-white">{{ $t('home.counterProvinces') }}</small>
							</div>
						</div>
					</div>
					<div class="col-lg-5 d-none d-lg-block text-center">
						<div class="hero-image-wrapper">
							<div class="hero-icon-main">
								<i class="fa-solid fa-hands-holding-circle"></i>
							</div>
							<div class="hero-badge-card badge-1">
								<i class="fa-solid fa-users text-primary me-2"></i>
								<span>{{ $t('home.newVolunteers') }}</span>
							</div>
							<div class="hero-badge-card badge-2">
								<i class="fa-solid fa-heart text-danger me-2"></i>
								<span>{{ $t('home.satisfactionRate') }}</span>
							</div>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- Chiến dịch nổi bật -->
		<section class="py-5" id="campaigns">
			<div class="container">
				<div class="d-flex align-items-center justify-content-between mb-4">
					<div>
						<h4 class="fw-bold mb-1"><i class="fa-solid fa-fire text-danger me-2"></i>{{ $t('home.featuredCampaigns') }}</h4>
						<p class="text-muted mb-0">{{ $t('home.featuredCampaignsDesc') }}</p>
					</div>
					<router-link to="/danh-sach-chien-dich" class="btn btn-outline-primary btn-sm">{{ $t('common.viewAll') }} <i class="fa-solid fa-arrow-right ms-1"></i></router-link>
				</div>
				<div v-if="campaigns.length" class="row g-4">
					<div class="col-lg-4 col-md-6" v-for="(campaign, index) in campaigns" :key="index">
							<div class="card h-100 campaign-card">
								<div class="card-img-top campaign-banner" :style="{ backgroundImage: campaign.image ? `url(${campaign.image})` : campaign.color, backgroundSize: 'cover', backgroundPosition: 'center' }">
									<span class="badge bg-light text-dark">{{ campaign.tag }}</span>
								</div>
							<div class="card-body">
								<h5 class="card-title fw-bold">{{ campaign.title }}</h5>
								<p class="card-text text-muted small">{{ campaign.description }}</p>
								<div class="d-flex gap-3 text-muted small mb-3">
									<span><i class="fa-solid fa-location-dot me-1"></i>{{ campaign.location }}</span>
									<span><i class="fa-regular fa-calendar me-1"></i>{{ campaign.date }}</span>
								</div>
								<div class="mb-3">
									<div class="d-flex justify-content-between mb-1">
										<small class="text-muted">{{ $t('home.registered') }}</small>
										<small class="fw-bold">{{ campaign.registered }}/{{ campaign.total }}</small>
									</div>
									<div class="progress" style="height: 6px;">
										<div class="progress-bar" role="progressbar"
											:style="{ width: getProgressWidth(campaign) + '%' }"
											:class="campaign.progressClass"></div>
									</div>
								</div>
							</div>
							<div class="card-footer bg-transparent border-top">
								<div class="d-flex gap-2">
									<router-link to="/dang-sach-chien-dich" class="btn btn-primary btn-sm flex-fill d-flex align-items-center justify-content-center">
										{{ $t('common.apply') }}
									</router-link>
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
						<div v-if="isLoading" class="spinner-border text-primary mb-3" role="status"></div>
						<i v-else class="fa-solid fa-fire-flame-curved d-block fs-1 mb-3 text-danger opacity-50"></i>
						<p class="mb-0">Chưa có chiến dịch nổi bật để hiển thị.</p>
					</div>
				</div>
			</div>
		</section>

		<!-- Chiến dịch đã hoàn thành -->
		<section class="py-5 upcoming-section" id="upcoming-campaigns">
			<div class="container">
				<div class="d-flex align-items-center justify-content-between mb-4">
					<div>
						<h4 class="fw-bold mb-1"><i class="fa-solid fa-calendar-day text-primary me-2"></i>{{ $t('home.upcomingCampaigns') }}</h4>
						<p class="text-muted mb-0">{{ $t('home.upcomingCampaignsDesc') }}</p>
					</div>
					<router-link to="/danh-sach-chien-dich" class="btn btn-outline-primary btn-sm">{{ $t('common.viewAll') }} <i class="fa-solid fa-arrow-right ms-1"></i></router-link>
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
									<span><i class="fa-solid fa-hourglass-start me-1"></i>{{ $t('home.startsOn') }} {{ campaign.date }}</span>
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
								<div class="d-flex gap-2">
									<router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="btn btn-primary btn-sm flex-fill d-flex align-items-center justify-content-center">
										{{ $t('common.viewDetails') }}
									</router-link>
									<router-link to="/danh-sach-chien-dich" class="btn btn-outline-secondary btn-sm flex-fill d-flex align-items-center justify-content-center">
										{{ $t('home.viewCampaigns') }}
									</router-link>
								</div>
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

		<!-- Chiến dịch đã hoàn thành -->
		<section class="py-5 bg-light" id="completed-campaigns">
			<div class="container">
				<div class="d-flex align-items-center justify-content-between mb-4">
					<div>
						<h4 class="fw-bold mb-1"><i class="fa-solid fa-check-circle text-success me-2"></i>{{ $t('home.completedCampaigns') }}</h4>
						<p class="text-muted mb-0">{{ $t('home.completedCampaignsDesc') }}</p>
					</div>
					<router-link to="/danh-sach-chien-dich?trang_thai=completed" class="btn btn-outline-success btn-sm">{{ $t('common.viewAll') }} <i class="fa-solid fa-arrow-right ms-1"></i></router-link>
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

		<!-- Quy trình tham gia -->
		<section class="py-5">
			<div class="container">
				<div class="text-center mb-5">
					<h4 class="fw-bold">{{ $t('home.howToJoin') }}</h4>
					<p class="text-muted">{{ $t('home.howToJoinDesc') }}</p>
				</div>
				<div class="row g-4">
					<div class="col-lg-3 col-md-6" v-for="(step, index) in steps" :key="index">
						<div class="card text-center h-100 step-card">
							<div class="card-body">
								<div class="step-number-badge bg-primary">{{ index + 1 }}</div>
								<div class="step-icon mb-3">
									<i :class="step.icon"></i>
								</div>
								<h6 class="fw-bold">{{ step.title }}</h6>
								<p class="text-muted small mb-0">{{ step.description }}</p>
							</div>
						</div>
					</div>
				</div>
			</div>
		</section>


	</div>
</template>

<script>
import api from '@/services/api';

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
			isLoading: false,
		}
	},
	computed: {
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
			} catch (_error) {
				this.heroStats = {
					volunteerCount: 0,
					campaignCount: 0,
					provinceCount: 0,
				};
				this.campaigns = [];
				this.upcomingCampaigns = [];
				this.completedCampaigns = [];
			} finally {
				this.isLoading = false;
			}
		},
		mapCampaignForUi(campaign, completed = false) {
			const totalSlots = Number(campaign?.so_luong_toi_da || 0);
			const registered = Number(campaign?.so_dang_ky || 0);
			const confirmed = Number(campaign?.so_xac_nhan || 0);
			return {
				id: campaign.id,
				icon: this.resolveCampaignIcon(campaign),
				title: campaign.tieu_de,
				description: campaign.mo_ta,
				location: campaign.dia_diem || this.$t('common.notAvailable'),
				date: this.formatDate(campaign.ngay_bat_dau),
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
/* ===== Hero with dark background ===== */
.hero-section {
	position: relative;
	padding: 60px 0;
	background: linear-gradient(135deg, #86bfd7 0%, #addaea 50%, #5c91a8 100%);
	overflow: hidden;
    border-radius: 12px;
}

.hero-section::before {
	content: '';
	position: absolute;
	top: -150px;
	right: -100px;
	width: 500px;
	height: 500px;
	border-radius: 50%;
	background: rgba(13, 110, 253, 0.08);
}

.hero-section::after {
	content: '';
	position: absolute;
	bottom: -100px;
	left: -80px;
	width: 350px;
	height: 350px;
	border-radius: 50%;
	background: rgba(255, 193, 7, 0.06);
}

.min-vh-hero {
	min-height: 420px;
}

.hero-title {
	font-size: 38px;
	font-weight: 800;
	line-height: 1.3;
	text-shadow: 0 2px 4px rgba(0,0,0,0.15);
}

.hero-description {
	font-size: 16px;
	line-height: 1.7;
	max-width: 520px;
	text-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.hero-counters .col-auto {
	padding-left: 20px;
	padding-right: 20px;
}

.hero-counters h3 {
	text-shadow: 0 2px 4px rgba(0,0,0,0.15);
}

/* Hero Visual */
.hero-image-wrapper {
	position: relative;
	width: 320px;
	height: 320px;
	margin: 0 auto;
}

.hero-icon-main {
	position: absolute;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -50%);
	width: 130px;
	height: 130px;
	background: #0d6efd;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 56px;
	color: white;
	box-shadow: 0 10px 40px rgba(13, 110, 253, 0.4);
}

.hero-badge-card {
	position: absolute;
	display: flex;
	align-items: center;
	padding: 10px 16px;
	background: white;
	border-radius: 10px;
	box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
	font-size: 13px;
	font-weight: 600;
	color: #333;
	animation: floatBadge 4s ease-in-out infinite;
}

.badge-1 { top: 30px; right: 10px; animation-delay: 0s; }
.badge-2 { bottom: 40px; left: 0; animation-delay: 2s; }

@keyframes floatBadge {
	0%, 100% { transform: translateY(0); }
	50% { transform: translateY(-8px); }
}

/* ===== Campaign Cards ===== */
.campaign-card {
	border: 1px solid #e9ecef;
	border-radius: 12px;
	overflow: hidden;
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.campaign-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08);
}

.campaign-banner {
	height: 140px;
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	padding: 16px;
}

.campaign-banner-icon {
	width: 50px;
	height: 50px;
	background: rgba(255, 255, 255, 0.2);
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 22px;
	color: white;
}

.upcoming-section {
	background: linear-gradient(180deg, rgba(13, 110, 253, 0.04), rgba(13, 110, 253, 0));
}

.upcoming-card {
	border-color: rgba(13, 110, 253, 0.12);
}

.upcoming-badge {
	background: rgba(255, 255, 255, 0.94);
	color: #0d6efd;
	font-weight: 700;
}

/* ===== Steps ===== */
.step-card {
	border: 1px solid #e9ecef;
	border-radius: 12px;
	position: relative;
	overflow: visible;
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.step-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 8px 24px rgba(0, 0, 0, 0.06);
}

.step-number-badge {
	position: absolute;
	top: -12px;
	left: 50%;
	transform: translateX(-50%);
	width: 28px;
	height: 28px;
	color: white;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
	font-weight: 700;
}

.step-icon {
	width: 56px;
	height: 56px;
	margin: 10px auto 0;
	background: rgba(13, 110, 253, 0.1);
	color: #0d6efd;
	border-radius: 14px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 22px;
}

@media (max-width: 991px) {
	.hero-title { font-size: 28px; }
}
</style>
