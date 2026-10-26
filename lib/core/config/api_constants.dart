class ApiConstants {
  ApiConstants._();

  // Active API Base URL
//  static const String baseUrl = 'https://27fd-39-49-217-161.ngrok-free.app';
  static const String baseUrl = 'https://api.reweu.app';

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
