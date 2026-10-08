import 'package:ebroker/data/model/map_bounds.dart';
import 'package:ebroker/utils/map/app_map_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

class GoogleMapControllerImpl implements AppMapController {
  GoogleMapControllerImpl(this.controller);
  final gm.GoogleMapController controller;

  @override
  Future<void> animateTo(ll.LatLng position, {double zoom = 15}) async {
    await controller.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(position.latitude, position.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  Future<MapBounds?> getVisibleBounds() async {
    final region = await controller.getVisibleRegion();
    return MapBounds(
      neLat: region.northeast.latitude,
      neLng: region.northeast.longitude,
      swLat: region.southwest.latitude,
      swLng: region.southwest.longitude,
    );
  }
}
