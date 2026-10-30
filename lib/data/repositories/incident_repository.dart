import '../models/incident.dart';
import '../models/incident_analytics.dart';
import '../../core/config/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/storage_service.dart';

class IncidentRepository {
  final ApiService _apiService;

  /// Encrypted store for the last loaded feed page and viewed incidents, so
  /// the app stays usable when the connection drops.
  final StorageService? cache;

  IncidentRepository(this._apiService, {this.cache});

  Future<IncidentPage> getIncidents({
    required int businessId,
    int? branchId,
    String? status,
    int page = 0,
    int? size,
  }) async {
    final cacheKey = 'feed_${businessId}_${branchId ?? 'all'}_${status ?? 'ALL'}';
    try {
      final raw = await _apiService.getBusinessIncidents(
        businessId,
        branchId: branchId,
        status: status,
        page: page,
        size: size ?? AppConfig.incidentPageSize,
      );
      if (page == 0) await cache?.writeCache(cacheKey, raw);
      return IncidentPage.fromJson(raw);
    } on ApiException catch (e) {
      if (page == 0 && e.isOffline) {
        final cached = await cache?.readCache(cacheKey);
        if (cached is Map<String, dynamic>) {
          return IncidentPage.fromJson(cached, fromCache: true);
        }
      }
      rethrow;
    }
  }

  Future<IncidentDetailResponse> getIncidentDetail(int incidentId) async {
    final cacheKey = 'incident_$incidentId';
    try {
      final rawJson = await _apiService.getIncidentDetails(incidentId);
      await cache?.writeCache(cacheKey, rawJson);
      return IncidentDetailResponse.fromJson(rawJson);
    } on ApiException catch (e) {
      if (e.isOffline) {
        final cached = await cache?.readCache(cacheKey);
        if (cached is Map<String, dynamic>) {
          return IncidentDetailResponse.fromJson(cached, fromCache: true);
        }
      }
      rethrow;
    }
  }

  Future<IncidentDetailResponse> addComment(int incidentId, String comment) async {
    final rawJson = await _apiService.addComment(incidentId, comment);
    await cache?.writeCache('incident_$incidentId', rawJson);
    return IncidentDetailResponse.fromJson(rawJson);
  }

  Future<void> updateStatus(
    int incidentId, {
    required String status,
    String? resolutionSummary,
    bool sendVoucher = false,
    double? voucherAmount,
  }) async {
    await _apiService.updateStatus(
      incidentId,
      status: status,
      resolutionSummary: resolutionSummary,
      sendVoucher: sendVoucher,
      voucherAmount: voucherAmount,
    );
  }

  Future<IncidentAnalytics> getAnalytics({
    required int businessId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final raw = await _apiService.getIncidentAnalytics(
      businessId,
      startDate: startDate,
      endDate: endDate,
    );
    return IncidentAnalytics.fromJson(raw);
  }
}
