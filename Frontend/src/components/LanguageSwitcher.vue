<template>
	<div class="lang-switcher dropdown px-2 text-dark">
		<a class="d-flex align-items-center nav-link dropdown-toggle dropdown-toggle-nocaret text-dark" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false">
			<img :src="currentLangIcon" alt="language" class="lang-icon me-1 shadow-sm border" width="22" height="15" style="border-radius: 2px;">
			<span class="ms-1 small fw-medium d-none d-xl-inline">{{ currentLangText }}</span>
		</a>
		<ul class="dropdown-menu dropdown-menu-end shadow-sm border-0 mt-2 p-1 lang-menu">
			<li>
				<a class="dropdown-item d-flex align-items-center py-2 px-3 rounded-2" :class="{ 'bg-light text-primary fw-bold': locale === 'vi' }" href="#" @click.prevent="changeLanguage('vi')">
					<img src="https://upload.wikimedia.org/wikipedia/commons/2/21/Flag_of_Vietnam.svg" alt="VI" width="20" height="14" class="me-2 rounded-1 border">
					Tiếng Việt
					<i class="fa-solid fa-check ms-auto text-primary" v-if="locale === 'vi'"></i>
				</a>
			</li>
			<li>
				<a class="dropdown-item d-flex align-items-center py-2 px-3 rounded-2" :class="{ 'bg-light text-primary fw-bold': locale === 'en' }" href="#" @click.prevent="changeLanguage('en')">
					<img src="https://upload.wikimedia.org/wikipedia/commons/a/a4/Flag_of_the_United_States.svg" alt="EN" width="20" height="14" class="me-2 rounded-1 border">
					English
					<i class="fa-solid fa-check ms-auto text-primary" v-if="locale === 'en'"></i>
				</a>
			</li>
		</ul>
	</div>
</template>

<script>
export default {
	name: 'LanguageSwitcher',
	computed: {
		locale() {
			return this.$i18n.locale;
		},
		currentLangIcon() {
			return this.locale === 'vi' 
				? 'https://upload.wikimedia.org/wikipedia/commons/2/21/Flag_of_Vietnam.svg'
				: 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Flag_of_the_United_States.svg';
		},
		currentLangText() {
			return this.locale === 'vi' ? 'Tiếng Việt' : 'English';
		}
	},
	methods: {
		changeLanguage(lang) {
			this.$i18n.locale = lang;
			localStorage.setItem('app-lang', lang);
			// Optional: you can force reload if some components aren't reacting properly
			// location.reload();
		}
	}
}
</script>

<style scoped>
.lang-menu {
	min-width: 150px;
}
.lang-menu .dropdown-item {
	font-size: 14px;
	transition: all 0.2s ease;
}
.lang-menu .dropdown-item:hover {
	background-color: #f8f9fa;
	color: #0d6efd;
}
.lang-icon {
	object-fit: cover;
}
</style>
