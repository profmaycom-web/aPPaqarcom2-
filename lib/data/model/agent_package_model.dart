import 'package:ebroker/data/model/subscription_pacakage_model.dart';

class AgentPackageResponseModel {
  AgentPackageResponseModel({required this.packages});

  factory AgentPackageResponseModel.fromJson(Map<String, dynamic> json) =>
      AgentPackageResponseModel(
        packages: (json['data'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(AgentPackageModel.fromJson)
            .toList(),
      );

  final List<AgentPackageModel> packages;
}

class AgentPackageModel {
  AgentPackageModel({
    required this.id,
    required this.name,
    required this.iosProductId,
    required this.packageType,
    required this.purchaseType,
    required this.price,
    required this.duration,
    required this.listDurationType,
    required this.status,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    required this.packageFeatures,
  });

  factory AgentPackageModel.fromJson(Map<String, dynamic> json) =>
      AgentPackageModel(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        iosProductId: json['ios_product_id']?.toString(),
        packageType: json['package_type']?.toString() ?? '',
        purchaseType: json['purchase_type']?.toString() ?? '',
        price: json['price'] as num?,
        duration: json['duration'] as int? ?? 0,
        listDurationType: json['list_duration_type']?.toString() ?? '',
        status: json['status'] as bool? ?? false,
        userType: json['user_type']?.toString() ?? '',
        createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          json['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
        ),
        packageFeatures: (json['package_features'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(AgentPackageFeature.fromJson)
            .toList(),
      );

  final int id;
  final String name;
  final String? iosProductId;
  final String packageType;
  final String purchaseType;
  final num? price;
  final int duration;
  final String listDurationType;
  final bool status;
  final String userType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AgentPackageFeature> packageFeatures;

  bool get isFree => packageType == 'free' || (price == null || price == 0);
}

class AgentPackageFeature {
  AgentPackageFeature({
    required this.id,
    required this.packageId,
    required this.featureId,
    required this.limitType,
    required this.limit,
    required this.feature,
  });

  factory AgentPackageFeature.fromJson(Map<String, dynamic> json) =>
      AgentPackageFeature(
        id: json['id'] as int,
        packageId: json['package_id'] as int,
        featureId: json['feature_id'] as int,
        limitType: AdvertisementLimit.values.firstWhere(
          (e) => e.toString() == 'AdvertisementLimit.${json["limit_type"]}',
          orElse: () => AdvertisementLimit.limited,
        ),
        limit: json['limit'] as int?,
        feature: AgentFeature.fromJson(
          json['feature'] as Map<String, dynamic>? ?? {},
        ),
      );

  final int id;
  final int packageId;
  final int featureId;
  final AdvertisementLimit limitType;
  final int? limit;
  final AgentFeature feature;

  bool get isIncluded =>
      limitType == AdvertisementLimit.unlimited ||
      (limit != null && limit! > 0);
}

class AgentFeature {
  AgentFeature({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.userType,
  });

  factory AgentFeature.fromJson(Map<String, dynamic> json) => AgentFeature(
    id: json['id'] as int? ?? 0,
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    status: json['status'] as bool? ?? false,
    userType: json['user_type']?.toString() ?? '',
  );

  final int id;
  final String name;
  final String type;
  final bool status;
  final String userType;
}
