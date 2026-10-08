import 'package:flutter/foundation.dart';

@immutable
class AddressComponent {
  const AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromMap(Map<String, dynamic> map) {
    return AddressComponent(
      longName:
          map['longText']?.toString() ?? map['long_name']?.toString() ?? '',
      shortName:
          map['shortText']?.toString() ?? map['short_name']?.toString() ?? '',
      types: ((map['types'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  final String longName;
  final String shortName;
  final List<String> types;
}

@immutable
class PlaceDetailsModel {
  const PlaceDetailsModel({
    this.lat,
    this.lng,
    this.addressComponents = const [],
  });

  factory PlaceDetailsModel.fromMap(Map<String, dynamic> map) {
    final locationMap = map['location'] is Map
        ? map['location'] as Map
        : ((map['geometry'] as Map<String, dynamic>?)?['location']
              as Map<String, dynamic>?);

    final rawLat =
        locationMap?['latitude'] ??
        locationMap?['lat'] ??
        map['latitude'] ??
        map['lat'];
    final rawLng =
        locationMap?['longitude'] ??
        locationMap?['lng'] ??
        map['longitude'] ??
        map['lng'];

    final componentsRaw = map['addressComponents'] ?? map['address_components'];
    final components = ((componentsRaw as List?) ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => AddressComponent.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return PlaceDetailsModel(
      lat: _toDouble(rawLat),
      lng: _toDouble(rawLng),
      addressComponents: components,
    );
  }

  factory PlaceDetailsModel.fromOsmResult(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final rawLat = location?['lat'];
    final rawLng = location?['lng'];

    return PlaceDetailsModel(
      lat: _toDouble(rawLat),
      lng: _toDouble(rawLng),
      addressComponents: [
        AddressComponent(
          longName: result['city']?.toString() ?? '',
          shortName: '',
          types: const ['locality'],
        ),
        AddressComponent(
          longName: result['state']?.toString() ?? '',
          shortName: '',
          types: const ['administrative_area_level_1'],
        ),
        AddressComponent(
          longName: result['country']?.toString() ?? '',
          shortName: '',
          types: const ['country'],
        ),
      ],
    );
  }

  final double? lat;
  final double? lng;
  final List<AddressComponent> addressComponents;

  String component(String type) {
    for (final c in addressComponents) {
      if (c.types.contains(type)) return c.longName;
    }
    return '';
  }

  String get city => component('locality');
  String get state => component('administrative_area_level_1');
  String get country => component('country');

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
