import 'package:ebroker/utils/extensions/lib/list.dart';

class PersonalizedInterestSettings {
  PersonalizedInterestSettings({
    required this.userId,
    required this.categoryIds,
    required this.priceRange,
    required this.propertyType,
    required this.outdoorFacilityIds,
    required this.countryIds,
  });

  factory PersonalizedInterestSettings.fromMap(Map<String, dynamic> map) {
    return PersonalizedInterestSettings(
      userId: map['user_id'] as int,
      categoryIds: (map['category_ids'] is String)
          ? []
          : ((map['category_ids']) as List).forceInt(),
      priceRange: (map['price_range'] is String)
          ? [0, 50]
          : (map['price_range'] as List).forceDouble(),
      propertyType: (map['property_type'] is String)
          ? []
          : (map['property_type'] as List).forceInt(),
      outdoorFacilityIds: (map['outdoor_facilitiy_ids'] is String)
          ? []
          : (map['outdoor_facilitiy_ids'] as List? ?? []).forceInt(),
      countryIds: (map['country_ids'] is List)
          ? (map['country_ids'] as List).forceInt()
          : <int>[],
    );
  }

  factory PersonalizedInterestSettings.empty() {
    return PersonalizedInterestSettings(
      userId: 0,
      categoryIds: [],
      priceRange: [0, 1],
      propertyType: [],
      outdoorFacilityIds: [],
      countryIds: [],
    );
  }
  final int userId;
  final List<int> categoryIds;
  final List<double> priceRange;
  final List<int> propertyType;
  final List<int> outdoorFacilityIds;
  final List<int> countryIds;

  @override
  String toString() {
    return '''PersonalizedInterestSettings{userId: $userId, categoryIds: $categoryIds, priceRange: $priceRange, propertyType: $propertyType, outdoorFacilityIds: $outdoorFacilityIds, countryIds: $countryIds}''';
  }
}
