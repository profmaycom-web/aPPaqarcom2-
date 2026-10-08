import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/utils/location_pin.dart';
import 'package:ebroker/utils/map/app_map_controller.dart';
import 'package:ebroker/utils/map/map_provider.dart';
import 'package:ebroker/utils/map/providers/google/google_map_widget.dart';
import 'package:ebroker/utils/map/providers/osm/osm_map_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

class AppMapMarker {
  const AppMapMarker({
    required this.id,
    required this.position,
    this.iconAsset,
    this.pinType,
    this.onTap,
    this.title,
    this.snippet,
    this.property,
    this.draggable = false,
    this.onDragEnd,
    this.onDrag,
  });
  final String id;
  final LatLng position;
  final String? iconAsset;
  final LocationPinType? pinType;
  final VoidCallback? onTap;
  final String? title;
  final String? snippet;
  final PropertyModel? property;
  final bool draggable;
  final void Function(LatLng position)? onDragEnd;
  final void Function(LatLng position)? onDrag;
}

class AppMapCircle {
  const AppMapCircle({
    required this.id,
    required this.center,
    required this.radius,
    this.fillColor = Colors.transparent,
    this.strokeColor = Colors.blue,
    this.strokeWidth = 1,
  });
  final String id;
  final LatLng center;
  final double radius;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;
}

class AppMapConfig {
  const AppMapConfig({
    required this.initialLatLng,
    this.initialZoom = 15.0,
    this.minZoom = 3.0,
    this.maxZoom = 21.0,
    this.markers = const [],
    this.circles = const [],
    this.onTap,
    this.onCameraMove,
    this.onCameraIdle,
    this.onReady,
    this.enableClustering = false,
    this.gestureRecognizers,
    this.zoomControlsEnabled = false,
    this.myLocationButtonEnabled = false,
  });
  final LatLng initialLatLng;
  final double initialZoom;
  final double? minZoom;
  final double? maxZoom;
  final List<AppMapMarker> markers;
  final List<AppMapCircle> circles;
  final void Function(LatLng position)? onTap;
  final void Function(LatLng position, double zoom)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final void Function(AppMapController controller)? onReady;
  final bool enableClustering;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final bool zoomControlsEnabled;
  final bool myLocationButtonEnabled;
}

class AppMapWidget extends StatelessWidget {
  const AppMapWidget({
    required this.config,
    super.key,
  });
  final AppMapConfig config;

  @override
  Widget build(BuildContext context) {
    if (AppSettings.mapServiceProvider == MapProvider.openStreetMaps) {
      return OsmMapWidget(config: config);
    } else {
      return GoogleMapWidget(config: config);
    }
  }
}
