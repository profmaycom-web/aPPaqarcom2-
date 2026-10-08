import 'package:ebroker/config/app_config.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/location_pin.dart';
import 'package:ebroker/utils/map/app_map_widget.dart';
import 'package:ebroker/utils/map/providers/osm/osm_map_controller_impl.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:material_ui/material_ui.dart';

class OsmMapWidget extends StatefulWidget {
  const OsmMapWidget({required this.config, super.key});
  final AppMapConfig config;

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  late final fm.MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.config.onReady?.call(OsmMapControllerImpl(_mapController));
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmMarkers = widget.config.markers.map((m) {
      return fm.Marker(
        point: m.position,
        width: 32,
        height: 40,
        child: GestureDetector(
          onTap: m.onTap,
          child: LocationPin(
            type: m.pinType ?? LocationPinType.selected,
            width: 32,
            height: 40,
          ),
        ),
      );
    }).toList();

    return fm.FlutterMap(
      mapController: _mapController,
      options: fm.MapOptions(
        initialCenter: widget.config.initialLatLng,
        initialZoom: widget.config.initialZoom,
        minZoom: widget.config.minZoom,
        maxZoom: widget.config.maxZoom,
        onTap: (tapPosition, point) {
          widget.config.onTap?.call(point);
        },
        onPositionChanged: (camera, hasGesture) {
          widget.config.onCameraMove?.call(camera.center, camera.zoom);
        },
        onMapEvent: (event) {
          if (event is fm.MapEventMoveEnd ||
              event is fm.MapEventFlingAnimationEnd) {
            widget.config.onCameraIdle?.call();
          }
        },
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: AppConfig.applicationName,
        ),
        if (widget.config.circles.isNotEmpty)
          fm.CircleLayer(
            circles: widget.config.circles.map((c) {
              return fm.CircleMarker(
                point: c.center,
                radius: c.radius,
                useRadiusInMeter: true,
                color: c.fillColor,
                borderColor: c.strokeColor,
                borderStrokeWidth: c.strokeWidth.toDouble(),
              );
            }).toList(),
          ),
        if (widget.config.enableClustering)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 20,
              size: Size(40.rw(context), 40.rh(context)),
              alignment: Alignment.center,
              markers: fmMarkers,
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                    shape: .circle,
                    color: context.color.tertiaryColor,
                    border: Border.all(
                      color: context.color.buttonColor.withValues(alpha: .3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: CustomText(
                      markers.length.toString(),
                      color: context.color.buttonColor,
                    ),
                  ),
                );
              },
            ),
          )
        else
          fm.MarkerLayer(
            markers: fmMarkers,
          ),
        const fm.SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
          backgroundColor: Colors.white,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
