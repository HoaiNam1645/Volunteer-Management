import { createRouter, createWebHistory } from "vue-router";
import {
	getFirstAccessibleAdminRoute,
	getFirstAccessibleUserRoute,
	hasAnyPermission,
} from "../utils/permissions";

const routes = [
    {
        path: '/',
        component: () => import('../components/User/Trang_Chu.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/dang-nhap',
        alias: ['/login'],
        component: () => import('../components/User/auth/Trang_Dang_Nhap.vue'),
        meta: { layout: 'auth', guestOnly: true }
    },
    {
        path: '/dang-ky',
        component: () => import('../components/User/auth/Trang_Dang_Ky.vue'),
        meta: { layout: 'auth', guestOnly: true }
    },
    {
        path: '/dang-ky/thanh-cong',
        component: () => import('../components/User/auth/Trang_Dang_Ky_Thanh_Cong.vue'),
        meta: { layout: 'auth', guestOnly: true }
    },
    {
        path: '/quen-mat-khau',
        component: () => import('../components/User/auth/Trang_Quen_Mat_Khau.vue'),
        meta: { layout: 'auth', guestOnly: true }
    },
    {
        path: '/dat-lai-mat-khau/:token',
        component: () => import('../components/User/auth/Trang_Dat_Lai_Mat_Khau.vue'),
        meta: { layout: 'auth', guestOnly: true }
    },
    {
        path: '/xac-thuc-email/:token',
        component: () => import('../components/User/auth/Trang_Xac_Thuc_Email.vue'),
        meta: { layout: 'auth' }
    },
    {
        path: '/dieu-khoan',
        component: () => import('../components/User/Dieu_Khoan.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/chinh-sach-bao-mat',
        component: () => import('../components/User/Chinh_Sach_Bao_Mat.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/danh-sach-chien-dich',
        component: () => import('../components/User/Danh_Sach_Chien_Dich.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/chi-tiet-chien-dich/:id',
        component: () => import('../components/User/Chi_Tiet_Chien_Dich.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/quan-ly-chien-dich',
        component: () => import('../components/User/Quan_Ly_Chien_Dich.vue'),
        meta: { layout: 'default', requiresAuth: true, permissions: ['volunteer_campaigns.view'] }
    },
    {
        path: '/quan-ly-chien-dich/chi-tiet/:id',
        component: () => import('../components/User/Chi_Tiet_Quan_Ly_Chien_Dich.vue'),
        meta: { layout: 'default', requiresAuth: true, permissions: ['volunteer_campaigns.view'] }
    },
    {
        path: '/ho-so-nang-luc',
        component: () => import('../components/User/Ho_So_Nang_Luc.vue'),
        meta: { layout: 'default', requiresAuth: true, permissions: ['competency_profile.view'] }
    },
    {
        path: '/theo-doi-phan-hoi',
        component: () => import('../components/User/Theo_Doi_Phan_Hoi.vue'),
        meta: { layout: 'default', requiresAuth: true, permissions: ['feedback_tracking.view'] }
    },
    {
        path: '/thong-tin-ca-nhan',
        component: () => import('../components/User/Thong_Tin_Ca_Nhan.vue'),
        meta: { layout: 'default', requiresAuth: true, permissions: ['account_center.view'] }
    },
    {
        path: '/dieu-phoi-nhan-su',
        component: () => import('../components/User/Dieu_Phoi_Nhan_Su.vue'),
        meta: { layout: 'default', requiresAuth: true, permissions: ['campaign_coordination.view'] }
    },
    {
        path: '/giam-sat-bao-cao',
        component: () => import('../components/User/Giam_Sat_Bao_Cao.vue'),
        meta: { layout: 'default', requiresAuth: true, permissions: ['campaign_report_monitoring.view'] }
    },
    // ===== Admin Routes =====
    {
        path: '/admin',
        component: () => import('../components/Admin/Dashboard.vue'),
        meta: { layout: 'admin', permissions: ['dashboard.view'] }
    },
    {
        path: '/admin/nguoi-dung',
        component: () => import('../components/Admin/Quan_Ly_Nguoi_Dung.vue'),
        meta: { layout: 'admin', permissions: ['user_management.view'] }
    },
    {
        path: '/admin/chien-dich',
        redirect: '/kiem-duyet-vien/chien-dich',
    },
    {
        path: '/kiem-duyet-vien/chien-dich',
        component: () => import('../components/Kiem_Duyet_Vien/Quan_Ly_Chien_Dich.vue'),
        meta: { layout: 'admin', permissions: ['campaign_review.view'] }
    },
    {
        path: '/admin/danh-muc',
        component: () => import('../components/Admin/Quan_Ly_Danh_Muc.vue'),
        meta: { layout: 'admin', permissions: ['category_management.view'] }
    },
    {
        path: '/admin/ai-goi-y',
        component: () => import('../components/Admin/Quan_Ly_AI.vue'),
        meta: { layout: 'admin', permissions: ['ai_management.view'] }
    },
    {
        path: '/admin/thong-ke',
        redirect: '/kiem-duyet-vien/thong-ke',
    },
    {
        path: '/kiem-duyet-vien/thong-ke',
        component: () => import('../components/Admin/Thong_Ke.vue'),
        meta: { layout: 'admin', permissions: ['statistics.view'] }
    },
    {
        path: '/admin/phan-quyen',
        component: () => import('../components/Admin/Phan_Quyen.vue'),
        meta: { layout: 'admin', permissions: ['permission_management.view'] }
    },
    {
        path: '/admin/phan-quyen-nguoi-dung',
        component: () => import('../components/Admin/Phan_Quyen_Nguoi_Dung.vue'),
        meta: { layout: 'admin', permissions: ['permission_management.view'] }
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes: routes
})

function getAuthenticatedHome(role) {
    let currentUser = null;
    try {
        currentUser = JSON.parse(localStorage.getItem('user') || 'null');
    } catch (_error) {
        currentUser = null;
    }

    if (role === 'kiem_duyet_vien' || role === 'quan_tri_vien') {
        const adminHome = getFirstAccessibleAdminRoute(currentUser);
        return adminHome !== '/' ? adminHome : getFirstAccessibleUserRoute(currentUser);
    }

    return getFirstAccessibleUserRoute(currentUser);
}

router.beforeEach((to, from, next) => {
    let currentUser = null;
    try {
        currentUser = JSON.parse(localStorage.getItem('user') || 'null');
    } catch (_error) {
        currentUser = null;
    }

    const role = currentUser?.vai_tro || null;
    const hasToken = Boolean(localStorage.getItem('token'));
    const isAuthenticated = Boolean(role && hasToken);
    const isAdminRoute = to.path.startsWith('/admin') || to.path.startsWith('/kiem-duyet-vien');
    const isReviewerRoute = to.path.startsWith('/kiem-duyet-vien');
    const hasRoutePermission = hasAnyPermission(currentUser, to.meta.permissions || []);

    if (role === 'kiem_duyet_vien' && to.path === '/admin') {
        return next('/kiem-duyet-vien/thong-ke');
    }

    if (to.meta.guestOnly && isAuthenticated) {
        return next(getAuthenticatedHome(role));
    }

    if (to.meta.requiresAuth && !isAuthenticated) {
        return next('/dang-nhap');
    }

    if (!role && isAdminRoute) {
        return next('/');
    }

    if (isReviewerRoute && role !== 'kiem_duyet_vien') {
        return next(getAuthenticatedHome(role));
    }

    if (role !== 'kiem_duyet_vien' && role !== 'quan_tri_vien' && isAdminRoute) {
        return next('/');
    }

    if (isAdminRoute && !hasRoutePermission) {
        return next(getAuthenticatedHome(role));
    }

    if (!isAdminRoute && to.meta.requiresAuth && !hasRoutePermission) {
        return next(getAuthenticatedHome(role));
    }

    next();
});

export default router
