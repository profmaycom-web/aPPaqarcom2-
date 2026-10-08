class ComparePropertyModel {
  ComparePropertyModel({this.sourceProperty, this.targetProperty});

  ComparePropertyModel.fromJson(Map<String, dynamic> json) {
    sourceProperty = json['source_property'] is Map
        ? SourceProperty.fromJson(
            Map<String, dynamic>.from(json['source_property'] as Map),
          )
        : null;
    targetProperty = json['target_property'] is Map
        ? TargetProperty.fromJson(
            Map<String, dynamic>.from(json['target_property'] as Map),
          )
        : null;
  }
  SourceProperty? sourceProperty;
  TargetProperty? targetProperty;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (sourceProperty != null) {
      data['source_property'] = sourceProperty?.toJson();
    }
    if (targetProperty != null) {
      data['target_property'] = targetProperty?.toJson();
    }
    return data;
  }
}

class SourceProperty {
  SourceProperty({
    this.id,
    this.title,
    this.translatedTitle,
    this.titleImage,
    this.city,
    this.state,
    this.country,
    this.isPremium,
    this.address,
    this.createdAt,
    this.price,
    this.rentduration,
    this.propertyType,
    this.totalLikes,
    this.totalViews,
    this.facilities,
    this.nearByPlaces,
    this.category,
    this.translatedDescription,
  });

  SourceProperty.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');
    title = json['title']?.toString() ?? '';
    translatedTitle = json['translated_title']?.toString() ?? '';
    titleImage = json['title_image']?.toString() ?? '';
    city = json['city']?.toString() ?? '';
    state = json['state']?.toString() ?? '';
    country = json['country']?.toString() ?? '';
    isPremium = json['is_premium']?.toString() ?? '0';
    address = json['address']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    price = json['price']?.toString() ?? '';
    rentduration = json['rentduration']?.toString() ?? '';
    propertyType = json['property_type']?.toString() ?? '';
    totalLikes = json['total_likes']?.toString() ?? '0';
    totalViews = json['total_views']?.toString() ?? '0';
    if (json['facilities'] is List) {
      facilities = <Facilities>[];
      for (final dynamic v in json['facilities'] as List) {
        if (v is Map) {
          facilities!.add(
            Facilities.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }
    if (json['near_by_places'] is List) {
      nearByPlaces = <NearByPlaces>[];
      for (final dynamic v in json['near_by_places'] as List) {
        if (v is Map) {
          nearByPlaces!.add(
            NearByPlaces.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }
    category = json['category'] is Map
        ? Category.fromJson(Map<String, dynamic>.from(json['category'] as Map))
        : null;
    translatedDescription = json['translated_description']?.toString() ?? '';
  }
  int? id;
  String? title;
  String? translatedTitle;
  String? titleImage;
  String? city;
  String? state;
  String? country;
  String? isPremium;
  String? address;
  String? createdAt;
  String? price;
  String? rentduration;
  String? propertyType;
  String? totalLikes;
  String? totalViews;
  List<Facilities>? facilities;
  List<NearByPlaces>? nearByPlaces;
  Category? category;
  String? translatedDescription;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['translated_title'] = translatedTitle;
    data['title_image'] = titleImage;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    data['is_premium'] = isPremium;
    data['address'] = address;
    data['created_at'] = createdAt;
    data['price'] = price;
    data['rentduration'] = rentduration;
    data['property_type'] = propertyType;
    data['total_likes'] = totalLikes;
    data['total_views'] = totalViews;
    if (facilities != null) {
      data['facilities'] = facilities!.map((v) => v.toJson()).toList();
    }
    if (nearByPlaces != null) {
      data['near_by_places'] = nearByPlaces!.map((v) => v.toJson()).toList();
    }
    if (category != null) {
      data['category'] = category!.toJson();
    }
    data['translated_description'] = translatedDescription;
    return data;
  }
}

class Category {
  Category({
    this.id,
    this.name,
    this.image,
    this.translatedName,
  });

  Category.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');
    name = json['category']?.toString() ?? json['name']?.toString();
    image = json['image']?.toString() ?? '';
    translatedName = json['translated_name']?.toString() ?? '';
  }
  int? id;
  String? name;
  String? image;
  String? translatedName;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['translated_name'] = translatedName;
    return data;
  }
}

class TypeValue {
  TypeValue({
    this.value,
  });

  TypeValue.fromJson(Map<String, dynamic> json) {
    value = json['value']?.toString() ?? '';
  }
  String? value;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['value'] = value;
    return data;
  }
}

class Translation {
  Translation({
    this.languageId,
    this.value,
  });

  Translation.fromJson(Map<String, dynamic> json) {
    languageId = json['language_id'];
    value = json['value']?.toString();
  }
  dynamic languageId;
  String? value;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['language_id'] = languageId;
    data['value'] = value;
    return data;
  }
}

class TranslatedOptionValue {
  TranslatedOptionValue({
    this.value,
    this.translated,
  });

  TranslatedOptionValue.fromJson(Map<String, dynamic> json) {
    value = json['value']?.toString() ?? '';
    translated = json['translated']?.toString() ?? '';
  }
  String? value;
  String? translated;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['value'] = value;
    data['translated'] = translated;
    return data;
  }
}

class Facilities {
  Facilities({
    this.id,
    this.name,
    this.translatedName,
    this.image,
    this.isRequired,
    this.typeOfParameter,
    this.typeValues,
    this.translatedOptionValue,
    this.value,
    this.translations,
  });

  Facilities.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString() ?? '';
    translatedName = json['translated_name']?.toString() ?? '';
    image = json['image']?.toString() ?? '';
    isRequired = json['is_required']?.toString() ?? '0';
    typeOfParameter = json['type_of_parameter']?.toString() ?? '';
    if (json['type_values'] is List) {
      typeValues = <TypeValue>[];
      for (final dynamic v in json['type_values'] as List) {
        if (v is Map) {
          typeValues!.add(
            TypeValue.fromJson(Map<String, dynamic>.from(v)),
          );
        } else if (v is String) {
          typeValues!.add(TypeValue.fromJson({'value': v}));
        } else {
          typeValues!.add(TypeValue.fromJson({}));
        }
      }
    }
    if (json['translated_option_value'] is List) {
      translatedOptionValue = <TranslatedOptionValue>[];
      for (final dynamic v in json['translated_option_value'] as List) {
        if (v is Map) {
          translatedOptionValue!.add(
            TranslatedOptionValue.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }
    value = json['value'];
    if (json['translations'] is List) {
      translations = <Translation>[];
      for (final dynamic v in json['translations'] as List) {
        if (v is Map) {
          translations!.add(
            Translation.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }
  }
  int? id;
  String? name;
  String? translatedName;
  String? image;
  String? isRequired;
  String? typeOfParameter;
  List<TypeValue>? typeValues;
  List<TranslatedOptionValue>? translatedOptionValue;
  dynamic value;
  List<Translation>? translations;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['translated_name'] = translatedName;
    data['image'] = image;
    data['is_required'] = isRequired;
    data['type_of_parameter'] = typeOfParameter;
    if (typeValues != null) {
      data['type_values'] = typeValues!.map((v) => v.toJson()).toList();
    }
    if (translatedOptionValue != null) {
      data['translated_option_value'] = translatedOptionValue!
          .map((v) => v.toJson())
          .toList();
    }
    data['value'] = value;
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NearByPlaces {
  NearByPlaces({
    this.id,
    this.propertyId,
    this.facilityId,
    this.distance,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.translatedName,
    this.image,
    this.translations,
  });

  NearByPlaces.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');
    propertyId = json['property_id']?.toString() ?? '';
    facilityId = json['facility_id']?.toString() ?? '';
    distance = json['distance']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
    translatedName = json['translated_name']?.toString() ?? '';
    image = json['image']?.toString() ?? '';
    if (json['translations'] is List) {
      translations = <Translation>[];
      for (final dynamic v in json['translations'] as List) {
        if (v is Map) {
          translations!.add(
            Translation.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }
  }
  int? id;
  String? propertyId;
  String? facilityId;
  String? distance;
  String? createdAt;
  String? updatedAt;
  String? name;
  String? translatedName;
  String? image;
  List<Translation>? translations;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['property_id'] = propertyId;
    data['facility_id'] = facilityId;
    data['distance'] = distance;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['name'] = name;
    data['translated_name'] = translatedName;
    data['image'] = image;
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TargetProperty {
  TargetProperty({
    this.id,
    this.title,
    this.translatedTitle,
    this.titleImage,
    this.city,
    this.state,
    this.country,
    this.isPremium,
    this.address,
    this.createdAt,
    this.price,
    this.rentduration,
    this.propertyType,
    this.totalLikes,
    this.totalViews,
    this.facilities,
    this.nearByPlaces,
    this.category,
    this.translatedDescription,
  });

  TargetProperty.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');
    title = json['title']?.toString() ?? '';
    translatedTitle = json['translated_title']?.toString() ?? '';
    titleImage = json['title_image']?.toString() ?? '';
    city = json['city']?.toString() ?? '';
    state = json['state']?.toString() ?? '';
    country = json['country']?.toString() ?? '';
    isPremium = json['is_premium']?.toString() ?? '0';
    address = json['address']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    price = json['price']?.toString() ?? '';
    rentduration = json['rentduration']?.toString() ?? '';
    propertyType = json['property_type']?.toString() ?? '';
    totalLikes = json['total_likes']?.toString() ?? '0';
    totalViews = json['total_views']?.toString() ?? '0';
    if (json['facilities'] is List) {
      facilities = <Facilities>[];
      for (final dynamic v in json['facilities'] as List) {
        if (v is Map) {
          facilities!.add(
            Facilities.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }
    if (json['near_by_places'] is List) {
      nearByPlaces = <NearByPlaces>[];
      for (final dynamic v in json['near_by_places'] as List) {
        if (v is Map) {
          nearByPlaces!.add(
            NearByPlaces.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }
    category = json['category'] is Map
        ? Category.fromJson(Map<String, dynamic>.from(json['category'] as Map))
        : null;
    translatedDescription = json['translated_description']?.toString() ?? '';
  }
  int? id;
  String? title;
  String? translatedTitle;
  String? titleImage;
  String? city;
  String? state;
  String? country;
  String? isPremium;
  String? address;
  String? createdAt;
  String? price;
  String? rentduration;
  String? propertyType;
  String? totalLikes;
  String? totalViews;
  List<Facilities>? facilities;
  List<NearByPlaces>? nearByPlaces;
  Category? category;
  String? translatedDescription;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['translated_title'] = translatedTitle;
    data['title_image'] = titleImage;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    data['is_premium'] = isPremium;
    data['address'] = address;
    data['created_at'] = createdAt;
    data['price'] = price;
    data['rentduration'] = rentduration;
    data['property_type'] = propertyType;
    data['total_likes'] = totalLikes;
    data['total_views'] = totalViews;
    if (facilities != null) {
      data['facilities'] = facilities!.map((v) => v.toJson()).toList();
    }
    if (nearByPlaces != null) {
      data['near_by_places'] = nearByPlaces!.map((v) => v.toJson()).toList();
    }
    if (category != null) {
      data['category'] = category!.toJson();
    }
    data['translated_description'] = translatedDescription;
    return data;
  }
}
