<template>
    <div class="wrapper">
		<div class="header-wrapper">
            <DinhTrang></DinhTrang>
            <ThanhDieuHuong></ThanhDieuHuong>
		</div>
		<div class="page-wrapper">
			<div class="page-content">
                <router-view></router-view>
            </div>
		</div>
        <ChanTrang></ChanTrang>
        <ToastNotification ref="toast" />
	</div>
</template>
<script>
import DinhTrang from "../components/Dinh_Trang.vue";
import ChanTrang from "../components/Chan_Trang.vue";
import ThanhDieuHuong from "../components/Thanh_Dieu_Huong.vue";
import ToastNotification from "../../components/ToastNotification.vue";
import { refreshCurrentUser } from "../../services/api";
import { getFirstAccessibleUserRoute, hasAnyPermission } from "../../utils/permissions";
import "../../assets/js/bootstrap.bundle.min.js";
import "../../assets/js/jquery.min.js";
import "../../assets/plugins/simplebar/js/simplebar.min.js";
import "../../assets/plugins/metismenu/js/metisMenu.min.js";
import "../../assets/plugins/perfect-scrollbar/js/perfect-scrollbar.js";
import "../../assets/js/index.js";
import "../../assets/js/app.js";
import "../../assets/js/pace.min.js";
export default {
    name        :   "app",
    data() {
        return { toastRef: null };
    },
    provide() {
        return {
            toast: {
                showToast: (type, title, message) => {
                    if (this.$refs.toast && typeof this.$refs.toast[type] === 'function') {
                        this.$refs.toast[type](title, message);
                    }
                }
            }
        };
    },
    mounted() {
        window.addEventListener('focus', this.handleWindowFocus);
    },
    beforeUnmount() {
        window.removeEventListener('focus', this.handleWindowFocus);
    },
    methods: {
        async handleWindowFocus() {
            await refreshCurrentUser({ force: true, silent: true });
            this.redirectIfRouteForbidden();
        },
        redirectIfRouteForbidden() {
            if (!this.$route.meta?.requiresAuth) {
                return;
            }

            let currentUser = null;
            try {
                currentUser = JSON.parse(localStorage.getItem('user') || 'null');
            } catch (_error) {
                currentUser = null;
            }

            if (hasAnyPermission(currentUser, this.$route.meta?.permissions || [])) {
                return;
            }

            const fallbackRoute = getFirstAccessibleUserRoute(currentUser);
            if (fallbackRoute && fallbackRoute !== this.$route.path) {
                this.$router.replace(fallbackRoute);
            }
        },
    },
    watch: {
        '$route'() {
            this.redirectIfRouteForbidden();
        }
    },
    components  :   {
        DinhTrang, ThanhDieuHuong, ChanTrang, ToastNotification
    }
}
</script>
<style>
@import "../../assets/plugins/simplebar/css/simplebar.css";
@import "../../assets/plugins/perfect-scrollbar/css/perfect-scrollbar.css";
@import "../../assets/plugins/metismenu/css/metisMenu.min.css";
@import "../../assets/css/pace.min.css";
@import "../../assets/css/bootstrap.min.css";
@import "../../assets/css/bootstrap-extended.css";
@import url("https://fonts.googleapis.com/css2?family=Roboto:wght@400;500&display=swap");
@import "../../assets/css/app.css";
@import "../../assets/css/icons.css";
@import "../../assets/css/dark-theme.css";
@import "../../assets/css/semi-dark.css";
@import "../../assets/css/header-colors.css";
@import url("https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css");
</style>
