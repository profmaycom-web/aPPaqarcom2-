import 'package:dio/dio.dart';
import 'package:ebroker/data/model/google_place_model.dart';
import 'package:ebroker/data/model/place_details_model.dart';
import 'package:ebroker/utils/api.dart';

class GooglePlaceRepository {
  //This will search places from google place api
  //We use this to search location while adding new property
  Future<List<GooglePlaceModel>> serchCities(String text) async {
    try {
      final queryParameters = <String, dynamic>{
        Api.input: text,
      };
      final apiResponse = await Api.get(
        url: Api.getPlaceList,
        useBaseUrl: false,
        queryParameters: queryParameters,
      );
      return _buildPlaceModelList(apiResponse);
    } on Exception catch (e) {
      if (e is DioException) {}
      throw ApiException(e.toString());
    }
  }

  ///this will convert normal response to List of models
  ///so we can use it easily in code
  List<GooglePlaceModel> _buildPlaceModelList(
    Map<String, dynamic> apiResponse,
  ) {
    try {
      final dataMap = apiResponse['data'] is Map
          ? apiResponse['data'] as Map
          : <String, dynamic>{};
      final predictions =
          (dataMap['suggestions'] as List<dynamic>?) ??
          (dataMap['predictions'] as List<dynamic>?) ??
          [];
      return predictions
          .map(
            (prediction) => GooglePlaceModel.fromGooglePrediction(
              Map<String, dynamic>.from(prediction as Map),
            ),
          )
          .toList();
    } on Exception catch (_) {
      return [];
    }
  }

  ///Fetches place details for a given placeId (forward lookup) or
  ///lat/lng pair (reverse geocoding). Returns a typed [PlaceDetailsModel].
  ///
  ///The backend wraps the response as either:
  ///  - success: `data: { result: {...}, status: "OK" }`
  ///  - empty:   `data: []`
  ///In the empty / malformed case this throws `ApiException('noDataFound')`
  ///so the cubit surfaces it as a failure state instead of silently
  ///emitting a blank model.
  Future<PlaceDetailsModel> getPlaceDetails({
    required String latitude,
    required String longitude,
    String? placeId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        if (placeId != null && placeId.isNotEmpty) 'place_id': placeId,
        Api.latitude: latitude,
        Api.longitude: longitude,
      };
      final response = await Api.get(
        url: Api.getPlaceDetails,
        queryParameters: queryParameters,
        useBaseUrl: false,
      );

      final data = response['data'];
      if (data is! Map) {
        throw ApiException('noDataFound');
      }
      final resultMap = data['result'] is Map
          ? Map<String, dynamic>.from(data['result'] as Map)
          : Map<String, dynamic>.from(data);
      return PlaceDetailsModel.fromMap(resultMap);
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
