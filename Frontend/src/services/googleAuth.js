const GOOGLE_SCRIPT_URL = 'https://accounts.google.com/gsi/client';

let googleScriptPromise = null;

function loadGoogleScript() {
    if (typeof window === 'undefined') {
        return Promise.reject(new Error('Google Sign-In chỉ hỗ trợ trên trình duyệt.'));
    }

    if (window.google?.accounts?.oauth2) {
        return Promise.resolve(window.google);
    }

    if (googleScriptPromise) {
        return googleScriptPromise;
    }

    googleScriptPromise = new Promise((resolve, reject) => {
        const existingScript = document.querySelector(`script[src="${GOOGLE_SCRIPT_URL}"]`);
        if (existingScript) {
            existingScript.addEventListener('load', () => resolve(window.google), { once: true });
            existingScript.addEventListener('error', () => reject(new Error('Không thể tải Google Sign-In SDK.')), { once: true });
            return;
        }

        const script = document.createElement('script');
        script.src = GOOGLE_SCRIPT_URL;
        script.async = true;
        script.defer = true;
        script.onload = () => resolve(window.google);
        script.onerror = () => reject(new Error('Không thể tải Google Sign-In SDK.'));
        document.head.appendChild(script);
    });

    return googleScriptPromise;
}

export async function requestGoogleAuthCode() {
    const clientId = String(import.meta.env.VITE_GOOGLE_CLIENT_ID || '').trim();
    if (!clientId) {
        throw new Error('Thiếu cấu hình VITE_GOOGLE_CLIENT_ID ở frontend.');
    }

    const google = await loadGoogleScript();

    return new Promise((resolve, reject) => {
        const codeClient = google.accounts.oauth2.initCodeClient({
            client_id: clientId,
            scope: 'openid email profile',
            ux_mode: 'popup',
            callback: (response) => {
                if (response?.error) {
                    reject(new Error('Đăng nhập Google bị từ chối hoặc đã bị hủy.'));
                    return;
                }

                if (!response?.code) {
                    reject(new Error('Google không trả về mã xác thực hợp lệ.'));
                    return;
                }

                resolve(response.code);
            },
        });

        codeClient.requestCode();
    });
}
