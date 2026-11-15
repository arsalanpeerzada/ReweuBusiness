import 'dart:convert';

class SupportConfig {
  final String phone;
  final String? whatsapp;
  final String? email;
  final String supportHours;
  final bool isChatEnabled;
  final DateTime? updatedAt;

  const SupportConfig({
    required this.phone,
    this.whatsapp,
    this.email,
    required this.supportHours,
    this.isChatEnabled = true,
    this.updatedAt,
  });

  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasWhatsapp => whatsapp != null && whatsapp!.trim().isNotEmpty;
  bool get hasEmail => email != null && email!.trim().isNotEmpty;

  factory SupportConfig.fromJson(Map<String, dynamic> json) {
    return SupportConfig(
      phone: json['phone']?.toString().trim() ?? '',
      whatsapp: json['whatsapp']?.toString().trim(),
      email: json['email']?.toString().trim(),
      supportHours: json['supportHours']?.toString().trim() ?? '',
      isChatEnabled: json['isChatEnabled'] is bool ? json['isChatEnabled'] as bool : true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'supportHours': supportHours,
        'isChatEnabled': isChatEnabled,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  static SupportConfig? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SupportConfig.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }
}

class SupportMessage {
  final int id;
  final int threadId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final int? incidentId;
  final String? incidentCode;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.incidentId,
    this.incidentCode,
    required this.createdAt,
  });

  bool get isFromSuperAdmin => senderRole.toUpperCase().contains('SUPER_ADMIN');

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      threadId: json['threadId'] is int
          ? json['threadId'] as int
          : int.tryParse(json['threadId']?.toString() ?? '0') ?? 0,
      senderId: json['senderId'] is int
          ? json['senderId'] as int
          : int.tryParse(json['senderId']?.toString() ?? '0') ?? 0,
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'PARTNER',
      message: json['message']?.toString() ?? '',
      incidentId: json['incidentId'] is int
          ? json['incidentId'] as int
          : int.tryParse(json['incidentId']?.toString() ?? ''),
      incidentCode: json['incidentCode']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
