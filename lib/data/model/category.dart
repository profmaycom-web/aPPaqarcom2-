import 'dart:convert';

import 'package:ebroker/utils/api.dart';

class Category {
  Category({
    this.id,
    this.category,
    this.image,
    this.parameterTypes,
    this.translatedName,
  });

  Category.fromJson(Map<String, dynamic> json) {
    id = json[Api.id] is int
        ? json[Api.id] as int
        : int.tryParse(json[Api.id]?.toString() ?? '');
    category = json[Api.category]?.toString() ?? '';
    image = json[Api.image]?.toString() ?? '';
    final rawParams = json[Api.parameterTypes];
    if (rawParams is Map) {
      parameterTypes = rawParams['parameters'] as List? ?? [];
    } else if (rawParams is List) {
      parameterTypes = rawParams;
    } else {
      parameterTypes = [];
    }
    translatedName = json['translated_name']?.toString() ?? '';
  }

  Category.fromProperty(Map<String, dynamic> json) {
    id = json[Api.id] is int
        ? json[Api.id] as int
        : int.tryParse(json[Api.id]?.toString() ?? '');
    category = json[Api.category]?.toString() ?? '';
    translatedName = json['translated_name']?.toString() ?? '';
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      category: map['category']?.toString(),
      image: map['image']?.toString(),
      parameterTypes: map['parameterTypes'] as List? ?? [],
      translatedName: map['translated_name']?.toString() ?? '',
    );
  }
  int? id;
  String? category;
  String? image;
  List<dynamic>? parameterTypes;
  String? translatedName;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'image': image,
      'parameterTypes': parameterTypes,
      'translated_name': translatedName,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return '''Category(id: $id, category: $category, image: $image, parameterTypes: $parameterTypes, translatedName: $translatedName)''';
  }
}

class Type {
  Type({this.id, this.type});

  Type.fromJson(Map<String, dynamic> json) {
    id = json[Api.id].toString();
    type = json[Api.type]?.toString() ?? '';
  }
  String? id;
  String? type;
}
