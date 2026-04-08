export const ADMIN_PERMISSION_GROUPS = [
	{
		key: 'dashboard',
		permissions: [{ key: 'dashboard.view', shortLabel: 'Truy cap' }],
	},
	{
		key: 'user_management',
		permissions: [
			{ key: 'user_management.view', shortLabel: 'Xem' },
			{ key: 'user_management.manage', shortLabel: 'Quan ly' },
		],
	},
	{
		key: 'category_management',
		permissions: [
			{ key: 'category_management.view', shortLabel: 'Xem' },
			{ key: 'category_management.manage', shortLabel: 'Quan ly' },
		],
	},
	{
		key: 'campaign_review',
		permissions: [
			{ key: 'campaign_review.view', shortLabel: 'Xem' },
			{ key: 'campaign_review.manage', shortLabel: 'Quan ly' },
		],
	},
	{
		key: 'ai_management',
		permissions: [{ key: 'ai_management.view', shortLabel: 'Truy cap' }],
	},
	{
		key: 'statistics',
		permissions: [{ key: 'statistics.view', shortLabel: 'Truy cap' }],
	},
	{
		key: 'permission_management',
		permissions: [
			{ key: 'permission_management.view', shortLabel: 'Xem' },
			{ key: 'permission_management.manage', shortLabel: 'Quan ly' },
		],
	},
];

export const USER_PERMISSION_GROUPS = [
	{
		key: 'account_center',
		permissions: [
			{ key: 'account_center.view', shortLabel: 'Xem' },
			{ key: 'account_center.manage', shortLabel: 'Chinh sua' },
		],
	},
	{
		key: 'competency_profile',
		permissions: [
			{ key: 'competency_profile.view', shortLabel: 'Xem' },
			{ key: 'competency_profile.manage', shortLabel: 'Chinh sua' },
		],
	},
	{
		key: 'volunteer_campaigns',
		permissions: [
			{ key: 'volunteer_campaigns.view', shortLabel: 'Xem' },
			{ key: 'volunteer_campaigns.manage', shortLabel: 'Quan ly' },
		],
	},
	{
		key: 'campaign_coordination',
		permissions: [
			{ key: 'campaign_coordination.view', shortLabel: 'Xem' },
			{ key: 'campaign_coordination.manage', shortLabel: 'Quan ly' },
		],
	},
	{
		key: 'campaign_report_monitoring',
		permissions: [
			{ key: 'campaign_report_monitoring.view', shortLabel: 'Xem' },
			{ key: 'campaign_report_monitoring.manage', shortLabel: 'Quan ly' },
		],
	},
	{
		key: 'feedback_tracking',
		permissions: [
			{ key: 'feedback_tracking.view', shortLabel: 'Xem' },
			{ key: 'feedback_tracking.manage', shortLabel: 'Quan ly' },
		],
	},
	{
		key: 'campaign_participation',
		permissions: [{ key: 'campaign_participation.manage', shortLabel: 'Tham gia' }],
	},
	{
		key: 'ai_recommendation',
		permissions: [{ key: 'ai_recommendation.view', shortLabel: 'Goi y AI' }],
	},
];

export const ADMIN_ROUTE_PERMISSIONS = [
	{ path: '/admin', permission: 'dashboard.view' },
	{ path: '/kiem-duyet-vien/chien-dich', permission: 'campaign_review.view' },
	{ path: '/admin/nguoi-dung', permission: 'user_management.view' },
	{ path: '/admin/danh-muc', permission: 'category_management.view' },
	{ path: '/admin/ai-goi-y', permission: 'ai_management.view' },
	{ path: '/kiem-duyet-vien/thong-ke', permission: 'statistics.view' },
	{ path: '/admin/phan-quyen', permission: 'permission_management.view' },
	{ path: '/admin/phan-quyen-nguoi-dung', permission: 'permission_management.view' },
];

export const USER_ROUTE_PERMISSIONS = [
	{ path: '/thong-tin-ca-nhan', permission: 'account_center.view' },
	{ path: '/ho-so-nang-luc', permission: 'competency_profile.view' },
	{ path: '/quan-ly-chien-dich', permission: 'volunteer_campaigns.view' },
	{ path: '/dieu-phoi-nhan-su', permission: 'campaign_coordination.view' },
	{ path: '/giam-sat-bao-cao', permission: 'campaign_report_monitoring.view' },
	{ path: '/theo-doi-phan-hoi', permission: 'feedback_tracking.view' },
];

export const ROLE_DEFAULT_PERMISSIONS = {
	tinh_nguyen_vien: [
		'account_center.view',
		'account_center.manage',
		'competency_profile.view',
		'competency_profile.manage',
		'volunteer_campaigns.view',
		'volunteer_campaigns.manage',
		'campaign_coordination.view',
		'campaign_coordination.manage',
		'campaign_report_monitoring.view',
		'campaign_report_monitoring.manage',
		'feedback_tracking.view',
		'feedback_tracking.manage',
		'campaign_participation.manage',
		'ai_recommendation.view',
	],
	kiem_duyet_vien: [
		'account_center.view',
		'account_center.manage',
		'dashboard.view',
		'campaign_review.view',
		'campaign_review.manage',
		'statistics.view',
	],
	quan_tri_vien: [
		'account_center.view',
		'account_center.manage',
		'dashboard.view',
		'user_management.view',
		'user_management.manage',
		'category_management.view',
		'category_management.manage',
		'campaign_review.view',
		'campaign_review.manage',
		'ai_management.view',
		'statistics.view',
		'permission_management.view',
		'permission_management.manage',
	],
};

export const PERMISSION_GROUPS = ADMIN_PERMISSION_GROUPS;

export function getPermissionGroups(scope = 'admin') {
	return scope === 'user' ? USER_PERMISSION_GROUPS : ADMIN_PERMISSION_GROUPS;
}

export function getUserPermissions(user) {
	const permissions = user?.permissions || user?.quyen_han || [];
	if (Array.isArray(permissions) && permissions.length) {
		return Array.from(new Set(permissions));
	}

	return [...(ROLE_DEFAULT_PERMISSIONS[user?.vai_tro] || [])];
}

export function hasPermission(user, permission) {
	if (!permission) return true;
	return getUserPermissions(user).includes(permission);
}

export function hasAnyPermission(user, permissions = []) {
	if (!permissions.length) return true;
	return permissions.some((permission) => hasPermission(user, permission));
}

export function getFirstAccessibleAdminRoute(user) {
	if (user?.vai_tro === 'kiem_duyet_vien' && hasPermission(user, 'statistics.view')) {
		return '/kiem-duyet-vien/thong-ke';
	}

	const match = ADMIN_ROUTE_PERMISSIONS.find((route) => hasPermission(user, route.permission));
	return match?.path || '/';
}

export function getFirstAccessibleUserRoute(user) {
	const match = USER_ROUTE_PERMISSIONS.find((route) => hasPermission(user, route.permission));
	return match?.path || '/';
}

export function syncStoredUser(patch = {}) {
	try {
		const rawUser = localStorage.getItem('user');
		if (!rawUser) return null;

		const currentUser = JSON.parse(rawUser);
		const nextUser = { ...currentUser, ...patch };
		localStorage.setItem('user', JSON.stringify(nextUser));
		return nextUser;
	} catch (_error) {
		return null;
	}
}
