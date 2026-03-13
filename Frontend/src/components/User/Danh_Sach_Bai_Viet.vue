<template>
	<div class="articles-page">
		<!-- Hero Section -->
		<section class="articles-hero">
			<div class="container position-relative" style="z-index:1;">
				<div class="row align-items-center">
					<div class="col-lg-7">
						<div class="d-flex align-items-center gap-2 mb-3">
							<span class="badge bg-white bg-opacity-25 text-white px-3 py-2 rounded-pill">
								<i class="fa-solid fa-newspaper me-1"></i> {{ $t('articleList.badge') }}
							</span>
						</div>
						<h1 class="hero-title text-white mb-3">{{ $t('articleList.heroTitle1') }} <br><span class="text-warning">{{ $t('articleList.heroTitle2') }}</span></h1>
						<p class="hero-description text-white-50 mb-0">
							{{ $t('articleList.heroDesc') }}
						</p>
					</div>
					<div class="col-lg-5 d-none d-lg-block text-center">
						<div class="hero-visual">
							<div class="hero-icon-circle">
								<i class="fa-solid fa-feather-pointed"></i>
							</div>
							<div class="hero-float-badge badge-a1">
								<i class="fa-solid fa-fire-flame-curved text-danger me-2"></i>
								<span>{{ $t('articleList.newArticlesCount') }}</span>
							</div>
							<div class="hero-float-badge badge-a2">
								<i class="fa-solid fa-eye text-primary me-2"></i>
								<span>{{ $t('articleList.totalReads') }}</span>
							</div>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- Featured Article (full-width) -->
		<section class="py-4 bg-light">
			<div class="container">
				<div class="card border-0 shadow-sm overflow-hidden featured-article-card" v-if="featuredArticle">
					<div class="row g-0">
						<div class="col-lg-6">
							<div class="featured-article-img h-100" 
								:style="{ backgroundImage: `url(${featuredArticle.coverImage})`, backgroundSize: 'cover', backgroundPosition: 'center' }">
								<div class="featured-overlay">
									<span class="badge bg-warning text-dark px-3 py-2 rounded-pill shadow-sm">
										<i class="fa-solid fa-star me-1"></i> {{ $t('articleList.featuredBadge') }}
									</span>
								</div>
							</div>
						</div>
						<div class="col-lg-6 d-flex flex-column">
							<div class="card-body p-4 p-lg-5 d-flex flex-column">
								<div class="d-flex align-items-center gap-3 mb-3">
									<span class="badge rounded-pill" :class="getCategoryBadgeClass(featuredArticle.category)">
										<i :class="getCategoryIcon(featuredArticle.category)" class="me-1"></i>
										{{ getCategoryLabel(featuredArticle.category) }}
									</span>
									<span class="text-muted small">
										<i class="fa-regular fa-clock me-1"></i>{{ featuredArticle.date }}
									</span>
								</div>
								<h3 class="fw-bold mb-3">
									<router-link :to="`/bai-viet/${featuredArticle.id}`" class="text-dark text-decoration-none featured-link">
										{{ featuredArticle.title }}
									</router-link>
								</h3>
								<p class="text-muted flex-grow-1 mb-4">{{ featuredArticle.summary }}</p>
								<div class="d-flex align-items-center justify-content-between mt-auto">
									<div class="d-flex align-items-center gap-2">
										<div class="author-avatar" :style="{ background: featuredArticle.authorColor }">
											{{ featuredArticle.authorName.charAt(0) }}
										</div>
										<div>
											<p class="mb-0 small fw-bold">{{ featuredArticle.authorName }}</p>
											<p class="mb-0 text-muted" style="font-size: 12px;">{{ featuredArticle.authorRole }}</p>
										</div>
									</div>
									<div class="d-flex align-items-center gap-3 text-muted small">
										<span><i class="fa-regular fa-eye me-1"></i>{{ featuredArticle.views }}</span>
										<span><i class="fa-regular fa-heart me-1"></i>{{ featuredArticle.likes }}</span>
										<span><i class="fa-regular fa-comment me-1"></i>{{ featuredArticle.comments }}</span>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- Main Content: Filters + Articles Grid -->
		<section class="py-5 bg-light">
			<div class="container">
				<!-- Category Chips -->
				<div class="d-flex flex-wrap align-items-center gap-2 mb-4">
					<button class="btn btn-sm rounded-pill px-3"
						:class="selectedCategory === '' ? 'btn-primary' : 'btn-outline-secondary'"
						@click="selectedCategory = ''">
						<i class="fa-solid fa-border-all me-1"></i> {{ $t('common.all') }}
					</button>
					<button class="btn btn-sm rounded-pill px-3"
						v-for="cat in categories" :key="cat.value"
						:class="selectedCategory === cat.value ? 'btn-primary' : 'btn-outline-secondary'"
						@click="selectedCategory = cat.value">
						<i :class="cat.icon" class="me-1"></i> {{ cat.label }}
						<span class="badge bg-white bg-opacity-25 ms-1 rounded-pill small">{{ getCategoryCount(cat.value) }}</span>
					</button>
				</div>

				<!-- Search + Sort Bar -->
				<div class="card border-0 shadow-sm mb-4">
					<div class="card-body p-3">
						<div class="row g-3 align-items-center">
							<div class="col-lg-5">
								<div class="input-group">
									<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
									<input type="text" class="form-control bg-light border-start-0 ps-0" 
										:placeholder="$t('articleList.searchPlaceholder')" v-model="searchQuery">
									<button class="btn btn-light border-start-0" v-if="searchQuery" @click="searchQuery = ''">
										<i class="fa-solid fa-xmark text-muted small"></i>
									</button>
								</div>
							</div>
							<div class="col-lg-7 d-flex flex-wrap align-items-center justify-content-between gap-2">
								<div class="text-muted small">
									{{ $t('common.showing') }} <strong>{{ filteredArticles.length }}</strong> {{ $t('articleList.articlesCountText') }}
								</div>
								<div class="d-flex align-items-center gap-2">
									<span class="text-muted small fw-medium text-nowrap">{{ $t('common.sortBy') }}</span>
									<select class="form-select form-select-sm bg-light border-0" style="width: 150px;" v-model="sortBy">
										<option value="newest">{{ $t('sort.newest') }}</option>
										<option value="popular">{{ $t('sort.popular') }}</option>
										<option value="most-liked">{{ $t('sort.mostLiked') }}</option>
									</select>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Articles Grid -->
				<div class="row g-4">
					<div class="col-lg-4 col-md-6" v-for="article in paginatedArticles" :key="article.id">
						<div class="card h-100 border-0 shadow-sm article-card">
							<!-- Cover Image -->
							<div class="article-cover position-relative" 
								:style="{ backgroundImage: `url(${article.coverImage})`, backgroundSize: 'cover', backgroundPosition: 'center' }">
								<div class="article-cover-overlay"></div>
								<div class="position-absolute top-0 start-0 m-3">
									<span class="badge rounded-pill shadow-sm" :class="getCategoryBadgeClass(article.category)">
										<i :class="getCategoryIcon(article.category)" class="me-1"></i>
										{{ getCategoryLabel(article.category) }}
									</span>
								</div>
								<div class="position-absolute bottom-0 end-0 m-3">
									<span class="badge bg-dark bg-opacity-75 text-white rounded-pill px-2">
										<i class="fa-regular fa-clock me-1"></i>{{ article.readTime }} {{ $t('articleList.readTimeLabel') }}
									</span>
								</div>
							</div>

							<!-- Body -->
							<div class="card-body p-4 d-flex flex-column">
								<div class="d-flex align-items-center gap-2 mb-3">
									<div class="author-avatar-sm" :style="{ background: article.authorColor }">
										{{ article.authorName.charAt(0) }}
									</div>
									<span class="small text-muted">{{ article.authorName }}</span>
									<span class="text-muted small ms-auto">{{ article.date }}</span>
								</div>
								<h5 class="fw-bold mb-2 article-title">
									<router-link :to="`/bai-viet/${article.id}`" class="text-dark text-decoration-none stretched-link">
										{{ article.title }}
									</router-link>
								</h5>
								<p class="text-muted small mb-3 article-summary flex-grow-1">{{ article.summary }}</p>
								
								<!-- Tags -->
								<div class="d-flex flex-wrap gap-1 mb-3">
									<span class="badge bg-light text-muted fw-normal rounded-pill px-2 py-1" 
										style="font-size: 11px;" v-for="tag in article.tags" :key="tag">
										#{{ tag }}
									</span>
								</div>

								<!-- Footer stats -->
								<div class="d-flex align-items-center justify-content-between pt-3 border-top">
									<div class="d-flex align-items-center gap-3 text-muted small">
										<span><i class="fa-regular fa-eye me-1"></i>{{ article.views }}</span>
										<span><i class="fa-regular fa-heart me-1"></i>{{ article.likes }}</span>
										<span><i class="fa-regular fa-comment me-1"></i>{{ article.comments }}</span>
									</div>
									<router-link :to="`/bai-viet/${article.id}`" class="btn btn-sm btn-outline-primary rounded-pill px-3 position-relative" style="z-index: 2;">
										{{ $t('articleList.readMore') }} <i class="fa-solid fa-arrow-right ms-1"></i>
									</router-link>
								</div>
							</div>
						</div>
					</div>

					<!-- Empty State -->
					<div class="col-12" v-if="filteredArticles.length === 0">
						<div class="card border-0 shadow-sm text-center py-5">
							<div class="card-body">
								<i class="fa-solid fa-file-circle-question fs-1 text-muted opacity-25 mb-3"></i>
								<h5 class="fw-bold">{{ $t('articleList.emptyTitle') }}</h5>
								<p class="text-muted mb-3">{{ $t('articleList.emptyDesc') }}</p>
								<button class="btn btn-outline-primary" @click="resetFilters">
									<i class="fa-solid fa-rotate-left me-1"></i> {{ $t('articleList.resetFilters') }}
								</button>
							</div>
						</div>
					</div>
				</div>

				<!-- Pagination -->
				<nav class="mt-5" v-if="totalPages > 1">
					<ul class="pagination justify-content-center">
						<li class="page-item" :class="{ disabled: currentPage === 1 }">
							<a class="page-link border-0 shadow-sm rounded-start-pill px-3" href="#" @click.prevent="currentPage--">
								<i class="fa-solid fa-chevron-left me-1"></i> {{ $t('pagination.prev') }}
							</a>
						</li>
						<li class="page-item" :class="{ active: page === currentPage }" v-for="page in visiblePages" :key="page">
							<a class="page-link border-0 shadow-sm" href="#" @click.prevent="currentPage = page">{{ page }}</a>
						</li>
						<li class="page-item" :class="{ disabled: currentPage === totalPages }">
							<a class="page-link border-0 shadow-sm rounded-end-pill px-3" href="#" @click.prevent="currentPage++">
								{{ $t('pagination.next') }} <i class="fa-solid fa-chevron-right ms-1"></i>
							</a>
						</li>
					</ul>
				</nav>
			</div>
		</section>

		<!-- Newsletter CTA -->
		<section class="py-5">
			<div class="container">
				<div class="card border-0 shadow-sm newsletter-card overflow-hidden">
					<div class="card-body p-5 text-center text-white position-relative" style="z-index: 1;">
						<div class="mb-3">
							<div class="newsletter-icon mx-auto">
								<i class="fa-solid fa-envelope-open-text"></i>
							</div>
						</div>
						<h4 class="fw-bold mb-2">{{ $t('articleList.newsletterTitle') }}</h4>
						<p class="mb-4 text-white-50 mx-auto" style="max-width: 500px;">
							{{ $t('articleList.newsletterDesc') }}
						</p>
						<div class="row justify-content-center">
							<div class="col-lg-5 col-md-8">
								<div class="input-group input-group-lg shadow">
									<input type="email" class="form-control border-0" :placeholder="$t('articleList.emailPlaceholder')">
									<button class="btn btn-warning fw-bold px-4">
										<i class="fa-solid fa-paper-plane me-1"></i> {{ $t('articleList.subscribeBtn') }}
									</button>
								</div>
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
	name: 'DanhSachBaiViet',
	data() {
		return {
			searchQuery: '',
			selectedCategory: '',
			sortBy: 'newest',
			currentPage: 1,
			perPage: 6,
			categories: [
				{ value: 'news', icon: 'fa-solid fa-bullhorn' },
				{ value: 'story', icon: 'fa-solid fa-heart' },
				{ value: 'guide', icon: 'fa-solid fa-circle-info' },
				{ value: 'event', icon: 'fa-solid fa-calendar-check' },
				{ value: 'result', icon: 'fa-solid fa-chart-line' }
			].map(c => ({...c, label: this.$t(`articleCategories.${c.value}`) || c.value})),
			featuredArticle: {
				id: 1,
				title: 'Chiến dịch "Mùa hè xanh" 2026 chính thức khởi động tại 28 tỉnh thành',
				summary: 'Hàng nghìn sinh viên trên toàn quốc đã sẵn sàng lên đường tham gia chiến dịch tình nguyện mùa hè lớn nhất trong năm. Năm nay, chiến dịch mở rộng lên 28 tỉnh thành với nhiều hoạt động ý nghĩa như xây cầu, dạy học và khám bệnh miễn phí.',
				category: 'news',
				date: '05/03/2026',
				views: '2.4K',
				likes: 342,
				comments: 56,
				readTime: 8,
				coverImage: 'https://images.unsplash.com/photo-1529390079861-591de354faf5?w=800&q=80',
				authorName: 'Ban Biên Tập',
				authorRole: 'VMS-AI',
				authorColor: '#0d6efd',
				tags: ['mùa_hè_xanh', 'tình_nguyện', 'sinh_viên']
			},
			articles: [
				{
					id: 2,
					title: 'Câu chuyện TNV: Từ sinh viên nhút nhát đến điều phối viên tự tin',
					summary: 'Hành trình đầy cảm hứng của bạn Minh Anh — từ một tình nguyện viên mới chưa dám phát biểu trước đông người, trở thành người điều phối thành công nhiều chiến dịch lớn.',
					category: 'story',
					date: '03/03/2026',
					views: '1.8K',
					likes: 245,
					comments: 32,
					readTime: 6,
					coverImage: 'https://images.unsplash.com/photo-1531545514256-b1400bc00f31?w=600&q=80',
					authorName: 'Minh Anh',
					authorRole: 'Điều phối viên',
					authorColor: '#dc3545',
					tags: ['câu_chuyện', 'cảm_hứng', 'điều_phối']
				},
				{
					id: 3,
					title: 'Kết quả chiến dịch "Trồng rừng phía Bắc" vượt mong đợi',
					summary: 'Hơn 5.000 cây xanh đã được trồng thành công tại các tỉnh miền núi phía Bắc. Chiến dịch thu hút 320 tình nguyện viên từ 15 tỉnh thành.',
					category: 'result',
					date: '28/02/2026',
					views: '956',
					likes: 189,
					comments: 24,
					readTime: 5,
					coverImage: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=600&q=80',
					authorName: 'Quỹ Xanh VN',
					authorRole: 'Tổ chức',
					authorColor: '#198754',
					tags: ['trồng_rừng', 'môi_trường', 'kết_quả']
				},
				{
					id: 4,
					title: 'Hướng dẫn đăng ký tham gia chiến dịch cho TNV mới',
					summary: 'Bài viết hướng dẫn chi tiết từng bước cách tạo tài khoản, khai báo kỹ năng, thiết lập hồ sơ năng lực và đăng ký tham gia chiến dịch đầu tiên.',
					category: 'guide',
					date: '25/02/2026',
					views: '2.1K',
					likes: 156,
					comments: 67,
					readTime: 4,
					coverImage: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=600&q=80',
					authorName: 'Ban Biên Tập',
					authorRole: 'VMS-AI',
					authorColor: '#0d6efd',
					tags: ['hướng_dẫn', 'TNV_mới', 'đăng_ký']
				},
				{
					id: 5,
					title: 'Sự kiện giao lưu tình nguyện viên Đà Nẵng 2026',
					summary: 'Buổi giao lưu, kết nối giữa các tình nguyện viên và điều phối viên tại Đà Nẵng sẽ diễn ra vào ngày 15/04/2026 với nhiều hoạt động thú vị.',
					category: 'event',
					date: '22/02/2026',
					views: '723',
					likes: 98,
					comments: 15,
					readTime: 3,
					coverImage: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=600&q=80',
					authorName: 'Nguyễn Hoàng',
					authorRole: 'Điều phối viên',
					authorColor: '#fd7e14',
					tags: ['sự_kiện', 'giao_lưu', 'đà_nẵng']
				},
				{
					id: 6,
					title: '10 kỹ năng cần thiết cho tình nguyện viên hiệu quả',
					summary: 'Những kỹ năng mềm và cứng giúp bạn trở thành tình nguyện viên được đánh giá cao, từ giao tiếp, làm việc nhóm đến quản lý thời gian.',
					category: 'guide',
					date: '20/02/2026',
					views: '1.5K',
					likes: 210,
					comments: 42,
					readTime: 7,
					coverImage: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=600&q=80',
					authorName: 'Trần Thanh',
					authorRole: 'Tình nguyện viên',
					authorColor: '#6f42c1',
					tags: ['kỹ_năng', 'phát_triển', 'kinh_nghiệm']
				},
				{
					id: 7,
					title: 'Đà Nẵng: 200 suất cơm miễn phí phát cho bệnh nhân nghèo',
					summary: 'Nhóm tình nguyện "Bữa cơm yêu thương" đã phát 200 suất cơm cho bệnh nhân nghèo tại bệnh viện Đà Nẵng trong ngày 14/02.',
					category: 'news',
					date: '15/02/2026',
					views: '645',
					likes: 134,
					comments: 18,
					readTime: 4,
					coverImage: 'https://images.unsplash.com/photo-1593113565696-7bbef1caff91?w=600&q=80',
					authorName: 'Lê Thảo',
					authorRole: 'Tình nguyện viên',
					authorColor: '#e83e8c',
					tags: ['cơm_miễn_phí', 'đà_nẵng', 'bệnh_viện']
				},
				{
					id: 8,
					title: 'Chia sẻ kinh nghiệm tổ chức chiến dịch thiện nguyện quy mô lớn',
					summary: 'Bài viết chia sẻ những bí quyết và kinh nghiệm thực tế từ người điều phối viên đã tổ chức thành công hơn 20 chiến dịch.',
					category: 'story',
					date: '10/02/2026',
					views: '890',
					likes: 167,
					comments: 29,
					readTime: 9,
					coverImage: 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=600&q=80',
					authorName: 'Phạm Đức',
					authorRole: 'Điều phối viên',
					authorColor: '#20c997',
					tags: ['kinh_nghiệm', 'tổ_chức', 'điều_phối']
				},
				{
					id: 9,
					title: 'Kết quả chiến dịch "Ánh sáng cho em" — Hơn 500 kính được trao',
					summary: 'Chiến dịch khám mắt miễn phí và tặng kính cho học sinh vùng cao đã trao tặng hơn 500 chiếc kính tại 8 trường tiểu học.',
					category: 'result',
					date: '08/02/2026',
					views: '1.1K',
					likes: 198,
					comments: 35,
					readTime: 5,
					coverImage: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=600&q=80',
					authorName: 'Quỹ Bảo Trợ',
					authorRole: 'Tổ chức',
					authorColor: '#0dcaf0',
					tags: ['ánh_sáng_cho_em', 'giáo_dục', 'kết_quả']
				}
			]
		}
	},
	computed: {
		filteredArticles() {
			return this.articles.filter(a => {
				if (this.searchQuery && !a.title.toLowerCase().includes(this.searchQuery.toLowerCase()) 
					&& !a.summary.toLowerCase().includes(this.searchQuery.toLowerCase())) return false;
				if (this.selectedCategory && a.category !== this.selectedCategory) return false;
				return true;
			});
		},
		sortedArticles() {
			let arr = [...this.filteredArticles];
			if (this.sortBy === 'popular') {
				arr.sort((a, b) => this.parseViews(b.views) - this.parseViews(a.views));
			} else if (this.sortBy === 'most-liked') {
				arr.sort((a, b) => b.likes - a.likes);
			} else {
				arr.sort((a, b) => b.id - a.id);
			}
			return arr;
		},
		totalPages() {
			return Math.ceil(this.sortedArticles.length / this.perPage);
		},
		paginatedArticles() {
			const start = (this.currentPage - 1) * this.perPage;
			return this.sortedArticles.slice(start, start + this.perPage);
		},
		visiblePages() {
			const pages = [];
			for (let i = 1; i <= this.totalPages; i++) {
				pages.push(i);
			}
			return pages;
		}
	},
	watch: {
		searchQuery() { this.currentPage = 1; },
		selectedCategory() { this.currentPage = 1; },
		sortBy() { this.currentPage = 1; }
	},
	methods: {
		parseViews(v) {
			if (typeof v === 'string') {
				if (v.includes('K')) return parseFloat(v) * 1000;
				return parseInt(v.replace(/,/g, ''));
			}
			return v;
		},
		getCategoryCount(cat) {
			return this.articles.filter(a => a.category === cat).length;
		},
		getCategoryLabel(cat) {
			return this.$t(`articleCategories.${cat}`) || cat;
		},
		getCategoryIcon(cat) {
			return { news: 'fa-solid fa-bullhorn', story: 'fa-solid fa-heart', guide: 'fa-solid fa-circle-info', event: 'fa-solid fa-calendar-check', result: 'fa-solid fa-chart-line' }[cat] || 'fa-solid fa-tag';
		},
		getCategoryBadgeClass(cat) {
			return { news: 'bg-primary text-white', story: 'bg-danger text-white', guide: 'bg-info text-dark', event: 'bg-warning text-dark', result: 'bg-success text-white' }[cat] || 'bg-secondary';
		},
		resetFilters() {
			this.searchQuery = '';
			this.selectedCategory = '';
			this.sortBy = 'newest';
			this.currentPage = 1;
		}
	}
}
</script>

<style scoped>
/* ===== Hero ===== */
.articles-hero {
	padding: 50px 0;
	background: linear-gradient(135deg, #86bfd7 0%, #addaea 50%, #5c91a8 100%);
	position: relative;
	overflow: hidden;
	border-radius: 12px;
}

.articles-hero::before {
	content: '';
	position: absolute;
	top: -150px;
	right: -100px;
	width: 500px;
	height: 500px;
	border-radius: 50%;
	background: rgba(13, 110, 253, 0.08);
}

.articles-hero::after {
	content: '';
	position: absolute;
	bottom: -100px;
	left: -80px;
	width: 350px;
	height: 350px;
	border-radius: 50%;
	background: rgba(255, 193, 7, 0.06);
}

.hero-title {
	font-size: 36px;
	font-weight: 800;
	line-height: 1.3;
	text-shadow: 0 2px 4px rgba(0,0,0,0.15);
}

.hero-description {
	font-size: 15px;
	line-height: 1.7;
	max-width: 500px;
}

/* Hero Visual */
.hero-visual {
	position: relative;
	width: 280px;
	height: 280px;
	margin: 0 auto;
}

.hero-icon-circle {
	position: absolute;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -50%);
	width: 110px;
	height: 110px;
	background: #0d6efd;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 44px;
	color: white;
	box-shadow: 0 10px 40px rgba(13, 110, 253, 0.4);
}

.hero-float-badge {
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

.badge-a1 { top: 20px; right: 0; animation-delay: 0s; }
.badge-a2 { bottom: 30px; left: -10px; animation-delay: 2s; }

@keyframes floatBadge {
	0%, 100% { transform: translateY(0); }
	50% { transform: translateY(-8px); }
}

/* ===== Featured Article ===== */
.featured-article-card {
	border-radius: 16px;
	transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.featured-article-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 12px 40px rgba(0, 0, 0, 0.1) !important;
}

.featured-article-img {
	min-height: 320px;
	border-radius: 16px 0 0 16px;
	position: relative;
}

.featured-overlay {
	position: absolute;
	top: 24px;
	left: 24px;
}

.featured-link:hover {
	color: #0d6efd !important;
}

.author-avatar {
	width: 40px;
	height: 40px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 16px;
	flex-shrink: 0;
}

.author-avatar-sm {
	width: 28px;
	height: 28px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 12px;
	flex-shrink: 0;
}

/* ===== Article Cards ===== */
.article-card {
	border-radius: 16px;
	overflow: hidden;
	transition: all 0.3s ease;
}

.article-card:hover {
	transform: translateY(-6px);
	box-shadow: 0 12px 30px rgba(0, 0, 0, 0.1) !important;
}

.article-card:hover .article-title a {
	color: #0d6efd !important;
}

.article-cover {
	height: 200px;
	position: relative;
	overflow: hidden;
}

.article-cover-overlay {
	position: absolute;
	inset: 0;
	background: linear-gradient(to bottom, transparent 60%, rgba(0,0,0,0.15));
}

.article-title {
	display: -webkit-box;
	-webkit-line-clamp: 2;
	line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
	min-height: 48px;
}

.article-summary {
	display: -webkit-box;
	-webkit-line-clamp: 3;
	line-clamp: 3;
	-webkit-box-orient: vertical;
	overflow: hidden;
}

/* ===== Newsletter CTA ===== */
.newsletter-card {
	border-radius: 16px;
	background: linear-gradient(135deg, #86bfd7 0%, #5c91a8 50%, #3a7ca5 100%);
	position: relative;
	overflow: hidden;
}

.newsletter-card::before {
	content: '';
	position: absolute;
	top: -100px;
	right: -50px;
	width: 300px;
	height: 300px;
	border-radius: 50%;
	background: rgba(255, 255, 255, 0.06);
}

.newsletter-card::after {
	content: '';
	position: absolute;
	bottom: -80px;
	left: -40px;
	width: 250px;
	height: 250px;
	border-radius: 50%;
	background: rgba(255, 193, 7, 0.06);
}

.newsletter-icon {
	width: 64px;
	height: 64px;
	background: rgba(255, 255, 255, 0.15);
	border-radius: 16px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 28px;
}

/* ===== Responsive ===== */
@media (max-width: 991px) {
	.hero-title { font-size: 26px; }
	.featured-article-img {
		min-height: 220px;
		border-radius: 16px 16px 0 0;
	}
}

@media (max-width: 767px) {
	.articles-hero { padding: 30px 0; }
	.hero-title { font-size: 22px; }
}
</style>
