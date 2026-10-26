import 'package:go_router/go_router.dart';
import '../core/biometrics/biometric_service.dart';
import '../core/storage/storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/incidents/screens/incident_detail_screen.dart';
import '../features/incidents/screens/incident_feed_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class AppRouter {
  final StorageService storageService;
  final BiometricService biometricService;
  final AuthRepository authRepository;

  AppRouter({
    required this.storageService,
    required this.biometricService,
    required this.authRepository,
  });

  late final GoRouter router = GoRouter(
    initialLocation: '/incidents',
    redirect: (context, state) async {
      final token = await storageService.getToken();
      final isLoggingIn = state.matchedLocation == '/login';

      if (token == null && !isLoggingIn) {
        return '/login';
      }
      if (token != null && isLoggingIn) {
        final businessId = storageService.getBusinessId();
        if (businessId != null && businessId > 0) {
          return '/incidents?businessId=$businessId';
        }
        return '/incidents';
      }
      return null;
    },
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
        path: '/profile',
        builder: (context, state) => ProfileScreen(
          storageService: storageService,
          authRepository: authRepository,
          biometricService: biometricService,
        ),
      ),
      GoRoute(
        path: '/incidents',
        builder: (context, state) {
          final businessIdStr = state.uri.queryParameters['businessId'];
          final businessId = int.tryParse(businessIdStr ?? '') ??
              storageService.getBusinessId() ??
              0;
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
