import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

class InteractivePropertyMap extends StatefulWidget {
  const InteractivePropertyMap({
    required this.latitude,
    required this.longitude,
    required this.propertyType,
    this.onFullScreenTap,
    this.delayMs = 0,
    this.zoom,
    this.zoomControlsEnabled = false,
    this.gestureRecognizers,
    super.key,
  });

  final double latitude;
  final double longitude;
  final String propertyType;
  final VoidCallback? onFullScreenTap;

  /// Delay in milliseconds before rendering the map.
  /// Useful to avoid jank during page-transition animations.
  final int delayMs;

  /// Zoom level override. Defaults to [AppConfig.propertyDetailsMapZoom].
  final double? zoom;

  /// Whether to display zoom controls (+ / - buttons).
  final bool zoomControlsEnabled;

  /// Optional custom gesture recognizers (e.g. for fullscreen interactive mode).
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<InteractivePropertyMap> createState() => _InteractivePropertyMapState();
}

class _InteractivePropertyMapState extends State<InteractivePropertyMap> {
  final Completer<AppMapController> _controller = Completer();
  bool _isDelayDone = false;

  @override
  void initState() {
    super.initState();
    final delay = widget.delayMs > 0
        ? Duration(milliseconds: widget.delayMs)
        : Duration.zero;
    Future.delayed(delay, () {
      if (mounted) {
        setState(() {
          _isDelayDone = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDelayDone) {
      return CustomShimmer(
        height: 200.rh(context),
        width: double.infinity,
        borderRadius: 4.rw(context),
      );
    }

    final latLng = LatLng(widget.latitude, widget.longitude);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4.rw(context)),
          child: AppMapWidget(
            config: AppMapConfig(
              initialLatLng: latLng,
              initialZoom: widget.zoom ?? AppConfig.propertyDetailsMapZoom,
              zoomControlsEnabled: widget.zoomControlsEnabled,
              gestureRecognizers: widget.gestureRecognizers,
              onReady: (controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              circles: [
                if (!AppSettings.showExactLocation)
                  AppMapCircle(
                    id: 'property_radius',
                    center: latLng,
                    radius: 5000, // 5km in meters
                    fillColor: context.color.tertiaryColor.withValues(
                      alpha: .3,
                    ),
                    strokeWidth: 2,
                    strokeColor: context.color.tertiaryColor,
                  ),
              ],
              markers: [
                if (AppSettings.showExactLocation)
                  AppMapMarker(
                    id: 'exact_location',
                    position: latLng,
                    pinType: widget.propertyType.toLowerCase() == 'sell'
                        ? LocationPinType.sell
                        : widget.propertyType.toLowerCase() == 'rent'
                        ? LocationPinType.rent
                        : LocationPinType.selected,
                  ),
              ],
            ),
          ),
        ),
        if (widget.onFullScreenTap != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: widget.onFullScreenTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.fullscreen,
                  color: context.color.textColorDark,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
