import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/reset_password_screen.dart';
import '../presentation/screens/auth/email_verification_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/campaign/campaign_list_screen.dart';
import '../presentation/screens/campaign/campaign_detail_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/competency_profile_screen.dart';
import '../presentation/screens/my_campaigns/my_campaigns_screen.dart';
import '../presentation/screens/feedback/feedback_screen.dart';
import '../presentation/screens/coordinator/coordinator_screen.dart';
import '../presentation/screens/report/report_screen.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';
import '../presentation/screens/admin/admin_users_screen.dart';
import '../presentation/screens/admin/admin_categories_screen.dart';
import '../presentation/screens/admin/admin_shell.dart';
import '../presentation/screens/admin/trust_eval_dashboard_screen.dart';
import '../presentation/screens/admin/admin_campaigns_screen.dart';
import '../presentation/screens/admin/admin_statistics_screen.dart';
import '../presentation/screens/admin/admin_permissions_screen.dart';
import '../presentation/screens/admin/admin_user_permissions_screen.dart';
import '../presentation/screens/common/main_shell.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static final _adminShellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      debugLogDiagnostics: false,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isInitialized = authProvider.isInitialized;
        final path = state.matchedLocation;

        // Wait for auth to initialize
        if (!isInitialized) {
          if (path != '/splash') return '/splash';
          return null;
        }

        // Splash screen - let it load
        if (path == '/splash') return null;

        // Auth routes - redirect to home if already logged in
        if (_isAuthRoute(path) && isLoggedIn) {
          return _getHomeRoute(authProvider);
        }

        // Guest routes
        if (_isGuestRoute(path) && !isLoggedIn) return null;

        // Protected routes - redirect to login if not logged in
        if (_isProtectedRoute(path) && !isLoggedIn) {
          return '/login';
        }

        // Admin routes
        if (path.startsWith('/admin')) {
          if (!authProvider.isAdminOrReviewer) {
            return _getHomeRoute(authProvider);
          }
        }

        // Reviewer routes
        if (path == '/coordinator' && !authProvider.isReviewer) {
          return _getHomeRoute(authProvider);
        }

        return null;
      },
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth routes (guest only)
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'] ?? '';
            final email = state.uri.queryParameters['email'] ?? '';
            return ResetPasswordScreen(token: token, email: email);
          },
        ),
        GoRoute(
          path: '/email-verification',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'] ?? '';
            return EmailVerificationScreen(token: token);
          },
        ),

        // Volunteer shell routes
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/campaigns',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CampaignListScreen(),
              ),
            ),
            GoRoute(
              path: '/my-campaigns',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MyCampaignsScreen(),
              ),
            ),
            GoRoute(
              path: '/feedback',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: FeedbackScreen(),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),

        // Campaign detail - outside shell (full screen)
        GoRoute(
          path: '/campaign/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return CampaignDetailScreen(campaignId: id);
          },
        ),

        // Other routes - outside shell
        GoRoute(
          path: '/competency-profile',
          builder: (context, state) => const CompetencyProfileScreen(),
        ),

        // Admin/Reviewer routes - with AdminShell
        ShellRoute(
          navigatorKey: _adminShellNavigatorKey,
          builder: (context, state, child) => AdminShell(child: child),
          routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            GoRoute(
              path: '/admin/users',
              builder: (context, state) => const AdminUsersScreen(),
            ),
            GoRoute(
              path: '/admin/categories',
              builder: (context, state) => const AdminCategoriesScreen(),
            ),
            GoRoute(
              path: '/admin/trust-eval',
              builder: (context, state) => const TrustEvalDashboardScreen(),
            ),
            GoRoute(
              path: '/admin/campaigns',
              builder: (context, state) => const AdminCampaignsScreen(),
            ),
            GoRoute(
              path: '/admin/statistics',
              builder: (context, state) => const AdminStatisticsScreen(),
            ),
            GoRoute(
              path: '/admin/permissions',
              builder: (context, state) => const AdminPermissionsScreen(),
            ),
            GoRoute(
              path: '/admin/user-permissions',
              builder: (context, state) => const AdminUserPermissionsScreen(),
            ),
          ],
        ),

        // Coordinator (Reviewer) - standalone
        GoRoute(
          path: '/coordinator',
          builder: (context, state) => const CoordinatorScreen(),
        ),
        GoRoute(
          path: '/report',
          builder: (context, state) => const ReportScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy trang: ${state.matchedLocation}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _getHomeRoute(AuthProvider authProvider) {
    if (authProvider.isAdmin) return '/admin';
    if (authProvider.isReviewer) return '/coordinator';
    return '/';
  }

  static bool _isAuthRoute(String path) {
    return path == '/login' ||
        path == '/register' ||
        path == '/forgot-password' ||
        path == '/reset-password' ||
        path == '/email-verification';
  }

  static bool _isGuestRoute(String path) {
    // Routes that guests can access (no login required)
    return path == '/';
  }

  static bool _isProtectedRoute(String path) {
    return path == '/my-campaigns' ||
        path == '/feedback' ||
        path == '/profile' ||
        path == '/competency-profile' ||
        path == '/coordinator' ||
        path == '/report' ||
        path == '/admin' ||
        path == '/admin/users' ||
        path == '/admin/categories' ||
        path == '/admin/trust-eval' ||
        path == '/admin/campaigns' ||
        path == '/admin/statistics' ||
        path == '/admin/permissions' ||
        path == '/admin/user-permissions';
  }
}
