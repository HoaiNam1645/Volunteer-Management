<?php

namespace App\Support;

class PermissionRegistry
{
    public const GROUPS = [
        'dashboard' => [
            'scope' => 'admin',
            'permissions' => ['dashboard.view'],
        ],
        'user_management' => [
            'scope' => 'admin',
            'permissions' => ['user_management.view', 'user_management.manage'],
        ],
        'category_management' => [
            'scope' => 'admin',
            'permissions' => ['category_management.view', 'category_management.manage'],
        ],
        'campaign_review' => [
            'scope' => 'admin',
            'permissions' => ['campaign_review.view', 'campaign_review.manage'],
        ],
        'ai_management' => [
            'scope' => 'admin',
            'permissions' => ['ai_management.view'],
        ],
        'statistics' => [
            'scope' => 'admin',
            'permissions' => ['statistics.view'],
        ],
        'permission_management' => [
            'scope' => 'admin',
            'permissions' => ['permission_management.view', 'permission_management.manage'],
        ],
        'account_center' => [
            'scope' => 'user',
            'permissions' => ['account_center.view', 'account_center.manage'],
        ],
        'competency_profile' => [
            'scope' => 'user',
            'permissions' => ['competency_profile.view', 'competency_profile.manage'],
        ],
        'volunteer_campaigns' => [
            'scope' => 'user',
            'permissions' => ['volunteer_campaigns.view', 'volunteer_campaigns.manage'],
        ],
        'campaign_coordination' => [
            'scope' => 'user',
            'permissions' => ['campaign_coordination.view', 'campaign_coordination.manage'],
        ],
        'campaign_report_monitoring' => [
            'scope' => 'user',
            'permissions' => ['campaign_report_monitoring.view', 'campaign_report_monitoring.manage'],
        ],
        'feedback_tracking' => [
            'scope' => 'user',
            'permissions' => ['feedback_tracking.view', 'feedback_tracking.manage'],
        ],
        'campaign_participation' => [
            'scope' => 'user',
            'permissions' => ['campaign_participation.manage'],
        ],
        'ai_recommendation' => [
            'scope' => 'user',
            'permissions' => ['ai_recommendation.view'],
        ],
    ];

    public const ROLE_DEFAULTS = [
        'tinh_nguyen_vien' => [
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
        'kiem_duyet_vien' => [
            'account_center.view',
            'account_center.manage',
            'dashboard.view',
            'campaign_review.view',
            'campaign_review.manage',
            'statistics.view',
        ],
        'quan_tri_vien' => [
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
    ];

    public static function normalizeScope(?string $scope): string
    {
        return in_array($scope, ['admin', 'user'], true) ? $scope : 'admin';
    }

    public static function groupsForScope(?string $scope): array
    {
        $scope = static::normalizeScope($scope);

        return collect(static::GROUPS)
            ->filter(fn (array $group) => ($group['scope'] ?? 'admin') === $scope)
            ->all();
    }

    public static function permissionsForScope(?string $scope): array
    {
        return collect(static::groupsForScope($scope))
            ->flatMap(fn (array $group) => $group['permissions'] ?? [])
            ->values()
            ->all();
    }

    public static function allPermissions(): array
    {
        return collect(static::GROUPS)
            ->flatMap(fn (array $group) => $group['permissions'] ?? [])
            ->values()
            ->all();
    }

    public static function defaultsForRole(?string $role): array
    {
        return static::ROLE_DEFAULTS[$role] ?? [];
    }

    public static function defaultPermissionsForRoleAndScope(?string $role, ?string $scope): array
    {
        $scopePermissions = static::permissionsForScope($scope);

        return array_values(array_intersect(static::defaultsForRole($role), $scopePermissions));
    }

    public static function permissionsForScopeFromList(array $permissions, ?string $scope): array
    {
        $scopePermissions = static::permissionsForScope($scope);

        return array_values(array_intersect(static::normalize($permissions), $scopePermissions));
    }

    public static function normalize(?array $permissions): array
    {
        if (empty($permissions)) {
            return [];
        }

        $allowed = static::allPermissions();

        return collect($permissions)
            ->filter(fn ($permission) => is_string($permission) && in_array($permission, $allowed, true))
            ->unique()
            ->values()
            ->all();
    }
}
