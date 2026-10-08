import 'package:ebroker/data/model/languages_model.dart';
import 'package:ebroker/utils/map/map_provider.dart';

class AppSettings {
  AppSettings._();

  // ---------------------------------------------------------------------------
  // Store URLs  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  static String playstoreURLAndroid = '';
  static String appstoreURLios = '';

  /// iOS App Store numeric ID, derived from [appstoreURLios].
  static String iOSAppId = '';

  // ---------------------------------------------------------------------------
  // Authentication / OTP
  // ---------------------------------------------------------------------------

  /// OTP provider selected in the admin panel ('firebase' | 'twilio' | …).
  static String otpServiceProvider = '';

  // ---------------------------------------------------------------------------
  // Currency  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  static String currencyCode = '';

  /// Currency symbol. Defaults to '₹' as a safe fallback until the server
  /// response is available.
  static String currencySymbol = '₹';

  /// Currently selected country ID for headers (X-Country-Id)
  static String currentCountryId = '';

  // ---------------------------------------------------------------------------
  // Feature flags  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  static bool isAIEnabled = false;
  static bool isVerificationRequiredForUser = false;
  static bool isVerificationRequiredForAgent = false;
  static bool showDirectVideoUpload = false;
  static bool showPremiumToggle = true;
  static bool showExactLocation = false;
  static bool showWhatsappButton = false;
  static bool homePageLocationAlertStatus = true;

  // ---------------------------------------------------------------------------
  // Map / Location defaults  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  static MapProvider mapServiceProvider = MapProvider.googleMaps;
  static String latitude = '20.5937';
  static String longitude = '78.9629';
  static String minRadius = '1';
  static String maxRadius = '100';
  static String distanceOption = '';

  // ---------------------------------------------------------------------------
  // UI / Branding  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  static String loginBackground = '';
  static List<LanguagesModel> languages = [];

  // ---------------------------------------------------------------------------
  // Payments  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  static List<Map<String, dynamic>> bankTransferDetails = [];

  // ---------------------------------------------------------------------------
  // Payment gateways  (written by GetApiKeysCubit)
  // ---------------------------------------------------------------------------

  static List<String> enabledPaymentGateways = [];
  static String enabledPaymentGateway = '';

  // ---------------------------------------------------------------------------
  // Ads / AdMob  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  static bool isAdmobAdsEnabled = false;
  static String admobBannerAndroid = '';
  static String admobBannerIos = '';
  static String admobInterstitialAndroid = '';
  static String admobInterstitialIos = '';
  static String admobNativeAndroid = '';
  static String admobNativeIos = '';

  // ---------------------------------------------------------------------------
  // Demo mode  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  static bool isDemoModeOn = false;

  // ---------------------------------------------------------------------------
  // Stories  (written by FetchSystemSettingsCubit)
  // ---------------------------------------------------------------------------

  /// Max story video duration in seconds. Server-driven; defaults to 30 if
  /// unset/invalid, matching web (`story_max_duration`).
  static int storyMaxDurationSeconds = 30;
}
