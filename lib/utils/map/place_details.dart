import 'package:flutter/foundation.dart';

@immutable
class PlaceDetails {
  const PlaceDetails({
    required this.city,
    required this.state,
    required this.country,
    required this.address,
    this.lat,
    this.lng,
    this.isSnapped = false,
    this.snappedCountryName,
  });

  factory PlaceDetails.fromGoogleResult(Map<String, dynamic> result) {
    final locationMap = result['location'] is Map
        ? result['location'] as Map
        : ((result['geometry'] as Map<String, dynamic>?)?['location']
              as Map<String, dynamic>?);

    final rawLat =
        locationMap?['latitude'] ??
        locationMap?['lat'] ??
        result['latitude'] ??
        result['lat'];
    final rawLng =
        locationMap?['longitude'] ??
        locationMap?['lng'] ??
        result['longitude'] ??
        result['lng'];

    final addressComponentsRaw =
        result['addressComponents'] ?? result['address_components'];
    final addressComponents =
        ((addressComponentsRaw as List?) ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .toList();

    String getComponent(String type) {
      for (final c in addressComponents) {
        final types =
            (c['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
        if (types.contains(type)) {
          return c['longText']?.toString() ?? c['long_name']?.toString() ?? '';
        }
      }
      return '';
    }

    var city = getComponent('locality');
    if (city.isEmpty) city = getComponent('sublocality_level_1');
    if (city.isEmpty) city = getComponent('sublocality');
    if (city.isEmpty) city = getComponent('administrative_area_level_3');

    final state = getComponent('administrative_area_level_1');
    var country = getComponent('country');
    if (country.isEmpty && result['country'] != null) {
      country = result['country'].toString();
    }
    final formattedAddress =
        result['formattedAddress']?.toString() ??
        result['formatted_address']?.toString() ??
        '';

    if (country.isEmpty && formattedAddress.isNotEmpty) {
      final parts = formattedAddress.split(',').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) {
        country = parts.last;
      }
    }

    final isSnapped =
        result['snapped'] == true ||
        result['snapped'] == 'true' ||
        result['snapped'] == 1 ||
        result['snapped'] == '1';
    final snappedCountryName =
        result['snapped_country_name']?.toString() ??
        result['snapped_country']?.toString();

    return PlaceDetails(
      lat: _toDouble(rawLat),
      lng: _toDouble(rawLng),
      city: city,
      state: state,
      country: country.isNotEmpty ? country : (snappedCountryName ?? ''),
      address: formattedAddress,
      isSnapped: isSnapped,
      snappedCountryName: snappedCountryName,
    );
  }

  factory PlaceDetails.fromOsmResult(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final rawLat =
        location?['lat'] ??
        location?['latitude'] ??
        result['latitude'] ??
        result['lat'];
    final rawLng =
        location?['lng'] ??
        location?['longitude'] ??
        result['longitude'] ??
        result['lng'];

    final isSnapped =
        result['snapped'] == true ||
        result['snapped'] == 'true' ||
        result['snapped'] == 1 ||
        result['snapped'] == '1';
    final snappedCountryName =
        result['snapped_country_name']?.toString() ??
        result['snapped_country']?.toString();

    final country = result['country']?.toString() ?? '';

    return PlaceDetails(
      lat: _toDouble(rawLat),
      lng: _toDouble(rawLng),
      city: result['city']?.toString() ?? '',
      state: result['state']?.toString() ?? '',
      country: country.isNotEmpty ? country : (snappedCountryName ?? ''),
      address: result['address']?.toString() ?? '',
      isSnapped: isSnapped,
      snappedCountryName: snappedCountryName,
    );
  }
  final double? lat;
  final double? lng;
  final String city;
  final String state;
  final String country;
  final String address;
  final bool isSnapped;
  final String? snappedCountryName;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  String toString() {
    return 'PlaceDetails(lat: $lat, lng: $lng, city: $city, state: $state, country: $country, address: $address)';
  }
}
