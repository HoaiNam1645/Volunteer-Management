<template>
	<div class="admin-users">
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1">
					<i class="fa-solid fa-users text-primary me-2"></i>{{ $t('admin.userManagement.title') }}
				</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.userManagement.subtitle') }}</p>
			</div>
			<div class="d-flex align-items-center gap-2 flex-wrap">
				<router-link v-if="canViewPermissions" to="/admin/phan-quyen" class="btn btn-outline-primary rounded-pill px-4">
					<i class="fa-solid fa-shield-halved me-2"></i>{{ $t('admin.userManagement.permissionButton') }}
				</router-link>
				<button v-if="canManageUsers" class="btn btn-primary rounded-pill px-4" @click="openAddModal">
					<i class="fa-solid fa-user-plus me-2"></i>{{ $t('admin.userManagement.addUser') }}
				</button>
			</div>
		</div>

		<ul class="nav nav-tabs admin-tabs mb-4">
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'all' }" href="#" @click.prevent="setTab('all')">
					<i class="fa-solid fa-users me-1"></i>{{ $t('admin.userManagement.tabs.all') }}
					<span class="badge bg-primary ms-1">{{ stats.tong }}</span>
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'pending' }" href="#" @click.prevent="setTab('pending')">
					<i class="fa-solid fa-user-clock me-1"></i>{{ $t('admin.userManagement.tabs.pending') }}
					<span class="badge bg-warning text-dark ms-1">{{ stats.cho_duyet }}</span>
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'locked' }" href="#" @click.prevent="setTab('locked')">
					<i class="fa-solid fa-lock me-1"></i>{{ $t('admin.userManagement.tabs.locked') }}
					<span class="badge bg-danger ms-1">{{ stats.bi_khoa }}</span>
				</a>
			</li>
		</ul>

		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body py-3">
				<div class="row g-3 align-items-center">
					<div class="col-md-4">
						<div class="position-relative">
							<input
								v-model="searchQuery"
								type="text"
								class="form-control ps-5"
								:placeholder="$t('admin.userManagement.filter.searchPlaceholder')"
							>
							<i class="fa-solid fa-search position-absolute filter-icon"></i>
						</div>
					</div>
					<div class="col-md-3">
						<select v-model="filterRole" class="form-select">
							<option value="">{{ $t('admin.userManagement.filter.allRoles') }}</option>
							<option value="tinh_nguyen_vien">{{ $t('admin.userManagement.roles.volunteer') }}</option>
							<option value="kiem_duyet_vien">{{ $t('admin.userManagement.roles.coordinator') }}</option>
							<option value="quan_tri_vien">{{ $t('admin.userManagement.roles.admin') }}</option>
						</select>
					</div>
					<div class="col-md-3">
						<select v-model="filterStatus" class="form-select">
							<option value="">{{ $t('admin.userManagement.filter.allStatuses') }}</option>
							<option value="hoat_dong">{{ $t('admin.userManagement.statuses.active') }}</option>
							<option value="cho_duyet">{{ $t('admin.userManagement.statuses.pending') }}</option>
							<option value="bi_khoa">{{ $t('admin.userManagement.statuses.locked') }}</option>
						</select>
					</div>
					<div class="col-md-2 text-end">
						<button class="btn btn-outline-secondary btn-sm" @click="resetFilters">
							<i class="fa-solid fa-rotate-left me-1"></i>{{ $t('admin.userManagement.filter.reset') }}
						</button>
					</div>
				</div>
			</div>
		</div>

		<div class="card border-0 shadow-sm">
			<div class="card-body p-0">
				<div class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead class="table-light">
							<tr>
								<th class="ps-4">{{ $t('admin.userManagement.table.user') }}</th>
								<th>{{ $t('admin.userManagement.table.role') }}</th>
								<th>{{ $t('admin.userManagement.table.status') }}</th>
								<th>{{ $t('admin.userManagement.table.emailVerified') }}</th>
								<th>{{ $t('admin.userManagement.table.createdAt') }}</th>
								<th>{{ $t('admin.userManagement.table.campaigns') }}</th>
								<th class="text-center pe-4">{{ $t('admin.userManagement.table.actions') }}</th>
							</tr>
						</thead>
						<tbody v-if="users.length">
							<tr v-for="user in users" :key="user.id">
								<td class="ps-4">
									<div class="d-flex align-items-center gap-3">
										<div v-if="user.anh_dai_dien" class="user-table-avatar image-avatar">
											<img :src="user.anh_dai_dien" :alt="user.ho_ten">
										</div>
										<div v-else class="user-table-avatar" :style="{ background: user.color }">
											{{ getInitial(user.ho_ten) }}
										</div>
										<div>
											<h6 class="mb-0 small fw-bold">{{ user.ho_ten }}</h6>
											<span class="text-muted d-block" style="font-size: 12px;">{{ user.email }}</span>
											<span class="text-muted" style="font-size: 12px;">{{ user.so_dien_thoai || $t('admin.userManagement.table.noPhone') }}</span>
										</div>
									</div>
								</td>
								<td>
									<span class="badge rounded-pill" :class="getRoleBadgeClass(user.vai_tro)">
										<i :class="getRoleIcon(user.vai_tro)" class="me-1"></i>{{ getRoleLabel(user.vai_tro) }}
									</span>
								</td>
								<td>
									<span class="d-flex align-items-center gap-1">
										<span class="status-dot" :class="getStatusDotClass(user.trang_thai)"></span>
										<span class="small">{{ getStatusLabel(user.trang_thai) }}</span>
									</span>
								</td>
								<td>
									<span class="badge rounded-pill" :class="user.da_xac_thuc_email ? 'bg-success-subtle text-success' : 'bg-secondary-subtle text-secondary'">
										{{ user.da_xac_thuc_email ? $t('admin.userManagement.emailVerified.yes') : $t('admin.userManagement.emailVerified.no') }}
									</span>
								</td>
								<td><span class="text-muted small">{{ formatDateTime(user.tao_luc) }}</span></td>
								<td><span class="fw-bold small">{{ user.campaign_count }}</span></td>
								<td class="text-center pe-4">
									<div class="btn-group">
										<button class="btn btn-sm btn-outline-primary" :title="$t('admin.userManagement.actions.view')" @click="viewUser(user)">
											<i class="fa-solid fa-eye"></i>
										</button>
										<button v-if="canManageUsers" class="btn btn-sm btn-outline-secondary" :title="$t('admin.userManagement.actions.edit')" @click="openEditModal(user)">
											<i class="fa-solid fa-pen"></i>
										</button>
										<button
											v-if="canManageUsers && user.trang_thai === 'cho_duyet'"
											class="btn btn-sm btn-outline-success"
											:title="$t('admin.userManagement.actions.approve')"
											@click="confirmStatusChange(user, 'hoat_dong')"
										>
											<i class="fa-solid fa-check"></i>
										</button>
										<button
											v-if="canManageUsers && user.trang_thai === 'hoat_dong'"
											class="btn btn-sm btn-outline-warning"
											:title="$t('admin.userManagement.actions.lock')"
											@click="confirmStatusChange(user, 'bi_khoa')"
											:disabled="isSelf(user)"
										>
											<i class="fa-solid fa-lock"></i>
										</button>
										<button
											v-if="canManageUsers && user.trang_thai === 'bi_khoa'"
											class="btn btn-sm btn-outline-info"
											:title="$t('admin.userManagement.actions.unlock')"
											@click="confirmStatusChange(user, 'hoat_dong')"
										>
											<i class="fa-solid fa-lock-open"></i>
										</button>
										<button
											v-if="canManageUsers"
											class="btn btn-sm btn-outline-danger"
											:title="$t('admin.userManagement.actions.delete')"
											@click="confirmDelete(user)"
											:disabled="isSelf(user)"
										>
											<i class="fa-solid fa-trash"></i>
										</button>
									</div>
								</td>
							</tr>
						</tbody>
					</table>
				</div>

				<div class="text-center py-5" v-if="!loading && users.length === 0">
					<i class="fa-solid fa-users-slash text-muted" style="font-size: 48px;"></i>
					<p class="text-muted mt-3">{{ $t('admin.userManagement.emptyState') }}</p>
				</div>
				<div class="text-center py-5" v-if="loading">
					<div class="spinner-border text-primary" role="status"></div>
				</div>
			</div>

			<div class="card-footer bg-white border-top py-3" v-if="pagination.total > 0">
				<div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
					<span class="text-muted small">
						{{ $t('admin.userManagement.pagination.showing', { from: pagination.from, to: pagination.to, total: pagination.total }) }}
					</span>
					<nav>
						<ul class="pagination pagination-sm mb-0">
							<li class="page-item" :class="{ disabled: pagination.currentPage <= 1 }">
								<a class="page-link" href="#" @click.prevent="changePage(pagination.currentPage - 1)">«</a>
							</li>
							<li class="page-item" v-for="page in pages" :key="page" :class="{ active: page === pagination.currentPage }">
								<a class="page-link" href="#" @click.prevent="changePage(page)">{{ page }}</a>
							</li>
							<li class="page-item" :class="{ disabled: pagination.currentPage >= pagination.lastPage }">
								<a class="page-link" href="#" @click.prevent="changePage(pagination.currentPage + 1)">»</a>
							</li>
						</ul>
					</nav>
				</div>
			</div>
		</div>

		<div class="modal fade" :class="{ show: showFormModal }" :style="showFormModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered modal-lg">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold">
							<i :class="isEditing ? 'fa-solid fa-user-pen' : 'fa-solid fa-user-plus'" class="text-primary me-2"></i>
							{{ isEditing ? $t('admin.userManagement.modal.editUser') : $t('admin.userManagement.modal.addUser') }}
						</h5>
						<button type="button" class="btn-close" @click="closeFormModal"></button>
					</div>
					<div class="modal-body">
						<div class="row g-3">
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.fullName') }} <span class="text-danger">*</span></label>
								<input v-model="formData.ho_ten" type="text" class="form-control" :placeholder="$t('admin.userManagement.modal.fullNamePlaceholder')" :class="{ 'is-invalid': formErrors.ho_ten }">
								<div class="invalid-feedback">{{ formErrors.ho_ten }}</div>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.email') }} <span class="text-danger">*</span></label>
								<input v-model="formData.email" type="email" class="form-control" :placeholder="$t('admin.userManagement.modal.emailPlaceholder')" :class="{ 'is-invalid': formErrors.email }">
								<div class="invalid-feedback">{{ formErrors.email }}</div>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.phone') }}</label>
								<input v-model="formData.so_dien_thoai" type="text" class="form-control" :placeholder="$t('admin.userManagement.modal.phonePlaceholder')">
							</div>
							<div class="col-md-3">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.role') }} <span class="text-danger">*</span></label>
								<select v-if="!isEditing" v-model="formData.vai_tro" class="form-select">
									<option value="tinh_nguyen_vien">{{ $t('admin.userManagement.roles.volunteer') }}</option>
									<option value="kiem_duyet_vien">{{ $t('admin.userManagement.roles.coordinator') }}</option>
									<option value="quan_tri_vien">{{ $t('admin.userManagement.roles.admin') }}</option>
								</select>
								<input
									v-else
									:value="getRoleLabel(formData.vai_tro)"
									type="text"
									class="form-control"
									readonly
								>
							</div>
							<div class="col-md-3">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.status') }}</label>
								<select v-model="formData.trang_thai" class="form-select">
									<option value="hoat_dong">{{ $t('admin.userManagement.statuses.active') }}</option>
									<option value="cho_duyet">{{ $t('admin.userManagement.statuses.pending') }}</option>
									<option value="bi_khoa">{{ $t('admin.userManagement.statuses.locked') }}</option>
								</select>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">
									{{ isEditing ? $t('admin.userManagement.modal.passwordOptional') : $t('admin.userManagement.modal.password') }}
									<span class="text-danger" v-if="!isEditing">*</span>
								</label>
								<div class="position-relative">
									<input
										v-model="formData.mat_khau"
										:type="showPassword ? 'text' : 'password'"
										class="form-control pe-5"
										:placeholder="$t('admin.userManagement.modal.passwordPlaceholder')"
										:class="{ 'is-invalid': formErrors.mat_khau }"
									>
									<button type="button" class="btn btn-link position-absolute end-0 top-50 translate-middle-y text-muted pe-3" @click="showPassword = !showPassword">
										<i :class="showPassword ? 'fa-solid fa-eye-slash' : 'fa-solid fa-eye'"></i>
									</button>
								</div>
								<div class="invalid-feedback d-block" v-if="formErrors.mat_khau">{{ formErrors.mat_khau }}</div>
							</div>
							<div class="col-md-6">
								<div class="form-check form-switch mt-4 pt-2">
									<input id="xacThucEmail" v-model="formData.xac_thuc_email" class="form-check-input" type="checkbox">
									<label class="form-check-label fw-semibold" for="xacThucEmail">
										{{ $t('admin.userManagement.modal.emailVerified') }}
									</label>
								</div>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeFormModal">{{ $t('admin.userManagement.modal.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" :disabled="saving" @click="saveUser">
							<i :class="isEditing ? 'fa-solid fa-save' : 'fa-solid fa-plus'" class="me-1"></i>
							{{ isEditing ? $t('admin.userManagement.modal.update') : $t('admin.userManagement.modal.createAccount') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showFormModal" @click="closeFormModal"></div>

		<div class="modal fade" :class="{ show: showViewModal }" :style="showViewModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-user text-primary me-2"></i>{{ $t('admin.userManagement.viewModal.title') }}</h5>
						<button type="button" class="btn-close" @click="showViewModal = false"></button>
					</div>
					<div class="modal-body" v-if="viewingUser">
						<div class="text-center mb-4">
							<div v-if="viewingUser.anh_dai_dien" class="user-view-avatar mx-auto mb-3 image-avatar">
								<img :src="viewingUser.anh_dai_dien" :alt="viewingUser.ho_ten">
							</div>
							<div v-else class="user-view-avatar mx-auto mb-3" :style="{ background: viewingUser.color }">
								{{ getInitial(viewingUser.ho_ten) }}
							</div>
							<h5 class="fw-bold mb-1">{{ viewingUser.ho_ten }}</h5>
							<span class="text-muted small">{{ viewingUser.email }}</span>
						</div>
						<div class="row g-3">
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center h-100">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.table.role') }}</span>
									<span class="badge rounded-pill mt-1" :class="getRoleBadgeClass(viewingUser.vai_tro)">
										<i :class="getRoleIcon(viewingUser.vai_tro)" class="me-1"></i>{{ getRoleLabel(viewingUser.vai_tro) }}
									</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center h-100">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.table.status') }}</span>
									<span class="d-flex align-items-center justify-content-center gap-1 mt-1">
										<span class="status-dot" :class="getStatusDotClass(viewingUser.trang_thai)"></span>
										<span class="small fw-bold">{{ getStatusLabel(viewingUser.trang_thai) }}</span>
									</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center h-100">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.table.emailVerified') }}</span>
									<span class="fw-bold small">{{ viewingUser.da_xac_thuc_email ? $t('admin.userManagement.emailVerified.yes') : $t('admin.userManagement.emailVerified.no') }}</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center h-100">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.table.campaigns') }}</span>
									<span class="fw-bold small">{{ viewingUser.campaign_count }}</span>
								</div>
							</div>
							<div class="col-12">
								<div class="p-3 bg-light rounded-3">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.modal.phone') }}</span>
									<span class="fw-semibold small">{{ viewingUser.so_dien_thoai || $t('admin.userManagement.table.noPhone') }}</span>
								</div>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showViewModal = false">{{ $t('admin.userManagement.modal.close') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="showViewModal = false; openEditModal(viewingUser)">
							<i class="fa-solid fa-pen me-1"></i>{{ $t('admin.userManagement.actions.edit') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showViewModal" @click="showViewModal = false"></div>

		<ConfirmModal
			ref="confirmModal"
			:modalId="'userConfirmModal'"
			:title="confirmConfig.title"
			:message="confirmConfig.message"
			:detail="confirmConfig.detail"
			:icon="confirmConfig.icon"
			:variant="confirmConfig.variant"
			:confirmText="confirmConfig.confirmText"
			:confirmIcon="confirmConfig.confirmIcon"
			@confirm="onConfirmAction"
		/>
	</div>
</template>

<script>
import api from '../../services/api';
import ConfirmModal from '../../components/ConfirmModal.vue';
import { hasPermission } from '../../utils/permissions';

export default {
	name: 'QuanLyNguoiDung',
	components: { ConfirmModal },
	inject: ['toast'],
	data() {
		return {
			activeTab: 'all',
			searchQuery: '',
			filterRole: '',
			filterStatus: '',
			loading: false,
			saving: false,
			showFormModal: false,
			showViewModal: false,
			showPassword: false,
			isEditing: false,
			editingUserId: null,
			viewingUser: null,
			users: [],
			currentUser: null,
			currentUserId: null,
			stats: { tong: 0, cho_duyet: 0, bi_khoa: 0, hoat_dong: 0 },
			pagination: {
				currentPage: 1,
				lastPage: 1,
				perPage: 10,
				total: 0,
				from: 0,
				to: 0,
			},
			formData: {
				ho_ten: '',
				email: '',
				so_dien_thoai: '',
				vai_tro: 'tinh_nguyen_vien',
				trang_thai: 'hoat_dong',
				mat_khau: '',
				xac_thuc_email: true,
			},
			formErrors: {},
			confirmConfig: { title: '', message: '', detail: '', icon: '', variant: 'danger', confirmText: '', confirmIcon: '' },
			confirmAction: null,
			searchDebounce: null,
			suspendFilterWatch: false,
		};
	},
	computed: {
		canManageUsers() {
			return hasPermission(this.currentUser, 'user_management.manage');
		},
		canViewPermissions() {
			return hasPermission(this.currentUser, 'permission_management.view');
		},
		pages() {
			const total = this.pagination.lastPage || 1;
			const current = this.pagination.currentPage || 1;
			const start = Math.max(1, current - 2);
			const end = Math.min(total, start + 4);
			const pages = [];
			for (let page = start; page <= end; page += 1) {
				pages.push(page);
			}
			return pages;
		},
	},
	created() {
		this.loadCurrentUser();
		this.fetchUsers();
	},
	watch: {
		searchQuery() {
			clearTimeout(this.searchDebounce);
			this.searchDebounce = setTimeout(() => this.fetchUsers(1), 350);
		},
		filterRole() {
			if (this.suspendFilterWatch) return;
			this.fetchUsers(1);
		},
		filterStatus() {
			if (this.suspendFilterWatch) return;
			this.fetchUsers(1);
		},
	},
	beforeUnmount() {
		clearTimeout(this.searchDebounce);
	},
	methods: {
		getDefaultFormData() {
			return {
				ho_ten: '',
				email: '',
				so_dien_thoai: '',
				vai_tro: 'tinh_nguyen_vien',
				trang_thai: 'hoat_dong',
				mat_khau: '',
				xac_thuc_email: true,
			};
		},
		loadCurrentUser() {
			try {
				const currentUser = JSON.parse(localStorage.getItem('user') || 'null');
				this.currentUser = currentUser;
				this.currentUserId = currentUser?.id || null;
			} catch (_error) {
				this.currentUser = null;
				this.currentUserId = null;
			}
		},
		getInitial(name) {
			return (name || '?').trim().charAt(0).toUpperCase();
		},
		formatDateTime(value) {
			if (!value) return '--';
			return new Date(value).toLocaleDateString('vi-VN');
		},
		getRoleLabel(role) {
			return {
				tinh_nguyen_vien: this.$t('admin.userManagement.roles.volunteer'),
				kiem_duyet_vien: this.$t('admin.userManagement.roles.coordinator'),
				quan_tri_vien: this.$t('admin.userManagement.roles.admin'),
			}[role] || role;
		},
		getRoleIcon(role) {
			return {
				tinh_nguyen_vien: 'fa-solid fa-hand-holding-heart',
				kiem_duyet_vien: 'fa-solid fa-people-arrows',
				quan_tri_vien: 'fa-solid fa-shield-halved',
			}[role] || 'fa-solid fa-user';
		},
		getRoleBadgeClass(role) {
			return {
				tinh_nguyen_vien: 'bg-primary-subtle text-primary',
				kiem_duyet_vien: 'bg-success-subtle text-success',
				quan_tri_vien: 'bg-warning-subtle text-warning',
			}[role] || 'bg-secondary-subtle text-secondary';
		},
		getStatusLabel(status) {
			return {
				hoat_dong: this.$t('admin.userManagement.statuses.active'),
				cho_duyet: this.$t('admin.userManagement.statuses.pending'),
				bi_khoa: this.$t('admin.userManagement.statuses.locked'),
			}[status] || status;
		},
		getStatusDotClass(status) {
			return {
				hoat_dong: 'bg-success',
				cho_duyet: 'bg-warning',
				bi_khoa: 'bg-danger',
			}[status] || 'bg-secondary';
		},
		setTab(tab) {
			this.activeTab = tab;
			const nextStatus = tab === 'pending' ? 'cho_duyet' : (tab === 'locked' ? 'bi_khoa' : '');
			const shouldFetchManually = this.filterStatus === nextStatus;
			this.filterStatus = nextStatus;
			if (shouldFetchManually) this.fetchUsers(1);
		},
		changePage(page) {
			if (page < 1 || page > this.pagination.lastPage || page === this.pagination.currentPage) return;
			this.fetchUsers(page);
		},
		isSelf(user) {
			return user?.id === this.currentUserId;
		},
		async fetchUsers(page = this.pagination.currentPage) {
			this.loading = true;
			try {
				const params = {
					per_page: this.pagination.perPage,
					page,
				};

				if (this.searchQuery.trim()) params.tu_khoa = this.searchQuery.trim();
				if (this.filterRole) params.vai_tro = this.filterRole;
				if (this.filterStatus) params.trang_thai = this.filterStatus;

				const { data } = await api.get('/admin/nguoi-dung', { params });
				this.users = (data.data || []).map((user) => ({
					...user,
					color: this.colorFromText(user.ho_ten),
				}));
				this.stats = data.meta?.stats || this.stats;
				this.pagination = {
					currentPage: data.current_page || 1,
					lastPage: data.last_page || 1,
					perPage: data.per_page || this.pagination.perPage,
					total: data.total || 0,
					from: data.total ? ((data.current_page - 1) * data.per_page) + 1 : 0,
					to: data.total ? Math.min(data.current_page * data.per_page, data.total) : 0,
				};
			} catch (error) {
				this.showToast('error', this.$t('admin.userManagement.toast.loadErrorTitle'), error.response?.data?.message || this.$t('admin.userManagement.toast.loadErrorMessage'));
			} finally {
				this.loading = false;
			}
		},
		colorFromText(text) {
			const colors = ['#0d6efd', '#198754', '#dc3545', '#6f42c1', '#fd7e14', '#20c997', '#e83e8c', '#17a2b8', '#795548'];
			const hash = Array.from(text || '').reduce((total, char) => total + char.charCodeAt(0), 0);
			return colors[hash % colors.length];
		},
		openAddModal() {
			this.isEditing = false;
			this.editingUserId = null;
			this.formData = this.getDefaultFormData();
			this.formErrors = {};
			this.showPassword = false;
			this.showFormModal = true;
		},
		openEditModal(user) {
			this.isEditing = true;
			this.editingUserId = user.id;
			this.formData = {
				ho_ten: user.ho_ten,
				email: user.email,
				so_dien_thoai: user.so_dien_thoai || '',
				vai_tro: user.vai_tro,
				trang_thai: user.trang_thai,
				mat_khau: '',
				xac_thuc_email: !!user.da_xac_thuc_email,
			};
			this.formErrors = {};
			this.showPassword = false;
			this.showFormModal = true;
		},
		closeFormModal() {
			this.showFormModal = false;
			this.formErrors = {};
		},
		viewUser(user) {
			this.viewingUser = user;
			this.showViewModal = true;
		},
		async saveUser() {
			this.saving = true;
			this.formErrors = {};
			try {
				const payload = { ...this.formData };
				if (!payload.mat_khau) delete payload.mat_khau;
				if (this.isEditing) delete payload.vai_tro;

				if (this.isEditing) {
					await api.put(`/admin/nguoi-dung/${this.editingUserId}`, payload);
					this.showToast('success', this.$t('admin.userManagement.toast.updateSuccessTitle'), this.$t('admin.userManagement.toast.updateSuccessMessage', { name: this.formData.ho_ten }));
				} else {
					await api.post('/admin/nguoi-dung', payload);
					this.showToast('success', this.$t('admin.userManagement.toast.createSuccessTitle'), this.$t('admin.userManagement.toast.createSuccessMessage', { name: this.formData.ho_ten }));
				}

				this.closeFormModal();
				this.fetchUsers(this.pagination.currentPage);
			} catch (error) {
				if (error.response?.status === 422 && error.response?.data?.errors) {
					this.formErrors = Object.fromEntries(
						Object.entries(error.response.data.errors).map(([key, value]) => [key, value[0]])
					);
				} else {
					this.showToast('error', this.$t('admin.userManagement.toast.saveErrorTitle'), error.response?.data?.message || this.$t('admin.userManagement.toast.saveErrorMessage'));
				}
			} finally {
				this.saving = false;
			}
		},
		confirmStatusChange(user, status) {
			const isLock = status === 'bi_khoa';
			const isApprove = status === 'hoat_dong' && user.trang_thai === 'cho_duyet';
			const isUnlock = status === 'hoat_dong' && user.trang_thai === 'bi_khoa';

			this.confirmConfig = {
				title: isApprove
					? this.$t('admin.userManagement.confirm.approveTitle')
					: (isLock ? this.$t('admin.userManagement.confirm.lockTitle') : this.$t('admin.userManagement.confirm.unlockTitle')),
				message: isApprove
					? this.$t('admin.userManagement.confirm.approveMessage')
					: (isLock ? this.$t('admin.userManagement.confirm.lockMessage') : this.$t('admin.userManagement.confirm.unlockMessage')),
				detail: user.ho_ten,
				icon: isApprove ? 'fa-solid fa-user-check' : (isLock ? 'fa-solid fa-lock' : 'fa-solid fa-lock-open'),
				variant: isApprove ? 'success' : (isLock ? 'warning' : 'info'),
				confirmText: isApprove
					? this.$t('admin.userManagement.actions.approve')
					: (isLock ? this.$t('admin.userManagement.actions.lock') : this.$t('admin.userManagement.actions.unlock')),
				confirmIcon: isApprove ? 'fa-solid fa-check' : (isLock ? 'fa-solid fa-lock' : 'fa-solid fa-lock-open'),
			};

			this.confirmAction = async () => {
				try {
					await api.put(`/admin/nguoi-dung/${user.id}/trang-thai`, { trang_thai: status });
					this.showToast(
						isApprove ? 'success' : (isLock ? 'warning' : 'info'),
						isApprove
							? this.$t('admin.userManagement.toast.approveSuccessTitle')
							: (isLock ? this.$t('admin.userManagement.toast.lockSuccessTitle') : this.$t('admin.userManagement.toast.unlockSuccessTitle')),
						isApprove
							? this.$t('admin.userManagement.toast.approveSuccessMessage', { name: user.ho_ten })
							: (isLock ? this.$t('admin.userManagement.toast.lockSuccessMessage', { name: user.ho_ten }) : this.$t('admin.userManagement.toast.unlockSuccessMessage', { name: user.ho_ten }))
					);
					this.fetchUsers(this.pagination.currentPage);
				} catch (error) {
					this.showToast('error', this.$t('admin.userManagement.toast.saveErrorTitle'), error.response?.data?.message || this.$t('admin.userManagement.toast.saveErrorMessage'));
				}
			};

			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		confirmDelete(user) {
			this.confirmConfig = {
				title: this.$t('admin.userManagement.confirm.deleteTitle'),
				message: this.$t('admin.userManagement.confirm.deleteMessage'),
				detail: user.ho_ten,
				icon: 'fa-solid fa-trash',
				variant: 'danger',
				confirmText: this.$t('admin.userManagement.actions.delete'),
				confirmIcon: 'fa-solid fa-trash',
			};

			this.confirmAction = async () => {
				try {
					await api.delete(`/admin/nguoi-dung/${user.id}`);
					this.showToast('success', this.$t('admin.userManagement.toast.deleteSuccessTitle'), this.$t('admin.userManagement.toast.deleteSuccessMessage', { name: user.ho_ten }));
					const nextPage = this.users.length === 1 && this.pagination.currentPage > 1
						? this.pagination.currentPage - 1
						: this.pagination.currentPage;
					this.fetchUsers(nextPage);
				} catch (error) {
					this.showToast('error', this.$t('admin.userManagement.toast.saveErrorTitle'), error.response?.data?.message || this.$t('admin.userManagement.toast.saveErrorMessage'));
				}
			};

			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		onConfirmAction() {
			if (this.confirmAction) this.confirmAction();
			this.confirmAction = null;
		},
		resetFilters() {
			clearTimeout(this.searchDebounce);
			this.suspendFilterWatch = true;
			this.activeTab = 'all';
			this.searchQuery = '';
			this.filterRole = '';
			this.filterStatus = '';
			this.$nextTick(() => {
				this.suspendFilterWatch = false;
				this.fetchUsers(1);
			});
		},
		showToast(type, title, message) {
			this.toast?.showToast?.(type, title, message);
		},
	},
};
</script>

<style scoped>
.admin-tabs .nav-link {
	border: none;
	color: #6c757d;
	font-weight: 500;
	font-size: 14px;
	padding: 10px 16px;
	border-bottom: 2px solid transparent;
	transition: all 0.2s ease;
}

.admin-tabs .nav-link:hover {
	color: #0d6efd;
}

.admin-tabs .nav-link.active {
	color: #0d6efd;
	border-bottom-color: #0d6efd;
	background: transparent;
}

.filter-icon {
	left: 16px;
	top: 50%;
	transform: translateY(-50%);
	color: #adb5bd;
}

.user-table-avatar {
	width: 38px;
	height: 38px;
	min-width: 38px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 15px;
	overflow: hidden;
}

.user-view-avatar {
	width: 70px;
	height: 70px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 28px;
	overflow: hidden;
}

.image-avatar img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.status-dot {
	width: 8px;
	height: 8px;
	border-radius: 50%;
	display: inline-block;
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
	vertical-align: middle;
	font-size: 14px;
}
</style>
