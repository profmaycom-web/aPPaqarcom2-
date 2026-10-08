class PackageResponseModel {
  PackageResponseModel({
    required this.subscriptionPackage,
    required this.activePackage,
    required this.allFeature,
    required this.payAsYouGo,
  });

  factory PackageResponseModel.fromJson(Map<String, dynamic> json) =>
      PackageResponseModel(
        subscriptionPackage: (json['data'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(SubscriptionPackageModel.fromJson)
            .toList(),
        activePackage: (json['active_packages'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ActivePackage.fromJson)
            .toList(),
        allFeature: (json['all_features'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(AllFeature.fromJson)
            .toList(),
        payAsYouGo: (json['pay_as_you_go'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(PayAsYouGoModel.fromJson)
            .toList(),
      );

  List<SubscriptionPackageModel> subscriptionPackage;
  List<ActivePackage> activePackage;
  List<AllFeature> allFeature;
  List<PayAsYouGoModel> payAsYouGo;
}

class PayAsYouGoModel {
  PayAsYouGoModel({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.iosProductId,
  });

  factory PayAsYouGoModel.fromJson(Map<String, dynamic> json) =>
      PayAsYouGoModel(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        price: json['price'] as num? ?? 0,
        type: json['type']?.toString() ?? '',
        status: json['status'] as int? ?? 0,
        iosProductId: json['ios_product_id']?.toString(),
        createdAt: DateTime.parse(
          json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          json['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
        ),
      );

  int id;
  String name;
  num price;
  String type;
  int status;
  String? iosProductId;
  DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'type': type,
    'status': status,
    'ios_product_id': iosProductId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class SubscriptionPackageModel {
  SubscriptionPackageModel({
    required this.id,
    required this.iosProductId,
    required this.name,
    required this.translatedName,
    required this.packageType,
    required this.price,
    required this.duration,
    required this.createdAt,
    required this.features,
    required this.packageStatus,
    this.paymentTransactionId,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionPackageModel(
        id: json['id'] as int,
        iosProductId: json['ios_product_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        translatedName: json['translated_name']?.toString() ?? '',
        packageType: json['package_type']?.toString() ?? '',
        price: json['price'] as num? ?? 0,
        duration: json['duration'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at']?.toString() ?? ''),
        features: List<PackageFeatures>.from(
          (json['features'] as List? ?? []).map(
            (x) => PackageFeatures.fromJson(x as Map<String, dynamic>? ?? {}),
          ),
        ),
        packageStatus: json['package_status']?.toString() ?? '',
        paymentTransactionId: json['payment_transaction_id']?.toString() ?? '',
      );

  int id;
  String name;
  String? translatedName;
  String iosProductId;
  String packageType;
  num price;
  int duration;
  DateTime createdAt;
  List<PackageFeatures> features;
  String packageStatus;
  String? paymentTransactionId;
  SubscriptionPackageModel copyWith({
    int? id,
    String? iosProductId,
    String? name,
    String? translatedName,
    String? packageType,
    num? price,
    int? duration,
    DateTime? createdAt,
    List<PackageFeatures>? features,
    String? packageStatus,
    String? paymentTransactionId,
  }) => SubscriptionPackageModel(
    id: id ?? this.id,
    iosProductId: iosProductId ?? this.iosProductId,
    name: name ?? this.name,
    translatedName: translatedName ?? this.translatedName,
    packageType: packageType ?? this.packageType,
    price: price ?? this.price,
    duration: duration ?? this.duration,
    createdAt: createdAt ?? this.createdAt,
    features: features ?? this.features,
    packageStatus: packageStatus ?? this.packageStatus,
    paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ios_product_id': iosProductId,
    'name': name,
    'translated_name': translatedName,
    'package_type': packageType,
    'price': price,
    'duration': duration,
    'created_at': createdAt.toIso8601String(),
    'features': List<dynamic>.from(features.map((x) => x.toJson())),
    'package_status': packageStatus,
    'payment_transaction_id': paymentTransactionId,
  };
}

class ActivePackage {
  ActivePackage({
    required this.id,
    required this.iosProductId,
    required this.name,
    required this.translatedName,
    required this.packageType,
    required this.price,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.features,
    required this.isActive,
    required this.validUntil,
    required this.isRenewed,
    required this.isRenewAllowed,
  });

  factory ActivePackage.fromJson(Map<String, dynamic> json) => ActivePackage(
    id: json['id'] as int,
    iosProductId: json['ios_product_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    translatedName: json['translated_name']?.toString() ?? '',
    packageType: json['package_type']?.toString() ?? '',
    price: json['price'] as num? ?? 0,
    duration: json['duration'] as int? ?? 0,
    startDate: DateTime.parse(json['start_date']?.toString() ?? ''),
    endDate: DateTime.parse(json['end_date']?.toString() ?? ''),
    createdAt: DateTime.parse(json['created_at']?.toString() ?? ''),
    features: List<ActivePackageFeature>.from(
      (json['features'] as List? ?? []).map(
        (x) => ActivePackageFeature.fromJson(x as Map<String, dynamic>? ?? {}),
      ),
    ),
    isActive: json['is_active'] as int? ?? 0,
    validUntil: json['valid_until']?.toString() ?? '',
    isRenewed: json['is_renewed'] as bool? ?? false,
    isRenewAllowed: json['is_renew_allowed'] as bool? ?? false,
  );

  int id;
  String iosProductId;
  String name;
  String? translatedName;
  String packageType;
  num price;
  int duration;
  DateTime startDate;
  DateTime endDate;
  DateTime createdAt;
  List<ActivePackageFeature> features;
  int isActive;
  String validUntil;
  bool isRenewed;
  bool isRenewAllowed;

  ActivePackage copyWith({
    int? id,
    String? iosProductId,
    String? name,
    String? translatedName,
    String? packageType,
    num? price,
    int? duration,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    List<ActivePackageFeature>? features,
    int? isActive,
    String? validUntil,
    bool? isRenewed,
    bool? isRenewAllowed,
  }) => ActivePackage(
    id: id ?? this.id,
    iosProductId: iosProductId ?? this.iosProductId,
    name: name ?? this.name,
    translatedName: translatedName ?? this.translatedName,
    packageType: packageType ?? this.packageType,
    price: price ?? this.price,
    duration: duration ?? this.duration,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    createdAt: createdAt ?? this.createdAt,
    features: features ?? this.features,
    isActive: isActive ?? this.isActive,
    validUntil: validUntil ?? this.validUntil,
    isRenewed: isRenewed ?? this.isRenewed,
    isRenewAllowed: isRenewAllowed ?? this.isRenewAllowed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ios_product_id': iosProductId,
    'name': name,
    'translated_name': translatedName,
    'package_type': packageType,
    'price': price,
    'duration': duration,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'features': List<dynamic>.from(features.map((x) => x.toJson())),
    'is_active': isActive,
    'valid_until': validUntil,
    'is_renewed': isRenewed,
    'is_renew_allowed': isRenewAllowed,
  };
}

class ActivePackageFeature {
  ActivePackageFeature({
    required this.id,
    required this.name,
    required this.translatedName,
    required this.limitType,
    required this.limit,
    required this.usedLimit,
    required this.totalLimit,
  });

  factory ActivePackageFeature.fromJson(Map<String, dynamic> json) =>
      ActivePackageFeature(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        translatedName: json['translated_name']?.toString() ?? '',
        limitType: AdvertisementLimit.values.firstWhere(
          (e) => e.toString() == 'AdvertisementLimit.${json["limit_type"]}',
        ),
        limit: json['limit'] as int? ?? 0,
        usedLimit: json['used_limit'] as int? ?? 0,
        totalLimit: json['total_limit'] as int? ?? 0,
      );

  int id;
  String name;
  String? translatedName;
  AdvertisementLimit limitType;
  int? limit;
  int? usedLimit;
  int? totalLimit;

  ActivePackageFeature copyWith({
    int? id,
    String? name,
    String? translatedName,
    AdvertisementLimit? limitType,
    int? limit,
    int? usedLimit,
    int? totalLimit,
  }) => ActivePackageFeature(
    id: id ?? this.id,
    name: name ?? this.name,
    translatedName: translatedName ?? this.translatedName,
    limitType: limitType ?? this.limitType,
    limit: limit ?? this.limit,
    usedLimit: usedLimit ?? this.usedLimit,
    totalLimit: totalLimit ?? this.totalLimit,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'translated_name': translatedName,
    'limit_type': limitType.toString().split('.').last,
    'limit': limit,
    'used_limit': usedLimit,
    'total_limit': totalLimit,
  };
}

enum AdvertisementLimit { limited, unlimited }

class AllFeature {
  AllFeature({
    required this.id,
    required this.name,
    required this.translatedName,
    required this.status,
  });

  factory AllFeature.fromJson(Map<String, dynamic> json) => AllFeature(
    id: json['id'] as int,
    name: json['name']?.toString() ?? '',
    translatedName: json['translated_name']?.toString() ?? '',
    status: json['status'] as int? ?? 0,
  );

  int id;
  String name;
  String? translatedName;
  int status;

  AllFeature copyWith({
    int? id,
    String? name,
    String? translatedName,
    int? status,
  }) => AllFeature(
    id: id ?? this.id,
    name: name ?? this.name,
    translatedName: translatedName ?? this.translatedName,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'translated_name': translatedName,
    'status': status,
  };
}

class PackageFeatures {
  PackageFeatures({
    required this.id,
    required this.name,
    required this.translatedName,
    required this.limitType,
    required this.limit,
  });

  factory PackageFeatures.fromJson(Map<String, dynamic> json) =>
      PackageFeatures(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        translatedName: json['translated_name']?.toString() ?? '',
        limitType: AdvertisementLimit.values.firstWhere(
          (e) => e.toString() == 'AdvertisementLimit.${json["limit_type"]}',
        ),
        limit: json['limit'] as int? ?? 0,
      );

  int id;
  String name;
  String? translatedName;
  AdvertisementLimit limitType;
  int? limit;

  PackageFeatures copyWith({
    int? id,
    String? name,
    String? translatedName,
    AdvertisementLimit? limitType,
    int? limit,
  }) => PackageFeatures(
    id: id ?? this.id,
    name: name ?? this.name,
    translatedName: translatedName ?? this.translatedName,
    limitType: limitType ?? this.limitType,
    limit: limit ?? this.limit,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'translated_name': translatedName,
    'limit_type': limitType.toString().split('.').last,
    'limit': limit,
  };
}

class BankTransferResponseModel {
  BankTransferResponseModel({
    required this.userId,
    required this.packageId,
    required this.amount,
    required this.paymentGateway,
    required this.paymentStatus,
    required this.orderId,
    required this.paymentType,
    required this.updatedAt,
    required this.createdAt,
    required this.id,
  });

  factory BankTransferResponseModel.fromJson(Map<String, dynamic> json) =>
      BankTransferResponseModel(
        userId: json['user_id'] as int? ?? 0,
        packageId: json['package_id'] as int? ?? 0,
        amount: json['amount'] as num? ?? 0,
        paymentGateway: json['payment_gateway']?.toString() ?? '',
        paymentStatus: json['payment_status']?.toString() ?? '',
        orderId: json['order_id']?.toString() ?? '',
        paymentType: json['payment_type']?.toString() ?? '',
        updatedAt: DateTime.parse(json['updated_at']?.toString() ?? ''),
        createdAt: DateTime.parse(json['created_at']?.toString() ?? ''),
        id: json['id'] as int? ?? 0,
      );

  int userId;
  int packageId;
  num amount;
  String paymentGateway;
  String paymentStatus;
  String orderId;
  String paymentType;
  DateTime updatedAt;
  DateTime createdAt;
  int id;
}
