import 'package:ebroker/utils/helper_utils.dart';

class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

  static const String applicationName = 'عقاركم';
  static const String androidPackageName = 'com.aqarcoom.userapp';

  // ---------------------------------------------------------------------------
  // Network / API
  // ---------------------------------------------------------------------------

  // Remove Debug Logger Before Update

  /// Base host URL. Change this to point at a different backend environment.
  static const String hostUrl = 'https://link.aqarcoom.com';

  ///   ebroker.wrteam.me

  /// Web URL used when building share links for properties, projects, etc.
  static const String shareNavigationWebUrl = 'aqarcoom.com';

  ///   ebrokerweb.wrteam.me

  /// Full base URL used for all API requests. Do not change this.
  static final String baseUrl = '${HelperUtils.checkHost(hostUrl)}api/';

  // ---------------------------------------------------------------------------
  // Pagination / Data loading
  // ---------------------------------------------------------------------------

  /// Default page size for paginated API requests.
  static const int apiDataLoadLimit = 10;

  /// Maximum number of categories shown in the home screen before "More"
  /// button appears. Must be less than [apiDataLoadLimit].
  static const int maxCategoryShowLengthInHomeScreen = 5;

  /// Seconds to delay background API calls when cached data is already
  /// available, so the UI does not flicker.
  static const int hiddenAPIProcessDelay = 1;

  // ---------------------------------------------------------------------------
  // Deep linking
  // ---------------------------------------------------------------------------

  /// Type of deep link strategy used across the app.
  static const DeepLinkType deepLinkingType = DeepLinkType.native;

  // ---------------------------------------------------------------------------
  // Authentication / OTP
  // ---------------------------------------------------------------------------

  /// Seconds before the resend-OTP button becomes active (phone OTP).
  static const int otpResendSecond = 120;

  /// Seconds before a phone OTP session times out.
  static const int otpTimeOutSecond = 120;

  /// Seconds before the resend-OTP button becomes active (email OTP).
  static const int otpResendSecondForEmail = 600;

  /// Default country dial code shown on the login screen. Do not add '+'.
  static const String defaultCountryCode = '20';

  // ---------------------------------------------------------------------------
  // Lottie / Progress animations
  // ---------------------------------------------------------------------------

  /// Lottie file name inside `assets/lottie/` used as the loading indicator.
  static const String progressLottieFile = 'loading.json';

  /// Lottie file name used when the background is dark.
  static const String progressLottieFileWhite = 'loading_white.json';

  /// Lottie file name shown during maintenance mode.
  static const String maintenanceModeLottieFile = 'maintenancemode.json';

  /// Set to false to fall back to a plain CircularProgressIndicator.
  static const bool useLottieProgress = true;

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Android notification channel ID.
  static const String notificationChannel = 'basic_channel';

  // ---------------------------------------------------------------------------
  // Media
  // ---------------------------------------------------------------------------

  /// JPEG quality (0–100) when compressing images before upload.
  static const int uploadImageQuality = 50;

  // ---------------------------------------------------------------------------
  // Map
  // ---------------------------------------------------------------------------

  /// Default zoom level for the "Properties on Map" screen (overview & property selection).
  /// Set to 5 for regional/country level view (matching screenshot), higher values zoom closer.
  static const double propertyMapScreenZoom = 6;

  /// Default zoom level for property & project location maps on details screens.
  /// Lower values zoom out further (e.g. 10–11 for district/area level, 12–13 for neighborhood level, 14–15 for street level).
  static const double propertyDetailsMapZoom = 11;
}

// ---------------------------------------------------------------------------
// Supporting enums (compile-time config — live here, not in settings.dart)
// ---------------------------------------------------------------------------

/// Sections available on the home screen.
enum HomeScreenSections {
  search,
  slider,
  personalizedFeed,
  nearbyProperties,
  featuredProperties,
  mostLikedProperties,
  popularCities,
  agents,
  mostViewed,
  category,
  project,
  featuredProjects,
}

/// Deep-link strategy used for share URLs.
enum DeepLinkType { native }
