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
								<h3 class="mb-0 text-warning fw-bold">2,500+</h3>
								<small class="text-white">{{ $t('home.counterVolunteers') }}</small>
							</div>
							<div class="col-auto border-start border-light border-opacity-50">
								<h3 class="mb-0 text-white fw-bold">150+</h3>
								<small class="text-white">{{ $t('home.counterCampaigns') }}</small>
							</div>
							<div class="col-auto border-start border-light border-opacity-50">
								<h3 class="mb-0 text-white fw-bold">50+</h3>
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
					<a href="#" class="btn btn-outline-primary btn-sm">{{ $t('common.viewAll') }} <i class="fa-solid fa-arrow-right ms-1"></i></a>
				</div>
				<div class="row g-4">
					<div class="col-lg-4 col-md-6" v-for="(campaign, index) in campaigns" :key="index">
						<div class="card h-100 campaign-card">
							<div class="card-img-top campaign-banner" :style="{ backgroundImage: campaign.image ? `url(${campaign.image})` : campaign.color, backgroundSize: 'cover', backgroundPosition: 'center' }">
								<span class="badge bg-light text-dark">{{ campaign.tag }}</span>
								<div class="campaign-banner-icon">
									<i :class="campaign.icon"></i>
								</div>
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
											:style="{ width: (campaign.registered / campaign.total * 100) + '%' }"
											:class="campaign.progressClass"></div>
									</div>
								</div>
							</div>
							<div class="card-footer bg-transparent border-top">
								<div class="d-flex gap-2">
									<router-link to="/dang-ky" class="btn btn-primary btn-sm flex-fill d-flex align-items-center justify-content-center">
										{{ $t('common.apply') }}
									</router-link>
									<router-link to="#" class="btn btn-outline-secondary btn-sm flex-fill d-flex align-items-center justify-content-center">
										{{ $t('common.viewDetails') }}
									</router-link>
								</div>
							</div>
						</div>
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
					<a href="#" class="btn btn-outline-success btn-sm">{{ $t('common.viewAll') }} <i class="fa-solid fa-arrow-right ms-1"></i></a>
				</div>
				<div class="row g-4">
					<div class="col-lg-4 col-md-6" v-for="(campaign, index) in completedCampaigns" :key="index">
						<div class="card h-100 campaign-card opacity-75">
							<div class="card-img-top campaign-banner" :style="{ backgroundImage: campaign.image ? `url(${campaign.image})` : campaign.color, backgroundSize: 'cover', backgroundPosition: 'center', filter: 'grayscale(30%)' }">
								<span class="badge bg-success text-white">{{ $t('common.completed') }}</span>
								<div class="campaign-banner-icon">
									<i :class="campaign.icon"></i>
								</div>
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
									<router-link to="#" class="btn btn-outline-secondary btn-sm flex-fill d-flex align-items-center justify-content-center">
										{{ $t('common.viewDetails') }}
									</router-link>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- Bài viết mới nhất -->
		<section class="py-5">
			<div class="container">
				<div class="d-flex align-items-center justify-content-between mb-4">
					<div>
						<h4 class="fw-bold mb-1"><i class="fa-solid fa-newspaper text-primary me-2"></i>{{ $t('home.latestArticles') }}</h4>
						<p class="text-muted mb-0">{{ $t('home.latestArticlesDesc') }}</p>
					</div>
					<router-link to="/bai-viet" class="btn btn-outline-primary btn-sm">{{ $t('common.viewAll') }} <i class="fa-solid fa-arrow-right ms-1"></i></router-link>
				</div>
				<div class="row g-4">
					<div class="col-lg-6">
						<div class="card h-100 article-card article-featured">
							<div class="card-img-top article-banner bg-primary" :style="{ backgroundImage: articles[0].image ? `url(${articles[0].image})` : 'none', backgroundSize: 'cover', backgroundPosition: 'center' }">
								<div class="article-banner-overlay">
									<span class="badge bg-warning text-dark mb-2">{{ $t('common.featured') }}</span>
									<h4 class="text-white fw-bold mb-2">{{ articles[0].title }}</h4>
									<p class="text-white-50 mb-3 small">{{ articles[0].summary }}</p>
									<div class="d-flex gap-3 text-white-50 small">
										<span><i class="fa-regular fa-clock me-1"></i>{{ articles[0].date }}</span>
										<span><i class="fa-regular fa-eye me-1"></i>{{ articles[0].views }} {{ $t('common.views') }}</span>
									</div>
								</div>
							</div>
						</div>
					</div>
					<div class="col-lg-6">
						<div class="row g-4">
							<div class="col-12" v-for="(article, index) in articles.slice(1)" :key="index">
								<div class="card article-card article-small">
									<div class="card-body">
										<div class="d-flex gap-3">
											<div class="article-thumb" :style="{ background: article.color }">
												<i :class="article.icon" class="text-white"></i>
											</div>
											<div class="flex-grow-1">
												<span class="badge mb-1" :class="article.badgeClass">{{ article.tag }}</span>
												<h6 class="fw-bold mb-1">{{ article.title }}</h6>
												<p class="text-muted small mb-2">{{ article.summary }}</p>
												<div class="d-flex gap-3 text-muted small">
													<span><i class="fa-regular fa-clock me-1"></i>{{ article.date }}</span>
													<span><i class="fa-regular fa-eye me-1"></i>{{ article.views }} {{ $t('common.views') }}</span>
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
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
export default {
	name: "TrangChu",
	data() {
		return {
			completedCampaigns: [
				{
					icon: 'fa-solid fa-school',
					title: 'Sơn sửa trường Hy Vọng',
					description: 'Chiến dịch sơn lại toàn bộ trường dòng Hy Vọng tại ngoại ô thành phố, mang lại không gian học tập mới.',
					location: 'Củ Chi, TP.HCM',
					date: '10/01/2026',
					tag: 'Hoàn thành',
					color: 'linear-gradient(135deg, #6c757d, #adb5bd)',
					image: 'https://images.unsplash.com/photo-1544256718-3bcf237f3974?w=600&q=80',
					total: 120,
				},
				{
					icon: 'fa-solid fa-utensils',
					title: 'Bữa cơm nụ cười',
					description: 'Nấu và phát 500 suất ăn miễn phí cho người vô gia cư tại trung tâm thành phố trong dịp Tết.',
					location: 'Hà Nội',
					date: '28/01/2026',
					tag: 'Hoàn thành',
					color: 'linear-gradient(135deg, #6c757d, #adb5bd)',
					image: 'https://images.unsplash.com/photo-1593113565696-7bbef1caff91?w=600&q=80',
					total: 65,
				},
				{
					icon: 'fa-solid fa-water',
					title: 'Nước sạch về làng',
					description: 'Lắp đặt 3 hệ thống lọc nước sạch cho các hộ dân tại vùng bị ngập mặn ở Đồng Bằng Sông Cửu Long.',
					location: 'Bến Tre',
					date: '05/02/2026',
					tag: 'Hoàn thành',
					color: 'linear-gradient(135deg, #6c757d, #adb5bd)',
					image: 'https://images.unsplash.com/photo-1519336305162-4b6e511c504e?w=600&q=80',
					total: 40,
				}
			],
			campaigns: [
				{
					icon: 'fa-solid fa-tree',
					title: 'Trồng cây xanh TP.HCM',
					description: 'Chiến dịch trồng 1000 cây xanh tại các tuyến đường trọng điểm TP.HCM, hướng tới thành phố xanh sạch đẹp.',
					location: 'TP. Hồ Chí Minh',
					date: '15/03/2026',
					tag: 'Môi trường',
					color: 'linear-gradient(135deg, #198754, #20c997)',
					image: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=600&q=80',
					progressClass: 'bg-success',
					registered: 45,
					total: 80,
				},
				{
					icon: 'fa-solid fa-book-open',
					title: 'Dạy học cho trẻ em vùng cao',
					description: 'Chương trình dạy tiếng Anh và kỹ năng sống cho trẻ em tại Sapa, Lào Cai trong 2 tuần.',
					location: 'Lào Cai',
					date: '20/03/2026',
					tag: 'Giáo dục',
					color: 'linear-gradient(135deg, #0d6efd, #6610f2)',
					image: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=600&q=80',
					progressClass: 'bg-primary',
					registered: 28,
					total: 40,
				},
				{
					icon: 'fa-solid fa-hand-holding-medical',
					title: 'Khám bệnh miễn phí',
					description: 'Đoàn y bác sĩ khám và phát thuốc miễn phí cho bà con nghèo tại các xã vùng sâu.',
					location: 'Đồng Nai',
					date: '25/03/2026',
					tag: 'Y tế',
					color: 'linear-gradient(135deg, #dc3545, #e35d6a)',
					image: 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=600&q=80',
					progressClass: 'bg-danger',
					registered: 15,
					total: 30,
				}
			],
			articles: [
				{
					title: 'Chiến dịch "Mùa hè xanh" 2026 chính thức khởi động',
					summary: 'Hàng nghìn sinh viên trên toàn quốc đã sẵn sàng tham gia chiến dịch tình nguyện lớn nhất trong năm.',
					date: '05/03/2026',
					views: '1.2K',
					icon: 'fa-solid fa-sun',
					color: '#0d6efd',
					image: 'https://images.unsplash.com/photo-1529390079861-591de354faf5?w=800&q=80',
					tag: this.$t('common.featured'),
					badgeClass: 'bg-primary'
				},
				{
					title: 'Câu chuyện TNV: Từ sinh viên đến kiểm duyệt viên',
					summary: 'Hành trình đầy cảm hứng của bạn Minh Anh từ một tình nguyện viên mới đến người điều phối.',
					date: '02/03/2026',
					views: '890',
					icon: 'fa-solid fa-heart',
					color: '#dc3545',
					tag: 'Câu chuyện',
					badgeClass: 'bg-danger'
				},
				{
					title: 'Kết quả chiến dịch "Trồng rừng phía Bắc" vượt mong đợi',
					summary: 'Hơn 5.000 cây xanh đã được trồng thành công tại các tỉnh miền núi phía Bắc.',
					date: '28/02/2026',
					views: '654',
					icon: 'fa-solid fa-tree',
					color: '#198754',
					tag: 'Kết quả',
					badgeClass: 'bg-success'
				},
				{
					title: 'Hướng dẫn đăng ký tham gia chiến dịch cho TNV mới',
					summary: 'Bài viết hướng dẫn chi tiết cách tạo tài khoản, khai báo kỹ năng và đăng ký chiến dịch.',
					date: '25/02/2026',
					views: '432',
					icon: 'fa-solid fa-circle-info',
					color: '#0dcaf0',
					tag: 'Hướng dẫn',
					badgeClass: 'bg-info'
				}
			]
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
		}
	}
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

/* ===== Articles ===== */
.article-card {
	border: 1px solid #e9ecef;
	border-radius: 12px;
	overflow: hidden;
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.article-card:hover {
	transform: translateY(-3px);
	box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}

.article-featured .article-banner {
	height: 100%;
	min-height: 380px;
	display: flex;
	align-items: flex-end;
	border-radius: 12px;
}

.article-banner-overlay {
	padding: 30px;
	width: 100%;
	background: linear-gradient(to top, rgba(0,0,0,0.7), transparent);
	border-radius: 0 0 12px 12px;
}

.article-thumb {
	width: 60px;
	height: 60px;
	min-width: 60px;
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 22px;
}

.article-small { cursor: pointer; }

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
	.article-featured .article-banner { min-height: 260px; }
}
</style>
