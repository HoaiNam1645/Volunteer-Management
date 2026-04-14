/**
 * TrustEval API Client
 * Wraps the Laravel TrustEvalController endpoints used by the KDV (Kiểm Duyệt Viên) panel.
 *
 * Endpoints:
 *   GET  /api/trust-eval/campaign/:id        → get campaign evaluation
 *   PUT  /api/trust-eval/campaign/:id/refresh → trigger re-evaluation
 *   GET  /api/trust-eval/volunteer/:id      → get volunteer evaluation
 *   GET  /api/trust-eval/statistics         → admin dashboard stats
 *   GET  /api/trust-eval/health             → ML service health check
 */

import api from './api';

/**
 * Fetches the latest ML evaluation for a campaign.
 * @param {number} campaignId
 * @returns {Promise<import('./trustEvalTypes').CampaignEvaluationResponse>}
 */
export async function getCampaignEvaluation(campaignId) {
    const res = await api.get(`/trust-eval/campaign/${campaignId}`);
    if (res.data.status !== 1) {
        throw new Error(res.data.message || 'Failed to fetch campaign evaluation');
    }
    return res.data.data;
}

/**
 * Triggers a fresh ML evaluation for a campaign (bypasses cache).
 * @param {number} campaignId
 * @returns {Promise<import('./trustEvalTypes').CampaignEvaluationResponse>}
 */
export async function refreshCampaignEvaluation(campaignId) {
    const res = await api.post(`/trust-eval/campaign/${campaignId}/refresh`);
    if (res.data.status !== 1) {
        throw new Error(res.data.message || 'Failed to refresh campaign evaluation');
    }
    return res.data.data;
}

/**
 * Evaluates (or fetches cached) a volunteer.
 * @param {number} volunteerId
 * @returns {Promise<import('./trustEvalTypes').VolunteerEvaluationResponse>}
 */
export async function getVolunteerEvaluation(volunteerId) {
    const res = await api.get(`/trust-eval/volunteer/${volunteerId}`);
    if (res.data.status !== 1) {
        throw new Error(res.data.message || 'Failed to fetch volunteer evaluation');
    }
    return res.data.data;
}

/**
 * Fetches aggregated trust evaluation statistics for the admin dashboard.
 * @returns {Promise<import('./trustEvalTypes').TrustEvalStatistics>}
 */
export async function getStatistics() {
    const res = await api.get('/trust-eval/statistics');
    if (res.data.status !== 1) {
        throw new Error(res.data.message || 'Failed to fetch statistics');
    }
    return res.data.data;
}

/**
 * Pings the ML service health endpoint.
 * @returns {Promise<{healthy: boolean, data?: object, error?: string}>}
 */
export async function getMlServiceHealth() {
    try {
        const res = await api.get('/trust-eval/ml-health');
        return { healthy: res.data.status === 1, data: res.data.data };
    } catch (err) {
        return {
            healthy: false,
            error: err.response?.data?.message || err.message,
        };
    }
}
