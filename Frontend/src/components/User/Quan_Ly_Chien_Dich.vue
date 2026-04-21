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
											<i v-if="!campaignHasCover(campaign)" :class="campaign.icon"></i>
										</div>
										<div style="min-width: 0;">
											<div class="fw-bold text-dark text-truncate" style="max-width: 300px;">{{ campaign.title }}</div>
											<div class="text-muted small text-truncate d-none d-sm-block" style="max-width: 300px;" :title="campaign.description">{{ campaign.descriptionPreview || campaign.description }}</div>
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
										<button v-if="canEditCampaign(campaign)" type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.editMenu')" @click.prevent="editCampaign(campaign)">
											<i class="fa-regular fa-pen-to-square text-warning fs-6"></i>
										</button>
										<button v-if="canStartCampaign(campaign)" type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.startCampaignMenu')" @click.prevent="confirmStatusChange(campaign, 'dang_dien_ra')">
											<i class="fa-solid fa-play text-success fs-6"></i>
										</button>
										<button v-if="canManageCampaigns && campaign.status === 'active'" type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.completeCampaignMenu')" @click.prevent="confirmStatusChange(campaign, 'hoan_thanh')">
											<i class="fa-solid fa-flag-checkered text-success fs-6"></i>
										</button>
										<button v-if="canDeleteCampaign(campaign)" type="button" class="btn btn-sm btn-light border-0 bg-transparent shadow-none" :title="$t('coordinator.cancelCampaignMenu')" @click.prevent="confirmCancel(campaign)">
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
								<p class="text-muted small mb-3 text-truncate-2" :title="campaign.description">{{ campaign.descriptionPreview || campaign.description }}</p>
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
								<button v-if="canEditCampaign(campaign)" class="btn btn-sm btn-outline-primary flex-fill d-flex align-items-center justify-content-center gap-1" @click="editCampaign(campaign)">
									<i class="fa-regular fa-pen-to-square" style="font-size:12px"></i><span>{{ $t('coordinator.editBtn') }}</span>
								</button>
								<button class="btn btn-sm btn-outline-secondary flex-fill d-flex align-items-center justify-content-center gap-1" @click="viewCampaign(campaign)">
									<i class="fa-regular fa-eye" style="font-size:12px"></i><span>{{ $t('coordinator.detailsBtn') }}</span>
								</button>
								<button v-if="canStartCampaign(campaign)" class="btn btn-sm btn-outline-success d-flex align-items-center justify-content-center" style="width: 34px;height: 34px;padding-left: 10px;" :title="$t('coordinator.startCampaignMenu')" @click="confirmStatusChange(campaign, 'dang_dien_ra')">
									<i class="fa-solid fa-play" style="font-size:12px"></i>
								</button>
								<button v-else-if="canManageCampaigns && campaign.status === 'active'" class="btn btn-sm btn-outline-success d-flex align-items-center justify-content-center" style="width: 34px;height: 34px;padding-left: 10px;" :title="$t('coordinator.completeCampaignMenu')" @click="confirmStatusChange(campaign, 'hoan_thanh')">
									<i class="fa-solid fa-flag-checkered" style="font-size:12px"></i>
								</button>
								<button v-if="canDeleteCampaign(campaign)" class="btn btn-sm btn-outline-danger d-flex align-items-center justify-content-center" style="width: 34px;height: 34px;padding-left: 12px;" @click="confirmCancel(campaign)">
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
			<div class="modal-dialog campaign-modal-2xl modal-dialog-centered modal-dialog-scrollable">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-bottom px-4 pt-4 pb-3">
						<h5 class="modal-title fw-bold fs-4 text-dark">{{ isEditing ? $t('coordinator.editCampaignTitle') : $t('coordinator.createCampaignTitle') }}</h5>
						<button type="button" class="btn-close" data-bs-dismiss="modal" :disabled="isSaving"></button>
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
									<label class="form-label fw-semibold small mb-2">{{ $t('coordinator.descriptionLabel') }} <span class="text-danger">*</span></label>
									<div class="row g-3">
										<div v-for="field in descriptionFieldConfigs" :key="field.key" class="col-12 col-xl-6">
											<label class="form-label fw-semibold small">{{ field.label }}</label>
											<textarea
												class="form-control"
												rows="3"
												v-model.trim="formData.descriptionForm[field.key]"
												:placeholder="field.placeholder"></textarea>
										</div>
									</div>
								</div>
								<div class="col-12">
									<label class="form-label fw-semibold small">Mô tả hoàn chỉnh</label>
									<textarea
										class="form-control bg-light-subtle"
										rows="6"
										:value="generatedDescriptionValue"
										readonly
									></textarea>
									<div v-if="formErrors.description" class="invalid-feedback d-block">{{ formErrors.description }}</div>
									<div class="form-text">Nội dung này sẽ được gửi lên hệ thống làm mô tả chiến dịch.</div>
								</div>
								<div class="col-12">
									<div class="row g-3">
										<div class="col-12">
											<label class="form-label fw-semibold small">Ảnh bìa <span class="text-danger">*</span></label>
											<div class="upload-media-card" :class="{ 'is-invalid': formErrors.coverImage }">
												<div class="upload-media-preview">
													<img
														v-if="formData.coverPreviewImage"
														:src="formData.coverPreviewImage.url"
														alt="Ảnh bìa chiến dịch"
														class="upload-media-image">
													<div v-else class="upload-media-placeholder">
														<i class="fa-regular fa-image"></i>
														<span>Chưa chọn ảnh bìa</span>
													</div>
													<button
														v-if="formData.coverPreviewImage"
														type="button"
														class="btn btn-sm btn-light position-absolute top-0 end-0 m-2 rounded-circle shadow-sm"
														@click="removeCoverImage">
														<i class="fa-solid fa-xmark"></i>
													</button>
												</div>
												<div class="upload-media-body">
													<input
														type="file"
														class="form-control"
														accept="image/*"
														@change="onCoverImageChange">
													<div class="form-text mt-2">
														{{ formData.coverImageFile?.name || 'Ảnh này sẽ được dùng làm ảnh bìa chiến dịch.' }}
													</div>
												</div>
											</div>
											<div v-if="formErrors.coverImage" class="invalid-feedback d-block">{{ formErrors.coverImage }}</div>
										</div>
										<div class="col-12">
											<div class="d-flex align-items-center justify-content-between gap-3 mb-2">
												<label class="form-label fw-semibold small mb-0">Ảnh mô tả chiến dịch <span class="text-danger">*</span></label>
												<button type="button" class="btn btn-sm btn-outline-primary rounded-pill px-3" @click="addDetailImageInput">
													<i class="fa-solid fa-plus me-1"></i>Thêm ảnh
												</button>
											</div>
											<div class="row g-3">
												<div v-for="(uploadInput, index) in formData.detailImageInputs" :key="uploadInput.id" class="col-12 col-md-4">
													<div class="upload-media-card h-100" :class="{ 'is-invalid': formErrors.detailImages }">
														<div class="upload-media-preview">
															<img
																v-if="uploadInput.previewUrl"
																:src="uploadInput.previewUrl"
																:alt="`Ảnh mô tả ${index + 1}`"
																class="upload-media-image">
															<div v-else class="upload-media-placeholder">
																<i class="fa-regular fa-images"></i>
																<span>{{ `Ảnh mô tả ${index + 1}` }}</span>
															</div>
															<button
																type="button"
																class="btn btn-sm btn-light position-absolute top-0 end-0 m-2 rounded-circle shadow-sm"
																@click="removeDetailImageInput(uploadInput.id)"
																:title="'Xóa ô upload'"
																:disabled="formData.detailImageInputs.length <= 3 && !uploadInput.file">
																<i class="fa-solid fa-xmark"></i>
															</button>
														</div>
														<div class="upload-media-body">
															<input
																type="file"
																class="form-control"
																accept="image/*"
																@change="onDetailImagesChange($event, uploadInput.id)">
															<div class="form-text mt-2">
																{{ uploadInput.file?.name || 'Ô upload ảnh mô tả chiến dịch.' }}
															</div>
														</div>
													</div>
												</div>
											</div>
											<div class="form-text">Vui lòng tải tối thiểu 3 ảnh mô tả chiến dịch.</div>
											<div v-if="formErrors.detailImages" class="invalid-feedback d-block">{{ formErrors.detailImages }}</div>
											<div v-if="false && formData.existingDetailImages.length" class="row g-3 mt-1">
												<div v-for="(imageUrl, index) in formData.existingDetailImages" :key="`existing-detail-card-${imageUrl}-${index}`" class="col-sm-6 col-lg-4">
													<div class="upload-media-card h-100">
														<div class="upload-media-preview">
															<div class="position-absolute top-0 start-0 m-2 badge bg-dark bg-opacity-75">
																{{ `Ảnh hiện tại ${index + 1}` }}
															</div>
															<button
																type="button"
																class="btn btn-sm btn-light position-absolute top-0 end-0 m-2 rounded-circle shadow-sm"
																@click="removeDetailImage({ type: 'existing-detail', url: imageUrl })">
																<i class="fa-solid fa-xmark"></i>
															</button>
															<img :src="imageUrl" alt="Hình ảnh chiến dịch" class="upload-media-image">
														</div>
														<div class="upload-media-body py-2">
															<div class="small text-muted">Ảnh mô tả hiện tại của chiến dịch.</div>
														</div>
													</div>
												</div>
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
									<div class="position-relative">
										<div class="input-group">
											<span class="input-group-text bg-light"><i class="fa-solid fa-location-dot text-danger"></i></span>
											<input
												ref="locationInput"
												type="text"
												class="form-control"
												:class="{ 'is-invalid': formErrors.location }"
												v-model.trim="formData.location"
												:placeholder="$t('coordinator.locationPlaceholder')"
												autocomplete="off"
												required
												@input="handleLocationInput"
												@focus="handleLocationFocus"
												@blur="handleLocationBlur"
												@keydown="handleLocationKeydown">
											<span class="input-group-text bg-white" v-if="campaignGeocoding || locationSuggestionLoading">
												<span class="spinner-border spinner-border-sm text-primary" role="status"></span>
											</span>
										</div>
										<div
											v-if="locationSuggestionsVisible && (locationSuggestions.length || locationSuggestionLoading || formData.location)"
											class="location-suggestions-dropdown shadow-sm">
											<div
												v-for="(suggestion, index) in locationSuggestions"
												:key="suggestion.key"
												class="location-suggestion-item"
												:class="{ active: index === locationSuggestionIndex }"
												role="button"
												tabindex="-1"
												@mousedown.prevent="selectLocationSuggestion(suggestion)">
												<div class="d-flex justify-content-between align-items-start gap-3">
													<div class="min-w-0">
														<div class="fw-semibold text-dark text-truncate">{{ suggestion.label }}</div>
														<div v-if="suggestion.meta" class="small text-muted text-truncate">{{ suggestion.meta }}</div>
													</div>
													<span class="badge rounded-pill location-suggestion-source">{{ getLocationSuggestionSourceLabel(suggestion.source) }}</span>
												</div>
											</div>
											<div v-if="locationSuggestionLoading && !locationSuggestions.length" class="location-suggestion-empty text-muted">
												<i class="fa-solid fa-spinner fa-spin me-2"></i>{{ $t('coordinator.locationSuggestionLoading') }}
											</div>
											<div v-else-if="!locationSuggestionLoading && !locationSuggestions.length && formData.location" class="location-suggestion-empty text-muted">
												<i class="fa-solid fa-circle-info me-2"></i>{{ $t('coordinator.locationSuggestionsEmpty') }}
											</div>
										</div>
									</div>
									<div v-if="formErrors.location" class="invalid-feedback d-block">{{ formErrors.location }}</div>
									<div class="form-text small text-muted">{{ $t('coordinator.locationHint') }}</div>
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
						<button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal" :disabled="isSaving">{{ $t('coordinator.cancelBtn') }}</button>
						<button type="button" class="btn btn-primary shadow-sm" @click="saveCampaign" :disabled="!canManageCampaigns || isSaving">
							<i v-if="isSaving" class="fa-solid fa-spinner fa-spin me-1"></i>
							<i v-else class="fa-solid fa-paper-plane me-1"></i>{{ isSaving ? 'Đang xử lý...' : (isEditing ? $t('coordinator.updateBtn') : $t('coordinator.submitBtn')) }}
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
import { buildCampaignDescriptionPreview, extractCampaignDescriptionSections } from '../../utils/campaignDescription'

// Priority mapping: DB enum ↔ frontend key
const PRIORITY_MAP = { khan_cap: 'urgent', cao: 'high', trung_binh: 'medium', thap: 'low' };
const PRIORITY_MAP_REVERSE = { urgent: 'khan_cap', high: 'cao', medium: 'trung_binh', low: 'thap' };

// Status mapping: DB enum → frontend key
const STATUS_MAP = { cho_duyet: 'pending', tu_choi: 'rejected', da_duyet: 'approved', dang_dien_ra: 'active', hoan_thanh: 'completed', yeu_cau_huy: 'pending_cancel', da_huy: 'cancelled', nhap: 'draft' };

const DESCRIPTION_FIELD_CONFIG = [
	{
		key: 'purpose',
		label: 'Chiến dịch này được tổ chức nhằm mục đích gì?',
		placeholder: 'Ví dụ: Hỗ trợ học sinh vùng sâu có thêm điều kiện học tập và sinh hoạt tốt hơn.',
		sentence: 'Chiến dịch này được tổ chức nhằm mục đích {value}.',
	},
	{
		key: 'problem',
		label: 'Vấn đề hoặc nhu cầu nào mà chiến dịch muốn giải quyết?',
		placeholder: 'Ví dụ: Thiếu sách vở, vật dụng học tập và hoạt động đồng hành cho học sinh.',
		sentence: 'Chiến dịch tập trung giải quyết vấn đề hoặc nhu cầu là {value}.',
	},
	{
		key: 'tasks',
		label: 'Tình nguyện viên sẽ thực hiện những công việc cụ thể nào?',
		placeholder: 'Ví dụ: Phân loại quà tặng, tổ chức trò chơi, hỗ trợ hậu cần và hướng dẫn các em.',
		sentence: 'Tình nguyện viên sẽ trực tiếp thực hiện các công việc như {value}.',
	},
	{
		key: 'commitment',
		label: 'Tình nguyện viên cần cam kết những gì khi tham gia?',
		placeholder: 'Ví dụ: Có mặt đúng giờ, phối hợp theo nhóm và tuân thủ hướng dẫn của ban tổ chức.',
		sentence: 'Khi tham gia, tình nguyện viên cần cam kết {value}.',
	},
	{
		key: 'benefits',
		label: 'Quyền lợi hoặc hỗ trợ dành cho tình nguyện viên là gì?',
		placeholder: 'Ví dụ: Được hỗ trợ ăn trưa, cấp giấy chứng nhận và hướng dẫn trước khi tham gia.',
		sentence: 'Quyền lợi hoặc hỗ trợ dành cho tình nguyện viên bao gồm {value}.',
	},
	{
		key: 'contact',
		label: 'Thông tin liên hệ của người phụ trách chiến dịch là gì?',
		placeholder: 'Ví dụ: Chị Lan - 09xx xxx xxx - lan@vms.vn.',
		sentence: 'Thông tin liên hệ của người phụ trách chiến dịch là {value}.',
	},
];

const DESCRIPTION_FIELD_PREFIXES = {
	purpose: 'Chiến dịch này được tổ chức nhằm mục đích',
	problem: 'Chiến dịch tập trung giải quyết vấn đề hoặc nhu cầu là',
	tasks: 'Tình nguyện viên sẽ trực tiếp thực hiện các công việc như',
	commitment: 'Khi tham gia, tình nguyện viên cần cam kết',
	benefits: 'Quyền lợi hoặc hỗ trợ dành cho tình nguyện viên bao gồm',
	contact: 'Thông tin liên hệ của người phụ trách chiến dịch là',
};

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
			locationOptions: [],
			locationSuggestions: [],
			locationSuggestionsVisible: false,
			locationSuggestionIndex: -1,
			locationSuggestionLoading: false,
			locationSuggestionTimer: null,
			locationSuggestionRequestId: 0,
			formErrors: {},
			formData: {
				title: '', description: '', category: '', priority: '',
				descriptionForm: DESCRIPTION_FIELD_CONFIG.reduce((accumulator, field) => {
					accumulator[field.key] = '';
					return accumulator;
				}, {}),
				location: '', latitude: null, longitude: null,
				startDate: '', endDate: '',
				maxVolunteers: null, minVolunteers: null, requiredSkills: [],
				coverUrl: null,
				images: [],
				existingCoverImage: null,
				coverImageFile: null,
				coverPreviewUrl: '',
				coverPreviewImage: null,
				existingDetailImages: [],
				detailImages: [],
				detailImageInputs: [],
				detailPreviewImages: [],
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
		descriptionFieldConfigs() {
			return DESCRIPTION_FIELD_CONFIG;
		},
		generatedDescriptionValue() {
			return this.buildDescriptionPayload();
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
			if (this.locationSuggestionTimer) clearTimeout(this.locationSuggestionTimer);
			if (this.isEditing && this._justOpenedEdit) {
				this._justOpenedEdit = false;
				return;
			}
			if (this._applyingLocationSuggestion) {
				this._applyingLocationSuggestion = false;
				return;
			}
			const query = String(newVal || '').trim();
			if (!query) {
				this.locationSuggestions = [];
				this.locationSuggestionsVisible = false;
				this.locationSuggestionIndex = -1;
				this.locationSuggestionLoading = false;
				this.campaignGeocodeStatus = '';
				this.campaignGeocodeMessage = '';
				this.formData.latitude = null;
				this.formData.longitude = null;
				this.destroyCampaignMap();
				return;
			}
			this.queueLocationSuggestions(query);
			if (query.length >= 3 && query !== oldVal) {
				this.campaignGeocodeTimer = setTimeout(() => {
					this.geocodeCampaign(query);
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
		this.loadLocationOptions();
	},
	beforeUnmount() {
		if (this._searchTimer) clearTimeout(this._searchTimer);
		if (this.campaignGeocodeTimer) clearTimeout(this.campaignGeocodeTimer);
		if (this.locationSuggestionTimer) clearTimeout(this.locationSuggestionTimer);
		this.releaseCampaignImageObjectUrls();
		this.destroyCampaignMap();
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
		async loadLocationOptions() {
			try {
				const [regionRes, provinceRes] = await Promise.allSettled([
					api.get('/danh-muc/khu-vuc'),
					api.get('/danh-muc/tinh-thanh'),
				]);
				const options = [];
				const pushOption = (item, source, latitude = null, longitude = null) => {
					const label = String(item?.ten || '').trim();
					if (!label) return;
					options.push({
						key: `${source}-${item.id}-${label}`,
						label,
						value: label,
						searchText: label,
						source,
						meta: '',
						latitude: latitude === null || latitude === undefined || latitude === '' ? null : Number(latitude),
						longitude: longitude === null || longitude === undefined || longitude === '' ? null : Number(longitude),
						searchIndex: this.buildLocationSearchIndex(label),
					});
				};

				if (regionRes.status === 'fulfilled' && regionRes.value.data?.status === 1) {
					regionRes.value.data.data.forEach((item) => pushOption(item, 'internal'));
				}

				if (provinceRes.status === 'fulfilled' && provinceRes.value.data?.status === 1) {
					provinceRes.value.data.data.forEach((item) => pushOption(item, 'province', item.vi_do, item.kinh_do));
				}

				this.locationOptions = this.mergeLocationSuggestions(options);
			} catch (err) {
				console.error('Lá»—i táº£i danh sÃ¡ch Ä‘á»‹a Ä‘iá»ƒm:', err);
				this.locationOptions = [];
			}
		},
		normalizeLocationSearch(value) {
			return String(value || '')
				.normalize('NFD')
				.replace(/[\u0300-\u036f]/g, '')
				.toLowerCase()
				.replace(/\u0111/g, 'd')
				.replace(/[^a-z0-9]+/g, ' ')
				.trim();
		},
		buildLocationSearchIndex(label) {
			const normalized = this.normalizeLocationSearch(label);
			const aliases = [normalized];
			if (normalized.includes('ho chi minh')) {
				aliases.push('hcm', 'tphcm', 'tp hcm', 'ho chi minh', 'sai gon', 'saigon');
			}
			if (normalized === 'ha noi') aliases.push('hn');
			if (normalized === 'da nang') aliases.push('dn');
			if (normalized.startsWith('tp ')) {
				aliases.push(normalized.replace(/^tp\s+/, ''));
			}
			if (normalized.startsWith('thanh pho ')) {
				aliases.push(normalized.replace(/^thanh pho\s+/, ''));
			}
			return Array.from(new Set(aliases)).join(' ');
		},
		scoreLocationSuggestion(option, normalizedQuery) {
			const searchIndex = option.searchIndex || this.buildLocationSearchIndex(option.label);
			if (!normalizedQuery) return 0;
			if (searchIndex === normalizedQuery) return 0;
			if (searchIndex.startsWith(normalizedQuery)) return 1;
			if (searchIndex.includes(` ${normalizedQuery}`)) return 2;
			const idx = searchIndex.indexOf(normalizedQuery);
			return idx === -1 ? Number.MAX_SAFE_INTEGER : 10 + idx;
		},
		buildLocalLocationSuggestions(query) {
			const normalizedQuery = this.normalizeLocationSearch(query);
			if (!normalizedQuery) return [];

			return [...this.locationOptions]
				.filter((option) => (option.searchIndex || '').includes(normalizedQuery))
				.sort((a, b) => {
					const scoreDiff = this.scoreLocationSuggestion(a, normalizedQuery) - this.scoreLocationSuggestion(b, normalizedQuery);
					if (scoreDiff !== 0) return scoreDiff;
					if (a.source !== b.source) return a.source === 'province' ? -1 : 1;
					return a.label.localeCompare(b.label, 'vi');
				})
				.slice(0, 6);
		},
		mergeLocationSuggestions(...groups) {
			const deduped = new Map();
			groups
				.flat()
				.filter(Boolean)
				.forEach((item) => {
					const key = this.normalizeLocationSearch(item.value || item.label);
					if (!key) return;
					const existing = deduped.get(key);
					if (!existing || this.getLocationSuggestionPriority(item) > this.getLocationSuggestionPriority(existing)) {
						deduped.set(key, item);
					}
				});
			return Array.from(deduped.values());
		},
		getLocationSuggestionPriority(item) {
			return { province: 3, internal: 2, map: 1 }[item?.source] || 0;
		},
		queueLocationSuggestions(query) {
			const localSuggestions = this.buildLocalLocationSuggestions(query);
			this.locationSuggestions = localSuggestions;
			this.locationSuggestionsVisible = true;
			this.locationSuggestionIndex = localSuggestions.length ? 0 : -1;
			this.locationSuggestionLoading = query.length >= 2;

			if (query.length < 2) {
				this.locationSuggestionLoading = false;
				return;
			}

			const requestId = ++this.locationSuggestionRequestId;
			this.locationSuggestionTimer = setTimeout(() => {
				this.fetchRemoteLocationSuggestions(query, requestId);
			}, 250);
		},
		async fetchRemoteLocationSuggestions(query, requestId) {
			try {
				const url = `https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&q=${encodeURIComponent(query)}&countrycodes=vn&limit=5`;
				const res = await fetch(url, { headers: { 'Accept-Language': 'vi' } });
				const data = await res.json();
				if (requestId !== this.locationSuggestionRequestId || this.normalizeLocationSearch(this.formData.location) !== this.normalizeLocationSearch(query)) {
					return;
				}

				const remoteSuggestions = (Array.isArray(data) ? data : [])
					.map((item) => this.mapRemoteLocationSuggestion(item))
					.filter(Boolean);

				this.locationSuggestions = this.mergeLocationSuggestions(this.buildLocalLocationSuggestions(query), remoteSuggestions).slice(0, 8);
				this.locationSuggestionIndex = this.locationSuggestions.length ? 0 : -1;
			} catch (_err) {
				if (requestId === this.locationSuggestionRequestId) {
					this.locationSuggestions = this.buildLocalLocationSuggestions(query);
				}
			} finally {
				if (requestId === this.locationSuggestionRequestId) {
					this.locationSuggestionLoading = false;
				}
			}
		},
		mapRemoteLocationSuggestion(item) {
			if (!item?.display_name) return null;
			const address = item.address || {};
			const parts = [
				address.suburb,
				address.city_district,
				address.county,
				address.city,
				address.state,
			]
				.filter(Boolean)
				.filter((value, index, arr) => arr.findIndex((candidate) => this.normalizeLocationSearch(candidate) === this.normalizeLocationSearch(value)) === index);
			const label = parts.slice(0, 2).join(', ') || item.display_name.split(',').slice(0, 2).join(', ').trim();
			const selectedValue = item.display_name.split(',').slice(0, 4).join(', ').trim() || label;
			return {
				key: `remote-${item.place_id}`,
				label,
				value: selectedValue,
				meta: item.display_name.split(',').slice(0, 4).join(', ').trim(),
				searchText: item.display_name,
				source: 'map',
				latitude: Number(item.lat),
				longitude: Number(item.lon),
				searchIndex: this.buildLocationSearchIndex(label),
			};
		},
		handleLocationInput() {
			this.formErrors.location = '';
		},
		handleLocationFocus() {
			if (this.formData.location?.trim()) {
				this.queueLocationSuggestions(this.formData.location.trim());
			}
		},
		handleLocationBlur() {
			setTimeout(() => {
				this.locationSuggestionsVisible = false;
				this.locationSuggestionIndex = -1;
			}, 150);
		},
		handleLocationKeydown(event) {
			if (!this.locationSuggestionsVisible || !this.locationSuggestions.length) {
				if (event.key === 'Escape') this.locationSuggestionsVisible = false;
				return;
			}

			if (event.key === 'ArrowDown') {
				event.preventDefault();
				this.locationSuggestionIndex = (this.locationSuggestionIndex + 1) % this.locationSuggestions.length;
				return;
			}

			if (event.key === 'ArrowUp') {
				event.preventDefault();
				this.locationSuggestionIndex = this.locationSuggestionIndex <= 0
					? this.locationSuggestions.length - 1
					: this.locationSuggestionIndex - 1;
				return;
			}

			if (event.key === 'Enter' && this.locationSuggestionIndex >= 0) {
				event.preventDefault();
				this.selectLocationSuggestion(this.locationSuggestions[this.locationSuggestionIndex]);
				return;
			}

			if (event.key === 'Escape') {
				this.locationSuggestionsVisible = false;
				this.locationSuggestionIndex = -1;
			}
		},
		selectLocationSuggestion(suggestion) {
			if (!suggestion) return;
			this._applyingLocationSuggestion = true;
			this.formData.location = suggestion.value;
			this.locationSuggestionsVisible = false;
			this.locationSuggestionIndex = -1;
			this.locationSuggestionLoading = false;

			if (Number.isFinite(suggestion.latitude) && Number.isFinite(suggestion.longitude)) {
				this.updateCampaignMapPosition(suggestion.latitude, suggestion.longitude);
				this.campaignGeocodeStatus = 'success';
				this.campaignGeocodeMessage = `${this.$t('coordinator.locationFound')} ${suggestion.label}`;
				return;
			}

			this.geocodeCampaign(suggestion.searchText || suggestion.value);
		},
		getLocationSuggestionSourceLabel(source) {
			if (source === 'map') return this.$t('coordinator.locationSourceMap');
			return this.$t('coordinator.locationSourceInternal');
		},

		// ===== Mapping helpers =====
		mapCampaignFromApi(cd) {
			const loai = cd.loai_chien_dich;
			const rawImages = Array.isArray(cd.danh_sach_anh) ? cd.danh_sach_anh : [];
			const { coverImage, detailImages, allImages } = this.splitCampaignImages({
				coverUrl: cd.anh_bia,
				images: rawImages,
			});
			return {
				id: cd.id,
				title: cd.tieu_de,
				description: cd.mo_ta || '',
				descriptionPreview: buildCampaignDescriptionPreview(cd.mo_ta),
				coverUrl: coverImage,
				images: allImages.length ? allImages : [coverImage, ...detailImages].filter(Boolean),
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
		getStatusClass(s) { return { approved: 'bg-info text-white', active: 'bg-success text-white', pending: 'bg-warning text-dark', completed: 'bg-secondary text-white', pending_cancel: 'pending-cancel-badge text-white', cancelled: 'bg-danger bg-opacity-75 text-white', rejected: 'bg-dark text-white', draft: 'bg-light text-dark border' }[s] || 'bg-secondary'; },
		getStatusIcon(s) { return { approved: 'fa-solid fa-badge-check', active: 'fa-solid fa-circle-play', pending: 'fa-solid fa-hourglass-half', completed: 'fa-solid fa-circle-check', pending_cancel: 'fa-solid fa-clock-rotate-left', cancelled: 'fa-solid fa-ban', rejected: 'fa-solid fa-circle-xmark', draft: 'fa-solid fa-file-lines' }[s] || ''; },
		getProgress(c) { return c.maxVolunteers ? Math.round(c.registered / c.maxVolunteers * 100) : 0; },
		canEditCampaign(campaign) {
			return this.canManageCampaigns && !['pending_cancel', 'cancelled'].includes(campaign.status);
		},
		canStartCampaign(campaign) {
			return this.canManageCampaigns && campaign.status === 'approved';
		},
		canDeleteCampaign(campaign) {
			return this.canManageCampaigns && !['pending_cancel', 'cancelled'].includes(campaign.status);
		},
		campaignHasCover(campaign) {
			return Boolean(campaign?.coverUrl || campaign?.images?.[0]);
		},
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
			this.releaseCampaignImageObjectUrls();
			this.formErrors = {};
			this.formData = {
				title: '', description: '', category: '', priority: '',
				descriptionForm: this.createDescriptionForm(),
				location: '', latitude: null, longitude: null,
				startDate: '', endDate: '', maxVolunteers: null, minVolunteers: null, requiredSkills: [],
				coverUrl: null,
				images: [],
				existingCoverImage: null,
				coverImageFile: null,
				coverPreviewUrl: '',
				coverPreviewImage: null,
				existingDetailImages: [],
				detailImages: [],
				detailImageInputs: this.createCampaignImageInputs(3),
				detailPreviewImages: [],
			};
			this.locationSuggestions = [];
			this.locationSuggestionsVisible = false;
			this.locationSuggestionIndex = -1;
			this.locationSuggestionLoading = false;
			this.campaignGeocodeStatus = '';
			this.campaignGeocodeMessage = '';
			this.destroyCampaignMap();
		},
		openCreateModal() { this.isEditing = false; this.resetForm(); new bootstrap.Modal(this.$refs.campaignModal).show(); },
		editCampaign(c) {
			if (!this.canEditCampaign(c)) return;
			this.releaseCampaignImageObjectUrls();
			this.isEditing = true;
			this._justOpenedEdit = true;
			const { coverImage: existingCoverImage, detailImages: existingDetailImages, allImages: images } = this.splitCampaignImages({
				coverUrl: c.coverUrl,
				images: c.images || [],
			});
			this.formData = {
				...c,
				descriptionForm: this.parseDescriptionForm(c.description),
				requiredSkills: [...c.requiredSkills],
				coverUrl: existingCoverImage,
				images,
				existingCoverImage,
				coverImageFile: null,
				coverPreviewUrl: '',
				coverPreviewImage: existingCoverImage ? {
					key: `existing-cover-${existingCoverImage}`,
					type: 'existing-cover',
					url: existingCoverImage,
				} : null,
				existingDetailImages,
				detailImages: [],
				detailImageInputs: this.createCampaignImageInputsFromUrls(existingDetailImages, 3),
				detailPreviewImages: existingDetailImages.map((url, index) => ({
					key: `existing-detail-${index}-${url}`,
					type: 'existing-detail',
					url,
				})),
			};
			this.locationSuggestions = [];
			this.locationSuggestionsVisible = false;
			this.locationSuggestionIndex = -1;
			this.locationSuggestionLoading = false;
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
		createDescriptionForm() {
			return DESCRIPTION_FIELD_CONFIG.reduce((accumulator, field) => {
				accumulator[field.key] = '';
				return accumulator;
			}, {});
		},
		parseDescriptionForm(description) {
			const fallback = this.createDescriptionForm();
			const items = String(description || '')
				.replace(/\r/g, '')
				.split('\n')
				.map((item) => item.replace(/^\s*[-•]\s*/, '').trim())
				.filter(Boolean);

			if (!items.length) {
				return fallback;
			}

			const matchedKeys = new Set();
			items.forEach((item) => {
				DESCRIPTION_FIELD_CONFIG.forEach((field) => {
					const prefix = DESCRIPTION_FIELD_PREFIXES[field.key];
					if (!prefix || matchedKeys.has(field.key)) return;
					if (item.startsWith(prefix)) {
						fallback[field.key] = item.slice(prefix.length).replace(/^[:\s]+/, '').replace(/[.]+$/, '').trim();
						matchedKeys.add(field.key);
					}
				});
			});

			if (matchedKeys.size === 0) {
				DESCRIPTION_FIELD_CONFIG.forEach((field, index) => {
					fallback[field.key] = items[index] || '';
				});
			}

			if (matchedKeys.size > 0 && matchedKeys.size < DESCRIPTION_FIELD_CONFIG.length) {
				const remainingItems = items.filter((item) => !Array.from(matchedKeys).some((key) => item.startsWith(DESCRIPTION_FIELD_PREFIXES[key])));
				DESCRIPTION_FIELD_CONFIG.forEach((field) => {
					if (!fallback[field.key] && remainingItems.length) {
						fallback[field.key] = remainingItems.shift() || '';
					}
				});
			}

			return fallback;
		},
		normalizeDescriptionFieldValue(value) {
			return String(value || '')
				.replace(/\s+/g, ' ')
				.trim()
				.replace(/[.]+$/, '');
		},
		buildDescriptionPayload() {
			return DESCRIPTION_FIELD_CONFIG
				.map((field) => {
					const value = this.normalizeDescriptionFieldValue(this.formData.descriptionForm?.[field.key]);
					if (!value) return '';
					return field.sentence.replace('{value}', value);
				})
				.filter(Boolean)
				.join(' ');
		},
		syncDescriptionValue() {
			this.formData.description = this.buildDescriptionPayload();
		},
		parseDescriptionForm(description) {
			const fallback = this.createDescriptionForm();
			const extractedSections = extractCampaignDescriptionSections(description);
			if (extractedSections.length) {
				extractedSections.forEach((section) => {
					if (Object.prototype.hasOwnProperty.call(fallback, section.key)) {
						fallback[section.key] = section.value || '';
					}
				});
				return fallback;
			}

			const items = String(description || '')
				.replace(/\r/g, '')
				.split('\n')
				.map((item) => item.replace(/^\s*[-•]\s*/, '').trim())
				.filter(Boolean);

			DESCRIPTION_FIELD_CONFIG.forEach((field, index) => {
				fallback[field.key] = items[index] || '';
			});

			return fallback;
		},
		createCampaignImageInput(file = null, existingUrl = '') {
			return {
				id: `campaign-image-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
				file,
				existingUrl,
				previewUrl: file ? URL.createObjectURL(file) : (existingUrl || ''),
			};
		},
		splitCampaignImages({ coverUrl = null, images = [] } = {}) {
			const normalizedImages = (Array.isArray(images) ? images : [])
				.map((url) => (typeof url === 'string' ? url.trim() : ''))
				.filter(Boolean);
			const normalizedCoverUrl = typeof coverUrl === 'string' ? coverUrl.trim() : '';
			const coverImage = normalizedCoverUrl || normalizedImages[0] || null;
			const remainingImages = [...normalizedImages];
			if (coverImage) {
				const coverIndex = remainingImages.findIndex((url) => url === coverImage);
				if (coverIndex >= 0) {
					remainingImages.splice(coverIndex, 1);
				}
			}
			const detailImages = remainingImages.filter(Boolean);
			const allImages = [coverImage, ...detailImages].filter(Boolean);
			return { coverImage, detailImages, allImages };
		},
		createCampaignImageInputs(count = 3) {
			return Array.from({ length: count }, () => this.createCampaignImageInput());
		},
		createCampaignImageInputsFromUrls(urls = [], minCount = 3) {
			const inputs = (Array.isArray(urls) ? urls : [])
				.filter(Boolean)
				.map((url) => this.createCampaignImageInput(null, url));
			while (inputs.length < minCount) {
				inputs.push(this.createCampaignImageInput());
			}
			return inputs;
		},
		revokeCampaignImageUrl(url) {
			if (typeof url === 'string' && url.startsWith('blob:')) {
				URL.revokeObjectURL(url);
			}
		},
		releaseCampaignImageObjectUrls() {
			this.revokeCampaignImageUrl(this.formData?.coverPreviewUrl);
			(this.formData?.detailImageInputs || []).forEach((input) => this.revokeCampaignImageUrl(input.previewUrl));
		},
		ensureDetailImageInputs(minCount = 3) {
			if (!Array.isArray(this.formData.detailImageInputs)) {
				this.formData.detailImageInputs = [];
			}
			while (this.formData.detailImageInputs.length < minCount) {
				this.formData.detailImageInputs.push(this.createCampaignImageInput());
			}
		},
		getTotalDetailImageCount() {
			return (this.formData.detailImageInputs || []).filter((item) => item.file || item.existingUrl).length;
		},
		onCoverImageChange(e) {
			const file = Array.from(e.target.files || [])[0] || null;
			if (file && !file.type.startsWith('image/')) {
				this.formErrors.coverImage = 'Vui lòng chọn tệp hình ảnh hợp lệ.';
				e.target.value = '';
				return;
			}

			this.revokeCampaignImageUrl(this.formData.coverPreviewUrl);
			this.formData.coverImageFile = file;
			this.formData.coverPreviewUrl = file ? URL.createObjectURL(file) : '';
			this.syncCampaignImageState();
			this.formErrors.coverImage = '';
			e.target.value = '';
		},
		removeCoverImage() {
			this.revokeCampaignImageUrl(this.formData.coverPreviewUrl);
			const hadNewCover = Boolean(this.formData.coverImageFile);
			this.formData.coverImageFile = null;
			this.formData.coverPreviewUrl = '';
			if (!hadNewCover) {
				this.formData.existingCoverImage = null;
			}
			this.syncCampaignImageState();
		},
		addDetailImageInput() {
			this.ensureDetailImageInputs();
			this.formData.detailImageInputs.push(this.createCampaignImageInput());
		},
		onDetailImagesChange(e, inputId) {
			const file = Array.from(e.target.files || [])[0] || null;
			const targetInput = (this.formData.detailImageInputs || []).find((item) => item.id === inputId);
			if (!targetInput) return;
			if (file && !file.type.startsWith('image/')) {
				this.formErrors.detailImages = 'Vui lòng chọn tệp hình ảnh hợp lệ.';
				e.target.value = '';
				return;
			}

			this.revokeCampaignImageUrl(targetInput.previewUrl);
			targetInput.file = file;
			targetInput.existingUrl = '';
			targetInput.previewUrl = file ? URL.createObjectURL(file) : '';
			this.syncCampaignImageState();
			this.formErrors.detailImages = '';
			e.target.value = '';
		},
		removeDetailImageInput(inputId) {
			const removedInput = (this.formData.detailImageInputs || []).find((item) => item.id === inputId);
			if (removedInput) {
				this.revokeCampaignImageUrl(removedInput.previewUrl);
			}
			this.formData.detailImageInputs = (this.formData.detailImageInputs || []).filter((item) => item.id !== inputId);
			this.ensureDetailImageInputs();
			this.syncCampaignImageState();
		},
		syncCampaignImageState() {
			this.ensureDetailImageInputs();
			this.formData.detailImages = (this.formData.detailImageInputs || [])
				.map((item) => item.file)
				.filter(Boolean);
			this.formData.existingDetailImages = (this.formData.detailImageInputs || [])
				.map((item) => item.existingUrl)
				.filter(Boolean);
			this.formData.coverPreviewImage = this.formData.coverImageFile
				? {
					key: `new-cover-${this.formData.coverImageFile.name}-${this.formData.coverImageFile.size}`,
					type: 'new-cover',
					url: this.formData.coverPreviewUrl,
					file: this.formData.coverImageFile,
				}
				: (this.formData.existingCoverImage
					? {
						key: `existing-cover-${this.formData.existingCoverImage}`,
						type: 'existing-cover',
						url: this.formData.existingCoverImage,
					}
					: null);

			const existingDetailImages = (this.formData.existingDetailImages || []).map((url, index) => ({
				key: `existing-detail-${index}-${url}`,
				type: 'existing-detail',
				url,
			}));
			const newDetailImages = (this.formData.detailImageInputs || [])
				.filter((item) => item.file && item.previewUrl)
				.map((item, index) => ({
					key: `new-detail-${index}-${item.file.name}-${item.file.size}`,
					type: 'new-detail',
					url: item.previewUrl,
					file: item.file,
				}));
			this.formData.detailPreviewImages = [...existingDetailImages, ...newDetailImages];
			this.formData.coverUrl = this.formData.coverPreviewImage?.url || null;
			this.formData.images = [
				this.formData.coverPreviewImage?.url,
				...this.formData.detailPreviewImages.map((item) => item.url),
			].filter(Boolean);
		},
		removeDetailImage(image) {
			if (image.type === 'existing-detail') {
				this.formData.existingDetailImages = this.formData.existingDetailImages.filter((url) => url !== image.url);
			} else {
				const removedInput = (this.formData.detailImageInputs || []).find((item) => item.file === image.file || item.previewUrl === image.url);
				if (removedInput) {
					this.revokeCampaignImageUrl(removedInput.previewUrl);
				}
				this.formData.detailImageInputs = (this.formData.detailImageInputs || []).filter((item) => item.file !== image.file && item.previewUrl !== image.url);
				this.ensureDetailImageInputs();
			}
			this.syncCampaignImageState();
		},
		validateCampaignForm() {
			const errors = {};
			const today = new Date();
			today.setHours(0, 0, 0, 0);
			const startDate = this.formData.startDate ? new Date(this.formData.startDate) : null;
			const endDate = this.formData.endDate ? new Date(this.formData.endDate) : null;
			const descriptionPayload = this.buildDescriptionPayload();

			if (!this.formData.title?.trim()) errors.title = 'Vui lòng nhập tên chiến dịch.';
			else if (this.formData.title.trim().length < 5) errors.title = 'Tên chiến dịch phải có ít nhất 5 ký tự.';

			if (!descriptionPayload.trim()) {
				errors.description = 'Vui lòng hoàn thiện phần mô tả chiến dịch.';
			} else if (descriptionPayload.replace(/\s/g, '').length < 60) {
				errors.description = 'Mô tả hoàn chỉnh còn quá ngắn, vui lòng nhập đầy đủ hơn.';
			}

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

			if (!this.formData.coverPreviewImage) errors.coverImage = 'Vui lòng chọn ảnh bìa cho chiến dịch.';
			if (this.getTotalDetailImageCount() < 3) errors.detailImages = 'Vui lòng chọn tối thiểu 3 ảnh mô tả chiến dịch.';

			this.formErrors = errors;
			this.formData.description = descriptionPayload;
			return Object.keys(errors).length === 0;
		},
		async saveCampaign() {
			if (this.isSaving) return;
			if (!this.validateCampaignForm()) {
				if (this.toast) this.toast.showToast('error', 'Lỗi', this.$t('coordinator.fillAllFields'));
				else alert(this.$t('coordinator.fillAllFields'));
				return;
			}
			this.isSaving = true;

			const payload = new FormData();
			this.syncDescriptionValue();
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
			const existingImages = [
				...(this.formData.coverImageFile ? [] : (this.formData.existingCoverImage ? [this.formData.existingCoverImage] : [])),
				...(this.formData.existingDetailImages || []),
			];
			existingImages.forEach((url, index) => payload.append(`danh_sach_anh_hien_tai[${index}]`, url));
			if (this.formData.coverImageFile) {
				payload.append('anh_bia', this.formData.coverImageFile);
			}
			(this.formData.detailImages || []).forEach((file, index) => payload.append(`anh_phu[${index}]`, file));

			try {
				let res = null;
				if (this.isEditing) {
					payload.append('_method', 'PUT');
					res = await api.post(`/tinh-nguyen-vien/chien-dich/${this.formData.id}`, payload, {
						headers: { 'Content-Type': 'multipart/form-data' }
					});
				} else {
					res = await api.post('/tinh-nguyen-vien/chien-dich', payload, {
						headers: { 'Content-Type': 'multipart/form-data' }
					});
				}

				if (res?.data?.status !== 1) {
					throw new Error(res?.data?.message || 'Có lỗi xảy ra.');
				}

				if (this.toast) this.toast.showToast('success', 'Thành công!', res.data.message || this.$t('common.success'));
				if (!this.isEditing) this.resetForm();
				bootstrap.Modal.getOrCreateInstance(this.$refs.campaignModal)?.hide();
				await this.loadCampaigns();
			} catch (err) {
				const msg = err.response?.data?.message || err.message || 'Có lỗi xảy ra.';
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
.campaign-modal-2xl {
	max-width: min(1480px, calc(100vw - 2rem));
}

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

.pending-cancel-badge {
	background-color: #fd7e14 !important;
}

.upload-media-card {
	border: 1px solid rgba(15, 23, 42, 0.12);
	border-radius: 0.5rem;
	background: #fff;
	overflow: hidden;
	box-shadow: 0 10px 24px rgba(15, 23, 42, 0.05);
}

.upload-media-card.is-invalid {
	border-color: #dc3545;
}

.upload-media-preview {
	position: relative;
	height: 190px;
	background: linear-gradient(135deg, #f8fafc, #e2e8f0);
}

.upload-media-image {
	width: 100%;
	height: 100%;
	object-fit: cover;
	display: block;
}

.upload-media-placeholder {
	height: 100%;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	gap: 0.5rem;
	color: #64748b;
	font-size: 0.92rem;
	font-weight: 500;
	text-align: center;
	padding: 1rem;
}

.upload-media-placeholder i {
	font-size: 2rem;
	color: #94a3b8;
}

.upload-media-body {
	padding: 0.9rem;
}

.upload-media-body .form-control,
.upload-media-body .btn {
	border-radius: 0.375rem;
}

@media (max-width: 767.98px) {
	.upload-media-preview {
		height: 170px;
	}
}

.nav-tabs-custom .nav-link { border: none; border-bottom: 3px solid transparent; border-radius: 0; font-size: 13px; }
.nav-tabs-custom .nav-link.active { border-bottom-color: #0d6efd; background: transparent; }
.nav-tabs-custom .nav-link:hover:not(.active) { border-bottom-color: #dee2e6; }

.campaign-map-wrapper {
	height: 250px;
	width: 100%;
	z-index: 0;
}

.location-suggestions-dropdown {
	position: absolute;
	top: calc(100% + 0.35rem);
	left: 0;
	right: 0;
	z-index: 12;
	background: #fff;
	border: 1px solid rgba(15, 23, 42, 0.08);
	border-radius: 0.9rem;
	max-height: 280px;
	overflow-y: auto;
}

.location-suggestion-item {
	padding: 0.75rem 0.9rem;
	border-bottom: 1px solid rgba(15, 23, 42, 0.06);
	cursor: pointer;
	transition: background-color 0.15s ease;
}

.location-suggestion-item:last-child {
	border-bottom: none;
}

.location-suggestion-item:hover,
.location-suggestion-item.active {
	background: rgba(13, 110, 253, 0.08);
}

.location-suggestion-source {
	background: rgba(13, 110, 253, 0.1);
	color: #0d6efd;
	font-size: 11px;
	font-weight: 600;
	flex-shrink: 0;
}

.location-suggestion-empty {
	padding: 0.9rem;
	font-size: 13px;
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
