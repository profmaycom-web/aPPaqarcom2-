import 'package:ebroker/app/app.dart';
import 'package:ebroker/data/model/app_settings_datamodel.dart';
import 'package:ebroker/ui/theme/theme.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/hive_utils.dart';

AppSettingsDataModel fallbackSettingAppSettings = AppSettingsDataModel(
  appHomeScreen: AppIcons.fallbackHomeLogo,
  placeholderLogo: AppIcons.fallbackPlaceholderLogo,
  lightPrimary: primaryColor_,
  lightSecondary: secondaryColor_,
  lightTertiary: tertiaryColor_,
  darkPrimary: primaryColorDark,
  darkSecondary: secondaryColorDark,
  darkTertiary: tertiaryColorDark,
);

class LoadAppSettings {
  Future<void> load({required bool initBox}) async {
    try {
      if (initBox) {
        await HiveUtils.initBoxes();
      }
      // Restore theme from Hive cache — no network call needed here.
      final cached = HiveUtils.getAppThemeSettings();
      if (cached.isNotEmpty) {
        appSettings = AppSettingsDataModel.fromJson(cached);
      } else {
        appSettings = fallbackSettingAppSettings;
      }
    } on Exception catch (_) {
      appSettings = fallbackSettingAppSettings;
    }
  }
}
