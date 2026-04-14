<template>
	<div>
		<PageHeader
			:title="$t('coordinationScreen.title')"
			icon="fa-solid fa-people-arrows"
			:breadcrumbs="[
				{ label: $t('common.home'), to: '/' },
				{ label: $t('coordinator.campaignManagement'), to: '/quan-ly-chien-dich' },
				{ label: $t('coordinationScreen.title') }
			]">
			<template #actions>
				<router-link to="/quan-ly-chien-dich" class="btn btn-outline-secondary btn-sm">
					<i class="fa-solid fa-arrow-left me-1"></i>{{ $t('coordinationScreen.backToCampaigns') }}
				</router-link>
			</template>
		</PageHeader>

		<StatCards :cards="statCards" />

		<div class="card border-0 shadow-sm mb-4">
			<div class="card-body">
				<div class="row g-3 align-items-end">
					<div class="col-lg-8">
						<label class="form-label fw-semibold small">{{ $t('coordinationScreen.selectCampaignLabel') }}</label>
						<select class="form-select" v-model="selectedCampaignId">
							<option value="">{{ $t('coordinationScreen.selectCampaignPlaceholder') }}</option>
							<option v-for="campaign in campaigns" :key="campaign.id" :value="String(campaign.id)">
								{{ campaign.title }} - {{ campaign.location }}
							</option>
						</select>
					</div>
					<div class="col-lg-4 d-flex gap-2">
						<button class="btn btn-primary flex-grow-1" :disabled="!selectedCampaignId || isLoadingRecommendations" @click="loadCoordinationData">
							<i class="fa-solid fa-wand-magic-sparkles me-1"></i>{{ $t('coordinationScreen.loadSuggestions') }}
						</button>
						<button class="btn btn-outline-secondary" :disabled="!selectedCampaignId" @click="goToCampaignDetail">
							<i class="fa-regular fa-eye me-1"></i>{{ $t('coordinationScreen.detailBtn') }}
						</button>
					</div>
				</div>

				<div v-if="activeCampaign" class="coordination-summary mt-3">
					<div class="row g-3">
						<div class="col-md-6 col-lg-3">
							<div class="summary-card">
								<div class="summary-label">{{ $t('coordinationScreen.summaryCampaign') }}</div>
								<div class="summary-value text-truncate">{{ activeCampaign.title }}</div>
							</div>
						</div>
						<div class="col-md-6 col-lg-3">
							<div class="summary-card">
								<div class="summary-label">{{ $t('coordinationScreen.summaryLocation') }}</div>
								<div class="summary-value text-truncate">{{ activeCampaign.location }}</div>
							</div>
						</div>
						<div class="col-md-6 col-lg-3">
							<div class="summary-card">
								<div class="summary-label">{{ $t('coordinationScreen.summaryMinNeed') }}</div>
								<div class="summary-value">{{ activeCampaign.minVolunteers }}</div>
							</div>
						</div>
						<div class="col-md-6 col-lg-3">
							<div class="summary-card">
								<div class="summary-label">{{ $t('coordinationScreen.summaryRegistered') }}</div>
								<div class="summary-value">{{ activeCampaign.registered }}/{{ activeCampaign.maxVolunteers }}</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<div v-if="!selectedCampaignId" class="card border-0 shadow-sm">
			<div class="card-body text-center py-5 text-muted">
				<i class="fa-solid fa-people-arrows fs-1 d-block mb-3 opacity-25"></i>
				{{ $t('coordinationScreen.emptyState') }}
			</div>
		</div>

		<template v-else>
			<div v-if="isLoadingRecommendations" class="card border-0 shadow-sm mb-4">
				<div class="card-body text-center py-5">
					<div class="spinner-border text-primary mb-3" role="status"></div>
					<div class="text-muted">{{ $t('coordinationScreen.loading') }}</div>
				</div>
			</div>

			<template v-else>
				<div class="card border-0 shadow-sm mb-4">
					<div class="card-header bg-white border-bottom px-4 py-3 d-flex align-items-center justify-content-between">
						<div>
							<h6 class="fw-bold mb-1"><i class="fa-solid fa-layer-group me-2 text-success"></i>{{ $t('coordinationScreen.allocationTitle') }}</h6>
							<div class="text-muted small">{{ $t('coordinationScreen.allocationDesc') }}</div>
						</div>
						<div class="d-flex gap-2">
							<button class="btn btn-outline-primary btn-sm" :disabled="!canManageCoordination || inviteLoading || selectedInviteIds.length === 0" @click="inviteSelectedVolunteers">
								<i class="fa-solid fa-envelope me-1"></i>{{ $t('coordinationScreen.sendSelectedEmails', { count: selectedInviteIds.length }) }}
							</button>
							<button class="btn btn-success btn-sm" :disabled="!canManageCoordination || inviteLoading || allocationPrimary.length === 0" @click="invitePrimaryGroup">
								<i class="fa-solid fa-paper-plane me-1"></i>{{ $t('coordinationScreen.inviteTop') }}
							</button>
						</div>
					</div>
					<div class="card-body p-4">
						<div class="row g-3 mb-4">
							<div class="col-md-3 col-6">
								<div class="summary-card">
									<div class="summary-label">{{ $t('coordinationScreen.minLabel') }}</div>
									<div class="summary-value">{{ allocationSummary.so_luong_toi_thieu || 0 }}</div>
								</div>
							</div>
							<div class="col-md-3 col-6">
								<div class="summary-card">
									<div class="summary-label">{{ $t('coordinationScreen.maxLabel') }}</div>
									<div class="summary-value">{{ allocationSummary.so_luong_toi_da || 0 }}</div>
								</div>
							</div>
							<div class="col-md-3 col-6">
								<div class="summary-card">
									<div class="summary-label">{{ $t('coordinationScreen.confirmedLabel') }}</div>
									<div class="summary-value">{{ allocationSummary.so_xac_nhan_hien_tai || 0 }}</div>
								</div>
							</div>
							<div class="col-md-3 col-6">
								<div class="summary-card">
									<div class="summary-label">{{ $t('coordinationScreen.qualifiedLabel') }}</div>
									<div class="summary-value">{{ allocationSummary.so_tnv_du_chuan || 0 }}</div>
								</div>
							</div>
						</div>

						<div v-if="allocationRisks.length > 0" class="d-flex flex-column gap-2 mb-4">
							<div v-for="risk in allocationRisks" :key="risk.code" class="alert alert-warning border-0 mb-0">
								<i class="fa-solid fa-triangle-exclamation me-2"></i>{{ risk.message }}
							</div>
						</div>

						<div class="row g-4">
							<div class="col-12">
								<div class="border rounded-4 p-3 h-100">
									<div class="d-flex align-items-center justify-content-between mb-3">
										<div class="d-flex align-items-center gap-3">
											<h6 class="fw-bold mb-0">{{ $t('coordinationScreen.primaryGroup') }}</h6>
											<div v-if="allocationPrimary.length" class="form-check mb-0 small">
												<input
													:id="'select-primary-all'"
													class="form-check-input"
													type="checkbox"
													:checked="isGroupFullySelected(allocationPrimary)"
													@change="toggleGroupSelection(allocationPrimary, $event.target.checked)">
												<label class="form-check-label" :for="'select-primary-all'">{{ $t('coordinationScreen.selectAll') }}</label>
											</div>
										</div>
										<span class="badge bg-success text-white rounded-pill">{{ allocationPrimary.length }}</span>
									</div>
									<div class="small text-muted mb-3">{{ $t('coordinationScreen.primaryDesc') }}</div>
									<div v-if="allocationPrimary.length === 0" class="small text-muted">{{ $t('coordinationScreen.noPrimary') }}</div>
										<div v-else class="d-flex flex-column gap-2">
											<div v-for="volunteer in paginatedAllocationPrimary" :key="'primary-' + volunteer.id" class="list-row-card list-row-card-primary">
												<div class="form-check flex-shrink-0 mb-0">
													<input
														:id="'primary-select-' + volunteer.id"
														class="form-check-input"
														type="checkbox"
														:checked="isVolunteerSelected(volunteer.id)"
														@change="toggleVolunteerSelection(volunteer.id, $event.target.checked)">
												</div>
												<div class="list-row-main min-w-0">
													<div class="list-row-inline">
														<div class="fw-semibold text-dark text-truncate">{{ volunteer.name }}</div>
														<span class="list-row-score">{{ volunteer.finalScore }}%</span>
														<span v-if="volunteer.registrationStatusLabel" class="badge rounded-pill border text-dark bg-light">{{ volunteer.registrationStatusLabel }}</span>
														<div class="small text-muted compact-meta">
															{{ getVolunteerListMeta(volunteer) }}
														</div>
													</div>
												</div>
												<div class="d-flex gap-2 flex-shrink-0">
													<button class="btn btn-sm btn-light border rounded-pill px-3" @click="openVolunteerDetail(volunteer, $t('coordinationScreen.primaryGroup'))">{{ $t('coordinationScreen.viewDetail') }}</button>
													<button class="btn btn-sm btn-outline-primary rounded-pill px-3" :disabled="!canManageCoordination || inviteLoading || !canInviteVolunteer(volunteer)" @click="inviteVolunteers([volunteer.id])">{{ getInviteButtonLabel(volunteer) }}</button>
											</div>
										</div>
										<div class="mt-2">
											<div class="small text-muted mb-2">{{ $t('coordinationScreen.showingGroupCount', { showing: paginatedAllocationPrimary.length, total: allocationPrimary.length }) }}</div>
											<div class="d-flex justify-content-end">
												<nav v-if="totalPrimaryPages > 1">
													<ul class="pagination pagination-sm mb-0">
														<li class="page-item" :class="{ disabled: primaryPage === 1 }">
															<button class="page-link" @click="changePage('primaryPage', primaryPage - 1, totalPrimaryPages)">{{ $t('pagination.prev') }}</button>
														</li>
														<li
															v-for="page in getVisiblePages(primaryPage, totalPrimaryPages)"
															:key="'primary-page-' + page"
															class="page-item"
															:class="{ active: primaryPage === page, disabled: page === '...' }">
															<button class="page-link" :disabled="page === '...'" @click="typeof page === 'number' && changePage('primaryPage', page, totalPrimaryPages)">{{ page }}</button>
														</li>
														<li class="page-item" :class="{ disabled: primaryPage === totalPrimaryPages }">
															<button class="page-link" @click="changePage('primaryPage', primaryPage + 1, totalPrimaryPages)">{{ $t('pagination.next') }}</button>
														</li>
													</ul>
												</nav>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>

							<div v-if="excludedVolunteers.length > 0" class="border rounded-4 p-3 bg-light mt-4">
							<div class="d-flex align-items-center justify-content-between mb-3">
								<div class="d-flex align-items-center gap-3">
									<div>
										<div class="fw-semibold">{{ $t('coordinationScreen.excludedGroup') }}</div>
										<div class="small text-muted">{{ $t('coordinationScreen.excludedDesc') }}</div>
									</div>
									<div v-if="excludedVolunteers.length" class="form-check mb-0 small">
										<input
											:id="'select-excluded-all'"
											class="form-check-input"
											type="checkbox"
											:checked="isGroupFullySelected(excludedVolunteers)"
											@change="toggleGroupSelection(excludedVolunteers, $event.target.checked)">
										<label class="form-check-label" :for="'select-excluded-all'">{{ $t('coordinationScreen.selectAll') }}</label>
									</div>
								</div>
								<span class="badge bg-secondary text-white rounded-pill">{{ filteredExcludedVolunteers.length }}</span>
							</div>
							<div class="mb-3">
								<label class="form-label fw-semibold small">{{ $t('coordinationScreen.searchExcludedVolunteerLabel') }}</label>
								<div class="input-group">
									<span class="input-group-text bg-white border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
									<input
										v-model.trim="excludedVolunteerSearchQuery"
										type="text"
										class="form-control border-start-0"
										:placeholder="$t('coordinationScreen.searchExcludedVolunteerPlaceholder')">
								</div>
							</div>
								<div v-for="item in paginatedExcludedVolunteers" :key="'excluded-' + item.id" class="list-row-card list-row-card-excluded">
									<div class="form-check flex-shrink-0 mb-0">
										<input
											:id="'excluded-select-' + item.id"
											class="form-check-input"
											type="checkbox"
											:checked="isVolunteerSelected(item.id)"
											@change="toggleVolunteerSelection(item.id, $event.target.checked)">
									</div>
									<div class="list-row-main min-w-0">
										<div class="list-row-inline">
											<div class="fw-semibold text-dark text-truncate">{{ item.ho_ten }}</div>
											<span class="list-row-score">{{ Math.round(item.final_score || 0) }}%</span>
											<span v-if="getRegistrationStatusLabel(item.registration_status)" class="badge rounded-pill border text-dark bg-light">{{ getRegistrationStatusLabel(item.registration_status) }}</span>
											<div class="small text-muted compact-meta">{{ getVolunteerListMeta(mapExcludedVolunteerForUi(item)) }}</div>
										</div>
									</div>
										<div class="d-flex gap-2 flex-shrink-0">
											<button class="btn btn-sm btn-light border rounded-pill px-3" @click="openVolunteerDetail(mapExcludedVolunteerForUi(item), $t('coordinationScreen.excludedGroup'))">{{ $t('coordinationScreen.viewDetail') }}</button>
											<button class="btn btn-sm btn-primary rounded-pill px-3" :disabled="!canManageCoordination || inviteLoading || !canInviteVolunteer(item)" @click="inviteVolunteers([item.id])">
												{{ getInviteButtonLabel(item) }}
											</button>
										</div>
									</div>
							<div class="mt-2">
								<div class="small text-muted mb-2">{{ $t('coordinationScreen.showingGroupCount', { showing: paginatedExcludedVolunteers.length, total: filteredExcludedVolunteers.length }) }}</div>
								<div class="d-flex justify-content-end">
									<nav v-if="totalExcludedPages > 1">
										<ul class="pagination pagination-sm mb-0">
											<li class="page-item" :class="{ disabled: excludedPage === 1 }">
												<button class="page-link" @click="changePage('excludedPage', excludedPage - 1, totalExcludedPages)">{{ $t('pagination.prev') }}</button>
											</li>
											<li
												v-for="page in getVisiblePages(excludedPage, totalExcludedPages)"
												:key="'excluded-page-' + page"
												class="page-item"
												:class="{ active: excludedPage === page, disabled: page === '...' }">
												<button class="page-link" :disabled="page === '...'" @click="typeof page === 'number' && changePage('excludedPage', page, totalExcludedPages)">{{ page }}</button>
											</li>
											<li class="page-item" :class="{ disabled: excludedPage === totalExcludedPages }">
												<button class="page-link" @click="changePage('excludedPage', excludedPage + 1, totalExcludedPages)">{{ $t('pagination.next') }}</button>
											</li>
										</ul>
									</nav>
								</div>
							</div>
						</div>
					</div>
				</div>

				<div class="card border-0 shadow-sm">
						<div class="card-header bg-white border-bottom px-4 py-3 d-flex align-items-center justify-content-between">
						<div>
							<h6 class="fw-bold mb-1"><i class="fa-solid fa-user-check me-2 text-primary"></i>{{ $t('coordinationScreen.recommendedVolunteers') }}</h6>
							<div class="text-muted small">{{ $t('coordinationScreen.recommendedDesc') }}</div>
						</div>
						<div class="d-flex align-items-center gap-3">
							<div v-if="displayedRecommendedVolunteers.length" class="form-check mb-0 small">
								<input
									:id="'select-recommend-all'"
									class="form-check-input"
									type="checkbox"
									:checked="isGroupFullySelected(displayedRecommendedVolunteers)"
									@change="toggleGroupSelection(displayedRecommendedVolunteers, $event.target.checked)">
								<label class="form-check-label" :for="'select-recommend-all'">{{ $t('coordinationScreen.selectAll') }}</label>
							</div>
							<span class="badge bg-primary text-white rounded-pill">{{ displayedRecommendedVolunteers.length }}</span>
						</div>
					</div>
					<div class="card-body p-4">
						<div v-if="displayedRecommendedVolunteers.length === 0" class="text-center py-4 text-muted">
							<i class="fa-solid fa-user-slash d-block fs-3 mb-2 opacity-25"></i>
							{{ $t('coordinationScreen.noRecommendedVolunteers') }}
						</div>
							<div v-else class="d-flex flex-column gap-3">
								<div v-for="volunteer in paginatedRecommendedVolunteers" :key="'suggest-' + volunteer.id" class="list-row-card list-row-card-recommendation">
									<div class="form-check flex-shrink-0 mb-0">
										<input
											:id="'recommend-select-' + volunteer.id"
											class="form-check-input"
											type="checkbox"
											:checked="isVolunteerSelected(volunteer.id)"
											@change="toggleVolunteerSelection(volunteer.id, $event.target.checked)">
									</div>
									<div class="list-row-main min-w-0">
										<div class="list-row-inline">
											<div class="fw-semibold text-dark text-truncate">{{ volunteer.name }}</div>
											<span class="list-row-score">{{ volunteer.finalScore }}%</span>
											<span v-if="volunteer.registrationStatusLabel" class="badge rounded-pill border text-dark bg-light">{{ volunteer.registrationStatusLabel }}</span>
											<div class="small text-muted compact-meta">{{ getVolunteerListMeta(volunteer) }}</div>
										</div>
									</div>
									<div class="d-flex gap-2 flex-shrink-0">
										<button class="btn btn-outline-secondary btn-sm rounded-pill px-3" @click="openVolunteerDetail(volunteer, $t('coordinationScreen.recommendedVolunteers'))">
										{{ $t('coordinationScreen.viewDetail') }}
									</button>
									<button class="btn btn-primary btn-sm rounded-pill px-3" :disabled="!canManageCoordination || inviteLoading || !canInviteVolunteer(volunteer)" @click="inviteVolunteers([volunteer.id])">
										{{ getInviteButtonLabel(volunteer) }}
									</button>
								</div>
							</div>
							<div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-2">
								<div class="small text-muted">{{ $t('coordinationScreen.showingRecommendedCount', { showing: paginatedRecommendedVolunteers.length, total: displayedRecommendedVolunteers.length }) }}</div>
								<nav v-if="totalRecommendationPages > 1">
									<ul class="pagination pagination-sm mb-0">
										<li class="page-item" :class="{ disabled: recommendationPage === 1 }">
											<button class="page-link" @click="changePage('recommendationPage', recommendationPage - 1, totalRecommendationPages)">{{ $t('pagination.prev') }}</button>
										</li>
										<li
											v-for="page in getVisiblePages(recommendationPage, totalRecommendationPages)"
											:key="'recommend-page-' + page"
											class="page-item"
											:class="{ active: recommendationPage === page, disabled: page === '...' }">
											<button class="page-link" :disabled="page === '...'" @click="typeof page === 'number' && changePage('recommendationPage', page, totalRecommendationPages)">{{ page }}</button>
										</li>
										<li class="page-item" :class="{ disabled: recommendationPage === totalRecommendationPages }">
											<button class="page-link" @click="changePage('recommendationPage', recommendationPage + 1, totalRecommendationPages)">{{ $t('pagination.next') }}</button>
										</li>
									</ul>
								</nav>
							</div>
						</div>
					</div>
				</div>

				<div class="card border-0 shadow-sm mt-4">
					<div class="card-header bg-white border-bottom px-4 py-3 d-flex align-items-center justify-content-between">
						<div>
							<h6 class="fw-bold mb-1"><i class="fa-solid fa-map-location-dot me-2 text-warning"></i>{{ $t('coordinationScreen.remoteAreaTitle') }}</h6>
							<div class="text-muted small">{{ $t('coordinationScreen.remoteAreaDesc') }}</div>
						</div>
						<div class="d-flex align-items-center gap-3">
							<div v-if="remoteAreaVolunteers.length" class="form-check mb-0 small">
								<input
									:id="'select-remote-area-all'"
									class="form-check-input"
									type="checkbox"
									:checked="isGroupFullySelected(remoteAreaVolunteers)"
									@change="toggleGroupSelection(remoteAreaVolunteers, $event.target.checked)">
								<label class="form-check-label" :for="'select-remote-area-all'">{{ $t('coordinationScreen.selectAll') }}</label>
							</div>
							<span class="badge bg-warning text-dark rounded-pill">{{ remoteAreaVolunteers.length }}</span>
						</div>
					</div>
					<div class="card-body p-4">
						<div v-if="remoteAreaVolunteers.length === 0" class="text-center py-4 text-muted">
							<i class="fa-solid fa-route d-block fs-3 mb-2 opacity-25"></i>
							{{ $t('coordinationScreen.noRemoteArea') }}
						</div>
						<div v-else class="d-flex flex-column gap-3">
							<div v-for="volunteer in paginatedRemoteAreaVolunteers" :key="'remote-area-' + volunteer.id" class="list-row-card list-row-card-remote-area">
								<div class="form-check flex-shrink-0 mb-0">
									<input
										:id="'remote-area-select-' + volunteer.id"
										class="form-check-input"
										type="checkbox"
										:checked="isVolunteerSelected(volunteer.id)"
										@change="toggleVolunteerSelection(volunteer.id, $event.target.checked)">
								</div>
								<div class="list-row-main min-w-0">
									<div class="list-row-inline">
										<div class="fw-semibold text-dark text-truncate">{{ volunteer.name }}</div>
										<span class="badge rounded-pill border border-warning text-warning-emphasis bg-warning-subtle">{{ $t('coordinationScreen.remoteAreaBadge') }}</span>
										<span v-if="volunteer.registrationStatusLabel" class="badge rounded-pill border text-dark bg-light">{{ volunteer.registrationStatusLabel }}</span>
										<div class="small text-muted compact-meta">{{ getVolunteerListMeta(volunteer) }}</div>
									</div>
								</div>
								<div class="d-flex gap-2 flex-shrink-0">
									<button class="btn btn-outline-secondary btn-sm rounded-pill px-3" @click="openVolunteerDetail(volunteer, $t('coordinationScreen.remoteAreaTitle'))">{{ $t('coordinationScreen.viewDetail') }}</button>
									<button class="btn btn-primary btn-sm rounded-pill px-3" :disabled="!canManageCoordination || inviteLoading || !canInviteVolunteer(volunteer)" @click="inviteVolunteers([volunteer.id])">
										{{ getInviteButtonLabel(volunteer) }}
									</button>
								</div>
							</div>
							<div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-2">
								<div class="small text-muted">{{ $t('coordinationScreen.showingGroupCount', { showing: paginatedRemoteAreaVolunteers.length, total: remoteAreaVolunteers.length }) }}</div>
								<nav v-if="totalRemoteAreaPages > 1">
									<ul class="pagination pagination-sm mb-0">
										<li class="page-item" :class="{ disabled: remoteAreaPage === 1 }">
											<button class="page-link" @click="changePage('remoteAreaPage', remoteAreaPage - 1, totalRemoteAreaPages)">{{ $t('pagination.prev') }}</button>
										</li>
										<li v-for="page in getVisiblePages(remoteAreaPage, totalRemoteAreaPages)" :key="'remote-area-page-' + page" class="page-item" :class="{ active: remoteAreaPage === page, disabled: page === '...' }">
											<button class="page-link" :disabled="page === '...'" @click="typeof page === 'number' && changePage('remoteAreaPage', page, totalRemoteAreaPages)">{{ page }}</button>
										</li>
										<li class="page-item" :class="{ disabled: remoteAreaPage === totalRemoteAreaPages }">
											<button class="page-link" @click="changePage('remoteAreaPage', remoteAreaPage + 1, totalRemoteAreaPages)">{{ $t('pagination.next') }}</button>
										</li>
									</ul>
								</nav>
							</div>
						</div>
					</div>
				</div>

				<div class="card border-0 shadow-sm mt-4">
					<div class="card-header bg-white border-bottom px-4 py-3 d-flex align-items-center justify-content-between">
						<div>
							<h6 class="fw-bold mb-1"><i class="fa-solid fa-ranking-star me-2 text-warning"></i>{{ $t('coordinationScreen.profileHighlightTitle') }}</h6>
							<div class="text-muted small">{{ $t('coordinationScreen.profileHighlightDesc') }}</div>
						</div>
						<button class="btn btn-outline-secondary btn-sm rounded-pill px-3" @click="toggleProfileSort">
							<i class="fa-solid fa-arrow-up-wide-short me-1"></i>{{ profileSortLabel }}
						</button>
					</div>
					<div class="card-body p-4">
						<div v-if="sortedProfileHighlightVolunteers.length === 0" class="text-center py-4 text-muted">
							<i class="fa-solid fa-chart-line d-block fs-3 mb-2 opacity-25"></i>
							{{ $t('coordinationScreen.noProfileHighlights') }}
						</div>
						<div v-else class="d-flex flex-column gap-3">
							<div v-for="volunteer in paginatedProfileHighlightVolunteers" :key="'profile-' + volunteer.id" class="list-row-card">
								<div class="list-row-main min-w-0">
									<div class="list-row-inline">
										<div class="fw-semibold text-dark text-truncate">{{ volunteer.name }}</div>
										<span class="list-row-score">{{ volunteer.breakdown.profileStrength }}%</span>
										<div class="small text-muted compact-meta">
											{{ $t('coordinationScreen.profileStrengthMeta', { experience: volunteer.experienceCount, certificates: volunteer.certificateCount }) }}
										</div>
									</div>
								</div>
								<div class="d-flex gap-2 flex-shrink-0">
									<button class="btn btn-outline-secondary btn-sm rounded-pill px-3" @click="openVolunteerDetail(volunteer, $t('coordinationScreen.profileHighlightTitle'))">{{ $t('coordinationScreen.viewDetail') }}</button>
									<button class="btn btn-primary btn-sm rounded-pill px-3" :disabled="!canManageCoordination || inviteLoading || !canInviteVolunteer(volunteer)" @click="inviteVolunteers([volunteer.id])">
										{{ getInviteButtonLabel(volunteer) }}
									</button>
								</div>
							</div>
							<div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-2">
								<div class="small text-muted">{{ $t('coordinationScreen.showingGroupCount', { showing: paginatedProfileHighlightVolunteers.length, total: sortedProfileHighlightVolunteers.length }) }}</div>
								<nav v-if="totalProfileHighlightPages > 1">
									<ul class="pagination pagination-sm mb-0">
										<li class="page-item" :class="{ disabled: profileHighlightPage === 1 }">
											<button class="page-link" @click="changePage('profileHighlightPage', profileHighlightPage - 1, totalProfileHighlightPages)">{{ $t('pagination.prev') }}</button>
										</li>
										<li v-for="page in getVisiblePages(profileHighlightPage, totalProfileHighlightPages)" :key="'profile-page-' + page" class="page-item" :class="{ active: profileHighlightPage === page, disabled: page === '...' }">
											<button class="page-link" :disabled="page === '...'" @click="typeof page === 'number' && changePage('profileHighlightPage', page, totalProfileHighlightPages)">{{ page }}</button>
										</li>
										<li class="page-item" :class="{ disabled: profileHighlightPage === totalProfileHighlightPages }">
											<button class="page-link" @click="changePage('profileHighlightPage', profileHighlightPage + 1, totalProfileHighlightPages)">{{ $t('pagination.next') }}</button>
										</li>
									</ul>
								</nav>
							</div>
						</div>
					</div>
				</div>
			</template>
		</template>

		<div v-if="showDetailModal && selectedVolunteerDetail" class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
			<div class="modal-dialog modal-dialog-centered modal-lg">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<div>
							<div class="small text-muted">{{ selectedVolunteerContext }}</div>
							<h5 class="modal-title fw-bold mt-1">{{ selectedVolunteerDetail.name }}</h5>
						</div>
						<button type="button" class="btn-close" @click="closeVolunteerDetail"></button>
					</div>
						<div class="modal-body pt-3">
							<div class="modal-overview mb-4">
								<div class="modal-overview-title">{{ $t('coordinationScreen.detailSummary') }}</div>
								<div class="modal-overview-text">{{ selectedVolunteerDetail.decisionSummary }}</div>
							</div>

						<div class="d-flex flex-wrap gap-2 mb-3">
							<span v-if="selectedVolunteerDetail.matchLabel" class="badge rounded-pill" :class="getRecommendationBadgeClass(selectedVolunteerDetail.matchLevel)">{{ selectedVolunteerDetail.matchLabel }}</span>
							<span v-if="selectedVolunteerDetail.finalScore !== null && selectedVolunteerDetail.finalScore !== undefined" class="badge bg-dark text-white rounded-pill">{{ selectedVolunteerDetail.finalScore }}%</span>
							<span v-if="selectedVolunteerDetail.decisionTitle" class="badge bg-light text-dark border rounded-pill">{{ selectedVolunteerDetail.decisionTitle }}</span>
							<span v-if="selectedVolunteerDetail.registrationStatusLabel" class="badge bg-light text-dark border rounded-pill">{{ selectedVolunteerDetail.registrationStatusLabel }}</span>
						</div>

							<div class="small text-muted d-flex flex-wrap gap-3 mb-4">
								<span v-if="selectedVolunteerDetail.email"><i class="fa-solid fa-envelope me-1"></i>{{ selectedVolunteerDetail.email }}</span>
								<span><i class="fa-solid fa-location-dot text-danger me-1"></i>{{ selectedVolunteerDetail.areaText }}</span>
								<span v-if="selectedVolunteerDetail.distanceText"><i class="fa-solid fa-route text-success me-1"></i>{{ selectedVolunteerDetail.distanceText }}</span>
								<span><i class="fa-regular fa-calendar text-primary me-1"></i>{{ selectedVolunteerDetail.availabilityText }}</span>
								<span><i class="fa-solid fa-briefcase text-secondary me-1"></i>{{ $t('coordinationScreen.profileStrengthMeta', { experience: selectedVolunteerDetail.experienceCount, certificates: selectedVolunteerDetail.certificateCount }) }}</span>
							</div>

						<div v-if="selectedVolunteerDetail.skills?.length" class="d-flex flex-wrap gap-2 mb-4">
							<span v-for="skill in selectedVolunteerDetail.skills" :key="'detail-skill-' + skill" class="badge bg-light text-muted border">{{ skill }}</span>
						</div>

						<div v-if="selectedVolunteerDetail.breakdown" class="recommend-breakdown-grid mb-4">
							<div class="recommend-breakdown-item">
								<span>{{ $t('coordinationScreen.skillLabel') }}</span>
								<strong>{{ selectedVolunteerDetail.breakdown.skill }}%</strong>
							</div>
							<div class="recommend-breakdown-item">
								<span>{{ $t('coordinationScreen.scheduleLabel') }}</span>
								<strong>{{ selectedVolunteerDetail.breakdown.availability }}%</strong>
							</div>
							<div class="recommend-breakdown-item">
								<span>{{ $t('coordinationScreen.distanceLabel') }}</span>
								<strong>{{ selectedVolunteerDetail.breakdown.distance }}%</strong>
							</div>
							<div class="recommend-breakdown-item">
								<span>{{ $t('coordinationScreen.priorityLabel') }}</span>
								<strong>{{ selectedVolunteerDetail.breakdown.preference }}%</strong>
							</div>
								<div class="recommend-breakdown-item">
									<span>{{ $t('coordinationScreen.reliabilityLabel') }}</span>
									<strong>{{ selectedVolunteerDetail.breakdown.reliability }}%</strong>
								</div>
								<div class="recommend-breakdown-item">
									<span>{{ $t('coordinationScreen.profileStrengthLabel') }}</span>
									<strong>{{ selectedVolunteerDetail.breakdown.profileStrength }}%</strong>
								</div>
							</div>

						<div class="mb-3" v-if="selectedVolunteerDetail.reason">
							<div class="fw-semibold mb-2">{{ $t('coordinationScreen.needBeforeInvite') }}</div>
							<div class="text-muted small">{{ selectedVolunteerDetail.reason }}</div>
						</div>

						<div v-if="selectedVolunteerDetail.reasons?.length" class="mb-3">
							<div class="fw-semibold mb-2">{{ $t('coordinationScreen.reasonsTitle') }}</div>
							<div v-for="reason in selectedVolunteerDetail.reasons" :key="'detail-reason-' + reason" class="small text-muted mb-1">
								<i class="fa-solid fa-circle-check text-success me-2"></i>{{ reason }}
							</div>
						</div>

							<div v-if="selectedVolunteerDetail.warnings?.length" class="mb-1">
								<div class="fw-semibold mb-2">{{ $t('coordinationScreen.warningsTitle') }}</div>
								<div v-for="warning in selectedVolunteerDetail.warnings" :key="'detail-warning-' + warning" class="small text-warning-emphasis mb-1">
									<i class="fa-solid fa-triangle-exclamation text-warning me-2"></i>{{ warning }}
								</div>
							</div>

							<div v-if="showComparisonPanel && comparisonRows.length" class="comparison-panel mt-4">
								<div class="comparison-panel-header">
									<div>
										<div class="comparison-panel-title">{{ $t('coordinationScreen.compare.title') }}</div>
										<div class="comparison-panel-subtitle">{{ activeCampaign?.title || $t('coordinationScreen.compare.currentCampaign') }}</div>
									</div>
								</div>

								<div class="comparison-table-wrap">
									<table class="comparison-table">
										<thead>
											<tr>
												<th>{{ $t('coordinationScreen.compare.criteria') }}</th>
												<th>{{ $t('coordinationScreen.compare.campaign') }}</th>
												<th>{{ $t('coordinationScreen.compare.matchLevel') }}</th>
												<th>{{ $t('coordinationScreen.compare.volunteer') }}</th>
											</tr>
										</thead>
										<tbody>
											<tr v-for="row in comparisonRows" :key="row.label">
												<td class="comparison-cell-label">{{ row.label }}</td>
												<td class="comparison-cell-main">
													<div class="comparison-side-main">{{ row.campaign }}</div>
													<div v-if="row.campaignHelper" class="comparison-side-helper">{{ row.campaignHelper }}</div>
												</td>
												<td class="comparison-cell-status">
													<span class="comparison-badge" :class="row.statusClass">{{ row.statusLabel }}</span>
												</td>
												<td class="comparison-cell-main">
													<div class="comparison-side-main">{{ row.volunteer }}</div>
													<div v-if="row.volunteerHelper" class="comparison-side-helper">{{ row.volunteerHelper }}</div>
												</td>
											</tr>
										</tbody>
									</table>
								</div>

								<div class="comparison-detail-grid mt-3">
									<div class="comparison-detail-card">
										<div class="comparison-detail-title">{{ $t('coordinationScreen.compare.matchedSkills') }}</div>
										<div v-if="comparisonSkillSummary.noRequirement" class="small text-muted">
											{{ $t('coordinationScreen.compare.noSkillRequirement') }}
										</div>
										<div v-else-if="comparisonSkillSummary.matched.length" class="comparison-chip-wrap">
											<span
												v-for="skill in comparisonSkillSummary.matched"
												:key="'matched-skill-' + skill"
												class="comparison-chip comparison-chip-good">
												{{ skill }}
											</span>
										</div>
										<div v-else class="small text-muted">{{ $t('coordinationScreen.compare.noMatchedSkills') }}</div>
									</div>

									<div class="comparison-detail-card">
										<div class="comparison-detail-title">{{ $t('coordinationScreen.compare.missingSkills') }}</div>
										<div v-if="comparisonSkillSummary.noRequirement" class="small text-muted">
											{{ $t('coordinationScreen.compare.noMissingSkillsBecauseNoRequirement') }}
										</div>
										<div v-else-if="comparisonSkillSummary.missing.length" class="comparison-chip-wrap">
											<span
												v-for="skill in comparisonSkillSummary.missing"
												:key="'missing-skill-' + skill"
												class="comparison-chip comparison-chip-warn">
												{{ skill }}
											</span>
										</div>
										<div v-else class="small text-muted">{{ $t('coordinationScreen.compare.hasAllSkills') }}</div>
									</div>

									<div class="comparison-detail-card">
										<div class="comparison-detail-title">{{ $t('coordinationScreen.compare.matchedDays') }}</div>
										<div v-if="comparisonDaySummary.matched.length" class="comparison-chip-wrap">
											<span
												v-for="day in comparisonDaySummary.matched"
												:key="'matched-day-' + day"
												class="comparison-chip comparison-chip-good">
												{{ day }}
											</span>
										</div>
										<div v-else class="small text-muted">{{ $t('coordinationScreen.compare.noMatchedDays') }}</div>
									</div>

									<div class="comparison-detail-card">
										<div class="comparison-detail-title">{{ $t('coordinationScreen.compare.missingDays') }}</div>
										<div v-if="comparisonDaySummary.missing.length" class="comparison-chip-wrap">
											<span
												v-for="day in comparisonDaySummary.missing"
												:key="'missing-day-' + day"
												class="comparison-chip comparison-chip-warn">
												{{ day }}
											</span>
										</div>
										<div v-else class="small text-muted">{{ $t('coordinationScreen.compare.allDaysMatched') }}</div>
									</div>
								</div>

								<div v-if="comparisonHighlights.length" class="comparison-highlights mt-3">
									<div class="fw-semibold mb-2">{{ $t('coordinationScreen.compare.highlights') }}</div>
									<div v-for="highlight in comparisonHighlights" :key="highlight" class="small text-muted mb-1">
										<i class="fa-solid fa-circle-info text-primary me-2"></i>{{ highlight }}
									</div>
								</div>
							</div>
						</div>
						<div class="modal-footer border-0 pt-0">
							<button type="button" class="btn btn-light rounded-pill px-4" @click="closeVolunteerDetail">{{ $t('common.close') }}</button>
							<button
								v-if="activeCampaign"
								type="button"
								class="btn btn-outline-dark rounded-pill px-4"
								@click="toggleComparisonPanel">
								{{ showComparisonPanel ? $t('coordinationScreen.compare.hide') : $t('coordinationScreen.compare.show') }}
							</button>
								<button
									v-if="selectedVolunteerDetail.id"
									type="button"
									class="btn btn-primary rounded-pill px-4"
									:disabled="!canManageCoordination || inviteLoading || !canInviteVolunteer(selectedVolunteerDetail)"
									@click="inviteVolunteers([selectedVolunteerDetail.id])">
									{{ getInviteButtonLabel(selectedVolunteerDetail) }}
								</button>
					</div>
				</div>
			</div>
		</div>
		<div v-if="showDetailModal" class="modal-backdrop fade show" @click="closeVolunteerDetail"></div>
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue'
import StatCards from '../../components/StatCards.vue'
import api from '../../services/api'
import { hasPermission } from '../../utils/permissions'

const PRIORITY_MAP = { khan_cap: 'urgent', cao: 'high', trung_binh: 'medium', thap: 'low' };

export default {
	name: 'DieuPhoiNhanSu',
	components: { PageHeader, StatCards },
	inject: ['toast'],
	data() {
		return {
			campaigns: [],
			selectedCampaignId: '',
			isLoadingCampaigns: false,
			isLoadingRecommendations: false,
				inviteLoading: false,
				pageSize: 8,
				excludedVolunteerSearchQuery: '',
				recommendationPage: 1,
				primaryPage: 1,
				remoteAreaPage: 1,
				backupPage: 1,
				excludedPage: 1,
				profileHighlightPage: 1,
				profileSortMode: 'strongest',
				selectedInviteIds: [],
			recommendedVolunteers: [],
			remoteAreaVolunteers: [],
			excludedVolunteers: [],
			allocationPrimary: [],
			allocationBackup: [],
			allocationRisks: [],
				allocationSummary: {},
				showDetailModal: false,
				selectedVolunteerDetail: null,
				selectedVolunteerContext: '',
				showComparisonPanel: false,
			};
		},
		computed: {
			canManageCoordination() {
				try {
					const user = JSON.parse(localStorage.getItem('user') || 'null');
					return hasPermission(user, 'campaign_coordination.manage');
				} catch (_error) {
					return false;
				}
			},
			activeCampaign() {
				return this.campaigns.find((campaign) => String(campaign.id) === String(this.selectedCampaignId)) || null;
			},
			comparisonSkillSummary() {
				if (!this.showDetailModal || !this.selectedVolunteerDetail || !this.activeCampaign) {
					return { matched: [], missing: [], noRequirement: false };
				}

				const campaignSkills = this.activeCampaign.skills || [];
				const volunteerSkills = this.selectedVolunteerDetail.skills || [];
				const noRequirement = campaignSkills.length === 0;

				return {
					noRequirement,
					matched: volunteerSkills.filter((skill) => campaignSkills.includes(skill)),
					missing: campaignSkills.filter((skill) => !volunteerSkills.includes(skill)),
				};
			},
			comparisonDaySummary() {
				if (!this.showDetailModal || !this.selectedVolunteerDetail || !this.activeCampaign) {
					return { matched: [], missing: [] };
				}

				const campaignDays = this.getCampaignWeekdayLabels(this.activeCampaign.startDate, this.activeCampaign.endDate);
				const volunteerDays = this.normalizeVolunteerDayLabels(this.selectedVolunteerDetail.availabilityDays || []);
				const matched = campaignDays.filter((day) => volunteerDays.includes(day));
				const missing = campaignDays.filter((day) => !volunteerDays.includes(day));

				return { matched, missing };
			},
			comparisonRows() {
				if (!this.showDetailModal || !this.selectedVolunteerDetail || !this.activeCampaign) return [];

				const campaignSkills = this.activeCampaign.skills || [];
				const volunteerSkills = this.selectedVolunteerDetail.skills || [];
				const matchedSkills = this.comparisonSkillSummary.matched;
				const missingSkills = this.comparisonSkillSummary.missing;
				const skillPercent = campaignSkills.length ? Math.round((matchedSkills.length / campaignSkills.length) * 100) : 100;
				const availabilityPercent = this.selectedVolunteerDetail.breakdown?.availability ?? 0;
				const distancePercent = this.selectedVolunteerDetail.breakdown?.distance ?? 0;
				const overallPercent = this.selectedVolunteerDetail.finalScore ?? 0;
				const hasDistance = this.selectedVolunteerDetail.distanceValue !== null && this.selectedVolunteerDetail.distanceValue !== undefined;
				const matchedDays = this.comparisonDaySummary.matched;
				const missingDays = this.comparisonDaySummary.missing;

				return [
					{
						label: this.$t('coordinationScreen.compare.skillLabel'),
						campaign: campaignSkills.length ? campaignSkills.join(', ') : this.$t('coordinationScreen.compare.noSpecificSkillRequirement'),
						campaignHelper: campaignSkills.length ? this.$t('coordinationScreen.compare.campaignNeedsSkills', { count: campaignSkills.length, matched: matchedSkills.length }) : '',
						volunteer: volunteerSkills.length ? volunteerSkills.join(', ') : this.$t('coordinationScreen.compare.profileNoSkills'),
						volunteerHelper: matchedSkills.length
							? this.$t('coordinationScreen.compare.skillMatchFraction', { matched: matchedSkills.length, total: Math.max(campaignSkills.length, 1), missing: missingSkills.length })
							: (campaignSkills.length ? this.$t('coordinationScreen.compare.noClearSkillMatch') : this.$t('coordinationScreen.compare.skillNotRestricted')),
						statusLabel: this.$t('campaignList.compare.percentMatch', { percent: skillPercent }),
						statusClass: this.getComparisonBadgeClass(skillPercent),
					},
					{
						label: this.$t('coordinationScreen.compare.locationLabel'),
						campaign: this.activeCampaign.location || this.$t('coordinationScreen.compare.noLocation'),
						campaignHelper: this.activeCampaign.areaText || '',
						volunteer: this.selectedVolunteerDetail.areaText || this.$t('coordinationScreen.compare.profileNoArea'),
						volunteerHelper: hasDistance ? this.$t('coordinationScreen.compare.distanceToCampaign', { distance: this.selectedVolunteerDetail.distanceText }) : this.$t('coordinationScreen.compare.distanceUnavailable'),
						statusLabel: this.$t('coordinationScreen.compare.percentNear', { percent: hasDistance ? distancePercent : 0 }),
						statusClass: hasDistance ? this.getComparisonBadgeClass(distancePercent) : 'comparison-badge-muted',
					},
					{
						label: this.$t('coordinationScreen.compare.timeLabel'),
						campaign: this.activeCampaign.dateText || this.$t('coordinationScreen.compare.noSpecificDate'),
						campaignHelper: this.activeCampaign.weekdayRangeText || '',
						volunteer: this.selectedVolunteerDetail.availabilityText || this.$t('coordinationScreen.compare.profileNoAvailability'),
						volunteerHelper: this.selectedVolunteerDetail.breakdown ? this.$t('coordinationScreen.compare.dayMatchSummary', { matched: matchedDays.length, missing: missingDays.length }) : '',
						statusLabel: this.$t('campaignList.compare.percentMatch', { percent: availabilityPercent }),
						statusClass: this.getComparisonBadgeClass(availabilityPercent),
					},
					{
						label: this.$t('coordinationScreen.compare.overallLabel'),
						campaign: this.activeCampaign.priorityLabel || this.$t('coordinationScreen.compare.notSpecified'),
						campaignHelper: this.activeCampaign.capacityText || '',
						volunteer: this.selectedVolunteerDetail.matchLabel || this.$t('coordinationScreen.compare.noGroupYet'),
						volunteerHelper: this.selectedVolunteerDetail.finalScore !== null && this.selectedVolunteerDetail.finalScore !== undefined
							? this.$t('coordinationScreen.compare.profileOverallFit', { percent: this.selectedVolunteerDetail.finalScore })
							: (this.selectedVolunteerDetail.reason || this.$t('coordinationScreen.compare.notQualifiedYet')),
						statusLabel: this.$t('campaignList.compare.percentOverall', { percent: overallPercent }),
						statusClass: this.getComparisonBadgeClass(overallPercent),
					},
				];
			},
			comparisonHighlights() {
				if (!this.showDetailModal || !this.selectedVolunteerDetail || !this.activeCampaign) return [];

				const matchedSkills = this.comparisonSkillSummary.matched;
				const missingSkills = this.comparisonSkillSummary.missing;
				const noSkillRequirement = this.comparisonSkillSummary.noRequirement;
				const matchedDays = this.comparisonDaySummary.matched;
				const missingDays = this.comparisonDaySummary.missing;
				const highlights = [];

				if (noSkillRequirement) {
					highlights.push(this.$t('coordinationScreen.compare.highlightNoSkillRequirement'));
				} else if (matchedSkills.length) {
					highlights.push(this.$t('coordinationScreen.compare.highlightMatchedSkills', { skills: matchedSkills.join(', ') }));
				}

				if (!noSkillRequirement && missingSkills.length) {
					highlights.push(this.$t('coordinationScreen.compare.highlightMissingSkills', { skills: missingSkills.join(', ') }));
				}

				if (this.selectedVolunteerDetail.distanceText) {
					highlights.push(this.$t('coordinationScreen.compare.highlightDistance', { distance: this.selectedVolunteerDetail.distanceText }));
				}

				if (matchedDays.length) {
					highlights.push(this.$t('coordinationScreen.compare.highlightMatchedDays', { days: matchedDays.join(', ') }));
				}

				if (missingDays.length) {
					highlights.push(this.$t('coordinationScreen.compare.highlightMissingDays', { days: missingDays.join(', ') }));
				}

				if (this.selectedVolunteerDetail.reason) {
					highlights.push(this.selectedVolunteerDetail.reason);
				}

				return highlights.slice(0, 4);
			},
		statCards() {
				return [
				{ label: this.$t('coordinationScreen.statsCampaigns'), value: this.campaigns.length, icon: 'fa-solid fa-flag', color: 'primary' },
				{ label: this.$t('coordinationScreen.statsRecommended'), value: this.displayedRecommendedVolunteers.length, icon: 'fa-solid fa-user-check', color: 'success' },
				{ label: this.$t('coordinationScreen.statsPrimary'), value: this.allocationPrimary.length, icon: 'fa-solid fa-bolt', color: 'warning' },
				{ label: this.$t('coordinationScreen.statsRisks'), value: this.allocationRisks.length, icon: 'fa-solid fa-triangle-exclamation', color: 'danger' },
			];
		},
		displayedRecommendedVolunteers() {
			const primaryIds = new Set(this.allocationPrimary.map((item) => item.id));
			return this.recommendedVolunteers.filter((item) => !primaryIds.has(item.id));
		},
		paginatedRecommendedVolunteers() {
			return this.paginateItems(this.displayedRecommendedVolunteers, this.recommendationPage);
		},
		totalRecommendationPages() {
			return this.getTotalPages(this.displayedRecommendedVolunteers);
		},
		paginatedAllocationPrimary() {
			return this.paginateItems(this.allocationPrimary, this.primaryPage);
		},
		totalPrimaryPages() {
			return this.getTotalPages(this.allocationPrimary);
		},
		paginatedRemoteAreaVolunteers() {
			return this.paginateItems(this.remoteAreaVolunteers, this.remoteAreaPage);
		},
		totalRemoteAreaPages() {
			return this.getTotalPages(this.remoteAreaVolunteers);
		},
		paginatedAllocationBackup() {
			return this.paginateItems(this.allocationBackup, this.backupPage);
		},
		totalBackupPages() {
			return this.getTotalPages(this.allocationBackup);
		},
			filteredExcludedVolunteers() {
				const keyword = this.excludedVolunteerSearchQuery.trim().toLowerCase();
				if (!keyword) return this.excludedVolunteers;
				return this.excludedVolunteers.filter((item) => String(item?.ho_ten || '').toLowerCase().includes(keyword));
			},
			paginatedExcludedVolunteers() {
				return this.paginateItems(this.filteredExcludedVolunteers, this.excludedPage);
			},
			totalExcludedPages() {
				return this.getTotalPages(this.filteredExcludedVolunteers);
			},
			profileHighlightVolunteers() {
				const merged = [
					...this.allocationPrimary,
					...this.displayedRecommendedVolunteers,
					...this.remoteAreaVolunteers,
					...this.excludedVolunteers.map((item) => this.mapExcludedVolunteerForUi(item)),
				];
				const byId = new Map();
				merged.forEach((item) => {
					if (!byId.has(item.id)) byId.set(item.id, item);
				});
				return Array.from(byId.values());
			},
			sortedProfileHighlightVolunteers() {
				const items = [...this.profileHighlightVolunteers];
				const factor = this.profileSortMode === 'strongest' ? -1 : 1;
				return items.sort((a, b) => {
					const profileCompare = (a.breakdown.profileStrength - b.breakdown.profileStrength) * factor;
					if (profileCompare !== 0) return profileCompare;
					const experienceCompare = ((a.experienceCount || 0) - (b.experienceCount || 0)) * factor;
					if (experienceCompare !== 0) return experienceCompare;
					const certificateCompare = ((a.certificateCount || 0) - (b.certificateCount || 0)) * factor;
					if (certificateCompare !== 0) return certificateCompare;
					return ((a.finalScore || 0) - (b.finalScore || 0)) * factor;
				});
			},
			paginatedProfileHighlightVolunteers() {
				return this.paginateItems(this.sortedProfileHighlightVolunteers, this.profileHighlightPage);
			},
			totalProfileHighlightPages() {
				return this.getTotalPages(this.sortedProfileHighlightVolunteers);
			},
			profileSortLabel() {
				return this.profileSortMode === 'strongest'
					? this.$t('coordinationScreen.profileSortStrongest')
					: this.$t('coordinationScreen.profileSortWeakest');
			},
		},
	watch: {
		selectedCampaignId(newValue) {
			if (!newValue) {
				this.clearCoordinationState();
				this.syncRouteQuery('');
				return;
			}
			this.syncRouteQuery(newValue);
			this.loadCoordinationData();
		},
		totalPrimaryPages(total) {
			this.primaryPage = this.clampPage(this.primaryPage, total);
		},
		totalRemoteAreaPages(total) {
			this.remoteAreaPage = this.clampPage(this.remoteAreaPage, total);
		},
		totalExcludedPages(total) {
			this.excludedPage = this.clampPage(this.excludedPage, total);
		},
		totalRecommendationPages(total) {
			this.recommendationPage = this.clampPage(this.recommendationPage, total);
		},
		excludedVolunteerSearchQuery() {
			this.excludedPage = 1;
		},
		totalProfileHighlightPages(total) {
			this.profileHighlightPage = this.clampPage(this.profileHighlightPage, total);
		},
	},
	async mounted() {
		await this.loadCampaigns();
	},
	methods: {
			mapCampaignFromApi(cd) {
				const skills = (cd.ky_nangs || []).map((skill) => skill.ten).filter(Boolean);
				const weekdayRangeText = this.buildCampaignWeekdayRangeText(cd.ngay_bat_dau, cd.ngay_ket_thuc);
				return {
					id: cd.id,
					title: cd.tieu_de,
					location: cd.dia_diem,
					priority: PRIORITY_MAP[cd.muc_do_uu_tien] || 'medium',
					priorityLabel: {
						high: this.$t('coordinationScreen.priorityHigh'),
						medium: this.$t('coordinationScreen.priorityMedium'),
						low: this.$t('coordinationScreen.priorityLow'),
						urgent: this.$t('coordinationScreen.priorityUrgent'),
					}[PRIORITY_MAP[cd.muc_do_uu_tien] || 'medium'],
					minVolunteers: cd.so_luong_toi_thieu || 1,
					maxVolunteers: cd.so_luong_toi_da || 0,
					registered: cd.so_dang_ky || 0,
					startDate: cd.ngay_bat_dau || '',
					endDate: cd.ngay_ket_thuc || '',
					skills,
					dateText: this.buildCampaignDateText(cd.ngay_bat_dau, cd.ngay_ket_thuc),
					weekdayRangeText,
					areaText: cd.khu_vuc?.ten || '',
					capacityText: this.$t('coordinationScreen.capacityText', { min: cd.so_luong_toi_thieu || 1, max: cd.so_luong_toi_da || 0 }),
				};
			},
		clearCoordinationState() {
			this.resetPagination();
			this.selectedInviteIds = [];
			this.recommendedVolunteers = [];
			this.remoteAreaVolunteers = [];
			this.excludedVolunteers = [];
			this.allocationPrimary = [];
			this.allocationBackup = [];
			this.allocationRisks = [];
			this.allocationSummary = {};
		},
		syncRouteQuery(campaignId) {
			const nextQuery = { ...this.$route.query };
			if (campaignId) {
				nextQuery.campaign_id = String(campaignId);
			} else {
				delete nextQuery.campaign_id;
			}
			this.$router.replace({ path: this.$route.path, query: nextQuery });
		},
			getRecommendationBadgeClass(level) {
				return {
					rat_phu_hop: 'bg-success text-white',
					phu_hop: 'bg-primary text-white',
					can_nhac: 'bg-warning text-dark',
				}[level] || 'bg-secondary text-white';
			},
			getComparisonBadgeClass(percent) {
				if (percent >= 80) return 'comparison-badge-good';
				if (percent >= 50) return 'comparison-badge-warn';
				if (percent > 0) return 'comparison-badge-bad';
				return 'comparison-badge-muted';
			},
			getWeekdayLabel(dateString) {
				if (!dateString) return '';
				const date = new Date(dateString);
				if (Number.isNaN(date.getTime())) return '';
				const labels = [
					this.$t('common.weekdays.sunday'),
					this.$t('common.weekdays.monday'),
					this.$t('common.weekdays.tuesday'),
					this.$t('common.weekdays.wednesday'),
					this.$t('common.weekdays.thursday'),
					this.$t('common.weekdays.friday'),
					this.$t('common.weekdays.saturday'),
				];
				return labels[date.getDay()] || '';
			},
			formatShortDate(dateString) {
				if (!dateString) return '';
				const date = new Date(dateString);
				if (Number.isNaN(date.getTime())) return dateString;
				const day = String(date.getDate()).padStart(2, '0');
				const month = String(date.getMonth() + 1).padStart(2, '0');
				const year = date.getFullYear();
				return `${day}-${month}-${year}`;
			},
			buildCampaignDateText(startDate, endDate) {
				const start = this.formatShortDate(startDate);
				const end = this.formatShortDate(endDate);
				if (start && end) return `${start} - ${end}`;
				return start || end || this.$t('coordinationScreen.compare.noSpecificDate');
			},
			buildCampaignWeekdayRangeText(startDate, endDate) {
				const startWeekday = this.getWeekdayLabel(startDate);
				const endWeekday = this.getWeekdayLabel(endDate);
				const start = this.formatShortDate(startDate);
				const end = this.formatShortDate(endDate);

				if (startWeekday && endWeekday && start && end) {
					return `${start} (${startWeekday}) đến ${end} (${endWeekday})`;
				}

				return '';
			},
			getCampaignWeekdayLabels(startDate, endDate) {
				if (!startDate || !endDate) return [];
				const current = new Date(startDate);
				const end = new Date(endDate);
				if (Number.isNaN(current.getTime()) || Number.isNaN(end.getTime()) || current > end) return [];

				const labels = [];
				const seen = new Set();
				while (current <= end) {
					const label = this.getWeekdayLabel(current.toISOString().slice(0, 10));
					if (label && !seen.has(label)) {
						seen.add(label);
						labels.push(label);
					}
					current.setDate(current.getDate() + 1);
				}
				return labels;
			},
			normalizeVolunteerDayLabels(days = []) {
				const dayMap = {
					thu_hai: this.$t('common.weekdays.monday'),
					thu_ba: this.$t('common.weekdays.tuesday'),
					thu_tu: this.$t('common.weekdays.wednesday'),
					thu_nam: this.$t('common.weekdays.thursday'),
					thu_sau: this.$t('common.weekdays.friday'),
					thu_bay: this.$t('common.weekdays.saturday'),
					chu_nhat: this.$t('common.weekdays.sunday'),
					thu_hai_ca_ngay: this.$t('common.weekdays.monday'),
					thu_ba_ca_ngay: this.$t('common.weekdays.tuesday'),
					thu_tu_ca_ngay: this.$t('common.weekdays.wednesday'),
					thu_nam_ca_ngay: this.$t('common.weekdays.thursday'),
					thu_sau_ca_ngay: this.$t('common.weekdays.friday'),
					thu_bay_ca_ngay: this.$t('common.weekdays.saturday'),
					chu_nhat_ca_ngay: this.$t('common.weekdays.sunday'),
				};

				return [...new Set(
					(days || [])
						.map((day) => String(day || '').trim().toLowerCase())
						.map((day) => dayMap[day] || '')
						.filter(Boolean)
				)];
			},
		resetPagination() {
			this.recommendationPage = 1;
			this.primaryPage = 1;
			this.remoteAreaPage = 1;
			this.backupPage = 1;
			this.excludedPage = 1;
			this.profileHighlightPage = 1;
		},
		clampPage(page, totalPages) {
			const total = Math.max(1, Number(totalPages || 1));
			const current = Number(page || 1);
			return Math.min(total, Math.max(1, current));
		},
		changePage(pageKey, nextPage, totalPages) {
			this[pageKey] = this.clampPage(nextPage, totalPages);
		},
		getVisiblePages(currentPage, totalPages) {
			const current = this.clampPage(currentPage, totalPages);
			const total = Math.max(1, Number(totalPages || 1));
			if (total <= 7) {
				return Array.from({ length: total }, (_, index) => index + 1);
			}

			const pages = [1];
			const start = Math.max(2, current - 1);
			const end = Math.min(total - 1, current + 1);

			if (start > 2) pages.push('...');
			for (let page = start; page <= end; page += 1) {
				pages.push(page);
			}
			if (end < total - 1) pages.push('...');
			pages.push(total);

			return pages;
		},
		getTotalPages(items) {
			return Math.max(1, Math.ceil((items?.length || 0) / this.pageSize));
		},
		paginateItems(items, page) {
			const list = Array.isArray(items) ? items : [];
			const safePage = this.clampPage(page, this.getTotalPages(list));
			const start = (safePage - 1) * this.pageSize;
			return list.slice(start, start + this.pageSize);
		},
		getVolunteerListMeta(volunteer) {
			const parts = [];
			if (volunteer.areaText) parts.push(volunteer.areaText);
			if (volunteer.distanceText) parts.push(volunteer.distanceText);
			return parts.join(' • ');
		},
		getRegistrationStatusLabel(status) {
			return {
				da_dang_ky: this.$t('coordinationScreen.registrationPending'),
				da_xac_nhan: this.$t('coordinationScreen.registrationConfirmed'),
				da_duyet: this.$t('campaignRegistration.statuses.da_duyet'),
				dang_tham_gia: this.$t('coordinationScreen.registrationParticipating'),
				hoan_thanh: this.$t('coordinationScreen.registrationCompleted'),
			}[status] || '';
		},
		canInviteVolunteer(volunteer) {
			const status = volunteer?.registrationStatus || volunteer?.registration_status || '';
			return !['da_dang_ky', 'da_xac_nhan', 'da_duyet', 'dang_tham_gia', 'hoan_thanh'].includes(status);
		},
		getInviteButtonLabel(volunteer) {
			const status = volunteer?.registrationStatus || volunteer?.registration_status || '';
			if (status === 'da_dang_ky') return this.$t('coordinationScreen.invitePending');
			if (status === 'da_xac_nhan') return this.$t('coordinationScreen.inviteConfirmed');
			if (status === 'da_duyet') return this.$t('campaignRegistration.statuses.da_duyet');
			if (status === 'dang_tham_gia') return this.$t('coordinationScreen.inviteParticipating');
			if (status === 'hoan_thanh') return this.$t('coordinationScreen.inviteCompleted');
			return this.$t('coordinationScreen.invite');
		},
		isVolunteerSelected(volunteerId) {
			return this.selectedInviteIds.includes(volunteerId);
		},
		toggleVolunteerSelection(volunteerId, checked) {
			const ids = new Set(this.selectedInviteIds);
			if (checked) {
				ids.add(volunteerId);
			} else {
				ids.delete(volunteerId);
			}
			this.selectedInviteIds = Array.from(ids);
		},
		isGroupFullySelected(volunteers = []) {
			if (!volunteers.length) return false;
			return volunteers.every((item) => this.selectedInviteIds.includes(item.id));
		},
			toggleGroupSelection(volunteers = [], checked) {
				const ids = new Set(this.selectedInviteIds);
			volunteers.forEach((item) => {
				if (checked) {
					ids.add(item.id);
				} else {
					ids.delete(item.id);
				}
				});
				this.selectedInviteIds = Array.from(ids);
			},
			toggleProfileSort() {
				this.profileSortMode = this.profileSortMode === 'strongest' ? 'weakest' : 'strongest';
				this.profileHighlightPage = 1;
			},
		getExcludedShortTitle(reason = '') {
			const normalized = reason.toLowerCase();
			if (normalized.includes('trùng lịch')) return this.$t('coordinationScreen.excludedScheduleConflictTitle');
			if (normalized.includes('xác thực')) return this.$t('coordinationScreen.excludedVerificationTitle');
			if (normalized.includes('kỹ năng')) return this.$t('coordinationScreen.excludedSkillTitle');
			if (normalized.includes('không hoạt động')) return this.$t('coordinationScreen.excludedInactiveTitle');
			return this.$t('coordinationScreen.excludedDefaultTitle');
		},
		getExcludedShortSummary(reason = '') {
			const normalized = reason.toLowerCase();
			if (normalized.includes('trùng lịch')) return this.$t('coordinationScreen.excludedScheduleConflictSummary');
			if (normalized.includes('xác thực')) return this.$t('coordinationScreen.excludedVerificationSummary');
			if (normalized.includes('kỹ năng')) return this.$t('coordinationScreen.excludedSkillSummary');
			if (normalized.includes('không hoạt động')) return this.$t('coordinationScreen.excludedInactiveSummary');
			return reason || this.$t('coordinationScreen.excludedDefaultSummary');
		},
			mapVolunteerForUi(item, bucket = 'recommendation') {
				const finalScore = Math.round(item.final_score || 0);
				const breakdown = {
					skill: Math.round(item.score_breakdown?.skill || 0),
					availability: Math.round(item.score_breakdown?.availability || 0),
					distance: Math.round(item.score_breakdown?.distance || 0),
					preference: Math.round(item.score_breakdown?.preference || 0),
					reliability: Math.round(item.score_breakdown?.reliability || 0),
					profileStrength: Math.round(item.score_breakdown?.profile_strength || 0),
				};
			const reasons = item.reasons || [];
			const warnings = item.warnings || [];
			const name = item.ho_ten || item.name || '—';

			let decisionTitle = this.$t('coordinationScreen.decisionFitTitle');
			let decisionSummary = this.$t('coordinationScreen.decisionFitSummary');

			if (bucket === 'primary') {
				decisionTitle = this.$t('coordinationScreen.decisionPrimaryTitle');
				if (breakdown.skill >= 80 && breakdown.availability >= 80) {
					decisionSummary = this.$t('coordinationScreen.decisionPrimaryStrong');
				} else if (warnings.length === 0) {
					decisionSummary = this.$t('coordinationScreen.decisionPrimaryBalanced');
				} else {
					decisionSummary = this.$t('coordinationScreen.decisionPrimaryWithWarnings');
				}
			}

			if (bucket === 'backup') {
				decisionTitle = this.$t('coordinationScreen.decisionBackupTitle');
				if (warnings.length > 0) {
					decisionSummary = this.$t('coordinationScreen.decisionBackupWithWarnings');
				} else {
					decisionSummary = this.$t('coordinationScreen.decisionBackupSummary');
				}
			}

			if (bucket === 'remote_area') {
				decisionTitle = this.$t('coordinationScreen.decisionRemoteAreaTitle');
				decisionSummary = item.area_match_reason || this.$t('coordinationScreen.decisionRemoteAreaSummary');
			}

			const matchLabel = bucket === 'remote_area'
				? this.$t('coordinationScreen.remoteAreaBadge')
				: ({
					rat_phu_hop: this.$t('coordinationScreen.matchPrimary'),
					phu_hop: this.$t('coordinationScreen.matchBackup'),
					can_nhac: this.$t('coordinationScreen.matchConsider'),
				}[item.match_level] || this.$t('coordinationScreen.matchDefault'));

				return {
					id: item.id,
					name,
					email: item.email || '—',
					avatar: item.anh_dai_dien || item.avatar || null,
					skills: (item.ky_nangs || []).map((skill) => skill.ten),
					areaText: (item.khu_vucs || []).map((area) => area.ten).join(', ') || this.$t('coordinationScreen.noArea'),
					availabilityText: (item.lich_ranh || []).join(', ') || this.$t('coordinationScreen.noAvailability'),
					availabilityDays: item.lich_ranh || [],
					distanceText: item.distance_km !== null && item.distance_km !== undefined ? `${item.distance_km} km` : '',
					distanceValue: item.distance_km !== null && item.distance_km !== undefined ? Number(item.distance_km) : null,
					experienceCount: Number(item.experience_count || 0),
					certificateCount: Number(item.certificate_count || 0),
					registrationStatus: item.registration_status || '',
					registrationStatusLabel: this.getRegistrationStatusLabel(item.registration_status),
					finalScore,
					matchLevel: item.match_level,
				matchLabel,
				breakdown,
				reasons,
				warnings,
				areaMatchReason: item.area_match_reason || '',
				decisionTitle,
				decisionSummary,
			};
		},
			mapExcludedVolunteerForUi(item) {
			const mapped = this.mapVolunteerForUi(item, 'excluded');
			return {
				...mapped,
				reason: item.reason || this.$t('coordinationScreen.excludedDefaultSummary'),
				decisionTitle: this.getExcludedShortTitle(item.reason || ''),
				decisionSummary: this.getExcludedShortSummary(item.reason || ''),
				matchLabel: mapped.matchLabel || '',
				matchLevel: mapped.matchLevel || '',
				};
			},
			applyInviteState(volunteerIds = [], nextStatus = 'da_dang_ky') {
				const idSet = new Set((volunteerIds || []).map((id) => Number(id)));
				const updateMappedList = (list = []) => list.map((item) => {
					if (!idSet.has(Number(item.id))) return item;
					return {
						...item,
						registrationStatus: nextStatus,
						registrationStatusLabel: this.getRegistrationStatusLabel(nextStatus),
					};
				});
				const updateRawList = (list = []) => list.map((item) => {
					if (!idSet.has(Number(item.id))) return item;
					return {
						...item,
						registration_status: nextStatus,
					};
				});

				this.allocationPrimary = updateMappedList(this.allocationPrimary);
				this.recommendedVolunteers = updateMappedList(this.recommendedVolunteers);
				this.remoteAreaVolunteers = updateMappedList(this.remoteAreaVolunteers);
				this.excludedVolunteers = updateRawList(this.excludedVolunteers);

				if (this.selectedVolunteerDetail && idSet.has(Number(this.selectedVolunteerDetail.id))) {
					this.selectedVolunteerDetail = {
						...this.selectedVolunteerDetail,
						registrationStatus: nextStatus,
						registrationStatusLabel: this.getRegistrationStatusLabel(nextStatus),
					};
				}
			},
				openVolunteerDetail(volunteer, context = '') {
				this.selectedVolunteerDetail = volunteer;
				this.selectedVolunteerContext = context;
				this.showComparisonPanel = false;
				this.showDetailModal = true;
			},
			closeVolunteerDetail() {
				this.showDetailModal = false;
				this.selectedVolunteerDetail = null;
				this.selectedVolunteerContext = '';
				this.showComparisonPanel = false;
			},
			toggleComparisonPanel() {
				this.showComparisonPanel = !this.showComparisonPanel;
			},
		async loadCampaigns() {
			this.isLoadingCampaigns = true;
			try {
				const res = await api.get('/tinh-nguyen-vien/chien-dich', {
					params: {
						per_page: 100,
						trang_thai: 'da_duyet',
						for_coordination: 1,
					},
				});
				const items = Array.isArray(res.data?.data) ? res.data.data : [];
				this.campaigns = items
					.filter((item) => item.trang_thai === 'da_duyet')
					.map((item) => this.mapCampaignFromApi(item));

				const requestedId = this.$route.query.campaign_id ? String(this.$route.query.campaign_id) : '';
				const hasRequestedCampaign = requestedId && this.campaigns.some((campaign) => String(campaign.id) === requestedId);

				if (hasRequestedCampaign) {
					this.selectedCampaignId = requestedId;
				} else if (!this.selectedCampaignId && this.campaigns.length > 0) {
					this.selectedCampaignId = String(this.campaigns[0].id);
				}
			} catch (error) {
					this.toast?.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('coordinationScreen.loadCampaignsError'));
			} finally {
				this.isLoadingCampaigns = false;
			}
		},
			async loadCoordinationData() {
				if (!this.selectedCampaignId) return;
				this.isLoadingRecommendations = true;
				try {
					const recommendationRes = await api.get('/goi-y', {
						params: {
							type: 'tinh_nguyen_vien',
							mode: 'allocation',
							campaign_id: this.selectedCampaignId,
							limit: 20,
							only_available: 1,
						},
					});

					const recommendationData = recommendationRes.data?.data || {};
					this.resetPagination();

					this.recommendedVolunteers = (recommendationData.recommended || recommendationData.all || []).map((item) => this.mapVolunteerForUi(item, 'recommendation'));
					this.remoteAreaVolunteers = (recommendationData.remote_area_matches || []).map((item) => this.mapVolunteerForUi(item, 'remote_area'));

					this.excludedVolunteers = recommendationData.excluded || [];
					this.allocationPrimary = (recommendationData.recommended_primary || []).map((item) => this.mapVolunteerForUi(item, 'primary'));
					this.allocationBackup = [];
					this.allocationRisks = recommendationData.risk_flags || [];
					this.allocationSummary = recommendationData.resource_summary || {};
					this.selectedInviteIds = [];
				} catch (error) {
					this.clearCoordinationState();
					this.toast?.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('coordinationScreen.loadCoordinationError'));
			} finally {
				this.isLoadingRecommendations = false;
			}
		},
			async inviteVolunteers(volunteerIds) {
				if (!volunteerIds || volunteerIds.length === 0 || !this.selectedCampaignId) return;
				this.inviteLoading = true;
				try {
					const res = await api.post(`/chien-dich/${this.selectedCampaignId}/moi-tinh-nguyen-vien`, {
						volunteer_ids: volunteerIds,
					});
					this.toast?.showToast('success', this.$t('common.success'), res.data?.message || this.$t('coordinationScreen.inviteSuccess'));
					this.applyInviteState(volunteerIds, 'da_dang_ky');
					this.selectedInviteIds = this.selectedInviteIds.filter((id) => !volunteerIds.includes(id));
					const invitedCount = Number(res.data?.data?.invited_count || 0);
					if (invitedCount > 0) {
						this.allocationSummary = {
							...this.allocationSummary,
							so_dang_ky_hien_tai: Number(this.allocationSummary.so_dang_ky_hien_tai || 0) + invitedCount,
						};
					}
				} catch (error) {
				this.toast?.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('coordinationScreen.inviteError'));
			} finally {
				this.inviteLoading = false;
			}
		},
		inviteSelectedVolunteers() {
			this.inviteVolunteers(this.selectedInviteIds);
		},
		invitePrimaryGroup() {
			this.inviteVolunteers(this.allocationPrimary.map((item) => item.id));
		},
		goToCampaignDetail() {
			if (!this.selectedCampaignId) return;
			this.$router.push(`/quan-ly-chien-dich/chi-tiet/${this.selectedCampaignId}`);
		},
	},
}
</script>

<style scoped>
.summary-card {
	background: #f8fafc;
	border: 1px solid #e2e8f0;
	border-radius: 16px;
	padding: 16px;
	height: 100%;
}

.summary-label {
	color: #64748b;
	font-size: 12px;
	font-weight: 600;
	margin-bottom: 6px;
	text-transform: uppercase;
	letter-spacing: 0.04em;
}

.summary-value {
	color: #0f172a;
	font-size: 20px;
	font-weight: 700;
}

.coordination-summary {
	background: linear-gradient(135deg, rgba(13, 110, 253, 0.05), rgba(25, 135, 84, 0.05));
	border: 1px solid rgba(13, 110, 253, 0.12);
	border-radius: 20px;
	padding: 16px;
}

.recommendation-item {
	background: #fff;
}

.list-row-card {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 16px;
	padding: 14px 16px;
	border: 1px solid #e2e8f0;
	border-radius: 18px;
	background: #fff;
}

.list-row-card-primary {
	border-color: rgba(25, 135, 84, 0.22);
	background: linear-gradient(180deg, rgba(25, 135, 84, 0.05), rgba(255, 255, 255, 0.98));
}

.list-row-card-backup {
	border-color: rgba(108, 117, 125, 0.2);
	background: linear-gradient(180deg, rgba(108, 117, 125, 0.04), rgba(255, 255, 255, 0.98));
}

.list-row-card-excluded {
	margin-bottom: 8px;
}

.list-row-card-recommendation {
	border-color: rgba(13, 110, 253, 0.16);
}

.list-row-card-remote-area {
	border-color: rgba(255, 193, 7, 0.28);
	background: linear-gradient(180deg, rgba(255, 193, 7, 0.08), rgba(255, 255, 255, 0.98));
}

.list-row-main {
	flex: 1 1 auto;
}

.list-row-inline {
	display: flex;
	align-items: center;
	gap: 12px;
	min-width: 0;
}

.list-row-score {
	flex-shrink: 0;
	font-size: 14px;
	font-weight: 700;
	color: #0f172a;
}

.compact-meta {
	min-width: 0;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.allocation-card {
	background: #fff;
}

.allocation-card-primary {
	border-color: rgba(25, 135, 84, 0.25) !important;
	background: linear-gradient(180deg, rgba(25, 135, 84, 0.05), rgba(25, 135, 84, 0.01));
}

.allocation-card-backup {
	border-color: rgba(108, 117, 125, 0.22) !important;
	background: linear-gradient(180deg, rgba(108, 117, 125, 0.05), rgba(108, 117, 125, 0.01));
}

.recommendation-avatar {
	width: 52px;
	height: 52px;
	min-width: 52px;
	font-size: 18px;
}

.allocation-title {
	color: #0f172a;
	font-weight: 600;
}

.allocation-meta-row {
	display: flex;
	flex-wrap: wrap;
	gap: 16px;
	font-size: 13px;
	color: #64748b;
}

.recommend-breakdown-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(110px, 1fr));
	gap: 10px;
}

.recommend-breakdown-item {
	background: #f8fafc;
	border: 1px solid #e2e8f0;
	border-radius: 14px;
	padding: 10px 12px;
	display: flex;
	flex-direction: column;
	gap: 4px;
}

.recommend-breakdown-item span {
	color: #64748b;
	font-size: 12px;
}

.recommend-breakdown-item strong {
	color: #0f172a;
	font-size: 16px;
}

.min-w-0 {
	min-width: 0;
}

.text-clamp-2 {
	display: -webkit-box;
	-webkit-line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
}

.modal-overview {
	padding: 14px 16px;
	border-radius: 16px;
	background: #f8fafc;
	border: 1px solid #e2e8f0;
}

.modal-overview-title {
	font-size: 13px;
	font-weight: 700;
	color: #334155;
	margin-bottom: 6px;
	text-transform: uppercase;
	letter-spacing: 0.04em;
}

.modal-overview-text {
	color: #0f172a;
	font-size: 15px;
	line-height: 1.6;
}

.comparison-panel {
	padding-top: 1rem;
	border-top: 1px solid #e2e8f0;
}

.comparison-panel-header {
	margin-bottom: 1rem;
}

.comparison-panel-title {
	font-size: 1rem;
	font-weight: 700;
	color: #0f172a;
}

.comparison-panel-subtitle {
	font-size: 0.875rem;
	color: #64748b;
	margin-top: 0.15rem;
}

.comparison-table-wrap {
	overflow-x: auto;
	border: 1px solid #e2e8f0;
	border-radius: 16px;
	background: #fff;
}

.comparison-table {
	width: 100%;
	border-collapse: collapse;
	min-width: 760px;
}

.comparison-table th,
.comparison-table td {
	padding: 1rem;
	border-bottom: 1px solid #e2e8f0;
	vertical-align: top;
}

.comparison-table thead th {
	background: #f8fafc;
	font-size: 0.78rem;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	color: #64748b;
}

.comparison-table tbody tr:last-child td {
	border-bottom: 0;
}

.comparison-cell-label {
	width: 140px;
	font-size: 0.95rem;
	font-weight: 700;
	color: #0f172a;
}

.comparison-cell-main {
	min-width: 0;
}

.comparison-cell-status {
	width: 150px;
	text-align: center;
}

.comparison-side-label {
	font-size: 0.72rem;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	color: #64748b;
	margin-bottom: 0.2rem;
}

.comparison-side-main {
	font-size: 0.96rem;
	font-weight: 600;
	color: #0f172a;
	line-height: 1.5;
	word-break: break-word;
}

.comparison-side-helper {
	margin-top: 0.2rem;
	font-size: 0.83rem;
	color: #64748b;
	line-height: 1.45;
}

.comparison-status {
	display: flex;
	align-items: center;
	justify-content: center;
}

.comparison-badge {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.45rem 0.8rem;
	border-radius: 999px;
	font-size: 0.8rem;
	font-weight: 700;
	white-space: nowrap;
}

.comparison-badge-good {
	background: #dcfce7;
	color: #166534;
}

.comparison-badge-warn {
	background: #fef3c7;
	color: #92400e;
}

.comparison-badge-bad {
	background: #fee2e2;
	color: #991b1b;
}

.comparison-badge-muted {
	background: #e5e7eb;
	color: #4b5563;
}

.comparison-highlights {
	padding: 1rem;
	border-radius: 16px;
	border: 1px dashed #cbd5e1;
	background: #f8fafc;
}

.comparison-detail-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 1rem;
}

.comparison-detail-card {
	padding: 1rem;
	border-radius: 16px;
	border: 1px solid #e2e8f0;
	background: #f8fafc;
}

.comparison-detail-title {
	font-size: 0.9rem;
	font-weight: 700;
	color: #0f172a;
	margin-bottom: 0.75rem;
}

.comparison-chip-wrap {
	display: flex;
	flex-wrap: wrap;
	gap: 0.5rem;
}

.comparison-chip {
	display: inline-flex;
	align-items: center;
	padding: 0.4rem 0.75rem;
	border-radius: 999px;
	font-size: 0.82rem;
	font-weight: 600;
}

.comparison-chip-good {
	background: #dcfce7;
	color: #166534;
}

.comparison-chip-warn {
	background: #fef3c7;
	color: #92400e;
}

@media (max-width: 767.98px) {
	.recommendation-avatar {
		width: 44px;
		height: 44px;
		min-width: 44px;
		font-size: 16px;
	}

	.list-row-card {
		flex-direction: column;
		align-items: stretch;
	}

	.list-row-inline {
		flex-wrap: wrap;
	}

	.compact-meta {
		white-space: normal;
	}

	.comparison-detail-grid {
		grid-template-columns: 1fr;
	}
}
</style>
