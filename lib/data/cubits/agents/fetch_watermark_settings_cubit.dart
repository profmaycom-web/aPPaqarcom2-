import 'package:ebroker/data/model/watermark_settings_model.dart';
import 'package:ebroker/data/repositories/watermark_settings_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ─────────────────────────────────────────────────────────────────

abstract class FetchWatermarkSettingsState {}

class FetchWatermarkSettingsInitial extends FetchWatermarkSettingsState {}

class FetchWatermarkSettingsInProgress extends FetchWatermarkSettingsState {}

class FetchWatermarkSettingsSuccess extends FetchWatermarkSettingsState {
  FetchWatermarkSettingsSuccess(this.settings);
  final WatermarkSettingsModel settings;
}

class FetchWatermarkSettingsFailure extends FetchWatermarkSettingsState {
  FetchWatermarkSettingsFailure(this.errorMessage);
  final String errorMessage;
}

// ── Cubit ──────────────────────────────────────────────────────────────────

class FetchWatermarkSettingsCubit extends Cubit<FetchWatermarkSettingsState> {
  FetchWatermarkSettingsCubit() : super(FetchWatermarkSettingsInitial());

  final WatermarkSettingsRepository _repository = WatermarkSettingsRepository();

  Future<void> fetch() async {
    try {
      emit(FetchWatermarkSettingsInProgress());
      final settings = await _repository.getSettings();
      emit(FetchWatermarkSettingsSuccess(settings));
    } on ApiException catch (e) {
      emit(FetchWatermarkSettingsFailure(e.toString()));
    } on Exception catch (e) {
      emit(FetchWatermarkSettingsFailure(e.toString()));
    }
  }
}
