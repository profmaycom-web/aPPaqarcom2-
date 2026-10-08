import 'package:ebroker/data/model/map_bounds.dart';
import 'package:ebroker/utils/map/app_map_controller.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

class OsmMapControllerImpl implements AppMapController {
  OsmMapControllerImpl(this.controller);
  final fm.MapController controller;

  @override
  Future<void> animateTo(LatLng position, {double zoom = 15}) async {
    controller.move(position, zoom);
  }

  @override
  Future<MapBounds?> getVisibleBounds() async {
    final bounds = controller.camera.visibleBounds;
    return MapBounds(
      neLat: bounds.northEast.latitude,
      neLng: bounds.northEast.longitude,
      swLat: bounds.southWest.latitude,
      swLng: bounds.southWest.longitude,
    );
  }
}
