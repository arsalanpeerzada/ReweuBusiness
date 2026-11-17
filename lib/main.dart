import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/biometrics/biometric_service.dart';
import 'core/network/api_service.dart';
import 'core/push/push_service.dart';
import 'core/security/app_lock.dart';
import 'core/storage/storage_service.dart';
import 'core/widgets/app_logo.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/incident_repository.dart';
import 'data/repositories/support_repository.dart';
import 'features/incidents/bloc/incident_feed_bloc.dart';
import 'routes/app_router.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (_) {}
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  GoogleFonts.config.allowRuntimeFetching = false;
  try {
    await EasyLocalization.ensureInitialized().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('EasyLocalization init failed: $e');
  }

  final storageService = await StorageService.init();
  final apiService = ApiService(storageService: storageService);
  final incidentRepository = IncidentRepository(apiService, cache: storageService);
  final supportRepository = SupportRepository(
    apiService: apiService,
    storageService: storageService,
  );
  final pushService = PushService(
    apiService: apiService,
    storageService: storageService,
  );
  final authRepository = AuthRepository(
    apiService: apiService,
    storageService: storageService,
    onSignedIn: pushService.registerDevice,
    onBeforeSignOut: pushService.unregisterDevice,
  );
  final biometricService = BiometricService();
  final appLock = AppLockController(storageService);

  final appRouter = AppRouter(
    storageService: storageService,
    biometricService: biometricService,
    authRepository: authRepository,
    appLock: appLock,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ur', 'PK'),
      ],
      path: 'assets/languages',
      fallbackLocale: const Locale('en', 'US'),
      saveLocale: true,
      child: ReweuBusinessApp(
        storageService: storageService,
        incidentRepository: incidentRepository,
        supportRepository: supportRepository,
        authRepository: authRepository,
        biometricService: biometricService,
        pushService: pushService,
        appLock: appLock,
        appRouter: appRouter,
      ),
    ),
  );
}

class ReweuBusinessApp extends StatefulWidget {
  final StorageService storageService;
  final IncidentRepository incidentRepository;
  final SupportRepository supportRepository;
  final AuthRepository authRepository;
  final BiometricService biometricService;
  final PushService pushService;
  final AppLockController appLock;
  final AppRouter appRouter;

  const ReweuBusinessApp({
    super.key,
    required this.storageService,
    required this.incidentRepository,
    required this.supportRepository,
    required this.authRepository,
    required this.biometricService,
    required this.pushService,
    required this.appLock,
    required this.appRouter,
  });

  @override
  State<ReweuBusinessApp> createState() => _ReweuBusinessAppState();
}

class _ReweuBusinessAppState extends State<ReweuBusinessApp> with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Hides content while the app is not in the foreground, so the OS
  /// app-switcher snapshot never shows customer details.
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ApiService.onSessionExpired = () {
      // Drop this device's FCM token so it stops receiving the user's alerts.
      widget.pushService.unregisterDevice();
      widget.appLock.reset();
      widget.appRouter.router.go('/login');
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('errors.session_expired'.tr())));
    };

    widget.pushService.onOpenIncident = (incidentId) {
      widget.appRouter.router.push('/incidents/$incidentId');
    };

    WidgetsBinding.instance.addPostFrameCallback((_) => _startPush());
  }

  Future<void> _startPush() async {
    await FirebaseBootstrap.init();
    await widget.pushService.init();
    if (widget.storageService.hasToken) {
      await widget.pushService.registerDevice();
    }
    final pending = widget.pushService.takePendingIncident();
    if (pending != null) {
      widget.appRouter.router.push('/incidents/$pending');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.pushService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        setState(() => _obscured = true);
      case AppLifecycleState.paused:
        widget.appLock.onBackgrounded();
        setState(() => _obscured = true);
      case AppLifecycleState.resumed:
        widget.appLock.onResumed();
        setState(() => _obscured = false);
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        RepositoryProvider.value(value: widget.storageService),
        RepositoryProvider.value(value: widget.incidentRepository),
        RepositoryProvider.value(value: widget.supportRepository),
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider.value(value: widget.biometricService),
        RepositoryProvider.value(value: widget.pushService),
        ChangeNotifierProvider.value(value: widget.appLock),
        BlocProvider(
          create: (context) => IncidentFeedBloc(widget.incidentRepository),
        ),
      ],
      child: MaterialApp.router(
          title: 'auth.title'.tr(),
          onGenerateTitle: (_) => 'auth.title'.tr(),
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _messengerKey,
          themeMode: ThemeMode.dark, // Default OLED dark for operations
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: widget.appRouter.router,
          builder: (context, child) {
            return Stack(
              children: [
                ?child,
                if (_obscured)
                  Positioned.fill(
                    child: ColoredBox(
                      color: context.palette.background,
                      child: const Center(child: AppLogo(height: 32, alignment: Alignment.center)),
                    ),
                  ),
              ],
            );
          },
        ),
    );
  }
}
