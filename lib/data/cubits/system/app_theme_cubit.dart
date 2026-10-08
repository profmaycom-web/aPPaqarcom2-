import 'dart:async';

import 'package:ebroker/utils/hive_keys.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

class AppThemeCubit extends Cubit<ThemeMode> with WidgetsBindingObserver {
  AppThemeCubit() : super(_getInitialThemeMode()) {
    WidgetsBinding.instance.addObserver(this);
  }

  static ThemeMode _getInitialThemeMode() {
    switch (HiveUtils.getCurrentTheme()) {
      case 'system':
        return ThemeMode.system;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (state == ThemeMode.system) {
      emit(ThemeMode.system);
    }
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    if (state == themeMode) return;
    emit(themeMode);
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      Hive.box<dynamic>(
        HiveKeys.themeBox,
      ).put(HiveKeys.currentTheme, themeMode.name),
    );
  }

  bool get isDarkMode {
    if (state == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == .dark;
    }
    return state == ThemeMode.dark;
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}
