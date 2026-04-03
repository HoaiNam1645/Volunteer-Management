<template>
	<div>
		<!-- Page Header -->
		<PageHeader
			:title="$t('coordinator.campaignManagement')"
			icon="fa-solid fa-flag"
			:breadcrumbs="[{ label: $t('common.home'), to: '/'}, { label: $t('coordinator.campaignManagement') }]">
			<template #actions>
				<button v-if="canManageCampaigns" class="btn btn-primary shadow-sm" @click="openCreateModal">
					<i class="fa-solid fa-plus me-1 d-none d-sm-inline"></i>{{ $t('coordinator.createCampaign') }}
				</button>
			</template>
		</PageHeader>

		<!-- Stat Cards -->
		<StatCards :cards="statCards" />

		<!-- Filters & Table -->
		<div class="card border-0 shadow-sm">
			<!-- Status Tabs -->
			<div class="card-header bg-white border-bottom-0 pt-3 pb-0 px-3">
				<ul class="nav nav-tabs nav-tabs-custom border-bottom-0 flex-nowrap overflow-auto">
					<li class="nav-item" v-for="tab in statusTabs" :key="tab.value">
						<a class="nav-link px-3 px-md-4 py-2 fw-medium text-nowrap"
							:class="{ 'active text-primary': activeTab === tab.value, 'text-muted': activeTab !== tab.value }"
							href="#" @click.prevent="activeTab = tab.value">
							{{ tab.label }}
							<span class="badge ms-1 rounded-pill"
								:class="activeTab === tab.value ? 'bg-primary' : 'bg-light text-muted'">
								{{ getCountByStatus(tab.value) }}
							</span>
						</a>
					</li>
				</ul>
			</div>

			<div class="card-body px-3 px-md-4">
				<!-- Filters -->
				<div class="row g-2 g-md-3 mb-4">
					<div class="col-12 col-sm-6 col-lg-4">
						<div class="input-group input-group-sm">
							<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
							<input type="text" class="form-control form-control-sm bg-light border-start-0 ps-0" :placeholder="$t('coordinator.searchCampaignPlaceholder')" v-model="searchQuery">
						</div>
					</div>
					<div class="col-6 col-sm-3 col-lg-3">
						<select class="form-select form-select-sm bg-light border-0" v-model="filterCategory">
							<option value="">{{ $t('coordinator.allTypes') }}</option>
							<option v-for="t in campaignTypes" :key="t.id" :value="t.id">{{ t.ten }}</option>
						</select>
					</div>
					<div class="col-6 col-sm-3 col-lg-3">
						<select class="form-select form-select-sm bg-light border-0" v-model="filterPriority">
							<option value="">{{ $t('coordinator.allPriorities') }}</option>
							<option value="urgent">{{ $t('priorities.urgent') }}</option>
							<option value="high">{{ $t('priorities.high') }}</option>
							<option value="medium">{{ $t('priorities.medium') }}</option>
							<option value="low">{{ $t('priorities.low') }}</option>
						</select>
					</div>
					<div class="col-auto ms-auto d-flex align-items-center">
						<div class="btn-group btn-group-sm" role="group">
							<button class="btn" :class="viewMode === 'table' ? 'btn-primary' : 'btn-outline-primary'" @click="viewMode = 'table'"><i class="fa-solid fa-list"></i></button>
							<button class="btn" :class="viewMode === 'grid' ? 'btn-primary' : 'btn-outline-primary'" @click="viewMode = 'grid'"><i class="fa-solid fa-grip"></i></button>
						</div>
					</div>
				</div>

				<!-- TABLE VIEW -->
				<div v-if="viewMode === 'table'" class="table-responsive">
					<table class="table table-hover align-middle mb-0">
						<thead>
							<tr class="bg-light">
								<th class="fw-semibold text-muted small text-uppercase py-3 ps-3 border-0" style="min-width:250px">{{ $t('coordinator.campaignCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-lg-table-cell">{{ $t('coordinator.typeCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-xl-table-cell">{{ $t('coordinator.locationCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 d-none d-md-table-cell">{{ $t('coordinator.timeCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('coordinator.tnvCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center d-none d-sm-table-cell">{{ $t('coordinator.priorityCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center">{{ $t('coordinator.statusCol') }}</th>
								<th class="fw-semibold text-muted small text-uppercase py-3 border-0 text-center" style="width:110px">{{ $t('common.actions') }}</th>
							</tr>
						</thead>
						<tbody>
							<tr v-for="campaign in filteredCampaigns" :key="campaign.id" class="campaign-row">
								<td class="ps-3">
									<div class="d-flex align-items-center gap-2 gap-md-3">
										<div class="campaign-avatar rounded-3 d-flex align-items-center justify-content-center text-white flex-shrink-0" :style="getCampaignCoverStyle(campaign, 'avatar')">
											<i :class="campaign.icon"></i>
										</div>
										<div style="min-width: 0;">
											<div class="fw-bold text-dark text-truncate" style="max-width: 300px;">{{ campaign.title }}</div>
											<div class="text-muted small text-truncate d-none d-sm-block" style="max-width: 300px;" :title="campaign.description">{{ campaign.description }}</div>
										</div>
									</div>
								</td>
								<td class="d-none d-lg-table-cell"><span class="badge bg-light text-dark border small">{{ getCategoryLabel(campaign.category) }}</span></td>
								<td class="d-none d-xl-table-cell">
									<div class="text-muted small text-truncate" style="max-width: 200px;" :title="campaign.location">
										<i class="fa-solid fa-location-dot me-1 text-danger"></i>{{ campaign.location }}
									</div>
								</td>
								<td class="d-none d-md-table-cell"><span class="text-muted small"><i class="fa-regular fa-calendar me-1"></i>{{ campaign.startDate }}</span></td>
								<td class="text-center">
									<span class="fw-semibold">{{ campaign.registered }}</span><span class="text-muted">/{{ campaign.maxVolunteers }}</span>
								</td>
								<td class="text-center d-none d-sm-table-cell">
									<span class="badge rounded-pill" :class="getPriorityClass(campaign.priority)">{{ getPriorityLabel(campaign.priority) }}</span>
								</td>
								<td class="text-center">
									<span class="badge rounded-pill" :class="getStatusClass(campaign.status)">
										<i class="me-1" :class="getStatusIcon(campaign.status)"></i>{{ getStatusLabel(campaign.status) }}
									</span>
								</td>
								<td class="text-center">
									<div class="d-flex align-items-center justify-content-center gap-1">
										<button type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.viewDetailsMenu')" @click.prevent="viewCampaign(campaign)">
											<i class="fa-regular fa-eye text-primary fs-6"></i>
										</button>
										<button v-if="canManageCampaigns" type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.editMenu')" @click.prevent="editCampaign(campaign)">
											<i class="fa-regular fa-pen-to-square text-warning fs-6"></i>
										</button>
										<button v-if="canManageCampaigns && campaign.status === 'approved'" type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.startCampaignMenu')" @click.prevent="confirmStatusChange(campaign, 'dang_dien_ra')">
											<i class="fa-solid fa-play text-success fs-6"></i>
										</button>
										<button v-if="canManageCampaigns && campaign.status === 'active'" type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.completeCampaignMenu')" @click.prevent="confirmStatusChange(campaign, 'hoan_thanh')">
											<i class="fa-solid fa-flag-checkered text-success fs-6"></i>
										</button>
										<button v-if="canManageCampaigns" type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.cancelCampaignMenu')" @click.prevent="confirmCancel(campaign)">
											<i class="fa-regular fa-trash-can text-danger fs-6"></i>
										</button>
									</div>
								</td>
							</tr>
							<tr v-if="filteredCampaigns.length === 0">
								<td colspan="8" class="text-center py-5">
									<i class="fa-solid fa-inbox fs-1 d-block opacity-25 mb-2"></i>
									<span class="text-muted">{{ $t('coordinator.noCampaignFound') }}</span>
								</td>
							</tr>
						</tbody>
					</table>
				</div>

				<!-- GRID VIEW -->
				<div v-if="viewMode === 'grid'" class="row g-3">
					<div class="col-12 col-sm-6 col-xl-4" v-for="campaign in filteredCampaigns" :key="campaign.id">
						<div class="card h-100 border hover-card">
							<div class="campaign-grid-banner d-flex align-items-end p-3" :style="getCampaignCoverStyle(campaign, 'banner')">
								<div class="d-flex justify-content-between align-items-end w-100">
									<span class="badge bg-white text-dark shadow-sm small fw-semibold">{{ getCategoryLabel(campaign.category) }}</span>
									<span class="badge rounded-pill" :class="getStatusClass(campaign.status)">{{ getStatusLabel(campaign.status) }}</span>
								</div>
							</div>
							<div class="card-body pb-2">
								<h6 class="fw-bold text-dark mb-2 text-truncate">{{ campaign.title }}</h6>
								<p class="text-muted small mb-3 text-truncate-2">{{ campaign.description }}</p>
								<div class="d-flex flex-column gap-1 small text-muted">
									<div class="text-truncate"><i class="fa-solid fa-location-dot me-2 text-danger"></i>{{ campaign.location }}</div>
									<div><i class="fa-regular fa-calendar me-2 text-primary"></i>{{ campaign.startDate }} — {{ campaign.endDate }}</div>
									<div class="d-flex justify-content-between align-items-center">
										<span><i class="fa-solid fa-users me-2 text-success"></i>{{ campaign.registered }}/{{ campaign.maxVolunteers }}</span>
										<span class="badge rounded-pill" :class="getPriorityClass(campaign.priority)">{{ getPriorityLabel(campaign.priority) }}</span>
									</div>
								</div>
								<div class="mt-3">
									<div class="progress" style="height: 5px;">
										<div class="progress-bar" :class="campaign.status === 'completed' ? 'bg-success' : 'bg-primary'" :style="{ width: getProgress(campaign) + '%' }"></div>
									</div>
									<div class="text-muted text-end mt-1" style="font-size:11px">{{ getProgress(campaign) }}%</div>
								</div>
							</div>
							<div class="card-footer bg-transparent border-top py-2 d-flex gap-2">
								<button v-if="canManageCampaigns" class="btn btn-sm btn-outline-primary flex-fill d-flex align-items-center justify-content-center gap-1" @click="editCampaign(campaign)">
									<i class="fa-regular fa-pen-to-square" style="font-size:12px"></i><span>{{ $t('coordinator.editBtn') }}</span>
								</button>
								<button class="btn btn-sm btn-outline-secondary flex-fill d-flex align-items-center justify-content-center gap-1" @click="viewCampaign(campaign)">
									<i class="fa-regular fa-eye" style="font-size:12px"></i><span>{{ $t('coordinator.detailsBtn') }}</span>
								</button>
								<button v-if="canManageCampaigns && campaign.status === 'approved'" class="btn btn-sm btn-outline-success d-flex align-items-center justify-content-center" style="width: 34px;height: 34px;padding-left: 10px;" :title="$t('coordinator.startCampaignMenu')" @click="confirmStatusChange(campaign, 'dang_dien_ra')">
									<i class="fa-solid fa-play" style="font-size:12px"></i>
								</button>
								<button v-else-if="canManageCampaigns && campaign.status === 'active'" class="btn btn-sm btn-outline-success d-flex align-items-center justify-content-center" style="width: 34px;height: 34px;padding-left: 10px;" :title="$t('coordinator.completeCampaignMenu')" @click="confirmStatusChange(campaign, 'hoan_thanh')">
									<i class="fa-solid fa-flag-checkered" style="font-size:12px"></i>
								</button>
								<button v-if="canManageCampaigns" class="btn btn-sm btn-outline-danger d-flex align-items-center justify-content-center" style="width: 34px;height: 34px;padding-left: 12px;" @click="confirmCancel(campaign)">
									<i class="fa-regular fa-circle-xmark" style="font-size:12px"></i>
								</button>
							</div>
						</div>
					</div>
					<div v-if="filteredCampaigns.length === 0" class="col-12 text-center py-5">
						<i class="fa-solid fa-inbox fs-1 d-block opacity-25 mb-2"></i>
						<span class="text-muted">{{ $t('coordinator.noCampaignFound') }}</span>
					</div>
				</div>

				<!-- Pagination -->
				<div class="d-flex flex-column flex-sm-row justify-content-between align-items-center mt-4 pt-3 border-top gap-3" v-if="totalCampaigns > 0">
					<!-- Left: Info + Per page selector -->
					<div class="d-flex align-items-center gap-3 flex-wrap">
						<div class="text-muted small">
							Hiển thị <strong>{{ paginationFrom }}–{{ paginationTo }}</strong> / {{ totalCampaigns }} chiến dịch
						</div>
						<div class="d-flex align-items-center gap-2">
							<label class="text-muted small mb-0 text-nowrap">Số bản ghi:</label>
							<select class="form-select form-select-sm" style="width: 72px;" v-model="perPage">
								<option value="5">5</option>
								<option value="10">10</option>
								<option value="20">20</option>
								<option value="50">50</option>
							</select>
						</div>
					</div>
					<!-- Right: Page navigation -->
					<nav v-if="lastPage > 1">
						<ul class="pagination pagination-sm mb-0">
							<li class="page-item" :class="{ disabled: currentPage === 1 }">
								<a class="page-link" href="#" @click.prevent="goToPage(1)" title="Trang đầu">«</a>
							</li>
							<li class="page-item" :class="{ disabled: currentPage === 1 }">
								<a class="page-link" href="#" @click.prevent="goToPage(currentPage - 1)">‹</a>
							</li>
							<template v-for="p in paginationPages" :key="p">
								<li v-if="p === '...'" class="page-item disabled"><span class="page-link">…</span></li>
								<li v-else class="page-item" :class="{ active: currentPage === p }">
									<a class="page-link" href="#" @click.prevent="goToPage(p)">{{ p }}</a>
								</li>
							</template>
							<li class="page-item" :class="{ disabled: currentPage === lastPage }">
								<a class="page-link" href="#" @click.prevent="goToPage(currentPage + 1)">›</a>
							</li>
							<li class="page-item" :class="{ disabled: currentPage === lastPage }">
								<a class="page-link" href="#" @click.prevent="goToPage(lastPage)" title="Trang cuối">»</a>
							</li>
						</ul>
					</nav>
				</div>
			</div>
		</div>

		<!-- CREATE/EDIT MODAL -->
		<div class="modal fade" id="campaignModal" tabindex="-1" ref="campaignModal">
			<div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-bottom px-4 pt-4 pb-3">
						<h5 class="modal-title fw-bold fs-4 text-dark">{{ isEditing ? $t('coordinator.editCampaignTitle') : $t('coordinator.createCampaignTitle') }}</h5>
						<button type="button" class="btn-close" data-bs-dismiss="modal"></button>
					</div>
					<div class="modal-body px-4 py-4">
						<form @submit.prevent="saveCampaign">
							<!-- Section: Thông tin -->
							<h6 class="fw-bold text-primary mb-3"><i class="fa-solid fa-circle-info me-2"></i>{{ $t('coordinator.basicInfo') }}</h6>
							<div class="row g-3 mb-4">
								<div class="col-12">
									<label class="form-label fw-semibold small">{{ $t('coordinator.campaignName') }} <span class="text-danger">*</span></label>
									<input type="text" class="form-control" :class="{ 'is-invalid': formErrors.title }" v-model.trim="formData.title" :placeholder="$t('coordinator.campaignNamePlaceholder')" required>
									<div v-if="formErrors.title" class="invalid-feedback d-block">{{ formErrors.title }}</div>
								</div>
								<div class="col-12">
									<label class="form-label fw-semibold small">{{ $t('coordinator.descriptionLabel') }} <span class="text-danger">*</span></label>
									<textarea class="form-control" rows="3" :class="{ 'is-invalid': formErrors.description }" v-model.trim="formData.description" :placeholder="$t('coordinator.descriptionPlaceholder')" required></textarea>
									<div v-if="formErrors.description" class="invalid-feedback d-block">{{ formErrors.description }}</div>
								</div>
								<div class="col-12">
									<label class="form-label fw-semibold small">Hình ảnh chiến dịch</label>
									<input type="file" class="form-control" :class="{ 'is-invalid': formErrors.images }" accept="image/*" multiple @change="onCampaignImagesChange">
									<div class="form-text">Có thể chọn nhiều ảnh. Ảnh đầu tiên sẽ dùng làm ảnh bìa.</div>
									<div v-if="formErrors.images" class="invalid-feedback d-block">{{ formErrors.images }}</div>
									<div v-if="formData.previewImages.length" class="row g-3 mt-1">
										<div v-for="(image, index) in formData.previewImages" :key="image.key" class="col-sm-6 col-lg-4">
											<div class="border rounded-3 overflow-hidden bg-light position-relative h-100">
												<div class="position-absolute top-0 start-0 m-2 badge" :class="index === 0 ? 'bg-primary' : 'bg-dark bg-opacity-75'">
													{{ index === 0 ? 'Ảnh bìa' : `Ảnh ${index + 1}` }}
												</div>
												<button
													type="button"
													class="btn btn-sm btn-light position-absolute top-0 end-0 m-2 rounded-circle shadow-sm"
													@click="removeCampaignImage(image)">
													<i class="fa-solid fa-xmark"></i>
												</button>
												<img :src="image.url" alt="Hình ảnh chiến dịch" class="w-100 object-fit-cover" style="height: 180px;">
											</div>
										</div>
									</div>
								</div>
								<div class="col-sm-6">
									<label class="form-label fw-semibold small">{{ $t('coordinator.campaignType') }} <span class="text-danger">*</span></label>
									<select class="form-select" :class="{ 'is-invalid': formErrors.category }" v-model="formData.category" required>
										<option value="">{{ $t('coordinator.selectType') }}</option>
										<option v-for="t in campaignTypes" :key="t.id" :value="t.id">{{ t.ten }}</option>
									</select>
									<div v-if="formErrors.category" class="invalid-feedback d-block">{{ formErrors.category }}</div>
								</div>
								<div class="col-sm-6">
									<label class="form-label fw-semibold small">{{ $t('coordinator.priorityLevel') }} <span class="text-danger">*</span></label>
									<select class="form-select" :class="{ 'is-invalid': formErrors.priority }" v-model="formData.priority" required>
										<option value="">{{ $t('coordinator.selectPriority') }}</option>
										<option value="urgent">{{ $t('priorities.urgent') }}</option>
										<option value="high">{{ $t('priorities.high') }}</option>
										<option value="medium">{{ $t('priorities.medium') }}</option>
										<option value="low">{{ $t('priorities.low') }}</option>
									</select>
									<div v-if="formErrors.priority" class="invalid-feedback d-block">{{ formErrors.priority }}</div>
								</div>
							</div>

							<hr class="my-4">

							<!-- Section: Địa điểm & Thời gian -->
							<h6 class="fw-bold text-primary mb-3"><i class="fa-solid fa-map-location-dot me-2"></i>{{ $t('coordinator.locationAndTime') }}</h6>
							<div class="row g-3 mb-4">
								<div class="col-12">
									<label class="form-label fw-semibold small">{{ $t('coordinator.locationLabel') }} <span class="text-danger">*</span></label>
									<div class="input-group">
										<span class="input-group-text bg-light"><i class="fa-solid fa-location-dot text-danger"></i></span>
										<input type="text" class="form-control" :class="{ 'is-invalid': formErrors.location }" v-model.trim="formData.location" :placeholder="$t('coordinator.locationPlaceholder')" required>
										<span class="input-group-text bg-white" v-if="campaignGeocoding">
											<span class="spinner-border spinner-border-sm text-primary" role="status"></span>
										</span>
									</div>
									<div v-if="formErrors.location" class="invalid-feedback d-block">{{ formErrors.location }}</div>
									<div class="form-text small" v-if="campaignGeocodeStatus">
										<i :class="campaignGeocodeStatus === 'success' ? 'fa-solid fa-check-circle text-success' : 'fa-solid fa-info-circle text-warning'" class="me-1"></i>
										<span :class="campaignGeocodeStatus === 'success' ? 'text-success' : 'text-warning'">{{ campaignGeocodeMessage }}</span>
									</div>
								</div>

								<!-- Mini Map for Campaign -->
								<div class="col-12" v-if="formData.location">
									<label class="form-label fw-semibold small">
										<i class="fa-solid fa-map text-success me-1"></i>{{ $t('coordinator.organizationLocation') }}
										<span class="text-muted fw-normal ms-1">{{ $t('coordinator.dragPinHint') }}</span>
									</label>
									<div id="campaign-map-container" class="campaign-map-wrapper rounded-3 border overflow-hidden"></div>
								</div>

								<!-- Toa do (Readonly) -->
								<div class="col-sm-6" v-if="formData.latitude">
									<label class="form-label fw-semibold small">
										<i class="fa-solid fa-crosshairs text-primary me-1"></i>{{ $t('coordinator.latitude') }}
									</label>
									<input type="text" class="form-control form-control-sm bg-light" :value="formData.latitude" readonly>
								</div>
								<div class="col-sm-6" v-if="formData.longitude">
									<label class="form-label fw-semibold small">
										<i class="fa-solid fa-crosshairs text-primary me-1"></i>{{ $t('coordinator.longitude') }}
									</label>
									<input type="text" class="form-control form-control-sm bg-light" :value="formData.longitude" readonly>
								</div>
								<div class="col-sm-6">
									<label class="form-label fw-semibold small">{{ $t('coordinator.startDate') }} <span class="text-danger">*</span></label>
									<input type="date" class="form-control" :class="{ 'is-invalid': formErrors.startDate }" v-model="formData.startDate" required>
									<div v-if="formErrors.startDate" class="invalid-feedback d-block">{{ formErrors.startDate }}</div>
								</div>
								<div class="col-sm-6">
									<label class="form-label fw-semibold small">{{ $t('coordinator.endDate') }} <span class="text-danger">*</span></label>
									<input type="date" class="form-control" :class="{ 'is-invalid': formErrors.endDate }" v-model="formData.endDate" required>
									<div v-if="formErrors.endDate" class="invalid-feedback d-block">{{ formErrors.endDate }}</div>
								</div>
							</div>

							<hr class="my-4">

							<!-- Section: Yêu cầu TNV -->
							<h6 class="fw-bold text-primary mb-3"><i class="fa-solid fa-users-gear me-2"></i>{{ $t('coordinator.volunteerRequirements') }}</h6>
							<div class="row g-3 mb-3">
								<div class="col-sm-6">
									<label class="form-label fw-semibold small">{{ $t('coordinator.quantityNeeded') }} (Tối đa) <span class="text-danger">*</span></label>
									<div class="input-group">
										<span class="input-group-text bg-light"><i class="fa-solid fa-users text-primary"></i></span>
										<input type="number" class="form-control" :class="{ 'is-invalid': formErrors.maxVolunteers }" v-model.number="formData.maxVolunteers" placeholder="50" min="1" required>
										<span class="input-group-text bg-light small">{{ $t('common.people') }}</span>
									</div>
									<div v-if="formErrors.maxVolunteers" class="invalid-feedback d-block">{{ formErrors.maxVolunteers }}</div>
								</div>
								<div class="col-sm-6">
									<label class="form-label fw-semibold small">Số lượng tối thiểu <span class="text-danger">*</span></label>
									<div class="input-group">
										<span class="input-group-text bg-light"><i class="fa-solid fa-user-check text-success"></i></span>
										<input type="number" class="form-control" :class="{ 'is-invalid': formErrors.minVolunteers }" v-model.number="formData.minVolunteers" placeholder="5" min="1" required>
										<span class="input-group-text bg-light small">{{ $t('common.people') }}</span>
									</div>
									<div v-if="formErrors.minVolunteers" class="invalid-feedback d-block">{{ formErrors.minVolunteers }}</div>
								</div>
								<div class="col-12">
									<label class="form-label fw-semibold small">{{ $t('coordinator.requiredSkills') }}</label>
									<p class="text-muted mb-2" style="font-size:12px">{{ $t('coordinator.requiredSkillsHint') }}</p>
									<div class="d-flex flex-wrap gap-2">
										<span v-for="skill in availableSkills" :key="skill.id"
											class="badge rounded-pill px-3 py-2 user-select-none skill-tag"
											:class="formData.requiredSkills.includes(skill.id) ? 'bg-primary text-white shadow-sm' : 'bg-light text-dark'"
											style="font-size:12px; cursor:pointer; border: 1px solid #dee2e6;"
											@click="toggleRequiredSkill(skill.id)">
											<i :class="skill.icon" class="me-1"></i>{{ skill.name }}
										</span>
									</div>
								</div>
							</div>
						</form>
					</div>
					<div class="modal-footer bg-light border-0 px-4">
						<button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">{{ $t('coordinator.cancelBtn') }}</button>
						<button type="button" class="btn btn-primary shadow-sm" @click="saveCampaign" :disabled="!canManageCampaigns">
							<i class="fa-solid fa-paper-plane me-1"></i>{{ isEditing ? $t('coordinator.updateBtn') : $t('coordinator.submitBtn') }}
						</button>
					</div>
				</div>
			</div>
		</div>

		<ConfirmModal
			ref="cancelModal"
			modalId="cancelCampaignModal"
			:title="$t('coordinator.cancelCampaignTitle')"
			:message="$t('coordinator.cancelCampaignMsg')"
			:detail="cancelTarget?.title || ''"
			icon="fa-solid fa-triangle-exclamation"
			variant="danger"
			:confirmText="$t('coordinator.confirmCancelBtn')"
			confirmIcon="fa-solid fa-ban"
			:cancelText="$t('coordinator.keepBtn')"
			:dismissOnConfirm="false"
			@confirm="cancelCampaign">
			<template #warning>
				<div class="bg-warning bg-opacity-10 rounded-3 p-3 mb-3 text-start">
					<small class="text-warning fw-semibold"><i class="fa-solid fa-info-circle me-1"></i>{{ $t('coordinator.cancelWarningTitle') }}</small>
					<ul class="mb-0 mt-1 small text-muted ps-3">
						<li>{{ $t('coordinator.cancelWarning1') }}</li>
						<li>{{ $t('coordinator.cancelWarning2') }}</li>
					</ul>
				</div>
				<div class="text-start mt-3">
					<label class="form-label fw-semibold small">Lý do hủy <span class="text-danger">*</span></label>
					<textarea class="form-control" rows="2" v-model="cancelReason" placeholder="Vui lòng nhập lý do hủy chiến dịch..." required></textarea>
				</div>
			</template>
		</ConfirmModal>

		<ConfirmModal
			ref="statusModal"
			modalId="statusCampaignModal"
			:title="statusConfirmConfig.title"
			:message="statusConfirmConfig.message"
			:detail="statusConfirmConfig.detail"
			:detailList="statusConfirmConfig.detailList"
			:detailListTitle="statusConfirmConfig.detailListTitle"
			:icon="statusConfirmConfig.icon"
			:variant="statusConfirmConfig.variant"
			:confirmText="statusConfirmConfig.confirmText"
			confirmIcon="fa-solid fa-check"
			:dismissOnConfirm="false"
			@confirm="updateCampaignStatus" />
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue'
import StatCards from '../../components/StatCards.vue'
import ConfirmModal from '../../components/ConfirmModal.vue'
import api from '../../services/api'
import { hasPermission } from '../../utils/permissions'

// Priority mapping: DB enum ↔ frontend key
const PRIORITY_MAP = { khan_cap: 'urgent', cao: 'high', trung_binh: 'medium', thap: 'low' };
const PRIORITY_MAP_REVERSE = { urgent: 'khan_cap', high: 'cao', medium: 'trung_binh', low: 'thap' };

// Status mapping: DB enum → frontend key
const STATUS_MAP = { cho_duyet: 'pending', tu_choi: 'rejected', da_duyet: 'approved', dang_dien_ra: 'active', hoan_thanh: 'completed', yeu_cau_huy: 'pending_cancel', da_huy: 'cancelled', nhap: 'draft' };

export default {
	name: "QuanLyChienDich",
	components: { PageHeader, StatCards, ConfirmModal },
	inject: ['toast'],
	data() {
		return {
			activeTab: 'all',
			searchQuery: '',
			filterCategory: '',
			filterPriority: '',
			viewMode: 'table',
			isEditing: false,
			isSaving: false,
			cancelTarget: null,
			cancelReason: '',
			statusTarget: null,
			nextStatusTarget: null,
			statusForceProceed: false,
			statusConfirmConfig: {
				title: '',
				message: '',
				detail: '',
				detailList: [],
				detailListTitle: '',
				icon: '',
				variant: '',
				confirmText: '',
			},
			campaignMap: null,
			campaignMarker: null,
			campaignGeocoding: false,
			campaignGeocodeStatus: '',
			campaignGeocodeMessage: '',
			campaignGeocodeTimer: null,
			formErrors: {},
			formData: {
				title: '', description: '', category: '', priority: '',
				location: '', latitude: null, longitude: null,
				startDate: '', endDate: '',
				maxVolunteers: null, minVolunteers: null, requiredSkills: [],
				coverUrl: null,
				images: [],
				existingImages: [],
				newImages: [],
				previewImages: [],
			},
			campaigns: [],
			campaignTypes: [],
			skillsList: [],
			// Pagination
			currentPage: 1,
			lastPage: 1,
			perPage: '5',
			totalCampaigns: 0,
		}
	},
	computed: {
		statusTabs() {
			return [
				{ label: this.$t('coordinator.tabAll'), value: 'all' },
				{ label: this.$t('coordinator.tabActive'), value: 'active' },
				{ label: this.$t('coordinator.tabPending'), value: 'pending' },
				{ label: this.$t('coordinator.tabCompleted'), value: 'completed' },
				{ label: this.$t('coordinator.tabPendingCancel') || 'Yêu cầu hủy', value: 'pending_cancel' },
				{ label: this.$t('coordinator.tabCancelled'), value: 'cancelled' },
			];
		},
		availableSkills() {
			if (this.skillsList.length > 0) {
				return this.skillsList.map(s => ({
					id: s.id,
					name: s.ten,
					icon: s.bieu_tuong ? `fa-solid ${s.bieu_tuong}` : 'fa-solid fa-star'
				}));
			}
			// Fallback to i18n
			return Array.from({ length: 10 }, (_, i) => ({
				id: i + 1,
				name: this.$t(`skillNames.${i + 1}`),
				icon: ['fa-solid fa-calendar-check','fa-solid fa-boxes-stacked','fa-solid fa-kit-medical','fa-solid fa-bullhorn','fa-solid fa-chalkboard-teacher','fa-solid fa-laptop-code','fa-solid fa-utensils','fa-solid fa-truck','fa-solid fa-brain','fa-solid fa-camera'][i]
			}));
		},
		canManageCampaigns() {
			try {
				const user = JSON.parse(localStorage.getItem('user') || 'null');
				return hasPermission(user, 'volunteer_campaigns.manage');
			} catch (_error) {
				return false;
			}
		},
		myCampaigns() {
			return this.campaigns;
		},
		statCards() {
			const c = this.myCampaigns;
			return [
				{ label: this.$t('coordinator.totalCampaigns'), value: this.totalCampaigns, icon: 'fa-solid fa-layer-group', color: 'primary' },
				{ label: this.$t('coordinator.activeCampaigns'), value: c.filter(x => x.status === 'active').length, icon: 'fa-solid fa-circle-check', color: 'success' },
				{ label: this.$t('coordinator.pendingApproval'), value: c.filter(x => x.status === 'pending').length, icon: 'fa-solid fa-clock', color: 'warning' },
				{ label: this.$t('coordinator.completedCampaigns'), value: c.filter(x => x.status === 'completed').length, icon: 'fa-solid fa-box-archive', color: 'secondary' },
			];
		},
		filteredCampaigns() {
			// Server-side filtering via API, so just return campaigns as-is
			return this.myCampaigns;
		},
		paginationFrom() {
			if (this.totalCampaigns === 0) return 0;
			return (this.currentPage - 1) * this.perPage + 1;
		},
		paginationTo() {
			return Math.min(this.currentPage * this.perPage, this.totalCampaigns);
		},
		paginationPages() {
			const total = this.lastPage;
			const cur = this.currentPage;
			if (total <= 7) {
				return Array.from({ length: total }, (_, i) => i + 1);
			}
			const pages = [];
			pages.push(1);
			if (cur > 3) pages.push('...');
			for (let i = Math.max(2, cur - 1); i <= Math.min(total - 1, cur + 1); i++) {
				pages.push(i);
			}
			if (cur < total - 2) pages.push('...');
			pages.push(total);
			return pages;
		}
	},
	watch: {
		activeTab() { this.currentPage = 1; this.loadCampaigns(); },
		filterCategory() { this.currentPage = 1; this.loadCampaigns(); },
		filterPriority() { this.currentPage = 1; this.loadCampaigns(); },
		perPage() { this.currentPage = 1; this.loadCampaigns(); },
		searchQuery() {
			// Debounce search
			if (this._searchTimer) clearTimeout(this._searchTimer);
			this._searchTimer = setTimeout(() => {
				this.currentPage = 1;
				this.loadCampaigns();
			}, 400);
		},
		'formData.location'(newVal, oldVal) {
			if (this.campaignGeocodeTimer) clearTimeout(this.campaignGeocodeTimer);
			if (this.isEditing && this._justOpenedEdit) {
				this._justOpenedEdit = false;
				return;
			}
			if (newVal && newVal.length >= 5 && newVal !== oldVal) {
				this.campaignGeocodeTimer = setTimeout(() => {
					this.geocodeCampaign(newVal);
				}, 800);
			}
		}
	},
	mounted() {
		// Load Leaflet CSS
		if (!document.getElementById('leaflet-css')) {
			const link = document.createElement('link');
			link.id = 'leaflet-css';
			link.rel = 'stylesheet';
			link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
			document.head.appendChild(link);
		}
		// Load Leaflet JS
		if (!window.L) {
			const script = document.createElement('script');
			script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
			document.head.appendChild(script);
		}
		this.loadCampaigns();
		this.loadCampaignTypes();
		this.loadSkills();
	},
	methods: {
		// ===== Data Loading =====
		async loadCampaigns(page) {
			if (page) this.currentPage = page;
			try {
					const STATUS_MAP_REVERSE = { pending: 'cho_duyet', approved: 'da_duyet', active: 'dang_dien_ra', completed: 'hoan_thanh', pending_cancel: 'yeu_cau_huy', cancelled: 'da_huy', rejected: 'tu_choi' };
				const params = {
					page: this.currentPage,
					per_page: this.perPage,
				};
				if (this.activeTab && this.activeTab !== 'all') params.trang_thai = STATUS_MAP_REVERSE[this.activeTab] || this.activeTab;
				if (this.searchQuery) params.tu_khoa = this.searchQuery;
				if (this.filterCategory) params.loai_chien_dich_id = this.filterCategory;
				if (this.filterPriority) params.muc_do_uu_tien = PRIORITY_MAP_REVERSE[this.filterPriority] || this.filterPriority;

				const res = await api.get('/tinh-nguyen-vien/chien-dich', { params });
				if (res.data.status === 1) {
					this.campaigns = res.data.data.map(cd => this.mapCampaignFromApi(cd));
					this.currentPage = res.data.current_page;
					this.lastPage = res.data.last_page;
					this.totalCampaigns = res.data.total;
				}
			} catch (err) {
				console.error('Lỗi tải danh sách chiến dịch:', err);
			}
		},
		async loadCampaignTypes() {
			try {
				const res = await api.get('/danh-muc/loai-chien-dich');
				if (res.data.status === 1) {
					this.campaignTypes = res.data.data;
				}
			} catch (err) {
				console.error('Lỗi tải loại chiến dịch:', err);
			}
		},
		async loadSkills() {
			try {
				const res = await api.get('/danh-muc/ky-nang');
				if (res.data.status === 1) {
					this.skillsList = res.data.data;
				}
			} catch (err) {
				console.error('Lỗi tải kỹ năng:', err);
			}
		},

		// ===== Mapping helpers =====
		mapCampaignFromApi(cd) {
			const loai = cd.loai_chien_dich;
			const images = Array.isArray(cd.danh_sach_anh) && cd.danh_sach_anh.length
				? cd.danh_sach_anh
				: (cd.anh_bia ? [cd.anh_bia] : []);
			return {
				id: cd.id,
				title: cd.tieu_de,
				description: cd.mo_ta || '',
				coverUrl: images[0] || cd.anh_bia || null,
				images,
				category: cd.loai_chien_dich_id || '',
				priority: PRIORITY_MAP[cd.muc_do_uu_tien] || 'medium',
				location: cd.dia_diem,
				latitude: cd.vi_do,
				longitude: cd.kinh_do,
				startDate: cd.ngay_bat_dau,
				endDate: cd.ngay_ket_thuc,
				maxVolunteers: cd.so_luong_toi_da,
				minVolunteers: cd.so_luong_toi_thieu || 1,
				registered: cd.so_dang_ky || 0,
				status: STATUS_MAP[cd.trang_thai] || cd.trang_thai,
				requiredSkills: cd.ky_nang_ids || [],
				icon: loai ? `fa-solid ${loai.bieu_tuong || 'fa-flag'}` : 'fa-solid fa-flag',
				color: loai ? `linear-gradient(135deg, ${loai.mau_sac || '#0d6efd'}, ${this.lightenColor(loai.mau_sac || '#0d6efd')})` : 'linear-gradient(135deg, #0d6efd, #6610f2)',
			};
		},
		lightenColor(hex) {
			// Simple lighten by mixing with white
			let r = parseInt(hex.slice(1, 3), 16);
			let g = parseInt(hex.slice(3, 5), 16);
			let b = parseInt(hex.slice(5, 7), 16);
			r = Math.min(255, r + 40);
			g = Math.min(255, g + 40);
			b = Math.min(255, b + 40);
			return `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
		},

		// ===== Display helpers =====
		getCountByStatus(s) { return s === 'all' ? this.myCampaigns.length : this.myCampaigns.filter(c => c.status === s).length; },
		getCategoryLabel(cat) {
			const found = this.campaignTypes.find(t => t.id === cat || String(t.id) === String(cat));
			return found ? found.ten : (cat || '—');
		},
		getPriorityLabel(p) { return this.$t(`priorities.${p}`); },
		getPriorityClass(p) { return { urgent: 'bg-danger text-white', high: 'bg-warning text-dark', medium: 'bg-info text-white', low: 'bg-light text-muted border' }[p] || 'bg-secondary'; },
		getStatusLabel(s) { return this.$t(`statuses.${s}`); },
		getStatusClass(s) { return { approved: 'bg-info text-white', active: 'bg-success text-white', pending: 'bg-warning text-dark', completed: 'bg-secondary text-white', pending_cancel: 'bg-orange text-white', cancelled: 'bg-danger bg-opacity-75 text-white', rejected: 'bg-dark text-white', draft: 'bg-light text-dark border' }[s] || 'bg-secondary'; },
		getStatusIcon(s) { return { approved: 'fa-solid fa-badge-check', active: 'fa-solid fa-circle-play', pending: 'fa-solid fa-hourglass-half', completed: 'fa-solid fa-circle-check', pending_cancel: 'fa-solid fa-clock-rotate-left', cancelled: 'fa-solid fa-ban', rejected: 'fa-solid fa-circle-xmark', draft: 'fa-solid fa-file-lines' }[s] || ''; },
		getProgress(c) { return c.maxVolunteers ? Math.round(c.registered / c.maxVolunteers * 100) : 0; },
		getCampaignCoverStyle(campaign, variant = 'banner') {
			const coverUrl = campaign.coverUrl || campaign.images?.[0] || null;
			if (coverUrl) {
				const overlay = variant === 'avatar'
					? 'linear-gradient(rgba(15,23,42,.20), rgba(15,23,42,.20))'
					: 'linear-gradient(rgba(15,23,42,.28), rgba(15,23,42,.28))';
				return {
					background: `${overlay}, url(${coverUrl}) center/cover`,
				};
			}
			return { background: campaign.color };
		},

		// ===== Form =====
		resetForm() {
			this.formErrors = {};
			this.formData = {
				title: '', description: '', category: '', priority: '',
				location: '', latitude: null, longitude: null,
				startDate: '', endDate: '', maxVolunteers: null, minVolunteers: null, requiredSkills: [],
				coverUrl: null,
				images: [],
				existingImages: [],
				newImages: [],
				previewImages: [],
			};
			this.campaignGeocodeStatus = '';
			this.campaignGeocodeMessage = '';
			this.destroyCampaignMap();
		},
		openCreateModal() { this.isEditing = false; this.resetForm(); new bootstrap.Modal(this.$refs.campaignModal).show(); },
		editCampaign(c) {
			this.isEditing = true;
			this._justOpenedEdit = true;
			this.formData = {
				...c,
				requiredSkills: [...c.requiredSkills],
				coverUrl: c.coverUrl || c.images?.[0] || null,
				images: [...(c.images || [])],
				existingImages: [...(c.images || [])],
				newImages: [],
				previewImages: (c.images || []).map((url, index) => ({
					key: `existing-${index}-${url}`,
					type: 'existing',
					url,
				})),
			};
			new bootstrap.Modal(this.$refs.campaignModal).show();
			if (c.latitude && c.longitude) {
				setTimeout(() => {
					this.updateCampaignMapPosition(parseFloat(c.latitude), parseFloat(c.longitude));
					this.campaignGeocodeStatus = 'success';
					this.campaignGeocodeMessage = this.$t('coordinator.savedFromDb');
				}, 300);
			} else {
				this.geocodeCampaign(c.location);
			}
		},
		viewCampaign(c) { this.$router.push(`/quan-ly-chien-dich/chi-tiet/${c.id}`); },
		goToPage(page) {
			if (page >= 1 && page <= this.lastPage) {
				this.loadCampaigns(page);
			}
		},
		onCampaignImagesChange(e) {
			const files = Array.from(e.target.files || []);
			if (!files.length) return;

			const validFiles = files.filter((file) => file.type.startsWith('image/'));
			if (!validFiles.length) return;

			this.formData.newImages = [...this.formData.newImages, ...validFiles];
			this.syncCampaignPreviewImages();
			this.formErrors.images = '';
			e.target.value = '';
		},
		syncCampaignPreviewImages() {
			const existing = (this.formData.existingImages || []).map((url, index) => ({
				key: `existing-${index}-${url}`,
				type: 'existing',
				url,
			}));
			const news = (this.formData.newImages || []).map((file, index) => ({
				key: `new-${index}-${file.name}-${file.size}`,
				type: 'new',
				url: URL.createObjectURL(file),
				file,
			}));
			this.formData.previewImages = [...existing, ...news];
			this.formData.images = this.formData.previewImages.map((item) => item.url);
			this.formData.coverUrl = this.formData.previewImages[0]?.url || null;
		},
		removeCampaignImage(image) {
			if (image.type === 'existing') {
				this.formData.existingImages = this.formData.existingImages.filter((url) => url !== image.url);
			} else {
				this.formData.newImages = this.formData.newImages.filter((file) => file !== image.file);
			}
			this.syncCampaignPreviewImages();
		},
		validateCampaignForm() {
			const errors = {};
			const today = new Date();
			today.setHours(0, 0, 0, 0);
			const startDate = this.formData.startDate ? new Date(this.formData.startDate) : null;
			const endDate = this.formData.endDate ? new Date(this.formData.endDate) : null;

			if (!this.formData.title?.trim()) errors.title = 'Vui lòng nhập tên chiến dịch.';
			else if (this.formData.title.trim().length < 5) errors.title = 'Tên chiến dịch phải có ít nhất 5 ký tự.';

			if (!this.formData.description?.trim()) errors.description = 'Vui lòng nhập mô tả chiến dịch.';
			else if (this.formData.description.trim().length < 20) errors.description = 'Mô tả chiến dịch phải có ít nhất 20 ký tự.';

			if (!this.formData.category) errors.category = 'Vui lòng chọn loại chiến dịch.';
			if (!this.formData.priority) errors.priority = 'Vui lòng chọn mức độ ưu tiên.';

			if (!this.formData.location?.trim()) errors.location = 'Vui lòng nhập địa điểm tổ chức.';
			else if (this.formData.location.trim().length < 5) errors.location = 'Địa điểm phải có ít nhất 5 ký tự.';

			if (!this.formData.startDate) errors.startDate = 'Vui lòng chọn ngày bắt đầu.';
			else if (startDate && startDate < today) errors.startDate = 'Ngày bắt đầu không được ở trong quá khứ.';

			if (!this.formData.endDate) errors.endDate = 'Vui lòng chọn ngày kết thúc.';
			else if (startDate && endDate && endDate < startDate) errors.endDate = 'Ngày kết thúc phải sau hoặc bằng ngày bắt đầu.';

			if (!this.formData.maxVolunteers || this.formData.maxVolunteers < 1) errors.maxVolunteers = 'Số lượng tối đa phải lớn hơn 0.';
			if (!this.formData.minVolunteers || this.formData.minVolunteers < 1) errors.minVolunteers = 'Số lượng tối thiểu phải lớn hơn 0.';
			else if (this.formData.maxVolunteers && this.formData.minVolunteers > this.formData.maxVolunteers) errors.minVolunteers = 'Số lượng tối thiểu không được lớn hơn số lượng tối đa.';

			if ((this.formData.previewImages || []).length > 10) errors.images = 'Tối đa 10 hình ảnh cho mỗi chiến dịch.';

			this.formErrors = errors;
			return Object.keys(errors).length === 0;
		},

		async saveCampaign() {
			if (!this.validateCampaignForm()) {
				if (this.toast) this.toast.showToast('error', 'Lỗi', this.$t('coordinator.fillAllFields'));
				else alert(this.$t('coordinator.fillAllFields'));
				return;
			}
			this.isSaving = true;

			const payload = new FormData();
			payload.append('tieu_de', this.formData.title);
			payload.append('mo_ta', this.formData.description || '');
			if (this.formData.category) payload.append('loai_chien_dich_id', this.formData.category);
			payload.append('dia_diem', this.formData.location);
			if (this.formData.latitude !== null && this.formData.latitude !== '') payload.append('vi_do', this.formData.latitude);
			if (this.formData.longitude !== null && this.formData.longitude !== '') payload.append('kinh_do', this.formData.longitude);
			payload.append('ngay_bat_dau', this.formData.startDate);
			payload.append('ngay_ket_thuc', this.formData.endDate);
			payload.append('so_luong_toi_da', this.formData.maxVolunteers || 50);
			payload.append('so_luong_toi_thieu', this.formData.minVolunteers || 1);
			payload.append('muc_do_uu_tien', PRIORITY_MAP_REVERSE[this.formData.priority] || 'trung_binh');
			(this.formData.requiredSkills || []).forEach((id, index) => payload.append(`ky_nang_ids[${index}]`, id));
			(this.formData.existingImages || []).forEach((url, index) => payload.append(`danh_sach_anh_hien_tai[${index}]`, url));
			if ((this.formData.existingImages || []).length === 0 && this.formData.newImages.length > 0) {
				payload.append('anh_bia', this.formData.newImages[0]);
				this.formData.newImages.slice(1).forEach((file, index) => payload.append(`anh_phu[${index}]`, file));
			} else {
				this.formData.newImages.forEach((file, index) => payload.append(`anh_phu[${index}]`, file));
			}

			try {
				if (this.isEditing) {
					payload.append('_method', 'PUT');
					const res = await api.post(`/tinh-nguyen-vien/chien-dich/${this.formData.id}`, payload, {
						headers: { 'Content-Type': 'multipart/form-data' }
					});
					if (res.data.status === 1) {
						if (this.toast) this.toast.showToast('success', 'Thành công!', res.data.message);
					}
				} else {
					const res = await api.post('/tinh-nguyen-vien/chien-dich', payload, {
						headers: { 'Content-Type': 'multipart/form-data' }
					});
					if (res.data.status === 1) {
						if (this.toast) this.toast.showToast('success', 'Thành công!', res.data.message);
					}
				}
				bootstrap.Modal.getInstance(this.$refs.campaignModal)?.hide();
				await this.loadCampaigns();
			} catch (err) {
				const msg = err.response?.data?.message || 'Có lỗi xảy ra.';
					if (this.toast) this.toast.showToast('error', 'Lỗi', msg);
				else alert(msg);
			} finally {
				this.isSaving = false;
			}
		},

		confirmCancel(c) { this.cancelTarget = c; this.cancelReason = ''; this.$refs.cancelModal.show(); },

		confirmStatusChange(c, nextStatus) {
			this.statusTarget = c;
			this.nextStatusTarget = nextStatus;
			this.statusForceProceed = false;
			this.statusConfirmConfig = {
				title: nextStatus === 'dang_dien_ra' ? this.$t('coordinator.startCampaignTitle') : this.$t('coordinator.completeCampaignTitle'),
				message: nextStatus === 'dang_dien_ra'
					? this.$t('coordinator.startCampaignMsg', { title: c.title })
					: this.$t('coordinator.completeCampaignMsg', { title: c.title }),
				detail: nextStatus === 'dang_dien_ra'
					? this.$t('coordinator.startCampaignDetail')
					: this.$t('coordinator.completeCampaignDetail'),
				detailList: [],
				detailListTitle: '',
				icon: nextStatus === 'dang_dien_ra' ? 'fa-solid fa-play-circle' : 'fa-solid fa-flag-checkered',
				variant: nextStatus === 'dang_dien_ra' ? 'warning' : 'success',
				confirmText: nextStatus === 'dang_dien_ra' ? this.$t('coordinator.startCampaignBtn') : this.$t('coordinator.completeCampaignBtn'),
			};
			this.$refs.statusModal.show();
		},

		async updateCampaignStatus() {
			if (!this.statusTarget || !this.nextStatusTarget) return;
			let shouldResetState = true;
			try {
				const res = await api.put(`/tinh-nguyen-vien/chien-dich/${this.statusTarget.id}/trang-thai`, {
					trang_thai: this.nextStatusTarget,
					bo_qua_canh_bao: this.statusForceProceed,
				});
				if (res.data.status === 1) {
					if (this.toast) this.toast.showToast('success', 'Thành công!', res.data.message);
					await this.loadCampaigns();
					this.$refs.statusModal.hide();
				}
			} catch (err) {
				const warning = err.response?.data?.warning;
				if (warning && this.nextStatusTarget === 'dang_dien_ra') {
					shouldResetState = false;
					this.statusForceProceed = true;
					const detailParts = [];
					(warning?.warning_items || []).forEach((item) => {
						if (item?.message) {
							detailParts.push(item.message);
						}
					});
					if (warning?.so_luong_toi_thieu && Number.isFinite(Number(warning?.so_xac_nhan))) {
						detailParts.push(this.$t('coordinator.startCampaignWarningMsg', {
							confirmed: warning.so_xac_nhan ?? 0,
							minimum: warning.so_luong_toi_thieu ?? 0,
						}));
					}
					if (warning?.so_chua_xac_nhan) {
						detailParts.push(this.$t('coordinator.startCampaignWarningDetail', {
							pending: warning.so_chua_xac_nhan ?? 0,
						}));
					}
					if (warning?.bat_dau_som_hon_du_kien && warning?.ngay_bat_dau_du_kien) {
						detailParts.push(this.$t('coordinator.startCampaignEarlyWarningDetail', {
							date: warning.ngay_bat_dau_du_kien,
						}));
					}
					if (warning?.chi_tiet) {
						detailParts.push(warning.chi_tiet);
					}
					this.statusConfirmConfig = {
						title: warning?.bat_dau_som_hon_du_kien
							? this.$t('coordinator.startCampaignEarlyWarningTitle')
							: this.$t('coordinator.startCampaignWarningTitle'),
						message: warning?.message || this.$t('coordinator.startCampaignWarningTitle'),
						detail: '',
						detailList: detailParts,
						detailListTitle: 'Các cảnh báo cần lưu ý',
						icon: 'fa-solid fa-triangle-exclamation',
						variant: 'warning',
						confirmText: this.$t('coordinator.startCampaignProceedBtn'),
					};
					this.$refs.statusModal.show();
					return;
				}

				const msg = err.response?.data?.message || 'Có lỗi xảy ra.';
				if (this.toast) this.toast.showToast('error', 'Lỗi', msg);
			} finally {
				if (shouldResetState) {
					this.statusTarget = null;
					this.nextStatusTarget = null;
					this.statusForceProceed = false;
				}
			}
		},

		async cancelCampaign() {
			if (!this.cancelTarget) return;
			if (!this.cancelReason.trim()) {
					if (this.toast) this.toast.showToast('warning', 'Cảnh báo', 'Vui lòng nhập lý do hủy chiến dịch!');
				else alert('Vui lòng nhập lý do hủy chiến dịch!');
				return;
			}
			try {
				const res = await api.put(`/tinh-nguyen-vien/chien-dich/${this.cancelTarget.id}/huy`, { ly_do: this.cancelReason });
				if (res.data.status === 1) {
					if (this.toast) this.toast.showToast('success', 'Thành công!', res.data.message);
					await this.loadCampaigns();
					this.$refs.cancelModal.hide();
				}
			} catch (err) {
				const msg = err.response?.data?.message || 'Có lỗi xảy ra.';
				if (this.toast) this.toast.showToast('error', 'Lỗi', msg);
			}
		},

		toggleRequiredSkill(id) { const i = this.formData.requiredSkills.indexOf(id); if (i > -1) this.formData.requiredSkills.splice(i, 1); else this.formData.requiredSkills.push(id); },

		// === Campaign Map ===
		initCampaignMap(lat = 10.8231, lng = 106.6297) {
			this.$nextTick(() => {
				const container = document.getElementById('campaign-map-container');
				if (!container || !window.L) return;
				if (this.campaignMap) { this.campaignMap.remove(); this.campaignMap = null; }

				this.campaignMap = window.L.map(container, {
					center: [lat, lng],
					zoom: 15,
					zoomControl: true,
					attributionControl: false
				});

				window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
					maxZoom: 19
				}).addTo(this.campaignMap);

				const pinIcon = window.L.divIcon({
					html: '<div class="custom-pin"><i class="fa-solid fa-location-dot"></i></div>',
					iconSize: [36, 36],
					iconAnchor: [18, 36],
					className: 'custom-pin-wrapper'
				});

				this.campaignMarker = window.L.marker([lat, lng], {
					draggable: true,
					icon: pinIcon
				}).addTo(this.campaignMap);

				this.formData.latitude = lat.toFixed(7);
				this.formData.longitude = lng.toFixed(7);

				this.campaignMarker.on('dragend', (e) => {
					const pos = e.target.getLatLng();
					this.formData.latitude = pos.lat.toFixed(7);
					this.formData.longitude = pos.lng.toFixed(7);
				});

				// Fix map rendering inside modal
				setTimeout(() => { this.campaignMap.invalidateSize(); }, 300);
			});
		},
		destroyCampaignMap() {
			if (this.campaignMap) {
				this.campaignMap.remove();
				this.campaignMap = null;
				this.campaignMarker = null;
			}
		},
		updateCampaignMapPosition(lat, lng) {
			if (this.campaignMap && this.campaignMarker) {
				this.campaignMap.setView([lat, lng], 16, { animate: true });
				this.campaignMarker.setLatLng([lat, lng]);
				this.formData.latitude = lat.toFixed(7);
				this.formData.longitude = lng.toFixed(7);
			} else {
				this.initCampaignMap(lat, lng);
			}
		},
		async geocodeCampaign(address) {
			this.campaignGeocoding = true;
			this.campaignGeocodeStatus = '';
			this.campaignGeocodeMessage = '';
			try {
				let filteredAddress = address.trim();
				filteredAddress = filteredAddress.replace(/^[A-Z0-9]{4,8}\+[A-Z0-9]{2,}\s*,?\s*/g, '');

				if (/^\d/.test(filteredAddress)) {
					filteredAddress = filteredAddress.replace(/^(\d+)\s*/, 'Số $1, ');
				}

				const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(filteredAddress)}&countrycodes=vn&limit=3`;
				let res = await fetch(url, { headers: { 'Accept-Language': 'vi' } });
				let data = await res.json();

				if ((!data || data.length === 0) && filteredAddress.includes(',')) {
					const fallbackAddress = filteredAddress.substring(filteredAddress.indexOf(',') + 1).trim();
					const fallbackUrl = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(fallbackAddress)}&countrycodes=vn&limit=3`;
					res = await fetch(fallbackUrl, { headers: { 'Accept-Language': 'vi' } });
					data = await res.json();
				}

				if (data && data.length > 0) {
					const lat = parseFloat(data[0].lat);
					const lng = parseFloat(data[0].lon);
					this.updateCampaignMapPosition(lat, lng);
					this.campaignGeocodeStatus = 'success';
					this.campaignGeocodeMessage = `${this.$t('coordinator.locationFound')} ${data[0].display_name.substring(0, 100)}`;
				} else {
					this.campaignGeocodeStatus = 'fallback';
					this.campaignGeocodeMessage = this.$t('coordinator.locationNotFound');
					if (!this.campaignMap) this.initCampaignMap();
				}
			} catch (err) {
				this.campaignGeocodeStatus = 'fallback';
				this.campaignGeocodeMessage = this.$t('coordinator.connectionError');
				if (!this.campaignMap) this.initCampaignMap();
			} finally {
				this.campaignGeocoding = false;
			}
		}
	}
}
</script>

<style scoped>
.campaign-avatar { width: 40px; height: 40px; }
.campaign-grid-banner { height: 90px; }
.min-w-0 { min-width: 0; }

.campaign-row { transition: background-color 0.15s ease; }
.campaign-row:hover { background-color: rgba(13, 110, 253, 0.03) !important; }

.hover-card { transition: all 0.2s ease; }
.hover-card:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(0,0,0,0.08) !important; }

.text-truncate-2 { display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

.skill-tag { transition: all 0.15s ease; }
.skill-tag:hover { opacity: 0.85; }

.nav-tabs-custom .nav-link { border: none; border-bottom: 3px solid transparent; border-radius: 0; font-size: 13px; }
.nav-tabs-custom .nav-link.active { border-bottom-color: #0d6efd; background: transparent; }
.nav-tabs-custom .nav-link:hover:not(.active) { border-bottom-color: #dee2e6; }

.campaign-map-wrapper {
	height: 250px;
	width: 100%;
	z-index: 0;
}

@media (max-width: 575.98px) {
	.campaign-avatar { width: 34px; height: 34px; font-size: 12px; }
	.campaign-grid-banner { height: 70px; }
	.campaign-map-wrapper { height: 200px; }
}
</style>

<style>
/* Leaflet custom pin - global */
.custom-pin-wrapper {
	background: none !important;
	border: none !important;
}
.custom-pin {
	font-size: 36px;
	color: #dc3545;
	filter: drop-shadow(0 2px 4px rgba(0,0,0,0.4));
	animation: campaign-pin-bounce 0.4s ease;
	transition: transform 0.15s;
	cursor: grab;
}
.custom-pin:hover {
	transform: scale(1.2);
}
@keyframes campaign-pin-bounce {
	0% { transform: translateY(-20px); opacity: 0; }
	60% { transform: translateY(4px); }
	100% { transform: translateY(0); opacity: 1; }
}
</style>
