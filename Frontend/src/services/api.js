import axios from 'axios';
import {
	getFirstAccessibleAdminRoute,
	getFirstAccessibleUserRoute,
	hasPermission,
} from '../utils/permissions';

const resolvedBaseUrl = (() => {
    const configuredBaseUrl = String(import.meta.env.VITE_API_BASE_URL || '').trim();
    if (configuredBaseUrl) {
        return configuredBaseUrl.replace(/\/+$/, '');
    }

    if (typeof window !== 'undefined' && window.location?.origin) {
        return `${window.location.origin.replace(/\/+$/, '')}/api`;
    }

    return '/api';
})();

const api = axios.create({
    baseURL: resolvedBaseUrl,
    withCredentials: true,
    headers: {
        'Accept': 'application/json',
    }
});

let refreshCurrentUserPromise = null;
let lastCurrentUserRefreshAt = 0;
const CURRENT_USER_REFRESH_TTL = 5000;

function readStoredUser() {
    try {
        return JSON.parse(localStorage.getItem('user') || 'null');
    } catch (_error) {
        return null;
    }
}

function storeCurrentUser(user) {
    if (!user) {
        return null;
    }

    const mergedUser = {
        ...(readStoredUser() || {}),
        ...user,
        quyen_han: user.quyen_han || user.permissions || [],
        permissions: user.permissions || user.quyen_han || [],
    };

    localStorage.setItem('user', JSON.stringify(mergedUser));
    window.dispatchEvent(new CustomEvent('user-updated'));
    return mergedUser;
}

function resolveForbiddenRedirect(user) {
    const currentPath = window.location.pathname || '/';
    const isAdminRoute = currentPath.startsWith('/admin') || currentPath.startsWith('/kiem-duyet-vien');

    if (isAdminRoute) {
        if (currentPath === '/admin' && !hasPermission(user, 'dashboard.view')) {
            return getFirstAccessibleAdminRoute(user);
        }

        if (currentPath.startsWith('/kiem-duyet-vien/chien-dich') && !hasPermission(user, 'campaign_review.view')) {
            return getFirstAccessibleAdminRoute(user);
        }
    } else {
        if (currentPath.startsWith('/thong-tin-ca-nhan') && !hasPermission(user, 'account_center.view')) {
            return getFirstAccessibleUserRoute(user);
        }

        if (currentPath.startsWith('/ho-so-nang-luc') && !hasPermission(user, 'competency_profile.view')) {
            return getFirstAccessibleUserRoute(user);
        }

        if (currentPath.startsWith('/quan-ly-chien-dich') && !hasPermission(user, 'volunteer_campaigns.view')) {
            return getFirstAccessibleUserRoute(user);
        }

        if (currentPath.startsWith('/dieu-phoi-nhan-su') && !hasPermission(user, 'campaign_coordination.view')) {
            return getFirstAccessibleUserRoute(user);
        }

        if (currentPath.startsWith('/giam-sat-bao-cao') && !hasPermission(user, 'campaign_report_monitoring.view')) {
            return getFirstAccessibleUserRoute(user);
        }

        if (currentPath.startsWith('/theo-doi-phan-hoi') && !hasPermission(user, 'feedback_tracking.view')) {
            return getFirstAccessibleUserRoute(user);
        }
    }

    return null;
}

export async function refreshCurrentUser({ force = false, silent = false } = {}) {
    const token = localStorage.getItem('token');
    if (!token) {
        return null;
    }

    const now = Date.now();
    if (!force && (now - lastCurrentUserRefreshAt) < CURRENT_USER_REFRESH_TTL) {
        return readStoredUser();
    }

    if (refreshCurrentUserPromise) {
        return refreshCurrentUserPromise;
    }

    refreshCurrentUserPromise = api.get('/xac-thuc/thong-tin')
        .then((response) => {
            const nextUser = response.data?.data || null;
            if (!nextUser) {
                return readStoredUser();
            }

            lastCurrentUserRefreshAt = Date.now();
            return storeCurrentUser(nextUser);
        })
        .catch((error) => {
            if (!silent) {
                throw error;
            }

            return readStoredUser();
        })
        .finally(() => {
            refreshCurrentUserPromise = null;
        });

    return refreshCurrentUserPromise;
}

// Interceptor: gắn JWT token vào header nếu có
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }

    if (config.data instanceof FormData) {
        delete config.headers['Content-Type'];
    } else if (!config.headers['Content-Type']) {
        config.headers['Content-Type'] = 'application/json';
    }

    return config;
});

// Interceptor: nếu 401 → xóa token & redirect login
api.interceptors.response.use(
    (response) => response,
    async (error) => {
        if (error.response && error.response.status === 401) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            if (window.location.pathname !== '/dang-nhap') {
                window.location.href = '/dang-nhap';
            }
        }

        if (error.response && error.response.status === 403 && localStorage.getItem('token')) {
            const refreshedUser = await refreshCurrentUser({ force: true, silent: true });
            const redirectPath = resolveForbiddenRedirect(refreshedUser);

            if (redirectPath && redirectPath !== window.location.pathname) {
                window.location.href = redirectPath;
            }
        }

        return Promise.reject(error);
    }
);

export default api;
