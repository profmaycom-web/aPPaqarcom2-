import 'package:ebroker/data/model/company.dart';
import 'package:ebroker/data/model/languages_model.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/data/repositories/system_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/network/cache_manger.dart';

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class FetchSystemSettingsState {}

class FetchSystemSettingsInitial extends FetchSystemSettingsState {}

class FetchSystemSettingsInProgress extends FetchSystemSettingsState {}

class FetchSystemSettingsSuccess extends FetchSystemSettingsState {
  FetchSystemSettingsSuccess({required this.settings});
  final Map<dynamic, dynamic> settings;
}

class FetchSystemSettingsFailure extends FetchSystemSettingsState {
  FetchSystemSettingsFailure(this.errorMessage);
  final String errorMessage;
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class FetchSystemSettingsCubit extends Cubit<FetchSystemSettingsState> {
  FetchSystemSettingsCubit() : super(FetchSystemSettingsInitial());

  final SystemRepository _systemRepository = SystemRepository();

  Company? companyData;

  /// Tracks whether the in-flight [_applySettings] call is applying a fresh
  /// network response (vs. the offline/cached fallback), so we know whether
  /// it's safe to evict the login-background image cache.
  bool _lastFetchFromNetwork = false;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  Future<void> fetchSettings({
    required bool isAnonymous,
    bool? forceRefresh,
  }) async {
    try {
      await CacheData().getData(
        forceRefresh: forceRefresh ?? false,
        delay: 0,
        onProgress: () {
          emit(FetchSystemSettingsInProgress());
        },
        onNetworkRequest: () async {
          _lastFetchFromNetwork = true;
          return _systemRepository.fetchSystemSettings(
            isAnonymouse: isAnonymous,
          );
        },
        onOfflineData: () {
          _lastFetchFromNetwork = false;
          return (state as FetchSystemSettingsSuccess).settings;
        },
        onSuccess: _applySettings,
        hasData: state is FetchSystemSettingsSuccess,
      );
    } on Exception catch (e) {
      emit(FetchSystemSettingsFailure(e.toString()));
    }
  }

  /// Returns a single setting value by [SystemSetting] key.
  dynamic getSetting(SystemSetting selected) {
    if (state is! FetchSystemSettingsSuccess) return null;

    final settings =
        (state as FetchSystemSettingsSuccess).settings['data'] as Map;

    if (selected == SystemSetting.languageType) {
      return settings['languages'];
    }
    if (selected == SystemSetting.demoMode) {
      return settings.containsKey('demo_mode') ? settings['demo_mode'] : false;
    }

    return settings[Constant.systemSettingKeys[selected]];
  }

  /// Returns the raw `data` map from the last successful response.
  Map<dynamic, dynamic> getRawSettings() {
    if (state is FetchSystemSettingsSuccess) {
      return (state as FetchSystemSettingsSuccess).settings['data'] as Map;
    }
    return {};
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _applySettings(Map<dynamic, dynamic> data) {
    final response = data['data'] as Map<dynamic, dynamic>;

    try {
      appSettings = AppSettingsDataModel.fromJson(
        Map<String, dynamic>.from(response),
      );
      unawaited(
        HiveUtils.setAppThemeSetting(Map<String, dynamic>.from(response)),
      );
      // Same in-place-URL stale image issue as loginBackground below: the
      // backend re-uses the same URL when these logos are replaced.
      if (_lastFetchFromNetwork) {
        for (final logoUrl in [
          appSettings.placeholderLogo,
          appSettings.appHomeScreen,
          appSettings.darkModeLogo,
        ]) {
          if (logoUrl != null && logoUrl.isNotEmpty) {
            unawaited(CachedNetworkImage.evictFromCache(logoUrl));
          }
        }
      }
    } on Exception {
      // If theme parsing fails, keep the existing theme — don't crash.
    }

    // --- Company data (replaces CompanyCubit API call) ---------------------
    companyData = Company.fromJson(Map<String, dynamic>.from(response));

    // --- Currency ----------------------------------------------------------
    final selectedCurrencyData =
        (response['selected_currency_data'] ?? <String, dynamic>{}) as Map;
    // A selected country carries its own currency and must win over the
    // default currency the settings API always returns.
    if (HiveUtils.applySelectedCountryCurrency()) {
      // nothing to do, the country currency is already applied
    } else if (selectedCurrencyData.isNotEmpty) {
      AppSettings.currencyCode = selectedCurrencyData['code']?.toString() ?? '';
      AppSettings.currencySymbol =
          selectedCurrencyData['symbol']?.toString() ?? '₹';
    } else {
      // Fallback: use top-level currency_symbol key
      final fallbackSymbol = _get(
        data,
        SystemSetting.currencySymbol,
      )?.toString();
      if (fallbackSymbol != null && fallbackSymbol.isNotEmpty) {
        AppSettings.currencySymbol = fallbackSymbol;
      }
    }

    // --- Demo mode ---------------------------------------------------------
    if (response.containsKey('demo_mode')) {
      AppSettings.isDemoModeOn = response['demo_mode'] as bool? ?? false;
    }

    // --- Stories -------------------------------------------------------------
    final storyMaxDuration = int.tryParse(
      response['story_max_duration']?.toString() ?? '',
    );
    AppSettings.storyMaxDurationSeconds =
        (storyMaxDuration != null && storyMaxDuration > 0)
        ? storyMaxDuration
        : 30;

    // --- AdMob -------------------------------------------------------------
    AppSettings.isAdmobAdsEnabled =
        response['show_admob_ads'] == '1' || response['show_admob_ads'] == true;
    AppSettings.admobBannerAndroid =
        response['android_banner_ad_id']?.toString() ?? '';
    AppSettings.admobBannerIos = response['ios_banner_ad_id']?.toString() ?? '';
    AppSettings.admobNativeAndroid =
        response['android_native_ad_id']?.toString() ?? '';
    AppSettings.admobNativeIos = response['ios_native_ad_id']?.toString() ?? '';
    AppSettings.admobInterstitialAndroid =
        response['android_interstitial_ad_id']?.toString() ?? '';
    AppSettings.admobInterstitialIos =
        response['ios_interstitial_ad_id']?.toString() ?? '';

    // --- Feature flags -----------------------------------------------------
    AppSettings.homePageLocationAlertStatus =
        response['home_page_location_alert_status'] == '1';
    AppSettings.isAIEnabled = response['gemini_ai_enabled'] == true;
    AppSettings.isVerificationRequiredForUser =
        (response['verification_required_for_user'] as bool?) ?? false;
    AppSettings.isVerificationRequiredForAgent =
        (response['verification_required_for_agent'] as bool?) ?? false;
    AppSettings.showDirectVideoUpload =
        response['show_direct_video_upload'] == '1' ||
        response['show_direct_video_upload'] == true;
    AppSettings.showPremiumToggle =
        response['show_premium_toggle'] == '1' ||
        response['show_premium_toggle'] == true;
    AppSettings.showExactLocation =
        response['show_exact_location'] == '1' ||
        response['show_exact_location'] == true;
    AppSettings.showWhatsappButton =
        response['show_whatsapp_button'] == '1' ||
        response['show_whatsapp_button'] == true;

    // --- Store URLs --------------------------------------------------------
    AppSettings.playstoreURLAndroid =
        response['playstore_id']?.toString() ?? '';
    AppSettings.appstoreURLios = response['appstore_id']?.toString() ?? '';
    AppSettings.iOSAppId = (response['appstore_id'] ?? '')
        .toString()
        .split('/')
        .last;

    // --- OTP ---------------------------------------------------------------
    AppSettings.otpServiceProvider =
        response['otp_service_provider']?.toString() ?? '';

    // --- Map / Location ----------------------------------------------------
    AppSettings.mapServiceProvider =
        response['map_service_provider'] == 'open_street_maps'
        ? MapProvider.openStreetMaps
        : MapProvider.googleMaps;
    AppSettings.minRadius = response['min_radius']?.toString() ?? '';
    AppSettings.maxRadius = response['max_radius']?.toString() ?? '';
    AppSettings.latitude = response['latitude']?.toString() ?? '20.5937';
    AppSettings.longitude = response['longitude']?.toString() ?? '78.9629';
    AppSettings.distanceOption = response['distance_option']?.toString() ?? '';

    // --- UI / Branding -----------------------------------------------------
    final newLoginBackground =
        response['app_login_background']?.toString() ?? '';
    if (_lastFetchFromNetwork && newLoginBackground.isNotEmpty) {
      // Backend re-uses the same URL when the login background is replaced,
      // so CachedNetworkImage's disk cache (keyed by URL) would otherwise
      // keep serving stale bytes until the app is uninstalled. Evict on
      // every fresh network fetch so the next paint re-downloads it.
      unawaited(CachedNetworkImage.evictFromCache(newLoginBackground));
    }
    AppSettings.loginBackground = newLoginBackground;

    // --- Languages ---------------------------------------------------------
    AppSettings.languages = (response['languages'] as List? ?? [])
        .map((e) => LanguagesModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // --- Payments ----------------------------------------------------------
    AppSettings.bankTransferDetails =
        (response['bank_details'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    emit(FetchSystemSettingsSuccess(settings: data));
  }

  /// Reads a single setting from the raw response map using systemSettingKeys.
  dynamic _get(Map<dynamic, dynamic> settings, SystemSetting selected) {
    return (settings['data'] as Map? ??
        {})[Constant.systemSettingKeys[selected]];
  }
}
