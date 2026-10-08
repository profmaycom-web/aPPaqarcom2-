import 'package:ebroker/data/model/property_model.dart';

class PropertySectionsModel {
  PropertySectionsModel({
    required this.nearbyProperties,
    required this.featuredProperties,
    required this.mostViewedProperties,
    required this.mostLikedProperties,
    required this.premiumProperties,
    required this.curatedProperties,
    required this.locationBasedData,
    this.nearbySectionId,
    this.featuredSectionId,
    this.mostViewedSectionId,
    this.mostLikedSectionId,
    this.premiumSectionId,
    this.curatedSectionId,
  });

  factory PropertySectionsModel.fromApiResponse(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};

    final nearby = _parseSectionList<PropertyModel>(
      data['nearby_properties'],
      PropertyModel.fromMap,
    );
    final featured = _parseSectionList<PropertyModel>(
      data['featured_properties'],
      PropertyModel.fromMap,
    );
    final mostViewed = _parseSectionList<PropertyModel>(
      data['most_viewed_properties'],
      PropertyModel.fromMap,
    );
    final mostLiked = _parseSectionList<PropertyModel>(
      data['most_liked_properties'],
      PropertyModel.fromMap,
    );
    final premium = _parseSectionList<PropertyModel>(
      data['premium_properties'],
      PropertyModel.fromMap,
    );
    final curated = _parseSectionList<PropertyModel>(
      data['curated_properties'],
      PropertyModel.fromMap,
    );

    return PropertySectionsModel(
      nearbyProperties: nearby.items,
      featuredProperties: featured.items,
      mostViewedProperties: mostViewed.items,
      mostLikedProperties: mostLiked.items,
      premiumProperties: premium.items,
      curatedProperties: curated.items,
      locationBasedData: data['location_based_data'] as bool? ?? false,
      nearbySectionId: nearby.sectionId,
      featuredSectionId: featured.sectionId,
      mostViewedSectionId: mostViewed.sectionId,
      mostLikedSectionId: mostLiked.sectionId,
      premiumSectionId: premium.sectionId,
      curatedSectionId: curated.sectionId,
    );
  }

  final List<PropertyModel> nearbyProperties;
  final List<PropertyModel> featuredProperties;
  final List<PropertyModel> mostViewedProperties;
  final List<PropertyModel> mostLikedProperties;
  final List<PropertyModel> premiumProperties;
  final List<PropertyModel> curatedProperties;
  final bool locationBasedData;

  final int? nearbySectionId;
  final int? featuredSectionId;
  final int? mostViewedSectionId;
  final int? mostLikedSectionId;
  final int? premiumSectionId;
  final int? curatedSectionId;
}

({int? sectionId, List<T> items}) _parseSectionList<T>(
  dynamic node,
  T Function(Map<String, dynamic>) fromMap,
) {
  if (node is! Map) return (sectionId: null, items: <T>[]);
  final map = node.cast<String, dynamic>();
  final sectionId = map['section_id'] as int?;
  final list = (map['data'] as List? ?? const [])
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => fromMap(Map<String, dynamic>.from(e)))
      .toList();
  return (sectionId: sectionId, items: list);
}
