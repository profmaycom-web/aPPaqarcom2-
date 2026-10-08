import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ebroker/data/model/watermark_settings_model.dart';
import 'package:ebroker/utils/api.dart';

class WatermarkSettingsRepository {
  static const String _getUrl = 'get-agent-watermark-settings';
  static const String _updateUrl = 'update-agent-watermark-settings';

  Future<WatermarkSettingsModel> getSettings() async {
    final response = await Api.get(url: _getUrl);
    return WatermarkSettingsModel.fromMap(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<WatermarkSettingsModel> updateSettings({
    required bool watermarkEnabled,
    required double watermarkOpacity,
    required double watermarkSize,
    required String watermarkStyle,
    required String watermarkPosition,
    required double watermarkRotation,
    File? watermarkImage,
  }) async {
    final params = <String, dynamic>{
      'watermark_enabled': watermarkEnabled ? '1' : '0',
      'watermark_opacity': watermarkOpacity.round().toString(),
      'watermark_size': watermarkSize.round().toString(),
      'watermark_style': watermarkStyle,
      'watermark_position': watermarkPosition,
      'watermark_rotation': watermarkRotation.round().toString(),
    };

    if (watermarkImage != null) {
      params['watermark_image'] = await MultipartFile.fromFile(
        watermarkImage.path,
      );
    }

    final response = await Api.post(url: _updateUrl, parameter: params);
    return WatermarkSettingsModel.fromMap(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }
}
