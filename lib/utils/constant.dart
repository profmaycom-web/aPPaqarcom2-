import 'package:ebroker/config/app_config.dart';
import 'package:ebroker/data/model/propery_filter_model.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:material_ui/material_ui.dart';

const String svgPath = 'assets/svg/';

abstract class Constant {
  static String get appName => AppConfig.applicationName;
  static String get androidPackageName => AppConfig.androidPackageName;

  // ---------------------------------------------------------------------------
  // UI infrastructure
  // ---------------------------------------------------------------------------

  static ScrollPhysics scrollPhysics = const AlwaysScrollableScrollPhysics();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'navigatorKey from constants',
  );

  static Future<void> navigateTo(String routeName, {Object? arguments}) async {
    await navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  // ---------------------------------------------------------------------------
  // Session / transient state
  // ---------------------------------------------------------------------------

  static String? subscriptionPackageId;
  static PropertyFilterModel? propertyFilter;
  static List<int> interestedPropertyIds = [];
  static Map<dynamic, dynamic> addProperty = {};

  // ---------------------------------------------------------------------------
  // Notification / enquiry constants
  // ---------------------------------------------------------------------------

  static String typeRent = 'rent';
  static String valSellBuy = '0';
  static String valRent = '1';
  static const List<String> rentDurations = [
    'Daily',
    'Monthly',
    'Yearly',
  ];
  static String generalNotification = '0';
  static String enquiryNotification = '1';
  static String notificationPropertyEnquiry = 'property_inquiry';
  static String notificationDefault = 'default';

  // ---------------------------------------------------------------------------
  // System settings – maintenance / update flags
  // ---------------------------------------------------------------------------

  static String maintenanceMode = '0'; // '0' = OFF
  static bool isUpdateAvailable = false;
  static String newVersionNumber = '';
  static bool isNumberWithSuffix = false;

  // ---------------------------------------------------------------------------
  // Isolate task IDs (set by the language/settings loaders)
  // ---------------------------------------------------------------------------

  static int? languageTaskId;
  static int? appSettingTaskId;

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  /// Minimum number of chat messages loaded per page. Must be > 25.
  static int minChatMessages = 35;

  // ---------------------------------------------------------------------------
  // Demo mode credentials (Constant owns these; isDemoModeOn lives in AppSettings)
  // ---------------------------------------------------------------------------

  static String demoCountryCode = '91';
  static String demoMobileNumber = '1234567890';
  static String demoFirebaseID = '6a1Zdl2TxORQGbCazj4XDGfgBBG3';
  static String demoModeOTP = '123456';

  // ---------------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------------

  static const String terminalLogMode = 'debug';

  // ---------------------------------------------------------------------------
  // System settings key map
  //
  // Maps [SystemSetting] enum values to their backend JSON keys.
  // Used by [FetchSystemSettingsCubit.getSetting].
  // ---------------------------------------------------------------------------

  static Map<SystemSetting, String> systemSettingKeys = {
    SystemSetting.currencySymbol: 'currency_symbol',
    SystemSetting.maintenanceMode: 'maintenance_mode',
    SystemSetting.languageType: 'languages',
    SystemSetting.defaultLanguage: 'default_language',
    SystemSetting.forceUpdate: 'force_update',
    SystemSetting.androidVersion: 'android_version',
    SystemSetting.numberWithSuffix: 'number_with_suffix',
    SystemSetting.iosVersion: 'ios_version',
    SystemSetting.language: 'default_language_name',
    SystemSetting.numberWithOtpLogin: 'number_with_otp_login',
    SystemSetting.socialLogin: 'social_login',
    SystemSetting.emailPasswordLogin: 'email_password_login',
    SystemSetting.mapServiceProvider: 'map_service_provider',
  };
}
