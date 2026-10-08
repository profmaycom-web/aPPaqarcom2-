import 'dart:developer';

import 'package:ebroker/data/model/city_model.dart';
import 'package:ebroker/data/model/home_section_data_model.dart';
import 'package:ebroker/data/model/map_bounds.dart';
import 'package:ebroker/data/model/other_sections_model.dart';
import 'package:ebroker/data/model/project_sections_model.dart';
import 'package:ebroker/data/model/property_sections_model.dart';
import 'package:ebroker/exports/main_export.dart';

class HomeScreenDataRepository {
  Map<String, dynamic> _locationParameters() {
    final latitude = HiveUtils.getLatitude()?.toString() ?? '';
    final longitude = HiveUtils.getLongitude()?.toString() ?? '';
    final radius = HiveUtils.getRadius()?.toString() ?? '';
    final city = HiveUtils.getHomeCityName();

    final location = {
      if (city.toString().isNotEmpty && city != null) 'city': city,
      if (latitude.isNotEmpty) Api.latitude: latitude,
      if (longitude.isNotEmpty) Api.longitude: longitude,
      if (radius.isNotEmpty) 'radius': radius,
    };
    return location;
  }

  Future<HomeSectionDataModel> fetchSectionsData() async {
    try {
      final result = await Api.get(
        url: Api.homepageSectionsData,
      );
      return HomeSectionDataModel.fromApiResponse(result);
    } on Exception catch (e, st) {
      log(
        e.toString(),
        stackTrace: st,
        name: 'HOME SECTIONS DATA ERROR:',
      );
      throw ApiException(e.toString());
    }
  }

  Future<PropertySectionsModel> fetchPropertySections() async {
    try {
      final result = await Api.get(
        url: Api.homepagePropertySections,
        queryParameters: _locationParameters(),
      );
      return PropertySectionsModel.fromApiResponse(result);
    } on Exception catch (e, st) {
      log(
        e.toString(),
        stackTrace: st,
        name: 'HOME PROPERTY SECTIONS ERROR:',
      );
      throw ApiException(e.toString());
    }
  }

  Future<ProjectSectionsModel> fetchProjectSections() async {
    try {
      final result = await Api.get(
        url: Api.homepageProjectSections,
        queryParameters: _locationParameters(),
      );
      return ProjectSectionsModel.fromApiResponse(result);
    } on Exception catch (e, st) {
      log(
        e.toString(),
        stackTrace: st,
        name: 'HOME PROJECT SECTIONS ERROR:',
      );
      throw ApiException(e.toString());
    }
  }

  Future<OtherSectionsModel> fetchOtherSections() async {
    try {
      final result = await Api.get(
        url: Api.homepageOtherSections,
        queryParameters: _locationParameters(),
      );
      return OtherSectionsModel.fromApiResponse(result);
    } on Exception catch (e, st) {
      log(
        e.toString(),
        stackTrace: st,
        name: 'HOME OTHER SECTIONS ERROR:',
      );
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchPropertiesByCities() async {
    try {
      final result = await Api.get(
        url: Api.apiGetPropertiesByCity,
      );

      final dynamic dataNode = result['data'];
      List<dynamic> rawList;
      if (dataNode is Map<String, dynamic> && dataNode['data'] is List) {
        rawList = dataNode['data'] as List<dynamic>;
      } else if (dataNode is List) {
        rawList = dataNode;
      } else if (result['cities'] is List) {
        rawList = result['cities'] as List<dynamic>;
      } else {
        rawList = const [];
      }

      var isWithImage = false;
      if (dataNode is Map) {
        isWithImage = dataNode['with_image'] as bool? ?? false;
      } else {
        isWithImage = result['with_image'] as bool? ?? false;
      }

      return {
        'cities': rawList
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => City.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        'isWithImage': isWithImage,
      };
    } on Exception catch (e, st) {
      log(
        e.toString(),
        stackTrace: st,
        name: 'PROPERTIES BY CITIES ERROR:',
      );
      throw ApiException(e.toString());
    }
  }

  Future<List<PropertyModel>> fetchHomepagePropertiesOnMap({
    MapBounds? bounds,
    String? latitude,
    String? longitude,
    String? radius,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (bounds != null && bounds.isValid) {
        queryParams.addAll(bounds.toQueryParams());
      } else {
        final lat = latitude ?? HiveUtils.getLatitude()?.toString() ?? '';
        final lng = longitude ?? HiveUtils.getLongitude()?.toString() ?? '';
        final rad = radius ?? HiveUtils.getRadius()?.toString() ?? '';
        if (lat.isNotEmpty) queryParams[Api.latitude] = lat;
        if (lng.isNotEmpty) queryParams[Api.longitude] = lng;
        if (rad.isNotEmpty) queryParams['radius'] = rad;
      }

      final result = await Api.get(
        url: Api.homepagePropertiesOnMap,
        queryParameters: queryParams,
      );

      if (result['error'] == true) {
        throw ApiException(result['message']?.toString() ?? '');
      }

      final rawList = result['data'] as List? ?? [];
      return rawList.map((e) {
        return PropertyModel.fromMap(e as Map<String, dynamic>? ?? {});
      }).toList();
    } on Exception catch (e, st) {
      log(
        e.toString(),
        stackTrace: st,
        name: 'HOMEPAGE PROPERTIES ON MAP ERROR:',
      );
      throw ApiException(e.toString());
    }
  }
}
