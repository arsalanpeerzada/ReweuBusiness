import '../models/support_config.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/storage_service.dart';

class SupportRepository {
  final ApiService apiService;
  final StorageService storageService;

  SupportRepository({
    required this.apiService,
    required this.storageService,
  });

  SupportConfig? getCachedSupportConfig() {
    return SupportConfig.fromJsonString(storageService.getSupportConfigJson());
  }

  /// Fetches the latest support hotline & hours from the backend and caches
  /// them locally. Falls back to the cached config if the request fails.
  Future<SupportConfig?> getSupportConfig({bool forceRefresh = true}) async {
    final cached = getCachedSupportConfig();
    if (!forceRefresh && cached != null) {
      return cached;
    }

    try {
      final raw = await apiService.getSupportConfig();
      if (raw.isNotEmpty) {
        final config = SupportConfig.fromJson(raw);
        await storageService.saveSupportConfigJson(config.toJsonString());
        return config;
      }
      return cached;
    } catch (_) {
      return cached;
    }
  }

  Future<List<SupportMessage>> getMessages({int? incidentId}) async {
    final rawList = await apiService.getSupportMessages(incidentId: incidentId);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(SupportMessage.fromJson)
        .toList();
  }

  Future<SupportMessage> sendMessage({
    required String message,
    int? incidentId,
  }) async {
    final raw = await apiService.sendSupportMessage(
      message: message,
      incidentId: incidentId,
    );
    return SupportMessage.fromJson(raw);
  }
}
