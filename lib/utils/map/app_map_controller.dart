import 'package:ebroker/data/model/map_bounds.dart';
import 'package:latlong2/latlong.dart';

class AppMapController {
  Future<void> animateTo(LatLng position, {double zoom = 15}) {
    throw UnimplementedError('animateTo() has not been implemented.');
  }

  Future<MapBounds?> getVisibleBounds() {
    throw UnimplementedError('getVisibleBounds() has not been implemented.');
  }
}
