class IncidentListResponse {
  final int id;
  final String code;
  final DateTime createdAt;
  final double? rating;
  final int reviewId;
  final List<String> metrics;
  final String? location;
  final String? email;
  final String? phoneNumber;
  final List<AssigneeInfo> assignees;
  final String status;
  final String severity;

  IncidentListResponse({
    required this.id,
    required this.code,
    required this.createdAt,
    this.rating,
    required this.reviewId,
    required this.metrics,
    this.location,
    this.email,
    this.phoneNumber,
    required this.assignees,
    required this.status,
    required this.severity,
  });

  factory IncidentListResponse.fromJson(Map<String, dynamic> json) {
    return IncidentListResponse(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null,
      reviewId: json['reviewId'] is int
          ? json['reviewId']
          : int.tryParse(json['reviewId']?.toString() ?? '0') ?? 0,
      metrics: (json['metrics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      location: json['location'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      assignees: (json['assignees'] as List<dynamic>?)
              ?.map((e) => AssigneeInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] ?? 'OPEN',
      severity: json['severity'] ?? 'LOW',
    );
  }
}

class IncidentPage {
  final List<IncidentListResponse> items;
  final bool isLast;
  final int? totalElements;

  /// True when the page was served from the offline cache.
  final bool fromCache;

  const IncidentPage({
    required this.items,
    required this.isLast,
    this.totalElements,
    this.fromCache = false,
  });

  factory IncidentPage.fromJson(Map<String, dynamic> json, {bool fromCache = false}) {
    return IncidentPage(
      items: (json['content'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(IncidentListResponse.fromJson)
          .toList(),
      isLast: json['last'] != false,
      totalElements: json['totalElements'] is int ? json['totalElements'] as int : null,
      fromCache: fromCache,
    );
  }
}

class AssigneeInfo {
  final int userId;
  final String name;
  final String? avatarUrl;

  AssigneeInfo({required this.userId, required this.name, this.avatarUrl});

  factory AssigneeInfo.fromJson(Map<String, dynamic> json) {
    return AssigneeInfo(
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
    );
  }
}

class IncidentActivityResponse {
  final int id;
  final String eventType;
  final String? message;
  final AssigneeInfo? performedBy;
  final DateTime createdAt;

  IncidentActivityResponse({
    required this.id,
    required this.eventType,
    this.message,
    this.performedBy,
    required this.createdAt,
  });

  factory IncidentActivityResponse.fromJson(Map<String, dynamic> json) {
    return IncidentActivityResponse(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      eventType: json['eventType'] ?? 'COMMENT',
      message: json['message'],
      performedBy: json['performedBy'] != null
          ? AssigneeInfo.fromJson(json['performedBy'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class IncidentDetailResponse {
  final int id;
  final String code;
  final DateTime createdAt;
  final String status;
  final String severity;
  final String? branchName;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final double? rating;
  final String? reviewComment;
  final Map<String, double> metrics;
  final List<AssigneeInfo> assignees;
  final List<IncidentActivityResponse> activities;
  final String? resolutionSummary;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;

  /// True when the detail was served from the offline cache.
  final bool fromCache;

  IncidentDetailResponse({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.status,
    required this.severity,
    this.branchName,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.rating,
    this.reviewComment,
    required this.metrics,
    required this.assignees,
    required this.activities,
    this.resolutionSummary,
    this.reviewedAt,
    this.resolvedAt,
    this.fromCache = false,
  });

  bool get isClosed => status == 'RESOLVED' || status == 'CLOSED';

  List<String> get metricNames => metrics.keys.toList();

  factory IncidentDetailResponse.fromJson(Map<String, dynamic> json, {bool fromCache = false}) {
    final Map<String, double> parsedMetrics = {};
    if (json['metrics'] is Map<String, dynamic>) {
      (json['metrics'] as Map<String, dynamic>).forEach((key, val) {
        parsedMetrics[key] = (val is num)
            ? val.toDouble()
            : double.tryParse(val.toString()) ?? 0.0;
      });
    } else if (json['metrics'] is List) {
      for (final m in json['metrics'] as List<dynamic>) {
        parsedMetrics[m.toString()] = 0.0;
      }
    }

    return IncidentDetailResponse(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'OPEN',
      severity: json['severity'] ?? 'LOW',
      branchName: json['locationName'] ??
          json['branchName'] ??
          json['branch']?['name'] ??
          json['location'],
      customerName: json['customerName'] ?? json['customer']?['name'],
      customerEmail: json['customerEmail'] ?? json['customer']?['email'],
      customerPhone: json['customerPhone'] ?? json['customer']?['phone'],
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null,
      reviewComment: json['reviewText'] ?? json['reviewComment'] ?? json['comment'],
      metrics: parsedMetrics,
      assignees: (json['assignees'] as List<dynamic>?)
              ?.map((e) => AssigneeInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => IncidentActivityResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      resolutionSummary: json['resolutionSummary'],
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'].toString()) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'].toString()) : null,
      fromCache: fromCache,
    );
  }
}
