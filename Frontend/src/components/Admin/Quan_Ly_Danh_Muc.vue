<template>
	<div class="admin-categories">
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-layer-group text-primary me-2"></i>{{ $t('admin.categories.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.categories.subtitle') }}</p>
			</div>
		</div>

		<div class="row g-4">
			<div class="col-lg-4">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3">
						<div class="d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-tools text-primary me-2"></i>{{ $t('admin.categories.skills.title') }}</h6>
							<button v-if="canManageCategories" class="btn btn-primary btn-sm rounded-pill px-3" @click="openAddModal('ky-nang')">
								<i class="fa-solid fa-plus"></i>
							</button>
						</div>
						<input v-model="searchSkills" type="text" class="form-control form-control-sm mt-2" :placeholder="$t('admin.categories.skills.search')">
					</div>
					<div class="card-body p-0 scroll-body">
						<div class="category-item d-flex align-items-start gap-3 px-3 py-3 border-bottom" v-for="skill in filteredSkills" :key="skill.id">
							<div class="cat-icon bg-primary-subtle text-primary">
								<i :class="skill.bieu_tuong || 'fa-solid fa-wrench'"></i>
							</div>
							<div class="flex-grow-1 min-w-0">
								<div class="d-flex align-items-center justify-content-between gap-2 mb-1">
									<p class="mb-0 small fw-bold text-truncate">{{ skill.ten }}</p>
									<span class="badge rounded-pill" :class="skill.hoat_dong ? 'bg-success-subtle text-success' : 'bg-secondary-subtle text-secondary'">
										{{ skill.hoat_dong ? $t('admin.categories.common.active') : $t('admin.categories.common.inactive') }}
									</span>
								</div>
								<p class="text-muted mb-1 small" v-if="skill.mo_ta">{{ skill.mo_ta }}</p>
								<span class="text-muted meta-text">
									{{ $t('admin.categories.skills.usersCount', { count: skill.nguoi_dung_count }) }} •
									{{ $t('admin.categories.skills.campaignsCount', { count: skill.chien_dich_count }) }}
								</span>
							</div>
							<div v-if="canManageCategories" class="btn-group btn-group-sm opacity-hover">
								<button class="btn btn-outline-secondary btn-sm" @click="openEditModal('ky-nang', skill)">
									<i class="fa-solid fa-pen"></i>
								</button>
								<button class="btn btn-outline-danger btn-sm" @click="confirmRemove('ky-nang', skill)">
									<i class="fa-solid fa-trash"></i>
								</button>
							</div>
						</div>
						<div class="text-center py-4 text-muted small" v-if="!loading && filteredSkills.length === 0">
							<i class="fa-solid fa-inbox d-block mb-2" style="font-size: 28px;"></i>
							{{ $t('admin.categories.skills.notFound') }}
						</div>
						<div class="text-center py-4" v-if="loading">
							<div class="spinner-border text-primary" role="status"></div>
						</div>
					</div>
					<div class="card-footer bg-white text-center py-2 border-top">
						<span class="text-muted small">{{ $t('admin.categories.skills.total', { count: skills.length }) }}</span>
					</div>
				</div>
			</div>

			<div class="col-lg-4">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3">
						<div class="d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-map-location-dot text-success me-2"></i>{{ $t('admin.categories.regions.title') }}</h6>
							<button v-if="canManageCategories" class="btn btn-success btn-sm rounded-pill px-3" @click="openAddModal('khu-vuc')">
								<i class="fa-solid fa-plus"></i>
							</button>
						</div>
						<input v-model="searchRegions" type="text" class="form-control form-control-sm mt-2" :placeholder="$t('admin.categories.regions.search')">
					</div>
					<div class="card-body p-0 scroll-body">
						<div class="category-item d-flex align-items-start gap-3 px-3 py-3 border-bottom" v-for="region in filteredRegions" :key="region.id">
							<div class="cat-icon bg-success-subtle text-success">
								<i class="fa-solid fa-location-dot"></i>
							</div>
							<div class="flex-grow-1 min-w-0">
								<div class="d-flex align-items-center justify-content-between gap-2 mb-1">
									<p class="mb-0 small fw-bold text-truncate">{{ region.ten }}</p>
									<span class="badge rounded-pill" :class="region.hoat_dong ? 'bg-success-subtle text-success' : 'bg-secondary-subtle text-secondary'">
										{{ region.hoat_dong ? $t('admin.categories.common.active') : $t('admin.categories.common.inactive') }}
									</span>
								</div>
								<p class="text-muted mb-1 small">
									{{ formatCoordinates(region.vi_do, region.kinh_do) }}
								</p>
								<span class="text-muted meta-text">
									{{ $t('admin.categories.regions.usersCount', { count: region.nguoi_dung_count }) }} •
									{{ $t('admin.categories.regions.campaignsCount', { count: region.chien_dich_count }) }}
								</span>
							</div>
							<div v-if="canManageCategories" class="btn-group btn-group-sm opacity-hover">
								<button class="btn btn-outline-secondary btn-sm" @click="openEditModal('khu-vuc', region)">
									<i class="fa-solid fa-pen"></i>
								</button>
								<button class="btn btn-outline-danger btn-sm" @click="confirmRemove('khu-vuc', region)">
									<i class="fa-solid fa-trash"></i>
								</button>
							</div>
						</div>
						<div class="text-center py-4 text-muted small" v-if="!loading && filteredRegions.length === 0">
							<i class="fa-solid fa-inbox d-block mb-2" style="font-size: 28px;"></i>
							{{ $t('admin.categories.regions.notFound') }}
						</div>
						<div class="text-center py-4" v-if="loading">
							<div class="spinner-border text-success" role="status"></div>
						</div>
					</div>
					<div class="card-footer bg-white text-center py-2 border-top">
						<span class="text-muted small">{{ $t('admin.categories.regions.total', { count: regions.length }) }}</span>
					</div>
				</div>
			</div>

			<div class="col-lg-4">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-header bg-white border-bottom py-3">
						<div class="d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-tags text-warning me-2"></i>{{ $t('admin.categories.types.title') }}</h6>
							<button v-if="canManageCategories" class="btn btn-warning btn-sm rounded-pill px-3 text-dark" @click="openAddModal('loai-chien-dich')">
								<i class="fa-solid fa-plus"></i>
							</button>
						</div>
						<input v-model="searchTypes" type="text" class="form-control form-control-sm mt-2" :placeholder="$t('admin.categories.types.search')">
					</div>
					<div class="card-body p-0 scroll-body">
						<div class="category-item d-flex align-items-start gap-3 px-3 py-3 border-bottom" v-for="type in filteredTypes" :key="type.id">
							<div class="cat-icon text-white" :style="{ background: type.mau_sac || '#f59f00' }">
								<i :class="type.bieu_tuong || 'fa-solid fa-tag'"></i>
							</div>
							<div class="flex-grow-1 min-w-0">
								<div class="d-flex align-items-center justify-content-between gap-2 mb-1">
									<p class="mb-0 small fw-bold text-truncate">{{ type.ten }}</p>
									<span class="badge rounded-pill" :class="type.hoat_dong ? 'bg-success-subtle text-success' : 'bg-secondary-subtle text-secondary'">
										{{ type.hoat_dong ? $t('admin.categories.common.active') : $t('admin.categories.common.inactive') }}
									</span>
								</div>
								<p class="text-muted mb-1 small">{{ type.bieu_tuong || $t('admin.categories.common.noIcon') }}</p>
								<span class="text-muted meta-text">{{ $t('admin.categories.types.campaignsCount', { count: type.chien_dich_count }) }}</span>
							</div>
							<div v-if="canManageCategories" class="btn-group btn-group-sm opacity-hover">
								<button class="btn btn-outline-secondary btn-sm" @click="openEditModal('loai-chien-dich', type)">
									<i class="fa-solid fa-pen"></i>
								</button>
								<button class="btn btn-outline-danger btn-sm" @click="confirmRemove('loai-chien-dich', type)">
									<i class="fa-solid fa-trash"></i>
								</button>
							</div>
						</div>
						<div class="text-center py-4 text-muted small" v-if="!loading && filteredTypes.length === 0">
							<i class="fa-solid fa-inbox d-block mb-2" style="font-size: 28px;"></i>
							{{ $t('admin.categories.types.notFound') }}
						</div>
						<div class="text-center py-4" v-if="loading">
							<div class="spinner-border text-warning" role="status"></div>
						</div>
					</div>
					<div class="card-footer bg-white text-center py-2 border-top">
						<span class="text-muted small">{{ $t('admin.categories.types.total', { count: types.length }) }}</span>
					</div>
				</div>
			</div>
		</div>

		<div class="modal fade" :class="{ show: showFormModal }" :style="showFormModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold">
							<i :class="getCategoryModalIcon()" class="me-2"></i>
							{{ isEditing ? $t('admin.categories.form.editTitle', { cat: getCategoryLabel(editingCategory) }) : $t('admin.categories.form.addTitle', { cat: getCategoryLabel(editingCategory) }) }}
						</h5>
						<button type="button" class="btn-close" @click="closeModal"></button>
					</div>
					<div class="modal-body">
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('admin.categories.form.nameLabel', { cat: getCategoryLabel(editingCategory) }) }} <span class="text-danger">*</span></label>
							<input v-model="catFormData.ten" type="text" class="form-control" :placeholder="$t('admin.categories.form.namePlaceholder', { cat: getCategoryLabel(editingCategory).toLowerCase() })" :class="{ 'is-invalid': catFormErrors.ten }">
							<div class="invalid-feedback">{{ catFormErrors.ten }}</div>
						</div>

						<div class="mb-3" v-if="editingCategory === 'ky-nang' || editingCategory === 'loai-chien-dich'">
							<label class="form-label small fw-bold">{{ $t('admin.categories.form.iconLabel') }}</label>
							<input v-model="catFormData.bieu_tuong" type="text" class="form-control" :placeholder="$t('admin.categories.form.iconPlaceholder')">
						</div>

						<div class="mb-3" v-if="editingCategory === 'ky-nang'">
							<label class="form-label small fw-bold">{{ $t('admin.categories.form.descriptionLabel') }}</label>
							<textarea v-model="catFormData.mo_ta" class="form-control" rows="3" :placeholder="$t('admin.categories.form.descriptionPlaceholder')"></textarea>
						</div>

						<div class="row g-3" v-if="editingCategory === 'khu-vuc'">
							<div class="col-6">
								<label class="form-label small fw-bold">{{ $t('admin.categories.form.latitudeLabel') }}</label>
								<input v-model="catFormData.vi_do" type="number" step="0.0000001" class="form-control" :placeholder="$t('admin.categories.form.latitudePlaceholder')">
							</div>
							<div class="col-6">
								<label class="form-label small fw-bold">{{ $t('admin.categories.form.longitudeLabel') }}</label>
								<input v-model="catFormData.kinh_do" type="number" step="0.0000001" class="form-control" :placeholder="$t('admin.categories.form.longitudePlaceholder')">
							</div>
						</div>

						<div class="mb-3" v-if="editingCategory === 'loai-chien-dich'">
							<label class="form-label small fw-bold">{{ $t('admin.categories.form.colorLabel') }}</label>
							<div class="d-flex gap-2 align-items-center">
								<input v-model="catFormData.mau_sac" type="color" class="form-control form-control-color">
								<input v-model="catFormData.mau_sac" type="text" class="form-control" :placeholder="$t('admin.categories.form.colorPlaceholder')">
							</div>
						</div>

						<div class="form-check form-switch mt-3">
							<input id="categoryActive" v-model="catFormData.hoat_dong" class="form-check-input" type="checkbox">
							<label class="form-check-label fw-semibold" for="categoryActive">{{ $t('admin.categories.form.activeLabel') }}</label>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeModal">{{ $t('admin.categories.form.cancelBtn') }}</button>
						<button v-if="canManageCategories" type="button" class="btn rounded-pill px-4" :class="getCategorySaveClass()" @click="saveCategoryItem">
							<i :class="isEditing ? 'fa-solid fa-save' : 'fa-solid fa-plus'" class="me-1"></i>
							{{ isEditing ? $t('admin.categories.form.updateBtn') : $t('admin.categories.form.addBtn') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showFormModal" @click="closeModal"></div>

		<ConfirmModal
			ref="confirmModal"
			:modalId="'catConfirmModal'"
			:title="confirmConfig.title"
			:message="confirmConfig.message"
			:detail="confirmConfig.detail"
			:icon="'fa-solid fa-trash'"
			:variant="'danger'"
			:confirmText="$t('admin.categories.delete.confirmBtn')"
			:confirmIcon="'fa-solid fa-trash'"
			@confirm="onConfirmDelete"
		/>
	</div>
</template>

<script>
import api from '../../services/api';
import ConfirmModal from '../../components/ConfirmModal.vue';
import { hasPermission } from '../../utils/permissions';

export default {
	name: 'QuanLyDanhMuc',
	components: { ConfirmModal },
	inject: ['toast'],
	data() {
		return {
			currentUser: null,
			searchSkills: '',
			searchRegions: '',
			searchTypes: '',
			showFormModal: false,
			isEditing: false,
			editingCategory: 'ky-nang',
			editingItemId: null,
			loading: false,
			confirmConfig: { title: '', message: '', detail: '' },
			deleteAction: null,
			catFormErrors: {},
			catFormData: {
				ten: '',
				bieu_tuong: '',
				mo_ta: '',
				vi_do: '',
				kinh_do: '',
				mau_sac: '#f59f00',
				hoat_dong: true,
			},
			skills: [],
			regions: [],
			types: [],
		};
	},
	computed: {
		canManageCategories() {
			return hasPermission(this.currentUser, 'category_management.manage');
		},
		filteredSkills() {
			if (!this.searchSkills) return this.skills;
			return this.skills.filter((item) => item.ten.toLowerCase().includes(this.searchSkills.toLowerCase()));
		},
		filteredRegions() {
			if (!this.searchRegions) return this.regions;
			return this.regions.filter((item) => item.ten.toLowerCase().includes(this.searchRegions.toLowerCase()));
		},
		filteredTypes() {
			if (!this.searchTypes) return this.types;
			return this.types.filter((item) => item.ten.toLowerCase().includes(this.searchTypes.toLowerCase()));
		},
	},
	created() {
		this.loadCurrentUser();
		this.fetchCategories();
	},
	methods: {
		loadCurrentUser() {
			try {
				this.currentUser = JSON.parse(localStorage.getItem('user') || 'null');
			} catch (_error) {
				this.currentUser = null;
			}
		},
		defaultCategoryData() {
			return {
				ten: '',
				bieu_tuong: '',
				mo_ta: '',
				vi_do: '',
				kinh_do: '',
				mau_sac: '#f59f00',
				hoat_dong: true,
			};
		},
		getCategoryLabel(cat) {
			return {
				'ky-nang': this.$t('admin.categories.skills.label'),
				'khu-vuc': this.$t('admin.categories.regions.label'),
				'loai-chien-dich': this.$t('admin.categories.types.label'),
			}[cat] || '';
		},
		getCategoryModalIcon() {
			return {
				'ky-nang': 'fa-solid fa-tools text-primary',
				'khu-vuc': 'fa-solid fa-map-location-dot text-success',
				'loai-chien-dich': 'fa-solid fa-tags text-warning',
			}[this.editingCategory] || '';
		},
		getCategorySaveClass() {
			return {
				'ky-nang': 'btn-primary',
				'khu-vuc': 'btn-success',
				'loai-chien-dich': 'btn-warning text-dark',
			}[this.editingCategory] || 'btn-primary';
		},
		formatCoordinates(lat, lng) {
			if (lat === null || lat === undefined || lng === null || lng === undefined || lat === '' || lng === '') {
				return this.$t('admin.categories.regions.noCoordinates');
			}
			return `${lat}, ${lng}`;
		},
		async fetchCategories() {
			this.loading = true;
			try {
				const { data } = await api.get('/admin/danh-muc');
				this.skills = data.data?.ky_nangs || [];
				this.regions = data.data?.khu_vucs || [];
				this.types = data.data?.loai_chien_dichs || [];
			} catch (error) {
				this.showToast('error', this.$t('admin.categories.toast.loadErrorTitle'), error.response?.data?.message || this.$t('admin.categories.toast.loadErrorMessage'));
			} finally {
				this.loading = false;
			}
		},
		openAddModal(category) {
			this.isEditing = false;
			this.editingCategory = category;
			this.editingItemId = null;
			this.catFormData = this.defaultCategoryData();
			this.catFormErrors = {};
			this.showFormModal = true;
		},
		openEditModal(category, item) {
			this.isEditing = true;
			this.editingCategory = category;
			this.editingItemId = item.id;
			this.catFormData = {
				ten: item.ten,
				bieu_tuong: item.bieu_tuong || '',
				mo_ta: item.mo_ta || '',
				vi_do: item.vi_do ?? '',
				kinh_do: item.kinh_do ?? '',
				mau_sac: item.mau_sac || '#f59f00',
				hoat_dong: !!item.hoat_dong,
			};
			this.catFormErrors = {};
			this.showFormModal = true;
		},
		closeModal() {
			this.showFormModal = false;
			this.catFormErrors = {};
		},
		async saveCategoryItem() {
			this.catFormErrors = {};
			try {
				const payload = {
					ten: this.catFormData.ten,
					hoat_dong: !!this.catFormData.hoat_dong,
				};

				if (this.editingCategory === 'ky-nang') {
					payload.bieu_tuong = this.catFormData.bieu_tuong || null;
					payload.mo_ta = this.catFormData.mo_ta || null;
				}

				if (this.editingCategory === 'khu-vuc') {
					payload.vi_do = this.catFormData.vi_do === '' ? null : this.catFormData.vi_do;
					payload.kinh_do = this.catFormData.kinh_do === '' ? null : this.catFormData.kinh_do;
				}

				if (this.editingCategory === 'loai-chien-dich') {
					payload.bieu_tuong = this.catFormData.bieu_tuong || null;
					payload.mau_sac = this.catFormData.mau_sac || null;
				}

				if (this.isEditing) {
					await api.put(`/admin/danh-muc/${this.editingCategory}/${this.editingItemId}`, payload);
					this.showToast('success', this.$t('admin.categories.toast.updateSuccess'), this.$t('admin.categories.toast.updateMsg', { name: payload.ten }));
				} else {
					await api.post(`/admin/danh-muc/${this.editingCategory}`, payload);
					this.showToast('success', this.$t('admin.categories.toast.addSuccess'), this.$t('admin.categories.toast.addMsg', { cat: this.getCategoryLabel(this.editingCategory), name: payload.ten }));
				}

				this.closeModal();
				this.fetchCategories();
			} catch (error) {
				if (error.response?.status === 422 && error.response?.data?.errors) {
					this.catFormErrors = Object.fromEntries(
						Object.entries(error.response.data.errors).map(([key, value]) => [key, value[0]])
					);
				} else {
					this.showToast('error', this.$t('admin.categories.toast.saveErrorTitle'), error.response?.data?.message || this.$t('admin.categories.toast.saveErrorMessage'));
				}
			}
		},
		confirmRemove(category, item) {
			const label = this.getCategoryLabel(category);
			this.confirmConfig = {
				title: this.$t('admin.categories.delete.title', { cat: label }),
				message: this.$t('admin.categories.delete.message', { cat: label }),
				detail: item.ten,
			};
			this.deleteAction = async () => {
				try {
					await api.delete(`/admin/danh-muc/${category}/${item.id}`);
					this.showToast('success', this.$t('admin.categories.toast.deleteSuccess'), this.$t('admin.categories.toast.deleteMsg', { cat: label, name: item.ten }));
					this.fetchCategories();
				} catch (error) {
					this.showToast('warning', this.$t('admin.categories.toast.deleteBlockedTitle'), error.response?.data?.message || this.$t('admin.categories.toast.deleteBlockedMessage'));
				}
			};
			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		onConfirmDelete() {
			if (this.deleteAction) this.deleteAction();
			this.deleteAction = null;
		},
		showToast(type, title, message) {
			this.toast?.showToast?.(type, title, message);
		},
	},
};
</script>

<style scoped>
.scroll-body {
	max-height: 460px;
	overflow-y: auto;
}

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

.meta-text {
	font-size: 11px;
}

.min-w-0 {
	min-width: 0;
}
</style>
