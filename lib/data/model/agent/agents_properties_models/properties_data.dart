import 'package:ebroker/data/model/category.dart';

bool _parseBool(dynamic val, {bool defaultValue = false}) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) {
    return val == '1' || val.toLowerCase() == 'true';
  }
  return defaultValue;
}

class PropertiesData {
  const PropertiesData({
    required this.id,
    required this.slugId,
    required this.city,
    required this.state,
    required this.country,
    required this.price,
    required this.categoryId,
    required this.propertyType,
    required this.title,
    required this.translatedTitle,
    required this.translatedDescription,
    required this.titleImage,
    required this.isPremium,
    required this.address,
    required this.addedBy,
    required this.promoted,
    required this.isFavourite,
    required this.category,
    required this.rentduration,
    this.currencyCode,
    this.currencySymbol,
  });

  PropertiesData.fromJson(Map<String, dynamic> json)
    : id = int.tryParse(json['id']?.toString() ?? '') ?? 0,
      slugId = json['slug_id']?.toString() ?? '',
      city = json['city']?.toString() ?? '',
      state = json['state']?.toString() ?? '',
      country = json['country']?.toString() ?? '',
      price = json['price']?.toString() ?? '',
      categoryId = json['category_id']?.toString() ?? '',
      propertyType = json['property_type']?.toString() ?? '',
      title = json['title']?.toString() ?? '',
      translatedTitle = json['translated_title']?.toString() ?? '',
      translatedDescription = json['translated_description']?.toString() ?? '',
      titleImage = json['title_image']?.toString() ?? '',
      isPremium = json['is_premium']?.toString() ?? '',
      address = json['address']?.toString() ?? '',
      addedBy = json['added_by']?.toString() ?? '',
      promoted = _parseBool(json['promoted']),
      isFavourite = json['is_favourite']?.toString() ?? '',
      category = Category.fromJson(
        json['category'] as Map<String, dynamic>? ?? {},
      ),
      rentduration = json['rentduration']?.toString() ?? '',
      currencyCode = json['property_currency'] is Map
          ? json['property_currency']['code']?.toString()
          : json['currency_code']?.toString(),
      currencySymbol = json['property_currency'] is Map
          ? json['property_currency']['symbol']?.toString()
          : json['currency_symbol']?.toString();

  final int id;
  final String slugId;
  final String city;
  final String state;
  final String country;
  final String price;
  final String categoryId;
  final String propertyType;
  final String title;
  final String? translatedTitle;
  final String? translatedDescription;
  final String titleImage;
  final String isPremium;
  final String address;
  final String addedBy;
  final bool promoted;
  final String isFavourite;
  final Category category;
  final String rentduration;
  final String? currencyCode;
  final String? currencySymbol;
}
