import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/biometrics/biometric_service.dart';
import 'core/network/api_service.dart';
import 'core/storage/storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/incident_repository.dart';
import 'features/incidents/bloc/incident_detail_bloc.dart';
import 'features/incidents/bloc/incident_feed_bloc.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final storageService = await StorageService.init();
  final apiService = ApiService(storageService: storageService);
  final incidentRepository = IncidentRepository(apiService);
  final authRepository = AuthRepository(
    apiService: apiService,
    storageService: storageService,
  );
  final biometricService = BiometricService();

  final appRouter = AppRouter(
    storageService: storageService,
    biometricService: biometricService,
    authRepository: authRepository,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ur', 'PK'),
      ],
      path: 'assets/languages',
      fallbackLocale: const Locale('en', 'US'),
      child: ReweuBusinessApp(
        storageService: storageService,
        incidentRepository: incidentRepository,
        authRepository: authRepository,
        biometricService: biometricService,
        appRouter: appRouter,
      ),
    ),
  );
}

class ReweuBusinessApp extends StatelessWidget {
  final StorageService storageService;
  final IncidentRepository incidentRepository;
  final AuthRepository authRepository;
  final BiometricService biometricService;
  final AppRouter appRouter;

  const ReweuBusinessApp({
    super.key,
    required this.storageService,
    required this.incidentRepository,
    required this.authRepository,
    required this.biometricService,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: incidentRepository),
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: biometricService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => IncidentFeedBloc(incidentRepository),
          ),
          BlocProvider(
            create: (context) => IncidentDetailBloc(incidentRepository),
          ),
        ],
        child: MaterialApp.router(
          title: 'Reweu Business',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark, // Default OLED dark for operations
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: appRouter.router,
        ),
      ),
    );
  }
}
