<template>
	<div class="admin-articles">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-newspaper text-primary me-2"></i>{{ $t('admin.articles.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.articles.subtitle') }}</p>
			</div>
			<button class="btn btn-primary rounded-pill px-4" @click="openAddModal">
				<i class="fa-solid fa-pen-nib me-2"></i>{{ $t('admin.articles.newArticleBtn') }}
			</button>
		</div>

		<!-- Stats Quick View -->
		<div class="row g-3 mb-4">
			<div class="col-sm-3" v-for="s in computedStats" :key="s.label">
				<div class="card border-0 shadow-sm">
					<div class="card-body p-3 d-flex align-items-center gap-3">
						<div class="article-stat-icon" :style="{ background: s.bg, color: s.color }">
							<i :class="s.icon"></i>
						</div>
						<div>
							<p class="text-muted small mb-0">{{ s.label }}</p>
							<h5 class="fw-bold mb-0">{{ s.value }}</h5>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Filters -->
		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body py-3">
				<div class="row g-3 align-items-center">
					<div class="col-md-4">
						<div class="position-relative">
							<input type="text" class="form-control ps-5" :placeholder="$t('admin.articles.searchPlaceholder')" v-model="search">
							<i class="fa-solid fa-search position-absolute" style="left: 16px; top: 50%; transform: translateY(-50%); color: #adb5bd;"></i>
						</div>
					</div>
					<div class="col-md-3">
						<select class="form-select" v-model="filterCategory">
							<option value="">{{ $t('admin.articles.allCategories') }}</option>
							<option value="news">{{ $t('articleCategories.news') }}</option>
							<option value="story">{{ $t('articleCategories.story') }}</option>
							<option value="guide">{{ $t('articleCategories.guide') }}</option>
							<option value="event">{{ $t('articleCategories.event') }}</option>
							<option value="result">{{ $t('articleCategories.result') }}</option>
						</select>
					</div>
					<div class="col-md-3">
						<select class="form-select" v-model="filterStatus">
							<option value="">{{ $t('admin.articles.allStatuses') }}</option>
							<option value="published">{{ $t('admin.articles.status.published') }}</option>
							<option value="draft">{{ $t('admin.articles.status.draft') }}</option>
							<option value="featured">{{ $t('admin.articles.status.featured') }}</option>
						</select>
					</div>
					<div class="col-md-2 text-end">
						<button class="btn btn-outline-secondary btn-sm" @click="resetFilters">
							<i class="fa-solid fa-rotate-left me-1"></i>{{ $t('admin.articles.reset') }}
						</button>
					</div>
				</div>
			</div>
		</div>

		<!-- Articles Table -->
		<div class="card border-0 shadow-sm">
			<div class="card-body p-0">
				<div class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead class="table-light">
							<tr>
								<th class="ps-4" style="width: 40px;"><input class="form-check-input" type="checkbox"></th>
								<th>{{ $t('admin.articles.table.article') }}</th>
								<th>{{ $t('admin.articles.table.category') }}</th>
								<th>{{ $t('admin.articles.table.status') }}</th>
								<th class="text-center">{{ $t('admin.articles.table.views') }}</th>
								<th class="text-center">{{ $t('admin.articles.table.interactions') }}</th>
								<th>{{ $t('admin.articles.table.date') }}</th>
								<th class="text-center">{{ $t('admin.articles.table.actions') }}</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="article in filteredArticles" :key="article.id">
								<td class="ps-4"><input class="form-check-input" type="checkbox"></td>
								<td>
									<div class="d-flex align-items-center gap-3">
										<div class="article-thumb" :style="{ backgroundImage: `url(${article.image})` }"></div>
										<div style="min-width: 0;">
											<h6 class="mb-0 small fw-bold article-title-cell">{{ article.title }}</h6>
											<span class="text-muted" style="font-size: 12px;">{{ article.author }}</span>
										</div>
									</div>
								</td>
								<td>
									<span class="badge rounded-pill" :class="getCategoryClass(article.category)">
										{{ getCategoryLabel(article.category) }}
									</span>
								</td>
								<td>
									<span class="badge rounded-pill" :class="getStatusClass(article.status)">
										<i :class="getStatusIcon(article.status)" class="me-1"></i>{{ getStatusLabel(article.status) }}
									</span>
								</td>
								<td class="text-center">
									<span class="fw-bold small">{{ article.views }}</span>
								</td>
								<td class="text-center">
									<span class="text-muted small">
										<i class="fa-solid fa-heart text-danger me-1"></i>{{ article.likes }}
										<i class="fa-solid fa-comment text-primary ms-2 me-1"></i>{{ article.comments }}
									</span>
								</td>
								<td><span class="text-muted small">{{ article.date }}</span></td>
								<td class="text-center">
									<div class="btn-group">
										<button class="btn btn-sm btn-outline-primary" :title="$t('admin.articles.actions.view')" @click="viewArticle(article)">
											<i class="fa-solid fa-eye"></i>
										</button>
										<button class="btn btn-sm btn-outline-secondary" :title="$t('admin.articles.actions.edit')" @click="openEditModal(article)">
											<i class="fa-solid fa-pen"></i>
										</button>
										<button class="btn btn-sm" :title="$t('admin.articles.actions.feature')"
											:class="article.status === 'featured' ? 'btn-warning' : 'btn-outline-warning'"
											@click="toggleFeatured(article)">
											<i class="fa-solid fa-star"></i>
										</button>
										<button class="btn btn-sm btn-outline-danger" :title="$t('admin.articles.actions.delete')"
											@click="confirmDelete(article)">
											<i class="fa-solid fa-trash"></i>
										</button>
									</div>
								</td>
							</tr>
						</tbody>
					</table>
				</div>

				<div class="text-center py-5" v-if="filteredArticles.length === 0">
					<i class="fa-solid fa-newspaper text-muted" style="font-size: 48px;"></i>
					<p class="text-muted mt-3">{{ $t('admin.articles.empty.noArticles') }}</p>
				</div>
			</div>

			<div class="card-footer bg-white border-top py-3" v-if="filteredArticles.length > 0">
				<div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
					<span class="text-muted small">{{ $t('admin.articles.empty.showing', { count: filteredArticles.length }) }}</span>
					<nav>
						<ul class="pagination pagination-sm mb-0">
							<li class="page-item disabled"><a class="page-link" href="#">«</a></li>
							<li class="page-item active"><a class="page-link" href="#">1</a></li>
							<li class="page-item"><a class="page-link" href="#">2</a></li>
							<li class="page-item"><a class="page-link" href="#">»</a></li>
						</ul>
					</nav>
				</div>
			</div>
		</div>

		<!-- Add/Edit Article Modal -->
		<div class="modal fade" :class="{ show: showFormModal }" :style="showFormModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered modal-lg">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold">
							<i :class="isEditing ? 'fa-solid fa-pen-to-square' : 'fa-solid fa-pen-nib'" class="text-primary me-2"></i>
							{{ isEditing ? $t('admin.articles.form.editTitle') : $t('admin.articles.form.addTitle') }}
						</h5>
						<button type="button" class="btn-close" @click="showFormModal = false"></button>
					</div>
					<div class="modal-body">
						<div class="row g-3">
							<div class="col-12">
								<label class="form-label small fw-bold">{{ $t('admin.articles.form.titleLabel') }} <span class="text-danger">*</span></label>
								<input type="text" class="form-control" :placeholder="$t('admin.articles.form.titlePlaceholder')"
									v-model="formData.title" :class="{ 'is-invalid': formErrors.title }">
								<div class="invalid-feedback">{{ formErrors.title }}</div>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.articles.form.categoryLabel') }} <span class="text-danger">*</span></label>
								<select class="form-select" v-model="formData.category">
									<option value="">{{ $t('admin.articles.form.categorySelect') }}</option>
									<option value="news">{{ $t('articleCategories.news') }}</option>
									<option value="story">{{ $t('articleCategories.story') }}</option>
									<option value="guide">{{ $t('articleCategories.guide') }}</option>
									<option value="event">{{ $t('articleCategories.event') }}</option>
									<option value="result">{{ $t('articleCategories.result') }}</option>
								</select>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.articles.form.statusLabel') }}</label>
								<select class="form-select" v-model="formData.status">
									<option value="draft">{{ $t('admin.articles.status.draft') }}</option>
									<option value="published">{{ $t('admin.articles.status.published') }}</option>
									<option value="featured">{{ $t('admin.articles.status.featured') }}</option>
								</select>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.articles.form.authorLabel') }}</label>
								<input type="text" class="form-control" :placeholder="$t('admin.articles.form.authorPlaceholder')" v-model="formData.author">
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.articles.form.imageLabel') }}</label>
								<input type="text" class="form-control" :placeholder="$t('admin.articles.form.imagePlaceholder')" v-model="formData.image">
							</div>
							<div class="col-12">
								<label class="form-label small fw-bold">{{ $t('admin.articles.form.summaryLabel') }}</label>
								<textarea class="form-control" rows="2" :placeholder="$t('admin.articles.form.summaryPlaceholder')" v-model="formData.summary"></textarea>
							</div>
							<div class="col-12">
								<label class="form-label small fw-bold">{{ $t('admin.articles.form.contentLabel') }}</label>
								<textarea class="form-control" rows="6" :placeholder="$t('admin.articles.form.contentPlaceholder')" v-model="formData.content"></textarea>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showFormModal = false">{{ $t('admin.articles.form.cancelBtn') }}</button>
						<button v-if="!isEditing" type="button" class="btn btn-outline-secondary rounded-pill px-4" @click="saveArticle('draft')">
							<i class="fa-solid fa-file-pen me-1"></i>{{ $t('admin.articles.form.saveDraftBtn') }}
						</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="saveArticle()">
							<i :class="isEditing ? 'fa-solid fa-save' : 'fa-solid fa-paper-plane'" class="me-1"></i>
							{{ isEditing ? $t('admin.articles.form.updateBtn') : $t('admin.articles.form.publishBtn') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showFormModal" @click="showFormModal = false"></div>

		<!-- View Article Modal -->
		<div class="modal fade" :class="{ show: showViewModal }" :style="showViewModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered modal-lg">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-newspaper text-primary me-2"></i>{{ $t('admin.articles.view.title') }}</h5>
						<button type="button" class="btn-close" @click="showViewModal = false"></button>
					</div>
					<div class="modal-body" v-if="viewingArticle">
						<div class="article-view-hero mb-3" v-if="viewingArticle.image"
							:style="{ backgroundImage: `url(${viewingArticle.image})` }"></div>
						<div class="d-flex align-items-center gap-2 mb-2">
							<span class="badge rounded-pill" :class="getCategoryClass(viewingArticle.category)">
								{{ getCategoryLabel(viewingArticle.category) }}
							</span>
							<span class="badge rounded-pill" :class="getStatusClass(viewingArticle.status)">
								<i :class="getStatusIcon(viewingArticle.status)" class="me-1"></i>{{ getStatusLabel(viewingArticle.status) }}
							</span>
						</div>
						<h4 class="fw-bold">{{ viewingArticle.title }}</h4>
						<div class="d-flex align-items-center gap-3 text-muted small mb-3">
							<span><i class="fa-solid fa-user me-1"></i>{{ viewingArticle.author }}</span>
							<span><i class="fa-solid fa-calendar me-1"></i>{{ viewingArticle.date }}</span>
							<span><i class="fa-solid fa-eye me-1"></i>{{ viewingArticle.views }} {{ $t('admin.articles.table.views').toLowerCase() }}</span>
						</div>
						<div class="d-flex gap-3 mb-3">
							<div class="py-2 px-3 bg-light rounded-3 text-center">
								<i class="fa-solid fa-heart text-danger"></i> <span class="fw-bold">{{ viewingArticle.likes }}</span>
							</div>
							<div class="py-2 px-3 bg-light rounded-3 text-center">
								<i class="fa-solid fa-comment text-primary"></i> <span class="fw-bold">{{ viewingArticle.comments }}</span>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showViewModal = false">{{ $t('admin.articles.view.closeBtn') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="showViewModal = false; openEditModal(viewingArticle)">
							<i class="fa-solid fa-pen me-1"></i>{{ $t('admin.articles.view.editBtn') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showViewModal" @click="showViewModal = false"></div>

		<!-- Confirm Delete Modal -->
		<ConfirmModal ref="confirmModal" :modalId="'articleConfirmModal'"
			:title="$t('admin.articles.delete.title')" :message="$t('admin.articles.delete.message')"
			:detail="deleteTarget ? deleteTarget.title : ''"
			icon="fa-solid fa-trash" variant="danger"
			:confirmText="$t('admin.articles.delete.confirmBtn')" confirmIcon="fa-solid fa-trash"
			@confirm="onConfirmDelete" />
	</div>
</template>

<script>
import ConfirmModal from '../../components/ConfirmModal.vue';

export default {
	name: 'QuanLyBaiViet',
	components: { ConfirmModal },
	props: {
		toast: { type: Object, default: null }
	},
	data() {
		return {
			search: '',
			filterCategory: '',
			filterStatus: '',
			showFormModal: false,
			showViewModal: false,
			isEditing: false,
			editingArticleId: null,
			viewingArticle: null,
			deleteTarget: null,
			formData: { title: '', category: '', status: 'draft', author: 'Admin', image: '', summary: '', content: '' },
			formErrors: {},
			articles: [
				{ id: 1, title: 'Chiến dịch "Mùa hè xanh" 2026 chính thức khởi động tại 28 tỉnh thành', author: 'Ban Biên Tập', category: 'news', status: 'featured', views: '2.4K', likes: 342, comments: 56, date: '05/03/2026', image: 'https://images.unsplash.com/photo-1529390079861-591de354faf5?w=100&q=80' },
				{ id: 2, title: 'Câu chuyện TNV: Từ sinh viên nhút nhát đến kiểm duyệt viên tự tin', author: 'Phạm Đức', category: 'story', status: 'published', views: '890', likes: 167, comments: 29, date: '03/03/2026', image: 'https://images.unsplash.com/photo-1531545514256-b1400bc00f31?w=100&q=80' },
				{ id: 3, title: 'Kết quả chiến dịch "Ánh sáng cho em" — Hơn 500 kính được trao', author: 'Quỹ Bảo Trợ', category: 'result', status: 'published', views: '1.1K', likes: 198, comments: 35, date: '08/02/2026', image: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=100&q=80' },
				{ id: 4, title: 'Hướng dẫn đăng ký tham gia chiến dịch cho TNV mới', author: 'Admin', category: 'guide', status: 'published', views: '645', likes: 89, comments: 18, date: '25/02/2026', image: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=100&q=80' },
				{ id: 5, title: 'Sự kiện giao lưu tình nguyện viên Đà Nẵng 2026', author: 'Lê Thảo', category: 'event', status: 'published', views: '430', likes: 76, comments: 12, date: '22/02/2026', image: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=100&q=80' },
				{ id: 6, title: 'TNV xuất sắc tháng 2: Nguyễn Minh Tuấn', author: 'Admin', category: 'news', status: 'draft', views: '0', likes: 0, comments: 0, date: '(nháp)', image: 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=100&q=80' },
				{ id: 7, title: '10 điều cần chuẩn bị trước khi đi tình nguyện vùng cao', author: 'Ban Biên Tập', category: 'guide', status: 'draft', views: '0', likes: 0, comments: 0, date: '(nháp)', image: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=100&q=80' }
			]
		}
	},
	computed: {
		computedStats() {
			return [
				{ label: this.$t('admin.articles.stats.total'), value: this.articles.length, icon: 'fa-solid fa-newspaper', bg: 'rgba(79,140,247,0.1)', color: '#4f8cf7' },
				{ label: this.$t('admin.articles.stats.published'), value: this.articles.filter(a => a.status === 'published' || a.status === 'featured').length, icon: 'fa-solid fa-check-circle', bg: 'rgba(40,167,69,0.1)', color: '#28a745' },
				{ label: this.$t('admin.articles.stats.draft'), value: this.articles.filter(a => a.status === 'draft').length, icon: 'fa-solid fa-file-pen', bg: 'rgba(253,126,20,0.1)', color: '#fd7e14' },
				{ label: this.$t('admin.articles.stats.featured'), value: this.articles.filter(a => a.status === 'featured').length, icon: 'fa-solid fa-star', bg: 'rgba(220,53,69,0.1)', color: '#dc3545' }
			];
		},
		filteredArticles() {
			let list = this.articles;
			if (this.search) {
				const q = this.search.toLowerCase();
				list = list.filter(a => a.title.toLowerCase().includes(q));
			}
			if (this.filterCategory) list = list.filter(a => a.category === this.filterCategory);
			if (this.filterStatus) list = list.filter(a => a.status === this.filterStatus);
			return list;
		}
	},
	methods: {
		getCategoryLabel(cat) {
			return this.$t(`articleCategories.${cat}`) || cat;
		},
		getCategoryClass(cat) {
			return { news: 'bg-primary-subtle text-primary', story: 'bg-danger-subtle text-danger', guide: 'bg-info-subtle text-info', event: 'bg-warning-subtle text-warning', result: 'bg-success-subtle text-success' }[cat];
		},
		getStatusLabel(s) {
			return this.$t(`admin.articles.status.${s}`);
		},
		getStatusIcon(s) {
			return { published: 'fa-solid fa-check-circle', draft: 'fa-solid fa-file-pen', featured: 'fa-solid fa-star' }[s];
		},
		getStatusClass(s) {
			return { published: 'bg-success-subtle text-success', draft: 'bg-secondary-subtle text-secondary', featured: 'bg-warning-subtle text-warning' }[s];
		},
		// --- Form ---
		openAddModal() {
			this.isEditing = false;
			this.editingArticleId = null;
			this.formData = { title: '', category: '', status: 'draft', author: 'Admin', image: '', summary: '', content: '' };
			this.formErrors = {};
			this.showFormModal = true;
		},
		openEditModal(article) {
			this.isEditing = true;
			this.editingArticleId = article.id;
			this.formData = {
				title: article.title,
				category: article.category,
				status: article.status,
				author: article.author,
				image: article.image,
				summary: '',
				content: ''
			};
			this.formErrors = {};
			this.showFormModal = true;
		},
		saveArticle(forceDraft) {
			this.formErrors = {};
			if (!this.formData.title.trim()) { this.formErrors.title = this.$t('admin.articles.validation.titleRequired'); return; }

			if (this.isEditing) {
				const article = this.articles.find(a => a.id === this.editingArticleId);
				if (article) {
					article.title = this.formData.title;
					article.category = this.formData.category || article.category;
					article.status = this.formData.status;
					article.author = this.formData.author || article.author;
					if (this.formData.image) article.image = this.formData.image;
				}
				this.showToast('success', this.$t('admin.articles.toast.updateSuccess'), this.$t('admin.articles.toast.updateMsg', { title: this.formData.title }));
			} else {
				const newArticle = {
					id: Date.now(),
					title: this.formData.title,
					author: this.formData.author || 'Admin',
					category: this.formData.category || 'news',
					status: forceDraft ? 'draft' : (this.formData.status || 'published'),
					views: '0',
					likes: 0,
					comments: 0,
					date: forceDraft ? '(nháp)' : new Date().toLocaleDateString('vi-VN'),
					image: this.formData.image || 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=100&q=80'
				};
				this.articles.unshift(newArticle);
				this.showToast('success',
					forceDraft ? this.$t('admin.articles.toast.draftSaved') : this.$t('admin.articles.toast.publishSuccess'),
					forceDraft ? this.$t('admin.articles.toast.draftMsg', { title: this.formData.title }) : this.$t('admin.articles.toast.publishMsg', { title: this.formData.title })
				);
			}
			this.showFormModal = false;
		},
		// --- View ---
		viewArticle(article) {
			this.viewingArticle = article;
			this.showViewModal = true;
		},
		// --- Toggle Featured ---
		toggleFeatured(article) {
			const wasFeatured = article.status === 'featured';
			article.status = wasFeatured ? 'published' : 'featured';
			this.showToast(
				wasFeatured ? 'info' : 'success',
				wasFeatured ? this.$t('admin.articles.toast.unfeatured') : this.$t('admin.articles.toast.featured'),
				`"${article.title}"`
			);
		},
		// --- Delete ---
		confirmDelete(article) {
			this.deleteTarget = article;
			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		onConfirmDelete() {
			if (this.deleteTarget) {
				const title = this.deleteTarget.title;
				this.articles = this.articles.filter(a => a.id !== this.deleteTarget.id);
				this.showToast('success', this.$t('admin.articles.toast.deleteSuccess'), this.$t('admin.articles.toast.deleteMsg', { title: title }));
				this.deleteTarget = null;
			}
		},
		resetFilters() {
			this.search = '';
			this.filterCategory = '';
			this.filterStatus = '';
		},
		showToast(type, title, message) {
			if (this.toast) this.toast[type](title, message);
		}
	}
}
</script>

<style scoped>
.article-stat-icon {
	width: 42px;
	height: 42px;
	min-width: 42px;
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 18px;
}

.article-thumb {
	width: 56px;
	height: 42px;
	min-width: 56px;
	border-radius: 8px;
	background-size: cover;
	background-position: center;
}

.article-title-cell {
	display: -webkit-box;
	-webkit-line-clamp: 1;
	line-clamp: 1;
	-webkit-box-orient: vertical;
	overflow: hidden;
}

.article-view-hero {
	width: 100%;
	height: 200px;
	border-radius: 12px;
	background-size: cover;
	background-position: center;
}

.table th {
	font-size: 12px;
	font-weight: 700;
	color: #6c757d;
	text-transform: uppercase;
	letter-spacing: 0.5px;
	border-bottom: none;
}

.table td {
	font-size: 14px;
}
</style>
