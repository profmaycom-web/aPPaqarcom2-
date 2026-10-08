import 'package:ebroker/settings.dart';
import 'package:ebroker/utils/map/map_provider.dart';
import 'package:ebroker/utils/map/place_search_service.dart';
import 'package:ebroker/utils/map/providers/google/google_place_search_service.dart';
import 'package:ebroker/utils/map/providers/osm/osm_place_search_service.dart';

class MapServiceFactory {
  static PlaceSearchService createPlaceSearchService() {
    if (AppSettings.mapServiceProvider == MapProvider.openStreetMaps) {
      return OsmPlaceSearchService();
    } else {
      return GooglePlaceSearchService();
    }
  }
}
