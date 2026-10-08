import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/map/place_details.dart';
import 'package:ebroker/utils/map/place_model.dart';
import 'package:ebroker/utils/map/place_search_service.dart';

class OsmPlaceSearchService implements PlaceSearchService {
  @override
  Future<List<PlaceModel>> searchCities(
    String query, {
    String? countryId,
    String? countryName,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        Api.input: query,
        if (countryId != null && countryId.isNotEmpty) 'country_id': countryId,
      };
      final apiResponse = await Api.get(
        url: Api.getOsmPlaceList,
        useBaseUrl: false,
        queryParameters: queryParameters,
      );

      final predictions =
          apiResponse['data']?['predictions'] as List<dynamic>? ?? [];
      final results = predictions
          .map(
            (p) => PlaceModel.fromOsmPrediction(
              Map<String, dynamic>.from(p as Map),
            ),
          )
          .toList();

      if (countryName != null && countryName.trim().isNotEmpty) {
        final cName = countryName.trim().toLowerCase();
        final filtered = results.where((place) {
          final placeCountry = place.country.toLowerCase();
          final placeDesc = place.description.toLowerCase();
          if (placeCountry.isNotEmpty) {
            return placeCountry.contains(cName) || cName.contains(placeCountry);
          }
          if (placeDesc.isNotEmpty) {
            return placeDesc.contains(cName);
          }
          return true;
        }).toList();

        return filtered.isNotEmpty ? filtered : results;
      }

      return results;
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }

  @override
  Future<PlaceDetails> getPlaceDetails({
    required String latitude,
    required String longitude,
    String? placeId,
    String? countryId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        if (placeId != null && placeId.isNotEmpty) 'place_id': placeId,
        Api.latitude: latitude,
        Api.longitude: longitude,
      };
      final response = await Api.get(
        url: Api.getOsmPlaceDetails,
        queryParameters: queryParameters,
        useBaseUrl: false,
        countryId: countryId,
      );

      final data = response['data'];
      if (data is! Map) {
        throw ApiException('noDataFound');
      }
      final result = data['result'];
      final resultMap = result is Map
          ? Map<String, dynamic>.from(result)
          : Map<String, dynamic>.from(data);
      if (data['snapped'] != null) {
        resultMap['snapped'] = data['snapped'];
      }
      if (data['snapped_country_name'] != null) {
        resultMap['snapped_country_name'] = data['snapped_country_name'];
      }
      if (data['location'] != null && resultMap['location'] == null) {
        resultMap['location'] = data['location'];
      }
      if (response['snapped'] != null) {
        resultMap['snapped'] = response['snapped'];
      }
      if (response['snapped_country_name'] != null) {
        resultMap['snapped_country_name'] = response['snapped_country_name'];
      }
      return PlaceDetails.fromOsmResult(resultMap);
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
