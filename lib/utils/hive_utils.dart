import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/data/model/user_model.dart';
import 'package:ebroker/data/repositories/auth_repository.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/utils/active_role_manager.dart';
import 'package:ebroker/utils/follow_manager.dart';
import 'package:ebroker/utils/hive_keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:material_ui/material_ui.dart';

class HiveUtils {
  HiveUtils._();

  static dynamic initBoxes() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(HiveKeys.authBox);
    await Hive.openBox<dynamic>(HiveKeys.userDetailsBox);
    await Hive.openBox<dynamic>(HiveKeys.agentProfileBox);
    await Hive.openBox<dynamic>(HiveKeys.homeLocationBox);
    await Hive.openBox<dynamic>(HiveKeys.languageBox);
    await Hive.openBox<dynamic>(HiveKeys.themeBox);
    await Hive.openBox<dynamic>(HiveKeys.svgBox);
    await Hive.openBox<dynamic>(HiveKeys.themeColorBox);
  }

  static String? getJWT() {
    return Hive.box<dynamic>(
          HiveKeys.userDetailsBox,
        ).get(HiveKeys.jwtToken)?.toString() ??
        '';
  }

  static Future<void> dontShowChooseLocationDialoge() async {
    await Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).put('showChooseLocationDialoge', false);
  }

  static bool isGuest() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get('isGuest') as bool? ??
        true;
  }

  static Future<void> setAppThemeSetting(Map<String, dynamic> data) async {
    await Hive.box<dynamic>(HiveKeys.themeColorBox).putAll(data);
  }

  static Map<String, dynamic> getAppThemeSettings() {
    return Map<String, dynamic>.from(
      Hive.box<dynamic>(HiveKeys.themeColorBox).toMap(),
    );
  }

  static Future<void> setIsNotGuest() async {
    await Hive.box<dynamic>(HiveKeys.userDetailsBox).put('isGuest', false);
  }

  static Future<void> setIsGuest() async {
    await Hive.box<dynamic>(HiveKeys.userDetailsBox).put('isGuest', true);
  }

  static bool isShowChooseLocationDialoge() {
    final value = Hive.box<dynamic>(HiveKeys.userDetailsBox).get(
      'showChooseLocationDialoge',
    );

    if (value == null) {
      return true;
    }
    return false;
  }

  static String? getUserId() {
    if (Hive.box<dynamic>(HiveKeys.userDetailsBox).get('id') == null) {
      return null;
    }
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get('id').toString();
  }

  static String getCurrentTheme() {
    return Hive.box<dynamic>(
          HiveKeys.themeBox,
        ).get(HiveKeys.currentTheme, defaultValue: 'system')?.toString() ??
        'system';
  }

  static dynamic getCountryCode() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).toMap()['country_code'];
  }

  static dynamic getUserLatitude() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get(HiveKeys.latitude);
  }

  static dynamic getUserLongitude() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get(HiveKeys.longitude);
  }

  static dynamic getLatitude() {
    return Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.latitude);
  }

  static dynamic getLongitude() {
    return Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.longitude);
  }

  static dynamic getRadius() {
    return Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.radius);
  }

  static Future<void> setProfileNotCompleted() async {
    await Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).put(HiveKeys.isProfileCompleted, false);
  }

  static Future<void> setCurrentTheme(ThemeMode theme) async {
    String themeValue;
    switch (theme) {
      case ThemeMode.system:
        themeValue = 'system';
      case ThemeMode.dark:
        themeValue = 'dark';
      case ThemeMode.light:
        themeValue = 'light';
    }
    await Hive.box<dynamic>(
      HiveKeys.themeBox,
    ).put(HiveKeys.currentTheme, themeValue);
  }

  static Future<void> setUserData(Map<dynamic, dynamic> data) async {
    await Hive.box<dynamic>(HiveKeys.userDetailsBox).putAll(data);
  }

  static Future<void> setAgentProfileData(Map<String, dynamic> data) async {
    final box = Hive.box<dynamic>(HiveKeys.agentProfileBox);
    await box.clear();
    await box.putAll(data);
  }

  static AgentProfileModel? getAgentProfileData() {
    try {
      final box = Hive.box<dynamic>(HiveKeys.agentProfileBox);
      if (box.isEmpty) return null;
      return AgentProfileModel.fromMap(Map<String, dynamic>.from(box.toMap()));
    } on Object catch (_) {
      return null;
    }
  }

  static Future<void> clearAgentProfileData() async {
    await Hive.box<dynamic>(HiveKeys.agentProfileBox).clear();
  }

  static LoginType getUserLoginType() {
    return LoginType.values.firstWhere(
      (element) =>
          element.name ==
          Hive.box<dynamic>(HiveKeys.userDetailsBox).get('type'),
    );
  }

  static bool isUserAgent() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get('is_agent')
            as bool? ??
        false;
  }

  static bool isUserVerified() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get('is_user_verified')
            as bool? ??
        false;
  }

  static bool isAgentVerified() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get('is_agent_verified')
            as bool? ??
        false;
  }

  static bool isAdminAdded() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get('is_admin_added')
            as bool? ??
        false;
  }

  static bool isEmailVerified() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get('is_email_verified')
            as bool? ??
        false;
  }

  static String getBecomeAgentStatus() {
    return Hive.box<dynamic>(
          HiveKeys.userDetailsBox,
        ).get('become_agent_status')?.toString() ??
        '';
  }

  static String getAgentVerificationStatus() {
    return Hive.box<dynamic>(
          HiveKeys.userDetailsBox,
        ).get('agent_verification_status')?.toString() ??
        '';
  }

  static String? getAgentProfile() {
    return Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).get('agent_profile_photo')?.toString();
  }

  static ActiveRole getActiveRole() {
    final raw = Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).get(HiveKeys.activeRole)?.toString();
    return ActiveRole.fromString(raw);
  }

  static Future<void> setActiveRole(ActiveRole role) async {
    await Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).put(HiveKeys.activeRole, role.value);
  }

  static dynamic getUserCityName() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get(HiveKeys.city);
  }

  static dynamic getUserCityPlaceId() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get(HiveKeys.cityPlaceId);
  }

  static dynamic getUserStateName() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get(HiveKeys.stateKey);
  }

  static dynamic getUserCountryName() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get(HiveKeys.countryKey);
  }

  static String? getSelectedCountryName() {
    final selected =
        Hive.box<dynamic>(HiveKeys.userDetailsBox).get('selected_country_name')
            as String?;
    if (selected != null && selected.trim().isNotEmpty) {
      return selected.trim();
    }
    final userCountry = HiveUtils.getUserCountryName()?.toString();
    if (userCountry != null && userCountry.trim().isNotEmpty) {
      return userCountry.trim();
    }
    return null;
  }

  static String? getSelectedCountryId() {
    return Hive.box<dynamic>(HiveKeys.userDetailsBox).get('selected_country_id')
        as String?;
  }

  static Future<void> setSelectedCountry({
    required String name,
    required String id,
    String currencyCode = '',
    String currencySymbol = '',
  }) async {
    final box = Hive.box<dynamic>(HiveKeys.userDetailsBox);
    await box.put('selected_country_name', name);
    await box.put('selected_country_id', id);
    await box.put('selected_country_currency_code', currencyCode);
    await box.put('selected_country_currency_symbol', currencySymbol);
    AppSettings.currentCountryId = id;
    applySelectedCountryCurrency();
  }

  static String? getSelectedCountryCurrencyCode() {
    return Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).get('selected_country_currency_code') as String?;
  }

  static String? getSelectedCountryCurrencySymbol() {
    return Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).get('selected_country_currency_symbol') as String?;
  }

  /// The app settings API always answers with the default currency, so the
  /// currency of the selected country is what the app has to use while a
  /// country is selected.
  static bool applySelectedCountryCurrency() {
    final code = getSelectedCountryCurrencyCode() ?? '';
    final symbol = getSelectedCountryCurrencySymbol() ?? '';
    if (code.isEmpty && symbol.isEmpty) return false;
    if (code.isNotEmpty) AppSettings.currencyCode = code;
    if (symbol.isNotEmpty) AppSettings.currencySymbol = symbol;
    return true;
  }

  static dynamic getHomeLatitude() {
    return Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.latitude);
  }

  static dynamic getHomeLongitude() {
    return Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.longitude);
  }

  static dynamic getHomeCityName() {
    return Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.city);
  }

  static dynamic getHomeCityPlaceId() {
    return Hive.box<dynamic>(
      HiveKeys.homeLocationBox,
    ).get(HiveKeys.cityPlaceId);
  }

  static dynamic getHomeStateName() {
    return Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.stateKey);
  }

  static dynamic getHomeCountryName() {
    return Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.countryKey);
  }

  static Future<void> setJWT(String token) async {
    await Hive.box<dynamic>(
      HiveKeys.userDetailsBox,
    ).put(HiveKeys.jwtToken, token);
  }

  static UserModel getUserDetails() {
    return UserModel.fromJson(
      Map<String, dynamic>.from(
        Hive.box<dynamic>(HiveKeys.userDetailsBox).toMap(),
      ),
    );
  }

  static Future<void> setUserIsAuthenticated() async {
    await Hive.box<dynamic>(
      HiveKeys.authBox,
    ).put(HiveKeys.isAuthenticated, true);
  }

  static Future<void> setUserIsNotAuthenticated() async =>
      Hive.box<dynamic>(HiveKeys.authBox).put(HiveKeys.isAuthenticated, false);

  static Future<void> setUserIsNotNew() async {
    await Hive.box<dynamic>(
      HiveKeys.authBox,
    ).put(HiveKeys.isAuthenticated, true);
    return Hive.box<dynamic>(
      HiveKeys.authBox,
    ).put(HiveKeys.isUserFirstTime, false);
  }

  static bool isLocationFilled() {
    final city = Hive.box<dynamic>(HiveKeys.homeLocationBox).get(HiveKeys.city);
    final state = Hive.box<dynamic>(
      HiveKeys.homeLocationBox,
    ).get(HiveKeys.stateKey);
    final country = Hive.box<dynamic>(
      HiveKeys.homeLocationBox,
    ).get(HiveKeys.countryKey);

    if (city == null && state == null && country == null) {
      return false;
    } else {
      return true;
    }
  }

  static String getLanguageCode() {
    try {
      final languageData = Hive.box<dynamic>(
        HiveKeys.languageBox,
      ).get(HiveKeys.currentLanguageKey);

      if (languageData == null) {
        return 'en';
      }

      final code = languageData['code']?.toString() ?? 'en';
      return code;
    } on Exception catch (_) {
      return 'en';
    }
  }

  static Future<void> setLocation({
    required String city,
    required String state,
    required String? latitude,
    required String? longitude,
    required String country,
    required String placeId,
  }) async {
    try {
      await Hive.box<dynamic>(HiveKeys.userDetailsBox).put(HiveKeys.city, city);
      await Hive.box<dynamic>(
        HiveKeys.userDetailsBox,
      ).put(HiveKeys.stateKey, state);
      await Hive.box<dynamic>(
        HiveKeys.userDetailsBox,
      ).put(HiveKeys.countryKey, country);

      if (latitude != null) {
        await Hive.box<dynamic>(
          HiveKeys.userDetailsBox,
        ).put(HiveKeys.latitude, latitude);
      }
      if (longitude != null) {
        await Hive.box<dynamic>(
          HiveKeys.userDetailsBox,
        ).put(HiveKeys.longitude, longitude);
      }
    } on Exception catch (_) {}
  }

  static Future<void> setHomeLocation({
    required String city,
    required String state,
    required String? latitude,
    required String? longitude,
    required String country,
    required String placeId,
    required String? radius,
  }) async {
    try {
      await Hive.box<dynamic>(
        HiveKeys.homeLocationBox,
      ).put(HiveKeys.city, city);
      await Hive.box<dynamic>(
        HiveKeys.homeLocationBox,
      ).put(HiveKeys.stateKey, state);
      await Hive.box<dynamic>(
        HiveKeys.homeLocationBox,
      ).put(HiveKeys.countryKey, country);

      if (latitude != null) {
        await Hive.box<dynamic>(
          HiveKeys.homeLocationBox,
        ).put(HiveKeys.latitude, latitude);
      }
      if (longitude != null) {
        await Hive.box<dynamic>(
          HiveKeys.homeLocationBox,
        ).put(HiveKeys.longitude, longitude);
      }
      if (radius != null) {
        await Hive.box<dynamic>(
          HiveKeys.homeLocationBox,
        ).put(HiveKeys.radius, radius);
      }
    } on Exception catch (_) {}
  }

  static Future<void> clearLocation() async {
    await Hive.box<dynamic>(HiveKeys.userDetailsBox).putAll({
      HiveKeys.city: '',
      HiveKeys.stateKey: '',
      HiveKeys.countryKey: '',
      HiveKeys.latitude: '',
      HiveKeys.longitude: '',
      HiveKeys.radius: AppSettings.minRadius,
    });
  }

  static Future<void> clearHomeLocation() async {
    await Hive.box<dynamic>(HiveKeys.homeLocationBox).putAll({
      HiveKeys.city: '',
      HiveKeys.stateKey: '',
      HiveKeys.countryKey: '',
      HiveKeys.latitude: '',
      HiveKeys.longitude: '',
      HiveKeys.radius: AppSettings.minRadius,
    });
  }

  static Future<bool> storeLanguage(
    dynamic data,
  ) async {
    await Hive.box<dynamic>(
      HiveKeys.languageBox,
    ).put(HiveKeys.currentLanguageKey, data);

    return true;
  }

  static dynamic getLanguage() {
    return Hive.box<dynamic>(
      HiveKeys.languageBox,
    ).get(HiveKeys.currentLanguageKey);
  }

  @visibleForTesting
  static Future<void> setUserIsNew() async {
    //Only testing purpose // not in production
    await Hive.box<dynamic>(
      HiveKeys.authBox,
    ).put(HiveKeys.isAuthenticated, false);
    return Hive.box<dynamic>(
      HiveKeys.authBox,
    ).put(HiveKeys.isUserFirstTime, true);
  }

  static bool isUserAuthenticated() {
    return Hive.box<dynamic>(HiveKeys.authBox).get(HiveKeys.isAuthenticated)
            as bool? ??
        false;
  }

  static bool isUserFirstTime() {
    return Hive.box<dynamic>(HiveKeys.authBox).get(HiveKeys.isUserFirstTime)
            as bool? ??
        true;
  }

  static Future<void> logoutUser(
    BuildContext context, {
    required VoidCallback onLogout,
    bool? isRedirect,
  }) async {
    try {
      final loginType = HiveUtils.getUserLoginType();
      if (loginType == LoginType.email) {
        await AuthRepository().beforeLogout();
        await FirebaseAuth.instance.signOut();
        await setUserIsNotAuthenticated();
        await Hive.box<dynamic>(HiveKeys.userDetailsBox).clear();
        onLogout.call();
        await HiveUtils.setUserIsNotAuthenticated();
        await context.read<AgentProfileCubit>().reset();
        await HiveUtils.clear();
      }
      if (loginType == LoginType.phone &&
          AppSettings.otpServiceProvider == 'firebase') {
        await AuthRepository().beforeLogout();
        await FirebaseAuth.instance.signOut();
        await setUserIsNotAuthenticated();
        await Hive.box<dynamic>(HiveKeys.userDetailsBox).clear();
        onLogout.call();
        await HiveUtils.setUserIsNotAuthenticated();
        await context.read<AgentProfileCubit>().reset();
        await HiveUtils.clear();
      }
      if (loginType == LoginType.apple || loginType == LoginType.google) {
        await AuthRepository().beforeLogout();
        await FirebaseAuth.instance.signOut();
        await setUserIsNotAuthenticated();
        await Hive.box<dynamic>(HiveKeys.userDetailsBox).clear();
        onLogout.call();
        await HiveUtils.setUserIsNotAuthenticated();
        await context.read<AgentProfileCubit>().reset();
        await HiveUtils.clear();
      }
      if (loginType == LoginType.phone &&
          AppSettings.otpServiceProvider == 'twilio') {
        await setUserIsNotAuthenticated();
        await Hive.box<dynamic>(HiveKeys.userDetailsBox).clear();
        onLogout.call();
        await HiveUtils.setUserIsNotAuthenticated();
        await context.read<AgentProfileCubit>().reset();
        await HiveUtils.clear();
      }
      await Future.delayed(
        Duration.zero,
        () async {
          if (isRedirect ?? true) {
            await Navigator.pushReplacementNamed(context, Routes.login);
          }
        },
      );
    } on Exception catch (_) {
      await Future.delayed(
        Duration.zero,
        () async {
          if (isRedirect ?? true) {
            await Navigator.pushReplacementNamed(context, Routes.login);
          }
        },
      );
    }
  }

  static Set<int> getFollowedAgents() {
    try {
      final raw = Hive.box<dynamic>(HiveKeys.userDetailsBox).get(
        HiveKeys.followedAgents,
      );
      if (raw is List) {
        return raw.map((e) => int.tryParse(e.toString()) ?? 0).toSet();
      }
      if (raw is Set) {
        return raw.map((e) => int.tryParse(e.toString()) ?? 0).toSet();
      }
    } on Exception catch (_) {}
    return {};
  }

  static Future<void> setAgentFollowed(
    int agentId, {
    required bool isFollowing,
  }) async {
    try {
      final followed = getFollowedAgents();
      if (isFollowing) {
        followed.add(agentId);
      } else {
        followed.remove(agentId);
      }
      await Hive.box<dynamic>(HiveKeys.userDetailsBox).put(
        HiveKeys.followedAgents,
        followed.toList(),
      );
    } on Exception catch (_) {}
  }

  static bool isAgentFollowedInHive(int agentId) {
    final followed = getFollowedAgents();
    return followed.contains(agentId);
  }

  static Future<void> clear() async {
    FollowManager.clearCache();
    await Hive.box<dynamic>(HiveKeys.userDetailsBox).clear();
    await Hive.box<dynamic>(HiveKeys.agentProfileBox).clear();
  }
}
