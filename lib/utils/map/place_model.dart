import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class PlaceModel {
  const PlaceModel({
    required this.city,
    required this.description,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.state,
    required this.country,
  });

  factory PlaceModel.fromGooglePrediction(Map<String, dynamic> raw) {
    final prediction = raw['placePrediction'] is Map
        ? Map<String, dynamic>.from(raw['placePrediction'] as Map)
        : raw;

    final textObj = prediction['text'];
    final structuredFormat = prediction['structuredFormat'];

    var description = '';
    if (textObj is Map && textObj['text'] != null) {
      description = textObj['text'].toString();
    } else {
      description =
          prediction['description']?.toString() ??
          prediction['formattedAddress']?.toString() ??
          prediction['formatted_address']?.toString() ??
          '';
    }

    final rawPlaceId =
        prediction['placeId']?.toString() ??
        prediction['place_id']?.toString() ??
        prediction['id']?.toString() ??
        '';
    final placeStr = prediction['place']?.toString() ?? '';
    final placeId = rawPlaceId.isNotEmpty
        ? rawPlaceId
        : (placeStr.startsWith('places/') ? placeStr.substring(7) : placeStr);

    var city = '';
    var state = '';
    var country = '';

    if (structuredFormat is Map) {
      final mainTextObj = structuredFormat['mainText'];
      if (mainTextObj is Map && mainTextObj['text'] != null) {
        city = mainTextObj['text'].toString();
      }
      final secondaryTextObj = structuredFormat['secondaryText'];
      if (secondaryTextObj is Map && secondaryTextObj['text'] != null) {
        final secText = secondaryTextObj['text'].toString();
        final parts = secText.split(',').map((e) => e.trim()).toList();
        if (parts.isNotEmpty) state = parts[0];
        if (parts.length > 1) country = parts.sublist(1).join(', ');
      }
    }

    if (city.isEmpty || (state.isEmpty && country.isEmpty)) {
      final terms = prediction['terms'] as List<dynamic>? ?? [];
      if (city.isEmpty) {
        city = terms.isNotEmpty && terms[0]['value'] != null
            ? terms[0]['value'].toString()
            : '';
      }
      if (state.isEmpty) {
        state = terms.length > 1 && terms[1]['value'] != null
            ? terms[1]['value'].toString()
            : '';
      }
      if (country.isEmpty) {
        country = terms.length > 2 && terms[2]['value'] != null
            ? terms[2]['value'].toString()
            : '';
      }
    }

    return PlaceModel(
      city: city,
      description: description,
      placeId: placeId,
      state: state,
      country: country,
      latitude: '',
      longitude: '',
    );
  }

  factory PlaceModel.fromGooglePlaceDetails(Map<String, dynamic> map) {
    final addressComponentsRaw =
        map['addressComponents'] ?? map['address_components'];
    var city = '';
    var state = '';
    var country = '';

    if (addressComponentsRaw is List) {
      final components = addressComponentsRaw
          .whereType<Map<dynamic, dynamic>>()
          .toList();
      String getComp(String type) {
        for (final c in components) {
          final types =
              (c['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
          if (types.contains(type)) {
            return c['longText']?.toString() ??
                c['long_name']?.toString() ??
                '';
          }
        }
        return '';
      }

      city = getComp('locality');
      if (city.isEmpty) city = getComp('sublocality_level_1');
      if (city.isEmpty) city = getComp('sublocality');
      if (city.isEmpty) city = getComp('administrative_area_level_3');
      state = getComp('administrative_area_level_1');
      country = getComp('country');
    }

    if (city.isEmpty) {
      city = map['name'] as String? ?? map['city'] as String? ?? '';
    }
    if (state.isEmpty) {
      state = map['state'] as String? ?? '';
    }
    if (country.isEmpty) {
      country = map['country'] as String? ?? '';
    }

    final locationMap = map['location'] is Map
        ? map['location'] as Map
        : (map['geometry'] is Map
              ? (map['geometry'] as Map)['location'] as Map?
              : null);

    final lat =
        locationMap?['latitude']?.toString() ??
        locationMap?['lat']?.toString() ??
        map['latitude']?.toString() ??
        map['lat']?.toString() ??
        '';
    final lng =
        locationMap?['longitude']?.toString() ??
        locationMap?['lng']?.toString() ??
        map['longitude']?.toString() ??
        map['lng']?.toString() ??
        '';

    final placeId =
        map['id']?.toString() ??
        map['placeId']?.toString() ??
        map['place_id']?.toString() ??
        '';

    final description =
        map['formattedAddress']?.toString() ??
        map['formatted_address']?.toString() ??
        map['desctiption']?.toString() ??
        map['description']?.toString() ??
        '';

    return PlaceModel(
      city: city,
      description: description,
      placeId: placeId,
      latitude: lat,
      longitude: lng,
      state: state,
      country: country,
    );
  }

  factory PlaceModel.fromOsmPrediction(Map<String, dynamic> prediction) {
    return PlaceModel(
      city: prediction['city']?.toString() ?? '',
      description: prediction['description']?.toString() ?? '',
      placeId: prediction['place_id']?.toString() ?? '',
      state: prediction['state']?.toString() ?? '',
      country: prediction['country']?.toString() ?? '',
      latitude: prediction['lat']?.toString() ?? '',
      longitude: prediction['lng']?.toString() ?? '',
    );
  }

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('addressComponents') ||
        map.containsKey('address_components') ||
        map.containsKey('formattedAddress') ||
        (map.containsKey('location') && map['location'] is Map)) {
      return PlaceModel.fromGooglePlaceDetails(map);
    }
    return PlaceModel(
      city: map['name'] as String? ?? map['city'] as String? ?? '',
      description:
          map['desctiption'] as String? ?? map['description'] as String? ?? '',
      placeId: map['placeId'] as String? ?? map['place_id'] as String? ?? '',
      latitude: map['latitude'] as String? ?? map['lat'] as String? ?? '',
      longitude: map['longitude'] as String? ?? map['lng'] as String? ?? '',
      state: map['state'] as String? ?? '',
      country: map['country'] as String? ?? '',
    );
  }
  final String city;
  final String description;
  final String placeId;
  final String latitude;
  final String longitude;
  final String state;
  final String country;

  PlaceModel copyWith({
    String? name,
    String? cityName,
    String? placeId,
    String? latitude,
    String? longitude,
    String? state,
    String? country,
  }) {
    return PlaceModel(
      city: name ?? city,
      state: state ?? this.state,
      country: country ?? this.country,
      description: cityName ?? description,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': city,
      'desctiption': description,
      'placeId': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'country': country,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return '''PlaceModel(city: $city, description: $description, placeId: $placeId, latitude: $latitude, longitude: $longitude, state: $state, country: $country)''';
  }

  @override
  bool operator ==(covariant PlaceModel other) {
    if (identical(this, other)) return true;

    return other.city == city &&
        other.description == description &&
        other.placeId == placeId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.state == state &&
        other.country == country;
  }

  @override
  int get hashCode {
    return city.hashCode ^
        description.hashCode ^
        placeId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        state.hashCode ^
        country.hashCode;
  }
}
