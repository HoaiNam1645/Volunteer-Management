<template>
	<div class="admin-categories">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-layer-group text-primary me-2"></i>{{ $t('admin.categories.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.categories.subtitle') }}</p>
			</div>
		</div>

		<!-- 3 Column Layout for Categories -->
		<div class="row g-4">
			<!-- Skills -->
			<div class="col-lg-4">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3">
						<div class="d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-tools text-primary me-2"></i>{{ $t('admin.categories.skills.title') }}</h6>
							<button class="btn btn-primary btn-sm rounded-pill px-3" @click="openAddModal('skills')">
								<i class="fa-solid fa-plus"></i>
							</button>
						</div>
						<input type="text" class="form-control form-control-sm mt-2" :placeholder="$t('admin.categories.skills.search')" v-model="searchSkills">
					</div>
					<div class="card-body p-0" style="max-height: 420px; overflow-y: auto;">
						<div class="category-item d-flex align-items-center gap-3 px-3 py-2 border-bottom" 
						v-for="(skill, idx) in filteredSkills" :key="idx">
							<div class="cat-icon bg-primary-subtle text-primary">
								<i class="fa-solid fa-wrench"></i>
							</div>
							<div class="flex-grow-1">
								<p class="mb-0 small fw-bold">{{ skill.name }}</p>
								<span class="text-muted" style="font-size: 11px;">{{ $t('admin.categories.skills.usersCount', { count: skill.count }) }}</span>
							</div>
							<div class="btn-group btn-group-sm opacity-hover">
								<button class="btn btn-outline-secondary btn-sm" @click="openEditModal('skills', idx)">
									<i class="fa-solid fa-pen" style="font-size: 11px;"></i>
								</button>
								<button class="btn btn-outline-danger btn-sm" @click="confirmRemove('skills', idx)">
									<i class="fa-solid fa-trash" style="font-size: 11px;"></i>
								</button>
							</div>
						</div>
						<div class="text-center py-4 text-muted small" v-if="filteredSkills.length === 0">
							<i class="fa-solid fa-inbox d-block mb-2" style="font-size: 28px;"></i>
							{{ $t('admin.categories.skills.notFound') }}
						</div>
					</div>
					<div class="card-footer bg-white text-center py-2 border-top">
						<span class="text-muted small">{{ $t('admin.categories.skills.total', { count: skills.length }) }}</span>
					</div>
				</div>
			</div>

			<!-- Regions -->
			<div class="col-lg-4">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3">
						<div class="d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-map-location-dot text-success me-2"></i>{{ $t('admin.categories.regions.title') }}</h6>
							<button class="btn btn-success btn-sm rounded-pill px-3" @click="openAddModal('regions')">
								<i class="fa-solid fa-plus"></i>
							</button>
						</div>
						<input type="text" class="form-control form-control-sm mt-2" :placeholder="$t('admin.categories.regions.search')" v-model="searchRegions">
					</div>
					<div class="card-body p-0" style="max-height: 420px; overflow-y: auto;">
						<div class="category-item d-flex align-items-center gap-3 px-3 py-2 border-bottom" 
						v-for="(region, idx) in filteredRegions" :key="idx">
							<div class="cat-icon bg-success-subtle text-success">
								<i class="fa-solid fa-location-dot"></i>
							</div>
							<div class="flex-grow-1">
								<p class="mb-0 small fw-bold">{{ region.name }}</p>
								<span class="text-muted" style="font-size: 11px;">{{ $t('admin.categories.regions.campaignsCount', { count: region.campaigns }) }}</span>
							</div>
							<div class="btn-group btn-group-sm opacity-hover">
								<button class="btn btn-outline-secondary btn-sm" @click="openEditModal('regions', idx)">
									<i class="fa-solid fa-pen" style="font-size: 11px;"></i>
								</button>
								<button class="btn btn-outline-danger btn-sm" @click="confirmRemove('regions', idx)">
									<i class="fa-solid fa-trash" style="font-size: 11px;"></i>
								</button>
							</div>
						</div>
						<div class="text-center py-4 text-muted small" v-if="filteredRegions.length === 0">
							<i class="fa-solid fa-inbox d-block mb-2" style="font-size: 28px;"></i>
							{{ $t('admin.categories.regions.notFound') }}
						</div>
					</div>
					<div class="card-footer bg-white text-center py-2 border-top">
						<span class="text-muted small">{{ $t('admin.categories.regions.total', { count: regions.length }) }}</span>
					</div>
				</div>
			</div>

			<!-- Campaign Types -->
			<div class="col-lg-4">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3">
						<div class="d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-tags text-warning me-2"></i>{{ $t('admin.categories.types.title') }}</h6>
							<button class="btn btn-warning btn-sm rounded-pill px-3 text-dark" @click="openAddModal('types')">
								<i class="fa-solid fa-plus"></i>
							</button>
						</div>
						<input type="text" class="form-control form-control-sm mt-2" :placeholder="$t('admin.categories.types.search')" v-model="searchTypes">
					</div>
					<div class="card-body p-0" style="max-height: 420px; overflow-y: auto;">
						<div class="category-item d-flex align-items-center gap-3 px-3 py-2 border-bottom" 
						v-for="(type, idx) in filteredTypes" :key="idx">
							<div class="cat-icon bg-warning-subtle text-warning">
								<i class="fa-solid fa-tag"></i>
							</div>
							<div class="flex-grow-1">
								<p class="mb-0 small fw-bold">{{ type.name }}</p>
								<span class="text-muted" style="font-size: 11px;">{{ $t('admin.categories.types.campaignsCount', { count: type.campaigns }) }}</span>
							</div>
							<div class="btn-group btn-group-sm opacity-hover">
								<button class="btn btn-outline-secondary btn-sm" @click="openEditModal('types', idx)">
									<i class="fa-solid fa-pen" style="font-size: 11px;"></i>
								</button>
								<button class="btn btn-outline-danger btn-sm" @click="confirmRemove('types', idx)">
									<i class="fa-solid fa-trash" style="font-size: 11px;"></i>
								</button>
							</div>
						</div>
						<div class="text-center py-4 text-muted small" v-if="filteredTypes.length === 0">
							<i class="fa-solid fa-inbox d-block mb-2" style="font-size: 28px;"></i>
							{{ $t('admin.categories.types.notFound') }}
						</div>
					</div>
					<div class="card-footer bg-white text-center py-2 border-top">
						<span class="text-muted small">{{ $t('admin.categories.types.total', { count: types.length }) }}</span>
					</div>
				</div>
			</div>
		</div>

		<!-- Add/Edit Category Modal -->
		<div class="modal fade" :class="{ show: showFormModal }" :style="showFormModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold">
							<i :class="getCategoryModalIcon()" class="me-2"></i>
							{{ isEditing ? $t('admin.categories.form.editTitle', { cat: getCategoryLabel(editingCategory) }) : $t('admin.categories.form.addTitle', { cat: getCategoryLabel(editingCategory) }) }}
						</h5>
						<button type="button" class="btn-close" @click="showFormModal = false"></button>
					</div>
					<div class="modal-body">
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('admin.categories.form.nameLabel', { cat: getCategoryLabel(editingCategory) }) }} <span class="text-danger">*</span></label>
							<input type="text" class="form-control" :placeholder="$t('admin.categories.form.namePlaceholder', { cat: getCategoryLabel(editingCategory).toLowerCase() })"
								v-model="catFormData.name" :class="{ 'is-invalid': catFormError }" @keyup.enter="saveCategoryItem">
							<div class="invalid-feedback">{{ catFormError }}</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showFormModal = false">{{ $t('admin.categories.form.cancelBtn') }}</button>
						<button type="button" class="btn rounded-pill px-4" :class="getCategorySaveClass()" @click="saveCategoryItem">
							<i :class="isEditing ? 'fa-solid fa-save' : 'fa-solid fa-plus'" class="me-1"></i>
							{{ isEditing ? $t('admin.categories.form.updateBtn') : $t('admin.categories.form.addBtn') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showFormModal" @click="showFormModal = false"></div>

		<!-- Confirm Delete Modal -->
		<ConfirmModal ref="confirmModal" :modalId="'catConfirmModal'"
			:title="confirmConfig.title" :message="confirmConfig.message" :detail="confirmConfig.detail"
			:icon="'fa-solid fa-trash'" :variant="'danger'"
			:confirmText="$t('admin.categories.delete.confirmBtn')" :confirmIcon="'fa-solid fa-trash'"
			@confirm="onConfirmDelete" />
	</div>
</template>

<script>
import ConfirmModal from '../../components/ConfirmModal.vue';

export default {
	name: 'QuanLyDanhMuc',
	components: { ConfirmModal },
	props: {
		toast: { type: Object, default: null }
	},
	data() {
		return {
			searchSkills: '',
			searchRegions: '',
			searchTypes: '',
			showFormModal: false,
			isEditing: false,
			editingCategory: 'skills',
			editingIndex: null,
			catFormData: { name: '' },
			catFormError: '',
			confirmConfig: { title: '', message: '', detail: '' },
			deleteAction: null,
			skills: [
				{ name: 'Dạy học', count: 245 },
				{ name: 'Y tế / Sơ cứu', count: 128 },
				{ name: 'Xây dựng', count: 89 },
				{ name: 'Truyền thông', count: 156 },
				{ name: 'Kỹ thuật', count: 72 },
				{ name: 'Nấu ăn', count: 98 },
				{ name: 'Lái xe', count: 64 },
				{ name: 'Phiên dịch', count: 43 },
				{ name: 'Thiết kế', count: 87 },
				{ name: 'Âm nhạc / Nghệ thuật', count: 51 },
				{ name: 'Quản lý dự án', count: 34 },
				{ name: 'IT / Công nghệ', count: 112 }
			],
			regions: [
				{ name: 'TP. Hồ Chí Minh', campaigns: 32 },
				{ name: 'Hà Nội', campaigns: 28 },
				{ name: 'Đà Nẵng', campaigns: 18 },
				{ name: 'Lào Cai', campaigns: 12 },
				{ name: 'Quảng Nam', campaigns: 15 },
				{ name: 'Đắk Lắk', campaigns: 8 },
				{ name: 'Quảng Bình', campaigns: 6 },
				{ name: 'Nghệ An', campaigns: 10 },
				{ name: 'Thừa Thiên Huế', campaigns: 9 },
				{ name: 'Cần Thơ', campaigns: 7 }
			],
			types: [
				{ name: 'Giáo dục', campaigns: 35 },
				{ name: 'Y tế', campaigns: 22 },
				{ name: 'Môi trường', campaigns: 28 },
				{ name: 'Xây dựng', campaigns: 15 },
				{ name: 'Cứu trợ thiên tai', campaigns: 8 },
				{ name: 'Văn hóa - Xã hội', campaigns: 12 },
				{ name: 'Thể thao', campaigns: 6 },
				{ name: 'Công nghệ', campaigns: 4 }
			]
		}
	},
	computed: {
		filteredSkills() {
			if (!this.searchSkills) return this.skills;
			return this.skills.filter(s => s.name.toLowerCase().includes(this.searchSkills.toLowerCase()));
		},
		filteredRegions() {
			if (!this.searchRegions) return this.regions;
			return this.regions.filter(r => r.name.toLowerCase().includes(this.searchRegions.toLowerCase()));
		},
		filteredTypes() {
			if (!this.searchTypes) return this.types;
			return this.types.filter(t => t.name.toLowerCase().includes(this.searchTypes.toLowerCase()));
		}
	},
	methods: {
		getCategoryLabel(cat) {
			return this.$t(`admin.categories.${cat}.label`) || '';
		},
		getCategoryModalIcon() {
			const icons = { skills: 'fa-solid fa-tools text-primary', regions: 'fa-solid fa-map-location-dot text-success', types: 'fa-solid fa-tags text-warning' };
			return icons[this.editingCategory] || '';
		},
		getCategorySaveClass() {
			const classes = { skills: 'btn-primary', regions: 'btn-success', types: 'btn-warning text-dark' };
			return classes[this.editingCategory] || 'btn-primary';
		},
		getList(category) {
			return { skills: this.skills, regions: this.regions, types: this.types }[category];
		},
		openAddModal(category) {
			this.isEditing = false;
			this.editingCategory = category;
			this.editingIndex = null;
			this.catFormData = { name: '' };
			this.catFormError = '';
			this.showFormModal = true;
		},
		openEditModal(category, idx) {
			this.isEditing = true;
			this.editingCategory = category;
			this.editingIndex = idx;
			const list = this.getList(category);
			this.catFormData = { name: list[idx].name };
			this.catFormError = '';
			this.showFormModal = true;
		},
		saveCategoryItem() {
			if (!this.catFormData.name.trim()) {
				this.catFormError = this.$t('admin.categories.validation.nameRequired');
				return;
			}
			const list = this.getList(this.editingCategory);
			const label = this.getCategoryLabel(this.editingCategory);

			if (this.isEditing) {
				const oldName = list[this.editingIndex].name;
				list[this.editingIndex].name = this.catFormData.name.trim();
				this.showToast('success', this.$t('admin.categories.toast.updateSuccess'), this.$t('admin.categories.toast.updateMsg', { old: oldName, new: this.catFormData.name.trim() }));
			} else {
				const newItem = this.editingCategory === 'skills'
					? { name: this.catFormData.name.trim(), count: 0 }
					: { name: this.catFormData.name.trim(), campaigns: 0 };
				list.unshift(newItem);
				this.showToast('success', this.$t('admin.categories.toast.addSuccess'), this.$t('admin.categories.toast.addMsg', { cat: label, name: this.catFormData.name.trim() }));
			}
			this.showFormModal = false;
		},
		confirmRemove(category, idx) {
			const list = this.getList(category);
			const label = this.getCategoryLabel(category);
			this.confirmConfig = {
				title: this.$t('admin.categories.delete.title', { cat: label }),
				message: this.$t('admin.categories.delete.message', { cat: label }),
				detail: list[idx].name
			};
			this.deleteAction = () => {
				const name = list[idx].name;
				list.splice(idx, 1);
				this.showToast('success', this.$t('admin.categories.toast.deleteSuccess'), this.$t('admin.categories.toast.deleteMsg', { cat: label, name: name }));
			};
			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		onConfirmDelete() {
			if (this.deleteAction) this.deleteAction();
			this.deleteAction = null;
		},
		showToast(type, title, message) {
			if (this.toast) this.toast[type](title, message);
		}
	}
}
</script>

<style scoped>
.cat-icon {
	width: 36px;
	height: 36px;
	min-width: 36px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 14px;
}

.category-item {
	transition: background 0.2s ease;
}

.category-item:hover {
	background: #f8f9fa;
}

.category-item:last-child {
	border-bottom: none !important;
}

.opacity-hover {
	opacity: 0.3;
	transition: opacity 0.2s ease;
}

.category-item:hover .opacity-hover {
	opacity: 1;
}
</style>
