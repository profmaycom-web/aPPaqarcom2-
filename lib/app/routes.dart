import 'dart:developer';

import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/advertisement/my_advertisment_screen.dart';
import 'package:ebroker/ui/screens/agent_dashboard/agent_followers_screen.dart';
import 'package:ebroker/ui/screens/agent_dashboard/verify_agent_form_screen.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_details_screen.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_list_screen.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_registration_success_screen.dart';
import 'package:ebroker/ui/screens/agent_mode/become_agent_form_screen.dart';
import 'package:ebroker/ui/screens/agent_mode/become_agent_screen.dart';
import 'package:ebroker/ui/screens/appointment/configuration_screens/appointment_configuration_screen.dart';
import 'package:ebroker/ui/screens/appointment/my_appointments_screen.dart';
import 'package:ebroker/ui/screens/appointment/send_request_screens/appointment_flow.dart';
import 'package:ebroker/ui/screens/auth/email_registration_form.dart';
import 'package:ebroker/ui/screens/auth/otp_screen.dart';
import 'package:ebroker/ui/screens/auth/phone_registration_form.dart';
import 'package:ebroker/ui/screens/home/city_properties_screen.dart';
import 'package:ebroker/ui/screens/home/home_screen.dart';
import 'package:ebroker/ui/screens/home/widgets/city_list_screen.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/preferences_settings_screen.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/privacy_other_info_screen.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/watermark_settings_section.dart';
import 'package:ebroker/ui/screens/profile/widgets/user_verification_form.dart';
import 'package:ebroker/ui/screens/project/add_project/add_project_screen.dart';
import 'package:ebroker/ui/screens/proprties/add_property/add_property_screen.dart';
import 'package:ebroker/ui/screens/proprties/widgets/compare_property_screen.dart';
import 'package:ebroker/ui/screens/settings/faqs_screen.dart';
import 'package:ebroker/ui/screens/stories/add_story_screen.dart';
import 'package:ebroker/ui/screens/stories/my_stories_screen.dart';
import 'package:ebroker/ui/screens/stories/select_story_listing_screen.dart';
import 'package:ebroker/ui/screens/stories/story_review_screen.dart';
import 'package:ebroker/ui/screens/stories/story_viewer_screen.dart';

class Routes {
  //private constructor
  Routes._();

  static const appointmentFlow = '/appointmentFlow';
  static const appointmentConfiguration = '/appointmentConfiguration';
  static const comparePropertiesScreen = '/comparePropertiesScreen';
  static const myAppointmentsScreen = '/myAppointmentsScreen';
  static const userVerificationForm = '/userVerificationForm';
  static const verifyAgentForm = '/verifyAgentForm';
  static const becomeAgentScreen = '/becomeAgentScreen';
  static const becomeAgentForm = '/becomeAgentForm';
  static const agentRegistrationSuccess = '/agentRegistrationSuccess';
  static const agentDetailsScreen = '/agentDetailsScreen';
  static const agentListScreen = '/agentListScreen';
  static const agentFollowersScreen = '/agentFollowersScreen';
  static const cityPropertiesScreen = '/cityPropertiesScreen';
  static const splash = '/';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const otpScreen = 'otpScreen';
  static const emailRegistrationForm = 'emailRegistrationForm';
  static const phoneRegistrationForm = 'phoneRegistrationForm';
  static const editProfile = 'editProfile';
  static const editAgentProfile = 'editAgentProfile';
  static const watermarkSettings = 'watermarkSettings';
  static const main = 'main';
  static const home = 'home_screen';
  static const addProperty = 'addProperty';
  static const waitingScreen = 'waitingScreen';
  static const categories = 'Categories';
  static const cityListScreen = 'cityListScreen';
  static const addresses = 'address';
  static const chooseAdrs = 'chooseAddress';
  static const propertiesList = 'propertiesList';
  static const propertyDetails = 'PropertyDetails';
  static const storyViewer = 'StoryViewer';
  static const myStories = 'MyStories';
  static const addStory = 'AddStory';
  static const selectStoryListing = 'SelectStoryListing';
  static const uploadStory = 'UploadStory';
  static const contactUs = 'ContactUs';
  static const profileSettings = 'profileSettings';
  static const myEnquiry = 'MyEnquiry';
  static const filterScreen = 'filterScreen';
  static const notificationPage = 'notificationpage';
  static const notificationDetailPage = 'notificationdetailpage';
  static const addPropertyScreenRoute = 'addPropertyScreenRoute';
  static const articlesScreenRoute = 'articlesScreenRoute';
  static const subscriptionPackageListRoute = 'subscriptionPackageListRoute';
  static const maintenanceMode = '/maintenanceMode';
  static const favoritesScreen = '/favoritescreen';
  static const articleDetailsScreenRoute = '/articleDetailsScreenRoute';
  static const areaConvertorScreen = '/areaCalculatorScreen';

  // static const mortgageCalculatorScreen = '/mortgageCalculatorScreen';
  static const preferencesSettings = '/preferencesSettings';
  static const privacyOtherInfo = '/privacyOtherInfo';
  static const searchScreenRoute = '/searchScreenRoute';
  static const chooseLocaitonMap = '/chooseLocationMap';
  static const propertyMapScreen = '/propertyMap';
  static const dashboard = '/dashboard';

  static const myAdvertisment = '/myAdvertisment';
  static const transactionHistory = '/transactionHistory';

  // static const nearbyAllProperties = '/nearbyAllProperties';
  static const personalizedPropertyScreen = '/personalizedPropertyScreen';
  static const allProjectsScreen = '/allProjectsScreen';
  static const faqsScreen = '/faqsScreen';

  ///Project section routes
  static const String addProjectDetails = '/addProjectDetails';
  static const String addProjectScreenRoute = '/addProjectScreenRoute';
  static const String projectMetaDataScreens = '/projectMetaDataScreens';
  static const String manageFloorPlansScreen = '/manageFloorPlansScreen';

  ///Add property screens
  static const selectPropertyTypeScreen = '/selectPropertyType';
  static const addPropertyDetailsScreen = '/addPropertyDetailsScreen';
  static const setPropertyParametersScreen = '/setPropertyParametersScreen';
  static const selectOutdoorFacility = '/selectOutdoorFacility';

  ///View project
  static const projectDetailsScreen = '/projectDetailsScreen';

  //Sandbox[test]
  static const playground = 'playground';

  static String currentRoute = '';
  static String previousCustomerRoute = '';

  static Route<dynamic>? onGenerateRouted(RouteSettings routeSettings) {
    previousCustomerRoute = currentRoute;
    currentRoute = routeSettings.name ?? '';
    log(currentRoute, name: 'CURRENT ROUTE');

    if (_isDeepLink(currentRoute)) {
      return null;
    }

    if (currentRoute.contains('/link?')) {
      return null;
    }

    switch (routeSettings.name) {
      case '':
        break;

      case splash:
        return CupertinoPageRoute(builder: (context) => const SplashScreen());
      case onboarding:
        return CupertinoPageRoute(
          builder: (context) => const OnboardingScreen(),
        );
      case home:
        return CupertinoPageRoute(
          builder: (context) => const HomeScreen(from: 'main'),
        );
      case main:
        return MainActivity.route(routeSettings);
      case login:
        return LoginScreen.route(routeSettings);
      case otpScreen:
        return OtpScreen.route(routeSettings);
      case emailRegistrationForm:
        return EmailRegistrationForm.route(routeSettings);
      case phoneRegistrationForm:
        return PhoneRegistrationForm.route(routeSettings);
      case editProfile:
        return EditProfileScreen.route(routeSettings);
      case editAgentProfile:
        return EditAgentProfileScreen.route(routeSettings);
      case watermarkSettings:
        return WatermarkSettingsScreen.route(routeSettings);
      case categories:
        return CategoryList.route(routeSettings);
      case cityListScreen:
        return CityListScreen.route(routeSettings);
      case cityPropertiesScreen:
        return CityPropertiesScreen.route(routeSettings);
      case maintenanceMode:
        return MaintenanceMode.route(routeSettings);
      case preferencesSettings:
        return PreferencesSettingsScreen.route(routeSettings);
      case privacyOtherInfo:
        return PrivacyOtherInfoScreen.route(routeSettings);
      case propertiesList:
        return PropertiesList.route(routeSettings);
      case propertyDetails:
        return PropertyDetails.route(routeSettings);
      case storyViewer:
        return StoryViewerScreen.route(routeSettings);
      case myStories:
        return MyStoriesScreen.route(routeSettings);
      case addStory:
        return AddStoryScreen.route(routeSettings);
      case selectStoryListing:
        return SelectStoryListingScreen.route(routeSettings);
      case uploadStory:
        return StoryReviewScreen.route(routeSettings);
      case contactUs:
        return ContactUs.route(routeSettings);
      case profileSettings:
        return ProfileSettings.route(routeSettings);
      case filterScreen:
        return FilterScreen.route(routeSettings);
      case notificationPage:
        return Notifications.route(routeSettings);
      case notificationDetailPage:
        return NotificationDetail.route(routeSettings);
      case chooseLocaitonMap:
        return ChooseLocationMap.route(routeSettings);
      case articlesScreenRoute:
        return ArticlesScreen.route(routeSettings);
      case areaConvertorScreen:
        return AreaCalculator.route(routeSettings);
      case articleDetailsScreenRoute:
        return ArticleDetails.route(routeSettings);
      case subscriptionPackageListRoute:
        return SubscriptionPackageListScreen.route(routeSettings);
      case favoritesScreen:
        return FavoritesScreen.route(routeSettings);
      case selectPropertyTypeScreen:
        return SelectPropertyType.route(routeSettings);
      case transactionHistory:
        return TransactionHistory.route(routeSettings);
      case myAdvertisment:
        return MyAdvertisementScreen.route(routeSettings);
      case personalizedPropertyScreen:
        return PersonalizedPropertyScreen.route(routeSettings);
      case addProperty:
      case addPropertyScreenRoute:
        return AddPropertyScreen.route(routeSettings);
      case addPropertyDetailsScreen:
        return AddPropertyScreen.route(routeSettings);
      case setPropertyParametersScreen:
        return SetProeprtyParametersScreen.route(routeSettings);
      case searchScreenRoute:
        return SearchScreen.route(routeSettings);
      case propertyMapScreen:
        return PropertyMapScreen.route(routeSettings);
      case selectOutdoorFacility:
        return SelectOutdoorFacility.route(routeSettings);
      case addProjectDetails:
        return AddProjectScreen.route(routeSettings);
      case addProjectScreenRoute:
        return AddProjectScreen.route(routeSettings);
      case projectMetaDataScreens:
        return ProjectMetaDetails.route(routeSettings);
      case projectDetailsScreen:
        return ProjectDetailsScreen.route(routeSettings);
      case manageFloorPlansScreen:
        return ManageFloorPlansScreen.route(routeSettings);
      case allProjectsScreen:
        return AllProjectsScreen.route(routeSettings);
      case agentListScreen:
        return AgentListScreen.route(routeSettings);
      case agentFollowersScreen:
        return AgentFollowersScreen.route(routeSettings);
      case agentDetailsScreen:
        return AgentDetailsScreen.route(routeSettings);
      case userVerificationForm:
        return UserVerificationForm.route(routeSettings);
      case verifyAgentForm:
        return VerifyAgentFormScreen.route(routeSettings);
      case becomeAgentScreen:
        return BecomeAgentScreen.route(routeSettings);
      case becomeAgentForm:
        return BecomeAgentFormScreen.route(routeSettings);
      case agentRegistrationSuccess:
        return AgentRegistrationSuccessScreen.route(routeSettings);
      case faqsScreen:
        return FaqsScreen.route(routeSettings);
      case comparePropertiesScreen:
        return ComparePropertyScreen.route(routeSettings);
      case appointmentFlow:
        return AppointmentFlow.route(routeSettings);
      case appointmentConfiguration:
        return AppointmentConfigurationScreen.route(routeSettings);
      case myAppointmentsScreen:
        return MyAppointmentsScreen.route(routeSettings);
      default:
        return null;
    }
    return null;
  }

  static bool _isDeepLink(String route) {
    return route.contains('/property-details/') ||
        route.contains('/project-details/') ||
        route.contains('/agent-details/') ||
        route.contains('/article-details/');
  }
}
