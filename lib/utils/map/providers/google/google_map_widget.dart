import 'dart:async';
import 'dart:ui';

import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/location_pin.dart';
import 'package:ebroker/utils/map/app_map_widget.dart';
import 'package:ebroker/utils/map/providers/google/google_map_controller_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:material_ui/material_ui.dart';

class GoogleClusterItem with ClusterItem {
  GoogleClusterItem(this.marker);
  final AppMapMarker marker;

  @override
  gm.LatLng get location =>
      gm.LatLng(marker.position.latitude, marker.position.longitude);
}

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({required this.config, super.key});
  final AppMapConfig config;

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  gm.GoogleMapController? _googleMapController;
  late ClusterManager<GoogleClusterItem> _clusterManager;
  Set<gm.Marker> _clusteredMarkers = {};
  final Map<LocationPinType, gm.BitmapDescriptor> _pinIconsCache = {};

  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMapStyle());
    unawaited(_loadCustomIcons());
    if (widget.config.enableClustering) {
      _initClusterManager();
    }
  }

  void _initClusterManager() {
    final items = widget.config.markers.map(GoogleClusterItem.new).toList();
    _clusterManager = ClusterManager<GoogleClusterItem>(
      items,
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );
  }

  void _updateMarkers(Set<gm.Marker> markers) {
    if (mounted) {
      setState(() {
        _clusteredMarkers = markers;
      });
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      _darkMapStyle = await rootBundle.loadString(
        'assets/map_styles/dark_map.json',
      );
      if (mounted) {
        setState(() {});
      }
    } on Exception catch (_) {}
  }

  Future<void> _loadCustomIcons() async {
    try {
      for (final type in LocationPinType.values) {
        final descriptor = await LocationPin.getBitmapDescriptor(type);
        _pinIconsCache[type] = descriptor;
      }
      if (mounted) {
        setState(() {});
        if (widget.config.enableClustering) {
          _clusterManager.updateMap();
        }
      }
    } on Exception catch (_) {}
  }

  gm.BitmapDescriptor _getSingleMarkerIcon(AppMapMarker marker) {
    final type = marker.pinType ?? LocationPinType.selected;
    if (_pinIconsCache.containsKey(type)) {
      return _pinIconsCache[type]!;
    }
    if (_pinIconsCache.containsKey(LocationPinType.selected)) {
      return _pinIconsCache[LocationPinType.selected]!;
    }
    return gm.BitmapDescriptor.defaultMarker;
  }

  Future<gm.Marker> _markerBuilder(Cluster<GoogleClusterItem> cluster) async {
    final isMultiple = cluster.isMultiple;
    if (!isMultiple) {
      final item = cluster.items.first;
      return gm.Marker(
        markerId: gm.MarkerId(item.marker.id),
        position: cluster.location,
        icon: _getSingleMarkerIcon(item.marker),
        onTap: item.marker.onTap,
      );
    }

    final clusterIcon = await _getClusterIcon(cluster.count);
    return gm.Marker(
      markerId: gm.MarkerId('cluster_${cluster.getId()}'),
      position: cluster.location,
      icon: clusterIcon,
      onTap: () async {
        if (_googleMapController != null) {
          final currentZoom = await _googleMapController!.getZoomLevel();
          await _googleMapController!.animateCamera(
            gm.CameraUpdate.newLatLngZoom(
              cluster.location,
              (currentZoom + 2.5).clamp(3.0, 20.0),
            ),
          );
        }
      },
    );
  }

  Future<gm.BitmapDescriptor> _getClusterIcon(int size) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = context.color.tertiaryColor; // Sleek blue
    final paintOuter = Paint()
      ..color = context.color.tertiaryColor.withValues(alpha: 0.2);

    const radius = 22.0;
    const radiusOuter = 28.0;

    canvas
      ..drawCircle(
        const Offset(radiusOuter, radiusOuter),
        radiusOuter,
        paintOuter,
      )
      ..drawCircle(const Offset(radiusOuter, radiusOuter), radius, paint);

    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: size.toString(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      )
      ..layout();

    painter.paint(
      canvas,
      Offset(
        radiusOuter - painter.width / 2,
        radiusOuter - painter.height / 2,
      ),
    );

    final img = await pictureRecorder.endRecording().toImage(
      radiusOuter.round() * 2,
      radiusOuter.round() * 2,
    );
    final data = await img.toByteData(format: ImageByteFormat.png);
    return gm.BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  @override
  void didUpdateWidget(covariant GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.enableClustering) {
      final items = widget.config.markers.map(GoogleClusterItem.new).toList();
      _clusterManager.setItems(items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markersSet = widget.config.enableClustering
        ? _clusteredMarkers
        : widget.config.markers.map((m) {
            return gm.Marker(
              markerId: gm.MarkerId(m.id),
              position: gm.LatLng(m.position.latitude, m.position.longitude),
              icon: _getSingleMarkerIcon(m),
              draggable: m.draggable,
              onDrag: m.onDrag != null
                  ? (p) => m.onDrag!(ll.LatLng(p.latitude, p.longitude))
                  : null,
              onDragEnd: m.onDragEnd != null
                  ? (p) => m.onDragEnd!(ll.LatLng(p.latitude, p.longitude))
                  : null,
              onTap: m.onTap,
            );
          }).toSet();

    final circlesSet = widget.config.circles.map((c) {
      return gm.Circle(
        circleId: gm.CircleId(c.id),
        center: gm.LatLng(c.center.latitude, c.center.longitude),
        radius: c.radius,
        fillColor: c.fillColor,
        strokeColor: c.strokeColor,
        strokeWidth: c.strokeWidth,
      );
    }).toSet();

    return gm.GoogleMap(
      style: Theme.of(context).brightness == Brightness.dark
          ? _darkMapStyle
          : null,
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(
          widget.config.initialLatLng.latitude,
          widget.config.initialLatLng.longitude,
        ),
        zoom: widget.config.initialZoom,
      ),
      minMaxZoomPreference: gm.MinMaxZoomPreference(
        widget.config.minZoom,
        widget.config.maxZoom,
      ),
      zoomControlsEnabled: widget.config.zoomControlsEnabled,
      myLocationButtonEnabled: widget.config.myLocationButtonEnabled,
      mapToolbarEnabled: false,
      gestureRecognizers:
          widget.config.gestureRecognizers ??
          const <Factory<OneSequenceGestureRecognizer>>{},
      markers: markersSet,
      circles: circlesSet,
      onTap: (latLng) {
        widget.config.onTap?.call(ll.LatLng(latLng.latitude, latLng.longitude));
      },
      onCameraMove: (position) {
        if (widget.config.enableClustering) {
          _clusterManager.onCameraMove(position);
        }
        widget.config.onCameraMove?.call(
          ll.LatLng(position.target.latitude, position.target.longitude),
          position.zoom,
        );
      },
      onCameraIdle: () {
        if (widget.config.enableClustering) {
          _clusterManager.updateMap();
        }
        widget.config.onCameraIdle?.call();
      },
      onMapCreated: _onMapCreated,
    );
  }

  Future<void> _onMapCreated(gm.GoogleMapController controller) async {
    _googleMapController = controller;
    widget.config.onReady?.call(GoogleMapControllerImpl(controller));
    if (widget.config.enableClustering) {
      await _clusterManager.setMapId(controller.mapId);
    }
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }
}
