class ApiConstants {
  ApiConstants._();

  // API Base URL. Override per environment at build time:
  //   flutter run --dart-define=API_BASE_URL=https://staging-api.reweu.app
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.reweu.app',
  );

  // Endpoints
  static const String login = '/api/users/login';
  static const String myBusinesses = '/api/business/my-businesses';
  static const String myBranches = '/api/businessBranch/my-branches';
  static const String businesses = '/api/business/getAllBusinesses';
  static const String userProfile = '/api/users/getProfile';
  static const String incidentsByBusiness = '/api/incidents/business';
  static const String incidentDetails = '/api/incidents';
  static const String incidentAnalytics = '/api/incidents/analytics/business';
  static const String registerDevice = '/api/users/devices/register';
  static const String unregisterDevice = '/api/users/devices/unregister';
}

class AppConfig {
  AppConfig._();

  static const String appName = 'Reweu Business';

  /// Incidents fetched per page (the backend clamps to 1..100).
  static const int incidentPageSize = 20;

  /// Branches fetched when building the branch selector.
  static const int branchPageSize = 100;

  /// How long the app may sit in the background before biometrics are
  /// required again.
  static const Duration lockAfter = Duration(seconds: 60);

  /// Service recovery vouchers.
  static const String voucherCurrency = 'PKR';
  static const double maxVoucherAmount = 50000;

  /// Minimum length of a resolution summary when resolving an incident.
  static const int minResolutionSummaryLength = 10;

  /// Android notification channel for incident alerts.
  static const String incidentChannelId = 'incident_alerts';
}
