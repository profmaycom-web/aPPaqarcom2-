import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';

class LottieEditor {
  LottieEditor();
  final ValueNotifier<Map<String, dynamic>?> _lottieNotifier =
      ValueNotifier<Map<String, dynamic>>({});
  Map<String, dynamic>? get lottieJson => _lottieNotifier.value;
  ValueNotifier<Map<String, dynamic>?> get listener => _lottieNotifier;

  ///This is to load lottie file put here asset file path
  ///CALL THIS FIRST->
  Future<void> openAndLoad(String path) async {
    try {
      final data = await rootBundle.loadString(path);
      final lottieJson = json.decode(data) as Map<String, dynamic>;
      _updateLottieJson(lottieJson);
    } on Exception catch (e) {
      _handleError('Error opening and loading Lottie file', e);
    }
  }

  ////This function is used to modify all colors of lottie with their opacity
  ////USE THIS-->
  void changeWholeLottieFileColor(Color targetColor) {
    if (lottieJson != null) {
      final modifiedJson = modifyColorsRecursive(lottieJson!, targetColor);
      _updateLottieJson(modifiedJson);
    } else {}
  }

  ////This file is to modify colors by their shape name; [Useful for multiple color lottie]
  void changeColorsOfShapeNames(List<String> shapeNames, Color targetColor) {
    if (lottieJson != null) {
      final modifiedJson = modifyColorsByShapeNames(
        lottieJson!,
        shapeNames,
        targetColor,
      );
      _updateLottieJson(modifiedJson);
    } else {}
  }

  ///This will convert json to UINT8
  ///USE THIS TO DISPLAY LOTTIE

  Uint8List convertToUint8List() {
    if (lottieJson != null) {
      return Uint8List.fromList(utf8.encode(json.encode(lottieJson)));
    } else {
      return Uint8List(0); // Return an empty list or handle as needed
    }
  }

  // Private method to modify colors recursively
  Map<String, dynamic> modifyColorsRecursive(
    Map<String, dynamic> json,
    Color targetColor,
  ) {
    final layers = (json['layers'] as List<dynamic>?) ?? [];

    for (final dynamic layer in layers) {
      _modifyLayerColors(layer, targetColor);
    }
    return json;
  }

  // Private method to modify colors by shape names
  Map<String, dynamic> modifyColorsByShapeNames(
    Map<String, dynamic> json,
    List<String> shapeNames,
    Color targetColor,
  ) {
    final layers = (json['layers'] as List<dynamic>?) ?? [];
    for (final dynamic layer in layers) {
      _modifyLayerColorsByShapeNames(layer, shapeNames, targetColor);
    }
    return json;
  }

  // Private method to modify colors within a layer
  void _modifyLayerColors(dynamic layer, Color targetColor) {
    final shapes = (layer['shapes'] as List<dynamic>?) ?? [];
    for (final dynamic shape in shapes) {
      _loopShapes(shape as Map<String, dynamic>, targetColor);
    }
  }

  void _loopShapes(Map<dynamic, dynamic> shape, dynamic targetColor) {
    final shapes = (shape['it'] as List?) ?? [];
    for (final element in shapes) {
      if (element['ty'] == 'fl') {
        element['c'] = _flutterColorToLottie(targetColor as Color);
      } else if (element['ty'] == 'gr') {
        _loopShapes(element as Map<dynamic, dynamic>, targetColor);
      } else if (element['ty'] == 'st') {
        element['c'] = _flutterColorToLottie(targetColor as Color);
      }
    }
  }

  // Private method to modify colors within a layer based on shape names
  void _modifyLayerColorsByShapeNames(
    dynamic layer,
    List<String> shapeNames,
    Color targetColor,
  ) {
    final shapes = (layer['shapes'] as List<dynamic>?) ?? [];
    for (final dynamic shape in shapes) {
      if (shape['ty'] == 'fl' || shape['ty'] == 'st') {
        final shapeName = shape['nm']?.toString() ?? '';

        if (shapeNames.contains(shapeName)) {
          shape['c'] = _flutterColorToLottie(targetColor);
        }
      } else if (shape['ty'] == 'gr') {
        _modifyLayerColorsByShapeNames(shape, shapeNames, targetColor);
      }
    }
  }

  // Private method to handle errors
  void _handleError(String message, dynamic error) {
    // You can choose to throw an exception, log the error, or handle it differently.
  }

  // Private method to update the Lottie JSON and notify listeners
  void _updateLottieJson(Map<String, dynamic> modifiedJson) {
    assert(modifiedJson.isNotEmpty, 'Lottie JSON should not be empty');
    _lottieNotifier.value = modifiedJson;
  }

  // Private method to convert Flutter color to Lottie color format
  Map<String, dynamic> _flutterColorToLottie(Color flutterColor) {
    final red = flutterColor.r;
    final green = flutterColor.g;
    final blue = flutterColor.b;
    final alpha = flutterColor.a;

    return {
      'a': 0,
      'k': [red, green, blue, alpha],
      'ix': 4,
    };
  }

  // Dispose method to release resources
  void dispose() {
    _lottieNotifier.dispose();
  }
}
