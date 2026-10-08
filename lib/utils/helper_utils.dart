import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_picker/country_picker.dart';
import 'package:ebroker/data/cubits/property/fetch_city_property_list.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/ad_banner_model.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/data/repositories/project_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/proprties/property_details/property_sheet_controller.dart';
import 'package:ebroker/utils/locale_list.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

enum MessageType {
  success(successMessageColor),
  warning(warningMessageColor),
  error(errorMessageColor);

  const MessageType(this.value);

  final Color value;
}

/// Property type filter used by [HelperUtils.loadMyProperties].
enum MyPropertyListingType {
  none(''),
  all('all'),
  sell('sell'),
  rent('rent'),
  sold('sold'),
  rented('rented');

  const MyPropertyListingType(this.value);

  final String value;

  static MyPropertyListingType fromValue(String value) {
    return values.firstWhere(
      (element) => element.value == value,
      orElse: () => MyPropertyListingType.none,
    );
  }
}

/// Request/active status filter used by [HelperUtils.loadMyProperties]
/// for both its `requestStatus` and `status` parameters.
enum MyPropertyRequestStatus {
  none(''),
  all('all'),
  approved('approved'),
  active('1'),
  rejected('rejected'),
  pending('pending'),
  expired('expired'),
  draft('draft');

  const MyPropertyRequestStatus(this.value);

  final String value;

  static MyPropertyRequestStatus fromValue(String value) {
    return values.firstWhere(
      (element) => element.value == value,
      orElse: () => MyPropertyRequestStatus.none,
    );
  }
}

/// Safely parses dynamic values (bool, int, String, null) into a boolean.
bool parseBool(dynamic val, {bool defaultValue = false}) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) {
    return val == '1' || val.toLowerCase() == 'true';
  }
  return defaultValue;
}

class HelperUtils {
  static bool parseBool(dynamic val, {bool defaultValue = false}) =>
      parseBool(val, defaultValue: defaultValue);

  static final Set<String> _pendingDetailNavigations = <String>{};
  static final Set<String> _pendingPackageChecks = <String>{};

  static String formatFollowerCount(int count) {
    if (count >= 1000) {
      final val = count / 1000;
      final formatted = val % 1 == 0
          ? val.toInt().toString()
          : val.toStringAsFixed(1);
      return '${formatted}k';
    }
    return count.toString();
  }

  static Future<bool> checkInternet() async {
    var check = false;
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      check = true;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      check = true;
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      check = true;
    }
    return check;
  }

  static CustomText requiredSymbol(BuildContext context) {
    return CustomText(
      '*',
      color: context.color.error,
      fontWeight: .w400,
    );
  }

  static String checkHost(String url) {
    // A host without a scheme produces a relative URI that Dio cannot open,
    // which surfaces as a bogus "no internet" error, so default to https.
    final withScheme = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';

    if (withScheme.endsWith('/')) {
      return withScheme;
    } else {
      return '$withScheme/';
    }
  }

  static Future<String?> getDownloadPath({
    dynamic Function(dynamic err)? onError,
  }) async {
    Directory? directory;
    try {
      directory = await getApplicationDocumentsDirectory();
    } on Exception catch (err) {
      onError?.call(err);
    }
    return directory?.path;
  }

  static Future<void> onTapBanner(
    BuildContext context,
    AdBanner? banner,
  ) async {
    if (banner == null) return;
    if (banner.type == 'external_link') {
      await url_launcher.launchUrl(Uri.parse(banner.externalLinkUrl ?? ''));
    } else if (banner.type == 'banner_only') {
      await UiUtils.showFullScreenImage(
        context,
        provider: NetworkImage(banner.image ?? ''),
      );
    } else if (banner.type == 'property') {
      try {
        await loadAndNavigateToPropertyDetails(
          context: context,
          propertyId: banner.propertyId ?? 0,
          isMyProperty:
              banner.property?.addedBy.toString() == HiveUtils.getUserId(),
          showLoader: true,
        );
      } on Exception catch (_) {}
    }
  }

  static Future<PropertyModel> fetchPropertyDetails({
    required int propertyId,
    required bool isMyProperty,
  }) {
    return PropertyRepository().fetchPropertyFromPropertyId(
      id: propertyId,
      isMyProperty: isMyProperty,
    );
  }

  static Future<PropertyModel?> loadPropertyDetails({
    required int propertyId,
    required bool isMyProperty,
    BuildContext? context,
    bool showLoader = false,
  }) async {
    if (isMyProperty) {
      await context?.read<CreatePropertyCubit>().clear();
    }
    final loaderContext = _resolvePropertyNavigationContext(context);
    final navigationKey = 'property-$propertyId-$isMyProperty';
    if (!_pendingDetailNavigations.add(navigationKey)) return null;

    try {
      if (showLoader && loaderContext != null) {
        unawaited(Widgets.showLoader(loaderContext));
      }

      final property = await fetchPropertyDetails(
        propertyId: propertyId,
        isMyProperty: isMyProperty,
      );

      if (showLoader) {
        Widgets.hideLoder(loaderContext);
      }

      return property;
    } on Exception catch (e) {
      if (showLoader) {
        Widgets.hideLoder(loaderContext);
      }
      final didSwitchRole = await _showRequiredRoleDialog(
        context: context,
        error: e,
      );
      if (didSwitchRole) {
        try {
          if (showLoader && loaderContext != null) {
            unawaited(Widgets.showLoader(loaderContext));
          }
          final property = await fetchPropertyDetails(
            propertyId: propertyId,
            isMyProperty: isMyProperty,
          );
          if (showLoader) {
            Widgets.hideLoder(loaderContext);
          }
          return property;
        } on Exception catch (retryError) {
          if (showLoader) {
            Widgets.hideLoder(loaderContext);
          }
          showSnackBarMessage(context, retryError.toString(), type: .error);
          return null;
        }
      }
      if (_isRequiredRoleError(e)) {
        return null;
      }
      showSnackBarMessage(context, e.toString(), type: .error);
      return null;
    } finally {
      _pendingDetailNavigations.remove(navigationKey);
    }
  }

  static Future<void> loadAndNavigateToPropertyDetails({
    required int propertyId,
    required bool isMyProperty,
    BuildContext? context,
    bool fromMyProperty = false,
    bool fromSuccess = false,
    bool fromCompleteEnquiry = false,
    bool isReplace = false,
    bool popCurrentIfAlreadyOpen = false,
    bool showLoader = false,
    String? heroTag,
  }) async {
    final property = await loadPropertyDetails(
      propertyId: propertyId,
      isMyProperty: isMyProperty || fromMyProperty,
      context: context,
      showLoader: showLoader,
    );
    if (property != null) {
      await navigateToPropertyDetails(
        context: context,
        property: property,
        fromMyProperty: fromMyProperty,
        fromSuccess: fromSuccess,
        fromCompleteEnquiry: fromCompleteEnquiry,
        isReplace: isReplace,
        popCurrentIfAlreadyOpen: popCurrentIfAlreadyOpen,
        heroTag: heroTag,
      );
    }
  }

  static Future<void> navigateToPropertyDetails({
    required PropertyModel property,
    BuildContext? context,
    bool fromMyProperty = false,
    bool fromSuccess = false,
    bool fromCompleteEnquiry = false,
    bool isReplace = false,
    bool popCurrentIfAlreadyOpen = false,
    String? heroTag,
  }) async {
    final navigationContext = _resolvePropertyNavigationContext(context);
    if (navigationContext == null) return;

    final navigator = Navigator.of(navigationContext);
    final currentRoute = ModalRoute.of(navigationContext)?.settings.name;

    if (popCurrentIfAlreadyOpen &&
        currentRoute == Routes.propertyDetails &&
        navigator.canPop()) {
      navigator.pop();
    }

    final isPremium = property.isPremium ?? false;
    final isAddedByMe =
        fromMyProperty || property.addedBy.toString() == HiveUtils.getUserId();

    if (isPremium && !isAddedByMe) {
      await GuestChecker.check(
        onNotGuest: () async {
          final navigationKey = 'property-${property.id}';
          if (!_pendingPackageChecks.add(navigationKey)) return;
          final packageAvailable = await CheckPackageCubit().checkAvailability(
            packageType: PackageType.premiumProperties,
          );
          _pendingPackageChecks.remove(navigationKey);

          if (packageAvailable) {
            if (navigator.canPop() || PropertySheetController.isShowing) {
              if (isReplace) {
                await navigator.pushReplacementNamed(
                  Routes.propertyDetails,
                  arguments: {
                    'propertyData': property,
                    'fromMyProperty': fromMyProperty,
                    'fromSuccess': fromSuccess,
                    'fromCompleteEnquiry': fromCompleteEnquiry,
                    'heroTag': heroTag,
                  },
                );
              } else {
                await navigator.pushNamed(
                  Routes.propertyDetails,
                  arguments: {
                    'propertyData': property,
                    'fromMyProperty': fromMyProperty,
                    'fromSuccess': fromSuccess,
                    'fromCompleteEnquiry': fromCompleteEnquiry,
                    'heroTag': heroTag,
                  },
                );
              }
            } else {
              PropertySheetController.showProperty(
                property: property,
                fromMyProperty: fromMyProperty,
                fromCompleteEnquiry: fromCompleteEnquiry,
                fromSuccess: fromSuccess,
                heroTag: heroTag,
              );
            }
          } else {
            await UiUtils.showBlurredDialoge(
              navigationContext,
              dialog: const BlurredSubscriptionDialogBox(
                packageType: SubscriptionPackageType.premiumProperties,
                isAcceptContainesPush: true,
              ),
            );
          }
        },
      );
    } else {
      if (navigator.canPop() || PropertySheetController.isShowing) {
        if (isReplace) {
          await navigator.pushReplacementNamed(
            Routes.propertyDetails,
            arguments: {
              'propertyData': property,
              'fromMyProperty': fromMyProperty,
              'fromSuccess': fromSuccess,
              'fromCompleteEnquiry': fromCompleteEnquiry,
              'heroTag': heroTag,
            },
          );
        } else {
          await navigator.pushNamed(
            Routes.propertyDetails,
            arguments: {
              'propertyData': property,
              'fromMyProperty': fromMyProperty,
              'fromSuccess': fromSuccess,
              'fromCompleteEnquiry': fromCompleteEnquiry,
              'heroTag': heroTag,
            },
          );
        }
      } else {
        PropertySheetController.showProperty(
          property: property,
          fromMyProperty: fromMyProperty,
          fromCompleteEnquiry: fromCompleteEnquiry,
          fromSuccess: fromSuccess,
          heroTag: heroTag,
        );
      }
    }
  }

  static Widget buildBackButton(
    BuildContext context,
    VoidCallback? onTapBackButton,
    //
    // ignore: avoid_positional_boolean_parameters
    bool preventDefaultPop,
  ) {
    return GestureDetector(
      onTap: () {
        onTapBackButton?.call();
        if (!preventDefaultPop) {
          Navigator.pop(context);
        }
      },
      child: Container(
        alignment: Alignment.center,
        child: CustomImage(
          imageUrl: AppIcons.arrowLeft,
          width: 24.rh(context),
          height: 24.rh(context),
          matchTextDirection: true,
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  static Future<ProjectModel> fetchProjectDetails({
    required int projectId,
    required bool isMyProject,
    BuildContext? context,
  }) async {
    final requestContext = _resolvePropertyNavigationContext(context);
    if (requestContext == null) {
      throw StateError('No navigation context available for project details');
    }

    final projectDetails = await ProjectRepository().getProjectDetails(
      requestContext,
      id: projectId,
      isMyProject: isMyProject,
    );
    return projectDetails;
  }

  static Future<ProjectModel?> loadProjectDetails({
    required int projectId,
    required bool isMyProject,
    BuildContext? context,
    bool showLoader = false,
  }) async {
    final navigationKey = 'project-$projectId';
    if (!_pendingDetailNavigations.add(navigationKey)) return null;

    BuildContext? loaderContext;
    if (showLoader && context != null) {
      loaderContext = _resolvePropertyNavigationContext(context);
      if (loaderContext != null && loaderContext.mounted) {
        unawaited(Widgets.showLoader(loaderContext));
      }
    }

    try {
      final project = await fetchProjectDetails(
        projectId: projectId,
        isMyProject: isMyProject,
        context: context,
      );

      if (loaderContext != null && loaderContext.mounted) {
        Widgets.hideLoder(loaderContext);
      }
      return project;
    } on Exception catch (e) {
      if (loaderContext != null && loaderContext.mounted) {
        Widgets.hideLoder(loaderContext);
      }

      if (e.toString().contains('429')) {
        if (context != null && context.mounted) {
          showSnackBarMessage(
            context,
            'tooManyRequestsPleaseWait',
            type: .error,
          );
        }
      } else {
        if (context != null && context.mounted) {
          showSnackBarMessage(
            context,
            e.toString(),
            type: .error,
          );
        }
      }
      return null;
    } finally {
      _pendingDetailNavigations.remove(navigationKey);
    }
  }

  static Future<void> loadAndNavigateToProjectDetails({
    required int projectId,
    required bool isMyProject,
    BuildContext? context,
    bool isReplace = false,
    bool popCurrentIfAlreadyOpen = false,
    bool showLoader = false,
  }) async {
    final project = await loadProjectDetails(
      projectId: projectId,
      isMyProject: isMyProject,
      context: context,
      showLoader: showLoader,
    );
    if (project != null) {
      await navigateToProjectDetails(
        context: context,
        project: project,
        isReplace: isReplace,
        popCurrentIfAlreadyOpen: popCurrentIfAlreadyOpen,
      );
    }
  }

  static Future<void> navigateToProjectDetails({
    required ProjectModel project,
    BuildContext? context,
    bool isReplace = false,
    bool popCurrentIfAlreadyOpen = false,
  }) async {
    final navigationContext = _resolvePropertyNavigationContext(context);
    if (navigationContext == null) return;

    final navigator = Navigator.of(navigationContext);
    final currentRoute = ModalRoute.of(navigationContext)?.settings.name;

    if (popCurrentIfAlreadyOpen &&
        currentRoute == Routes.projectDetailsScreen &&
        navigator.canPop()) {
      navigator.pop();
    }

    final isPremium = project.isPremium ?? false;
    final isMyProject = project.addedBy.toString() == HiveUtils.getUserId();

    if (isPremium && !isMyProject) {
      await GuestChecker.check(
        onNotGuest: () async {
          final navigationKey = 'project-${project.id}';
          if (!_pendingPackageChecks.add(navigationKey)) return;
          final packageAvailable = await CheckPackageCubit().checkAvailability(
            packageType: PackageType.premiumProjects,
          );
          _pendingPackageChecks.remove(navigationKey);

          if (packageAvailable) {
            if (navigator.canPop() || PropertySheetController.isShowing) {
              if (isReplace) {
                await navigator.pushReplacementNamed(
                  Routes.projectDetailsScreen,
                  arguments: {
                    'project': project,
                  },
                );
              } else {
                await navigator.pushNamed(
                  Routes.projectDetailsScreen,
                  arguments: {
                    'project': project,
                  },
                );
              }
            } else {
              PropertySheetController.showProject(
                project: project,
              );
            }
          } else {
            await UiUtils.showBlurredDialoge(
              navigationContext,
              dialog: const BlurredSubscriptionDialogBox(
                packageType: SubscriptionPackageType.premiumProjects,
                isAcceptContainesPush: true,
              ),
            );
          }
        },
      );
    } else {
      if (navigator.canPop() || PropertySheetController.isShowing) {
        if (isReplace) {
          await navigator.pushReplacementNamed(
            Routes.projectDetailsScreen,
            arguments: {
              'project': project,
            },
          );
        } else {
          await navigator.pushNamed(
            Routes.projectDetailsScreen,
            arguments: {
              'project': project,
            },
          );
        }
      } else {
        PropertySheetController.showProject(
          project: project,
        );
      }
    }
  }

  static Future<void> navigateToAgentDetails({
    required BuildContext? context,
    required String agentId,
    required bool isAdmin,
    bool popCurrentIfAlreadyOpen = false,
  }) async {
    final navigationContext = _resolvePropertyNavigationContext(context);
    if (navigationContext == null) return;

    final navigator = Navigator.of(navigationContext);
    final currentRoute = ModalRoute.of(navigationContext)?.settings.name;

    if (popCurrentIfAlreadyOpen &&
        currentRoute == Routes.agentDetailsScreen &&
        navigator.canPop()) {
      navigator.pop();
    }

    await goToNextPage(
      Routes.agentDetailsScreen,
      navigationContext,
      false,
      args: {
        'agentID': agentId,
        'isAdmin': isAdmin,
      },
    );
  }

  static Future<void> navigateToArticleDetails({
    required BuildContext? context,
    String? articleId,
    String? slug,
    bool popCurrentIfAlreadyOpen = false,
  }) async {
    final navigationContext = _resolvePropertyNavigationContext(context);
    if (navigationContext == null) return;

    final navigator = Navigator.of(navigationContext);
    final currentRoute = ModalRoute.of(navigationContext)?.settings.name;

    if (popCurrentIfAlreadyOpen &&
        currentRoute == Routes.articleDetailsScreenRoute &&
        navigator.canPop()) {
      navigator.pop();
    }

    await goToNextPage(
      Routes.articleDetailsScreenRoute,
      navigationContext,
      false,
      args: {
        'id': articleId,
        'slug': slug,
      },
    );
  }

  static Future<void> navigateToCityProperties({
    required BuildContext? context,
    required String cityName,
    bool popCurrentIfAlreadyOpen = false,
  }) async {
    final navigationContext = _resolvePropertyNavigationContext(context);
    if (navigationContext == null) return;

    final navigator = Navigator.of(navigationContext);
    final currentRoute = ModalRoute.of(navigationContext)?.settings.name;

    if (popCurrentIfAlreadyOpen &&
        currentRoute == Routes.cityPropertiesScreen &&
        navigator.canPop()) {
      navigator.pop();
    }

    unawaited(
      navigationContext.read<FetchCityPropertyList>().fetch(
        cityName: cityName,
        forceRefresh: true,
      ),
    );

    await goToNextPage(
      Routes.cityPropertiesScreen,
      navigationContext,
      false,
      args: {
        'cityName': cityName,
      },
    );
  }

  static BuildContext? _resolvePropertyNavigationContext(
    BuildContext? context,
  ) {
    if (context != null && context.mounted) {
      return context;
    }

    final navigatorContext = Constant.navigatorKey.currentContext;
    if (navigatorContext != null && navigatorContext.mounted) {
      return navigatorContext;
    }

    final navigatorState = Constant.navigatorKey.currentState;
    if (navigatorState != null && navigatorState.mounted) {
      return navigatorState.context;
    }

    return null;
  }

  static Future<void> loadMyProperties(
    BuildContext context, {
    MyPropertyListingType type = MyPropertyListingType.none,
    MyPropertyRequestStatus requestStatus = MyPropertyRequestStatus.none,
    MyPropertyRequestStatus status = MyPropertyRequestStatus.none,
  }) async {
    await context.read<FetchMyPropertiesCubit>().fetchMyProperties(
      type: type.value,
      requestStatus: requestStatus.value,
      status: status.value,
    );
  }

  static Future<bool> _showRequiredRoleDialog({
    required BuildContext? context,
    required Object error,
  }) async {
    if (error is! ApiException) return false;

    final requiredRole = _requiredRoleFromErrorKey(error.errorKey);
    if (requiredRole == null) return false;

    final dialogContext = _resolvePropertyNavigationContext(context);
    if (dialogContext == null) return false;

    final didSwitchRole = await UiUtils.showBlurredDialoge(
      dialogContext,
      dialog: BlurredRoleRequiredDialogBox(requiredRole: requiredRole),
    );

    return didSwitchRole == true;
  }

  static bool _isRequiredRoleError(Object error) {
    if (error is! ApiException) return false;
    return _requiredRoleFromErrorKey(error.errorKey) != null;
  }

  static String? _requiredRoleFromErrorKey(String? errorKey) {
    if (errorKey == null) return null;

    final normalizedKey = errorKey.toLowerCase();
    if (normalizedKey == 'requiredagentrole') return ActiveRole.agent.value;
    if (normalizedKey == 'requireduserrole') return ActiveRole.user.value;

    return null;
  }

  static int comparableVersion(String version) {
    //removing dot from version and parsing it into int
    final plain = version.replaceAll('.', '');

    return int.parse(plain);
  }

  static String nativeDeepLinkUrlOfProperty(String slug) {
    return 'https://${AppConfig.shareNavigationWebUrl}/property-details/$slug?share=true&lang=${HiveUtils.getLanguageCode()}';
  }

  static String nativeDeepLinkUrlOfProject(String slug) {
    return 'https://${AppConfig.shareNavigationWebUrl}/project-details/$slug?share=true&lang=${HiveUtils.getLanguageCode()}';
  }

  static String nativeDeepLinkUrlOfAgent(String slug, {bool isAdmin = false}) {
    return 'https://${AppConfig.shareNavigationWebUrl}/agent-details/$slug?share=true${isAdmin ? '&is_admin=$isAdmin' : ''}&lang=${HiveUtils.getLanguageCode()}';
  }

  static String nativeDeepLinkUrlOfArticle(String slug) {
    return 'https://${AppConfig.shareNavigationWebUrl}/article-details/$slug?share=true&lang=${HiveUtils.getLanguageCode()}';
  }

  static Future<void> share(BuildContext context, String slugId) =>
      _shareEntity(context, slugId, _ShareKind.property);

  static Future<void> shareProject(BuildContext context, String slugId) =>
      _shareEntity(context, slugId, _ShareKind.project);

  static Future<void> shareAgent(
    BuildContext context,
    String slugId, {
    bool isAdmin = false,
  }) => _shareEntity(context, slugId, _ShareKind.agent, isAdmin: isAdmin);

  static Future<void> shareArticle(BuildContext context, String slugId) =>
      _shareEntity(context, slugId, _ShareKind.article);

  static Future<void> _shareEntity(
    BuildContext context,
    String slugId,
    _ShareKind kind, {
    bool isAdmin = false,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
    final deepLink = AppConfig.deepLinkingType == DeepLinkType.native
        ? kind.deepLinkUrl(slugId, isAdmin: isAdmin)
        : '';

    await CustomBottomSheet.show<void>(
      context: context,
      showDragHandle: false,
      borderRadius: 8,
      backgroundColor: context.color.backgroundColor,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: .min,
        children: [
          ListTile(
            leading: Icon(Icons.copy, color: context.color.textColorDark),
            title: CustomText('copylink'.translate(context)),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: deepLink));

              Future.delayed(Duration.zero, () {
                Navigator.pop(context);
                HelperUtils.showSnackBarMessage(
                  context,
                  'copied',
                  type: .success,
                );
              });
            },
          ),
          ListTile(
            leading: CustomImage(
              imageUrl: AppIcons.shareIcon,
              height: 24.rh(context),
              width: 24.rw(context),
              fit: .contain,
              color: context.color.textColorDark,
            ),
            title: CustomText('share'.translate(context)),
            onTap: () async {
              final text =
                  '${kind.descriptionKey.translate(context)}\n$deepLink';
              await SharePlus.instance.share(
                ShareParams(
                  text: text,
                  subject: kind.subjectKey.translate(context),
                  sharePositionOrigin: sharePositionOrigin,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static String formatPhoneNumber(String number, String phoneCode) {
    // Remove any existing formatting
    final cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    final phoneCodeWithPlus = '+$phoneCode';

    if (cleanNumber.isEmpty) return number;

    switch (phoneCodeWithPlus) {
      case '+91': // India: XXXXX XXXXX
        if (cleanNumber.length != 10) return number;
        return '${cleanNumber.substring(0, 5)} ${cleanNumber.substring(5)}';

      case '+1': // USA/Canada: (XXX) XXX-XXXX
        if (cleanNumber.length != 10) return number;
        return '(${cleanNumber.substring(0, 3)}) ${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6)}';

      case '+44': // UK: XXXX XXX XXX
        if (cleanNumber.length != 10) return number;
        return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4, 7)} ${cleanNumber.substring(7)}';

      case '+61': // Australia: XXX XXX XXX
        if (cleanNumber.length != 9) return number;
        return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6)}';

      case '+33': // France: X XX XX XX XX
        if (cleanNumber.length != 9) return number;
        return '${cleanNumber.substring(0, 1)} ${cleanNumber.substring(1, 3)} ${cleanNumber.substring(3, 5)} ${cleanNumber.substring(5, 7)} ${cleanNumber.substring(7)}';

      case '+49': // Germany: XXX XXXXXXX
        if (cleanNumber.length < 10 || cleanNumber.length > 11) return number;
        return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3)}';

      case '+55': // Brazil: (XX) XXXXX-XXXX
        if (cleanNumber.length != 11) return number;
        return '(${cleanNumber.substring(0, 2)}) ${cleanNumber.substring(2, 7)}-${cleanNumber.substring(7)}';

      case '+81': // Japan: XX-XXXX-XXXX
        if (cleanNumber.length != 10) return number;
        return '${cleanNumber.substring(0, 2)}-${cleanNumber.substring(2, 6)}-${cleanNumber.substring(6)}';

      case '+86': // China: XXX XXXX XXXX
        if (cleanNumber.length != 11) return number;
        return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 7)} ${cleanNumber.substring(7)}';

      case '+971': // UAE: XX XXX XXXX
        if (cleanNumber.length != 9) return number;
        return '${cleanNumber.substring(0, 2)} ${cleanNumber.substring(2, 5)} ${cleanNumber.substring(5)}';

      case '+966': // Saudi Arabia: XX XXX XXXX
        if (cleanNumber.length != 9) return number;
        return '${cleanNumber.substring(0, 2)} ${cleanNumber.substring(2, 5)} ${cleanNumber.substring(5)}';

      default:
        // Generic formatting for unsupported codes
        if (cleanNumber.length <= 4) return cleanNumber;
        if (cleanNumber.length <= 7) {
          return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3)}';
        }
        return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6)}';
    }
  }

  static int getMaxPhoneLength(String phoneCode) {
    final phoneCodeWithPlus = '+$phoneCode';
    switch (phoneCodeWithPlus) {
      case '+1': // USA/Canada
      case '+44': // UK
      case '+91': // India
        return 10;
      case '+81': // Japan
        return 10;
      case '+86': // China
      case '+55': // Brazil
        return 11;

      case '+61': // Australia
      case '+33': // France
      case '+971': // UAE
      case '+966': // Saudi Arabia
        return 9;

      case '+49': // Germany (can be 10 or 11)
        return 11;

      case '+7': // Russia
        return 10;

      case '+52': // Mexico
        return 10;

      case '+34': // Spain
        return 9;

      case '+39': // Italy
        return 10;

      case '+82': // South Korea
        return 10;

      case '+65': // Singapore
        return 8;

      case '+60': // Malaysia
        return 10;

      case '+62': // Indonesia
        return 11;

      case '+63': // Philippines
        return 10;

      case '+66': // Thailand
        return 9;

      case '+84': // Vietnam
        return 10;

      case '+880': // Bangladesh
        return 10;

      case '+92': // Pakistan
        return 10;

      case '+94': // Sri Lanka
        return 9;

      case '+977': // Nepal
        return 10;

      case '+27': // South Africa
        return 9;

      case '+234': // Nigeria
        return 10;

      case '+254': // Kenya
        return 9;

      default:
        return 15; // Max international phone number length
    }
  }

  static void showSnackBarMessage(
    BuildContext? context,
    String message, {
    required MessageType type,
    int messageDuration = 3,
    EdgeInsets? margin,
    TextAlign? textAlign,
  }) {
    if (context == null || !context.mounted) return;
    _SlideSnackBar.show(
      context: context,
      message: message.translate(context),
      duration: Duration(seconds: messageDuration),
      backgroundColor: type.value,
      textColor: Colors.white,
      textAlign: textAlign,
      margin:
          margin ??
          EdgeInsets.fromLTRB(
            24.rw(context),
            24.rh(context),
            24.rw(context),
            48.rh(context),
          ),
    );
  }

  static String getFileSizeString({required int bytes, int decimals = 0}) {
    const suffixes = ['b', 'kb', 'mb', 'gb', 'tb'];
    if (bytes == 0) return '0${suffixes[0]}';
    final i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + suffixes[i];
  }

  static Future<void> killPreviousPages(
    BuildContext context,
    String nextPage,
    Object args,
  ) async {
    await Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(nextPage, (route) => false, arguments: args);
  }

  static String getPackageDuration({required int duration}) {
    final days = duration ~/ 24;
    return '$days';
  }

  static Future<void> goToNextPage(
    String nextPage,
    BuildContext bContext,
    dynamic isReplace, {
    Object? args,
  }) async {
    if (isReplace as bool) {
      await Navigator.of(
        bContext,
      ).pushReplacementNamed(nextPage, arguments: args);
    } else {
      await Navigator.of(bContext).pushNamed(nextPage, arguments: args);
    }
  }

  static CountryService countryCodeService = CountryService();

  /// it will return user's locale-based country code
  static Future<Country> getSimCountry() async {
    final countryList = countryCodeService.getAll();

    var simCountry = countryList.firstWhere(
      (element) {
        return element.phoneCode == HiveUtils.getCountryCode();
      },
      orElse: () {
        return countryList
            .where(
              (element) => element.phoneCode == AppConfig.defaultCountryCode,
            )
            .first;
      },
    );

    if (AppSettings.isDemoModeOn) {
      simCountry = countryList
          .where((element) => element.phoneCode == Constant.demoCountryCode)
          .first;
    }

    return simCountry;
  }

  static bool isYoutubeVideo(String url) {
    final youtubeDomains = ['youtu.be', 'youtube.com'];

    final uri = Uri.parse(url);
    final host = uri.host.replaceAll('www.', '');
    if (youtubeDomains.contains(host)) {
      return true;
    } else {
      return false;
    }
  }

  static String? getYoutubeVideoId(String url) {
    final u = url.trim();
    if (!u.contains('http') && (u.length == 11)) return u;

    for (final exp in [
      RegExp(
        r'^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$',
      ),
      RegExp(
        r'^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$',
      ),
      RegExp(r'^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$'),
    ]) {
      final match = exp.firstMatch(u);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }
    return null;
  }

  static String getYoutubeThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  static bool isValidLocale(String locale) {
    return localeList.contains(locale);
  }

  static bool isVimeoVideo(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.replaceAll('www.', '');
    return host.contains('vimeo.com');
  }

  static String? getVimeoVideoId(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    for (final segment in uri.pathSegments) {
      if (RegExp(r'^\d+$').hasMatch(segment)) {
        return segment;
      }
    }
    return null;
  }

  static Future<File?> compressImageFile(File file) async {
    try {
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        "${file.path}_compressed.${file.path.split('.').last}",
        quality: AppConfig.uploadImageQuality,
      );
      return File(compressedFile?.path ?? '');
    } on Exception catch (_) {
      return null; //If any error occurs during compression, the process is stopped.
    }
  }

  static void runAfterTransition(BuildContext context, VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        if (route.animation!.isCompleted) {
          callback();
        } else {
          late final VoidCallback listener;
          listener = () {
            if (route.animation!.status == AnimationStatus.completed) {
              route.animation!.removeListener(listener);
              callback();
            }
          };
          route.animation!.addListener(listener);
        }
      } else {
        callback();
      }
    });
  }
}

enum _ShareKind {
  property('sharePropertyDescription', 'shareProperty'),
  project('shareProjectDescription', 'shareProject'),
  agent('shareAgentDescription', 'shareAgent'),
  article('shareArticleDescription', 'shareArticle');

  const _ShareKind(this.descriptionKey, this.subjectKey);

  final String descriptionKey;
  final String subjectKey;

  String deepLinkUrl(String slug, {bool isAdmin = false}) {
    switch (this) {
      case _ShareKind.property:
        return HelperUtils.nativeDeepLinkUrlOfProperty(slug);
      case _ShareKind.project:
        return HelperUtils.nativeDeepLinkUrlOfProject(slug);
      case _ShareKind.agent:
        return HelperUtils.nativeDeepLinkUrlOfAgent(slug, isAdmin: isAdmin);
      case _ShareKind.article:
        return HelperUtils.nativeDeepLinkUrlOfArticle(slug);
    }
  }
}

///Post Frame Callback
void postFrame(void Function(Duration t) fn) {
  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    fn.call(timeStamp);
  });
}

class _SlideSnackBar extends StatefulWidget {
  const _SlideSnackBar({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.margin,
    required this.onDismissed,
    required this.textColor,
    this.textAlign,
  });

  final String message;
  final Color backgroundColor;
  final Duration duration;
  final EdgeInsets margin;
  final TextAlign? textAlign;
  final VoidCallback onDismissed;
  final Color textColor;
  static OverlayEntry? _current;

  static void show({
    required BuildContext context,
    required String message,
    required Duration duration,
    required Color backgroundColor,
    required EdgeInsets margin,
    required Color textColor,
    TextAlign? textAlign,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SlideSnackBar(
        message: message,
        backgroundColor: backgroundColor,
        duration: duration,
        margin: margin,
        textAlign: textAlign,
        textColor: textColor,
        onDismissed: () {
          if (entry.mounted) entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  @override
  State<_SlideSnackBar> createState() => _SlideSnackBarState();
}

class _SlideSnackBarState extends State<_SlideSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 1.5),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _hideTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    _hideTimer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.margin.left,
      right: widget.margin.right,
      bottom: widget.margin.bottom,
      child: SlideTransition(
        position: _offset,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.rw(context),
                vertical: 16.rh(context),
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: context.color.textColorDark.withValues(alpha: .3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      widget.message,
                      maxLines: 3,
                      textAlign: widget.textAlign,
                      color: widget.textColor,
                    ),
                  ),
                  SizedBox(width: 8.rw(context)),
                  GestureDetector(
                    onTap: _dismiss,
                    child: CustomImage(
                      imageUrl: AppIcons.closeCircle,
                      height: 20.rw(context),
                      color: widget.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
