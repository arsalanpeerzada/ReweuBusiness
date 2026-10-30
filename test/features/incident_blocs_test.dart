import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reweu_business/core/network/api_exception.dart';
import 'package:reweu_business/core/network/api_service.dart';
import 'package:reweu_business/core/storage/storage_service.dart';
import 'package:reweu_business/data/models/incident.dart';
import 'package:reweu_business/data/repositories/incident_repository.dart';
import 'package:reweu_business/features/incidents/bloc/incident_detail_bloc.dart';
import 'package:reweu_business/features/incidents/bloc/incident_feed_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/test_translations.dart';

class MockIncidentRepository extends Mock implements IncidentRepository {}

IncidentListResponse incident(int id, {String severity = 'LOW', String status = 'OPEN'}) =>
    IncidentListResponse.fromJson({'id': id, 'code': 'INC-$id', 'status': status, 'severity': severity});

IncidentDetailResponse detail(int id) =>
    IncidentDetailResponse.fromJson({'id': id, 'code': 'INC-$id', 'status': 'OPEN', 'severity': 'HIGH'});

void main() {
  late MockIncidentRepository repo;

  setUpAll(loadEnglishTranslations);
  setUp(() => repo = MockIncidentRepository());

  void stubPages(List<IncidentPage> pages) {
    when(() => repo.getIncidents(
          businessId: any(named: 'businessId'),
          branchId: any(named: 'branchId'),
          status: any(named: 'status'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        )).thenAnswer((inv) async => pages[(inv.namedArguments[#page] as int).clamp(0, pages.length - 1)]);
  }

  group('IncidentFeedBloc', () {
    blocTest<IncidentFeedBloc, IncidentFeedState>(
      'loads the first page and reports more pages',
      build: () {
        stubPages([IncidentPage(items: [incident(1), incident(2)], isLast: false)]);
        return IncidentFeedBloc(repo);
      },
      act: (b) => b.add(const FetchIncidentsEvent(businessId: 3)),
      expect: () => [
        isA<IncidentFeedLoading>(),
        isA<IncidentFeedLoaded>()
            .having((s) => s.incidents.length, 'count', 2)
            .having((s) => s.hasMore, 'hasMore', true),
      ],
    );

    blocTest<IncidentFeedBloc, IncidentFeedState>(
      'appends the next page without duplicates',
      build: () {
        stubPages([
          IncidentPage(items: [incident(1), incident(2)], isLast: false),
          IncidentPage(items: [incident(2), incident(3)], isLast: true),
        ]);
        return IncidentFeedBloc(repo);
      },
      act: (b) async {
        b.add(const FetchIncidentsEvent(businessId: 3));
        await Future<void>.delayed(Duration.zero);
        b.add(const LoadMoreIncidentsEvent());
      },
      skip: 2,
      expect: () => [
        isA<IncidentFeedLoaded>().having((s) => s.isLoadingMore, 'loadingMore', true),
        isA<IncidentFeedLoaded>()
            .having((s) => s.incidents.map((i) => i.id).toList(), 'ids', [1, 2, 3])
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<IncidentFeedBloc, IncidentFeedState>(
      'Critical tab filters by severity and reads ahead',
      build: () {
        stubPages([
          IncidentPage(items: [incident(1), incident(2, severity: 'CRITICAL')], isLast: false),
          IncidentPage(items: [incident(3, severity: 'CRITICAL')], isLast: true),
        ]);
        return IncidentFeedBloc(repo);
      },
      act: (b) => b.add(const FetchIncidentsEvent(businessId: 3, status: 'CRITICAL')),
      expect: () => [
        isA<IncidentFeedLoading>(),
        isA<IncidentFeedLoaded>().having((s) => s.incidents.map((i) => i.id).toList(), 'ids', [2, 3]),
      ],
      verify: (_) {
        verify(() => repo.getIncidents(
              businessId: 3,
              branchId: null,
              status: null,
              page: any(named: 'page'),
              size: any(named: 'size'),
            )).called(2);
      },
    );

    blocTest<IncidentFeedBloc, IncidentFeedState>(
      'branch filter is passed to the backend',
      build: () {
        stubPages([IncidentPage(items: [incident(1)], isLast: true)]);
        return IncidentFeedBloc(repo);
      },
      act: (b) async {
        b.add(const FetchIncidentsEvent(businessId: 3));
        await Future<void>.delayed(Duration.zero);
        b.add(const BranchChangedEvent(11));
      },
      verify: (_) {
        verify(() => repo.getIncidents(
              businessId: 3,
              branchId: 11,
              status: 'OPEN',
              page: 0,
              size: any(named: 'size'),
            )).called(1);
      },
    );

    blocTest<IncidentFeedBloc, IncidentFeedState>(
      'a failed acknowledge shows a notice instead of failing silently',
      build: () {
        stubPages([IncidentPage(items: [incident(1)], isLast: true)]);
        when(() => repo.updateStatus(any(), status: any(named: 'status')))
            .thenThrow(const ApiException(ApiErrorKind.forbidden, 'No access'));
        return IncidentFeedBloc(repo);
      },
      act: (b) async {
        b.add(const FetchIncidentsEvent(businessId: 3));
        await Future<void>.delayed(Duration.zero);
        b.add(const QuickAcknowledgeEvent(1));
      },
      skip: 2,
      expect: () => [
        isA<IncidentFeedLoaded>()
            .having((s) => s.notice?.message, 'notice', 'No access')
            .having((s) => s.notice?.isError, 'isError', true),
      ],
    );

    blocTest<IncidentFeedBloc, IncidentFeedState>(
      'access errors carry their kind for the UI',
      build: () {
        when(() => repo.getIncidents(
              businessId: any(named: 'businessId'),
              branchId: any(named: 'branchId'),
              status: any(named: 'status'),
              page: any(named: 'page'),
              size: any(named: 'size'),
            )).thenThrow(const ApiException(ApiErrorKind.forbidden, 'No access'));
        return IncidentFeedBloc(repo);
      },
      act: (b) => b.add(const FetchIncidentsEvent(businessId: 3)),
      expect: () => [
        isA<IncidentFeedLoading>(),
        isA<IncidentFeedError>().having((s) => s.isAccessDenied, 'accessDenied', true),
      ],
    );

    blocTest<IncidentFeedBloc, IncidentFeedState>(
      'no business shows an error without calling the backend',
      build: () => IncidentFeedBloc(repo),
      act: (b) => b.add(const FetchIncidentsEvent(businessId: 0)),
      expect: () => [isA<IncidentFeedError>()],
      verify: (_) => verifyNever(() => repo.getIncidents(
            businessId: any(named: 'businessId'),
            branchId: any(named: 'branchId'),
            status: any(named: 'status'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )),
    );
  });

  group('IncidentDetailBloc', () {
    blocTest<IncidentDetailBloc, IncidentDetailState>(
      'a failed comment keeps the incident and reports the error',
      build: () {
        when(() => repo.getIncidentDetail(5)).thenAnswer((_) async => detail(5));
        when(() => repo.addComment(5, any()))
            .thenThrow(const ApiException(ApiErrorKind.network, 'Offline'));
        return IncidentDetailBloc(repo);
      },
      act: (b) async {
        b.add(const FetchIncidentDetailEvent(5));
        await Future<void>.delayed(Duration.zero);
        b.add(const PostCommentEvent(5, 'note'));
      },
      expect: () => [
        isA<IncidentDetailLoading>(),
        isA<IncidentDetailLoaded>().having((s) => s.notice, 'notice', isNull),
        isA<IncidentDetailLoaded>().having((s) => s.actionInProgress, 'busy', true),
        isA<IncidentDetailLoaded>()
            .having((s) => s.incident.id, 'id', 5)
            .having((s) => s.notice?.message, 'notice', 'Offline'),
      ],
    );

    blocTest<IncidentDetailBloc, IncidentDetailState>(
      'resolving refreshes the incident and confirms',
      build: () {
        when(() => repo.getIncidentDetail(5)).thenAnswer((_) async => detail(5));
        when(() => repo.updateStatus(
              5,
              status: 'RESOLVED',
              resolutionSummary: any(named: 'resolutionSummary'),
              sendVoucher: any(named: 'sendVoucher'),
              voucherAmount: any(named: 'voucherAmount'),
            )).thenAnswer((_) async {});
        return IncidentDetailBloc(repo);
      },
      act: (b) async {
        b.add(const FetchIncidentDetailEvent(5));
        await Future<void>.delayed(Duration.zero);
        b.add(const ResolveIncidentEvent(incidentId: 5, status: 'RESOLVED', summary: 'Refunded the guest'));
      },
      skip: 3,
      expect: () => [
        isA<IncidentDetailLoaded>().having((s) => s.notice?.isError, 'isError', false),
      ],
    );

    blocTest<IncidentDetailBloc, IncidentDetailState>(
      'load failure exposes a retryable error',
      build: () {
        when(() => repo.getIncidentDetail(5))
            .thenThrow(const ApiException(ApiErrorKind.notFound, 'Gone'));
        return IncidentDetailBloc(repo);
      },
      act: (b) => b.add(const FetchIncidentDetailEvent(5)),
      expect: () => [
        isA<IncidentDetailLoading>(),
        isA<IncidentDetailError>().having((s) => s.kind, 'kind', ApiErrorKind.notFound),
      ],
    );
  });

  group('IncidentRepository offline cache', () {
    test('serves the cached first page when offline', () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final storage = await StorageService.init();
      await storage.saveToken('t');

      final adapter = FakeHttpAdapter((_) => jsonBody(envelope({
            'content': [
              {'id': 1, 'code': 'INC-1', 'status': 'OPEN', 'severity': 'LOW'},
            ],
            'last': true,
          })));
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
      final repository = IncidentRepository(ApiService(storageService: storage, dioClient: dio), cache: storage);

      final online = await repository.getIncidents(businessId: 3, status: 'OPEN');
      expect(online.fromCache, isFalse);

      adapter.handler = (o) => throw DioException(requestOptions: o, type: DioExceptionType.connectionError);
      final offline = await repository.getIncidents(businessId: 3, status: 'OPEN');

      expect(offline.fromCache, isTrue);
      expect(offline.items.single.code, 'INC-1');
    });
  });
}
