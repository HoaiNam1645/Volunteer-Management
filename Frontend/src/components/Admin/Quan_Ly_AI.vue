<template>
	<div class="admin-ai">
		<!-- Page Header -->
		<div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-4">
			<div>
				<h4 class="fw-bold mb-1"><i class="fa-solid fa-robot text-primary me-2"></i>{{ $t('admin.ai.title') }}</h4>
				<p class="text-muted mb-0 small">{{ $t('admin.ai.subtitle') }}</p>
			</div>
		</div>

		<!-- AI Info Banner -->
		<div class="ai-info-banner mb-4">
			<div class="row align-items-center">
				<div class="col-lg-8">
					<h5 class="fw-bold text-white mb-2"><i class="fa-solid fa-microchip me-2"></i>{{ $t('admin.ai.banner.title') }}</h5>
					<p class="text-white-50 mb-3 small" v-html="$t('admin.ai.banner.desc')"></p>
					<div class="d-flex flex-wrap gap-2">
						<span class="badge bg-white bg-opacity-25 rounded-pill px-3 py-2">
							<i class="fa-solid fa-brain me-1"></i>Content-Based Filtering
						</span>
						<span class="badge bg-white bg-opacity-25 rounded-pill px-3 py-2">
							<i class="fa-solid fa-calculator me-1"></i>Cosine Similarity
						</span>
						<span class="badge bg-white bg-opacity-25 rounded-pill px-3 py-2">
							<i class="fa-solid fa-map-pin me-1"></i>Haversine Distance
						</span>
						<span class="badge bg-white bg-opacity-25 rounded-pill px-3 py-2">
							<i class="fa-solid fa-envelope me-1"></i>Auto Email Alert
						</span>
					</div>
				</div>
				<div class="col-lg-4 text-center d-none d-lg-block">
					<i class="fa-solid fa-network-wired" style="font-size: 80px; color: rgba(255,255,255,0.15);"></i>
				</div>
			</div>
		</div>

		<!-- Campaign Selection -->
		<div class="card border-0 shadow-sm mb-4">
			<div class="card-header bg-white border-bottom py-3">
				<h6 class="fw-bold mb-0"><i class="fa-solid fa-flag text-primary me-2"></i>{{ $t('admin.ai.campaignSelection.title') }}</h6>
			</div>
			<div class="card-body">
				<div class="row g-3">
					<div class="col-md-6">
						<select class="form-select" v-model="selectedCampaign">
							<option value="">{{ $t('admin.ai.campaignSelection.selectPlaceholder') }}</option>
							<option v-for="c in campaigns" :key="c.id" :value="c.id">{{ c.name }}</option>
						</select>
					</div>
					<div class="col-md-3">
						<select class="form-select" v-model="radiusKm">
							<option value="10">{{ $t('admin.ai.campaignSelection.radius.10') }}</option>
							<option value="25">{{ $t('admin.ai.campaignSelection.radius.25') }}</option>
							<option value="50">{{ $t('admin.ai.campaignSelection.radius.50') }}</option>
							<option value="100">{{ $t('admin.ai.campaignSelection.radius.100') }}</option>
							<option value="0">{{ $t('admin.ai.campaignSelection.radius.0') }}</option>
						</select>
					</div>
					<div class="col-md-3">
						<button class="btn btn-primary w-100" :disabled="!selectedCampaign" @click="runAI">
							<i class="fa-solid fa-wand-magic-sparkles me-2"></i>{{ $t('admin.ai.campaignSelection.runAiBtn') }}
						</button>
					</div>
				</div>

				<!-- Campaign Details -->
				<div class="mt-3 p-3 bg-light rounded-3" v-if="activeCampaign">
					<div class="row g-3">
						<div class="col-sm-4">
							<span class="text-muted small d-block">{{ $t('admin.ai.campaignSelection.campaignInfo.campaign') }}</span>
							<span class="fw-bold small">{{ activeCampaign.name }}</span>
						</div>
						<div class="col-sm-2">
							<span class="text-muted small d-block">{{ $t('admin.ai.campaignSelection.campaignInfo.need') }}</span>
							<span class="fw-bold small">{{ activeCampaign.need }} {{ $t('admin.ai.campaignSelection.campaignInfo.volunteers') }}</span>
						</div>
						<div class="col-sm-3">
							<span class="text-muted small d-block">{{ $t('admin.ai.campaignSelection.campaignInfo.skills') }}</span>
							<div class="d-flex flex-wrap gap-1 mt-1">
								<span class="badge bg-primary-subtle text-primary" style="font-size: 10px;" v-for="s in activeCampaign.skills" :key="s">{{ s }}</span>
							</div>
						</div>
						<div class="col-sm-3">
							<span class="text-muted small d-block">{{ $t('admin.ai.campaignSelection.campaignInfo.location') }}</span>
							<span class="fw-bold small"><i class="fa-solid fa-location-dot text-danger me-1"></i>{{ activeCampaign.location }}</span>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- AI Results -->
		<div class="card border-0 shadow-sm" v-if="showResults">
			<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
				<h6 class="fw-bold mb-0">
					<i class="fa-solid fa-wand-magic-sparkles text-primary me-2"></i>{{ $t('admin.ai.results.title') }}
					<span class="badge bg-primary ms-2">{{ $t('admin.ai.results.matchCount', { count: suggestions.length }) }}</span>
				</h6>
				<div class="d-flex gap-2">
					<button class="btn btn-sm btn-outline-success rounded-pill px-3">
						<i class="fa-solid fa-check-double me-1"></i>{{ $t('admin.ai.results.approveBtn') }}
					</button>
					<button class="btn btn-sm btn-outline-primary rounded-pill px-3">
						<i class="fa-solid fa-envelope me-1"></i>{{ $t('admin.ai.results.sendNotifyBtn') }}
					</button>
				</div>
			</div>
			<div class="card-body p-0">
				<div class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead class="table-light">
							<tr>
								<th class="ps-4" style="width: 40px;"><input class="form-check-input" type="checkbox"></th>
								<th>{{ $t('admin.ai.results.table.volunteer') }}</th>
								<th class="text-center">{{ $t('admin.ai.results.table.matchScore') }}</th>
								<th>{{ $t('admin.ai.results.table.matchedSkills') }}</th>
								<th>{{ $t('admin.ai.results.table.distance') }}</th>
								<th>{{ $t('admin.ai.results.table.experience') }}</th>
								<th class="text-center">{{ $t('admin.ai.results.table.status') }}</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="s in suggestions" :key="s.id" :class="{ 'table-success': s.score >= 90 }">
								<td class="ps-4"><input class="form-check-input" type="checkbox"></td>
								<td>
									<div class="d-flex align-items-center gap-3">
										<div class="ai-user-avatar" :style="{ background: s.color }">{{ s.name.charAt(0) }}</div>
										<div>
											<h6 class="mb-0 small fw-bold">{{ s.name }}</h6>
											<span class="text-muted" style="font-size: 12px;">{{ s.email }}</span>
										</div>
									</div>
								</td>
								<td class="text-center">
									<div class="score-badge" :class="getScoreClass(s.score)">
										{{ s.score }}%
									</div>
								</td>
								<td>
									<div class="d-flex flex-wrap gap-1">
										<span class="badge bg-primary-subtle text-primary" style="font-size: 10px;" v-for="sk in s.matchedSkills" :key="sk">{{ sk }}</span>
									</div>
								</td>
								<td>
									<span class="small" :class="s.distance <= 25 ? 'text-success fw-bold' : 'text-muted'">
										<i class="fa-solid fa-location-dot me-1"></i>{{ s.distance }} km
									</span>
								</td>
								<td>
									<div class="d-flex align-items-center gap-1">
										<i class="fa-solid fa-star text-warning" v-for="i in s.exp" :key="i" style="font-size: 11px;"></i>
										<i class="fa-regular fa-star text-muted" v-for="i in (5 - s.exp)" :key="'e'+i" style="font-size: 11px;"></i>
									</div>
								</td>
								<td class="text-center">
									<span class="badge rounded-pill" :class="s.available ? 'bg-success-subtle text-success' : 'bg-secondary-subtle text-secondary'">
										{{ s.available ? $t('admin.ai.results.available') : $t('admin.ai.results.busy') }}
									</span>
								</td>
							</tr>
						</tbody>
					</table>
				</div>
			</div>
		</div>

		<!-- Placeholder -->
		<div class="text-center py-5 card border-0 shadow-sm" v-if="!showResults">
			<div class="card-body">
				<div class="ai-placeholder-icon mx-auto mb-3">
					<i class="fa-solid fa-robot"></i>
				</div>
				<h5 class="fw-bold text-muted">{{ $t('admin.ai.placeholder.title') }}</h5>
				<p class="text-muted small" v-html="$t('admin.ai.placeholder.desc')"></p>
			</div>
		</div>
	</div>
</template>

<script>
export default {
	name: 'QuanLyAI',
	props: {
		toast: { type: Object, default: null }
	},
	data() {
		return {
			selectedCampaign: '',
			radiusKm: '50',
			showResults: false,
			campaigns: [
				{ id: 1, name: 'Trồng cây xanh Tây Nguyên 2026', need: 80, skills: ['Xây dựng', 'Kỹ thuật', 'Lái xe'], location: 'Đắk Lắk' },
				{ id: 2, name: 'Dạy học miễn phí Sapa', need: 20, skills: ['Dạy học', 'Phiên dịch'], location: 'Lào Cai' },
				{ id: 3, name: 'Khám bệnh cộng đồng Quảng Nam', need: 30, skills: ['Y tế / Sơ cứu', 'Truyền thông'], location: 'Quảng Nam' },
				{ id: 4, name: 'Xây nhà tình thương Bến Tre', need: 40, skills: ['Xây dựng', 'Kỹ thuật'], location: 'Bến Tre' }
			],
			suggestions: [
				{ id: 1, name: 'Nguyễn Minh Tuấn', email: 'tuan.nm@gmail.com', score: 95, matchedSkills: ['Xây dựng', 'Kỹ thuật'], distance: 12, exp: 5, available: true, color: '#0d6efd' },
				{ id: 2, name: 'Trần Văn Sơn', email: 'son.tv@gmail.com', score: 92, matchedSkills: ['Xây dựng', 'Lái xe'], distance: 8, exp: 4, available: true, color: '#198754' },
				{ id: 3, name: 'Lê Hải Yến', email: 'yen.lh@gmail.com', score: 87, matchedSkills: ['Kỹ thuật', 'Lái xe'], distance: 22, exp: 4, available: true, color: '#dc3545' },
				{ id: 4, name: 'Phạm Thị Lan', email: 'lan.pt@gmail.com', score: 81, matchedSkills: ['Xây dựng'], distance: 35, exp: 3, available: true, color: '#6f42c1' },
				{ id: 5, name: 'Hoàng Đức Minh', email: 'minh.hd@gmail.com', score: 76, matchedSkills: ['Kỹ thuật'], distance: 45, exp: 3, available: false, color: '#fd7e14' },
				{ id: 6, name: 'Vũ Quốc Bảo', email: 'bao.vq@gmail.com', score: 72, matchedSkills: ['Lái xe'], distance: 18, exp: 2, available: true, color: '#20c997' },
				{ id: 7, name: 'Đặng Thị Hoa', email: 'hoa.dt@gmail.com', score: 68, matchedSkills: ['Xây dựng'], distance: 55, exp: 2, available: true, color: '#e83e8c' }
			]
		}
	},
	computed: {
		activeCampaign() {
			return this.campaigns.find(c => c.id === Number(this.selectedCampaign));
		}
	},
	methods: {
		runAI() {
			this.showResults = true;
			if (this.toast) this.toast.success(this.$t('admin.ai.toast.successTitle'), this.$t('admin.ai.toast.successMsg', { count: this.suggestions.length }));
		},
		getScoreClass(score) {
			if (score >= 90) return 'score-excellent';
			if (score >= 75) return 'score-good';
			if (score >= 60) return 'score-average';
			return 'score-low';
		}
	}
}
</script>

<style scoped>
.ai-info-banner {
	background: linear-gradient(135deg, #1a1f36, #2c3e6f);
	border-radius: 16px;
	padding: 28px 32px;
}

.ai-user-avatar {
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

.score-badge {
	display: inline-block;
	padding: 4px 12px;
	border-radius: 20px;
	font-size: 13px;
	font-weight: 700;
}

.score-excellent {
	background: rgba(25, 135, 84, 0.12);
	color: #198754;
}

.score-good {
	background: rgba(13, 110, 253, 0.12);
	color: #0d6efd;
}

.score-average {
	background: rgba(253, 126, 20, 0.12);
	color: #fd7e14;
}

.score-low {
	background: rgba(108, 117, 125, 0.12);
	color: #6c757d;
}

.ai-placeholder-icon {
	width: 80px;
	height: 80px;
	border-radius: 50%;
	background: #f0f2f5;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 32px;
	color: #adb5bd;
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
