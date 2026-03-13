<template>
	<div class="admin-users">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-users text-primary me-2"></i>{{ $t('admin.userManagement.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.userManagement.subtitle') }}</p>
			</div>
			<button class="btn btn-primary rounded-pill px-4" @click="openAddModal">
				<i class="fa-solid fa-user-plus me-2"></i>{{ $t('admin.userManagement.addUser') }}
			</button>
		</div>

		<!-- Tab Navigation -->
		<ul class="nav nav-tabs admin-tabs mb-4">
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'all' }" href="#" @click.prevent="activeTab = 'all'">
					<i class="fa-solid fa-users me-1"></i>{{ $t('admin.userManagement.tabs.all') }} <span class="badge bg-primary ms-1">{{ allUsers.length }}</span>
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'pending' }" href="#" @click.prevent="activeTab = 'pending'">
					<i class="fa-solid fa-user-clock me-1"></i>{{ $t('admin.userManagement.tabs.pending') }} <span class="badge bg-warning text-dark ms-1">{{ pendingUsers.length }}</span>
				</a>
			</li>
			<li class="nav-item">
				<a class="nav-link" :class="{ active: activeTab === 'locked' }" href="#" @click.prevent="activeTab = 'locked'">
					<i class="fa-solid fa-lock me-1"></i>{{ $t('admin.userManagement.tabs.locked') }} <span class="badge bg-danger ms-1">{{ lockedUsers.length }}</span>
				</a>
			</li>
		</ul>

		<!-- Filter Bar -->
		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body py-3">
				<div class="row g-3 align-items-center">
					<div class="col-md-4">
						<div class="position-relative">
							<input type="text" class="form-control ps-5" :placeholder="$t('admin.userManagement.filter.searchPlaceholder')" v-model="searchQuery">
							<i class="fa-solid fa-search position-absolute" style="left: 16px; top: 50%; transform: translateY(-50%); color: #adb5bd;"></i>
						</div>
					</div>
					<div class="col-md-3">
						<select class="form-select" v-model="filterRole">
							<option value="">{{ $t('admin.userManagement.filter.allRoles') }}</option>
							<option value="volunteer">{{ $t('admin.userManagement.roles.volunteer') }}</option>
							<option value="coordinator">{{ $t('admin.userManagement.roles.coordinator') }}</option>
							<option value="admin">{{ $t('admin.userManagement.roles.admin') }}</option>
						</select>
					</div>
					<div class="col-md-3">
						<select class="form-select" v-model="filterStatus">
							<option value="">{{ $t('admin.userManagement.filter.allStatuses') }}</option>
							<option value="active">{{ $t('admin.userManagement.statuses.active') }}</option>
							<option value="pending">{{ $t('admin.userManagement.statuses.pending') }}</option>
							<option value="locked">{{ $t('admin.userManagement.statuses.locked') }}</option>
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

		<!-- Users Table -->
		<div class="card border-0 shadow-sm">
			<div class="card-body p-0">
				<div class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead class="table-light">
							<tr>
								<th class="ps-4" style="width: 40px;">
									<input class="form-check-input" type="checkbox">
								</th>
								<th>{{ $t('admin.userManagement.table.user') }}</th>
								<th>{{ $t('admin.userManagement.table.role') }}</th>
								<th>{{ $t('admin.userManagement.table.status') }}</th>
								<th>{{ $t('admin.userManagement.table.createdAt') }}</th>
								<th>{{ $t('admin.userManagement.table.campaigns') }}</th>
								<th class="text-center">{{ $t('admin.userManagement.table.actions') }}</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="user in filteredUsers" :key="user.id">
								<td class="ps-4">
									<input class="form-check-input" type="checkbox">
								</td>
								<td>
									<div class="d-flex align-items-center gap-3">
										<div class="user-table-avatar" :style="{ background: user.color }">
											{{ user.name.charAt(0) }}
										</div>
										<div>
											<h6 class="mb-0 small fw-bold">{{ user.name }}</h6>
											<span class="text-muted" style="font-size: 12px;">{{ user.email }}</span>
										</div>
									</div>
								</td>
								<td>
									<span class="badge rounded-pill" :class="getRoleBadgeClass(user.role)">
										<i :class="getRoleIcon(user.role)" class="me-1"></i>{{ getRoleLabel(user.role) }}
									</span>
								</td>
								<td>
									<span class="d-flex align-items-center gap-1">
										<span class="status-dot" :class="getStatusDotClass(user.status)"></span>
										<span class="small">{{ getStatusLabel(user.status) }}</span>
									</span>
								</td>
								<td><span class="text-muted small">{{ user.createdAt }}</span></td>
								<td><span class="fw-bold small">{{ user.campaigns }}</span></td>
								<td class="text-center">
									<div class="btn-group">
										<button class="btn btn-sm btn-outline-primary" :title="$t('admin.userManagement.actions.view')" @click="viewUser(user)">
											<i class="fa-solid fa-eye"></i>
										</button>
										<button class="btn btn-sm btn-outline-secondary" :title="$t('admin.userManagement.actions.edit')" @click="openEditModal(user)">
											<i class="fa-solid fa-pen"></i>
										</button>
										<button v-if="user.status === 'pending'" class="btn btn-sm btn-outline-success" :title="$t('admin.userManagement.actions.approve')" @click="confirmApprove(user)">
											<i class="fa-solid fa-check"></i>
										</button>
										<button v-if="user.status === 'active'" class="btn btn-sm btn-outline-warning" :title="$t('admin.userManagement.actions.lock')" @click="confirmLock(user)">
											<i class="fa-solid fa-lock"></i>
										</button>
										<button v-if="user.status === 'locked'" class="btn btn-sm btn-outline-info" :title="$t('admin.userManagement.actions.unlock')" @click="confirmUnlock(user)">
											<i class="fa-solid fa-lock-open"></i>
										</button>
										<button class="btn btn-sm btn-outline-danger" :title="$t('admin.userManagement.actions.delete')" @click="confirmDelete(user)">
											<i class="fa-solid fa-trash"></i>
										</button>
									</div>
								</td>
							</tr>
						</tbody>
					</table>
				</div>

				<div class="text-center py-5" v-if="filteredUsers.length === 0">
					<i class="fa-solid fa-users-slash text-muted" style="font-size: 48px;"></i>
					<p class="text-muted mt-3">{{ $t('admin.userManagement.emptyState') }}</p>
				</div>
			</div>

			<!-- Pagination -->
			<div class="card-footer bg-white border-top py-3" v-if="filteredUsers.length > 0">
				<div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
					<span class="text-muted small">{{ $t('admin.userManagement.pagination.showing', { count: filteredUsers.length }) }}</span>
					<nav>
						<ul class="pagination pagination-sm mb-0">
							<li class="page-item disabled"><a class="page-link" href="#">«</a></li>
							<li class="page-item active"><a class="page-link" href="#">1</a></li>
							<li class="page-item"><a class="page-link" href="#">2</a></li>
							<li class="page-item"><a class="page-link" href="#">3</a></li>
							<li class="page-item"><a class="page-link" href="#">»</a></li>
						</ul>
					</nav>
				</div>
			</div>
		</div>

		<!-- Add/Edit User Modal -->
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
								<input type="text" class="form-control" :placeholder="$t('admin.userManagement.modal.fullNamePlaceholder')" v-model="formData.name"
									:class="{ 'is-invalid': formErrors.name }">
								<div class="invalid-feedback">{{ formErrors.name }}</div>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.email') }} <span class="text-danger">*</span></label>
								<input type="email" class="form-control" :placeholder="$t('admin.userManagement.modal.emailPlaceholder')" v-model="formData.email"
									:class="{ 'is-invalid': formErrors.email }">
								<div class="invalid-feedback">{{ formErrors.email }}</div>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.phone') }}</label>
								<input type="text" class="form-control" :placeholder="$t('admin.userManagement.modal.phonePlaceholder')" v-model="formData.phone">
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.role') }} <span class="text-danger">*</span></label>
								<select class="form-select" v-model="formData.role">
									<option value="volunteer">{{ $t('admin.userManagement.roles.volunteer') }}</option>
									<option value="coordinator">{{ $t('admin.userManagement.roles.coordinator') }}</option>
									<option value="admin">{{ $t('admin.userManagement.roles.admin') }}</option>
								</select>
							</div>
							<div class="col-md-6" v-if="!isEditing">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.password') }} <span class="text-danger">*</span></label>
								<div class="position-relative">
									<input :type="showPassword ? 'text' : 'password'" class="form-control pe-5" :placeholder="$t('admin.userManagement.modal.passwordPlaceholder')"
										v-model="formData.password" :class="{ 'is-invalid': formErrors.password }">
									<button type="button" class="btn btn-link position-absolute end-0 top-50 translate-middle-y text-muted pe-3"
										@click="showPassword = !showPassword" style="z-index: 3;">
										<i :class="showPassword ? 'fa-solid fa-eye-slash' : 'fa-solid fa-eye'"></i>
									</button>
								</div>
								<div class="invalid-feedback d-block" v-if="formErrors.password">{{ formErrors.password }}</div>
							</div>
							<div class="col-md-6">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.status') }}</label>
								<select class="form-select" v-model="formData.status">
									<option value="active">{{ $t('admin.userManagement.statuses.active') }}</option>
									<option value="pending">{{ $t('admin.userManagement.statuses.pending') }}</option>
									<option value="locked">{{ $t('admin.userManagement.statuses.locked') }}</option>
								</select>
							</div>
							<div class="col-12">
								<label class="form-label small fw-bold">{{ $t('admin.userManagement.modal.note') }}</label>
								<textarea class="form-control" rows="2" :placeholder="$t('admin.userManagement.modal.notePlaceholder')" v-model="formData.note"></textarea>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeFormModal">{{ $t('admin.userManagement.modal.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="saveUser">
							<i :class="isEditing ? 'fa-solid fa-save' : 'fa-solid fa-plus'" class="me-1"></i>
							{{ isEditing ? $t('admin.userManagement.modal.update') : $t('admin.userManagement.modal.createAccount') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showFormModal" @click="closeFormModal"></div>

		<!-- View User Detail Modal -->
		<div class="modal fade" :class="{ show: showViewModal }" :style="showViewModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-user text-primary me-2"></i>{{ $t('admin.userManagement.viewModal.title') }}</h5>
						<button type="button" class="btn-close" @click="showViewModal = false"></button>
					</div>
					<div class="modal-body" v-if="viewingUser">
						<div class="text-center mb-4">
							<div class="user-view-avatar mx-auto mb-3" :style="{ background: viewingUser.color }">
								{{ viewingUser.name.charAt(0) }}
							</div>
							<h5 class="fw-bold mb-1">{{ viewingUser.name }}</h5>
							<span class="text-muted small">{{ viewingUser.email }}</span>
						</div>
						<div class="row g-3">
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.table.role') }}</span>
									<span class="badge rounded-pill mt-1" :class="getRoleBadgeClass(viewingUser.role)">
										<i :class="getRoleIcon(viewingUser.role)" class="me-1"></i>{{ getRoleLabel(viewingUser.role) }}
									</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.table.status') }}</span>
									<span class="d-flex align-items-center justify-content-center gap-1 mt-1">
										<span class="status-dot" :class="getStatusDotClass(viewingUser.status)"></span>
										<span class="small fw-bold">{{ getStatusLabel(viewingUser.status) }}</span>
									</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.table.createdAt') }}</span>
									<span class="fw-bold small">{{ viewingUser.createdAt }}</span>
								</div>
							</div>
							<div class="col-6">
								<div class="p-3 bg-light rounded-3 text-center">
									<span class="text-muted small d-block">{{ $t('admin.userManagement.table.campaigns') }}</span>
									<span class="fw-bold small">{{ viewingUser.campaigns }}</span>
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

		<!-- Confirm Modal (reusable) -->
		<ConfirmModal ref="confirmModal" :modalId="'userConfirmModal'"
			:title="confirmConfig.title" :message="confirmConfig.message" :detail="confirmConfig.detail"
			:icon="confirmConfig.icon" :variant="confirmConfig.variant"
			:confirmText="confirmConfig.confirmText" :confirmIcon="confirmConfig.confirmIcon"
			@confirm="onConfirmAction" />
	</div>
</template>

<script>
import ConfirmModal from '../../components/ConfirmModal.vue';

export default {
	name: 'QuanLyNguoiDung',
	components: { ConfirmModal },
	props: {
		toast: { type: Object, default: null }
	},
	data() {
		return {
			activeTab: 'all',
			searchQuery: '',
			filterRole: '',
			filterStatus: '',
			showFormModal: false,
			showViewModal: false,
			showPassword: false,
			isEditing: false,
			editingUserId: null,
			viewingUser: null,
			formData: { name: '', email: '', phone: '', role: 'volunteer', password: '', status: 'active', note: '' },
			formErrors: {},
			confirmConfig: { title: '', message: '', detail: '', icon: '', variant: 'danger', confirmText: '', confirmIcon: '' },
			confirmAction: null,
			users: [
				{ id: 1, name: 'Nguyễn Văn An', email: 'an.nv@gmail.com', phone: '0901234567', role: 'volunteer', status: 'active', createdAt: '01/03/2026', campaigns: 8, color: '#0d6efd' },
				{ id: 2, name: 'Trần Thị Bích', email: 'bich.tt@gmail.com', phone: '0912345678', role: 'coordinator', status: 'active', createdAt: '15/02/2026', campaigns: 15, color: '#198754' },
				{ id: 3, name: 'Lê Minh Châu', email: 'chau.lm@gmail.com', phone: '0923456789', role: 'volunteer', status: 'pending', createdAt: '04/03/2026', campaigns: 0, color: '#dc3545' },
				{ id: 4, name: 'Phạm Quốc Dũng', email: 'dung.pq@gmail.com', phone: '0934567890', role: 'volunteer', status: 'active', createdAt: '20/01/2026', campaigns: 5, color: '#6f42c1' },
				{ id: 5, name: 'Hoàng Yến Em', email: 'em.hy@gmail.com', phone: '0945678901', role: 'coordinator', status: 'active', createdAt: '10/02/2026', campaigns: 22, color: '#fd7e14' },
				{ id: 6, name: 'Đặng Thanh Phong', email: 'phong.dt@gmail.com', phone: '0956789012', role: 'volunteer', status: 'pending', createdAt: '05/03/2026', campaigns: 0, color: '#20c997' },
				{ id: 7, name: 'Vũ Thị Giang', email: 'giang.vt@gmail.com', phone: '0967890123', role: 'volunteer', status: 'locked', createdAt: '01/01/2026', campaigns: 3, color: '#6c757d' },
				{ id: 8, name: 'Bùi Văn Hải', email: 'hai.bv@gmail.com', phone: '0978901234', role: 'volunteer', status: 'pending', createdAt: '05/03/2026', campaigns: 0, color: '#e83e8c' },
				{ id: 9, name: 'Ngô Thị Inh', email: 'inh.nt@gmail.com', phone: '0989012345', role: 'admin', status: 'active', createdAt: '01/06/2025', campaigns: 0, color: '#4f8cf7' },
				{ id: 10, name: 'Mai Đức Kim', email: 'kim.md@gmail.com', phone: '0990123456', role: 'volunteer', status: 'active', createdAt: '28/02/2026', campaigns: 12, color: '#17a2b8' },
				{ id: 11, name: 'Cao Văn Long', email: 'long.cv@gmail.com', phone: '0901122334', role: 'volunteer', status: 'pending', createdAt: '06/03/2026', campaigns: 0, color: '#795548' },
				{ id: 12, name: 'Phan Thị Mỹ', email: 'my.pt@gmail.com', phone: '0912233445', role: 'volunteer', status: 'pending', createdAt: '06/03/2026', campaigns: 0, color: '#e91e63' }
			]
		}
	},
	computed: {
		allUsers() { return this.users; },
		pendingUsers() { return this.users.filter(u => u.status === 'pending'); },
		lockedUsers() { return this.users.filter(u => u.status === 'locked'); },
		filteredUsers() {
			let list = this.users;
			if (this.activeTab === 'pending') list = list.filter(u => u.status === 'pending');
			else if (this.activeTab === 'locked') list = list.filter(u => u.status === 'locked');
			if (this.searchQuery) {
				const q = this.searchQuery.toLowerCase();
				list = list.filter(u => u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q));
			}
			if (this.filterRole) list = list.filter(u => u.role === this.filterRole);
			if (this.filterStatus) list = list.filter(u => u.status === this.filterStatus);
			return list;
		}
	},
	methods: {
		getRoleLabel(role) {
			return { 
				volunteer: this.$t('admin.userManagement.roles.volunteer'), 
				coordinator: this.$t('admin.userManagement.roles.coordinator'), 
				admin: this.$t('admin.userManagement.roles.admin') 
			}[role];
		},
		getRoleIcon(role) {
			return { volunteer: 'fa-solid fa-hand-holding-heart', coordinator: 'fa-solid fa-people-arrows', admin: 'fa-solid fa-shield-halved' }[role];
		},
		getRoleBadgeClass(role) {
			return { volunteer: 'bg-primary-subtle text-primary', coordinator: 'bg-success-subtle text-success', admin: 'bg-warning-subtle text-warning' }[role];
		},
		getStatusLabel(status) {
			return { 
				active: this.$t('admin.userManagement.statuses.active'), 
				pending: this.$t('admin.userManagement.statuses.pending'), 
				locked: this.$t('admin.userManagement.statuses.locked') 
			}[status];
		},
		getStatusDotClass(status) {
			return { active: 'bg-success', pending: 'bg-warning', locked: 'bg-danger' }[status];
		},
		getRandomColor() {
			const colors = ['#0d6efd', '#198754', '#dc3545', '#6f42c1', '#fd7e14', '#20c997', '#e83e8c', '#4f8cf7', '#17a2b8', '#795548'];
			return colors[Math.floor(Math.random() * colors.length)];
		},
		// --- Form ---
		openAddModal() {
			this.isEditing = false;
			this.editingUserId = null;
			this.formData = { name: '', email: '', phone: '', role: 'volunteer', password: '', status: 'active', note: '' };
			this.formErrors = {};
			this.showPassword = false;
			this.showFormModal = true;
		},
		openEditModal(user) {
			this.isEditing = true;
			this.editingUserId = user.id;
			this.formData = { name: user.name, email: user.email, phone: user.phone || '', role: user.role, password: '', status: user.status, note: '' };
			this.formErrors = {};
			this.showFormModal = true;
		},
		closeFormModal() {
			this.showFormModal = false;
		},
		validateForm() {
			this.formErrors = {};
			if (!this.formData.name.trim()) this.formErrors.name = this.$t('admin.userManagement.validation.fullNameRequired');
			if (!this.formData.email.trim()) this.formErrors.email = this.$t('admin.userManagement.validation.emailRequired');
			else if (!/\S+@\S+\.\S+/.test(this.formData.email)) this.formErrors.email = this.$t('admin.userManagement.validation.emailInvalid');
			if (!this.isEditing && !this.formData.password) this.formErrors.password = this.$t('admin.userManagement.validation.passwordRequired');
			return Object.keys(this.formErrors).length === 0;
		},
		saveUser() {
			if (!this.validateForm()) return;
			if (this.isEditing) {
				const user = this.users.find(u => u.id === this.editingUserId);
				if (user) {
					user.name = this.formData.name;
					user.email = this.formData.email;
					user.phone = this.formData.phone;
					user.role = this.formData.role;
					user.status = this.formData.status;
				}
				this.showToast('success', this.$t('admin.userManagement.toast.updateSuccessTitle'), this.$t('admin.userManagement.toast.updateSuccessMessage', { name: this.formData.name }));
			} else {
				const newUser = {
					id: Date.now(),
					name: this.formData.name,
					email: this.formData.email,
					phone: this.formData.phone,
					role: this.formData.role,
					status: this.formData.status,
					createdAt: new Date().toLocaleDateString('vi-VN'),
					campaigns: 0,
					color: this.getRandomColor()
				};
				this.users.unshift(newUser);
				this.showToast('success', this.$t('admin.userManagement.toast.createSuccessTitle'), this.$t('admin.userManagement.toast.createSuccessMessage', { name: this.formData.name }));
			}
			this.closeFormModal();
		},
		// --- View ---
		viewUser(user) {
			this.viewingUser = user;
			this.showViewModal = true;
		},
		// --- Confirm Actions ---
		confirmApprove(user) {
			this.confirmConfig = {
				title: this.$t('admin.userManagement.confirm.approveTitle'),
				message: this.$t('admin.userManagement.confirm.approveMessage'),
				detail: user.name,
				icon: 'fa-solid fa-user-check',
				variant: 'success',
				confirmText: this.$t('admin.userManagement.actions.approve'),
				confirmIcon: 'fa-solid fa-check'
			};
			this.confirmAction = () => {
				user.status = 'active';
				this.showToast('success', this.$t('admin.userManagement.toast.approveSuccessTitle'), this.$t('admin.userManagement.toast.approveSuccessMessage', { name: user.name }));
			};
			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		confirmLock(user) {
			this.confirmConfig = {
				title: this.$t('admin.userManagement.confirm.lockTitle'),
				message: this.$t('admin.userManagement.confirm.lockMessage'),
				detail: user.name,
				icon: 'fa-solid fa-lock',
				variant: 'warning',
				confirmText: this.$t('admin.userManagement.actions.lock'),
				confirmIcon: 'fa-solid fa-lock'
			};
			this.confirmAction = () => {
				user.status = 'locked';
				this.showToast('warning', this.$t('admin.userManagement.toast.lockSuccessTitle'), this.$t('admin.userManagement.toast.lockSuccessMessage', { name: user.name }));
			};
			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		confirmUnlock(user) {
			this.confirmConfig = {
				title: this.$t('admin.userManagement.confirm.unlockTitle'),
				message: this.$t('admin.userManagement.confirm.unlockMessage'),
				detail: user.name,
				icon: 'fa-solid fa-lock-open',
				variant: 'info',
				confirmText: this.$t('admin.userManagement.actions.unlock'),
				confirmIcon: 'fa-solid fa-lock-open'
			};
			this.confirmAction = () => {
				user.status = 'active';
				this.showToast('info', this.$t('admin.userManagement.toast.unlockSuccessTitle'), this.$t('admin.userManagement.toast.unlockSuccessMessage', { name: user.name }));
			};
			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		confirmDelete(user) {
			this.confirmConfig = {
				title: this.$t('admin.userManagement.confirm.deleteTitle'),
				message: this.$t('admin.userManagement.confirm.deleteMessage'),
				detail: user.name,
				icon: 'fa-solid fa-trash',
				variant: 'danger',
				confirmText: this.$t('admin.userManagement.actions.delete'),
				confirmIcon: 'fa-solid fa-trash'
			};
			this.confirmAction = () => {
				this.users = this.users.filter(u => u.id !== user.id);
				this.showToast('success', this.$t('admin.userManagement.toast.deleteSuccessTitle'), this.$t('admin.userManagement.toast.deleteSuccessMessage', { name: user.name }));
			};
			this.$nextTick(() => this.$refs.confirmModal.show());
		},
		onConfirmAction() {
			if (this.confirmAction) this.confirmAction();
			this.confirmAction = null;
		},
		resetFilters() {
			this.searchQuery = '';
			this.filterRole = '';
			this.filterStatus = '';
		},
		showToast(type, title, message) {
			if (this.toast) this.toast[type](title, message);
		}
	}
}
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
.admin-tabs .nav-link:hover { color: #0d6efd; }
.admin-tabs .nav-link.active {
	color: #0d6efd;
	border-bottom-color: #0d6efd;
	background: transparent;
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
