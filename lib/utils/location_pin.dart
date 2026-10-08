import 'dart:ui' as ui;

import 'package:ebroker/utils/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:material_ui/material_ui.dart';

enum LocationPinType {
  selected,
  sell,
  rent,
}

class LocationPinColorMapper extends ColorMapper {
  const LocationPinColorMapper(this.targetColor);
  final Color targetColor;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == const Color(0xFF087C7C) || color == const Color(0xFF53ADAE)) {
      return targetColor;
    }
    return color;
  }
}

class LocationPin extends StatelessWidget {
  const LocationPin({
    super.key,
    this.type = LocationPinType.selected,
    this.color,
    this.width,
    this.height,
  });

  final LocationPinType type;
  final Color? color;
  final double? width;
  final double? height;

  static Color getColor(LocationPinType type) {
    switch (type) {
      case LocationPinType.selected:
        return const Color(0xFF087C7C); // Green
      case LocationPinType.sell:
        return const Color(0xFFDB9305); // Orange
      case LocationPinType.rent:
        return const Color(0xFF2196F3); // Blue
    }
  }

  Color get effectiveColor => color ?? getColor(type);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppIcons.locationPin,
      colorMapper: LocationPinColorMapper(effectiveColor),
      width: width,
      height: height,
    );
  }

  static Future<gm.BitmapDescriptor> getBitmapDescriptor(
    LocationPinType type, {
    Size size = const Size(
      66,
      96,
    ), // 2x resolution for crisp display on high DPI screens
  }) async {
    final targetColor = getColor(type);
    final hexColor =
        '#${targetColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    final rawSvg = await rootBundle.loadString(AppIcons.locationPin);
    final colorizedSvg = rawSvg
        .replaceAll(RegExp('#087C7C', caseSensitive: false), hexColor)
        .replaceAll(RegExp('#53ADAE', caseSensitive: false), hexColor);

    final pictureInfo = await vg.loadPicture(
      SvgStringLoader(colorizedSvg),
      null,
    );

    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..scale(
        size.width / pictureInfo.size.width,
        size.height / pictureInfo.size.height,
      )
      ..drawPicture(pictureInfo.picture);

    final rasterizedPicture = recorder.endRecording();
    final image = await rasterizedPicture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return gm.BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: 2,
    );
  }
}
