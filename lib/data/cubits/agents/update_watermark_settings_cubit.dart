import 'dart:io';

import 'package:ebroker/data/model/watermark_settings_model.dart';
import 'package:ebroker/data/repositories/watermark_settings_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ─────────────────────────────────────────────────────────────────

abstract class UpdateWatermarkSettingsState {}

class UpdateWatermarkSettingsInitial extends UpdateWatermarkSettingsState {}

class UpdateWatermarkSettingsInProgress extends UpdateWatermarkSettingsState {}

class UpdateWatermarkSettingsSuccess extends UpdateWatermarkSettingsState {
  UpdateWatermarkSettingsSuccess(this.settings);
  final WatermarkSettingsModel settings;
}

class UpdateWatermarkSettingsFailure extends UpdateWatermarkSettingsState {
  UpdateWatermarkSettingsFailure(this.errorMessage);
  final String errorMessage;
}

// ── Cubit ──────────────────────────────────────────────────────────────────

class UpdateWatermarkSettingsCubit extends Cubit<UpdateWatermarkSettingsState> {
  UpdateWatermarkSettingsCubit() : super(UpdateWatermarkSettingsInitial());

  final WatermarkSettingsRepository _repository = WatermarkSettingsRepository();

  Future<void> update({
    required bool watermarkEnabled,
    required double watermarkOpacity,
    required double watermarkSize,
    required String watermarkStyle,
    required String watermarkPosition,
    required double watermarkRotation,
    File? watermarkImage,
  }) async {
    try {
      emit(UpdateWatermarkSettingsInProgress());
      final settings = await _repository.updateSettings(
        watermarkEnabled: watermarkEnabled,
        watermarkOpacity: watermarkOpacity,
        watermarkSize: watermarkSize,
        watermarkStyle: watermarkStyle,
        watermarkPosition: watermarkPosition,
        watermarkRotation: watermarkRotation,
        watermarkImage: watermarkImage,
      );
      emit(UpdateWatermarkSettingsSuccess(settings));
    } on ApiException catch (e) {
      emit(UpdateWatermarkSettingsFailure(e.toString()));
    } on Exception catch (e) {
      emit(UpdateWatermarkSettingsFailure(e.toString()));
    }
  }
}
