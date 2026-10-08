import 'package:flutter/foundation.dart';

@immutable
class MapBounds {
  const MapBounds({
    required this.neLat,
    required this.neLng,
    required this.swLat,
    required this.swLng,
  });

  factory MapBounds.fromMap(Map<String, dynamic> map) {
    final ne = map['north_east'] as Map<String, dynamic>? ?? {};
    final sw = map['south_west'] as Map<String, dynamic>? ?? {};
    return MapBounds(
      neLat: (ne['lat'] as num?)?.toDouble() ?? 0.0,
      neLng: (ne['lng'] as num?)?.toDouble() ?? 0.0,
      swLat: (sw['lat'] as num?)?.toDouble() ?? 0.0,
      swLng: (sw['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double neLat;
  final double neLng;
  final double swLat;
  final double swLng;

  /// Checks whether coordinates form a valid bounding box:
  /// - Latitudes in [-90, 90]
  /// - Longitudes in [-180, 180]
  /// - north_east.lat >= south_west.lat
  bool get isValid =>
      neLat >= -90.0 &&
      neLat <= 90.0 &&
      swLat >= -90.0 &&
      swLat <= 90.0 &&
      neLng >= -180.0 &&
      neLng <= 180.0 &&
      swLng >= -180.0 &&
      swLng <= 180.0 &&
      neLat >= swLat;

  /// Shape matching base64 filters.location.bounds:
  /// {
  ///   "north_east": { "lat": 23.5, "lng": 72.9 },
  ///   "south_west": { "lat": 22.9, "lng": 72.3 }
  /// }
  Map<String, dynamic> toMap() {
    return {
      'north_east': {
        'lat': neLat,
        'lng': neLng,
      },
      'south_west': {
        'lat': swLat,
        'lng': swLng,
      },
    };
  }

  /// Top-level query params for GET /api/homepage/properties-on-map:
  /// ne_lat={n}&ne_lng={n}&sw_lat={n}&sw_lng={n}
  Map<String, String> toQueryParams() {
    return {
      'ne_lat': neLat.toString(),
      'ne_lng': neLng.toString(),
      'sw_lat': swLat.toString(),
      'sw_lng': swLng.toString(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapBounds &&
        other.neLat == neLat &&
        other.neLng == neLng &&
        other.swLat == swLat &&
        other.swLng == swLng;
  }

  @override
  int get hashCode => Object.hash(neLat, neLng, swLat, swLng);
}
