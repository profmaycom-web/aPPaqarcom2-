import 'dart:convert';

import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/advertisement_model.dart';
import 'package:ebroker/data/model/compare_property_model.dart';
import 'package:ebroker/exports/main_export.dart';

class PropertyRepository {
  Future<DataOutput<PropertyModel>> _fetchProperties(
    Map<String, dynamic> parameters,
  ) async {
    if (ActiveRoleManager.isAgent) {
      return DataOutput(total: 0, modelList: []);
    }
    try {
      final response = await Api.get(
        url: Api.apiGetPropertyList,
        queryParameters: parameters..removeWhere((key, value) => value == null),
      );

      final modelList = (response['data'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map<PropertyModel>(PropertyModel.fromMap)
          .toList();

      return DataOutput(
        total: int.parse(response['total']?.toString() ?? '0'),
        modelList: modelList,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  ///This method will add property
  Future<dynamic> createProperty({
    required Map<String, dynamic> parameters,
    bool isUpdate = false,
  }) async {
    try {
      final api = isUpdate ? Api.apiUpdateProperty : Api.apiPostProperty;
      if (parameters.containsKey('gallery_images')) {
        if ((parameters['gallery_images'] as List).isEmpty) {
          parameters.remove('gallery_images');
        }
      }

      if (parameters.containsKey('documents')) {
        if ((parameters['documents'] as List).isEmpty) {
          parameters.remove('documents');
        }
      }
      if (parameters['title_image'] == null) {
        parameters.remove('title_image');
      }
      if (parameters['three_d_image'] == null ||
          parameters['three_d_image'] == '') {
        parameters.remove('three_d_image');
      }
      if (parameters['custom_video'] == null) {
        parameters.remove('custom_video');
      }
      if (parameters['custom_video'] == null &&
          (parameters['video_link'] == null ||
              parameters['video_link'].toString().trim().isEmpty)) {
        parameters
          ..remove('video_type')
          ..remove('video_link');
      }
      final response = await Api.post(url: api, parameter: parameters);

      return response;
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<PropertyModel> fetchPropertyFromPropertyId({
    required int id,
    required bool isMyProperty,
  }) async {
    final parameters = <String, dynamic>{
      Api.id: id,
      if (!isMyProperty) 'current_user': HiveUtils.getUserId(),
    };

    final response = await Api.get(
      url: isMyProperty ? Api.getAddedProperties : Api.apiGetPropertyDetails,
      queryParameters: parameters,
    );
    if (response['error'] == true) {
      throw ApiException(
        response['message']?.toString() ?? '',
        errorKey: response['key']?.toString(),
      );
    }

    final data = response['data'];
    if (response['data'] == null) {
      throw ApiException('noDataFound');
    }

    if (data is List && data.isEmpty) {
      throw ApiException(response['message']?.toString() ?? 'noDataFound');
    }

    // If data is a List, take the first item
    if (data is List && data.isNotEmpty) {
      return PropertyModel.fromMap(data.first as Map<String, dynamic>);
    }
    // If data is a Map
    else if (data is Map<String, dynamic>) {
      return PropertyModel.fromMap(data);
    }

    throw ApiException('noDataFound');
  }

  Future<void> deleteProperty(
    int id,
  ) async {
    try {
      await Api.post(
        url: Api.apiDeleteProperty,
        parameter: {Api.id: id},
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  ///fetch most viewed properties
  Future<DataOutput<PropertyModel>> fetchMostViewedProperty({
    required int offset,
  }) {
    final filters = <String, dynamic>{
      'flags': {'most_views': '1'},
    }..addAll(_locationParameters());

    final parameters = {
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
      'filters': getEncodedFilters(filters: filters),
    };
    return _fetchProperties(parameters);
  }

  ///fetch advertised properties
  Future<DataOutput<PropertyModel>> fetchPromotedProperty({
    required int offset,
  }) {
    final filters = <String, dynamic>{
      'flags': {Api.promoted: 1},
    }..addAll(_locationParameters());

    final parameters = {
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
      'filters': getEncodedFilters(filters: filters),
    };
    return _fetchProperties(parameters);
  }

  Future<DataOutput<PropertyModel>> fetchNearByProperty({
    required int offset,
  }) async {
    if (HiveUtils.getHomeCityName().toString().isEmpty ||
        HiveUtils.getHomeCityName() == null) {
      return DataOutput(total: 0, modelList: []);
    }

    final filters = _locationParameters();

    final parameters = {
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
      'filters': getEncodedFilters(filters: filters),
    };
    return _fetchProperties(parameters);
  }

  Future<DataOutput<PropertyModel>> fetchMostLikeProperty({
    required int offset,
  }) {
    final filters = <String, dynamic>{
      'flags': {'most_liked': 1},
    }..addAll(_locationParameters());

    final parameters = {
      'filters': getEncodedFilters(filters: filters),
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
    };
    return _fetchProperties(parameters);
  }

  Future<DataOutput<AdvertisementProperty>> fetchMyPromotedProeprties({
    required int offset,
  }) async {
    try {
      final parameters = <String, dynamic>{
        Api.offset: offset,
        Api.limit: AppConfig.apiDataLoadLimit,
        Api.type: 'property',
      };

      final response = await Api.get(
        url: Api.getFeaturedData,
        queryParameters: parameters,
      );
      if (response['error'] == true) {
        throw ApiException(response['message']?.toString() ?? 'noDataFound');
      }
      final modelList = (response['data'] as List)
          .cast<Map<String, dynamic>>()
          .map<AdvertisementProperty>(AdvertisementProperty.fromJson)
          .toList();

      return DataOutput(
        total: int.parse(response['total']?.toString() ?? '0'),
        modelList: modelList,
      );
    } on Exception catch (_) {
      rethrow;
    }
  }

  ///Search property
  Future<DataOutput<PropertyModel>> searchProperty(
    String searchQuery, {
    required int offset,
    FilterApply? filter,
  }) {
    // Create filters map and add search query to it
    final filtersJson = <String, dynamic>{};
    if (filter?.toMap().isNotEmpty ?? false) {
      filtersJson.addAll(filter!.toMap());
    }
    if (searchQuery.isNotEmpty) {
      filtersJson['search'] = searchQuery;
    }

    final encoded = getEncodedFilters(filters: filtersJson);

    final parameters = {
      if (filtersJson.isNotEmpty) 'filters': encoded,
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
    };

    return _fetchProperties(parameters);
  }

  ///to get my properties which i had added to sell or rent
  Future<DataOutput<PropertyModel>> fetchMyProperties({
    required int offset,
    required String type,
    required String requestStatus,
    required String status,
  }) async {
    try {
      final propertyType = _findPropertyType(type.toLowerCase());
      final cleanRequestStatus = requestStatus.trim();
      final cleanStatus = status.trim();

      final isNumericStatus = cleanStatus == '1' || cleanStatus == '0';
      final isValidRequestStatus = cleanRequestStatus.isNotEmpty &&
          cleanRequestStatus.toLowerCase() != 'all' &&
          cleanRequestStatus != '1' &&
          cleanRequestStatus != '0';

      final parameters = <String, dynamic>{
        Api.offset: offset,
        Api.limit: AppConfig.apiDataLoadLimit,
        if (propertyType != null && propertyType.isNotEmpty)
          Api.propertyType: propertyType,
        if (isValidRequestStatus) 'request_status': cleanRequestStatus,
        if (isNumericStatus) 'status': cleanStatus,
      };

      final response = await Api.get(
        url: Api.getAddedProperties,
        queryParameters: parameters,
      );
      if (response['error'] == true) {
        throw ApiException(
          response['message']?.toString() ?? '',
          errorKey: response['key']?.toString(),
        );
      }
      final modelList = (response['data'] as List)
          .cast<Map<String, dynamic>>()
          .map<PropertyModel>(PropertyModel.fromMap)
          .toList();

      return DataOutput(
        total: int.parse(response['total']?.toString() ?? '0'),
        modelList: modelList,
      );
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }

  String? _findPropertyType(String type) {
    if (type.toLowerCase() == 'sell') {
      return '0';
    } else if (type.toLowerCase() == 'rent') {
      return '1';
    } else if (type.toLowerCase() == 'sold') {
      return '2';
    } else if (type.toLowerCase() == 'rented') {
      return '3';
    }
    return null;
  }

  Future<DataOutput<PropertyModel>> fetchPropertyFromCategoryId({
    required int id,
    required int offset,
    FilterApply? filter,
    bool? showPropertyType,
    String? searchQuery,
  }) {
    final filters = <String, dynamic>{
      Api.categoryId: id,
      ..._locationParameters(),
    };
    if (filter?.toMap().isNotEmpty ?? false) {
      filters.addAll(filter!.toMap().cast<String, dynamic>());
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filters['search'] = searchQuery;
    }
    final parameters = {
      if (filters.isNotEmpty)
        'filters': getEncodedFilters(
          filters: filters,
        ),
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
    };

    return _fetchProperties(parameters);
  }

  Future<dynamic> updatePropertyStatus({
    required dynamic propertyId,
    required dynamic status,
  }) async {
    await Api.post(
      url: Api.updatePropertyStatus,
      parameter: {'status': status, 'property_id': propertyId},
    );
  }

  Future<DataOutput<PropertyModel>> fetchPropertiesFromPlace({
    required int offset,
    String? placeId,
    String? city,
    String? state,
    String? country,
    FilterApply? filter,
    String? searchQuery,
  }) {
    final filtersJson = <String, dynamic>{
      'location': {
        'city': ?city,
        'state': ?state,
        'country': ?country,
        'place_id': ?placeId,
      },
    };

    // Merge any extra filters from FilterApply.
    if (filter?.toMap().isNotEmpty ?? false) {
      // Location from FilterApply should not override the city param.
      final filterMap = filter!.toMap()
        ..remove('location'); // city is already set above
      filtersJson.addAll(filterMap.cast<String, dynamic>());
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtersJson['search'] = searchQuery;
    }

    final parameters = {
      if (filtersJson.isNotEmpty)
        'filters': getEncodedFilters(filters: filtersJson),
      Api.limit: AppConfig.apiDataLoadLimit,
      Api.offset: offset,
    };
    return _fetchProperties(parameters);
  }

  Future<DataOutput<PropertyModel>> fetchAllProperties({
    required int offset,
  }) {
    final filters = <String, dynamic>{}..addAll(_locationParameters());

    final parameters = {
      if (filters.isNotEmpty) 'filters': getEncodedFilters(filters: filters),
      Api.limit: AppConfig.apiDataLoadLimit,
      Api.offset: offset,
    };
    return _fetchProperties(parameters);
  }

  Future<Map<String, dynamic>> changePropertyStatus({
    required int propertyId,
    required int status,
  }) async {
    final parameters = <String, dynamic>{
      Api.propertyId: propertyId,
      Api.status: status,
    };
    final response = await Api.post(
      url: Api.changePropertyStatus,
      parameter: parameters,
    );
    return response;
  }

  Future<PropertyModel> fetchBySlug(String slug) async {
    const apiUrl = Api.apiGetPropertyDetails;
    final result = await Api.get(
      url: apiUrl,
      queryParameters: {'slug_id': slug},
    );

    // Ensure 'data' is a List and safely extract the first item
    final data = result['data'];
    if (data is List && data.isNotEmpty) {
      final firstItem = data.first;
      if (firstItem is Map<String, dynamic>) {
        return PropertyModel.fromMap(firstItem);
      }
    }

    // Handle cases where data is null or in an unexpected format
    throw Exception('Invalid data format received');
  }

  Future<DataOutput<PropertyModel>> fetchSimilarProperty({
    required int propertyId,
  }) async {
    final parameters = <String, dynamic>{
      Api.propertyId: propertyId,
    };
    final response = await Api.get(
      url: Api.getAllSimilarProperties,
      queryParameters: parameters,
    );
    final modelList = (response['data'] as List)
        .cast<Map<String, dynamic>>()
        .map<PropertyModel>(PropertyModel.fromMap)
        .toList();
    return DataOutput(
      total: int.parse(response['total']?.toString() ?? '0'),
      modelList: modelList,
    );
  }

  Future<ComparePropertyModel> compareProperties({
    required int sourcePropertyId,
    required int targetPropertyId,
  }) async {
    try {
      final parameters = <String, dynamic>{
        'source_property_id': sourcePropertyId,
        'target_property_id': targetPropertyId,
      };
      final response = await Api.get(
        url: Api.compareProperties,
        queryParameters: parameters,
      );
      if (response['error'] == true) {
        throw ApiException(response['message']?.toString() ?? '');
      }
      final result = ComparePropertyModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );
      return result;
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<DataOutput<PropertyModel>> fetchPremiumProperty({
    required int offset,
  }) {
    final filters = <String, dynamic>{
      'flags': {'get_all_premium_properties': 1},
    }..addAll(_locationParameters());

    final parameters = {
      'filters': getEncodedFilters(filters: filters),
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
    };

    return _fetchProperties(parameters);
  }

  Future<DataOutput<PropertyModel>> fetchCuratedProperty({
    required int offset,
  }) {
    final filters = <String, dynamic>{
      'flags': {'admin_curated': 1},
    }..addAll(_locationParameters());

    final parameters = {
      'filters': getEncodedFilters(filters: filters),
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
    };

    return _fetchProperties(parameters);
  }

  String getEncodedFilters({
    required Map<String, dynamic> filters,
  }) {
    final encoded = base64Encode(utf8.encode(jsonEncode(filters)));
    return encoded;
  }

  Map<String, dynamic> _locationParameters() {
    final latitude = HiveUtils.getLatitude()?.toString() ?? '';
    final longitude = HiveUtils.getLongitude()?.toString() ?? '';
    final radius = HiveUtils.getRadius()?.toString() ?? '';
    final city = HiveUtils.getHomeCityName();

    final location = {
      'location': {
        if (city.toString().isNotEmpty && city != null) 'city': city,
        if (latitude.isNotEmpty) Api.latitude: latitude,
        if (longitude.isNotEmpty) Api.longitude: longitude,
        if (radius.isNotEmpty) Api.radius: radius,
      },
    };
    return location;
  }

  Future<DataOutput<PropertyModel>> getPersonalizedProeprties({
    required int offset,
    String? searchQuery,
  }) async {
    if (ActiveRoleManager.isAgent) {
      return DataOutput(total: 0, modelList: []);
    }

    final filtersJson = <String, dynamic>{};
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtersJson['search'] = searchQuery;
    }

    final response = await Api.get(
      url: Api.getUserRecommendation,
      queryParameters: {
        Api.offset: offset,
        Api.limit: AppConfig.apiDataLoadLimit,
        if (filtersJson.isNotEmpty)
          'filters': getEncodedFilters(filters: filtersJson),
      },
    );
    if (response['error'] == true) {
      throw ApiException(response['message']?.toString() ?? '');
    }

    final modelList = (response['data'] as List)
        .cast<Map<String, dynamic>>()
        .map<PropertyModel>(PropertyModel.fromMap)
        .toList();
    return DataOutput(
      total: response['total'] as int? ?? 0,
      modelList: modelList,
    );
  }
}
