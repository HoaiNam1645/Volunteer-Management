<template>
	<div class="bg-light min-vh-100 pb-5">
		<div class="container pt-4">
			<!-- Page Header -->
			<PageHeader
				:title="$t('profile.title')"
				icon="fa-solid fa-id-card-clip"
				:breadcrumbs="[{ label: $t('common.home'), to: '/'}, { label: $t('profile.title') }]">
				<template #actions>
					<button class="btn btn-primary shadow-sm" @click="saveProfile" :disabled="!canManageProfile || saving">
						<i class="fa-solid fa-save me-1"></i>{{ saving ? $t('profile.saving') : $t('profile.saveChanges') }}
					</button>
				</template>
			</PageHeader>

			<!-- Alert -->
			<div v-if="localAlertMessage" class="alert alert-dismissible fade show mb-3" :class="localAlertSuccess ? 'alert-success' : 'alert-danger'" role="alert">
				<i :class="localAlertSuccess ? 'fa-solid fa-circle-check' : 'fa-solid fa-exclamation-triangle'" class="me-2"></i>
				{{ localAlertMessage }}
				<button type="button" class="btn-close" @click="localAlertMessage = ''"></button>
			</div>

			<!-- Loading -->
			<div v-if="loading" class="text-center py-5">
				<div class="spinner-border text-primary" role="status"></div>
				<p class="text-muted mt-2 small">{{ $t('common.loading') }}</p>
			</div>

			<!-- Profile Completion -->
			<div class="card border-0 shadow-sm mb-4">
				<div class="card-body p-4">
					<div class="d-flex flex-column flex-sm-row align-items-start align-items-sm-center justify-content-between gap-3 mb-3">
						<div class="d-flex align-items-center gap-3">
							<div class="profile-avatar">
								<img v-if="profile.avatar" :src="profile.avatar" alt="Ảnh đại diện" class="profile-avatar-image">
								<i v-else class="fa-solid fa-user"></i>
							</div>
							<div>
								<h5 class="fw-bold mb-0">{{ profile.name }}</h5>
								<span class="text-muted small">{{ profile.email }}</span>
							</div>
						</div>
						<div class="text-end">
							<span class="small text-muted">{{ $t('profile.completion') }}</span>
							<div class="d-flex align-items-center gap-2">
								<div class="progress flex-grow-1" style="width:120px; height: 8px;">
									<div class="progress-bar bg-success" :style="{ width: profileCompletion + '%' }"></div>
								</div>
								<span class="fw-bold small" :class="profileCompletion >= 80 ? 'text-success' : 'text-warning'">{{ profileCompletion }}%</span>
							</div>
						</div>
					</div>
					<div class="d-flex flex-wrap gap-2" v-if="profileCompletion < 100">
						<span class="badge bg-warning-subtle text-warning px-3 py-2 small" v-for="hint in incompleteSections" :key="hint">
							<i class="fa-solid fa-exclamation-circle me-1"></i>{{ hint }}
						</span>
					</div>
				</div>
			</div>

			<div class="row g-4">
				<!-- LEFT COLUMN -->
				<div class="col-lg-8">
					<!-- Kỹ năng -->
					<div class="card border-0 shadow-sm mb-4" id="skills-section">
						<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between gap-2">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-tools text-primary me-2"></i>{{ $t('profile.skillsTitle') }}</h6>
							<button type="button" class="btn btn-sm btn-outline-primary rounded-pill px-3" :disabled="!canManageProfile || creatingSkill" @click="createSkillFromInput">
								<span v-if="creatingSkill" class="spinner-border spinner-border-sm me-1" role="status"></span>
								<i v-else class="fa-solid fa-plus me-1"></i>{{ $t('common.add') }}
							</button>
						</div>
						<div class="card-body">
							<p class="text-muted small mb-3">{{ $t('profile.skillsDesc') }}</p>
							<div class="d-flex flex-wrap gap-2 mb-3">
								<span v-for="skill in availableSkills" :key="skill.id"
									class="badge rounded-pill px-3 py-2 skill-tag"
									:class="profile.skills.includes(skill.id) ? 'bg-primary text-white shadow-sm' : 'bg-light text-dark border'"
									style="font-size: 13px; cursor: pointer;"
									@click="toggleSkill(skill.id)">
									{{ skill.name }}
								</span>
							</div>
							<div class="bg-light rounded-3 p-3">
								<label class="form-label small fw-bold">{{ $t('profile.otherSkillsTitle') }}</label>
								<div class="input-group input-group-sm">
									<input type="text" class="form-control form-control-sm" :class="{ 'is-invalid': skillCreateError }" v-model.trim="profile.otherSkills" :placeholder="$t('profile.otherSkillsPlaceholder')" @keydown.enter.prevent="createSkillFromInput">
									<button type="button" class="btn btn-primary" :disabled="!canManageProfile || creatingSkill" @click="createSkillFromInput">
										<span v-if="creatingSkill" class="spinner-border spinner-border-sm" role="status"></span>
										<i v-else class="fa-solid fa-plus"></i>
									</button>
								</div>
								<div v-if="skillCreateError" class="invalid-feedback d-block">{{ skillCreateError }}</div>
								<div class="form-text">Nhập kỹ năng chưa có trong danh sách rồi bấm thêm để tạo mới và chọn luôn.</div>
							</div>
						</div>
					</div>

					<!-- Kinh nghiệm -->
					<div class="card border-0 shadow-sm mb-4" id="experience-section">
						<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-briefcase text-success me-2"></i>{{ $t('profile.expTitle') }}</h6>
							<button type="button" class="btn btn-sm btn-outline-primary rounded-pill px-3" @click="addExperience">
								<i class="fa-solid fa-plus me-1"></i>{{ $t('common.add') }}
							</button>
						</div>
						<div class="card-body p-0">
							<div class="exp-item p-3 border-bottom" v-for="(exp, idx) in profile.experiences" :key="idx">
								<div class="d-flex align-items-start justify-content-between">
									<div class="d-flex gap-3 flex-grow-1">
										<div class="exp-icon" :style="{ background: exp.color }">
											<i class="fa-solid fa-heart-pulse text-white"></i>
										</div>
										<div class="flex-grow-1">
											<div v-if="exp.editing">
												<div class="row g-2 mb-2">
													<div class="col-md-6">
														<input type="text" class="form-control form-control-sm" v-model="exp.title" :placeholder="$t('profile.expNamePlaceholder')">
													</div>
													<div class="col-md-6">
														<input type="text" class="form-control form-control-sm" v-model="exp.org" :placeholder="$t('profile.expOrgPlaceholder')">
													</div>
												</div>
												<div class="row g-2 mb-2">
													<div class="col-md-4">
														<input type="text" class="form-control form-control-sm" v-model="exp.period" :placeholder="$t('profile.expPeriodPlaceholder')">
													</div>
													<div class="col-md-8">
														<input type="text" class="form-control form-control-sm" v-model="exp.desc" :placeholder="$t('profile.expDescPlaceholder')">
													</div>
												</div>
												<button type="button" class="btn btn-sm btn-primary rounded-pill px-3" @click="exp.editing = false">
													<i class="fa-solid fa-check me-1"></i>{{ $t('common.done') }}
												</button>
											</div>
											<div v-else>
												<h6 class="fw-bold small mb-0">{{ exp.title }}</h6>
												<span class="text-muted" style="font-size: 12px;">{{ exp.org }} · {{ exp.period }}</span>
												<p class="text-muted small mb-0 mt-1" v-if="exp.desc">{{ exp.desc }}</p>
											</div>
										</div>
									</div>
									<div class="d-flex gap-1" v-if="!exp.editing">
										<button type="button" class="btn btn-sm btn-light rounded-circle" style="width:28px;height:28px" @click="exp.editing = true">
											<i class="fa-solid fa-pen" style="font-size:10px"></i>
										</button>
										<button type="button" class="btn btn-sm btn-light rounded-circle text-danger" style="width:28px;height:28px" @click="removeExperience(idx)">
											<i class="fa-solid fa-xmark" style="font-size:10px"></i>
										</button>
									</div>
								</div>
							</div>
							<div class="text-center py-4 text-muted small" v-if="profile.experiences.length === 0">
								<i class="fa-solid fa-inbox d-block mb-2" style="font-size:28px; opacity:0.3"></i>
								{{ $t('profile.noExp') }}
							</div>
						</div>
					</div>

					<!-- Chứng chỉ -->
					<div class="card border-0 shadow-sm mb-4" id="certs-section">
						<div class="card-header bg-white border-bottom py-3 d-flex align-items-center justify-content-between">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-certificate text-warning me-2"></i>{{ $t('profile.certTitle') }}</h6>
							<button type="button" class="btn btn-sm btn-outline-warning rounded-pill px-3" @click="addCert">
								<i class="fa-solid fa-plus me-1"></i>{{ $t('common.add') }}
							</button>
						</div>
						<div class="card-body p-0">
							<div class="p-3 border-bottom d-flex align-items-center gap-3" v-for="(cert, idx) in profile.certificates" :key="idx">
								<div class="cert-icon">
									<i class="fa-solid fa-award text-warning"></i>
								</div>
								<div class="flex-grow-1">
									<div v-if="cert.editing">
										<div class="row g-2">
											<div class="col-md-5"><input type="text" class="form-control form-control-sm" v-model="cert.name" :placeholder="$t('profile.certNamePlaceholder')"></div>
											<div class="col-md-4"><input type="text" class="form-control form-control-sm" v-model="cert.issuer" :placeholder="$t('profile.certIssuerPlaceholder')"></div>
											<div class="col-md-3">
												<button type="button" class="btn btn-sm btn-primary rounded-pill px-3 w-100" @click="cert.editing = false">
													<i class="fa-solid fa-check me-1"></i>{{ $t('common.done') }}
												</button>
											</div>
										</div>
									</div>
									<div v-else>
										<span class="fw-bold small">{{ cert.name }}</span>
										<span class="text-muted small"> — {{ cert.issuer }}</span>
									</div>
								</div>
								<button type="button" class="btn btn-sm btn-light rounded-circle text-danger" style="width:28px;height:28px" v-if="!cert.editing" @click="removeCert(idx)">
									<i class="fa-solid fa-xmark" style="font-size:10px"></i>
								</button>
							</div>
							<div class="text-center py-4 text-muted small" v-if="profile.certificates.length === 0">
								<i class="fa-solid fa-certificate d-block mb-2" style="font-size:24px; opacity:0.3"></i>
								{{ $t('profile.noCert') }}
							</div>
						</div>
					</div>
				</div>

				<!-- RIGHT COLUMN -->
				<div class="col-lg-4">
					<!-- Khu vực hoạt động -->
					<div class="card border-0 shadow-sm mb-4" id="region-section">
						<div class="card-header bg-white border-bottom py-3">
							<h6 class="fw-bold mb-0"><i class="fa-solid fa-map-location-dot text-danger me-2"></i>{{ $t('profile.regionTitle') }}</h6>
						</div>
						<div class="card-body">
							<p class="text-muted small mb-3">{{ $t('profile.regionDesc') }}</p>
							<div class="d-flex flex-wrap gap-2">
								<span v-for="r in availableRegions" :key="r.value"
									class="badge rounded-pill px-3 py-2 skill-tag"
									:class="profile.regions.includes(r.value) ? 'bg-danger text-white' : 'bg-light text-dark border'"
									style="font-size: 12px; cursor: pointer;"
									@click="toggleRegion(r.value)">
									<i class="fa-solid fa-location-dot me-1"></i>{{ r.label }}
								</span>
							</div>
						</div>
					</div>

					<!-- Thời gian rảnh -->
					<div class="card border-0 shadow-sm mb-4" id="availability-section">
						<div class="card-header bg-white border-bottom py-3">
							<h6 class="fw-bold mb-0"><i class="fa-regular fa-calendar-check text-info me-2"></i>{{ $t('profile.availTitle') }}</h6>
						</div>
						<div class="card-body">
							<p class="text-muted small mb-3">{{ $t('profile.availDesc') }}</p>
							<div class="d-flex flex-column gap-2">
								<div class="form-check" v-for="day in weekDays" :key="day.value">
									<input class="form-check-input" type="checkbox" :id="'day-' + day.value" :value="day.value" v-model="profile.availability">
									<label class="form-check-label small" :for="'day-' + day.value">{{ day.label }}</label>
								</div>
							</div>
							<hr>
							<label class="form-label small fw-bold">{{ $t('profile.timePrefTitle') }}</label>
							<select class="form-select form-select-sm" v-model="profile.timePreference">
								<option value="sang">{{ $t('profile.timePrefOptions.morning') }}</option>
								<option value="chieu">{{ $t('profile.timePrefOptions.afternoon') }}</option>
								<option value="toi">{{ $t('profile.timePrefOptions.evening') }}</option>
								<option value="ca_ngay">{{ $t('profile.timePrefOptions.full') }}</option>
								<option value="linh_hoat">{{ $t('profile.timePrefOptions.flexible') }}</option>
							</select>
						</div>
					</div>

					<!-- Quick Summary -->
					<div class="card border-0 shadow-sm bg-primary text-white">
						<div class="card-body p-4">
							<h6 class="fw-bold mb-3"><i class="fa-solid fa-chart-simple me-2"></i>{{ $t('profile.summaryTitle') }}</h6>
							<div class="d-flex flex-column gap-3">
								<div class="d-flex justify-content-between">
									<span class="small opacity-75">{{ $t('profile.skillsLabel') }}</span>
									<span class="fw-bold">{{ profile.skills.length }} / {{ availableSkills.length }}</span>
								</div>
								<div class="d-flex justify-content-between">
									<span class="small opacity-75">{{ $t('profile.expLabel') }}</span>
									<span class="fw-bold">{{ profile.experiences.length }} {{ $t('profile.activitiesCount') }}</span>
								</div>
								<div class="d-flex justify-content-between">
									<span class="small opacity-75">{{ $t('profile.regionLabel') }}</span>
									<span class="fw-bold">{{ profile.regions.length }} {{ $t('profile.regionsCount') }}</span>
								</div>
								<div class="d-flex justify-content-between">
									<span class="small opacity-75">{{ $t('profile.availLabel') }}</span>
									<span class="fw-bold">{{ profile.availability.length }} {{ $t('profile.daysPerWeek') }}</span>
								</div>
								<div class="d-flex justify-content-between">
									<span class="small opacity-75">{{ $t('profile.certLabel') }}</span>
									<span class="fw-bold">{{ profile.certificates.length }}</span>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
import PageHeader from '../../components/PageHeader.vue'
import api from '@/services/api.js'
import { hasPermission } from '@/utils/permissions'

export default {
	name: 'HoSoNangLuc',
	inject: ['toast'],
	components: { PageHeader },
	data() {
		return {
			saving: false,
			loading: true,
			creatingSkill: false,
			skillCreateError: '',
			localAlertMessage: '',
			localAlertSuccess: false,
			availableSkills: [],
			availableRegions: [],
			profile: {
				name: '',
				email: '',
				avatar: '',
				skills: [],
				otherSkills: '',
				regions: [],
				availability: [],
				timePreference: 'linh_hoat',
				experiences: [],
				certificates: []
			}
		};
	},
	computed: {
		weekDays() {
			return [
				{ label: this.$t('profile.weekDays.monday'), value: 'thu_hai' },
				{ label: this.$t('profile.weekDays.tuesday'), value: 'thu_ba' },
				{ label: this.$t('profile.weekDays.wednesday'), value: 'thu_tu' },
				{ label: this.$t('profile.weekDays.thursday'), value: 'thu_nam' },
				{ label: this.$t('profile.weekDays.friday'), value: 'thu_sau' },
				{ label: this.$t('profile.weekDays.saturday'), value: 'thu_bay' },
				{ label: this.$t('profile.weekDays.sunday'), value: 'chu_nhat' }
			];
		},
		profileCompletion() {
			let score = 0;
			if (this.profile.skills.length > 0) score += 25;
			if (this.profile.regions.length > 0) score += 25;
			if (this.profile.availability.length > 0) score += 20;
			if (this.profile.experiences.length > 0) score += 20;
			if (this.profile.certificates.length > 0) score += 10;
			return score;
		},
		incompleteSections() {
			const hints = [];
			if (this.profile.skills.length === 0) hints.push(this.$t('profile.incompleteSkills'));
			if (this.profile.regions.length === 0) hints.push(this.$t('profile.incompleteRegions'));
			if (this.profile.availability.length === 0) hints.push(this.$t('profile.incompleteAvail'));
			if (this.profile.experiences.length === 0) hints.push(this.$t('profile.incompleteExp'));
			if (this.profile.certificates.length === 0) hints.push(this.$t('profile.incompleteCert'));
			return hints;
		},
		canManageProfile() {
			try {
				const user = JSON.parse(localStorage.getItem('user') || 'null');
				return hasPermission(user, 'competency_profile.manage');
			} catch (_error) {
				return false;
			}
		}
	},
	async mounted() {
		await this.loadData();
	},
	methods: {
		mapSkillOption(kn) {
			return {
				id: kn.id,
				name: kn.ten,
				icon: kn.bieu_tuong || 'fa-solid fa-star',
			};
		},
		async loadData() {
			this.loading = true;
			try {
				// Load catalogs + profile in parallel
				const [kyNangRes, khuVucRes, profileRes] = await Promise.all([
					api.get('/danh-muc/ky-nang'),
					api.get('/danh-muc/khu-vuc'),
					api.get('/nguoi-dung/ho-so-nang-luc'),
				]);

				// Skills catalog
				if (kyNangRes.data.status === 1) {
					this.availableSkills = kyNangRes.data.data.map((kn) => this.mapSkillOption(kn));
				}

				// Regions catalog
				if (khuVucRes.data.status === 1) {
					this.availableRegions = khuVucRes.data.data.map(kv => ({
						label: kv.ten,
						value: kv.id,
					}));
				}

				// Profile data
				if (profileRes.data.status === 1) {
					const d = profileRes.data.data;
					this.profile.name = d.ho_ten || '';
					this.profile.email = d.email || '';
					this.profile.avatar = d.anh_dai_dien || '';
					this.profile.skills = d.ky_nang_ids || [];
					this.profile.regions = d.khu_vuc_ids || [];
					this.profile.availability = d.lich_ranh || [];
					this.profile.timePreference = d.khung_gio_uu_tien || 'linh_hoat';

					// Map experiences
					this.profile.experiences = (d.kinh_nghiems || []).map(kn => ({
						id: kn.id,
						title: kn.tieu_de,
						org: kn.to_chuc || '',
						period: kn.thoi_gian || '',
						desc: kn.mo_ta || '',
						editing: false,
						color: '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0'),
					}));

					// Map certificates
					this.profile.certificates = (d.chung_chis || []).map(cc => ({
						id: cc.id,
						name: cc.ten,
						issuer: cc.don_vi_cap || '',
						editing: false,
					}));
				}
			} catch (e) {
				console.error('Lỗi tải hồ sơ:', e);
			} finally {
				this.loading = false;
			}
		},
		toggleSkill(id) {
			const idx = this.profile.skills.indexOf(id);
			if (idx > -1) this.profile.skills.splice(idx, 1);
			else this.profile.skills.push(id);
		},
		async createSkillFromInput() {
			const name = String(this.profile.otherSkills || '').trim();
			if (!name) {
				this.skillCreateError = 'Vui lòng nhập tên kỹ năng cần thêm.';
				return;
			}

			this.creatingSkill = true;
			this.skillCreateError = '';

			try {
				const { data } = await api.post('/nguoi-dung/ky-nang', { ten: name });
				const skill = data?.data;
				if (!skill?.id) {
					throw new Error('INVALID_RESPONSE');
				}

				const mappedSkill = this.mapSkillOption(skill);
				const existedIndex = this.availableSkills.findIndex((item) => item.id === mappedSkill.id);
				if (existedIndex > -1) this.availableSkills.splice(existedIndex, 1, mappedSkill);
				else this.availableSkills.push(mappedSkill);
				this.availableSkills.sort((a, b) => a.name.localeCompare(b.name, 'vi'));

				if (!this.profile.skills.includes(mappedSkill.id)) {
					this.profile.skills.push(mappedSkill.id);
				}

				this.profile.otherSkills = '';
				this.toast?.showToast?.('success', 'Thành công!', data?.message || 'Đã thêm kỹ năng mới.');
			} catch (error) {
				const responseData = error.response?.data;
				if (responseData?.errors) {
					const firstKey = Object.keys(responseData.errors)[0];
					this.skillCreateError = responseData.errors[firstKey]?.[0] || 'Dữ liệu không hợp lệ.';
				} else {
					this.skillCreateError = responseData?.message || 'Không thể thêm kỹ năng mới.';
				}
			} finally {
				this.creatingSkill = false;
			}
		},
		toggleRegion(id) {
			const idx = this.profile.regions.indexOf(id);
			if (idx > -1) this.profile.regions.splice(idx, 1);
			else this.profile.regions.push(id);
		},
		addExperience() {
			this.profile.experiences.push({ title: '', org: '', period: '', desc: '', editing: true, color: '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0') });
		},
		removeExperience(idx) {
			this.profile.experiences.splice(idx, 1);
		},
		addCert() {
			this.profile.certificates.push({ name: '', issuer: '', editing: true });
		},
		removeCert(idx) {
			this.profile.certificates.splice(idx, 1);
		},
		async saveProfile() {
			this.saving = true;
			this.localAlertMessage = '';
			try {
				const res = await api.put('/nguoi-dung/ho-so-nang-luc', {
					ky_nang_ids: this.profile.skills,
					khu_vuc_ids: this.profile.regions,
					lich_ranh: this.profile.availability,
					khung_gio_uu_tien: this.profile.timePreference,
					kinh_nghiems: this.profile.experiences
						.filter(e => e.title)
						.map(e => ({
							tieu_de: e.title,
							to_chuc: e.org || null,
							thoi_gian: e.period || null,
							mo_ta: e.desc || null,
						})),
					chung_chis: this.profile.certificates
						.filter(c => c.name)
						.map(c => ({
							ten: c.name,
							don_vi_cap: c.issuer || null,
						})),
				});
				if (res.data.status === 1) {
					if (this.toast) {
						this.toast.showToast('success', 'Thành công!', res.data.message);
					} else {
						this.localAlertMessage = res.data.message;
						this.localAlertSuccess = true;
					}
				}
			} catch (error) {
				this.localAlertSuccess = false;
				let errMsg = 'Không thể kết nối server.';
				if (error.response && error.response.data) {
					const data = error.response.data;
					if (data.errors) {
						const firstKey = Object.keys(data.errors)[0];
						errMsg = data.errors[firstKey][0];
					} else {
						errMsg = data.message || 'Lỗi lưu hồ sơ.';
					}
				}
				
				if (this.toast) {
					this.toast.showToast('error', 'Lỗi', errMsg);
				} else {
					this.localAlertMessage = errMsg;
				}
			} finally {
				this.saving = false;
			}
		}
	}
}
</script>

<style scoped>
.profile-avatar {
	width: 56px;
	height: 56px;
	min-width: 56px;
	overflow: hidden;
	border-radius: 50%;
	background: linear-gradient(135deg, #0d6efd, #6610f2);
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-size: 22px;
}

.profile-avatar-image {
	width: 100%;
	height: 100%;
	object-fit: cover;
	display: block;
}

.skill-tag {
	transition: all 0.15s ease;
	user-select: none;
}
.skill-tag:hover { opacity: 0.85; transform: translateY(-1px); }

.exp-icon {
	width: 40px;
	height: 40px;
	min-width: 40px;
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 16px;
}

.exp-item { transition: background 0.2s; }
.exp-item:hover { background: #f8f9fb; }
.exp-item:last-child { border-bottom: none !important; }

.cert-icon {
	width: 36px;
	height: 36px;
	min-width: 36px;
	border-radius: 50%;
	background: rgba(253, 126, 20, 0.1);
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 16px;
}
</style>
