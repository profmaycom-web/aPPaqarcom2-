import 'dart:convert';

import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/map_bounds.dart';
import 'package:ebroker/exports/main_export.dart';

class GMap {
  static Future<List<PropertyModel>> getNearByProperty(
    String city,
    String latitude,
    String longitude,
    String placeId, {
    FilterApply? filter,
    MapBounds? bounds,
  }) async {
    try {
      final activeBounds = bounds ?? filter?.get<LocationFilter>().bounds;
      final filterMap = (filter?.toMap() ?? {})..remove('location');

      if (activeBounds != null && activeBounds.isValid) {
        final existingLocation =
            (filter?.toMap()['location'] as Map<String, dynamic>?) ?? {};
        filterMap['location'] = {
          ...existingLocation,
          'bounds': activeBounds.toMap(),
        };
      }

      final response = await Api.get(
        url: Api.getPropertiesOnMap,
        queryParameters: {
          'city': city,
          'place_id': placeId,
          'latitude': latitude,
          'longitude': longitude,
          if (filterMap.isNotEmpty)
            'filters': base64Encode(utf8.encode(jsonEncode(filterMap))),
        },
      );
      // response.mlog('City response');
      if (response['error'] == true) {
        throw ApiException(response['message']?.toString() ?? '');
      }
      final points = (response['data'] as List? ?? []).map((e) {
        return PropertyModel.fromMap(e as Map<String, dynamic>? ?? {});
      }).toList();
      return points;
    } on Exception catch (_) {
      rethrow;
    }
  }
}
