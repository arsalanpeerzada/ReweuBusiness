import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reweu_business/core/network/api_exception.dart';
import 'package:reweu_business/core/network/api_service.dart';
import 'package:reweu_business/core/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/test_translations.dart';

void main() {
  late FakeHttpAdapter adapter;
  late ApiService api;
  late StorageService storage;

  setUpAll(loadEnglishTranslations);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    storage = await StorageService.init();
    await storage.saveToken('test-token');
    adapter = FakeHttpAdapter((_) => jsonBody(envelope({})));
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
    api = ApiService(storageService: storage, dioClient: dio);
    ApiService.onSessionExpired = null;
  });

  test('sends the bearer token and no development tunnel header', () async {
    await api.getIncidentDetails(1);
    final headers = adapter.requests.single.headers;
    expect(headers['Authorization'], 'Bearer test-token');
    expect(headers.keys.any((k) => k.toLowerCase().contains('ngrok')), isFalse);
  });

  test('getUserProfile sends the user id the backend requires', () async {
    adapter.handler = (_) => jsonBody(envelope({'id': 7, 'firstName': 'Test'}));
    final profile = await api.getUserProfile(7);
    expect(adapter.requests.single.path, '/api/users/getProfile');
    expect(adapter.requests.single.queryParameters['id'], 7);
    expect(profile['firstName'], 'Test');
  });

  test('addComment sends only the comment; the author comes from the token', () async {
    await api.addComment(12, 'Called the guest');
    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/api/incidents/12/comments');
    expect(req.data, {'comment': 'Called the guest'});
  });

  test('updateStatus sends query parameters only, without a client user id', () async {
    await api.updateStatus(5, status: 'RESOLVED', resolutionSummary: 'Refunded', sendVoucher: true, voucherAmount: 500);
    final req = adapter.requests.single;
    expect(req.method, 'PATCH');
    expect(req.path, '/api/incidents/5/status');
    expect(req.queryParameters, {
      'status': 'RESOLVED',
      'sendVoucher': true,
      'resolutionSummary': 'Refunded',
      'voucherAmount': 500.0,
    });
    expect(req.data, isNull);
  });

  test('getBusinessIncidents unwraps the paginated envelope', () async {
    adapter.handler = (_) => jsonBody(envelope({
          'content': [
            {'id': 1, 'code': 'INC-1', 'status': 'OPEN', 'severity': 'HIGH'},
          ],
          'pageNumber': 0,
          'pageSize': 20,
          'totalElements': 21,
          'totalPages': 2,
          'last': false,
        }));
    final page = await api.getBusinessIncidents(3, status: 'OPEN', page: 0);
    expect(adapter.requests.single.queryParameters, {'page': 0, 'size': 20, 'status': 'OPEN'});
    expect((page['content'] as List).length, 1);
    expect(page['last'], false);
    expect(page['totalElements'], 21);
  });

  test('ALL status is not sent as a filter', () async {
    adapter.handler = (_) => jsonBody(envelope({'content': [], 'last': true}));
    await api.getBusinessIncidents(3, status: 'ALL');
    expect(adapter.requests.single.queryParameters.containsKey('status'), isFalse);
  });

  test('a 401 outside login clears the session once and notifies', () async {
    var calls = 0;
    ApiService.onSessionExpired = () => calls++;
    adapter.handler = (_) => jsonBody({'message': 'expired'}, status: 401);

    await expectLater(api.getIncidentDetails(1), throwsA(isA<ApiException>()));
    await expectLater(api.getIncidentDetails(2), throwsA(isA<ApiException>()));

    expect(calls, 1);
    expect(storage.hasToken, isFalse);
  });

  test('a 401 on login is reported as wrong credentials, not session expiry', () async {
    var calls = 0;
    ApiService.onSessionExpired = () => calls++;
    adapter.handler = (_) => jsonBody({'message': 'Bad credentials'}, status: 401);

    try {
      await api.login('a@b.co', 'wrong-password');
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.kind, ApiErrorKind.unauthorised);
      expect(e.message, en('errors.invalid_credentials'));
    }
    expect(calls, 0);
  });

  test('connection failures map to an offline error', () async {
    adapter.handler = (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
    try {
      await api.getIncidentDetails(1);
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.isOffline, isTrue);
      expect(e.message, en('errors.network'));
    }
  });

  test('403 maps to forbidden', () async {
    adapter.handler = (_) => jsonBody({'message': 'nope'}, status: 403);
    try {
      await api.getIncidentDetails(1);
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.kind, ApiErrorKind.forbidden);
    }
  });

  test('analytics dates are sent as ISO local date-times', () async {
    await api.getIncidentAnalytics(
      4,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 27, 9, 30),
    );
    final q = adapter.requests.single.queryParameters;
    expect(adapter.requests.single.path, '/api/incidents/analytics/business/4');
    expect(q['startDate'], '2026-10-01T00:00:00');
    expect(q['endDate'], '2026-10-27T09:30:00');
  });
}
