class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginUserResponse {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String userName;
  final String? createdAt;
  final String token;
  final List<String> roles;
  final List<String> permissions;
  final String subscriptionTier;

  LoginUserResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userName,
    this.createdAt,
    required this.token,
    this.roles = const [],
    this.permissions = const [],
    this.subscriptionTier = 'FREE',
  });

  bool get isSuperAdmin => roles.contains('SUPER_ADMIN');
  bool get isAdmin =>
      roles.contains('ADMIN') ||
      roles.contains('BUSINESS_OWNER') ||
      roles.contains('BRANCH_ADMIN');

  factory LoginUserResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString() ??
        json['accessToken']?.toString() ??
        json['jwt']?.toString() ??
        json['jwtToken']?.toString() ??
        json['authToken']?.toString() ??
        '';

    return LoginUserResponse(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      token: token,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      permissions:
          (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      subscriptionTier: json['subscriptionTier']?.toString() ?? 'FREE',
    );
  }
}

class BranchSummary {
  final int id;
  final String name;
  final int businessId;
  final String? locationName;

  const BranchSummary({
    required this.id,
    required this.name,
    required this.businessId,
    this.locationName,
  });

  factory BranchSummary.fromJson(Map<String, dynamic> json) {
    return BranchSummary(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? json['branchName']?.toString() ?? '',
      businessId: json['businessId'] is int
          ? json['businessId']
          : int.tryParse(json['businessId']?.toString() ?? '') ?? 0,
      locationName: json['locationName']?.toString() ?? json['address']?.toString(),
    );
  }
}

class BusinessSummary {
  final int id;
  final String name;
  final double overAllRating;
  final String? description;
  final String? businessTypeName;
  final String? categoryName;
  final String? locationName;
  final String? logoUrl;

  BusinessSummary({
    required this.id,
    required this.name,
    required this.overAllRating,
    this.description,
    this.businessTypeName,
    this.categoryName,
    this.locationName,
    this.logoUrl,
  });

  factory BusinessSummary.fromJson(Map<String, dynamic> json) {
    return BusinessSummary(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      overAllRating: json['overAllRating'] != null
          ? double.tryParse(json['overAllRating'].toString()) ?? 0.0
          : 0.0,
      description: json['description']?.toString(),
      businessTypeName: json['businessTypeName']?.toString(),
      categoryName: json['categoryName']?.toString(),
      locationName: json['locationName']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }
}
