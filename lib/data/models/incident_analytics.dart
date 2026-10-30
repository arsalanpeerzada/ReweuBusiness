/// Mirrors the backend `IncidentAnalyticsResponse`
/// (`GET /api/incidents/analytics/business/{businessId}`).
class IncidentAnalytics {
  final int totalIncidents;
  final int resolvedIncidents;
  final int avgReviewTimeMinutes;
  final int avgResolveTimeMinutes;
  final List<SeverityTrendPoint> severityTrend;
  final List<PerformanceRow> staffPerformance;
  final List<PerformanceRow> locationPerformance;

  const IncidentAnalytics({
    required this.totalIncidents,
    required this.resolvedIncidents,
    required this.avgReviewTimeMinutes,
    required this.avgResolveTimeMinutes,
    required this.severityTrend,
    required this.staffPerformance,
    required this.locationPerformance,
  });

  double get resolutionRate =>
      totalIncidents == 0 ? 0 : resolvedIncidents / totalIncidents;

  factory IncidentAnalytics.fromJson(Map<String, dynamic> json) {
    final kpis = json['kpis'] is Map<String, dynamic>
        ? json['kpis'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return IncidentAnalytics(
      totalIncidents: _int(kpis['totalIncidents']),
      resolvedIncidents: _int(kpis['resolvedIncidents']),
      avgReviewTimeMinutes: _int(kpis['avgReviewTimeMinutes']),
      avgResolveTimeMinutes: _int(kpis['avgResolveTimeMinutes']),
      severityTrend: (json['severityChartData'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SeverityTrendPoint.fromJson)
          .toList(),
      staffPerformance: (json['staffPerformance'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => PerformanceRow.fromJson(e, nameKey: 'staffName', countKey: 'incidentsAssigned'))
          .toList(),
      locationPerformance: (json['locationPerformance'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => PerformanceRow.fromJson(e, nameKey: 'branchName', countKey: 'totalIncidents'))
          .toList(),
    );
  }
}

class SeverityTrendPoint {
  final DateTime date;
  final Map<String, int> countsBySeverity;

  const SeverityTrendPoint({required this.date, required this.countsBySeverity});

  int get total => countsBySeverity.values.fold(0, (a, b) => a + b);

  factory SeverityTrendPoint.fromJson(Map<String, dynamic> json) {
    final counts = <String, int>{};
    if (json['countsBySeverity'] is Map) {
      (json['countsBySeverity'] as Map).forEach((k, v) => counts[k.toString()] = _int(v));
    }
    return SeverityTrendPoint(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      countsBySeverity: counts,
    );
  }
}

class PerformanceRow {
  final String name;
  final int incidents;
  final int reviewed;
  final int resolved;
  final int avgReviewMinutes;
  final int avgResolveMinutes;
  final double percentResolved;

  const PerformanceRow({
    required this.name,
    required this.incidents,
    required this.reviewed,
    required this.resolved,
    required this.avgReviewMinutes,
    required this.avgResolveMinutes,
    required this.percentResolved,
  });

  factory PerformanceRow.fromJson(
    Map<String, dynamic> json, {
    required String nameKey,
    required String countKey,
  }) {
    return PerformanceRow(
      name: json[nameKey]?.toString() ?? '',
      incidents: _int(json[countKey]),
      reviewed: _int(json['reviewed']),
      resolved: _int(json['resolved']),
      avgReviewMinutes: _int(json['avgReviewMinutes']),
      avgResolveMinutes: _int(json['avgResolveMinutes']),
      percentResolved: (json['percentResolved'] is num)
          ? (json['percentResolved'] as num).toDouble()
          : double.tryParse(json['percentResolved']?.toString() ?? '') ?? 0,
    );
  }
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
