import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:ebroker/app/routes.dart';
import 'package:ebroker/config/app_config.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/utils/active_role_manager.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/curl_logger.dart';
import 'package:ebroker/utils/error_filter.dart';
import 'package:ebroker/utils/extensions/lib/translate.dart';
import 'package:ebroker/utils/guest_checker.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/hive_keys.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:ebroker/utils/network/interseptors/network_request_interseptor.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

/// Optimized API client with better structure and performance
class Api {
  // Private constructor for singleton pattern
  Api._();
  static final Api _instance = Api._();
  static Api get instance => _instance;

  // Dio instance - initialized once
  static final Dio _dio = Dio();
  static void initCurlLoggerInterceptor() {
    _dio.interceptors.add(CurlLoggerInterceptor());
  }

  // Metrics
  static int apiRequestCount = 0;
  static int apiErrorCount = 0;
  static final List<String> currentlyCallingAPI = <String>[];

  // Flag to prevent multiple simultaneous logout redirects
  static bool _isHandlingUnauthorized = false;

  static Future<bool> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    return hasInternet;
  }

  // Initialize interceptors once
  static void initInterceptors() {
    if (_dio.interceptors.isEmpty) {
      _dio.interceptors.add(NetworkRequestInterseptor());
    }
  }

  /// Get headers with caching for better performance
  static Map<String, String> headers({
    required bool usAuthToken,
    String? countryId,
    bool passCountryId = true,
  }) {
    final currentLanguageCode = HiveUtils.getLanguageCode();
    final effectiveCountryId = (countryId != null && countryId.isNotEmpty)
        ? countryId
        : (AppSettings.currentCountryId.isNotEmpty
              ? AppSettings.currentCountryId
              : (HiveUtils.getSelectedCountryId() ?? ''));

    if (countryId == null &&
        effectiveCountryId.isNotEmpty &&
        AppSettings.currentCountryId.isEmpty) {
      AppSettings.currentCountryId = effectiveCountryId;
    }

    final shouldPassCountry = passCountryId && effectiveCountryId.isNotEmpty;

    if (GuestChecker.value) {
      return {
        'Content-Language': currentLanguageCode,
        'Accept': 'application/json',
        'X-Active-Role': ActiveRole.user.value,
        if (shouldPassCountry) 'X-Country-Id': effectiveCountryId,
      };
    }

    final currentToken =
        Hive.box<dynamic>(
          HiveKeys.userDetailsBox,
        ).get(HiveKeys.jwtToken)?.toString() ??
        '';

    final hasAuthToken = usAuthToken && currentToken.isNotEmpty;

    return {
      'Content-Language': currentLanguageCode,
      'Accept': 'application/json',
      'X-Active-Role': hasAuthToken
          ? ActiveRoleManager.currentRoleValue
          : ActiveRole.user.value,
      if (hasAuthToken) 'Authorization': 'Bearer $currentToken',
      if (shouldPassCountry) 'X-Country-Id': effectiveCountryId,
    };
  }

  // Base URLs - grouped for better organization
  static const String stripeIntentAPI =
      'https://api.stripe.com/v1/payment_intents';

  // Place API endpoints
  static String get getPlaceList => '${AppConfig.baseUrl}get-map-places-list';
  static String get getPlaceDetails =>
      '${AppConfig.baseUrl}get-map-place-details';
  static String get getOsmPlaceList =>
      '${AppConfig.baseUrl}get-osm-places-list';
  static String get getOsmPlaceDetails =>
      '${AppConfig.baseUrl}get-osm-place-details';

  // Project APIs
  static const String postProject = 'post_project';
  static const String getProjects = 'get-projects';
  static const String getAddedProjects = 'get-added-projects';
  static const String getProjectDetails = 'get-project-detail';
  static const String deleteProject = 'delete_project';
  static const String changeProjectStatus = 'change-project-status';
  static const String apiRenewListing = 'renew_listing';

  // Property APIs
  static const String apiGetPropertyDetails = 'get_property';
  static const String apiGetPropertyList = 'get-property-list';
  static const String getAddedProperties = 'get-added-properties';
  static const String apiPostProperty = 'post_property';
  static const String apiUpdateProperty = 'update_post_property';
  static const String changePropertyStatus = 'change-property-status';
  static const String apiDeleteProperty = 'delete_property';
  static const String getAllSimilarProperties = 'get-all-similar-properties';
  static const String compareProperties = 'compare-properties';
  static const String updatePropertyStatus = 'update_property_status';

  // User Management APIs
  static const String apiLogin = 'user_signup';
  static const String userRegister = 'user-register';
  static const String apiUpdateProfile = 'update_profile';
  static const String apiDeleteUser = 'delete_user';
  static const String apiBeforeLogout = 'before-logout';
  static const String apigetUserbyId = 'get_user_by_id';
  static const String apiGetUserData = 'get-user-data';

  // Authentication APIs
  static const String apiGetOtp = 'get-otp';
  static const String apiVerifyOtp = 'verify-otp';
  static const String checkNumberPasswordExists =
      'check-number-password-exists';
  static const String updateNumberPassword = 'update-number-password';
  static const String updateEmailPassword = 'update-email-password';

  // Content APIs
  static const String apiGetSlider = 'get-slider';
  static const String apiGetCategories = 'get_categories';
  static const String apiGetUnit = 'get_unit';
  static const String getAdvanceFilter = 'property-advance-filter-data';
  static const String getOutdoorFacilites = 'get_facilities';
  static const String apiGetHouseType = 'get_house_type';
  static const String getFeaturedData = 'get-featured-data';
  static const String getArticles = 'get_articles';
  static const String getCitiesData = 'get-cities-data';
  static const String apiGetFaqs = 'faqs';
  static const String getLanguages = 'get_languages';
  static const String updateLanguage = 'update-language';
  static const String getCountries = 'get-countries';
  static const String getCurrencies = 'get-currencies';
  static const String getStories = 'get-stories';
  static const String storyView = 'story-view';
  static const String uploadStory = 'upload-story';
  static const String deleteStory = 'delete-story';
  static const String myStories = 'my-stories';

  // Homepage (refactored) APIs
  static const String homepageSectionsData = 'homepage/sections-data';
  static const String homepagePropertySections = 'homepage/property-sections';
  static const String homepageProjectSections = 'homepage/project-sections';
  static const String homepageOtherSections = 'homepage/other-sections';
  static const String apiGetPropertiesByCity = 'homepage/properties-by-city';
  static const String homepagePropertiesOnMap = 'homepage/properties-on-map';
  static const String getPropertiesOnMap = 'get-properties-on-map';

  /// Deprecated: legacy single-endpoint homepage payload.
  /// Kept for backwards compatibility; should not be used going forward.
  static const String homePageData = 'homepage-data';

  // Notification & Inquiry APIs
  static const String apiGetNotificationList = 'get_notification_list';
  static const String apiGetNotifications = 'get_notification_list';
  static const String apiSetPropertyEnquiry = 'set_property_inquiry';
  static const String apiGetPropertyEnquiry = 'get_property_inquiry';
  static const String deleteInquiry = 'delete_inquiry';

  // Favorites & Interest APIs
  static const String addFavourite = 'add_favourite';
  static const String getFavoriteProperty = 'get_favourite_property';
  static const String interestedUsers = 'interested_users';
  static const String getInterestedUsers = 'get_interested_users';
  static const String addEditUserInterest = 'add_edit_user_interest';
  static const String getUserRecommendation = 'get_user_recommendation';

  // Payment APIs
  static const String getPaymentApiKeys = 'get_payment_settings';
  static const String getPaymentDetails = 'get_payment_details';
  static const String createPaymentIntent = 'create-payment-intent';
  static const String paymentTransactionFail = 'payment-transaction-fail';
  static const String paypal = 'paypal';
  static const String flutterwave = 'flutterwave';
  static const String uploadBankReceiptFile = 'upload-bank-receipt-file';
  static const String initiateBankTransfer = 'initiate-bank-transfer';
  static const String getPaymentReceipt = 'get-payment-receipt';

  // Package APIs
  static const String getPackage = 'get-package';
  static const String getAgentPackages = 'get-agent-packages';
  static const String userPurchasePackage = 'user_purchase_package';
  static const String apiCheckPackageLimit = 'check-package-limit';
  static const String assignPackage = 'assign_package';
  static const String activateListing = 'activate-listing';

  // Chat APIs
  static const String getChatList = 'get_chats';
  static const String sendMessage = 'send_message';
  static const String getMessages = 'get_messages';
  static const String deleteChatMessage = 'delete_chat_message';
  static const String blockUser = 'block-user';
  static const String unblockUser = 'unblock-user';

  // Agent Dashboard APIs
  static const String agentDashboardSummary = 'agent-dashboard/summery';
  static const String agentDashboardListings = 'agent-dashboard/listings';
  static const String agentDashboardMostViewedCategory =
      'agent-dashboard/most-viewed-category';
  static const String agentDashboardMostViewedListing =
      'agent-dashboard/most-viewed-listing';
  static const String agentDashboardActivePackages =
      'agent-dashboard/active-packages';
  static const String agentDashboardFollowers = 'agent-dashboard/followers';

  // Agent Profile APIs
  static const String apiGetAgentProfile = 'get-agent-profile';
  static const String apiUpdateAgentProfile = 'update-agent-profile';

  // Agent APIs
  static const String apiGetApplyAgentVerification = 'apply-agent-verification';
  static const String getUserVerificationFormFields =
      'get-agent-verification-form-fields';
  static const String getAgentRegistrationForm = 'get-agent-verification-form';
  static const String apiGetAgentVerificationFormValues =
      'get-agent-verification-form-values';
  static const String getFollowingAgents = 'get-following-agents';
  static const String toggleFollowAgent = 'toggle-follow-agent';

  // User verification APIs
  static const String getUserVerificationForm = 'get_user_verification_form';
  static const String getUserVerificationFormValues =
      'get_user_verification_form_values';
  static const String applyUserVerification = 'apply_user_verification';
  static const String getAgents = 'agent-list';
  static const String getAgentFilterOptions = 'agent-filter-options';
  static const String getAgentProperties = 'agent-properties';

  // Appointment APIs
  static const String getMonthlyTimeSlots = 'appointment/monthly-time-slots';
  static const String checkAvailability = 'appointment/check-availability';
  static const String getUserAppointments = 'appointment/user-appointments';
  static const String getAgentAppointments = 'appointment/agent-appointments';
  static const String getBookingPreferences = 'appointment/booking-preferences';
  static const String getAgentTimeSchedules =
      'appointment/agent-time-schedules';
  static const String getUserReports = 'appointment/get-user-reports';
  static const String postAppointmentRequest = 'appointment/request';
  static const String updateAppointmentStatus = 'appointment/update-status';
  static const String postBookingPreferences =
      'appointment/booking-preferences';
  static const String postAgentTimeSchedules =
      'appointment/agent-time-schedules';
  static const String addUnavailability = 'appointment/add-unavailability';
  static const String manageExtraTimeSlots =
      'appointment/manage-extra-time-slots';
  static const String reportUser = 'appointment/report-user';
  static const String setAgentTimeSchedule =
      'appointment/set-agent-time-schedule';
  static const String deleteUnavailability =
      'appointment/delete-unavailability';
  static const String deleteExtraTimeSlot =
      'appointment/delete-extra-time-slots';
  static const String updateMeetingType = 'appointment/update-meeting-type';

  // Other APIs
  static const String apiGetMortgageCalculator = 'mortgage-calculator';
  static const String apiRemovePostImages = 'remove_post_images';
  static const String storeAdvertisement = 'store_advertisement';
  static const String deleteAdvertisement = 'delete_advertisement';
  static const String getAdBanners = 'ad-banners';
  static const String getReportReasons = 'get_report_reasons';
  static const String addReports = 'add_reports';
  static const String personalisedFields = 'personalised-fields';
  static const String apiGetAppSettings = 'app-settings';
  static const String apiGetPrivacyPolicy = 'privacy-policy';
  static const String apiGetTermsAndConditions = 'terms-conditions';
  static const String apiGetAboutUs = 'about-us';
  static const String apiGetCustomPages = 'get_custom_pages';

  // Gemini (AI) APIs
  static const String generateMeta = 'gemini/generate-meta';
  static const String generateDescription = 'gemini/generate-description';

  // Parameter names - organized alphabetically for easier lookup
  static const String aboutApp = 'about_app';
  static const String actionType = 'action_type';
  static const String addedBy = 'added_by';
  static const String address = 'address';
  static const String agentId = 'agent_id';
  static const String authId = 'auth_id';
  static const String category = 'category';
  static const String categoryId = 'category_id';
  static const String clientAddress = 'client_address';
  static const String company = 'company';
  static const String compAdrs = 'company_address';
  static const String compEmail = 'company_email';
  static const String compName = 'company_name';
  static const String compWebsite = 'company_website';
  static const String created = 'created';
  static const String createdAt = 'created_at';
  static const String currencySymbol = 'currency_symbol';
  static const String customerId = 'customer_id';
  static const String customersId = 'customers_id';
  static const String description = 'description';
  static const String durationSeconds = 'duration_seconds';
  static const String email = 'email';
  static const String enqStatus = 'status';
  static const String entityId = 'entity_id';
  static const String entityType = 'entity_type';
  static const String error = 'error';
  static const String fcmId = 'fcm_id';
  static const String gallery = 'gallery';
  static const String galleryImages = 'gallery_images';
  static const String id = 'id';
  static const String image = 'image';
  static const String input = 'input';
  static const String isActive = 'isActive';
  static const String isProjects = 'is_projects';
  static const String languageCode = 'language_code';
  static const String latitude = 'latitude';
  static const String limit = 'limit';
  static const String longitude = 'longitude';
  static const String maintenanceMode = 'maintenance_mode';
  static const String maxPrice = 'max_price';
  static const String media = 'media';
  static const String mediaType = 'media_type';
  static const String message = 'message';
  static const String minPrice = 'min_price';
  static const String mobile = 'mobile';
  static const String name = 'name';
  static const String notification = 'notification';
  static const String offset = 'offset';
  static const String packageId = 'package_id';
  static const String parameterTypes = 'parameter_types';
  static const String placeid = 'placeid';
  static const String postCreated = 'post_created';
  static const String postedSince = 'posted_since';
  static const String price = 'price';
  static const String privacyPolicy = 'privacy_policy';
  static const String profile = 'profile';
  static const String projectId = 'project_id';
  static const String promoted = 'promoted';
  static const String property = 'property';
  static const String propertyId = 'property_id';
  static const String propertyType = 'property_type';
  static const String propertysId = 'propertys_id';
  static const String radius = 'radius';
  static const String search = 'search';
  static const String status = 'status';
  static const String storyId = 'story_id';
  static const String tele1 = 'company_tel1';
  static const String tele2 = 'company_tel2';
  static const String termsAndConditions = 'terms_conditions';
  static const String thumbnail = 'thumbnail';
  static const String title = 'title';
  static const String titleImage = 'title_image';
  static const String totalView = 'total_view';
  static const String type = 'type';
  static const String typeId = 'type_id';
  static const String types = 'types';
  static const String userid = 'userid';
  static const String v360degImage = 'three_d_image';
  static const String videoLink = 'video_link';

  /// Generic request method to reduce code duplication
  static Future<Map<String, dynamic>> _makeRequest({
    required String method,
    required String url,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? queryParameters,
    bool useAuthToken = true,
    bool useBaseUrl = true,
    String? countryId,
    bool passCountryId = true,
  }) async {
    try {
      // Check internet connectivity before making any API call
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw ApiException('noInternet');
      }

      apiRequestCount++;
      final endpoint = (useBaseUrl ? AppConfig.baseUrl : '') + url;

      // Track API calls
      currentlyCallingAPI.add(url);

      Response<dynamic> response;

      // Never mutate caller-provided maps (they may be const / unmodifiable).
      final mutableParameters = parameters == null
          ? null
          : Map<String, dynamic>.from(parameters);
      final mutableQueryParameters = queryParameters == null
          ? null
          : Map<String, dynamic>.from(queryParameters);

      mutableParameters?.removeWhere(
        (key, value) => value == '' || value == null,
      );
      mutableQueryParameters?.removeWhere(
        (key, value) => value == '' || value == null,
      );

      final shouldUseMultipart =
          (method.toUpperCase() == 'POST') &&
          (mutableParameters != null && mutableParameters.isNotEmpty);

      final isProfileEndpoint =
          url == Api.apiGetUserData ||
          url == Api.apiUpdateProfile ||
          url == Api.apiGetAgentProfile ||
          url == Api.apiUpdateAgentProfile ||
          url.endsWith(Api.apiGetUserData) ||
          url.endsWith(Api.apiUpdateProfile) ||
          url.endsWith(Api.apiGetAgentProfile) ||
          url.endsWith(Api.apiUpdateAgentProfile);

      final effectivePassCountryId = passCountryId && !isProfileEndpoint;

      final requestOptions = Options(
        headers: headers(
          usAuthToken: useAuthToken,
          countryId: countryId,
          passCountryId: effectivePassCountryId,
        ),
        contentType: shouldUseMultipart ? 'multipart/form-data' : null,
      );

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get<dynamic>(
            endpoint,
            queryParameters: mutableQueryParameters ?? mutableParameters,
            options: requestOptions,
          );
        case 'POST':
          final formData =
              (mutableParameters != null && mutableParameters.isNotEmpty)
              ? FormData.fromMap(
                  _cloneMultipartFiles(mutableParameters),
                  ListFormat.multiCompatible,
                )
              : null;
          response = await _dio.post<dynamic>(
            endpoint,
            data: formData,
            queryParameters: mutableQueryParameters,
            options: requestOptions,
          );
        case 'DELETE':
          response = await _dio.delete<dynamic>(
            endpoint,
            queryParameters: mutableQueryParameters,
            options: requestOptions,
          );
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      currentlyCallingAPI.remove(url);
      return _processResponse(response);
    } on DioException catch (e) {
      apiErrorCount++;
      currentlyCallingAPI.remove(url);
      return _handleDioException(e);
    } on ApiException {
      apiErrorCount++;
      currentlyCallingAPI.remove(url);
      rethrow;
    } on Exception catch (e) {
      apiErrorCount++;
      currentlyCallingAPI.remove(url);
      throw ApiException(e.toString());
    }
  }

  /// Process API response
  static Map<String, dynamic> _processResponse(Response<dynamic> response) {
    final data = response.data;

    if (data is Map<String, dynamic> && data['error'] == true) {
      final d = data['data'];

      if (d == null || (d is List && d.isEmpty) || (d is Map && d.isEmpty)) {
        throw ApiException(
          data['message']?.toString() ?? 'API Error',
          errorKey: data['key']?.toString(),
        );
      }
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String && data.trim().isNotEmpty) {
      return {'data': data};
    }

    // Unexpected/empty body (null, empty string, list, etc.) - don't crash
    // on a bad cast, surface it as a proper API error instead.
    throw ApiException('Invalid response from server');
  }

  /// Handle Dio exceptions consistently
  static Map<String, dynamic> _handleDioException(DioException e) {
    if (e.response == null) {
      throw ApiException(e.message ?? 'Network Error');
    }

    final statusCode = e.response!.statusCode;
    final responseData = e.response!.data;

    // Handle 401 Unauthorized - Auto logout user
    if (statusCode == 401) {
      _handleUnauthorizedAccess();
      throw ApiException('sessionExpired');
    }

    // responseData may be null, a String (HTML error page, empty body),
    // or malformed JSON that Dio couldn't decode into a Map - never trust
    // it blindly to be a Map before reading fields off it.
    final responseMap = responseData is Map ? responseData : null;

    if (statusCode == 400) {
      if (responseMap != null && responseMap['data'] != null) {
        return _processResponse(e.response!);
      }
      throw ApiException(
        _extractMessage(responseMap) ?? e.message ?? 'HTTP Error $statusCode',
        errorKey: responseMap?['key']?.toString(),
      );
    }

    if (statusCode == 500) {
      throw ApiException(
        _extractMessage(responseMap) ?? e.message ?? 'Server Error',
        errorKey: responseMap?['key']?.toString(),
      );
    }

    // Throw exception for other status codes
    throw ApiException(
      _extractMessage(responseMap) ?? e.message ?? 'HTTP Error $statusCode',
      errorKey: responseMap?['key']?.toString(),
    );
  }

  /// Safely pull a human-readable message out of a possibly-null/non-Map
  /// error response body. Returns null (never throws) when nothing usable
  /// is present, so callers can fall back to a sane default.
  static String? _extractMessage(Map<dynamic, dynamic>? responseMap) {
    final message = responseMap?['message'];
    if (message == null) return null;
    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Handle 401 Unauthorized - Auto logout user
  static void _handleUnauthorizedAccess() {
    // Prevent multiple simultaneous logout redirects
    if (_isHandlingUnauthorized) return;

    final context = Constant.navigatorKey.currentContext;
    if (context == null) return;

    // Check if user is a guest - guests don't need to be logged out
    if (GuestChecker.value) return;

    // Check if user is not authenticated - no need to logout
    if (!HiveUtils.isUserAuthenticated()) return;

    // Check if we're already on the login screen
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == Routes.login || currentRoute == Routes.onboarding) {
      return;
    }

    // Set flag to prevent multiple redirects
    _isHandlingUnauthorized = true;

    // Perform logout similar to profile_screen logout flow
    Future.delayed(Duration.zero, () async {
      try {
        // Clear interest properties
        Constant.interestedPropertyIds.clear();

        // Logout user which handles all cleanup
        await HiveUtils.logoutUser(
          context,
          onLogout: () {},
          isRedirect: false,
        );
        HelperUtils.showSnackBarMessage(
          context,
          'sessionExpired'.translate(context),
          type: .error,
        );

        // Navigate to login screen
        await Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
          (route) => false,
        );
      } on Exception {
        HelperUtils.showSnackBarMessage(
          context,
          'sessionExpired'.translate(context),
          type: .error,
        );
        // If logout fails, still try to navigate to login
        await Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
          (route) => false,
        );
      } finally {
        // Reset flag after navigation completes
        Future.delayed(const Duration(milliseconds: 500), () {
          _isHandlingUnauthorized = false;
        });
      }
    });
  }

  /// GET request
  static Future<Map<String, dynamic>> get({
    required String url,
    bool useAuthToken = true,
    Map<String, dynamic>? queryParameters,
    bool useBaseUrl = true,
    String? countryId,
    bool passCountryId = true,
  }) {
    return _makeRequest(
      method: 'GET',
      url: url,
      parameters: queryParameters,
      useAuthToken: useAuthToken,
      useBaseUrl: useBaseUrl,
      countryId: countryId,
      passCountryId: passCountryId,
    );
  }

  /// POST request
  static Future<Map<String, dynamic>> post({
    required String url,
    required Map<String, dynamic> parameter,
    Map<String, dynamic>? queryParameters,
    bool useAuthToken = true,
    bool useBaseUrl = true,
    String? countryId,
    bool passCountryId = true,
  }) {
    return _makeRequest(
      method: 'POST',
      url: url,
      parameters: parameter,
      queryParameters: queryParameters,
      useAuthToken: useAuthToken,
      useBaseUrl: useBaseUrl,
      countryId: countryId,
      passCountryId: passCountryId,
    );
  }

  /// DELETE request
  static Future<Map<String, dynamic>> delete({
    required String url,
    Map<String, dynamic>? queryParameters,
    bool useAuthToken = true,
    bool useBaseUrl = true,
    String? countryId,
    bool passCountryId = true,
  }) {
    return _makeRequest(
      method: 'DELETE',
      url: url,
      queryParameters: queryParameters,
      useAuthToken: useAuthToken,
      useBaseUrl: useBaseUrl,
      countryId: countryId,
      passCountryId: passCountryId,
    );
  }

  static Map<String, dynamic> _cloneMultipartFiles(
    Map<String, dynamic> map,
  ) {
    return map.map((key, value) {
      if (value is MultipartFile) {
        return MapEntry(key, value.clone());
      }
      if (value is File) {
        return MapEntry(key, MultipartFile.fromFileSync(value.path));
      }
      if (value is List) {
        return MapEntry(
          key,
          value.map((e) {
            if (e is MultipartFile) return e.clone();
            if (e is File) return MultipartFile.fromFileSync(e.path);
            if (e is Map<String, dynamic>) return _cloneMultipartFiles(e);
            return e;
          }).toList(),
        );
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _cloneMultipartFiles(value));
      }
      return MapEntry(key, value);
    });
  }

  static Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return response;
  }

  static void _throwIfApiError(Map<String, dynamic> response) {
    if (response['error'] == true) {
      throw ApiException(response['message']?.toString() ?? 'API Error');
    }
  }

  static Future<String> generateDescriptionContent({
    required String entityType,
    required int languageId,
    String? entityId,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) async {
    final qp =
        <String, dynamic>{
          'entity_type': entityType,
          'entity_id': ?entityId,
          'language_id': languageId,
          ...context,
        }..removeWhere(
          (key, value) =>
              value == null || (value is String && value.trim().isEmpty),
        );

    final response = await post(
      url: generateDescription,
      parameter: const <String, dynamic>{},
      queryParameters: qp,
    );
    _throwIfApiError(response);

    final data = response['data'];
    if (data is String) return data;

    final unwrapped = _unwrapData(response);
    final candidate =
        unwrapped['description'] ??
        unwrapped['desc'] ??
        unwrapped['generated_description'] ??
        unwrapped['content'];
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate;
    }

    throw ApiException('Invalid AI description response');
  }

  static Future<Map<String, String>> generateMetaContent({
    required String entityType,
    String? entityId,
    Map<String, dynamic> context = const <String, dynamic>{},
    int? languageId,
  }) async {
    final qp =
        <String, dynamic>{
          'entity_type': entityType,
          'entity_id': ?entityId,
          'language_id': ?languageId,
          ...context,
        }..removeWhere(
          (key, value) =>
              value == null || (value is String && value.trim().isEmpty),
        );

    final response = await post(
      url: generateMeta,
      parameter: const <String, dynamic>{},
      queryParameters: qp,
    );
    _throwIfApiError(response);

    final unwrapped = _unwrapData(response);
    final metaTitle =
        (unwrapped['meta_title'] ?? unwrapped['title'])?.toString() ?? '';
    final metaDescription =
        (unwrapped['meta_description'] ?? unwrapped['description'])
            ?.toString() ??
        '';
    final metaKeywords =
        (unwrapped['meta_keywords'] ?? unwrapped['keywords'])?.toString() ?? '';

    if (metaTitle.trim().isEmpty &&
        metaDescription.trim().isEmpty &&
        metaKeywords.trim().isEmpty) {
      throw ApiException('Invalid AI meta response');
    }

    return <String, String>{
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'meta_keywords': metaKeywords,
    };
  }
}

// Error classes remain the same but with better documentation

/// Abstract base class for API errors
abstract class Error {
  StackTrace? stackTrace;
  DioException? error;
}

/// Represents no internet connection error
class NoInternetConnectionError extends Error {
  NoInternetConnectionError();

  @override
  String toString() => 'No Internet Connection';
}

/// Custom exception for API-related errors
class ApiException implements Exception {
  ApiException(this.errorMessage, {this.errorKey});

  final String errorMessage;
  final String? errorKey;

  @override
  String toString() {
    return ErrorFilter.check(errorMessage).error?.toString() ?? errorMessage;
  }
}
