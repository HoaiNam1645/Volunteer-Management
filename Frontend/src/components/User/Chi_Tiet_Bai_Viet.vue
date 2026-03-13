<template>
	<div class="article-detail-page">
		<!-- Breadcrumb -->
		<section class="bg-light py-3 border-bottom">
			<div class="container">
				<nav aria-label="breadcrumb">
					<ol class="breadcrumb mb-0 small">
						<li class="breadcrumb-item">
							<router-link to="/" class="text-decoration-none"><i class="fa-solid fa-home me-1"></i>{{ $t('common.home') }}</router-link>
						</li>
						<li class="breadcrumb-item">
							<router-link to="/bai-viet" class="text-decoration-none">{{ $t('articleList.badge') }}</router-link>
						</li>
						<li class="breadcrumb-item active" aria-current="page">{{ article.title }}</li>
					</ol>
				</nav>
			</div>
		</section>

		<!-- Hero Cover -->
		<section class="article-hero-cover" :style="{ backgroundImage: `url(${article.coverImage})` }">
			<div class="article-hero-overlay"></div>
			<div class="container position-relative" style="z-index: 2;">
				<div class="row justify-content-center">
					<div class="col-lg-8 text-center text-white">
						<div class="d-flex align-items-center justify-content-center gap-2 mb-3">
							<span class="badge rounded-pill px-3 py-2" :class="getCategoryBadgeClass(article.category)">
								<i :class="getCategoryIcon(article.category)" class="me-1"></i>
								{{ getCategoryLabel(article.category) }}
							</span>
							<span class="badge bg-dark bg-opacity-50 rounded-pill px-3 py-2">
								<i class="fa-regular fa-clock me-1"></i> {{ article.readTime }} {{ $t('articleList.readTimeLabel') }}
							</span>
						</div>
						<h1 class="fw-bold mb-4 article-cover-title">{{ article.title }}</h1>
						<div class="d-flex align-items-center justify-content-center gap-4 flex-wrap">
							<div class="d-flex align-items-center gap-2">
								<div class="cover-author-avatar" :style="{ background: article.authorColor }">
									{{ article.authorName.charAt(0) }}
								</div>
								<div class="text-start">
									<p class="mb-0 small fw-bold">{{ article.authorName }}</p>
									<p class="mb-0 text-white-50" style="font-size: 12px;">{{ article.authorRole }}</p>
								</div>
							</div>
							<span class="text-white-50 small"><i class="fa-regular fa-calendar me-1"></i>{{ article.date }}</span>
							<span class="text-white-50 small"><i class="fa-regular fa-eye me-1"></i>{{ article.views }} {{ $t('articleDetail.viewsLabel') }}</span>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- Main Content -->
		<section class="py-5">
			<div class="container">
				<div class="row g-5">
					<!-- LEFT: Article Content -->
					<div class="col-lg-8">
						<article class="article-content-wrapper d-flex gap-4">
							<!-- Share bar (floating on desktop) -->
							<div class="share-sidebar-wrapper d-none d-xl-block flex-shrink-0" style="width: 44px;">
								<div class="share-sidebar position-sticky d-flex flex-column align-items-center gap-2" style="top: 120px; z-index: 1;">
									<button class="share-btn" :title="$t('articleDetail.likeBtn')"><i class="fa-regular fa-heart"></i><span>{{ article.likes }}</span></button>
									<button class="share-btn" :title="$t('articleDetail.commentBtn')"><i class="fa-regular fa-comment"></i><span>{{ article.comments }}</span></button>
									<div class="share-divider"></div>
									<button class="share-btn" title="Facebook"><i class="fa-brands fa-facebook-f"></i></button>
									<button class="share-btn" title="Twitter"><i class="fa-brands fa-twitter"></i></button>
									<button class="share-btn" :title="$t('articleDetail.copyBtn')"><i class="fa-solid fa-link"></i></button>
								</div>
							</div>

							<!-- Article Body -->
							<div class="article-body flex-grow-1" style="min-width: 0;">
								<p class="lead text-muted mb-4">{{ article.summary }}</p>

								<div class="article-html-content" v-html="article.content"></div>

							</div>
						</article>

						<!-- Block: Tags, Author, Navigation (moved out of article content wrapper to be full width) -->
						<div class="post-article-footer mt-5 pt-4 border-top">
							<!-- Tags -->
							<div class="mb-4">
								<h6 class="fw-bold mb-3"><i class="fa-solid fa-tags me-2 text-primary"></i>{{ $t('articleDetail.tagsTitle') }}</h6>
								<div class="d-flex flex-wrap gap-2">
									<span class="badge bg-light text-muted fw-normal rounded-pill px-3 py-2" 
										v-for="tag in article.tags" :key="tag">
										#{{ tag }}
									</span>
								</div>
							</div>

							<!-- Mobile Share -->
							<div class="d-xl-none mb-4 pt-4 border-top">
								<h6 class="fw-bold mb-3"><i class="fa-solid fa-share-nodes me-2 text-primary"></i>{{ $t('articleDetail.shareTitle') }}</h6>
								<div class="d-flex gap-2">
									<button class="btn btn-sm btn-outline-primary rounded-pill px-3">
										<i class="fa-brands fa-facebook-f me-1"></i> Facebook
									</button>
									<button class="btn btn-sm btn-outline-info rounded-pill px-3">
										<i class="fa-brands fa-twitter me-1"></i> Twitter
									</button>
									<button class="btn btn-sm btn-outline-secondary rounded-pill px-3">
										<i class="fa-solid fa-link me-1"></i> {{ $t('articleDetail.copyBtn') }}
									</button>
								</div>
							</div>

							<!-- Author Box -->
							<div class="author-box mb-5">
								<div class="d-flex gap-3 align-items-start">
									<div class="author-box-avatar" :style="{ background: article.authorColor }">
										{{ article.authorName.charAt(0) }}
									</div>
									<div class="flex-grow-1">
										<h6 class="fw-bold mb-1">{{ article.authorName }}</h6>
										<p class="text-muted small mb-2">{{ article.authorRole }}</p>
										<p class="text-muted small mb-0">
											{{ article.authorBio || $t('articleDetail.defaultBio') }}
										</p>
									</div>
								</div>
							</div>

							<!-- Navigation (Prev/Next) -->
							<div class="row g-3">
								<div class="col-sm-6" v-if="prevArticle">
									<router-link :to="`/bai-viet/${prevArticle.id}`" class="card border-0 shadow-sm h-100 text-decoration-none nav-article-card">
										<div class="card-body p-3">
											<div class="text-muted small mb-1"><i class="fa-solid fa-arrow-left me-1"></i> {{ $t('articleDetail.prevArticle') }}</div>
											<h6 class="fw-bold mb-0 text-dark nav-article-title">{{ prevArticle.title }}</h6>
										</div>
									</router-link>
								</div>
								<div class="col-sm-6" :class="{ 'ms-auto': !prevArticle }" v-if="nextArticle">
									<router-link :to="`/bai-viet/${nextArticle.id}`" class="card border-0 shadow-sm h-100 text-decoration-none nav-article-card text-end">
										<div class="card-body p-3">
											<div class="text-muted small mb-1">{{ $t('articleDetail.nextArticle') }} <i class="fa-solid fa-arrow-right ms-1"></i></div>
											<h6 class="fw-bold mb-0 text-dark nav-article-title">{{ nextArticle.title }}</h6>
										</div>
									</router-link>
								</div>
							</div>
						</div>

						<!-- Comments Section -->
						<div class="mt-5">
							<div class="card border-0 shadow-sm">
								<div class="card-header bg-white py-3 border-bottom">
									<h5 class="fw-bold mb-0">
										<i class="fa-regular fa-comments me-2 text-primary"></i>
										{{ $t('articleDetail.commentsTitle') }} ({{ commentsList.length }})
									</h5>
								</div>
								<div class="card-body p-4">
									<!-- Comment Input -->
									<div class="d-flex gap-3 mb-4 pb-4 border-bottom">
										<div class="comment-avatar bg-primary text-white">
											<i class="fa-solid fa-user"></i>
										</div>
										<div class="flex-grow-1">
											<textarea class="form-control bg-light border-0 mb-2" rows="3" 
												:placeholder="$t('articleDetail.commentPlaceholder')" v-model="newComment"></textarea>
											<div class="d-flex justify-content-end">
												<button class="btn btn-primary btn-sm px-4 rounded-pill" 
													:disabled="!newComment.trim()" @click="addComment">
													<i class="fa-solid fa-paper-plane me-1"></i> {{ $t('articleDetail.sendComment') }}
												</button>
											</div>
										</div>
									</div>

									<!-- Comments List -->
									<div class="comment-item" v-for="comment in commentsList" :key="comment.id">
										<div class="d-flex gap-3">
											<div class="comment-avatar" :style="{ background: comment.color }">
												{{ comment.name.charAt(0) }}
											</div>
											<div class="flex-grow-1">
												<div class="d-flex align-items-center gap-2 mb-1">
													<h6 class="fw-bold mb-0 small">{{ comment.name }}</h6>
													<span class="text-muted" style="font-size: 12px;">{{ comment.time }}</span>
												</div>
												<p class="text-muted small mb-2">{{ comment.text }}</p>
												<div class="d-flex gap-3 text-muted small">
													<a href="#" class="text-decoration-none text-muted" @click.prevent>
														<i class="fa-regular fa-heart me-1"></i>{{ comment.likes }}
													</a>
													<a href="#" class="text-decoration-none text-muted" @click.prevent>
														<i class="fa-solid fa-reply me-1"></i>{{ $t('articleDetail.replyBtn') }}
													</a>
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>

					<!-- RIGHT: Sidebar -->
					<div class="col-lg-4">
						<div class="position-sticky" style="top: 20px;">
							<!-- Table of Contents -->
							<div class="card border-0 shadow-sm mb-4">
								<div class="card-header bg-white py-3 border-bottom">
									<h6 class="fw-bold mb-0"><i class="fa-solid fa-list-ul me-2 text-primary"></i>{{ $t('articleDetail.tocTitle') }}</h6>
								</div>
								<div class="card-body p-0">
									<ul class="list-unstyled toc-list mb-0">
										<li v-for="(heading, idx) in tableOfContents" :key="idx">
											<a :href="'#' + heading.id" class="toc-link d-flex align-items-center gap-2 px-3 py-2 text-decoration-none"
												:class="{ 'toc-active': activeHeading === heading.id }">
												<span class="toc-dot"></span>
												<span>{{ heading.text }}</span>
											</a>
										</li>
									</ul>
								</div>
							</div>

							<!-- Related Articles -->
							<div class="card border-0 shadow-sm mb-4">
								<div class="card-header bg-white py-3 border-bottom">
									<h6 class="fw-bold mb-0"><i class="fa-solid fa-newspaper me-2 text-primary"></i>{{ $t('articleDetail.relatedArticlesTitle') }}</h6>
								</div>
								<div class="card-body p-0">
									<router-link :to="`/bai-viet/${related.id}`" 
										class="related-item d-flex gap-3 p-3 text-decoration-none border-bottom"
										v-for="related in relatedArticles" :key="related.id">
										<div class="related-thumb" :style="{ backgroundImage: `url(${related.coverImage})` }"></div>
										<div class="flex-grow-1 d-flex flex-column">
											<span class="badge rounded-pill mb-1 align-self-start" 
												:class="getCategoryBadgeClass(related.category)" style="font-size: 10px;">
												{{ getCategoryLabel(related.category) }}
											</span>
											<h6 class="fw-bold small mb-1 text-dark related-title">{{ related.title }}</h6>
											<span class="text-muted" style="font-size: 11px;">
												<i class="fa-regular fa-clock me-1"></i>{{ related.date }}
											</span>
										</div>
									</router-link>
								</div>
							</div>

							<!-- Popular Tags -->
							<div class="card border-0 shadow-sm">
								<div class="card-header bg-white py-3 border-bottom">
									<h6 class="fw-bold mb-0"><i class="fa-solid fa-hashtag me-2 text-primary"></i>{{ $t('articleDetail.popularTagsTitle') }}</h6>
								</div>
								<div class="card-body">
									<div class="d-flex flex-wrap gap-2">
										<a href="#" class="badge bg-light text-muted fw-normal rounded-pill px-3 py-2 text-decoration-none popular-tag"
											v-for="tag in popularTags" :key="tag">
											#{{ tag }}
										</a>
									</div>
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
	name: 'ChiTietBaiViet',
	data() {
		return {
			activeHeading: '',
			newComment: '',
			article: {
				id: 1,
				title: 'Chiến dịch "Mùa hè xanh" 2026 chính thức khởi động tại 28 tỉnh thành',
				summary: 'Hàng nghìn sinh viên trên toàn quốc đã sẵn sàng lên đường tham gia chiến dịch tình nguyện mùa hè lớn nhất trong năm. Năm nay, chiến dịch mở rộng lên 28 tỉnh thành với nhiều hoạt động ý nghĩa.',
				category: 'news',
				date: '05/03/2026',
				views: '2.4K',
				likes: 342,
				comments: 56,
				readTime: 8,
				coverImage: 'https://images.unsplash.com/photo-1529390079861-591de354faf5?w=1200&q=80',
				authorName: 'Ban Biên Tập',
				authorRole: 'VMS-AI',
				authorColor: '#0d6efd',
				authorBio: 'Đội ngũ biên tập của VMS-AI — luôn mang đến những tin tức, câu chuyện truyền cảm hứng từ cộng đồng tình nguyện viên Việt Nam.',
				tags: ['mùa_hè_xanh', 'tình_nguyện', 'sinh_viên', '2026', 'cộng_đồng'],
				content: `
					<h2 id="gioi-thieu">1. Giới thiệu về chiến dịch</h2>
					<p>Chiến dịch <strong>"Mùa hè xanh" 2026</strong> là chiến dịch tình nguyện hè lớn nhất trong năm, quy tụ hàng nghìn sinh viên từ các trường đại học, cao đẳng trên toàn quốc. Năm nay, chiến dịch chính thức mở rộng quy mô lên <strong>28 tỉnh thành</strong>, tăng 5 tỉnh so với năm trước.</p>
					<p>Với sứ mệnh "Vì cộng đồng - Vì tương lai", chiến dịch tập trung vào các hoạt động thiết thực như xây dựng cơ sở hạ tầng nông thôn, dạy học cho trẻ em vùng cao, và khám chữa bệnh miễn phí cho người dân nghèo.</p>
					
					<div class="article-highlight my-4 p-4 rounded-3">
						<div class="d-flex gap-3 align-items-start">
							<div class="highlight-icon">
								<i class="fa-solid fa-quote-left"></i>
							</div>
							<div>
								<p class="mb-2 fst-italic">"Mỗi bạn trẻ là một hạt giống của sự thay đổi. Khi hàng nghìn hạt giống cùng nảy mầm, chúng ta sẽ tạo nên một mùa hè thật sự xanh."</p>
								<p class="mb-0 small fw-bold">— Nguyễn Văn A, Trưởng ban tổ chức</p>
							</div>
						</div>
					</div>

					<h2 id="quy-mo">2. Quy mô và số liệu</h2>
					<p>Năm nay, chiến dịch có quy mô lớn nhất từ trước đến nay với những con số ấn tượng:</p>
					<ul>
						<li><strong>5.200+</strong> tình nguyện viên đã đăng ký</li>
						<li><strong>28 tỉnh thành</strong> được triển khai</li>
						<li><strong>86 chiến dịch con</strong> tại các địa phương</li>
						<li><strong>120+ trường</strong> đại học/cao đẳng tham gia</li>
						<li><strong>35 tổ chức</strong> phi lợi nhuận đồng hành</li>
					</ul>

					<h2 id="hoat-dong">3. Các hoạt động chính</h2>
					<p>Chiến dịch được chia thành 4 mảng hoạt động chính:</p>
					
					<h3 id="xay-dung">3.1 Xây dựng cơ sở hạ tầng</h3>
					<p>Xây cầu, sửa đường, xây nhà cho hộ nghèo tại các xã vùng sâu vùng xa. Năm nay dự kiến hoàn thành 12 cầu bê-tông và 35 km đường nông thôn.</p>

					<h3 id="giao-duc">3.2 Giáo dục</h3>
					<p>Dạy học, phụ đạo cho trẻ em vùng khó khăn. Tổ chức các lớp dạy tiếng Anh, kỹ năng sống, và STEM cho học sinh tiểu học và THCS. Đặc biệt, năm nay có thêm chương trình "Thư viện vùng cao" — tặng sách và thiết lập thư viện mini cho 15 trường.</p>

					<h3 id="y-te">3.3 Y tế</h3>
					<p>Tổ chức khám bệnh miễn phí, phát thuốc, và tư vấn sức khỏe cho bà con. Dự kiến khám cho 10.000 lượt người dân tại 28 điểm khám.</p>

					<h3 id="moi-truong">3.4 Môi trường</h3>
					<p>Trồng cây, làm sạch bãi biển, thu gom rác thải, và nâng cao ý thức bảo vệ môi trường. Mục tiêu trồng 20.000 cây xanh trong suốt mùa hè.</p>

					<h2 id="dang-ky">4. Cách đăng ký tham gia</h2>
					<p>Để tham gia chiến dịch, bạn chỉ cần:</p>
					<ol>
						<li>Đăng ký tài khoản trên <strong>VMS-AI</strong></li>
						<li>Hoàn thiện hồ sơ năng lực (kỹ năng, kinh nghiệm)</li>
						<li>Tìm kiếm chiến dịch phù hợp tại khu vực của bạn</li>
						<li>Nhấn "Đăng ký tham gia" và chờ phê duyệt</li>
					</ol>
					<p>Hệ thống AI của VMS-AI sẽ gợi ý các chiến dịch phù hợp nhất dựa trên kỹ năng và vị trí của bạn.</p>

					<h2 id="ket-luan">5. Lời kết</h2>
					<p>Chiến dịch "Mùa hè xanh" 2026 không chỉ là dịp để các bạn trẻ cống hiến, mà còn là cơ hội trải nghiệm, rèn luyện bản thân và kết nối với cộng đồng. Hãy cùng chung tay tạo nên một mùa hè đầy ý nghĩa!</p>
					<p>Đăng ký tham gia ngay để trở thành một phần của hành trình tuyệt vời này. 💚</p>
				`
			},
			tableOfContents: [
				{ id: 'gioi-thieu', text: 'Giới thiệu về chiến dịch' },
				{ id: 'quy-mo', text: 'Quy mô và số liệu' },
				{ id: 'hoat-dong', text: 'Các hoạt động chính' },
				{ id: 'dang-ky', text: 'Cách đăng ký tham gia' },
				{ id: 'ket-luan', text: 'Lời kết' }
			],
			commentsList: [
				{
					id: 1,
					name: 'Nguyễn Minh Anh',
					text: 'Tuyệt vời quá! Năm nay mình nhất định sẽ đăng ký tham gia. Hy vọng được phân công vào mảng giáo dục ở Lào Cai.',
					time: '2 giờ trước',
					likes: 12,
					color: '#dc3545'
				},
				{
					id: 2,
					name: 'Trần Hữu Đức',
					text: 'Năm ngoái mình tham gia trồng cây ở Đà Nẵng, trải nghiệm rất tuyệt. Cảm ơn ban tổ chức đã mở rộng quy mô!',
					time: '5 giờ trước',
					likes: 8,
					color: '#198754'
				},
				{
					id: 3,
					name: 'Lê Thị Thanh Hằng',
					text: 'Mình muốn hỏi là điều kiện đăng ký có yêu cầu sinh viên không ạ? Mình đã đi làm rồi nhưng vẫn muốn tham gia.',
					time: '1 ngày trước',
					likes: 5,
					color: '#6f42c1'
				},
				{
					id: 4,
					name: 'Phạm Quốc Bảo',
					text: 'Thông tin rất hữu ích! Mình đã chia sẻ cho nhóm sinh viên của mình rồi. Cả nhóm sẽ đăng ký tham gia 🔥',
					time: '2 ngày trước',
					likes: 15,
					color: '#fd7e14'
				}
			],
			relatedArticles: [
				{
					id: 3,
					title: 'Kết quả chiến dịch "Trồng rừng phía Bắc" vượt mong đợi',
					category: 'result',
					date: '28/02/2026',
					coverImage: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=300&q=80'
				},
				{
					id: 2,
					title: 'Câu chuyện TNV: Từ sinh viên nhút nhát đến điều phối viên tự tin',
					category: 'story',
					date: '03/03/2026',
					coverImage: 'https://images.unsplash.com/photo-1531545514256-b1400bc00f31?w=300&q=80'
				},
				{
					id: 5,
					title: 'Sự kiện giao lưu tình nguyện viên Đà Nẵng 2026',
					category: 'event',
					date: '22/02/2026',
					coverImage: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=300&q=80'
				},
				{
					id: 4,
					title: 'Hướng dẫn đăng ký tham gia chiến dịch cho TNV mới',
					category: 'guide',
					date: '25/02/2026',
					coverImage: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=300&q=80'
				}
			],
			prevArticle: null,
			nextArticle: {
				id: 2,
				title: 'Câu chuyện TNV: Từ sinh viên nhút nhát đến điều phối viên tự tin'
			},
			popularTags: [
				'tình_nguyện', 'mùa_hè_xanh', 'giáo_dục', 'môi_trường',
				'cộng_đồng', 'sức_khỏe', 'trẻ_em', 'vùng_cao',
				'sinh_viên', 'điều_phối', 'đà_nẵng', 'tp_hcm'
			]
		}
	},
	methods: {
		getCategoryLabel(cat) {
			return this.$t(`articleCategories.${cat}`) || cat;
		},
		getCategoryIcon(cat) {
			return { news: 'fa-solid fa-bullhorn', story: 'fa-solid fa-heart', guide: 'fa-solid fa-circle-info', event: 'fa-solid fa-calendar-check', result: 'fa-solid fa-chart-line' }[cat] || 'fa-solid fa-tag';
		},
		getCategoryBadgeClass(cat) {
			return { news: 'bg-primary text-white', story: 'bg-danger text-white', guide: 'bg-info text-dark', event: 'bg-warning text-dark', result: 'bg-success text-white' }[cat] || 'bg-secondary';
		},
		addComment() {
			if (!this.newComment.trim()) return;
			this.commentsList.unshift({
				id: Date.now(),
				name: 'Bạn',
				text: this.newComment,
				time: this.$t('articleDetail.justNow'),
				likes: 0,
				color: '#0d6efd'
			});
			this.newComment = '';
		}
	},
	mounted() {
		// Scroll to top
		window.scrollTo(0, 0);

		// Intersection observer for Table of Contents active state
		const headings = document.querySelectorAll('.article-html-content h2, .article-html-content h3');
		if (headings.length > 0) {
			const observer = new IntersectionObserver(
				(entries) => {
					entries.forEach(entry => {
						if (entry.isIntersecting) {
							this.activeHeading = entry.target.id;
						}
					});
				},
				{ threshold: 0.5, rootMargin: '-100px 0px -60% 0px' }
			);
			headings.forEach(h => observer.observe(h));
		}
	}
}
</script>

<style scoped>
/* ===== Hero Cover ===== */
.article-hero-cover {
	position: relative;
	min-height: 420px;
	background-size: cover;
	background-position: center;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 60px 0;
}

.article-hero-overlay {
	position: absolute;
	inset: 0;
	background: linear-gradient(to bottom, rgba(0,0,0,0.3), rgba(0,0,0,0.7));
}

.article-cover-title {
	font-size: 34px;
	line-height: 1.4;
	text-shadow: 0 2px 8px rgba(0,0,0,0.3);
}

.cover-author-avatar {
	width: 38px;
	height: 38px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 16px;
	flex-shrink: 0;
	border: 2px solid rgba(255,255,255,0.3);
}

/* ===== Share Sidebar ===== */
.article-content-wrapper {
	position: relative;
}

/* Share sidebar positioning now handled by flex & sticky utilities */

.share-btn {
	width: 44px;
	height: 44px;
	border-radius: 50%;
	border: 1px solid #e9ecef;
	background: white;
	color: #6c757d;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	font-size: 16px;
	cursor: pointer;
	transition: all 0.2s ease;
	box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}

.share-btn span {
	font-size: 10px;
	margin-top: 1px;
	font-weight: 600;
}

.share-btn:hover {
	background: #0d6efd;
	color: white;
	border-color: #0d6efd;
	transform: scale(1.1);
}

.share-divider {
	width: 24px;
	height: 1px;
	background: #e9ecef;
	margin: 4px 0;
}

/* ===== Article Body ===== */
.article-body {
	font-size: 16px;
	line-height: 1.8;
	color: #333;
}

.article-body .lead {
	font-size: 18px;
	line-height: 1.7;
	border-left: 4px solid #0d6efd;
	padding-left: 20px;
}

.article-html-content :deep(h2) {
	font-size: 24px;
	font-weight: 700;
	margin-top: 40px;
	margin-bottom: 16px;
	color: #1a1a2e;
	padding-bottom: 8px;
	border-bottom: 2px solid #f0f0f0;
}

.article-html-content :deep(h3) {
	font-size: 20px;
	font-weight: 600;
	margin-top: 28px;
	margin-bottom: 12px;
	color: #333;
}

.article-html-content :deep(p) {
	margin-bottom: 16px;
	color: #444;
}

.article-html-content :deep(ul),
.article-html-content :deep(ol) {
	padding-left: 24px;
	margin-bottom: 20px;
}

.article-html-content :deep(li) {
	margin-bottom: 8px;
	color: #444;
}

.article-html-content :deep(strong) {
	color: #1a1a2e;
}

.article-html-content :deep(.article-highlight) {
	background: linear-gradient(135deg, #f0f7ff, #e8f4fd);
	border-left: 4px solid #0d6efd;
}

.article-html-content :deep(.highlight-icon) {
	width: 40px;
	height: 40px;
	min-width: 40px;
	background: #0d6efd;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-size: 18px;
}

/* ===== Author Box ===== */
.author-box {
	background: #f8f9fa;
	border-radius: 16px;
	padding: 24px;
	border: 1px solid #e9ecef;
}

.author-box-avatar {
	width: 56px;
	height: 56px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 22px;
	flex-shrink: 0;
}

/* ===== Nav Article Cards ===== */
.nav-article-card {
	border-radius: 12px;
	transition: all 0.2s ease;
}

.nav-article-card:hover {
	transform: translateY(-2px);
	box-shadow: 0 6px 16px rgba(0,0,0,0.08) !important;
}

.nav-article-title {
	display: -webkit-box;
	-webkit-line-clamp: 2;
	line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
	font-size: 14px;
}

/* ===== Comments ===== */
.comment-avatar {
	width: 36px;
	height: 36px;
	min-width: 36px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 14px;
}

.comment-item {
	padding: 16px 0;
	border-bottom: 1px solid #f0f0f0;
}

.comment-item:last-child {
	border-bottom: none;
}

/* ===== Sidebar ===== */
.toc-list li {
	border-bottom: 1px solid #f8f8f8;
}

.toc-list li:last-child {
	border-bottom: none;
}

.toc-link {
	color: #6c757d;
	font-size: 13px;
	transition: all 0.2s ease;
}

.toc-link:hover {
	background: #f8f9fa;
	color: #0d6efd;
}

.toc-active {
	color: #0d6efd !important;
	background: rgba(13, 110, 253, 0.05);
	font-weight: 600;
}

.toc-dot {
	width: 6px;
	height: 6px;
	min-width: 6px;
	border-radius: 50%;
	background: #dee2e6;
	transition: background 0.2s ease;
}

.toc-active .toc-dot {
	background: #0d6efd;
}

.related-item {
	transition: background 0.2s ease;
}

.related-item:hover {
	background: #f8f9fa;
}

.related-thumb {
	width: 64px;
	height: 64px;
	min-width: 64px;
	border-radius: 10px;
	background-size: cover;
	background-position: center;
}

.related-title {
	display: -webkit-box;
	-webkit-line-clamp: 2;
	line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
}

.popular-tag {
	transition: all 0.2s ease;
}

.popular-tag:hover {
	background: #0d6efd !important;
	color: white !important;
}

/* ===== Responsive ===== */
@media (max-width: 991px) {
	.article-hero-cover {
		min-height: 320px;
		padding: 40px 0;
	}
	.article-cover-title {
		font-size: 24px;
	}
}

@media (max-width: 767px) {
	.article-hero-cover {
		min-height: 280px;
		padding: 30px 0;
	}
	.article-cover-title {
		font-size: 20px;
	}
	.article-body {
		font-size: 15px;
	}
}
</style>
