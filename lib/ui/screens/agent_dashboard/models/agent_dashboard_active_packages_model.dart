class AgentDashboardActivePackageFeature {
  AgentDashboardActivePackageFeature({
    required this.id,
    required this.name,
    required this.translatedName,
    required this.limitType,
    this.limit,
    this.usedLimit,
    this.totalLimit,
  });

  factory AgentDashboardActivePackageFeature.fromJson(
    Map<String, dynamic> json,
  ) {
    return AgentDashboardActivePackageFeature(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      translatedName: json['translated_name'] as String? ?? '',
      limitType: json['limit_type'] as String? ?? 'unlimited',
      limit: json['limit'] as int?,
      usedLimit: json['used_limit'] as int?,
      totalLimit: json['total_limit'] as int?,
    );
  }

  final int id;
  final String name;
  final String translatedName;
  final String limitType;
  final int? limit;
  final int? usedLimit;
  final int? totalLimit;

  bool get isUnlimited => limitType == 'unlimited';
}

class AgentDashboardActivePackageModel {
  AgentDashboardActivePackageModel({
    required this.id,
    required this.name,
    required this.translatedName,
    required this.packageType,
    required this.price,
    required this.duration,
    required this.packageStatus,
    required this.features,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  factory AgentDashboardActivePackageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AgentDashboardActivePackageModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      translatedName: json['translated_name'] as String? ?? '',
      packageType: json['package_type'] as String? ?? '',
      price: json['price'] as num? ?? 0,
      duration: json['duration'] as int? ?? 0,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      packageStatus: json['package_status'] as String? ?? '',
      features: (json['features'] as List? ?? [])
          .map(
            (e) => AgentDashboardActivePackageFeature.fromJson(
              e as Map<String, dynamic>? ?? {},
            ),
          )
          .toList(),
      isActive: json['is_active'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final String translatedName;
  final String packageType;
  final num price;
  final int duration;
  final String? startDate;
  final String? endDate;
  final String packageStatus;
  final List<AgentDashboardActivePackageFeature> features;
  final int isActive;
}
