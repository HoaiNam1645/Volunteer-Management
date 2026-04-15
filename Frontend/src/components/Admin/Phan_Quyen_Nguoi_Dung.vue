<template>
	<div class="admin-permissions">
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1">
					<i class="fa-solid fa-user-shield text-primary me-2"></i>{{ $t('admin.userPermissions.title') }}
				</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.userPermissions.subtitle') }}</p>
			</div>
			<div class="d-flex gap-2 flex-wrap">
				<span class="badge rounded-pill bg-light text-dark border px-3 py-2">
					{{ $t('admin.userPermissions.badges.scope') }}
				</span>
				<span class="badge rounded-pill bg-primary-subtle text-primary px-3 py-2">
					{{ $t('admin.userPermissions.badges.separateTable') }}
				</span>
			</div>
		</div>

		<div class="row g-3 mb-4">
			<div class="col-md-3 col-sm-6" v-for="card in summaryCards" :key="card.key">
				<div class="card border-0 shadow-sm h-100">
					<div class="card-body p-3 d-flex align-items-center gap-3">
						<div class="summary-icon" :class="card.iconClass">
							<i :class="card.icon"></i>
						</div>
						<div>
							<p class="text-muted small mb-1">{{ card.label }}</p>
							<h4 class="fw-bold mb-0">{{ card.value }}</h4>
						</div>
					</div>
				</div>
			</div>
		</div>

		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body py-3">
				<div class="row g-3 align-items-center">
					<div class="col-lg-4">
						<div class="position-relative">
							<input
								v-model="searchQuery"
								type="text"
								class="form-control ps-5"
								:placeholder="$t('admin.userPermissions.filter.searchPlaceholder')"
							>
							<i class="fa-solid fa-search position-absolute filter-icon"></i>
						</div>
					</div>
					<div class="col-lg-2 col-md-4">
						<select v-model="filterRole" class="form-select">
							<option value="">{{ $t('admin.userPermissions.filter.allRoles') }}</option>
							<option value="tinh_nguyen_vien">{{ $t('admin.userManagement.roles.volunteer') }}</option>
						</select>
					</div>
					<div class="col-lg-2 col-md-4">
						<select v-model="filterStatus" class="form-select">
							<option value="">{{ $t('admin.userPermissions.filter.allStatuses') }}</option>
							<option value="hoat_dong">{{ $t('admin.userManagement.statuses.active') }}</option>
							<option value="cho_duyet">{{ $t('admin.userManagement.statuses.pending') }}</option>
							<option value="bi_khoa">{{ $t('admin.userManagement.statuses.locked') }}</option>
						</select>
					</div>
					<div class="col-lg-2 col-md-4">
						<select v-model="filterMode" class="form-select">
							<option value="">{{ $t('admin.userPermissions.filter.allModes') }}</option>
							<option value="mac_dinh">{{ $t('admin.userPermissions.modes.default') }}</option>
							<option value="tuy_chinh">{{ $t('admin.userPermissions.modes.custom') }}</option>
						</select>
					</div>
					<div class="col-lg-2 text-end">
						<button class="btn btn-outline-secondary btn-sm" @click="resetFilters">
							<i class="fa-solid fa-rotate-left me-1"></i>{{ $t('admin.userPermissions.filter.reset') }}
						</button>
					</div>
				</div>
			</div>
		</div>

		<div class="card border-0 shadow-sm">
			<div class="card-header bg-white border-bottom py-3">
				<div class="d-flex align-items-center justify-content-between flex-wrap gap-3">
					<div>
						<h6 class="fw-bold mb-1">{{ $t('admin.userPermissions.table.title') }}</h6>
						<p class="text-muted small mb-0">
							{{ $t('admin.userPermissions.table.summary', { groups: permissionGroups.length, permissions: permissionColumns.length, from: pageStart, to: pageEnd, total: totalUsers }) }}
						</p>
					</div>
					<div class="d-flex align-items-center gap-2 flex-wrap">
						<span class="text-muted small">{{ $t('admin.userPermissions.table.rowsPerPage') }}</span>
						<select v-model.number="pageSize" class="form-select form-select-sm page-size-select">
							<option v-for="size in pageSizeOptions" :key="size" :value="size">{{ size }}</option>
						</select>
					</div>
				</div>
			</div>
			<div class="card-body p-0">
				<div class="table-responsive permission-table-wrap">
					<table class="table permission-table align-middle mb-0">
						<thead class="table-light">
							<tr>
								<th rowspan="2" class="sticky-col sticky-name">{{ $t('admin.userPermissions.table.columns.account') }}</th>
								<th rowspan="2">{{ $t('admin.userPermissions.table.columns.role') }}</th>
								<th rowspan="2">{{ $t('admin.userPermissions.table.columns.status') }}</th>
								<th rowspan="2">{{ $t('admin.userPermissions.table.columns.mode') }}</th>
								<th
									v-for="group in permissionGroups"
									:key="group.key"
									:colspan="group.permissions.length"
									class="text-center permission-group-header"
								>
									{{ getGroupLabel(group.key) }}
								</th>
								<th rowspan="2" class="text-center">{{ $t('admin.userPermissions.table.columns.totalPermissions') }}</th>
								<th rowspan="2" class="text-center">{{ $t('admin.userPermissions.table.columns.actions') }}</th>
							</tr>
							<tr>
								<th
									v-for="permission in permissionColumns"
									:key="permission.key"
									class="text-center"
									:class="getPermissionCellClass(permission)"
								>
									<div class="permission-column-label">{{ getPermissionShortLabel(permission.key) }}</div>
								</th>
							</tr>
						</thead>
						<tbody v-if="paginatedUsers.length">
							<tr
								v-for="user in paginatedUsers"
								:key="user.id"
								:id="`user-permission-row-${user.id}`"
								:class="{ 'table-warning': isDirty(user) }"
							>
								<td class="sticky-col sticky-name bg-white">
									<div class="d-flex align-items-center gap-3">
										<div v-if="user.anh_dai_dien" class="user-avatar image-avatar">
											<img :src="user.anh_dai_dien" :alt="user.ho_ten">
										</div>
										<div v-else class="user-avatar" :style="{ background: colorFromText(user.ho_ten) }">
											{{ getInitial(user.ho_ten) }}
										</div>
										<div class="min-w-0">
											<div class="d-flex align-items-center gap-2 flex-wrap">
												<h6 class="mb-0 small fw-bold text-truncate">{{ user.ho_ten }}</h6>
												<span v-if="user.id === currentUserId" class="badge rounded-pill bg-info-subtle text-info">{{ $t('admin.userPermissions.table.currentAccount') }}</span>
											</div>
											<span class="text-muted d-block" style="font-size: 12px;">{{ user.email }}</span>
										</div>
									</div>
								</td>
								<td>
									<span class="badge rounded-pill" :class="getRoleBadgeClass(user.vai_tro)">
										{{ getRoleLabel(user.vai_tro) }}
									</span>
								</td>
								<td>
									<span class="badge rounded-pill" :class="getStatusBadgeClass(user.trang_thai)">
										{{ getStatusLabel(user.trang_thai) }}
									</span>
								</td>
								<td>
									<span class="badge rounded-pill" :class="user.su_dung_mac_dinh_pham_vi ? 'bg-light text-dark border' : 'bg-primary-subtle text-primary'">
										{{ user.su_dung_mac_dinh_pham_vi ? $t('admin.userPermissions.modes.default') : $t('admin.userPermissions.modes.custom') }}
									</span>
								</td>
								<td
									v-for="permission in permissionColumns"
									:key="`${user.id}-${permission.key}`"
									class="text-center"
									:class="getPermissionCellClass(permission)"
								>
									<div class="form-check d-inline-flex justify-content-center mb-0">
										<input
											class="form-check-input permission-checkbox"
											type="checkbox"
											:checked="hasDraftPermission(user.id, permission.key)"
											:disabled="!canManagePermissions || savingId === user.id || user.trang_thai === 'bi_khoa'"
											@change="setPermission(user.id, permission.key, $event.target.checked)"
										>
									</div>
								</td>
								<td class="text-center">
									<span class="fw-bold small">{{ getDraftPermissions(user.id).length }}</span>
								</td>
								<td class="text-center">
									<div class="d-flex align-items-center justify-content-center gap-2 flex-wrap">
										<button
											class="btn btn-sm btn-outline-secondary rounded-pill px-3"
											:disabled="!canManagePermissions || savingId === user.id || user.trang_thai === 'bi_khoa'"
											@click="resetToDefault(user)"
										>
											<i class="fa-solid fa-rotate-left me-1"></i>{{ $t('admin.userPermissions.actions.resetDefault') }}
										</button>
										<button
											class="btn btn-sm btn-primary rounded-pill px-3"
											:disabled="!canManagePermissions || !isDirty(user) || savingId === user.id || user.trang_thai === 'bi_khoa'"
											@click="savePermissions(user)"
										>
											<span v-if="savingId === user.id" class="spinner-border spinner-border-sm me-2"></span>
											<i v-else class="fa-solid fa-save me-1"></i>{{ $t('admin.userPermissions.actions.save') }}
										</button>
									</div>
								</td>
							</tr>
						</tbody>
					</table>
				</div>

				<div class="text-center py-5" v-if="loading">
					<div class="spinner-border text-primary" role="status"></div>
				</div>

				<div class="text-center py-5" v-else-if="users.length === 0">
					<i class="fa-solid fa-users text-muted" style="font-size: 48px;"></i>
					<p class="text-muted mt-3 mb-0">{{ $t('admin.userPermissions.table.empty') }}</p>
				</div>

				<div v-if="!loading && users.length" class="d-flex align-items-center justify-content-between flex-wrap gap-3 border-top px-3 py-3">
					<div class="text-muted small">
						{{ $t('admin.userPermissions.table.pagination', { page: currentPage, totalPages, from: pageStart, to: pageEnd, total: totalUsers }) }}
					</div>
					<nav :aria-label="$t('admin.userPermissions.table.ariaPagination')">
						<ul class="pagination pagination-sm mb-0">
							<li class="page-item" :class="{ disabled: currentPage === 1 }">
								<button class="page-link" @click="goToPage(currentPage - 1)">{{ $t('common.previous') }}</button>
							</li>
							<li v-for="page in visiblePages" :key="page" class="page-item" :class="{ active: page === currentPage }">
								<button class="page-link" @click="goToPage(page)">{{ page }}</button>
							</li>
							<li class="page-item" :class="{ disabled: currentPage === totalPages }">
								<button class="page-link" @click="goToPage(currentPage + 1)">{{ $t('common.next') }}</button>
							</li>
						</ul>
					</nav>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
import api from '../../services/api';
import {
	getFirstAccessibleAdminRoute,
	getPermissionGroups,
	hasPermission,
	syncStoredUser,
} from '../../utils/permissions';

export default {
	name: 'PhanQuyenNguoiDung',
	inject: ['toast'],
	data() {
		return {
			loading: false,
			savingId: null,
			users: [],
			draftPermissions: {},
			currentPage: 1,
			pageSize: 10,
			pageSizeOptions: [5, 10, 20, 50],
			searchQuery: '',
			filterRole: '',
			filterStatus: '',
			filterMode: '',
			searchDebounce: null,
			currentUser: null,
			currentUserId: null,
			stats: {
				tong: 0,
				admin: 0,
				kiem_duyet: 0,
				tinh_nguyen_vien: 0,
				mac_dinh: 0,
				tuy_chinh: 0,
			},
		};
	},
	computed: {
		canManagePermissions() {
			return hasPermission(this.currentUser, 'permission_management.manage');
		},
		permissionGroups() {
			return getPermissionGroups('user');
		},
		permissionColumns() {
			return this.permissionGroups.flatMap((group) => group.permissions.map((permission, index) => ({
				...permission,
				groupKey: group.key,
				isGroupStart: index === 0,
				isGroupEnd: index === group.permissions.length - 1,
			})));
		},
		totalUsers() {
			return this.users.length;
		},
		totalPages() {
			return Math.max(1, Math.ceil(this.totalUsers / this.pageSize));
		},
		paginatedUsers() {
			const start = (this.currentPage - 1) * this.pageSize;
			return this.users.slice(start, start + this.pageSize);
		},
		pageStart() {
			return this.totalUsers ? ((this.currentPage - 1) * this.pageSize) + 1 : 0;
		},
		pageEnd() {
			return this.totalUsers ? Math.min(this.currentPage * this.pageSize, this.totalUsers) : 0;
		},
		visiblePages() {
			const start = Math.max(1, this.currentPage - 2);
			const end = Math.min(this.totalPages, start + 4);
			const normalizedStart = Math.max(1, end - 4);

			return Array.from({ length: end - normalizedStart + 1 }, (_, index) => normalizedStart + index);
		},
		summaryCards() {
			return [
				{
					key: 'tong',
					label: this.$t('admin.userPermissions.summary.totalAccounts'),
					value: this.stats.tong,
					icon: 'fa-solid fa-users',
					iconClass: 'bg-primary-subtle text-primary',
				},
				{
					key: 'tinh_nguyen_vien',
					label: this.$t('admin.userPermissions.summary.volunteers'),
					value: this.stats.tinh_nguyen_vien,
					icon: 'fa-solid fa-hand-holding-heart',
					iconClass: 'bg-success-subtle text-success',
				},
				{
					key: 'mac_dinh',
					label: this.$t('admin.userPermissions.summary.defaultMode'),
					value: this.stats.mac_dinh,
					icon: 'fa-solid fa-layer-group',
					iconClass: 'bg-secondary-subtle text-secondary',
				},
				{
					key: 'tuy_chinh',
					label: this.$t('admin.userPermissions.summary.customMode'),
					value: this.stats.tuy_chinh,
					icon: 'fa-solid fa-sliders',
					iconClass: 'bg-warning-subtle text-warning',
				},
			];
		},
	},
	created() {
		this.loadCurrentUser();
		this.fetchUsers();
	},
	watch: {
		searchQuery() {
			clearTimeout(this.searchDebounce);
			this.currentPage = 1;
			this.searchDebounce = setTimeout(() => this.fetchUsers(), 300);
		},
		filterRole() {
			this.currentPage = 1;
			this.fetchUsers();
		},
		filterStatus() {
			this.currentPage = 1;
			this.fetchUsers();
		},
		filterMode() {
			this.currentPage = 1;
			this.fetchUsers();
		},
		pageSize() {
			this.currentPage = 1;
			this.$nextTick(() => this.focusRequestedUser());
		},
	},
	beforeUnmount() {
		clearTimeout(this.searchDebounce);
	},
	methods: {
		loadCurrentUser() {
			try {
				this.currentUser = JSON.parse(localStorage.getItem('user') || 'null');
				this.currentUserId = this.currentUser?.id || null;
			} catch (_error) {
				this.currentUser = null;
				this.currentUserId = null;
			}
		},
		getInitial(name) {
			return (name || '?').trim().charAt(0).toUpperCase();
		},
		colorFromText(text) {
			const colors = ['#0d6efd', '#198754', '#dc3545', '#6f42c1', '#fd7e14', '#20c997', '#e83e8c', '#17a2b8'];
			const hash = Array.from(text || '').reduce((total, char) => total + char.charCodeAt(0), 0);
			return colors[hash % colors.length];
		},
		getRoleLabel(role) {
			return {
				tinh_nguyen_vien: this.$t('admin.userManagement.roles.volunteer'),
				kiem_duyet_vien: this.$t('admin.userManagement.roles.coordinator'),
				quan_tri_vien: this.$t('admin.userManagement.roles.admin'),
			}[role] || role;
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
		getStatusBadgeClass(status) {
			return {
				hoat_dong: 'bg-success-subtle text-success',
				cho_duyet: 'bg-warning-subtle text-warning',
				bi_khoa: 'bg-danger-subtle text-danger',
			}[status] || 'bg-secondary-subtle text-secondary';
		},
		getGroupLabel(groupKey) {
			return {
				account_center: this.$t('admin.userPermissions.groups.accountCenter'),
				competency_profile: this.$t('admin.userPermissions.groups.competencyProfile'),
				volunteer_campaigns: this.$t('admin.userPermissions.groups.volunteerCampaigns'),
				campaign_coordination: this.$t('admin.userPermissions.groups.campaignCoordination'),
				campaign_report_monitoring: this.$t('admin.userPermissions.groups.campaignReportMonitoring'),
				feedback_tracking: this.$t('admin.userPermissions.groups.feedbackTracking'),
				campaign_participation: this.$t('admin.userPermissions.groups.campaignParticipation'),
				ai_recommendation: this.$t('admin.userPermissions.groups.aiRecommendation'),
			}[groupKey] || groupKey;
		},
		getPermissionShortLabel(permissionKey) {
			return {
				'account_center.view': this.$t('admin.userPermissions.columns.view'),
				'account_center.manage': this.$t('admin.userPermissions.columns.manage'),
				'competency_profile.view': this.$t('admin.userPermissions.columns.view'),
				'competency_profile.manage': this.$t('admin.userPermissions.columns.manage'),
				'volunteer_campaigns.view': this.$t('admin.userPermissions.columns.view'),
				'volunteer_campaigns.manage': this.$t('admin.userPermissions.columns.manage'),
				'campaign_coordination.view': this.$t('admin.userPermissions.columns.view'),
				'campaign_coordination.manage': this.$t('admin.userPermissions.columns.manage'),
				'campaign_report_monitoring.view': this.$t('admin.userPermissions.columns.view'),
				'campaign_report_monitoring.manage': this.$t('admin.userPermissions.columns.manage'),
				'feedback_tracking.view': this.$t('admin.userPermissions.columns.view'),
				'feedback_tracking.manage': this.$t('admin.userPermissions.columns.manage'),
				'campaign_participation.manage': this.$t('admin.userPermissions.columns.join'),
				'ai_recommendation.view': this.$t('admin.userPermissions.columns.ai'),
			}[permissionKey] || permissionKey;
		},
		getPermissionCellClass(permission) {
			return {
				'permission-group-start': permission.isGroupStart,
				'permission-group-end': permission.isGroupEnd,
			};
		},
		normalizePermissions(list = []) {
			return [...list].sort();
		},
		getDraftPermissions(userId) {
			return this.draftPermissions[userId] || [];
		},
		hasDraftPermission(userId, permissionKey) {
			return this.getDraftPermissions(userId).includes(permissionKey);
		},
		setPermission(userId, permissionKey, checked) {
			const current = new Set(this.getDraftPermissions(userId));
			if (checked) {
				current.add(permissionKey);
			} else {
				current.delete(permissionKey);
			}

			this.draftPermissions = {
				...this.draftPermissions,
				[userId]: Array.from(current),
			};
		},
		isDirty(user) {
			return JSON.stringify(this.normalizePermissions(user.scope_permissions || []))
				!== JSON.stringify(this.normalizePermissions(this.getDraftPermissions(user.id)));
		},
		async fetchUsers() {
			this.loading = true;
			try {
				const params = { pham_vi: 'user' };
				if (this.searchQuery.trim()) params.tu_khoa = this.searchQuery.trim();
				if (this.filterRole) params.vai_tro = this.filterRole;
				if (this.filterStatus) params.trang_thai = this.filterStatus;
				if (this.filterMode) params.che_do_quyen = this.filterMode;

				const { data } = await api.get('/admin/phan-quyen', { params });
				this.users = data.data || [];
				this.stats = data.meta?.stats || this.stats;
				this.draftPermissions = Object.fromEntries(
					this.users.map((user) => [user.id, [...(user.scope_permissions || [])]])
				);
				if (this.currentPage > this.totalPages) {
					this.currentPage = this.totalPages;
				}
				this.$nextTick(() => this.focusRequestedUser());
			} catch (error) {
				this.showToast('error', this.$t('admin.userPermissions.toast.loadErrorTitle'), error.response?.data?.message || this.$t('admin.userPermissions.toast.loadErrorMessage'));
			} finally {
				this.loading = false;
			}
		},
		async savePermissions(user) {
			this.savingId = user.id;
			try {
				const payload = {
					pham_vi: 'user',
					quyen_han: this.getDraftPermissions(user.id),
				};
				const { data } = await api.put(`/admin/phan-quyen/${user.id}`, payload);
				this.updateUserRow(data.data);
				await this.fetchUsers();
				this.showToast('success', this.$t('admin.userPermissions.toast.saveSuccessTitle'), this.$t('admin.userPermissions.toast.saveSuccessMessage', { name: user.ho_ten }));
			} catch (error) {
				this.showToast('error', this.$t('admin.userPermissions.toast.saveErrorTitle'), error.response?.data?.message || this.$t('admin.userPermissions.toast.saveErrorMessage'));
			} finally {
				this.savingId = null;
			}
		},
		async resetToDefault(user) {
			this.savingId = user.id;
			try {
				const { data } = await api.put(`/admin/phan-quyen/${user.id}`, { pham_vi: 'user', su_dung_mac_dinh: true });
				this.updateUserRow(data.data);
				await this.fetchUsers();
				this.showToast('success', this.$t('admin.userPermissions.toast.resetSuccessTitle'), this.$t('admin.userPermissions.toast.resetSuccessMessage', { name: user.ho_ten }));
			} catch (error) {
				this.showToast('error', this.$t('admin.userPermissions.toast.saveErrorTitle'), error.response?.data?.message || this.$t('admin.userPermissions.toast.saveErrorMessage'));
			} finally {
				this.savingId = null;
			}
		},
		updateUserRow(updatedUser) {
			this.users = this.users.map((user) => (user.id === updatedUser.id ? updatedUser : user));
			this.draftPermissions = {
				...this.draftPermissions,
				[updatedUser.id]: [...(updatedUser.scope_permissions || [])],
			};
			this.stats = {
				tong: this.users.length,
				admin: this.users.filter((user) => user.vai_tro === 'quan_tri_vien').length,
				kiem_duyet: this.users.filter((user) => user.vai_tro === 'kiem_duyet_vien').length,
				tinh_nguyen_vien: this.users.filter((user) => user.vai_tro === 'tinh_nguyen_vien').length,
				mac_dinh: this.users.filter((user) => user.su_dung_mac_dinh_pham_vi).length,
				tuy_chinh: this.users.filter((user) => !user.su_dung_mac_dinh_pham_vi).length,
			};

			if (updatedUser.id === this.currentUserId) {
				this.currentUser = syncStoredUser({
					permissions: updatedUser.permissions,
					quyen_han: updatedUser.quyen_han,
					su_dung_mac_dinh: updatedUser.su_dung_mac_dinh,
				}) || this.currentUser;
				window.dispatchEvent(new CustomEvent('user-updated'));

				if (!hasPermission(this.currentUser, 'permission_management.view')) {
					this.$router.replace(getFirstAccessibleAdminRoute(this.currentUser));
				}
			}
		},
		goToPage(page) {
			const nextPage = Math.min(this.totalPages, Math.max(1, page));
			if (nextPage === this.currentPage) return;

			this.currentPage = nextPage;
			this.$nextTick(() => this.focusRequestedUser());
		},
		focusRequestedUser() {
			const focusId = Number(this.$route.query.user || 0);
			if (!focusId) return;
			const focusIndex = this.users.findIndex((user) => Number(user.id) === focusId);
			if (focusIndex === -1) return;

			const targetPage = Math.floor(focusIndex / this.pageSize) + 1;
			if (targetPage !== this.currentPage) {
				this.currentPage = targetPage;
				this.$nextTick(() => this.focusRequestedUser());
				return;
			}

			const row = document.getElementById(`user-permission-row-${focusId}`);
			if (!row) return;
			row.scrollIntoView({ behavior: 'smooth', block: 'center' });
		},
		resetFilters() {
			clearTimeout(this.searchDebounce);
			this.currentPage = 1;
			this.searchQuery = '';
			this.filterRole = '';
			this.filterStatus = '';
			this.filterMode = '';
			this.fetchUsers();
		},
		showToast(type, title, message) {
			this.toast?.showToast?.(type, title, message);
		},
	},
};
</script>

<style scoped>
.admin-permissions {
	width: 100%;
	max-width: 100%;
	min-width: 0;
}

.admin-permissions .card {
	max-width: 100%;
}

.filter-icon {
	left: 16px;
	top: 50%;
	transform: translateY(-50%);
	color: #adb5bd;
}

.summary-icon {
	width: 48px;
	height: 48px;
	border-radius: 14px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 18px;
}

.page-size-select {
	width: 88px;
}

.permission-table-wrap {
	width: 100%;
	max-width: 100%;
	overflow-x: auto;
	overflow-y: visible;
	-webkit-overflow-scrolling: touch;
}

.permission-table {
	min-width: 1880px;
	width: max-content;
}

.permission-table th,
.permission-table td {
	white-space: nowrap;
	vertical-align: middle;
	font-size: 13px;
}

.permission-table thead th {
	font-size: 11px;
	text-transform: uppercase;
	letter-spacing: 0.4px;
}

.permission-group-header {
	background: #f8fafc;
	border-bottom: 0;
	font-size: 12px !important;
	font-weight: 700;
	padding-top: 1rem;
	padding-bottom: 0.85rem;
	position: relative;
}

.permission-group-header::after {
	content: '';
	position: absolute;
	left: 14px;
	right: 14px;
	bottom: 9px;
	height: 3px;
	border-radius: 999px;
	background: linear-gradient(90deg, rgba(13, 110, 253, 0.18), rgba(13, 110, 253, 0.5));
}

.permission-column-label {
	min-width: 86px;
	font-weight: 700;
	line-height: 1.35;
}

.permission-group-start {
	border-left: 2px solid #dfe7f1 !important;
}

.permission-group-end {
	border-right: 2px solid #dfe7f1 !important;
}

.sticky-col {
	position: sticky;
	left: 0;
	z-index: 2;
}

.sticky-name {
	min-width: 260px;
}

.user-avatar {
	width: 40px;
	height: 40px;
	min-width: 40px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: #fff;
	font-weight: 700;
	overflow: hidden;
}

.image-avatar img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.permission-checkbox {
	cursor: pointer;
}

.min-w-0 {
	min-width: 0;
}

@media (max-width: 991px) {
	.sticky-col {
		position: static;
	}

	.permission-table {
		width: 100%;
	}
}
</style>
