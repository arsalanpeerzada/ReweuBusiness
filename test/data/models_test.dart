import 'package:flutter_test/flutter_test.dart';
import 'package:reweu_business/data/models/auth_models.dart';
import 'package:reweu_business/data/models/incident.dart';
import 'package:reweu_business/data/models/incident_analytics.dart';

void main() {
  test('IncidentDetailResponse parses the backend detail shape', () {
    final detail = IncidentDetailResponse.fromJson({
      'id': 9,
      'code': 'INC-9',
      'status': 'ACKNOWLEDGED',
      'severity': 'CRITICAL',
      'createdAt': '2026-10-20T10:15:00',
      'reviewedAt': '2026-10-20T10:30:00',
      'resolvedAt': null,
      'activities': [
        {
          'id': 1,
          'eventType': 'COMMENT',
          'message': 'Calling guest',
          'performedBy': {'userId': 3, 'name': 'Manager', 'avatarUrl': null},
          'createdAt': '2026-10-20T10:20:00',
        },
      ],
      'assignees': [],
      'reviewId': 55,
      'rating': 1.5,
      'reviewText': 'Cold food',
      'customerName': 'Guest',
      'customerEmail': 'guest@example.com',
      'customerPhone': '+920000000000',
      'locationName': 'Main branch',
      'metrics': {'FOOD_QUALITY': 1.0},
    });

    expect(detail.code, 'INC-9');
    expect(detail.branchName, 'Main branch');
    expect(detail.reviewComment, 'Cold food');
    expect(detail.reviewedAt, DateTime(2026, 10, 20, 10, 30));
    expect(detail.metrics['FOOD_QUALITY'], 1.0);
    expect(detail.activities.single.performedBy?.name, 'Manager');
    expect(detail.isClosed, isFalse);
    expect(detail.fromCache, isFalse);
  });

  test('IncidentPage reads content and the last flag', () {
    final page = IncidentPage.fromJson({
      'content': [
        {'id': 1, 'code': 'A', 'status': 'OPEN', 'severity': 'LOW'},
        'not-a-map',
      ],
      'last': false,
      'totalElements': 40,
    }, fromCache: true);

    expect(page.items.length, 1);
    expect(page.isLast, isFalse);
    expect(page.totalElements, 40);
    expect(page.fromCache, isTrue);
  });

  test('IncidentAnalytics parses KPIs, trend and performance tables', () {
    final a = IncidentAnalytics.fromJson({
      'kpis': {
        'totalIncidents': 10,
        'resolvedIncidents': 7,
        'avgReviewTimeMinutes': 12,
        'avgResolveTimeMinutes': 95,
      },
      'severityChartData': [
        {
          'date': '2026-10-26',
          'countsBySeverity': {'CRITICAL': 1, 'LOW': 2},
        },
      ],
      'averageTimeChartData': [],
      'staffPerformance': [
        {'staffName': 'Ali', 'incidentsAssigned': 4, 'reviewed': 4, 'resolved': 3, 'avgReviewMinutes': 10, 'avgResolveMinutes': 60, 'percentResolved': 75.0},
      ],
      'locationPerformance': [
        {'branchName': 'Main', 'totalIncidents': 10, 'reviewed': 9, 'resolved': 7, 'avgReviewMinutes': 12, 'avgResolveMinutes': 95, 'percentResolved': 70.0},
      ],
    });

    expect(a.resolutionRate, closeTo(0.7, 1e-9));
    expect(a.severityTrend.single.total, 3);
    expect(a.staffPerformance.single.incidents, 4);
    expect(a.locationPerformance.single.name, 'Main');
  });

  test('BranchSummary reads the my-branches shape', () {
    final b = BranchSummary.fromJson({'id': 3, 'name': 'Gulberg', 'businessId': 8, 'address': 'Lahore'});
    expect(b.id, 3);
    expect(b.businessId, 8);
    expect(b.locationName, 'Lahore');
  });
}
