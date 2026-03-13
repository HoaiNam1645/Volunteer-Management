<template>
	<div class="bg-light min-vh-100 pb-5">
		<div class="container pt-4">
			<!-- Page Header -->
			<PageHeader
				:title="$t('feedback.title')"
				icon="fa-solid fa-clock-rotate-left"
				:breadcrumbs="[{ label: $t('common.home'), to: '/'}, { label: $t('feedback.title') }]">
			</PageHeader>

			<!-- Stats -->
			<StatCards :cards="statCards" />

			<!-- Tabs -->
			<ul class="nav nav-tabs nav-tabs-custom border-bottom-0 flex-nowrap overflow-auto mb-0">
				<li class="nav-item" v-for="tab in tabs" :key="tab.value">
					<a class="nav-link px-3 px-md-4 py-2 fw-medium text-nowrap"
						:class="{ 'active text-primary': activeTab === tab.value, 'text-muted': activeTab !== tab.value }"
						href="#" @click.prevent="activeTab = tab.value">
						<i :class="tab.icon" class="me-1"></i>{{ tab.label }}
						<span class="badge ms-1 rounded-pill" :class="activeTab === tab.value ? 'bg-primary' : 'bg-light text-muted'" v-if="tab.count">{{ tab.count }}</span>
					</a>
				</li>
			</ul>

			<!-- TAB: Lịch sử hoạt động -->
			<div class="card border-0 shadow-sm mb-4" v-if="activeTab === 'history'">
				<div class="card-header bg-white py-3">
					<div class="row g-2 align-items-center">
						<div class="col-md-5">
							<div class="input-group input-group-sm">
								<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
								<input type="text" class="form-control form-control-sm bg-light border-start-0 ps-0" :placeholder="$t('feedback.searchPlaceholder')" v-model="historySearch">
							</div>
						</div>
						<div class="col-md-3">
							<select class="form-select form-select-sm" v-model="historyFilter">
								<option value="">{{ $t('feedback.allStatuses') }}</option>
								<option value="completed">{{ $t('feedback.statuses.completed') }}</option>
								<option value="attending">{{ $t('feedback.statuses.attending') }}</option>
								<option value="registered">{{ $t('feedback.statuses.registered') }}</option>
								<option value="cancelled">{{ $t('feedback.statuses.cancelled') }}</option>
							</select>
						</div>
					</div>
				</div>
				<div class="card-body p-0">
					<div class="table-responsive">
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
											<div class="activity-icon rounded-3 d-flex align-items-center justify-content-center text-white flex-shrink-0" :style="{ background: h.color }">
												<i :class="h.icon" style="font-size: 14px;"></i>
											</div>
											<div class="min-w-0">
												<div class="fw-bold text-dark small text-truncate">{{ h.title }}</div>
												<div class="text-muted small text-truncate d-none d-sm-block">{{ h.org }}</div>
											</div>
										</div>
									</td>
									<td class="d-none d-md-table-cell">
										<span class="text-muted small"><i class="fa-solid fa-location-dot text-danger me-1"></i>{{ h.location }}</span>
									</td>
									<td class="d-none d-lg-table-cell">
										<span class="text-muted small"><i class="fa-regular fa-calendar me-1"></i>{{ h.date }}</span>
									</td>
									<td class="text-center">
										<span class="badge rounded-pill" :class="getHistoryStatusClass(h.status)">
											<i :class="getHistoryStatusIcon(h.status)" class="me-1"></i>{{ getHistoryStatusLabel(h.status) }}
										</span>
									</td>
									<td class="text-center d-none d-md-table-cell">
										<div class="d-flex justify-content-center gap-0" v-if="h.rating">
											<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= h.rating ? 'text-warning' : 'text-muted'" style="font-size:11px"></i>
										</div>
										<span class="text-muted small" v-else>—</span>
									</td>
									<td class="text-center">
										<div class="dropdown">
											<button class="btn btn-sm btn-light border-0 rounded-circle" data-bs-toggle="dropdown" style="width:30px;height:30px">
												<i class="fa-solid fa-ellipsis-vertical small"></i>
											</button>
											<ul class="dropdown-menu dropdown-menu-end shadow border-0 py-2">
												<li><a class="dropdown-item small py-2" href="#" @click.prevent="viewCampaign(h)"><i class="fa-regular fa-eye me-2 text-primary"></i>{{ $t('feedback.actions.viewDetail') }}</a></li>
												<li v-if="h.status === 'completed' && !h.feedback"><a class="dropdown-item small py-2" href="#" @click.prevent="openFeedback(h)"><i class="fa-solid fa-comment me-2 text-success"></i>{{ $t('feedback.actions.sendFeedback') }}</a></li>
												<li v-if="h.status === 'registered'"><a class="dropdown-item small py-2 text-danger" href="#" @click.prevent="cancelRegistration(h)"><i class="fa-solid fa-xmark me-2"></i>{{ $t('feedback.actions.cancelRegistration') }}</a></li>
											</ul>
										</div>
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

			<!-- TAB: Điểm đánh giá -->
			<div v-if="activeTab === 'scores'">
				<div class="row g-4">
					<div class="col-lg-4">
						<div class="card border-0 shadow-sm">
							<div class="card-body text-center p-4">
								<div class="rating-circle mx-auto mb-3">
									<span class="rating-number">{{ avgRating }}</span>
								</div>
								<div class="d-flex justify-content-center gap-1 mb-2">
									<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= Math.round(parseFloat(avgRating)) ? 'text-warning' : 'text-muted'" style="font-size:18px"></i>
								</div>
								<span class="text-muted small">{{ $t('feedback.basedOnReviews', { count: ratedActivities.length }) }}</span>
							</div>
						</div>
					</div>
					<div class="col-lg-8">
						<div class="card border-0 shadow-sm">
							<div class="card-header bg-white py-3">
								<h6 class="fw-bold mb-0"><i class="fa-solid fa-star text-warning me-2"></i>{{ $t('feedback.ratingDetailTitle') }}</h6>
							</div>
							<div class="card-body p-0">
								<div class="rating-row p-3 border-bottom d-flex align-items-center gap-3" v-for="h in ratedActivities" :key="h.id">
									<div class="activity-icon rounded-3 d-flex align-items-center justify-content-center text-white flex-shrink-0" :style="{ background: h.color }" style="width:38px;height:38px">
										<i :class="h.icon" style="font-size:13px"></i>
									</div>
									<div class="flex-grow-1 min-w-0">
										<div class="fw-bold small text-truncate">{{ h.title }}</div>
										<span class="text-muted" style="font-size:12px">{{ h.date }}</span>
									</div>
									<div class="d-flex gap-0 flex-shrink-0">
										<i v-for="i in 5" :key="i" class="fa-solid fa-star" :class="i <= h.rating ? 'text-warning' : 'text-muted'" style="font-size:13px"></i>
									</div>
									<span class="fw-bold small" style="min-width:30px">{{ h.rating }}/5</span>
								</div>
								<div class="text-center py-4 text-muted small" v-if="ratedActivities.length === 0">
									{{ $t('feedback.noRatings') }}
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- TAB: Thành tích -->
			<div v-if="activeTab === 'achievements'">
				<div class="row g-3">
					<div class="col-sm-6 col-lg-4" v-for="a in achievements" :key="a.id">
						<div class="card border-0 shadow-sm h-100 achievement-card" :class="{ 'unlocked': a.unlocked }">
							<div class="card-body p-4 text-center">
								<div class="achievement-badge mx-auto mb-3" :class="a.unlocked ? '' : 'locked'" :style="a.unlocked ? { background: a.color } : {}">
									<i :class="a.icon" style="font-size: 28px;"></i>
								</div>
								<h6 class="fw-bold mb-1">{{ a.title }}</h6>
								<p class="text-muted small mb-2">{{ a.description }}</p>
								<span class="badge rounded-pill px-3 py-2" :class="a.unlocked ? 'bg-success-subtle text-success' : 'bg-secondary-subtle text-secondary'">
									<i :class="a.unlocked ? 'fa-solid fa-check-circle' : 'fa-solid fa-lock'" class="me-1"></i>
									{{ a.unlocked ? $t('feedback.achieved') : $t('feedback.notAchieved') }}
								</span>
								<div class="progress mt-3" style="height:4px" v-if="!a.unlocked && a.progress !== undefined">
									<div class="progress-bar bg-primary" :style="{ width: a.progress + '%' }"></div>
								</div>
								<span class="text-muted small d-block mt-1" v-if="!a.unlocked && a.progress !== undefined">{{ a.progressText }}</span>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Feedback Modal -->
		<div class="modal fade" :class="{ show: showFeedbackModal }" :style="showFeedbackModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-comment text-success me-2"></i>{{ $t('feedback.actions.sendFeedback') }}</h5>
						<button type="button" class="btn-close" @click="showFeedbackModal = false"></button>
					</div>
					<div class="modal-body" v-if="feedbackTarget">
						<div class="bg-light rounded-3 p-3 mb-3">
							<span class="fw-bold small">{{ feedbackTarget.title }}</span>
							<span class="text-muted small d-block">{{ feedbackTarget.date }}</span>
						</div>
						<div class="text-center mb-3">
							<label class="form-label small fw-bold d-block">{{ $t('feedback.rateExperience') }}</label>
							<div class="d-flex justify-content-center gap-2">
								<i v-for="i in 5" :key="i" class="star-feedback"
									:class="i <= feedbackRating ? 'fa-solid fa-star text-warning' : 'fa-regular fa-star text-muted'"
									@click="feedbackRating = i"></i>
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
								<span v-for="tag in feedbackTags" :key="tag"
									class="badge rounded-pill px-3 py-2 skill-tag"
									:class="selectedFeedbackTags.includes(tag) ? 'bg-primary text-white' : 'bg-light text-dark border'"
									style="font-size: 12px; cursor: pointer;"
									@click="toggleFeedbackTag(tag)">{{ tag }}</span>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showFeedbackModal = false">{{ $t('common.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="submitFeedback" :disabled="!feedbackRating">
							<i class="fa-solid fa-paper-plane me-1"></i>{{ $t('feedback.actions.submit') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showFeedbackModal" @click="showFeedbackModal = false"></div>
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue'
import StatCards from '../../components/StatCards.vue'

export default {
	name: 'TheoDoiPhanHoi',
	components: { PageHeader, StatCards },
	data() {
		return {
			activeTab: 'history',
			historySearch: '',
			historyFilter: '',
			showFeedbackModal: false,
			feedbackTarget: null,
			feedbackRating: 0,
			feedbackText: '',
			selectedFeedbackTags: [],
			activities: [
				{ id: 1, title: 'Trồng cây xanh TP.HCM', org: 'VMS-AI', location: 'TP.HCM', date: '15/03/2026 — 20/03/2026', status: 'completed', rating: 5, feedback: true, icon: 'fa-solid fa-tree', color: '#198754' },
				{ id: 2, title: 'Dạy học miễn phí Sa Pa', org: 'Tình nguyện Vùng Cao', location: 'Lào Cai', date: '01/02/2026 — 15/02/2026', status: 'completed', rating: 4, feedback: true, icon: 'fa-solid fa-book-open', color: '#0d6efd' },
				{ id: 3, title: 'Khám bệnh cộng đồng', org: 'Quỹ Bảo Trợ', location: 'Quảng Nam', date: '25/03/2026 — 27/03/2026', status: 'attending', rating: null, feedback: false, icon: 'fa-solid fa-hand-holding-medical', color: '#dc3545' },
				{ id: 4, title: 'Mùa hè xanh 2026', org: 'Đoàn Thanh niên', location: 'Bến Tre', date: '01/06/2026 — 30/06/2026', status: 'registered', rating: null, feedback: false, icon: 'fa-solid fa-sun', color: '#fd7e14' },
				{ id: 5, title: 'Hỗ trợ sau bão Yagi', org: 'Hội Chữ thập đỏ', location: 'Quảng Ngãi', date: '01/10/2025 — 15/10/2025', status: 'completed', rating: 5, feedback: false, icon: 'fa-solid fa-house-flood-water', color: '#6c757d' },
				{ id: 6, title: 'Nấu ăn cho người vô gia cư', org: 'VMS-AI', location: 'TP.HCM', date: '10/01/2026', status: 'completed', rating: 4, feedback: true, icon: 'fa-solid fa-utensils', color: '#e83e8c' },
				{ id: 7, title: 'Tập huấn CNTT cho giáo viên', org: 'Microsoft Vietnam', location: 'Đắk Lắk', date: '05/04/2026 — 12/04/2026', status: 'cancelled', rating: null, feedback: false, icon: 'fa-solid fa-laptop-code', color: '#adb5bd' }
			],
			achievements: [
				{ id: 1, title: 'Người bạn mới', description: 'Tham gia chiến dịch đầu tiên', icon: 'fa-solid fa-seedling', color: '#198754', unlocked: true },
				{ id: 2, title: 'Tình nguyện viên tích cực', description: 'Tham gia 5 chiến dịch', icon: 'fa-solid fa-fire', color: '#fd7e14', unlocked: true },
				{ id: 3, title: 'Ngôi sao cộng đồng', description: 'Đạt đánh giá trung bình 4.5+', icon: 'fa-solid fa-star', color: '#ffc107', unlocked: true },
				{ id: 4, title: 'Bền bỉ', description: 'Tham gia liên tục 3 tháng', icon: 'fa-solid fa-shield-halved', color: '#0d6efd', unlocked: true },
				{ id: 5, title: 'Nhà lãnh đạo', description: 'Tham gia 10 chiến dịch', icon: 'fa-solid fa-crown', color: '#6f42c1', unlocked: false, progress: 60, progressText: '6/10 chiến dịch' },
				{ id: 6, title: 'Đa năng', description: 'Tham gia 3 lĩnh vực khác nhau', icon: 'fa-solid fa-puzzle-piece', color: '#20c997', unlocked: false, progress: 66, progressText: '2/3 lĩnh vực' },
				{ id: 7, title: 'Người truyền cảm hứng', description: 'Gửi 10 phản hồi tích cực', icon: 'fa-solid fa-heart', color: '#dc3545', unlocked: false, progress: 30, progressText: '3/10 phản hồi' },
				{ id: 8, title: 'Chuyên gia', description: 'Đạt 5 sao ở 5 chiến dịch', icon: 'fa-solid fa-gem', color: '#0dcaf0', unlocked: false, progress: 40, progressText: '2/5 chiến dịch 5 sao' }
			]
		}
	},
	computed: {
		tabs() {
			return [
				{ label: this.$t('feedback.tabs.history'), value: 'history', icon: 'fa-solid fa-clock-rotate-left' },
				{ label: this.$t('feedback.tabs.scores'), value: 'scores', icon: 'fa-solid fa-star' },
				{ label: this.$t('feedback.tabs.achievements'), value: 'achievements', icon: 'fa-solid fa-trophy' }
			];
		},
		feedbackTags() {
			return [
				this.$t('feedback.tags.organize'),
				this.$t('feedback.tags.logistics'),
				this.$t('feedback.tags.communication'),
				this.$t('feedback.tags.safety'),
				this.$t('feedback.tags.time'),
				this.$t('feedback.tags.other')
			];
		},
		statCards() {
			return [
				{ label: this.$t('feedback.stats.joined'), value: this.activities.filter(a => a.status === 'completed').length, icon: 'fa-solid fa-circle-check', color: 'success' },
				{ label: this.$t('feedback.stats.attending'), value: this.activities.filter(a => a.status === 'attending').length, icon: 'fa-solid fa-play', color: 'primary' },
				{ label: this.$t('feedback.stats.avgRating'), value: this.avgRating, icon: 'fa-solid fa-star', color: 'warning' },
				{ label: this.$t('feedback.stats.achievements'), value: this.achievements.filter(a => a.unlocked).length + '/' + this.achievements.length, icon: 'fa-solid fa-trophy', color: 'info' }
			];
		},
		filteredHistory() {
			let list = this.activities;
			if (this.historySearch) {
				const q = this.historySearch.toLowerCase();
				list = list.filter(h => h.title.toLowerCase().includes(q));
			}
			if (this.historyFilter) list = list.filter(h => h.status === this.historyFilter);
			return list;
		},
		ratedActivities() {
			return this.activities.filter(a => a.rating);
		},
		avgRating() {
			const rated = this.ratedActivities;
			if (rated.length === 0) return '0.0';
			return (rated.reduce((s, a) => s + a.rating, 0) / rated.length).toFixed(1);
		}
	},
	methods: {
		getHistoryStatusLabel(s) {
			return this.$t('feedback.statuses.' + s) || s;
		},
		getHistoryStatusClass(s) {
			return { completed: 'bg-success-subtle text-success', attending: 'bg-primary-subtle text-primary', registered: 'bg-info-subtle text-info', cancelled: 'bg-secondary-subtle text-secondary' }[s];
		},
		getHistoryStatusIcon(s) {
			return { completed: 'fa-solid fa-circle-check', attending: 'fa-solid fa-play', registered: 'fa-solid fa-clipboard-check', cancelled: 'fa-solid fa-ban' }[s];
		},
		getRatingLabel(r) {
			if (!r) return '';
			return this.$t(`feedback.ratingLabels.${r}`);
		},
		viewCampaign(h) {
			this.$router.push('/chi-tiet-chien-dich/' + h.id);
		},
		cancelRegistration(h) {
			h.status = 'cancelled';
		},
		openFeedback(h) {
			this.feedbackTarget = h;
			this.feedbackRating = 0;
			this.feedbackText = '';
			this.selectedFeedbackTags = [];
			this.showFeedbackModal = true;
		},
		toggleFeedbackTag(tag) {
			const idx = this.selectedFeedbackTags.indexOf(tag);
			if (idx > -1) this.selectedFeedbackTags.splice(idx, 1);
			else this.selectedFeedbackTags.push(tag);
		},
		submitFeedback() {
			if (this.feedbackTarget) {
				this.feedbackTarget.feedback = true;
			}
			this.showFeedbackModal = false;
		}
	}
}
</script>

<style scoped>
.min-w-0 { min-width: 0; }

.activity-icon {
	width: 40px;
	height: 40px;
	min-width: 40px;
}

.activity-row { transition: background 0.15s; }
.activity-row:hover { background-color: rgba(13,110,253,0.03) !important; }

/* Rating */
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

/* Achievement */
.achievement-card {
	border-radius: 16px !important;
	transition: transform 0.2s ease;
}
.achievement-card:hover { transform: translateY(-3px); }
.achievement-card.unlocked { border-left: 4px solid #198754 !important; }

.achievement-badge {
	width: 64px;
	height: 64px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
}

.achievement-badge.locked {
	background: #e9ecef;
	color: #adb5bd;
}

/* Feedback Stars */
.star-feedback {
	font-size: 28px;
	cursor: pointer;
	transition: transform 0.15s;
}
.star-feedback:hover { transform: scale(1.2); }

/* Tags */
.skill-tag { transition: all 0.15s ease; user-select: none; }
.skill-tag:hover { opacity: 0.85; }

/* Tabs */
.nav-tabs-custom .nav-link { border: none; border-bottom: 3px solid transparent; border-radius: 0; font-size: 13px; }
.nav-tabs-custom .nav-link.active { border-bottom-color: #0d6efd; background: transparent; }
.nav-tabs-custom .nav-link:hover:not(.active) { border-bottom-color: #dee2e6; }

@media (max-width: 575.98px) {
	.activity-icon { width: 34px; height: 34px; font-size: 12px; }
}
</style>
