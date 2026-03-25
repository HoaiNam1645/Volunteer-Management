<template>
	<div class="bg-light min-vh-100 pb-5">
		<div class="container pt-4">
			<PageHeader
				:title="$t('feedback.title')"
				icon="fa-solid fa-clock-rotate-left"
				:breadcrumbs="[{ label: $t('common.home'), to: '/' }, { label: $t('feedback.title') }]"
			/>

			<StatCards :cards="statCards" />

			<ul class="nav nav-tabs nav-tabs-custom border-bottom-0 flex-nowrap overflow-auto mb-0">
				<li class="nav-item" v-for="tab in tabs" :key="tab.value">
					<a
						class="nav-link px-3 px-md-4 py-2 fw-medium text-nowrap"
						:class="{ 'active text-primary': activeTab === tab.value, 'text-muted': activeTab !== tab.value }"
						href="#"
						@click.prevent="activeTab = tab.value"
					>
						<i :class="tab.icon" class="me-1"></i>{{ tab.label }}
						<span v-if="tab.count !== null" class="badge ms-1 rounded-pill" :class="activeTab === tab.value ? 'bg-primary' : 'bg-light text-muted'">{{ tab.count }}</span>
					</a>
				</li>
			</ul>

			<div v-if="loading" class="card border-0 shadow-sm mt-3">
				<div class="card-body p-5 text-center text-muted">
					<div class="spinner-border text-primary mb-3" role="status"></div>
					<div>{{ $t('common.loading') }}</div>
				</div>
			</div>

			<div class="card border-0 shadow-sm mb-4" v-else-if="activeTab === 'history'">
				<div class="card-header bg-white py-3">
					<div class="row g-2 align-items-center">
						<div class="col-md-5">
							<div class="input-group input-group-sm">
								<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
								<input type="text" class="form-control form-control-sm bg-light border-start-0 ps-0" :placeholder="$t('feedback.searchPlaceholder')" v-model="historySearch" />
							</div>
						</div>
						<div class="col-md-3">
							<select class="form-select form-select-sm" v-model="historyFilter">
								<option value="">{{ $t('feedback.allStatuses') }}</option>
								<option v-for="opt in registrationStatusOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
							</select>
						</div>
					</div>
				</div>
				<div class="card-body p-0">
					<div class="table-responsive table-responsive-history">
						<table class="table table-hover align-middle mb-0">
							<thead>
								<tr class="bg-light">
									<th class="fw-semibold text-muted small text-uppercase py-3 ps-3 border-0">{{ $t('feedback.tableHeadings.campaign') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-md-table-cell">{{ $t('feedback.tableHeadings.region') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-lg-table-cell">{{ $t('feedback.tableHeadings.time') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('feedback.tableHeadings.status') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center d-none d-md-table-cell">{{ $t('feedback.tableHeadings.rating') }}</th>
									<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center" style="width:80px"></th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="h in filteredHistory" :key="h.id" class="activity-row">
									<td class="ps-3">
										<div class="d-flex align-items-center gap-2 gap-md-3">
											<div class="activity-icon rounded-3 d-flex align-items-center justify-content-center text-white flex-shrink-0" :style="{ background: getCampaignColor(h.chien_dich_id) }">
												<i class="fa-solid fa-hand-holding-heart" style="font-size: 14px;"></i>
											</div>
											<div class="min-w-0">
												<div class="fw-bold text-dark small text-truncate">{{ h.chien_dich?.tieu_de }}</div>
												<div class="text-muted small text-truncate d-none d-sm-block">{{ h.chien_dich?.nguoi_tao?.ho_ten || $t('common.notAvailable') }}</div>
												<div class="text-muted" style="font-size: 11px;">
													{{ $t('feedback.timeline.createdAt') }}: {{ formatDateTime(h.chien_dich?.tao_luc) }}
												</div>
											</div>
										</div>
									</td>
									<td class="d-none d-md-table-cell">
										<span class="text-muted small"><i class="fa-solid fa-location-dot text-danger me-1"></i>{{ h.chien_dich?.dia_diem || $t('common.notAvailable') }}</span>
									</td>
									<td class="d-none d-lg-table-cell">
										<div class="text-muted small"><i class="fa-regular fa-calendar me-1"></i>{{ formatCampaignDateRange(h.chien_dich) }}</div>
										<div class="text-muted" style="font-size: 11px;">{{ $t('feedback.timeline.actualStart') }}: {{ formatDateTime(h.chien_dich?.thoi_gian_bat_dau_thuc_te) }}</div>
										<div class="text-muted" style="font-size: 11px;">{{ $t('feedback.timeline.actualEnd') }}: {{ formatDateTime(h.chien_dich?.thoi_gian_ket_thuc_thuc_te) }}</div>
									</td>
									<td class="text-center">
										<span class="badge rounded-pill" :class="getHistoryStatusClass(h.trang_thai_dang_ky)">
											<i :class="getHistoryStatusIcon(h.trang_thai_dang_ky)" class="me-1"></i>{{ getHistoryStatusLabel(h.trang_thai_dang_ky) }}
										</span>
									</td>
									<td class="text-center d-none d-md-table-cell">
										<div class="d-flex justify-content-center gap-0" v-if="h.danh_gia_tnv?.so_sao">
											<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= h.danh_gia_tnv.so_sao ? 'text-warning' : 'text-muted'" style="font-size:11px"></i>
										</div>
										<span class="text-muted small" v-else>—</span>
									</td>
									<td class="text-center">
										<button class="btn btn-sm btn-light border-0 rounded-circle" style="width:30px;height:30px" @click.stop="toggleActionMenu($event, h)">
											<i class="fa-solid fa-ellipsis-vertical small"></i>
										</button>
									</td>
								</tr>
								<tr v-if="filteredHistory.length === 0">
									<td colspan="6" class="text-center py-5 text-muted">
										<i class="fa-solid fa-inbox d-block mb-2 fs-3 opacity-25"></i>{{ $t('feedback.noHistory') }}
									</td>
								</tr>
							</tbody>
						</table>
					</div>
				</div>
			</div>

			<div v-if="!loading && activeTab === 'scores'">
				<div class="row g-4">
					<div class="col-lg-4">
						<div class="card border-0 shadow-sm">
							<div class="card-body text-center p-4">
								<div class="rating-circle mx-auto mb-3">
									<span class="rating-number">{{ avgRatingText }}</span>
								</div>
								<div class="d-flex justify-content-center gap-1 mb-2">
									<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= Math.round(Number(avgRatingText)) ? 'text-warning' : 'text-muted'" style="font-size:18px"></i>
								</div>
								<span class="text-muted small">{{ $t('feedback.basedOnReviews', { count: diemDanhGia.length }) }}</span>
							</div>
						</div>
					</div>
					<div class="col-lg-8">
						<div class="card border-0 shadow-sm">
							<div class="card-header bg-white py-3">
								<h6 class="fw-bold mb-0"><i class="fa-solid fa-star text-warning me-2"></i>{{ $t('feedback.ratingDetailTitle') }}</h6>
							</div>
							<div class="card-body p-0">
								<div class="rating-row p-3 border-bottom d-flex align-items-center gap-3" v-for="rating in diemDanhGia" :key="rating.id">
									<div class="activity-icon rounded-3 d-flex align-items-center justify-content-center text-white flex-shrink-0" :style="{ background: getCampaignColor(rating.chien_dich_id) }" style="width:38px;height:38px">
										<i class="fa-solid fa-star" style="font-size:13px"></i>
									</div>
									<div class="flex-grow-1 min-w-0">
										<div class="fw-bold small text-truncate">{{ rating.ten_chien_dich || $t('common.notAvailable') }}</div>
										<span class="text-muted" style="font-size:12px">{{ formatDateTime(rating.tao_luc) }}</span>
									</div>
									<div class="d-flex gap-0 flex-shrink-0">
										<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= rating.so_sao ? 'text-warning' : 'text-muted'" style="font-size:13px"></i>
									</div>
									<span class="fw-bold small" style="min-width:30px">{{ rating.so_sao }}/5</span>
								</div>
								<div class="text-center py-4 text-muted small" v-if="diemDanhGia.length === 0">
									{{ $t('feedback.noRatings') }}
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<div v-if="!loading && activeTab === 'reports'">
				<div class="row g-3">
					<div class="col-12" v-if="baoCaoChienDich.length === 0">
						<div class="card border-0 shadow-sm">
							<div class="card-body text-center py-5 text-muted">
								<i class="fa-regular fa-flag fs-2 d-block mb-2 opacity-50"></i>
								{{ $t('feedback.noReports') }}
							</div>
						</div>
					</div>
					<div class="col-12" v-for="report in baoCaoChienDich" :key="report.id">
						<div class="card border-0 shadow-sm">
							<div class="card-body p-4">
								<div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-2">
									<div>
										<div class="fw-bold">{{ report.tieu_de }}</div>
										<div class="small text-muted">{{ report.ten_chien_dich || $t('common.notAvailable') }} - {{ formatDateTime(report.tao_luc) }}</div>
									</div>
									<span class="badge rounded-pill" :class="getReportStatusClass(report.trang_thai)">{{ getReportStatusLabel(report.trang_thai) }}</span>
								</div>
								<div class="small mb-2"><span class="fw-semibold">{{ $t('feedback.reportCategory') }}:</span> {{ report.phan_loai }}</div>
								<div class="text-muted mb-3">{{ report.noi_dung }}</div>
								<div v-if="report.phan_hoi_xu_ly" class="bg-light rounded-3 p-3 small">
									<div class="fw-semibold mb-1">{{ $t('feedback.reportResponse') }}</div>
									<div>{{ report.phan_hoi_xu_ly }}</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

		</div>

		<div
			v-if="actionMenu.visible"
			class="action-menu-backdrop"
			@click="closeActionMenu"
		></div>

		<div
			v-if="actionMenu.visible && actionMenu.item"
			class="action-menu card border-0 shadow"
			:style="{ top: `${actionMenu.top}px`, left: `${actionMenu.left}px` }"
			@click.stop
		>
			<div class="list-group list-group-flush">
				<button type="button" class="list-group-item list-group-item-action small py-2 text-start" @click="handleViewDetailFromMenu">
					<i class="fa-regular fa-eye me-2 text-primary"></i>{{ $t('feedback.actions.viewDetail') }}
				</button>
				<button v-if="canManageFeedback && actionMenu.item.co_the_danh_gia_chien_dich" type="button" class="list-group-item list-group-item-action small py-2 text-start" @click="handleFeedbackFromMenu">
					<i class="fa-solid fa-comment me-2 text-success"></i>{{ $t('feedback.actions.sendFeedback') }}
				</button>
				<button v-if="canManageFeedback && actionMenu.item.co_the_report" type="button" class="list-group-item list-group-item-action small py-2 text-start text-danger" @click="handleReportFromMenu">
					<i class="fa-solid fa-flag me-2"></i>{{ $t('feedback.actions.reportCampaign') }}
				</button>
			</div>
		</div>

		<div class="modal fade" :class="{ show: showFeedbackModal }" :style="showFeedbackModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-comment text-success me-2"></i>{{ $t('feedback.actions.sendFeedback') }}</h5>
						<button type="button" class="btn-close" @click="closeFeedbackModal"></button>
					</div>
					<div class="modal-body" v-if="feedbackTarget">
						<div class="bg-light rounded-3 p-3 mb-3">
							<span class="fw-bold small">{{ feedbackTarget.chien_dich?.tieu_de }}</span>
							<span class="text-muted small d-block">{{ formatCampaignDateRange(feedbackTarget.chien_dich) }}</span>
						</div>
						<div class="text-center mb-3">
							<label class="form-label small fw-bold d-block">{{ $t('feedback.rateExperience') }}</label>
							<div class="d-flex justify-content-center gap-2">
								<i v-for="i in 5" :key="i" class="star-feedback" :class="i <= feedbackRating ? 'fa-solid fa-star text-warning' : 'fa-regular fa-star text-muted'" @click="feedbackRating = i"></i>
							</div>
							<span class="text-muted small mt-1 d-block">{{ getRatingLabel(feedbackRating) }}</span>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('feedback.yourCommentTitle') }}</label>
							<textarea class="form-control" rows="4" :placeholder="$t('feedback.commentPlaceholder')" v-model="feedbackText"></textarea>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('feedback.whatToImproveTitle') }}</label>
							<div class="d-flex flex-wrap gap-2">
								<span v-for="tag in feedbackTags" :key="tag.id" class="badge rounded-pill px-3 py-2 skill-tag" :class="selectedFeedbackTags.includes(tag.id) ? 'bg-primary text-white' : 'bg-light text-dark border'" style="font-size: 12px; cursor: pointer;" @click="toggleFeedbackTag(tag.id)">{{ tag.ten }}</span>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeFeedbackModal">{{ $t('common.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="submitFeedback" :disabled="!canManageFeedback || submittingFeedback || !feedbackRating">
							<i class="fa-solid fa-paper-plane me-1"></i>{{ submittingFeedback ? $t('common.processing') : $t('feedback.actions.submit') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showFeedbackModal" @click="closeFeedbackModal"></div>

		<div class="modal fade" :class="{ show: showReportModal }" :style="showReportModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-flag text-danger me-2"></i>{{ $t('feedback.actions.reportCampaign') }}</h5>
						<button type="button" class="btn-close" @click="closeReportModal"></button>
					</div>
					<div class="modal-body" v-if="reportTarget">
						<div class="bg-light rounded-3 p-3 mb-3">
							<span class="fw-bold small">{{ reportTarget.chien_dich?.tieu_de }}</span>
							<span class="text-muted small d-block">{{ reportTarget.chien_dich?.dia_diem }}</span>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('feedback.reportCategory') }}</label>
							<input type="text" class="form-control" v-model.trim="reportCategory" :placeholder="$t('feedback.reportCategoryPlaceholder')" />
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('feedback.reportTitle') }}</label>
							<input type="text" class="form-control" v-model.trim="reportTitle" :placeholder="$t('feedback.reportTitlePlaceholder')" />
						</div>
						<div class="mb-0">
							<label class="form-label small fw-bold">{{ $t('feedback.reportContent') }}</label>
							<textarea class="form-control" rows="4" v-model.trim="reportContent" :placeholder="$t('feedback.reportContentPlaceholder')"></textarea>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeReportModal">{{ $t('common.cancel') }}</button>
						<button type="button" class="btn btn-danger rounded-pill px-4" @click="submitReport" :disabled="!canManageFeedback || submittingReport">
							<i class="fa-solid fa-paper-plane me-1"></i>{{ submittingReport ? $t('common.processing') : $t('feedback.actions.submit') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showReportModal" @click="closeReportModal"></div>
	</div>
</template>

<script>
import api from '@/services/api.js';
import PageHeader from '../../components/PageHeader.vue';
import StatCards from '../../components/StatCards.vue';
import { hasPermission } from '@/utils/permissions';

export default {
	name: 'TheoDoiPhanHoi',
	components: { PageHeader, StatCards },
	inject: ['toast'],
	data() {
		return {
			loading: false,
			activeTab: 'history',
			historySearch: '',
			historyFilter: '',
			thongKe: {
				so_chien_dich_hoan_thanh: 0,
				so_chien_dich_dang_tham_gia: 0,
				diem_danh_gia_trung_binh: 0,
				tong_luot_danh_gia: 0,
				tong_bao_cao: 0,
				bao_cao_dang_xu_ly: 0,
			},
			lichSuHoatDong: [],
			diemDanhGia: [],
			baoCaoChienDich: [],
			feedbackTags: [],

			showFeedbackModal: false,
			feedbackTarget: null,
			feedbackRating: 0,
			feedbackText: '',
			selectedFeedbackTags: [],
			submittingFeedback: false,

			showReportModal: false,
			reportTarget: null,
			reportCategory: '',
			reportTitle: '',
			reportContent: '',
			submittingReport: false,
			actionMenu: {
				visible: false,
				item: null,
				top: 0,
				left: 0,
			},
		};
	},
	computed: {
		tabs() {
			return [
				{ label: this.$t('feedback.tabs.history'), value: 'history', icon: 'fa-solid fa-clock-rotate-left', count: this.lichSuHoatDong.length },
				{ label: this.$t('feedback.tabs.scores'), value: 'scores', icon: 'fa-solid fa-star', count: this.diemDanhGia.length },
				{ label: this.$t('feedback.tabs.reports'), value: 'reports', icon: 'fa-solid fa-flag', count: this.baoCaoChienDich.length },
			];
		},
		statCards() {
			return [
				{ label: this.$t('feedback.stats.joined'), value: this.thongKe.so_chien_dich_hoan_thanh, icon: 'fa-solid fa-circle-check', color: 'success' },
				{ label: this.$t('feedback.stats.attending'), value: this.thongKe.so_chien_dich_dang_tham_gia, icon: 'fa-solid fa-play', color: 'primary' },
				{ label: this.$t('feedback.stats.avgRating'), value: this.avgRatingText, icon: 'fa-solid fa-star', color: 'warning' },
				{ label: this.$t('feedback.stats.reports'), value: `${this.thongKe.bao_cao_dang_xu_ly}/${this.thongKe.tong_bao_cao}`, icon: 'fa-solid fa-flag', color: 'danger' },
			];
		},
		avgRatingText() {
			const value = Number(this.thongKe.diem_danh_gia_trung_binh || 0);
			return value.toFixed(1);
		},
		registrationStatusOptions() {
			return [
				'da_dang_ky',
				'da_xac_nhan',
				'da_duyet',
				'dang_tham_gia',
				'hoan_thanh',
				'da_huy',
				'tu_choi',
			].map((value) => ({ value, label: this.getHistoryStatusLabel(value) }));
		},
		filteredHistory() {
			let list = this.lichSuHoatDong;
			if (this.historySearch) {
				const q = this.historySearch.toLowerCase();
				list = list.filter((h) => (h.chien_dich?.tieu_de || '').toLowerCase().includes(q));
			}
			if (this.historyFilter) {
				list = list.filter((h) => h.trang_thai_dang_ky === this.historyFilter);
			}
			return list;
		},
		canManageFeedback() {
			try {
				const user = JSON.parse(localStorage.getItem('user') || 'null');
				return hasPermission(user, 'feedback_tracking.manage');
			} catch (_error) {
				return false;
			}
		},
	},
	async mounted() {
		await this.loadData();
	},
	methods: {
		async loadData() {
			this.loading = true;
			try {
				const res = await api.get('/tinh-nguyen-vien/theo-doi-phan-hoi');
				const data = res?.data?.data || {};
				this.thongKe = data.thong_ke || this.thongKe;
				this.lichSuHoatDong = Array.isArray(data.lich_su_hoat_dong) ? data.lich_su_hoat_dong : [];
				this.diemDanhGia = Array.isArray(data.diem_danh_gia) ? data.diem_danh_gia : [];
				this.baoCaoChienDich = Array.isArray(data.bao_cao_chien_dich) ? data.bao_cao_chien_dich : [];
				this.feedbackTags = Array.isArray(data.the_phan_hoi) ? data.the_phan_hoi : [];
			} catch (error) {
				this.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('feedback.loadError'));
			} finally {
				this.loading = false;
			}
		},
		getHistoryStatusLabel(status) {
			return this.$t(`campaignRegistration.statuses.${status}`);
		},
		getHistoryStatusClass(status) {
			return {
				da_dang_ky: 'bg-info-subtle text-info',
				da_xac_nhan: 'bg-primary-subtle text-primary',
				da_duyet: 'bg-success-subtle text-success',
				dang_tham_gia: 'bg-warning-subtle text-warning',
				hoan_thanh: 'bg-success-subtle text-success',
				da_huy: 'bg-secondary-subtle text-secondary',
				tu_choi: 'bg-danger-subtle text-danger',
			}[status] || 'bg-light text-muted';
		},
		getHistoryStatusIcon(status) {
			return {
				da_dang_ky: 'fa-solid fa-clipboard-check',
				da_xac_nhan: 'fa-solid fa-circle-check',
				da_duyet: 'fa-solid fa-badge-check',
				dang_tham_gia: 'fa-solid fa-person-running',
				hoan_thanh: 'fa-solid fa-check-double',
				da_huy: 'fa-solid fa-ban',
				tu_choi: 'fa-solid fa-xmark',
			}[status] || 'fa-solid fa-circle';
		},
		getReportStatusLabel(status) {
			return this.$t(`feedback.reportStatuses.${status}`);
		},
		getReportStatusClass(status) {
			return {
				moi: 'bg-warning-subtle text-warning',
				dang_xu_ly: 'bg-info-subtle text-info',
				da_xu_ly: 'bg-success-subtle text-success',
				tu_choi: 'bg-danger-subtle text-danger',
			}[status] || 'bg-light text-muted';
		},
		formatDate(input) {
			if (!input) return this.$t('common.notAvailable');
			const d = new Date(input);
			if (Number.isNaN(d.getTime())) return input;
			return d.toLocaleDateString('vi-VN');
		},
		formatDateTime(input) {
			if (!input) return this.$t('common.notAvailable');
			const d = new Date(input.replace(' ', 'T'));
			if (Number.isNaN(d.getTime())) return input;
			return d.toLocaleString('vi-VN');
		},
		formatCampaignDateRange(chienDich) {
			if (!chienDich) return this.$t('common.notAvailable');
			const from = this.formatDate(chienDich.ngay_bat_dau);
			const to = this.formatDate(chienDich.ngay_ket_thuc);
			if (from === to) return from;
			return `${from} - ${to}`;
		},
		getCampaignColor(campaignId) {
			const palette = ['#198754', '#0d6efd', '#fd7e14', '#dc3545', '#6f42c1', '#20c997'];
			return palette[(campaignId || 0) % palette.length];
		},
		getRatingLabel(value) {
			if (!value) return '';
			return this.$t(`feedback.ratingLabels.${value}`);
		},
		viewCampaign(item) {
			if (!item?.chien_dich_id) return;
			this.$router.push(`/chi-tiet-chien-dich/${item.chien_dich_id}`);
		},
		toggleActionMenu(event, item) {
			if (!item) return;
			if (this.actionMenu.visible && this.actionMenu.item?.id === item.id) {
				this.closeActionMenu();
				return;
			}
			const rect = event.currentTarget.getBoundingClientRect();
			const menuWidth = 240;
			const menuHeight = 180;
			const margin = 8;
			let left = rect.right - menuWidth;
			let top = rect.bottom + margin;
			if (left < margin) left = margin;
			if (top + menuHeight > window.innerHeight - margin) {
				top = Math.max(margin, rect.top - menuHeight - margin);
			}
			this.actionMenu = {
				visible: true,
				item,
				top,
				left,
			};
		},
		closeActionMenu() {
			this.actionMenu.visible = false;
			this.actionMenu.item = null;
		},
		handleViewDetailFromMenu() {
			this.viewCampaign(this.actionMenu.item);
			this.closeActionMenu();
		},
		handleFeedbackFromMenu() {
			this.openFeedback(this.actionMenu.item);
			this.closeActionMenu();
		},
		handleReportFromMenu() {
			this.openReport(this.actionMenu.item);
			this.closeActionMenu();
		},
		openFeedback(item) {
			this.feedbackTarget = item;
			this.feedbackRating = Number(item?.phan_hoi_chien_dich?.so_sao || 0);
			this.feedbackText = item?.phan_hoi_chien_dich?.nhan_xet || '';
			this.selectedFeedbackTags = Array.isArray(item?.phan_hoi_chien_dich?.the_ids)
				? [...item.phan_hoi_chien_dich.the_ids]
				: [];
			this.showFeedbackModal = true;
		},
		closeFeedbackModal() {
			this.showFeedbackModal = false;
			this.feedbackTarget = null;
			this.feedbackRating = 0;
			this.feedbackText = '';
			this.selectedFeedbackTags = [];
		},
		toggleFeedbackTag(tagId) {
			const idx = this.selectedFeedbackTags.indexOf(tagId);
			if (idx > -1) this.selectedFeedbackTags.splice(idx, 1);
			else this.selectedFeedbackTags.push(tagId);
		},
		async submitFeedback() {
			if (!this.feedbackTarget?.chien_dich_id || !this.feedbackRating) {
				return;
			}
			this.submittingFeedback = true;
			try {
				await api.post('/tinh-nguyen-vien/theo-doi-phan-hoi/danh-gia-chien-dich', {
					chien_dich_id: this.feedbackTarget.chien_dich_id,
					so_sao: this.feedbackRating,
					nhan_xet: this.feedbackText,
					the_ids: this.selectedFeedbackTags,
				});
				this.showToast('success', this.$t('common.success'), this.$t('feedback.submitSuccess'));
				this.closeFeedbackModal();
				await this.loadData();
			} catch (error) {
				this.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('feedback.submitError'));
			} finally {
				this.submittingFeedback = false;
			}
		},
		openReport(item) {
			this.reportTarget = item;
			this.reportCategory = '';
			this.reportTitle = '';
			this.reportContent = '';
			this.showReportModal = true;
		},
		closeReportModal() {
			this.showReportModal = false;
			this.reportTarget = null;
			this.reportCategory = '';
			this.reportTitle = '';
			this.reportContent = '';
		},
		async submitReport() {
			if (!this.reportTarget?.chien_dich_id || !this.reportCategory || !this.reportTitle || !this.reportContent) {
				this.showToast('warning', this.$t('common.warning'), this.$t('feedback.reportRequiredFields'));
				return;
			}

			this.submittingReport = true;
			try {
				await api.post('/tinh-nguyen-vien/theo-doi-phan-hoi/bao-cao', {
					chien_dich_id: this.reportTarget.chien_dich_id,
					phan_loai: this.reportCategory,
					tieu_de: this.reportTitle,
					noi_dung: this.reportContent,
				});
				this.showToast('success', this.$t('common.success'), this.$t('feedback.reportSuccess'));
				this.closeReportModal();
				this.activeTab = 'reports';
				await this.loadData();
			} catch (error) {
				this.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('feedback.reportError'));
			} finally {
				this.submittingReport = false;
			}
		},
		showToast(type, title, message) {
			if (this.toast && typeof this.toast.showToast === 'function') {
				this.toast.showToast(type, title, message);
			}
		},
	},
};
</script>

<style scoped>
.min-w-0 { min-width: 0; }

.activity-icon {
	width: 40px;
	height: 40px;
	min-width: 40px;
}

.activity-row { transition: background 0.15s; }
.activity-row:hover { background-color: rgba(13, 110, 253, 0.03) !important; }
.action-menu {
	position: fixed;
	z-index: 2000;
	width: 240px;
}
.action-menu-backdrop {
	position: fixed;
	inset: 0;
	z-index: 1999;
	background: transparent;
}

.rating-circle {
	width: 100px;
	height: 100px;
	border-radius: 50%;
	background: linear-gradient(135deg, #ffc107, #fd7e14);
	display: flex;
	align-items: center;
	justify-content: center;
}

.rating-number {
	font-size: 36px;
	font-weight: 800;
	color: white;
}

.rating-row { transition: background 0.2s; }
.rating-row:hover { background: #f8f9fa; }
.rating-row:last-child { border-bottom: none !important; }

.star-feedback {
	font-size: 28px;
	cursor: pointer;
	transition: transform 0.15s;
}
.star-feedback:hover { transform: scale(1.2); }

.skill-tag { transition: all 0.15s ease; user-select: none; }
.skill-tag:hover { opacity: 0.85; }

.nav-tabs-custom .nav-link {
	border: none;
	border-bottom: 3px solid transparent;
	border-radius: 0;
	font-size: 13px;
}
.nav-tabs-custom .nav-link.active {
	border-bottom-color: #0d6efd;
	background: transparent;
}
.nav-tabs-custom .nav-link:hover:not(.active) { border-bottom-color: #dee2e6; }

@media (max-width: 575.98px) {
	.activity-icon { width: 34px; height: 34px; font-size: 12px; }
}
</style>
