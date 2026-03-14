<template>
	<div>
		<!-- Page Header -->
		<PageHeader
			:title="$t('coordinator.volunteerCoordination')"
			icon="fa-solid fa-people-arrows"
			:breadcrumbs="[{ label: $t('common.home'), to: '/'}, { label: $t('coordinator.campaignManagement'), to: '/quan-ly-chien-dich'}, { label: $t('coordinator.volunteerCoordination') }]">
			<template #actions>
				<button class="btn btn-outline-primary shadow-sm btn-sm" @click="showHelpGuide = true">
					<i class="fa-solid fa-circle-question me-1"></i>{{ $t('coordinator.guideBtn') }}
				</button>
			</template>
		</PageHeader>

		<!-- Stats -->
		<StatCards :cards="statCards" />

		<!-- Campaign Selection -->
		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body">
				<div class="row g-3 align-items-end">
					<div class="col-md-5">
						<label class="form-label fw-semibold small"><i class="fa-solid fa-flag text-primary me-1"></i>{{ $t('coordinator.selectCampaignLabel') }}</label>
						<select class="form-select" v-model="selectedCampaignId">
							<option value="">{{ $t('coordinator.selectCampaignPlaceholder') }}</option>
							<option v-for="c in campaigns" :key="c.id" :value="c.id">{{ c.name }} ({{ c.location }})</option>
						</select>
					</div>
					<div class="col-md-3">
						<label class="form-label fw-semibold small"><i class="fa-solid fa-ruler-combined text-muted me-1"></i>{{ $t('coordinator.radiusLabel') }}</label>
						<select class="form-select" v-model="radiusKm">
							<option value="10">{{ $t('coordinator.radius10') }}</option>
							<option value="25">{{ $t('coordinator.radius25') }}</option>
							<option value="50">{{ $t('coordinator.radius50') }}</option>
							<option value="100">{{ $t('coordinator.radius100') }}</option>
							<option value="0">{{ $t('coordinator.radiusUnlimited') }}</option>
						</select>
					</div>
					<div class="col-md-4 d-flex gap-2">
						<button class="btn btn-primary flex-grow-1" :disabled="!selectedCampaignId" @click="runAISuggestion">
							<i class="fa-solid fa-wand-magic-sparkles me-1"></i>{{ $t('coordinator.aiSuggestBtn') }}
						</button>
						<button class="btn btn-outline-secondary" :disabled="!selectedCampaignId" @click="openManualAssign">
							<i class="fa-solid fa-hand-pointer me-1"></i>{{ $t('coordinator.manualBtn') }}
						</button>
					</div>
				</div>

				<!-- Campaign Info Strip -->
				<div class="mt-3 p-3 bg-light rounded-3" v-if="activeCampaign">
					<div class="row g-2 align-items-center">
						<div class="col-sm-4">
							<span class="text-muted small d-block">{{ $t('coordinator.campaignLabel') }}</span>
							<span class="fw-bold small">{{ activeCampaign.name }}</span>
						</div>
						<div class="col-sm-2">
							<span class="text-muted small d-block">{{ $t('coordinator.needLabel') }}</span>
							<span class="fw-bold small text-primary">{{ activeCampaign.need }} {{ $t('common.people') }}</span>
						</div>
						<div class="col-sm-3">
							<span class="text-muted small d-block">{{ $t('coordinator.skillsReqLabel') }}</span>
							<div class="d-flex flex-wrap gap-1 mt-1">
								<span class="badge bg-primary-subtle text-primary" style="font-size: 10px;" v-for="s in activeCampaign.skills" :key="s">{{ s }}</span>
							</div>
						</div>
						<div class="col-sm-3">
							<span class="text-muted small d-block">{{ $t('coordinator.areaLabel') }}</span>
							<span class="fw-bold small"><i class="fa-solid fa-location-dot text-danger me-1"></i>{{ activeCampaign.location }}</span>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- AI Banner -->
		<div class="ai-banner rounded-4 p-4 mb-4" v-if="!showResults && !showManual">
			<div class="row align-items-center">
				<div class="col-lg-8">
					<h5 class="fw-bold text-white mb-2"><i class="fa-solid fa-microchip me-2"></i>{{ $t('coordinator.aiSystemTitle') }}</h5>
					<p class="text-white-50 small mb-3">
						{{ $t('coordinator.aiSystemDesc1') }} <strong class="text-white">{{ $t('coordinator.aiSystemDescContentBased') }}</strong> {{ $t('coordinator.aiSystemDesc2') }} 
						<strong class="text-white">{{ $t('coordinator.aiSystemDescCosine') }}</strong> {{ $t('coordinator.aiSystemDesc3') }} 
						<strong class="text-white">{{ $t('coordinator.aiSystemDescHaversine') }}</strong>.
					</p>
					<div class="d-flex flex-wrap gap-2">
						<span class="badge bg-white bg-opacity-25 rounded-pill px-3 py-2"><i class="fa-solid fa-brain me-1"></i>{{ $t('coordinator.aiSystemDescContentBased') }}</span>
						<span class="badge bg-white bg-opacity-25 rounded-pill px-3 py-2"><i class="fa-solid fa-calculator me-1"></i>{{ $t('coordinator.aiSystemDescCosine') }}</span>
						<span class="badge bg-white bg-opacity-25 rounded-pill px-3 py-2"><i class="fa-solid fa-map-pin me-1"></i>{{ $t('coordinator.aiSystemDescHaversine') }}</span>
					</div>
				</div>
				<div class="col-lg-4 text-center d-none d-lg-flex flex-column align-items-center justify-content-center">
					<i class="fa-solid fa-robot" style="font-size: 80px; color: rgba(255,255,255,0.12);"></i>
				</div>
			</div>
		</div>

		<!-- AI Results -->
		<div class="card border-0 shadow-sm mb-4" v-if="showResults">
			<div class="card-header bg-white border-bottom py-3">
				<div class="d-flex flex-column flex-sm-row align-items-start align-items-sm-center justify-content-between gap-2">
					<h6 class="fw-bold mb-0">
						<i class="fa-solid fa-wand-magic-sparkles text-primary me-2"></i>{{ $t('coordinator.aiResultsTitle') }}
						<span class="badge bg-primary ms-2">{{ suggestions.length }} {{ $t('coordinator.matchedVolunteers') }}</span>
					</h6>
					<div class="d-flex gap-2 flex-wrap">
						<button class="btn btn-sm btn-success rounded-pill px-3" @click="approveSelected" :disabled="selectedIds.length === 0">
							<i class="fa-solid fa-check-double me-1"></i>{{ $t('coordinator.approveBtn') }} ({{ selectedIds.length }})
						</button>
						<button class="btn btn-sm btn-outline-primary rounded-pill px-3" @click="sendNotifications" :disabled="approvedList.length === 0">
							<i class="fa-solid fa-paper-plane me-1"></i>{{ $t('coordinator.sendNotifBtn') }}
						</button>
						<button class="btn btn-sm btn-outline-secondary rounded-pill px-3" @click="showResults = false">
							<i class="fa-solid fa-arrow-left me-1"></i>{{ $t('common.back') }}
						</button>
					</div>
				</div>
			</div>
			<div class="card-body p-0">
				<!-- Approved summary -->
				<div class="px-3 py-2 bg-success bg-opacity-10 border-bottom d-flex align-items-center gap-2" v-if="approvedList.length > 0">
					<i class="fa-solid fa-circle-check text-success"></i>
					<span class="small fw-bold text-success">{{ approvedList.length }} {{ $t('coordinator.volunteersApproved') }}</span>
				</div>

				<div class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead>
							<tr class="bg-light">
								<th class="fw-semibold text-muted small text-uppercase py-3 ps-3 border-0" style="width:40px">
									<input class="form-check-input" type="checkbox" @change="toggleSelectAll" :checked="allSelected">
								</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0">{{ $t('campaignDetail.volunteerCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('coordinator.matchScoreCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-md-table-cell">{{ $t('coordinator.matchedSkillsCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-lg-table-cell">{{ $t('coordinator.distanceCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-lg-table-cell">{{ $t('coordinator.experienceCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('coordinator.statusCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center" style="width:50px"></th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="s in suggestions" :key="s.id" :class="{ 'bg-success bg-opacity-10': s.approved }">
								<td class="ps-3">
									<input class="form-check-input" type="checkbox" :value="s.id" v-model="selectedIds" :disabled="s.approved">
								</td>
								<td>
									<div class="d-flex align-items-center gap-2 gap-md-3">
										<div class="user-avatar rounded-circle d-flex align-items-center justify-content-center text-white flex-shrink-0"
											:style="{ background: s.color }">{{ s.name.charAt(0) }}</div>
										<div class="min-w-0">
											<div class="fw-bold text-dark small text-truncate">{{ s.name }}</div>
											<div class="text-muted small text-truncate d-none d-sm-block">{{ s.email }}</div>
										</div>
									</div>
								</td>
								<td class="text-center">
									<div class="score-ring" :class="getScoreClass(s.score)">
										<span>{{ s.score }}%</span>
									</div>
								</td>
								<td class="d-none d-md-table-cell">
									<div class="d-flex flex-wrap gap-1">
										<span class="badge bg-primary-subtle text-primary" style="font-size: 10px;" v-for="sk in s.matchedSkills" :key="sk">{{ sk }}</span>
									</div>
								</td>
								<td class="d-none d-lg-table-cell">
									<span class="small" :class="s.distance <= 25 ? 'text-success fw-bold' : 'text-muted'">
										<i class="fa-solid fa-location-dot me-1"></i>{{ s.distance }} km
									</span>
								</td>
								<td class="d-none d-lg-table-cell">
									<div class="d-flex align-items-center gap-1">
										<i class="fa-solid fa-star text-warning" v-for="i in s.exp" :key="i" style="font-size: 11px;"></i>
										<i class="fa-regular fa-star text-muted" v-for="i in (5 - s.exp)" :key="'e'+i" style="font-size: 11px;"></i>
									</div>
								</td>
								<td class="text-center">
									<span class="badge rounded-pill" :class="s.approved ? 'bg-success text-white' : (s.available ? 'bg-success-subtle text-success' : 'bg-secondary-subtle text-secondary')">
										{{ s.approved ? $t('coordinator.statusAssigned') : (s.available ? $t('coordinator.statusReady') : $t('coordinator.statusBusy')) }}
									</span>
								</td>
								<td class="text-center">
									<div class="dropdown" v-if="!s.approved">
										<button class="btn btn-sm btn-light border-0 rounded-circle" data-bs-toggle="dropdown" style="width:30px;height:30px">
											<i class="fa-solid fa-ellipsis-vertical small"></i>
										</button>
										<ul class="dropdown-menu dropdown-menu-end shadow border-0 py-2">
											<li><a class="dropdown-item small py-2" href="#" @click.prevent="approveSingle(s)"><i class="fa-solid fa-check me-2 text-success"></i>{{ $t('coordinator.approveBtn') }}</a></li>
											<li><a class="dropdown-item small py-2" href="#" @click.prevent="removeSuggestion(s)"><i class="fa-solid fa-xmark me-2 text-danger"></i>{{ $t('coordinator.removeBtn') }}</a></li>
										</ul>
									</div>
									<i v-else class="fa-solid fa-circle-check text-success"></i>
								</td>
							</tr>
						</tbody>
					</table>
				</div>
			</div>
		</div>

		<!-- Manual Assignment -->
		<div class="card border-0 shadow-sm mb-4" v-if="showManual">
			<div class="card-header bg-white border-bottom py-3">
				<div class="d-flex align-items-center justify-content-between">
					<h6 class="fw-bold mb-0"><i class="fa-solid fa-hand-pointer text-warning me-2"></i>{{ $t('coordinator.manualAssignTitle') }}</h6>
					<button class="btn btn-sm btn-outline-secondary rounded-pill px-3" @click="showManual = false">
						<i class="fa-solid fa-arrow-left me-1"></i>{{ $t('common.back') }}
					</button>
				</div>
			</div>
			<div class="card-body">
				<div class="row g-3 mb-3">
					<div class="col-md-6">
						<div class="input-group input-group-sm">
							<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
							<input type="text" class="form-control form-control-sm bg-light border-start-0 ps-0" :placeholder="$t('coordinator.searchVolunteerPlaceholder')" v-model="manualSearch">
						</div>
					</div>
					<div class="col-md-3">
						<select class="form-select form-select-sm bg-light" v-model="manualSkillFilter">
							<option value="">{{ $t('coordinator.allSkillsOpt') }}</option>
							<option v-for="s in activeCampaign?.skills || []" :key="s" :value="s">{{ s }}</option>
						</select>
					</div>
					<div class="col-md-3 text-end">
						<button class="btn btn-success btn-sm rounded-pill px-3" :disabled="manualSelectedIds.length === 0" @click="confirmManualAssign">
							<i class="fa-solid fa-check me-1"></i>{{ $t('coordinator.approveBtn') }} ({{ manualSelectedIds.length }})
						</button>
					</div>
				</div>

				<div class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead>
							<tr class="bg-light">
								<th class="ps-3 border-0" style="width:40px"><input class="form-check-input" type="checkbox" @change="toggleManualAll" :checked="allManualSelected"></th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0">{{ $t('campaignDetail.volunteerCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-md-table-cell">{{ $t('campaignDetail.skillsCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-lg-table-cell">{{ $t('campaignDetail.areaCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('coordinator.statusCol') }}</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="v in filteredManualList" :key="v.id">
								<td class="ps-3"><input class="form-check-input" type="checkbox" :value="v.id" v-model="manualSelectedIds"></td>
								<td>
									<div class="d-flex align-items-center gap-2">
										<div class="user-avatar rounded-circle d-flex align-items-center justify-content-center text-white flex-shrink-0" :style="{ background: v.color }">{{ v.name.charAt(0) }}</div>
										<div>
											<div class="fw-bold small">{{ v.name }}</div>
											<div class="text-muted small d-none d-sm-block">{{ v.email }}</div>
										</div>
									</div>
								</td>
								<td class="d-none d-md-table-cell">
									<div class="d-flex flex-wrap gap-1">
										<span class="badge bg-light text-dark border" style="font-size:10px" v-for="sk in v.skills" :key="sk">{{ sk }}</span>
									</div>
								</td>
								<td class="d-none d-lg-table-cell"><span class="text-muted small"><i class="fa-solid fa-location-dot me-1 text-danger"></i>{{ v.location }}</span></td>
								<td class="text-center">
									<span class="badge rounded-pill" :class="v.available ? 'bg-success-subtle text-success' : 'bg-secondary-subtle text-secondary'">
										{{ v.available ? $t('coordinator.statusReady') : $t('coordinator.statusBusy') }}
									</span>
								</td>
							</tr>
							<tr v-if="filteredManualList.length === 0">
								<td colspan="5" class="text-center py-4 text-muted"><i class="fa-solid fa-inbox me-2"></i>{{ $t('coordinator.noVolunteerFound') }}</td>
							</tr>
						</tbody>
					</table>
				</div>
			</div>
		</div>

		<!-- Help Guide Modal -->
		<div class="modal fade" :class="{ show: showHelpGuide }" :style="showHelpGuide ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered modal-lg">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-circle-question text-primary me-2"></i>{{ $t('coordinator.guideTitle') }}</h5>
						<button type="button" class="btn-close" @click="showHelpGuide = false"></button>
					</div>
					<div class="modal-body">
						<div class="guide-steps">
							<div class="guide-step" v-for="(step, i) in guideSteps" :key="i">
								<div class="step-number" :class="step.color">{{ i + 1 }}</div>
								<div>
									<h6 class="fw-bold mb-1 small">{{ step.title }}</h6>
									<p class="text-muted mb-0 small">{{ step.desc }}</p>
								</div>
							</div>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="showHelpGuide = false">{{ $t('coordinator.understoodBtn') }}</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showHelpGuide" @click="showHelpGuide = false"></div>

		<!-- Send Notification Modal -->
		<div class="modal fade" :class="{ show: showNotifyModal }" :style="showNotifyModal ? 'display: block;' : ''" tabindex="-1">
			<div class="modal-dialog modal-dialog-centered">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<h5 class="modal-title fw-bold"><i class="fa-solid fa-paper-plane text-primary me-2"></i>{{ $t('coordinator.sendNotifTitle') }}</h5>
						<button type="button" class="btn-close" @click="showNotifyModal = false"></button>
					</div>
					<div class="modal-body">
						<div class="bg-primary bg-opacity-10 rounded-3 p-3 mb-3">
							<div class="d-flex align-items-center gap-2">
								<i class="fa-solid fa-users text-primary fs-5"></i>
								<div>
									<span class="fw-bold small">{{ approvedList.length }} {{ $t('coordinator.volunteersToReceiveNotif1') }}</span>
									<span class="text-muted small"> {{ $t('coordinator.volunteersToReceiveNotif2') }}</span>
								</div>
							</div>
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('coordinator.emailSubjectLabel') }}</label>
							<input type="text" class="form-control" v-model="notifySubject">
						</div>
						<div class="mb-3">
							<label class="form-label small fw-bold">{{ $t('coordinator.notifContentLabel') }}</label>
							<textarea class="form-control" rows="4" v-model="notifyMessage"></textarea>
						</div>
						<div class="form-check">
							<input class="form-check-input" type="checkbox" id="sendEmailCheck" v-model="sendEmail">
							<label class="form-check-label small" for="sendEmailCheck">{{ $t('coordinator.sendViaEmail') }}</label>
						</div>
						<div class="form-check">
							<input class="form-check-input" type="checkbox" id="sendSysCheck" v-model="sendSystem" checked>
							<label class="form-check-label small" for="sendSysCheck">{{ $t('coordinator.sendSystemNotif') }}</label>
						</div>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="showNotifyModal = false">{{ $t('common.cancel') }}</button>
						<button type="button" class="btn btn-primary rounded-pill px-4" @click="confirmSendNotifications">
							<i class="fa-solid fa-paper-plane me-1"></i>{{ $t('coordinator.sendNotifBtn') }}
						</button>
					</div>
				</div>
			</div>
		</div>
		<div class="modal-backdrop fade show" v-if="showNotifyModal" @click="showNotifyModal = false"></div>
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue'
import StatCards from '../../components/StatCards.vue'

export default {
	name: 'DieuPhoiNhanSu',
	components: { PageHeader, StatCards },
	data() {
		return {
			selectedCampaignId: '',
			radiusKm: '50',
			showResults: false,
			showManual: false,
			showHelpGuide: false,
			showNotifyModal: false,
			selectedIds: [],
			manualSelectedIds: [],
			manualSearch: '',
			manualSkillFilter: '',
			notifySubject: '',
			notifyMessage: '',
			sendEmail: true,
			sendSystem: true,
			campaigns: [
				{ id: 1, name: 'Trồng cây xanh Tây Nguyên', need: 80, skills: ['Xây dựng', 'Kỹ thuật', 'Lái xe'], location: 'Đắk Lắk' },
				{ id: 2, name: 'Dạy học miễn phí Sa Pa', need: 20, skills: ['Dạy học', 'Phiên dịch'], location: 'Lào Cai' },
				{ id: 3, name: 'Khám bệnh cộng đồng Quảng Nam', need: 30, skills: ['Y tế / Sơ cứu', 'Truyền thông'], location: 'Quảng Nam' },
				{ id: 4, name: 'Xây nhà tình thương Bến Tre', need: 40, skills: ['Xây dựng', 'Kỹ thuật'], location: 'Bến Tre' }
			],
			suggestions: [
				{ id: 1, name: 'Nguyễn Minh Tuấn', email: 'tuan.nm@gmail.com', score: 95, matchedSkills: ['Xây dựng', 'Kỹ thuật'], distance: 12, exp: 5, available: true, color: '#0d6efd', approved: false },
				{ id: 2, name: 'Trần Văn Sơn', email: 'son.tv@gmail.com', score: 92, matchedSkills: ['Xây dựng', 'Lái xe'], distance: 8, exp: 4, available: true, color: '#198754', approved: false },
				{ id: 3, name: 'Lê Hải Yến', email: 'yen.lh@gmail.com', score: 87, matchedSkills: ['Kỹ thuật', 'Lái xe'], distance: 22, exp: 4, available: true, color: '#dc3545', approved: false },
				{ id: 4, name: 'Phạm Thị Lan', email: 'lan.pt@gmail.com', score: 81, matchedSkills: ['Xây dựng'], distance: 35, exp: 3, available: true, color: '#6f42c1', approved: false },
				{ id: 5, name: 'Hoàng Đức Minh', email: 'minh.hd@gmail.com', score: 76, matchedSkills: ['Kỹ thuật'], distance: 45, exp: 3, available: false, color: '#fd7e14', approved: false },
				{ id: 6, name: 'Vũ Quốc Bảo', email: 'bao.vq@gmail.com', score: 72, matchedSkills: ['Lái xe'], distance: 18, exp: 2, available: true, color: '#20c997', approved: false },
				{ id: 7, name: 'Đặng Thị Hoa', email: 'hoa.dt@gmail.com', score: 68, matchedSkills: ['Xây dựng'], distance: 55, exp: 2, available: true, color: '#e83e8c', approved: false },
				{ id: 8, name: 'Ngô Thanh Tùng', email: 'tung.nt@gmail.com', score: 64, matchedSkills: ['Kỹ thuật'], distance: 30, exp: 2, available: true, color: '#17a2b8', approved: false }
			],
			allVolunteers: [
				{ id: 101, name: 'Trịnh Văn Nam', email: 'nam.tv@gmail.com', skills: ['Xây dựng', 'Lái xe', 'Kỹ thuật'], location: 'Đắk Lắk', available: true, color: '#0d6efd' },
				{ id: 102, name: 'Lý Thị Hương', email: 'huong.lt@gmail.com', skills: ['Dạy học', 'Truyền thông'], location: 'Gia Lai', available: true, color: '#e83e8c' },
				{ id: 103, name: 'Đỗ Quang Huy', email: 'huy.dq@gmail.com', skills: ['Y tế / Sơ cứu', 'Kỹ thuật'], location: 'Lâm Đồng', available: true, color: '#198754' },
				{ id: 104, name: 'Bùi Minh An', email: 'an.bm@gmail.com', skills: ['Xây dựng', 'Phiên dịch'], location: 'Đắk Nông', available: false, color: '#fd7e14' },
				{ id: 105, name: 'Phan Thị Mai', email: 'mai.pt@gmail.com', skills: ['Nấu ăn', 'Truyền thông', 'Lái xe'], location: 'Đắk Lắk', available: true, color: '#6f42c1' },
				{ id: 106, name: 'Hoàng Anh Dũng', email: 'dung.ha@gmail.com', skills: ['Kỹ thuật', 'Xây dựng'], location: 'Kon Tum', available: true, color: '#dc3545' },
				{ id: 107, name: 'Võ Ngọc Diệu', email: 'dieu.vn@gmail.com', skills: ['Phiên dịch', 'Dạy học', 'Truyền thông'], location: 'Đà Nẵng', available: true, color: '#20c997' },
				{ id: 108, name: 'Cao Văn Khánh', email: 'khanh.cv@gmail.com', skills: ['Lái xe', 'Xây dựng'], location: 'Đắk Lắk', available: true, color: '#17a2b8' }
			]
		}
	},
	computed: {
		activeCampaign() {
			return this.campaigns.find(c => c.id === Number(this.selectedCampaignId));
		},
		approvedList() {
			return this.suggestions.filter(s => s.approved);
		},
		allSelected() {
			const available = this.suggestions.filter(s => !s.approved);
			return available.length > 0 && available.every(s => this.selectedIds.includes(s.id));
		},
		allManualSelected() {
			return this.filteredManualList.length > 0 && this.filteredManualList.every(v => this.manualSelectedIds.includes(v.id));
		},
		filteredManualList() {
			let list = this.allVolunteers;
			if (this.manualSearch) {
				const q = this.manualSearch.toLowerCase();
				list = list.filter(v => v.name.toLowerCase().includes(q) || v.email.toLowerCase().includes(q));
			}
			if (this.manualSkillFilter) {
				list = list.filter(v => v.skills.includes(this.manualSkillFilter));
			}
			return list;
		},
		statCards() {
			return [
				{ label: this.$t('coordinator.statCampaigns'), value: this.campaigns.length, icon: 'fa-solid fa-flag', color: 'primary' },
				{ label: this.$t('coordinator.statAssigned'), value: this.approvedList.length, icon: 'fa-solid fa-user-check', color: 'success' },
				{ label: this.$t('coordinator.statPending'), value: this.suggestions.filter(s => !s.approved).length, icon: 'fa-solid fa-hourglass-half', color: 'warning' },
				{ label: this.$t('coordinator.statTotalVolunteers'), value: this.allVolunteers.length, icon: 'fa-solid fa-users', color: 'info' }
			];
		},
		guideSteps() {
			return [
				{ title: this.$t('coordinator.guideStep1Title'), desc: this.$t('coordinator.guideStep1Desc'), color: 'bg-primary' },
				{ title: this.$t('coordinator.guideStep2Title'), desc: this.$t('coordinator.guideStep2Desc'), color: 'bg-info' },
				{ title: this.$t('coordinator.guideStep3Title'), desc: this.$t('coordinator.guideStep3Desc'), color: 'bg-warning' },
				{ title: this.$t('coordinator.guideStep4Title'), desc: this.$t('coordinator.guideStep4Desc'), color: 'bg-success' },
				{ title: this.$t('coordinator.guideStep5Title'), desc: this.$t('coordinator.guideStep5Desc'), color: 'bg-danger' }
			];
		}
	},
	methods: {
		getScoreClass(score) {
			if (score >= 90) return 'score-excellent';
			if (score >= 75) return 'score-good';
			if (score >= 60) return 'score-average';
			return 'score-low';
		},
		runAISuggestion() {
			this.suggestions.forEach(s => { s.approved = false; });
			this.selectedIds = [];
			this.showResults = true;
			this.showManual = false;
		},
		openManualAssign() {
			this.manualSelectedIds = [];
			this.manualSearch = '';
			this.manualSkillFilter = '';
			this.showManual = true;
			this.showResults = false;
		},
		toggleSelectAll(e) {
			if (e.target.checked) {
				this.selectedIds = this.suggestions.filter(s => !s.approved).map(s => s.id);
			} else {
				this.selectedIds = [];
			}
		},
		toggleManualAll(e) {
			if (e.target.checked) {
				this.manualSelectedIds = this.filteredManualList.map(v => v.id);
			} else {
				this.manualSelectedIds = [];
			}
		},
		approveSelected() {
			this.suggestions.forEach(s => {
				if (this.selectedIds.includes(s.id)) s.approved = true;
			});
			this.selectedIds = [];
		},
		approveSingle(s) {
			s.approved = true;
			this.selectedIds = this.selectedIds.filter(id => id !== s.id);
		},
		removeSuggestion(s) {
			this.suggestions = this.suggestions.filter(x => x.id !== s.id);
		},
		confirmManualAssign() {
			this.manualSelectedIds = [];
			this.showManual = false;
		},
		sendNotifications() {
			this.notifySubject = `[VMS-AI] Phân công: ${this.activeCampaign?.name || ''}`;
			this.notifyMessage = `Chào bạn,\n\nBạn đã được phân công vào chiến dịch "${this.activeCampaign?.name || ''}". Vui lòng xác nhận tham gia trên hệ thống.\n\nTrân trọng,\nKiểm duyệt viên VMS-AI`;
			this.showNotifyModal = true;
		},
		confirmSendNotifications() {
			this.showNotifyModal = false;
		}
	}
}
</script>

<style scoped>
.user-avatar { width: 36px; height: 36px; min-width: 36px; font-weight: 700; font-size: 14px; }
.min-w-0 { min-width: 0; }

.ai-banner {
	background: linear-gradient(135deg, #1a1f36 0%, #2c3e6f 100%);
}

.score-ring {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	width: 48px;
	height: 48px;
	border-radius: 50%;
	font-size: 12px;
	font-weight: 800;
}

.score-excellent { background: rgba(25,135,84,0.12); color: #198754; border: 2px solid rgba(25,135,84,0.3); }
.score-good { background: rgba(13,110,253,0.12); color: #0d6efd; border: 2px solid rgba(13,110,253,0.3); }
.score-average { background: rgba(253,126,20,0.12); color: #fd7e14; border: 2px solid rgba(253,126,20,0.3); }
.score-low { background: rgba(108,117,125,0.12); color: #6c757d; border: 2px solid rgba(108,117,125,0.3); }

.guide-steps {
	display: flex;
	flex-direction: column;
	gap: 16px;
}

.guide-step {
	display: flex;
	align-items: flex-start;
	gap: 14px;
}

.step-number {
	width: 32px;
	height: 32px;
	min-width: 32px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: 700;
	font-size: 13px;
}

@media (max-width: 575.98px) {
	.user-avatar { width: 32px; height: 32px; font-size: 12px; }
	.score-ring { width: 40px; height: 40px; font-size: 11px; }
}
</style>
