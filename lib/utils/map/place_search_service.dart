import 'package:ebroker/utils/map/place_details.dart';
import 'package:ebroker/utils/map/place_model.dart';

abstract class PlaceSearchService {
  Future<List<PlaceModel>> searchCities(
    String query, {
    String? countryId,
    String? countryName,
  });
  Future<PlaceDetails> getPlaceDetails({
    required String latitude,
    required String longitude,
    String? placeId,
    String? countryId,
  });
}
