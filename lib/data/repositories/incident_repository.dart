import '../models/incident.dart';
import '../../core/network/api_service.dart';

class IncidentRepository {
  final ApiService _apiService;

  IncidentRepository(this._apiService);

  Future<List<IncidentListResponse>> getIncidents({
    required int businessId,
    int? branchId,
    String? status,
    int page = 0,
    int size = 50,
  }) async {
    final rawList = await _apiService.getBusinessIncidents(
      businessId,
      branchId: branchId,
      status: status,
      page: page,
      size: size,
    );

    return rawList
        .map((e) => IncidentListResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IncidentDetailResponse> getIncidentDetail(int incidentId) async {
    final rawJson = await _apiService.getIncidentDetails(incidentId);
    return IncidentDetailResponse.fromJson(rawJson);
  }

  Future<IncidentDetailResponse> addComment(int incidentId, String comment) async {
    final rawJson = await _apiService.addComment(incidentId, comment);
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
}
