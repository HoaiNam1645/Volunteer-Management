import axios from 'axios';

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
    (error) => {
        if (error.response && error.response.status === 401) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            if (window.location.pathname !== '/dang-nhap') {
                window.location.href = '/dang-nhap';
            }
        }
        return Promise.reject(error);
    }
);

export default api;
