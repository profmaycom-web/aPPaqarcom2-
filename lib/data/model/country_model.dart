import 'package:ebroker/data/model/languages_model.dart';
import 'package:flutter/foundation.dart';

@immutable
class CountryModel {
  const CountryModel({
    this.id,
    this.name,
    this.code,
    this.latitude,
    this.longitude,
    this.currencyId,
    this.currencyCode,
    this.currencySymbol,
    this.languages = const [],
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    var currencyId = json['currency_id'] != null
        ? int.tryParse(json['currency_id'].toString())
        : null;
    var currencyCode = json['currency_code']?.toString() ?? '';
    var currencySymbol = json['currency_symbol']?.toString() ?? '';

    if (json['currency'] is Map) {
      final curMap = json['currency'] as Map;
      if (currencyId == null && curMap['id'] != null) {
        currencyId = int.tryParse(curMap['id'].toString());
      }
      if (currencyCode.isEmpty) {
        currencyCode =
            curMap['code']?.toString() ??
            curMap['currency_code']?.toString() ??
            '';
      }
      if (currencySymbol.isEmpty) {
        currencySymbol =
            curMap['symbol']?.toString() ??
            curMap['currency_symbol']?.toString() ??
            '';
      }
    }

    final rawLanguages = json['languages'] ?? json['supported_languages'];
    final languages = <LanguagesModel>[];
    if (rawLanguages is List) {
      for (final l in rawLanguages) {
        if (l is Map) {
          languages.add(
            LanguagesModel.fromJson(Map<String, dynamic>.from(l)),
          );
        } else if (l is String && l.isNotEmpty) {
          languages.add(LanguagesModel(code: l, name: l));
        }
      }
    } else if (rawLanguages is Map) {
      languages.add(
        LanguagesModel.fromJson(Map<String, dynamic>.from(rawLanguages)),
      );
    }

    final defaultLang = json['default_language'] ?? json['language'];
    if (defaultLang is Map) {
      final parsed = LanguagesModel.fromJson(
        Map<String, dynamic>.from(defaultLang),
      );
      if (parsed.code != null && !languages.any((e) => e.code == parsed.code)) {
        languages.insert(0, parsed);
      }
    } else if (defaultLang is String && defaultLang.isNotEmpty) {
      if (!languages.any((e) => e.code == defaultLang)) {
        languages.insert(
          0,
          LanguagesModel(code: defaultLang, name: defaultLang),
        );
      }
    }

    final langId = json['language_id']?.toString();
    final langCode =
        json['language_code']?.toString() ??
        json['default_language_code']?.toString() ??
        json['lang_code']?.toString();
    final langName = json['language_name']?.toString();

    if (langCode != null && langCode.isNotEmpty) {
      final existingIndex = languages.indexWhere((e) => e.code == langCode);
      if (existingIndex >= 0) {
        final existing = languages[existingIndex];
        languages[existingIndex] = LanguagesModel(
          id: existing.id ?? langId,
          code: existing.code ?? langCode,
          name: (existing.name != null && existing.name != existing.code)
              ? existing.name
              : (langName ?? langCode),
        );
      } else {
        languages.insert(
          0,
          LanguagesModel(
            id: langId,
            code: langCode,
            name: langName ?? langCode,
          ),
        );
      }
    }

    final lat = double.tryParse(json['latitude']?.toString() ?? '');
    final lng = double.tryParse(json['longitude']?.toString() ?? '');
    final code = json['code']?.toString();

    return CountryModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name']?.toString() ?? json['country']?.toString() ?? '',
      code: code,
      latitude: lat,
      longitude: lng,
      currencyId: currencyId,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      languages: languages,
    );
  }

  final int? id;
  final String? name;
  final String? code;
  final double? latitude;
  final double? longitude;
  final int? currencyId;
  final String? currencyCode;
  final String? currencySymbol;
  final List<LanguagesModel> languages;

  String? get primaryLanguageCode {
    if (languages.isNotEmpty && languages.first.code != null) {
      return languages.first.code;
    }
    return null;
  }

  String? get primaryLanguageName {
    if (languages.isNotEmpty && languages.first.name != null) {
      return languages.first.name;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'latitude': latitude,
      'longitude': longitude,
      'currency_id': currencyId,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'languages': languages.map((e) => e.toMap()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CountryModel(id: $id, name: $name, code: $code, latitude: $latitude, longitude: $longitude, currencyId: $currencyId, currencyCode: $currencyCode, currencySymbol: $currencySymbol)';
  }
}
