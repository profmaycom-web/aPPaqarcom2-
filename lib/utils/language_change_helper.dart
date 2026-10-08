import 'dart:async';

import 'package:ebroker/data/cubits/advertisement/fetch_ad_banners_cubit.dart';
import 'package:ebroker/data/cubits/category/fetch_category_cubit.dart';
import 'package:ebroker/data/cubits/chat_cubits/get_chat_users.dart';
import 'package:ebroker/data/cubits/fetch_custom_pages_cubit.dart';
import 'package:ebroker/data/cubits/fetch_properties_by_cities_cubit.dart';
import 'package:ebroker/data/cubits/outdoorfacility/fetch_outdoor_facility_list.dart';
import 'package:ebroker/data/cubits/project/fetch_my_projects_cubit.dart';
import 'package:ebroker/data/cubits/property/home_infinityscroll_cubit.dart';
import 'package:ebroker/data/cubits/property/report/fetch_property_report_reason_list.dart';
import 'package:ebroker/data/cubits/system/fetch_language_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:ebroker/data/cubits/system/language_cubit.dart';
import 'package:ebroker/data/cubits/system/update_language_cubit.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/ui/screens/home/home_sections.dart';
import 'package:ebroker/utils/active_role_manager.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class LanguageChangeHelper {
  /// True while a country switch is being applied. Screens that refresh
  /// themselves on a country change (e.g. home) use this to stay out of the
  /// way, so the whole app is refreshed exactly once instead of every
  /// listener firing its own set of requests.
  static bool isApplyingCountryChange = false;

  static void refreshAppData(BuildContext context) {
    if (!ActiveRoleManager.isAgent) {
      unawaited(
        HomeSections.fetchAllHomeSections(
          context,
          forceRefresh: true,
        ),
      );
      unawaited(context.read<FetchPropertiesByCitiesCubit>().fetch());
      unawaited(context.read<HomePageInfinityScrollCubit>().fetch());
      unawaited(context.read<FetchAdBannersCubit>().fetch(page: 'homepage'));
    }
    unawaited(
      context.read<FetchSystemSettingsCubit>().fetchSettings(
        isAnonymous: !HiveUtils.isUserAuthenticated(),
      ),
    );
    unawaited(
      context.read<FetchCategoryCubit>().fetchCategories(forceRefresh: true),
    );
    unawaited(context.read<FetchOutdoorFacilityListCubit>().fetch());
    unawaited(context.read<GetChatListCubit>().fetch(forceRefresh: true));
    unawaited(HelperUtils.loadMyProperties(context));
    unawaited(context.read<FetchMyProjectsCubit>().fetchMyProjects());
    unawaited(
      context.read<FetchPropertyReportReasonsListCubit>().fetch(
        forceRefresh: true,
      ),
    );
    unawaited(context.read<FetchCustomPagesCubit>().fetchCustomPages());
  }

  static String getDefaultLanguageCode(BuildContext context) {
    try {
      final defaultLang = context
          .read<FetchSystemSettingsCubit>()
          .getSetting(SystemSetting.defaultLanguage)
          ?.toString();
      if (defaultLang != null && defaultLang.trim().isNotEmpty) {
        return defaultLang.trim();
      }
    } on Exception catch (_) {}
    return 'en';
  }

  static String? getLanguageCodeForCountry(
    BuildContext context,
    CountryModel country,
  ) {
    final countryName = (country.name ?? '').toLowerCase().trim();
    if (countryName.isEmpty || countryName == 'all') {
      return getDefaultLanguageCode(context);
    }

    // 1. If country has associated languages
    if (country.languages.isNotEmpty) {
      for (final l in country.languages) {
        if (l.code != null && l.code!.trim().isNotEmpty) {
          return l.code!.trim();
        }
      }
    }

    // 2. Common country-to-language mappings
    final countryLangMap = <String, String>{
      'india': 'hi',
      'bharat': 'hi',
      'united states': 'en',
      'united states of america': 'en',
      'usa': 'en',
      'united kingdom': 'en',
      'uk': 'en',
      'australia': 'en',
      'canada': 'en',
      'spain': 'es',
      'mexico': 'es',
      'france': 'fr',
      'germany': 'de',
      'saudi arabia': 'ar',
      'united arab emirates': 'ar',
      'uae': 'ar',
      'egypt': 'ar',
      'qatar': 'ar',
      'kuwait': 'ar',
      'oman': 'ar',
      'bahrain': 'ar',
      'russia': 'ru',
      'china': 'zh',
      'japan': 'ja',
      'portugal': 'pt',
      'brazil': 'pt',
      'italy': 'it',
      'turkey': 'tr',
      'turkiye': 'tr',
      'indonesia': 'id',
      'bangladesh': 'bn',
      'pakistan': 'ur',
    };

    if (countryLangMap.containsKey(countryName)) {
      return countryLangMap[countryName];
    }
    for (final entry in countryLangMap.entries) {
      if (countryName.contains(entry.key) || entry.key.contains(countryName)) {
        return entry.value;
      }
    }

    // 3. Match against available system languages
    final list =
        context.read<FetchSystemSettingsCubit>().getSetting(
              SystemSetting.languageType,
            )
            as List? ??
        AppSettings.languages.map((e) => e.toMap()).toList();

    for (final item in list) {
      if (item is Map) {
        final langName = (item['name']?.toString() ?? '').toLowerCase();
        final langCode = (item['code']?.toString() ?? '').toLowerCase();
        if (countryName.contains(langName) ||
            langName.contains(countryName) ||
            countryName.contains(langCode)) {
          return item['code']?.toString();
        }
      }
    }

    return null;
  }

  /// Returns true when the language actually changed and app data was
  /// refreshed as part of it, so callers don't refresh a second time.
  static Future<bool> changeLanguage(
    BuildContext context, {
    required String languageCode,
  }) async {
    try {
      final langState = context.read<LanguageCubit>().state;
      if (langState is LanguageLoader &&
          langState.languageCode == languageCode) {
        return false;
      }

      final fetchLangCubit = context.read<FetchLanguageCubit>();
      await fetchLangCubit.getLanguage(languageCode);
      final state = fetchLangCubit.state;
      if (state is FetchLanguageSuccess) {
        final map = state.toMap();
        final data = map['file_name'];
        map['data'] = data;
        map.remove('file_name');
        await HiveUtils.storeLanguage(map);
        if (context.mounted) {
          context.read<LanguageCubit>().emitLanguageLoader(
            code: state.code,
            isRtl: state.isRTL,
          );
          await context.read<UpdateLanguageCubit>().updateLanguage(
            languageCode: state.code,
          );
          if (context.mounted) {
            refreshAppData(context);
            return true;
          }
        }
      }
    } on Exception catch (_) {}
    return false;
  }

  static Future<bool> updateLanguageForCountry(
    BuildContext context,
    CountryModel country,
  ) async {
    final langCode = getLanguageCodeForCountry(context, country);
    if (langCode != null && langCode.isNotEmpty) {
      return changeLanguage(context, languageCode: langCode);
    }
    return false;
  }

  /// Persists [country] as the selected country, pulls the matching language
  /// and refreshes the app data once.
  ///
  /// Everything a country switch implies lives here so a selection never fans
  /// out into several parallel refreshes (which the API rejects with
  /// "too many attempts").
  static Future<void> applyCountrySelection(
    BuildContext context,
    CountryModel country,
  ) async {
    if (isApplyingCountryChange) return;
    isApplyingCountryChange = true;
    try {
      final isAll = (country.name ?? '').toLowerCase() == 'all';
      final countryId = isAll ? '' : (country.id?.toString() ?? '');
      // Prices are shown in the currency of the selected country; on "all
      // countries" the currency from the app settings takes over again.
      await HiveUtils.setSelectedCountry(
        name: isAll ? 'all' : (country.name ?? ''),
        id: countryId,
        currencyCode: isAll ? '' : (country.currencyCode ?? ''),
        currencySymbol: isAll ? '' : (country.currencySymbol ?? ''),
      );

      if (!context.mounted) return;
      final refreshed = await updateLanguageForCountry(context, country);
      if (!refreshed && context.mounted) {
        refreshAppData(context);
      }
    } finally {
      isApplyingCountryChange = false;
    }
  }
}
