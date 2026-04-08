<template>
	<div class="bg-light min-vh-100 pb-5">
		<div class="container pt-4">
			<div v-if="canLoadRecommendations && recommendationLoading" class="card border-0 shadow-sm mb-4">
				<div class="card-body p-4 d-flex align-items-center gap-3">
					<div class="spinner-border text-primary" role="status"></div>
					<div>
						<h5 class="fw-bold mb-1">{{ $t('campaignList.recommendation.title') }}</h5>
						<div class="text-muted small">{{ $t('campaignList.recommendation.loading') }}</div>
					</div>
				</div>
			</div>

			<div v-else-if="canLoadRecommendations && recommendedCampaigns.length > 0" class="card border-0 shadow-sm mb-4 recommendation-panel overflow-hidden">
				<div class="card-body p-4 p-lg-5">
					<div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-3 mb-4">
						<div>
							<div class="d-inline-flex align-items-center gap-2 badge rounded-pill text-bg-success px-3 py-2 mb-3">
								<i class="fa-solid fa-wand-magic-sparkles"></i>
								<span>{{ $t('campaignList.recommendation.badge') }}</span>
							</div>
							<h3 class="fw-bold mb-2">{{ $t('campaignList.recommendation.title') }}</h3>
							<p class="text-muted mb-0">{{ $t('campaignList.recommendation.desc') }}</p>
						</div>
						<div class="d-flex gap-2 flex-wrap">
							<button class="btn btn-outline-primary rounded-pill px-3" :class="{ active: recommendationFilters.nearbyOnly }" @click="toggleRecommendationNearby">
								<i class="fa-solid fa-location-dot me-2"></i>{{ $t('campaignList.recommendation.nearbyOnly') }}
							</button>
							<select class="form-select form-select-sm rounded-pill px-3" style="min-width: 190px;" v-model="recommendationFilters.priority" @change="loadRecommendations">
								<option value="">{{ $t('campaignList.recommendation.allPriorities') }}</option>
								<option value="khan_cap">{{ $t('campaignList.recommendation.priorityUrgent') }}</option>
								<option value="cao">{{ $t('campaignList.recommendation.priorityHigh') }}</option>
								<option value="trung_binh">{{ $t('campaignList.recommendation.priorityMedium') }}</option>
								<option value="thap">{{ $t('campaignList.recommendation.priorityLow') }}</option>
							</select>
						</div>
					</div>

					<div class="row g-4">
						<div class="col-md-6 col-xl-4" v-for="campaign in recommendedCampaigns" :key="'rec-' + campaign.id">
							<div class="card h-100 border-0 recommendation-card">
								<div class="campaign-banner-img position-relative" :style="getCampaignBannerStyle(campaign)">
									<div class="position-absolute top-0 start-0 m-3 d-flex flex-column gap-2">
										<span class="badge bg-white text-dark shadow-sm">{{ campaign.categoryLabel }}</span>
										<span class="badge bg-success text-white shadow-sm">{{ campaign.matchLabel }}</span>
									</div>
									<div class="position-absolute bottom-0 end-0 m-3">
										<span class="badge bg-dark text-white shadow-sm">{{ campaign.matchScore }}%</span>
									</div>
								</div>
								<div class="card-body p-4 d-flex flex-column">
									<h5 class="fw-bold mb-2 text-truncate-2" style="min-height: 48px;">
										<router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="text-dark text-decoration-none">
											{{ campaign.title }}
										</router-link>
									</h5>
									<p class="text-muted small mb-3 text-truncate-2">{{ campaign.description }}</p>
									<div class="d-flex flex-wrap gap-2 mb-3">
										<span v-for="badge in campaign.recommendationBadges" :key="badge" class="badge rounded-pill bg-light text-dark border">{{ badge }}</span>
									</div>
									<div class="small text-muted d-flex flex-column gap-2 mb-3">
										<div><i class="fa-solid fa-location-dot text-danger me-2"></i>{{ campaign.location }}</div>
										<div><i class="fa-regular fa-calendar text-primary me-2"></i>{{ campaign.startDate }} — {{ campaign.endDate }}</div>
										<div v-if="campaign.distanceText"><i class="fa-solid fa-route text-success me-2"></i>{{ campaign.distanceText }}</div>
									</div>
										<div class="recommend-breakdown rounded-3 p-3 bg-light mb-3">
											<div class="d-flex justify-content-between small mb-1"><span>{{ $t('campaignList.recommendation.skill') }}</span><strong>{{ campaign.breakdown.skill }}%</strong></div>
											<div class="d-flex justify-content-between small mb-1"><span>{{ $t('campaignList.recommendation.availability') }}</span><strong>{{ campaign.breakdown.availability }}%</strong></div>
											<div class="d-flex justify-content-between small mb-1"><span>{{ $t('campaignList.recommendation.distance') }}</span><strong>{{ campaign.breakdown.distance }}%</strong></div>
											<div class="d-flex justify-content-between small mb-1"><span>{{ $t('campaignList.recommendation.reliability') }}</span><strong>{{ campaign.breakdown.reliability }}%</strong></div>
											<div class="d-flex justify-content-between small"><span>{{ $t('campaignList.recommendation.profileStrength') }}</span><strong>{{ campaign.breakdown.profileStrength }}%</strong></div>
										</div>
									<div class="small text-muted mt-auto">
										<div v-for="reason in campaign.reasons" :key="reason" class="mb-1">
											<i class="fa-solid fa-circle-check text-success me-2"></i>{{ reason }}
										</div>
										<div v-for="warning in campaign.warnings" :key="warning" class="mb-1 text-warning-emphasis">
											<i class="fa-solid fa-triangle-exclamation text-warning me-2"></i>{{ warning }}
										</div>
									</div>
									<div class="d-flex gap-2 mt-3 position-relative z-2" v-if="canLoadRecommendations">
										<button class="btn btn-outline-dark btn-sm rounded-pill px-3" @click="openCampaignCompare(campaign)">
											<i class="fa-solid fa-table-columns me-1"></i>{{ $t('campaignList.compare.open') }}
										</button>
										<router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="btn btn-primary btn-sm rounded-pill px-3">
											{{ $t('campaignList.compare.viewDetail') }}
										</router-link>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<div v-if="searchKeyword" class="card border-0 shadow-sm mb-4 search-result-banner overflow-hidden">
				<div class="card-body p-4 p-lg-5 position-relative">
					<div class="search-banner-shape search-banner-shape-1"></div>
					<div class="search-banner-shape search-banner-shape-2"></div>
					<div class="position-relative d-flex flex-column flex-lg-row align-items-lg-center justify-content-between gap-3">
						<div>
							<div class="d-inline-flex align-items-center gap-2 badge rounded-pill text-bg-primary px-3 py-2 mb-3">
								<i class="fa-solid fa-magnifying-glass"></i>
								<span>{{ $t('campaignList.searchResultBadge') }}</span>
							</div>
							<h3 class="fw-bold mb-2">{{ $t('campaignList.searchResultTitle', { keyword: searchKeyword }) }}</h3>
							<p class="text-muted mb-0">{{ $t('campaignList.searchResultDesc', { count: sortedCampaigns.length }) }}</p>
						</div>
						<button class="btn btn-outline-secondary rounded-pill px-4 align-self-start align-self-lg-center" @click="clearSearchQuery">
							<i class="fa-solid fa-xmark me-2"></i>{{ $t('campaignList.clearSearchQuery') }}
						</button>
					</div>
				</div>
			</div>

			<!-- Mobile Filter Toggle -->
			<div class="d-lg-none mb-3">
				<button class="btn btn-primary w-100 fw-medium d-flex align-items-center justify-content-center gap-2" type="button" data-bs-toggle="offcanvas" data-bs-target="#filterOffcanvas">
					<i class="fa-solid fa-filter"></i> {{ $t('campaignList.filterCampaigns') }}
				</button>
			</div>

			<div class="row g-4">
				<!-- LEFT: Filters (Sidebar for Desktop) -->
				<div class="col-lg-3 d-none d-lg-block">
					<div class="card border-0 shadow-sm campaign-filter-sidebar">
						<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-filter me-2 text-primary"></i>{{ $t('campaignList.filters') }}</h6>
							<a href="#" class="small text-muted text-decoration-none" @click.prevent="clearFilters">{{ $t('campaignList.clearFilter') }}</a>
						</div>
						<div class="card-body p-0">
							<!-- Search -->
							<div class="p-3 border-bottom">
								<div class="input-group">
									<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
									<input type="text" class="form-control bg-light border-start-0 ps-0" :placeholder="$t('campaignList.campaignNamePlaceholder')" v-model="filters.search">
								</div>
							</div>

							<!-- Trạng thái -->
							<div class="p-3 border-bottom">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.status') }}</h6>
								<div class="form-check mb-2" v-for="status in filterMeta.statuses" :key="status.value">
									<input class="form-check-input" type="checkbox" :id="'status-' + status.value" :value="status.value" v-model="filters.status">
									<label class="form-check-label small d-flex justify-content-between align-items-center w-100" :for="'status-' + status.value">
										<span>{{ getFilterStatusLabel(status.value) }}</span>
										<span class="badge bg-light text-muted fw-normal rounded-pill">{{ status.count }}</span>
									</label>
								</div>
							</div>

							<!-- Loại chiến dịch -->
							<div class="p-3 border-bottom">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.field') }}</h6>
								<div class="form-check mb-2" v-for="cat in filterMeta.categories" :key="cat.value">
									<input class="form-check-input" type="checkbox" :id="'cat-'+cat.value" :value="cat.value" v-model="filters.category">
									<label class="form-check-label small d-flex justify-content-between align-items-center w-100" :for="'cat-'+cat.value">
										<span>{{ cat.label }}</span>
										<span class="badge bg-light text-muted fw-normal rounded-pill">{{ cat.count }}</span>
									</label>
								</div>
							</div>

							<!-- Địa điểm -->
							<div class="p-3 border-bottom">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.location') }}</h6>
								<select class="form-select form-select-sm" v-model="filters.location">
									<option value="">{{ $t('campaignList.allAreas') }}</option>
									<option v-for="location in filterMeta.locations" :key="location.value" :value="location.value">{{ location.value }}</option>
								</select>
							</div>

							<!-- Người điều phối -->
							<div class="p-3">
								<h6 class="fw-bold small text-uppercase text-muted mb-3">{{ $t('campaignList.creatorLabel') }}</h6>
								<select class="form-select form-select-sm" v-model="filters.coordinator">
									<option value="">{{ $t('common.all') }}</option>
									<option v-for="coord in filterMeta.creators" :key="coord.value" :value="coord.value">
										{{ coord.label }}
									</option>
								</select>
							</div>
						</div>
					</div>
				</div>

				<!-- RIGHT: Main Content -->
				<div class="col-lg-9">
					<!-- Top Sort Bar -->
					<div class="card border-0 shadow-sm mb-4">
						<div class="card-body p-3 d-flex flex-column flex-sm-row justify-content-between align-items-center gap-3">
							<div class="text-muted small">
								{{ $t('campaignList.showingResults') }} <strong>{{ sortedCampaigns.length }}</strong> {{ $t('campaignList.resultsLabel') }}
							</div>
							<div class="d-flex align-items-center gap-2">
								<span class="text-muted small fw-medium text-nowrap">{{ $t('campaignList.sortBy') }}</span>
								<select class="form-select form-select-sm bg-light border-0" style="width: 160px;" v-model="sortBy">
									<option value="newest">{{ $t('campaignList.newest') }}</option>
									<option value="urgent">{{ $t('campaignList.urgentFirst') }}</option>
									<option value="soonest">{{ $t('campaignList.soonest') }}</option>
								</select>
							</div>
						</div>
					</div>

					<div v-if="loading" class="row g-4">
						<div class="col-md-6 col-xl-4" v-for="n in 6" :key="n">
							<div class="card h-100 border-0 shadow-sm placeholder-glow">
								<div class="placeholder campaign-banner-img"></div>
								<div class="card-body p-4">
									<span class="placeholder col-9 mb-3 d-block"></span>
									<span class="placeholder col-12 mb-2 d-block"></span>
									<span class="placeholder col-8 mb-4 d-block"></span>
									<span class="placeholder col-6 d-block"></span>
								</div>
							</div>
						</div>
					</div>

					<!-- Campaigns Grid -->
					<div v-else class="row g-4">
						<div class="col-md-6 col-xl-4" v-for="campaign in sortedCampaigns" :key="campaign.id">
							<div class="card h-100 border-0 shadow-sm campaign-card">
								<!-- Image/Banner Placeholder -->
								<div class="campaign-banner-img position-relative" :style="getCampaignBannerStyle(campaign)">
									<div class="position-absolute top-0 start-0 m-3 d-flex flex-column gap-2">
										<span class="badge bg-white text-dark shadow-sm">{{ campaign.categoryLabel }}</span>
										<span class="badge" :class="getPriorityClassBadge(campaign.priority)">{{ getPriorityLabel(campaign.priority) }}</span>
									</div>
									<div class="position-absolute bottom-0 end-0 m-3 d-flex flex-column align-items-end gap-2">
										<span class="badge shadow-sm" :class="getStatusClassBadge(campaign.status)">
											<i class="me-1" :class="getStatusIconBadge(campaign.status)"></i>{{ getStatusLabel(campaign.status) }}
										</span>
										<span v-if="campaign.personalRegistrationLabel" class="badge bg-light text-dark border shadow-sm">{{ campaign.personalRegistrationLabel }}</span>
									</div>
								</div>

								<div class="card-body p-4 d-flex flex-column">
									<div class="d-flex align-items-center gap-2 mb-3">
										<div class="avatar-sm bg-primary bg-opacity-10 text-primary rounded-circle d-flex align-items-center justify-content-center fw-bold small">
											{{ getCoordinatorInitial(campaign.coordinatorName) }}
										</div>
										<span class="small text-muted text-truncate">{{ campaign.coordinatorName }}</span>
									</div>

									<!-- Title & Desc -->
									<h5 class="fw-bold mb-2 text-truncate-2" style="min-height: 48px;"><router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="text-dark text-decoration-none">{{ campaign.title }}</router-link></h5>
									<p class="text-muted small mb-3 text-truncate-2 flex-grow-1">{{ campaign.description }}</p>

									<!-- Meta -->
									<div class="d-flex flex-column gap-2 small text-muted mb-4">
										<div class="d-flex align-items-center gap-2 text-truncate">
											<i class="fa-solid fa-location-dot text-danger" style="width: 16px;"></i>
											<span class="text-truncate">{{ campaign.location }}</span>
										</div>
										<div class="d-flex align-items-center gap-2">
											<i class="fa-regular fa-calendar text-primary" style="width: 16px;"></i>
											<span>{{ campaign.startDate }} — {{ campaign.endDate }}</span>
										</div>
									</div>

									<!-- Progress -->
									<div class="mt-auto">
										<div class="d-flex justify-content-between align-items-end mb-1 small">
											<span class="fw-medium text-dark">{{ campaign.registered }} <span class="text-muted fw-normal">/ {{ campaign.maxVolunteers }} {{ $t('common.volunteerShort') }}</span></span>
											<span class="fw-bold" :class="getProgressColor(campaign)">{{ getProgress(campaign) }}%</span>
										</div>
										<div class="progress" style="height: 6px;">
											<div class="progress-bar" :class="`bg-${getProgressColorClass(campaign)}`" :style="{ width: getProgress(campaign) + '%' }"></div>
										</div>
										<div class="d-flex gap-2 mt-3 position-relative z-2" v-if="canLoadRecommendations">
											<button class="btn btn-outline-dark btn-sm rounded-pill px-3" @click="openCampaignCompare(campaign)">
												<i class="fa-solid fa-table-columns me-1"></i>So sánh
											</button>
											<router-link :to="`/chi-tiet-chien-dich/${campaign.id}`" class="btn btn-primary btn-sm rounded-pill px-3">
												Xem chi tiết
											</router-link>
										</div>
									</div>
								</div>
							</div>
						</div>

						<!-- Empty State -->
						<div class="col-12" v-if="sortedCampaigns.length === 0">
							<div class="card border-0 shadow-sm text-center py-5">
								<div class="card-body">
									<i class="fa-solid fa-search fs-1 text-muted opacity-25 mb-3"></i>
									<h5 class="fw-bold">{{ $t('campaignList.noCampaignFound') }}</h5>
									<p class="text-muted">{{ $t('campaignList.noCampaignFoundDesc') }}</p>
									<button class="btn btn-outline-primary mt-2" @click="clearFilters">{{ $t('campaignList.clearFilters') }}</button>
								</div>
							</div>
						</div>
					</div>

					<!-- Pagination -->
					<nav class="mt-5" v-if="sortedCampaigns.length > 0">
						<ul class="pagination justify-content-center border-0">
							<li class="page-item disabled"><a class="page-link border-0 shadow-sm rounded-start-pill px-3" href="#">{{ $t('campaignList.prev') }}</a></li>
							<li class="page-item active"><a class="page-link border-0 shadow-sm" href="#">1</a></li>
							<li class="page-item disabled"><a class="page-link border-0 shadow-sm rounded-end-pill px-3" href="#">{{ $t('campaignList.nextPage') }}</a></li>
						</ul>
					</nav>
				</div>
			</div>
		</div>

		<!-- Mobile Filter Offcanvas -->
		<div class="offcanvas offcanvas-bottom rounded-top-4" style="height: 85vh;" tabindex="-1" id="filterOffcanvas">
			<div class="offcanvas-header border-bottom py-3">
				<h5 class="offcanvas-title fw-bold"><i class="fa-solid fa-filter me-2 text-primary"></i>{{ $t('campaignList.filters') }}</h5>
				<button type="button" class="btn-close" data-bs-dismiss="offcanvas"></button>
			</div>
			<div class="offcanvas-body">
				<!-- Search -->
				<div class="mb-4">
					<label class="form-label fw-bold small text-muted text-uppercase">{{ $t('campaignList.search') }}</label>
					<div class="input-group">
						<span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-search text-muted small"></i></span>
						<input type="text" class="form-control bg-light border-start-0 ps-0" :placeholder="$t('campaignList.campaignNamePlaceholder')" v-model="filters.search">
					</div>
				</div>

				<!-- Trạng thái -->
				<div class="mb-4">
					<label class="form-label fw-bold small text-muted text-uppercase">{{ $t('campaignList.status') }}</label>
					<div class="d-flex flex-wrap gap-2">
						<div v-for="status in filterMeta.statuses" :key="'mob-' + status.value">
							<input type="checkbox" class="btn-check" :id="'mob-st-' + status.value" :value="status.value" v-model="filters.status">
							<label class="btn btn-outline-secondary btn-sm rounded-pill" :for="'mob-st-' + status.value">{{ getFilterStatusLabel(status.value) }}</label>
						</div>
					</div>
				</div>

				<!-- Lĩnh vực -->
				<div class="mb-4">
					<label class="form-label fw-bold small text-muted text-uppercase">{{ $t('campaignList.field') }}</label>
					<div class="d-flex flex-wrap gap-2">
						<div v-for="cat in filterMeta.categories" :key="'mob-'+cat.value">
							<input type="checkbox" class="btn-check" :id="'mob-cat-'+cat.value" :value="cat.value" v-model="filters.category">
							<label class="btn btn-outline-secondary btn-sm rounded-pill" :for="'mob-cat-'+cat.value">{{ cat.label }}</label>
						</div>
					</div>
				</div>

				<!-- Footer Buttons -->
				<div class="d-flex gap-2 mt-5">
					<button class="btn btn-light w-50" @click="clearFilters">{{ $t('campaignList.clearFilter') }}</button>
					<button class="btn btn-primary w-50" data-bs-dismiss="offcanvas">{{ $t('common.apply') }} ({{ sortedCampaigns.length }})</button>
				</div>
			</div>
		</div>

		<div v-if="showCompareModal" class="modal fade show d-block" tabindex="-1" role="dialog" aria-modal="true">
			<div class="modal-dialog modal-dialog-centered modal-xl">
				<div class="modal-content border-0 shadow">
					<div class="modal-header border-0 pb-0">
						<div>
							<div class="small text-muted">{{ $t('campaignList.compare.modalSubtitle') }}</div>
							<h5 class="modal-title fw-bold mt-1">{{ compareCampaign?.title || $t('campaignList.defaultCategory') }}</h5>
						</div>
						<button type="button" class="btn-close" @click="closeCampaignCompare"></button>
					</div>
					<div class="modal-body pt-3">
						<div v-if="compareLoading" class="text-center py-5">
							<div class="spinner-border text-primary mb-3" role="status"></div>
							<div class="text-muted">{{ $t('campaignList.compare.preparing') }}</div>
						</div>
						<template v-else-if="compareCampaign">
							<div class="compare-overview mb-4">
								<div class="compare-overview-title">{{ $t('campaignList.compare.overview') }}</div>
								<div class="compare-overview-text">
									{{ compareCampaign.compareSummary }}
								</div>
							</div>

							<div class="compare-table-wrap">
								<table class="compare-table">
									<thead>
										<tr>
											<th>{{ $t('campaignList.compare.criteria') }}</th>
											<th>{{ $t('campaignList.compare.campaign') }}</th>
											<th>{{ $t('campaignList.compare.matchLevel') }}</th>
											<th>{{ $t('campaignList.compare.profile') }}</th>
										</tr>
									</thead>
									<tbody>
										<tr v-for="row in compareRows" :key="row.label">
											<td class="compare-cell-label">{{ row.label }}</td>
											<td class="compare-cell-main">
												<div class="compare-main">{{ row.campaign }}</div>
												<div v-if="row.campaignHelper" class="compare-helper">{{ row.campaignHelper }}</div>
											</td>
											<td class="compare-cell-status">
												<span class="compare-badge" :class="getCompareBadgeClass(row.percent)">{{ row.statusLabel }}</span>
											</td>
											<td class="compare-cell-main">
												<div class="compare-main">{{ row.profile }}</div>
												<div v-if="row.profileHelper" class="compare-helper">{{ row.profileHelper }}</div>
											</td>
										</tr>
									</tbody>
								</table>
							</div>

							<div class="compare-detail-grid mt-3">
								<div class="compare-detail-card">
									<div class="compare-detail-title">{{ $t('campaignList.compare.matchedSkills') }}</div>
									<div v-if="compareSkillSummary.noRequirement" class="small text-muted">
										{{ $t('campaignList.compare.noSkillRequirement') }}
									</div>
									<div v-else-if="compareSkillSummary.matched.length" class="compare-chip-wrap">
										<span v-for="skill in compareSkillSummary.matched" :key="'cmp-skill-' + skill" class="compare-chip compare-chip-good">{{ skill }}</span>
									</div>
									<div v-else class="small text-muted">{{ $t('campaignList.compare.noMatchedSkills') }}</div>
								</div>

								<div class="compare-detail-card">
									<div class="compare-detail-title">{{ $t('campaignList.compare.missingSkills') }}</div>
									<div v-if="compareSkillSummary.noRequirement" class="small text-muted">
										{{ $t('campaignList.compare.noMissingSkillsBecauseNoRequirement') }}
									</div>
									<div v-else-if="compareSkillSummary.missing.length" class="compare-chip-wrap">
										<span v-for="skill in compareSkillSummary.missing" :key="'cmp-missing-skill-' + skill" class="compare-chip compare-chip-warn">{{ skill }}</span>
									</div>
									<div v-else class="small text-muted">{{ $t('campaignList.compare.hasAllSkills') }}</div>
								</div>

								<div class="compare-detail-card">
									<div class="compare-detail-title">{{ $t('campaignList.compare.matchedDays') }}</div>
									<div v-if="compareDaySummary.matched.length" class="compare-chip-wrap">
										<span v-for="day in compareDaySummary.matched" :key="'cmp-day-' + day" class="compare-chip compare-chip-good">{{ day }}</span>
									</div>
									<div v-else class="small text-muted">{{ $t('campaignList.compare.noMatchedDays') }}</div>
								</div>

								<div class="compare-detail-card">
									<div class="compare-detail-title">{{ $t('campaignList.compare.missingDays') }}</div>
									<div v-if="compareDaySummary.missing.length" class="compare-chip-wrap">
										<span v-for="day in compareDaySummary.missing" :key="'cmp-missing-day-' + day" class="compare-chip compare-chip-warn">{{ day }}</span>
									</div>
									<div v-else class="small text-muted">{{ $t('campaignList.compare.allDaysMatched') }}</div>
								</div>
							</div>

							<div v-if="compareHighlights.length" class="compare-highlights mt-3">
								<div class="fw-semibold mb-2">{{ $t('campaignList.compare.highlights') }}</div>
								<div v-for="highlight in compareHighlights" :key="highlight" class="small text-muted mb-1">
									<i class="fa-solid fa-circle-info text-primary me-2"></i>{{ highlight }}
								</div>
							</div>
						</template>
					</div>
					<div class="modal-footer border-0 pt-0">
						<button type="button" class="btn btn-light rounded-pill px-4" @click="closeCampaignCompare">{{ $t('common.close') }}</button>
						<router-link v-if="compareCampaign" :to="`/chi-tiet-chien-dich/${compareCampaign.id}`" class="btn btn-primary rounded-pill px-4">
							{{ $t('campaignList.compare.viewCampaignDetail') }}
						</router-link>
					</div>
				</div>
			</div>
		</div>
		<div v-if="showCompareModal" class="modal-backdrop fade show" @click="closeCampaignCompare"></div>

	</div>
</template>

<script>
import api from '@/services/api.js';
import { hasPermission } from '@/utils/permissions';

export default {
	name: 'DanhSachChienDich',
	inject: ['toast'],
	data() {
		return {
			loading: false,
			sortBy: 'newest',
			searchKeyword: '',
			filterMeta: {
				statuses: [],
				categories: [],
				locations: [],
				creators: [],
			},
			filters: {
				search: '',
				status: [],
				category: [],
				location: '',
				coordinator: ''
			},
			campaigns: [],
			recommendationLoading: false,
			recommendedCampaigns: [],
			recommendationFilters: {
				nearbyOnly: false,
				priority: '',
			},
			showCompareModal: false,
			compareLoading: false,
			compareCampaign: null,
			volunteerProfile: null,
			skillCatalog: [],
			areaCatalog: [],
			searchDebounceTimer: null,
			suspendFilterReload: false,
			suspendRouteWatcher: false,
		}
	},
	computed: {
		sortedCampaigns() {
			const arr = [...this.campaigns];
			if (this.sortBy === 'urgent') {
				const priorityVal = { urgent: 3, high: 2, medium: 1, low: 0 };
				arr.sort((a, b) => priorityVal[b.priority] - priorityVal[a.priority]);
			} else if (this.sortBy === 'soonest') {
				arr.sort((a, b) => a.startDateRaw.localeCompare(b.startDateRaw));
			} else {
				arr.sort((a, b) => b.id - a.id);
			}
			return arr;
		},
		currentUser() {
			try {
				return JSON.parse(localStorage.getItem('user') || 'null');
			} catch (_error) {
				return null;
			}
		},
		canLoadRecommendations() {
			return !!localStorage.getItem('token')
				&& this.currentUser?.vai_tro === 'tinh_nguyen_vien'
				&& hasPermission(this.currentUser, 'ai_recommendation.view');
		},
		compareSkillSummary() {
			if (!this.compareCampaign || !this.volunteerProfile) return { matched: [], missing: [], noRequirement: false };
			const campaignSkills = this.compareCampaign.skills || [];
			const profileSkills = this.volunteerProfile.skillNames || [];
			return {
				noRequirement: campaignSkills.length === 0,
				matched: profileSkills.filter((skill) => campaignSkills.includes(skill)),
				missing: campaignSkills.filter((skill) => !profileSkills.includes(skill)),
			};
		},
		compareDaySummary() {
			if (!this.compareCampaign || !this.volunteerProfile) return { matched: [], missing: [] };
			const campaignDays = this.getCampaignWeekdayLabels(this.compareCampaign.startDateRaw, this.compareCampaign.endDateRaw);
			const volunteerDays = this.normalizeVolunteerDayLabels(this.volunteerProfile.availability || []);
			return {
				matched: campaignDays.filter((day) => volunteerDays.includes(day)),
				missing: campaignDays.filter((day) => !volunteerDays.includes(day)),
			};
		},
		compareRows() {
			if (!this.compareCampaign || !this.volunteerProfile) return [];

			const skillPercent = this.compareCampaign.skills.length
				? Math.round((this.compareSkillSummary.matched.length / this.compareCampaign.skills.length) * 100)
				: 100;
			const availabilityPercent = this.compareCampaign.dayLabels.length
				? Math.round((this.compareDaySummary.matched.length / this.compareCampaign.dayLabels.length) * 100)
				: 100;
			const distancePercent = this.compareCampaign.distanceScore;
			const overallPercent = this.compareCampaign.matchScore ?? this.buildCompareOverallScore(skillPercent, availabilityPercent, distancePercent);

			return [
				{
					label: this.$t('campaignList.compare.skillLabel'),
					campaign: this.compareCampaign.skills.length ? this.compareCampaign.skills.join(', ') : this.$t('campaignList.compare.noSpecificSkillRequirement'),
					campaignHelper: this.compareCampaign.skills.length ? this.$t('campaignList.compare.campaignNeedsSkills', { count: this.compareCampaign.skills.length }) : '',
					profile: this.volunteerProfile.skillNames.length ? this.volunteerProfile.skillNames.join(', ') : this.$t('campaignList.compare.profileNoSkills'),
					profileHelper: this.compareSkillSummary.noRequirement
						? this.$t('campaignList.compare.skillNotRestricted')
						: this.$t('campaignList.compare.skillMatchFraction', { matched: this.compareSkillSummary.matched.length, total: this.compareCampaign.skills.length }),
					percent: skillPercent,
					statusLabel: this.$t('campaignList.compare.percentMatch', { percent: skillPercent }),
				},
				{
					label: this.$t('campaignList.compare.locationLabel'),
					campaign: this.compareCampaign.location || this.$t('campaignList.compare.noLocation'),
					campaignHelper: this.compareCampaign.areaText || '',
					profile: this.volunteerProfile.areaText || this.$t('campaignList.compare.profileNoArea'),
					profileHelper: this.compareCampaign.distanceText
						? this.$t('campaignList.compare.distanceToCampaign', { distance: this.compareCampaign.distanceText })
						: this.$t('campaignList.compare.distanceUnavailable'),
					percent: distancePercent,
					statusLabel: this.$t('campaignList.compare.percentNear', { percent: this.compareCampaign.distanceText ? distancePercent : 0 }),
				},
				{
					label: this.$t('campaignList.compare.timeLabel'),
					campaign: this.compareCampaign.dateText,
					campaignHelper: this.compareCampaign.weekdayRangeText,
					profile: this.volunteerProfile.availabilityText || this.$t('campaignList.compare.profileNoAvailability'),
					profileHelper: this.$t('campaignList.compare.dayMatchSummary', { matched: this.compareDaySummary.matched.length, missing: this.compareDaySummary.missing.length }),
					percent: availabilityPercent,
					statusLabel: this.$t('campaignList.compare.percentMatch', { percent: availabilityPercent }),
				},
				{
					label: this.$t('campaignList.compare.overallLabel'),
					campaign: this.compareCampaign.priorityLabel || this.$t('campaignList.compare.notSpecified'),
					campaignHelper: this.$t('campaignList.compare.capacityText', { min: this.compareCampaign.minVolunteers, max: this.compareCampaign.maxVolunteers }),
					profile: this.$t('campaignList.compare.currentProfile'),
					profileHelper: this.$t('campaignList.compare.profileOverallFit', { percent: overallPercent }),
					percent: overallPercent,
					statusLabel: this.$t('campaignList.compare.percentOverall', { percent: overallPercent }),
				},
			];
		},
		compareHighlights() {
			if (!this.compareCampaign || !this.volunteerProfile) return [];
			const highlights = [];
			if (this.compareSkillSummary.noRequirement) {
				highlights.push(this.$t('campaignList.compare.highlightNoSkillRequirement'));
			} else if (this.compareSkillSummary.matched.length) {
				highlights.push(this.$t('campaignList.compare.highlightMatchedSkills', { skills: this.compareSkillSummary.matched.join(', ') }));
			}
			if (!this.compareSkillSummary.noRequirement && this.compareSkillSummary.missing.length) {
				highlights.push(this.$t('campaignList.compare.highlightMissingSkills', { skills: this.compareSkillSummary.missing.join(', ') }));
			}
			if (this.compareCampaign.distanceText) {
				highlights.push(this.$t('campaignList.compare.highlightDistance', { distance: this.compareCampaign.distanceText }));
			}
			if (this.compareDaySummary.missing.length) {
				highlights.push(this.$t('campaignList.compare.highlightMissingDays', { days: this.compareDaySummary.missing.join(', ') }));
			}
			return highlights.slice(0, 4);
		},
	},
	async mounted() {
		this.syncFiltersFromRoute();
		await Promise.all([this.loadFilterMeta(), this.loadCampaigns()]);
		if (this.canLoadRecommendations) {
			await Promise.all([this.loadRecommendations(), this.loadVolunteerComparisonProfile()]);
		}
	},
	beforeUnmount() {
		if (this.searchDebounceTimer) {
			clearTimeout(this.searchDebounceTimer);
		}
	},
	watch: {
		'$route.query': {
			deep: true,
			handler() {
				if (this.suspendRouteWatcher) return;
				this.syncFiltersFromRoute();
				this.loadCampaigns();
			},
		},
		'filters.status': {
			deep: true,
			handler() {
				if (this.suspendFilterReload) return;
				this.loadCampaigns();
			},
		},
		'filters.category': {
			deep: true,
			handler() {
				if (this.suspendFilterReload) return;
				this.loadCampaigns();
			},
		},
		'filters.location'() {
			if (this.suspendFilterReload) return;
			this.loadCampaigns();
		},
		'filters.coordinator'() {
			if (this.suspendFilterReload) return;
			this.loadCampaigns();
		},
		'filters.search'(value, oldValue) {
			if (this.suspendFilterReload) return;
			if (value === this.searchKeyword && oldValue === undefined) {
				return;
			}
			if (this.searchDebounceTimer) {
				clearTimeout(this.searchDebounceTimer);
			}
			this.searchDebounceTimer = setTimeout(() => {
				this.loadCampaigns();
			}, 300);
		},
		sortBy() {
			this.syncRouteQuery();
		},
	},
	methods: {
		async loadFilterMeta() {
			try {
				const res = await api.get('/chien-dich/bo-loc');
				if (res.data?.status === 1) {
					this.filterMeta = {
						statuses: this.buildStatusFilterMeta(res.data.data?.statuses || []),
						categories: res.data.data?.categories || [],
						locations: res.data.data?.locations || [],
						creators: res.data.data?.creators || [],
					};
				}
			} catch (error) {
				this.showToast(
					'error',
					this.$t('common.error'),
					error.response?.data?.message || this.$t('campaignList.loadErrorMessage')
				);
			}
		},
		syncFiltersFromRoute() {
			const query = this.$route.query || {};
			const keyword = typeof query.name === 'string' ? query.name.trim() : '';
			const statuses = typeof query.status === 'string' && query.status.trim()
				? query.status.split(',').map(item => item.trim()).filter(Boolean)
				: [];
			const categories = typeof query.category === 'string' && query.category.trim()
				? query.category.split(',').map(item => item.trim()).filter(Boolean)
				: [];

			this.suspendFilterReload = true;
			this.searchKeyword = keyword;
			this.sortBy = typeof query.sort === 'string' && query.sort.trim() ? query.sort : 'newest';
			this.filters = {
				search: keyword,
				status: statuses,
				category: categories,
				location: typeof query.location === 'string' ? query.location : '',
				coordinator: typeof query.coordinator === 'string' ? query.coordinator : '',
			};
			this.$nextTick(() => {
				this.suspendFilterReload = false;
			});
		},
		buildRouteQuery() {
			const query = {};
			const keyword = this.filters.search.trim() || this.searchKeyword.trim();
			if (keyword) query.name = keyword;
			if (this.filters.status.length) query.status = this.filters.status.join(',');
			if (this.filters.category.length) query.category = this.filters.category.join(',');
			if (this.filters.location) query.location = this.filters.location;
			if (this.filters.coordinator) query.coordinator = this.filters.coordinator;
			if (this.sortBy && this.sortBy !== 'newest') query.sort = this.sortBy;
			return query;
		},
		async syncRouteQuery() {
			const currentQuery = JSON.stringify(this.$route.query || {});
			const nextQuery = JSON.stringify(this.buildRouteQuery());
			if (currentQuery === nextQuery) return;
			this.suspendRouteWatcher = true;
			try {
				await this.$router.replace({ path: this.$route.path, query: JSON.parse(nextQuery) });
			} finally {
				this.suspendRouteWatcher = false;
			}
		},
		async loadCampaigns() {
			this.loading = true;
			try {
				await this.syncRouteQuery();

				const params = {};
				const routeKeyword = this.searchKeyword.trim();
				const filterKeyword = this.filters.search.trim();
				const effectiveKeyword = filterKeyword || routeKeyword;

				if (effectiveKeyword) params.tu_khoa = effectiveKeyword;
				if (this.filters.status.length) {
					params.trang_thai = this.filters.status.map(this.mapStatusToApi).join(',');
				}
				if (this.filters.category.length) {
					params.loai_chien_dich_ids = this.filters.category.join(',');
				}
				if (this.filters.location) params.dia_diem = this.filters.location;
				if (this.filters.coordinator) params.nguoi_tao_id = this.filters.coordinator;

				const res = await api.get('/chien-dich', { params });
				this.campaigns = (res.data?.data || []).map(item => this.mapCampaignFromApi(item));
				this.filterMeta = {
					...this.filterMeta,
					statuses: this.buildStatusFilterMetaFromCampaigns(this.campaigns),
				};
			} catch (error) {
				this.showToast(
					'error',
					this.$t('common.error'),
					error.response?.data?.message || this.$t('campaignList.loadErrorMessage')
				);
			} finally {
				this.loading = false;
			}
		},
		async loadRecommendations() {
			if (!this.canLoadRecommendations) {
				this.recommendedCampaigns = [];
				return;
			}

			this.recommendationLoading = true;
				try {
					const params = {
						type: 'chien_dich',
						limit: 6,
					};
					if (this.recommendationFilters.nearbyOnly) params.nearby_only = 1;
					if (this.recommendationFilters.priority) params.priority = this.recommendationFilters.priority;

					const res = await api.get('/goi-y', { params });
				this.recommendedCampaigns = (res.data?.data || []).map((item) => ({
					id: item.id,
					title: item.tieu_de || '—',
					description: item.mo_ta || '',
					categoryLabel: item.loai_chien_dich?.ten || 'Chiến dịch',
					location: item.dia_diem || '—',
					startDate: this.formatDate(item.ngay_bat_dau),
					endDate: this.formatDate(item.ngay_ket_thuc),
					color: this.getBannerColor(this.mapPriority(item.muc_do_uu_tien)),
					coverUrl: null,
					matchScore: Math.round(item.final_score || 0),
					matchLabel: this.getRecommendationMatchLabel(item.match_level),
					reasons: item.reasons || [],
					warnings: item.warnings || [],
					recommendationBadges: item.badges || [],
						breakdown: {
							skill: Math.round(item.score_breakdown?.skill || 0),
							availability: Math.round(item.score_breakdown?.availability || 0),
							distance: Math.round(item.score_breakdown?.distance || 0),
							reliability: Math.round(item.score_breakdown?.reliability || 0),
							profileStrength: Math.round(item.score_breakdown?.profile_strength || 0),
						},
					skills: (item.ky_nangs || []).map((skill) => skill.ten).filter(Boolean),
					startDateRaw: item.ngay_bat_dau || '',
					endDateRaw: item.ngay_ket_thuc || '',
					priority: this.mapPriority(item.muc_do_uu_tien),
					minVolunteers: item.so_luong_toi_thieu || 1,
					maxVolunteers: item.so_luong_toi_da || 0,
					areaText: item.khu_vuc?.ten || '',
					distanceText: item.distance_km !== null && item.distance_km !== undefined ? `${item.distance_km} km` : '',
					distanceValue: item.distance_km !== null && item.distance_km !== undefined ? Number(item.distance_km) : null,
				}));
			} catch (error) {
				this.recommendedCampaigns = [];
				this.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('campaignList.recommendation.loadError'));
			} finally {
				this.recommendationLoading = false;
			}
		},
		async loadVolunteerComparisonProfile() {
			try {
				const [profileRes, infoRes, skillRes, areaRes] = await Promise.all([
					api.get('/nguoi-dung/ho-so-nang-luc'),
					api.get('/nguoi-dung/thong-tin'),
					api.get('/danh-muc/ky-nang'),
					api.get('/danh-muc/khu-vuc'),
				]);

				this.skillCatalog = Array.isArray(skillRes.data?.data) ? skillRes.data.data : [];
				this.areaCatalog = Array.isArray(areaRes.data?.data) ? areaRes.data.data : [];

				const profile = profileRes.data?.data || {};
				const info = infoRes.data?.data || {};
				const skillNames = (profile.ky_nang_ids || [])
					.map((id) => this.skillCatalog.find((item) => Number(item.id) === Number(id))?.ten)
					.filter(Boolean);
				const areaNames = (profile.khu_vuc_ids || [])
					.map((id) => this.areaCatalog.find((item) => Number(item.id) === Number(id))?.ten)
					.filter(Boolean);

				this.volunteerProfile = {
					skillIds: profile.ky_nang_ids || [],
					skillNames,
					areaIds: profile.khu_vuc_ids || [],
					areaText: areaNames.join(', '),
					availability: profile.lich_ranh || [],
					availabilityText: this.normalizeVolunteerDayLabels(profile.lich_ranh || []).join(', '),
					viDo: info.vi_do !== null && info.vi_do !== undefined ? Number(info.vi_do) : null,
					kinhDo: info.kinh_do !== null && info.kinh_do !== undefined ? Number(info.kinh_do) : null,
				};
			} catch (_error) {
				this.volunteerProfile = null;
			}
		},
		async openCampaignCompare(campaign) {
			this.showCompareModal = true;
			this.compareLoading = true;
			this.compareCampaign = null;
			try {
				if (!this.volunteerProfile) {
					await this.loadVolunteerComparisonProfile();
				}
				const res = await api.get(`/chien-dich/${campaign.id}`);
				const detail = res.data?.data || {};
				const matchedRecommendation = this.recommendedCampaigns.find((item) => Number(item.id) === Number(campaign.id));
				const distanceValue = this.calculateDistanceKm(
					this.volunteerProfile?.viDo,
					this.volunteerProfile?.kinhDo,
					detail.vi_do !== null && detail.vi_do !== undefined ? Number(detail.vi_do) : null,
					detail.kinh_do !== null && detail.kinh_do !== undefined ? Number(detail.kinh_do) : null,
				);

				this.compareCampaign = {
					id: detail.id || campaign.id,
					title: detail.tieu_de || campaign.title,
					location: detail.dia_diem || campaign.location,
					areaText: '',
					skills: (detail.ky_nangs || []).map((skill) => skill.ten).filter(Boolean),
					startDateRaw: detail.ngay_bat_dau || campaign.startDateRaw || '',
					endDateRaw: detail.ngay_ket_thuc || campaign.endDateRaw || '',
					dateText: this.buildCampaignDateText(detail.ngay_bat_dau || campaign.startDateRaw, detail.ngay_ket_thuc || campaign.endDateRaw),
					weekdayRangeText: this.buildCampaignWeekdayRangeText(detail.ngay_bat_dau || campaign.startDateRaw, detail.ngay_ket_thuc || campaign.endDateRaw),
					dayLabels: this.getCampaignWeekdayLabels(detail.ngay_bat_dau || campaign.startDateRaw, detail.ngay_ket_thuc || campaign.endDateRaw),
					priorityLabel: this.getPriorityLabel(this.mapPriority(detail.muc_do_uu_tien || campaign.priority)),
					minVolunteers: detail.so_luong_toi_thieu || campaign.minVolunteers || 1,
					maxVolunteers: detail.so_luong_toi_da || campaign.maxVolunteers || 0,
					matchScore: matchedRecommendation?.matchScore ?? null,
					distanceValue,
					distanceText: distanceValue !== null ? `${distanceValue.toFixed(2)} km` : '',
					distanceScore: this.distanceToPercent(distanceValue),
					compareSummary: matchedRecommendation
						? this.$t('campaignList.compare.summaryWithScore', { score: matchedRecommendation.matchScore })
						: this.$t('campaignList.compare.summaryWithoutScore'),
				};
			} catch (error) {
				this.showToast('error', this.$t('common.error'), error.response?.data?.message || this.$t('campaignList.compare.loadError'));
				this.showCompareModal = false;
			} finally {
				this.compareLoading = false;
			}
		},
		closeCampaignCompare() {
			this.showCompareModal = false;
			this.compareLoading = false;
			this.compareCampaign = null;
		},
		getCompareBadgeClass(percent) {
			if (percent >= 80) return 'compare-badge-good';
			if (percent >= 50) return 'compare-badge-warn';
			if (percent > 0) return 'compare-badge-bad';
			return 'compare-badge-muted';
		},
		getWeekdayLabel(dateString) {
			if (!dateString) return '';
			const date = new Date(dateString);
			if (Number.isNaN(date.getTime())) return '';
			return [
				this.$t('common.weekdays.sunday'),
				this.$t('common.weekdays.monday'),
				this.$t('common.weekdays.tuesday'),
				this.$t('common.weekdays.wednesday'),
				this.$t('common.weekdays.thursday'),
				this.$t('common.weekdays.friday'),
				this.$t('common.weekdays.saturday'),
			][date.getDay()] || '';
		},
		buildCampaignDateText(startDate, endDate) {
			const start = this.formatShortDate(startDate);
			const end = this.formatShortDate(endDate);
			if (start && end) return `${start} - ${end}`;
			return start || end || this.$t('campaignList.compare.noSpecificDate');
		},
		buildCampaignWeekdayRangeText(startDate, endDate) {
			const start = this.formatShortDate(startDate);
			const end = this.formatShortDate(endDate);
			const startWeekday = this.getWeekdayLabel(startDate);
			const endWeekday = this.getWeekdayLabel(endDate);
			if (start && end && startWeekday && endWeekday) {
				return `${start} (${startWeekday}) đến ${end} (${endWeekday})`;
			}
			return '';
		},
		formatShortDate(dateString) {
			if (!dateString) return '';
			const date = new Date(dateString);
			if (Number.isNaN(date.getTime())) return '';
			return `${String(date.getDate()).padStart(2, '0')}-${String(date.getMonth() + 1).padStart(2, '0')}-${date.getFullYear()}`;
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
			};
			return [...new Set((days || []).map((day) => dayMap[String(day || '').trim().toLowerCase()] || '').filter(Boolean))];
		},
		distanceToPercent(distanceKm) {
			if (distanceKm === null || distanceKm === undefined || Number.isNaN(distanceKm)) return 0;
			if (distanceKm <= 3) return 100;
			if (distanceKm <= 10) return Math.round(100 - ((distanceKm - 3) / 7) * 30);
			if (distanceKm <= 20) return Math.round(70 - ((distanceKm - 10) / 10) * 30);
			return 10;
		},
		buildCompareOverallScore(skillPercent, availabilityPercent, distancePercent) {
			return Math.round((distancePercent * 0.4) + (skillPercent * 0.3) + (availabilityPercent * 0.2) + 5);
		},
		calculateDistanceKm(lat1, lon1, lat2, lon2) {
			if ([lat1, lon1, lat2, lon2].some((value) => value === null || value === undefined || Number.isNaN(Number(value)))) {
				return null;
			}
			const toRad = (value) => (value * Math.PI) / 180;
			const earthRadiusKm = 6371;
			const dLat = toRad(lat2 - lat1);
			const dLon = toRad(lon2 - lon1);
			const a = Math.sin(dLat / 2) ** 2
				+ Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
			const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
			return earthRadiusKm * c;
		},
		toggleRecommendationNearby() {
			this.recommendationFilters.nearbyOnly = !this.recommendationFilters.nearbyOnly;
			this.loadRecommendations();
		},
		getRecommendationMatchLabel(level) {
			return {
				rat_phu_hop: this.$t('campaignList.recommendation.matchVeryGood'),
				phu_hop: this.$t('campaignList.recommendation.matchGood'),
				can_nhac: this.$t('campaignList.recommendation.matchConsider'),
			}[level] || this.$t('campaignList.recommendation.matchDefault');
		},
		mapCampaignFromApi(item) {
			const status = this.mapCampaignStatus(item);
			const priority = this.mapPriority(item.muc_do_uu_tien);
			const coordinatorId = String(item.nguoi_tao?.id || item.duyet_boi?.id || item.id);
			const coordinatorName = item.nguoi_tao?.ho_ten || item.duyet_boi?.ho_ten || this.$t('campaignList.unknownCreator');
			return {
				id: item.id,
				coordinatorId,
				coordinatorName,
				title: item.tieu_de || this.$t('common.notAvailable'),
				description: item.mo_ta || '',
				category: String(item.loai_chien_dich_id || item.loai_chien_dich?.id || ''),
				categoryLabel: item.loai_chien_dich?.ten || this.$t('campaignList.defaultCategory'),
				priority,
				location: item.dia_diem || this.$t('common.notAvailable'),
				startDate: this.formatDate(item.ngay_bat_dau),
				endDate: this.formatDate(item.ngay_ket_thuc),
				startDateRaw: item.ngay_bat_dau || '',
				endDateRaw: item.ngay_ket_thuc || '',
				maxVolunteers: item.so_luong_toi_da || 0,
				registered: item.so_dang_ky || 0,
				confirmed: item.so_xac_nhan || 0,
				status,
				canRegister: !!item.co_the_dang_ky,
				registrationClosed: !!item.da_het_han_dang_ky,
				color: this.getBannerColor(priority),
				coverUrl: item.anh_bia || null,
				personalRegistrationLabel: this.getRegistrationLabel(item.dang_ky_hien_tai?.trang_thai),
			};
		},
		mapCampaignStatus(item) {
			if (item.display_status) {
				return item.display_status;
			}

			if (item.trang_thai === 'da_duyet' && item.da_het_han_dang_ky) {
				return 'closed_registration';
			}

			const status = item.trang_thai;
			return {
				da_duyet: 'registering',
				dang_dien_ra: 'upcoming',
				hoan_thanh: 'completed',
			}[status] || 'registering';
		},
		buildStatusFilterMeta(statuses = []) {
			const counts = new Map((statuses || []).map((status) => [status.value, Number(status.count || 0)]));
			return [
				{ value: 'registering', count: counts.get('registering') || 0 },
				{ value: 'closed_registration', count: counts.get('closed_registration') || 0 },
				{ value: 'upcoming', count: counts.get('upcoming') || 0 },
				{ value: 'completed', count: counts.get('completed') || 0 },
			];
		},
		buildStatusFilterMetaFromCampaigns(campaigns = []) {
			const counts = campaigns.reduce((accumulator, campaign) => {
				const key = campaign.status || 'registering';
				accumulator[key] = (accumulator[key] || 0) + 1;
				return accumulator;
			}, {});
			return this.buildStatusFilterMeta([
				{ value: 'registering', count: counts.registering || 0 },
				{ value: 'closed_registration', count: counts.closed_registration || 0 },
				{ value: 'upcoming', count: counts.upcoming || 0 },
				{ value: 'completed', count: counts.completed || 0 },
			]);
		},
		mapStatusToApi(status) {
			return status;
		},
		mapPriority(priority) {
			return {
				thap: 'low',
				trung_binh: 'medium',
				cao: 'high',
				khan_cap: 'urgent',
			}[priority] || 'medium';
		},
		getBannerColor(priority) {
			return {
				urgent: 'linear-gradient(135deg, #dc3545, #e35d6a)',
				high: 'linear-gradient(135deg, #fd7e14, #ffc107)',
				medium: 'linear-gradient(135deg, #0d6efd, #0dcaf0)',
				low: 'linear-gradient(135deg, #6c757d, #adb5bd)',
			}[priority] || 'linear-gradient(135deg, #0d6efd, #0dcaf0)';
		},
		getCampaignBannerStyle(campaign) {
			if (campaign.coverUrl) {
				return {
					background: `linear-gradient(rgba(15,23,42,.28), rgba(15,23,42,.28)), url(${campaign.coverUrl}) center/cover`,
				};
			}
			return { background: campaign.color };
		},
		formatDate(date) {
			if (!date) return this.$t('common.notAvailable');
			const d = new Date(date);
			if (Number.isNaN(d.getTime())) return date;
			return d.toLocaleDateString('vi-VN');
		},
		getRegistrationLabel(status) {
			if (!status) return '';
			const translated = this.$t(`campaignRegistration.statuses.${status}`);
			if (translated !== `campaignRegistration.statuses.${status}`) return translated;
			const fallback = this.$t(`statuses.${status}`);
			return fallback !== `statuses.${status}` ? fallback : status;
		},
		getCoordinatorInitial(name) {
			return name.charAt(0).toUpperCase();
		},
		clearSearchQuery() {
			this.$router.push({ path: '/danh-sach-chien-dich' });
		},
		clearFilters() {
			this.suspendFilterReload = true;
			this.filters = { search: this.searchKeyword || '', status: [], category: [], location: '', coordinator: '' };
			this.$nextTick(() => {
				this.suspendFilterReload = false;
				this.loadCampaigns();
			});
		},
		getFilterStatusLabel(status) {
			return {
				registering: this.$t('campaignList.registering'),
				closed_registration: this.$t('campaignList.closedRegistration'),
				upcoming: this.$t('campaignList.upcoming'),
				completed: this.$t('campaignList.ended'),
			}[status] || status;
		},
		getPriorityLabel(p) { return this.$t(`priorities.${p}`) || p; },
		getPriorityClassBadge(p) { return { urgent: 'bg-danger text-white', high: 'bg-warning text-dark', medium: 'bg-info text-dark', low: 'bg-light text-muted' }[p] || 'bg-secondary'; },
		getStatusLabel(s) {
			return {
				closed_registration: this.$t('campaignList.closedRegistration'),
			}[s] || this.$t(`statuses.${s}`) || s;
		},
		getStatusClassBadge(s) { return { registering: 'bg-success text-white', closed_registration: 'bg-warning text-dark', upcoming: 'bg-primary text-white', completed: 'bg-secondary text-white' }[s] || 'bg-secondary'; },
		getStatusIconBadge(s) { return { registering: 'fa-regular fa-clock', closed_registration: 'fa-solid fa-lock', upcoming: 'fa-solid fa-hourglass-start', completed: 'fa-solid fa-check' }[s] || ''; },
		getProgress(c) { return c.maxVolunteers ? Math.round(c.registered / c.maxVolunteers * 100) : 0; },
		getProgressColorClass(c) {
			const p = this.getProgress(c);
			if (p >= 100) return 'secondary';
			if (p >= 80) return 'warning';
			return 'primary';
		},
		getProgressColor(c) {
			const p = this.getProgress(c);
			if (p >= 100) return 'text-secondary';
			if (p >= 80) return 'text-warning';
			return 'text-primary';
		},
		showToast(type, title, message) {
			if (this.toast?.showToast) {
				this.toast.showToast(type, title, message);
			}
		}
	}
}
</script>

<style scoped>
.campaign-hero {
	min-height: 250px;
}
.hero-shape {
	position: absolute;
	border-radius: 50%;
	background: rgba(255, 255, 255, 0.1);
}
.shape-1 {
	width: 500px;
	height: 500px;
	top: -200px;
	right: -100px;
}
.shape-2 {
	width: 300px;
	height: 300px;
	bottom: -150px;
	left: 10%;
}

.campaign-card {
	transition: all 0.3s ease;
}
.campaign-card:hover {
	transform: translateY(-5px);
	box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1) !important;
}
.campaign-card:hover h5 a {
	color: #0d6efd !important;
}

.recommendation-panel {
	background: linear-gradient(135deg, rgba(13, 110, 253, 0.04), rgba(25, 135, 84, 0.04));
}

.recommendation-card {
	box-shadow: 0 10px 24px rgba(13, 110, 253, 0.08);
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.recommendation-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 16px 32px rgba(13, 110, 253, 0.14);
}

.recommend-breakdown {
	border: 1px solid rgba(13, 110, 253, 0.08);
}

.campaign-banner-img {
	height: 160px;
	border-radius: 0.5rem 0.5rem 0 0;
}

.campaign-filter-sidebar {
	position: sticky;
	top: 132px;
	max-height: calc(100vh - 152px);
	overflow: hidden;
}

.campaign-filter-sidebar .card-body {
	max-height: calc(100vh - 216px);
	overflow-y: auto;
}

.avatar-sm {
	width: 24px;
	height: 24px;
	min-width: 24px;
	flex-shrink: 0;
}

.text-truncate-2 {
	display: -webkit-box;
	-webkit-line-clamp: 2;
	line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
}

.btn-check:checked + .btn-outline-secondary {
	background-color: #6c757d;
	color: white;
	border-color: #6c757d;
}

.search-result-banner {
	background:
		radial-gradient(circle at top right, rgba(13, 110, 253, 0.12), transparent 35%),
		linear-gradient(135deg, #ffffff, #f8fbff);
}

.search-banner-shape {
	position: absolute;
	border-radius: 50%;
	background: rgba(13, 110, 253, 0.08);
}

.search-banner-shape-1 {
	width: 220px;
	height: 220px;
	top: -120px;
	right: -60px;
}

.search-banner-shape-2 {
	width: 140px;
	height: 140px;
	bottom: -80px;
	left: 18%;
}

.compare-overview {
	padding: 14px 16px;
	border-radius: 16px;
	background: #f8fafc;
	border: 1px solid #e2e8f0;
}

.compare-overview-title {
	font-size: 13px;
	font-weight: 700;
	color: #334155;
	margin-bottom: 6px;
	text-transform: uppercase;
	letter-spacing: 0.04em;
}

.compare-overview-text {
	color: #0f172a;
	font-size: 15px;
	line-height: 1.6;
}

.compare-table-wrap {
	overflow-x: auto;
	border: 1px solid #e2e8f0;
	border-radius: 16px;
	background: #fff;
}

.compare-table {
	width: 100%;
	border-collapse: collapse;
	min-width: 760px;
}

.compare-table th,
.compare-table td {
	padding: 1rem;
	border-bottom: 1px solid #e2e8f0;
	vertical-align: top;
}

.compare-table thead th {
	background: #f8fafc;
	font-size: 0.78rem;
	font-weight: 700;
	text-transform: uppercase;
	letter-spacing: 0.04em;
	color: #64748b;
}

.compare-table tbody tr:last-child td {
	border-bottom: 0;
}

.compare-cell-label {
	width: 140px;
	font-size: 0.95rem;
	font-weight: 700;
	color: #0f172a;
}

.compare-cell-main {
	min-width: 0;
}

.compare-cell-status {
	width: 150px;
	text-align: center;
}

.compare-main {
	font-size: 0.96rem;
	font-weight: 600;
	color: #0f172a;
	line-height: 1.5;
	word-break: break-word;
}

.compare-helper {
	margin-top: 0.2rem;
	font-size: 0.83rem;
	color: #64748b;
	line-height: 1.45;
}

.compare-badge {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.45rem 0.8rem;
	border-radius: 999px;
	font-size: 0.8rem;
	font-weight: 700;
	white-space: nowrap;
}

.compare-badge-good {
	background: #dcfce7;
	color: #166534;
}

.compare-badge-warn {
	background: #fef3c7;
	color: #92400e;
}

.compare-badge-bad {
	background: #fee2e2;
	color: #991b1b;
}

.compare-badge-muted {
	background: #e5e7eb;
	color: #4b5563;
}

.compare-detail-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 1rem;
}

.compare-detail-card {
	padding: 1rem;
	border-radius: 16px;
	border: 1px solid #e2e8f0;
	background: #f8fafc;
}

.compare-detail-title {
	font-size: 0.9rem;
	font-weight: 700;
	color: #0f172a;
	margin-bottom: 0.75rem;
}

.compare-chip-wrap {
	display: flex;
	flex-wrap: wrap;
	gap: 0.5rem;
}

.compare-chip {
	display: inline-flex;
	align-items: center;
	padding: 0.4rem 0.75rem;
	border-radius: 999px;
	font-size: 0.82rem;
	font-weight: 600;
}

.compare-chip-good {
	background: #dcfce7;
	color: #166534;
}

.compare-chip-warn {
	background: #fef3c7;
	color: #92400e;
}

.compare-highlights {
	padding: 1rem;
	border-radius: 16px;
	border: 1px dashed #cbd5e1;
	background: #f8fafc;
}

@media (max-width: 767.98px) {
	.compare-detail-grid {
		grid-template-columns: 1fr;
	}
}

@media (max-width: 1199.98px) {
	.campaign-filter-sidebar {
		top: 120px;
		max-height: calc(100vh - 140px);
	}

	.campaign-filter-sidebar .card-body {
		max-height: calc(100vh - 204px);
	}
}
</style>
