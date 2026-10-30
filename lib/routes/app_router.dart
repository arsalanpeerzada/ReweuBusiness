import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/biometrics/biometric_service.dart';
import '../core/security/app_lock.dart';
import '../core/storage/storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../features/analytics/screens/incident_analytics_screen.dart';
import '../features/auth/screens/lock_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/incidents/screens/incident_detail_screen.dart';
import '../features/incidents/screens/incident_feed_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

class AppRouter {
  final StorageService storageService;
  final BiometricService biometricService;
  final AuthRepository authRepository;
  final AppLockController appLock;

  AppRouter({
    required this.storageService,
    required this.biometricService,
    required this.authRepository,
    required this.appLock,
  });

  int _storedBusinessId() => storageService.getBusinessId() ?? 0;

  late final GoRouter router = GoRouter(
    initialLocation: '/incidents',
    refreshListenable: appLock,
    redirect: (context, state) {
      final loggedIn = storageService.hasToken;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';
      final isLock = location == '/lock';

      if (!loggedIn) {
        return isLoggingIn ? null : '/login';
      }
      if (appLock.isLocked) {
        if (isLock) return null;
        return Uri(path: '/lock', queryParameters: {'from': state.uri.toString()}).toString();
      }
      if (isLock) return '/incidents';
      if (isLoggingIn) {
        final businessId = _storedBusinessId();
        return businessId > 0 ? '/incidents?businessId=$businessId' : '/incidents';
      }
      return null;
    },
    errorBuilder: (context, state) => _NotFoundScreen(location: state.uri.toString()),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          storageService: storageService,
          biometricService: biometricService,
          authRepository: authRepository,
        ),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => LockScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileScreen(
          storageService: storageService,
          authRepository: authRepository,
          biometricService: biometricService,
        ),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) {
          final businessId =
              int.tryParse(state.uri.queryParameters['businessId'] ?? '') ?? _storedBusinessId();
          return IncidentAnalyticsScreen(businessId: businessId);
        },
      ),
      GoRoute(
        path: '/incidents',
        builder: (context, state) {
          final businessIdStr = state.uri.queryParameters['businessId'];
          final businessId = int.tryParse(businessIdStr ?? '') ?? _storedBusinessId();
          return IncidentFeedScreen(businessId: businessId);
        },
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final incidentIdStr = state.pathParameters['id'] ?? '0';
              final incidentId = int.tryParse(incidentIdStr) ?? 0;
              return IncidentDetailScreen(incidentId: incidentId);
            },
          ),
        ],
      ),
    ],
  );
}

class _NotFoundScreen extends StatelessWidget {
  final String location;

  const _NotFoundScreen({required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: context.palette.textSecondary),
              const SizedBox(height: 16),
              Text('errors.page_not_found'.tr(), style: AppTypography.h3(context), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/incidents'),
                child: Text('common.go_to_incidents'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
