import { createRouter, createWebHistory } from "vue-router";

const routes = [
    {
        path: '/',
        component: () => import('../components/User/Trang_Chu.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/dang-nhap',
        component: () => import('../components/User/auth/Trang_Dang_Nhap.vue'),
        meta: { layout: 'auth' }
    },
    {
        path: '/dang-ky',
        component: () => import('../components/User/auth/Trang_Dang_Ky.vue'),
        meta: { layout: 'auth' }
    },
    {
        path: '/quen-mat-khau',
        component: () => import('../components/User/auth/Trang_Quen_Mat_Khau.vue'),
        meta: { layout: 'auth' }
    },
    {
        path: '/dat-lai-mat-khau/:token',
        component: () => import('../components/User/auth/Trang_Dat_Lai_Mat_Khau.vue'),
        meta: { layout: 'auth' }
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
        meta: { layout: 'default' }
    },
    {
        path: '/quan-ly-chien-dich/chi-tiet/:id',
        component: () => import('../components/User/Chi_Tiet_Quan_Ly_Chien_Dich.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/bai-viet',
        component: () => import('../components/User/Danh_Sach_Bai_Viet.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/bai-viet/:id',
        component: () => import('../components/User/Chi_Tiet_Bai_Viet.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/ho-so-nang-luc',
        component: () => import('../components/User/Ho_So_Nang_Luc.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/theo-doi-phan-hoi',
        component: () => import('../components/User/Theo_Doi_Phan_Hoi.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/thong-tin-ca-nhan',
        component: () => import('../components/User/Thong_Tin_Ca_Nhan.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/dieu-phoi-nhan-su',
        component: () => import('../components/User/Dieu_Phoi_Nhan_Su.vue'),
        meta: { layout: 'default' }
    },
    {
        path: '/giam-sat-bao-cao',
        component: () => import('../components/User/Giam_Sat_Bao_Cao.vue'),
        meta: { layout: 'default' }
    },
    // ===== Admin Routes =====
    {
        path: '/admin',
        component: () => import('../components/Admin/Dashboard.vue'),
        meta: { layout: 'admin' }
    },
    {
        path: '/admin/nguoi-dung',
        component: () => import('../components/Admin/Quan_Ly_Nguoi_Dung.vue'),
        meta: { layout: 'admin' }
    },
    {
        path: '/admin/chien-dich',
        component: () => import('../components/Kiem_Duyet_Vien/Quan_Ly_Chien_Dich.vue'),
        meta: { layout: 'admin' }
    },
    {
        path: '/admin/danh-muc',
        component: () => import('../components/Admin/Quan_Ly_Danh_Muc.vue'),
        meta: { layout: 'admin' }
    },
    {
        path: '/admin/bai-viet',
        component: () => import('../components/Admin/Quan_Ly_Bai_Viet.vue'),
        meta: { layout: 'admin' }
    },
    {
        path: '/admin/ai-goi-y',
        component: () => import('../components/Admin/Quan_Ly_AI.vue'),
        meta: { layout: 'admin' }
    },
    {
        path: '/admin/thong-ke',
        component: () => import('../components/Admin/Thong_Ke.vue'),
        meta: { layout: 'admin' }
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes: routes
})

router.beforeEach((to, from, next) => {
    let currentUser = null;
    try {
        currentUser = JSON.parse(localStorage.getItem('user') || 'null');
    } catch (_error) {
        currentUser = null;
    }

    const role = currentUser?.vai_tro || null;
    const isAdminRoute = to.path.startsWith('/admin');

    if (role === 'kiem_duyet_vien') {
        if (to.path === '/admin' || (isAdminRoute && to.path !== '/admin/chien-dich')) {
            return next('/admin/chien-dich');
        }
    }

    if (role !== 'kiem_duyet_vien' && role !== 'quan_tri_vien' && isAdminRoute) {
        return next('/');
    }

    next();
});

export default router
