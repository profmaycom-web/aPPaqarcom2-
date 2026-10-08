import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/agent_dashboard_screen.dart';
import 'package:ebroker/ui/screens/chat/chat_list_screen.dart';
import 'package:ebroker/ui/screens/home/home_screen.dart';
import 'package:ebroker/ui/screens/my_listings_screen.dart';
import 'package:ebroker/ui/screens/profile/profile_screen.dart';
import 'package:ebroker/ui/screens/proprties/property_details/in_screen_details_sheet.dart';
import 'package:ebroker/ui/screens/proprties/property_details/property_sheet_controller.dart';
import 'package:ebroker/ui/screens/widgets/add_listing_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

List<PropertyModel> myPropertylist = [];
Map<String, dynamic> searchbody = {};
String selectedcategoryId = '0';
String selectedcategoryName = '';
dynamic selectedCategory;
bool isFirstTime = true;

//this will set when i will visit in any category
dynamic currentVisitingCategoryId = '';
dynamic currentVisitingCategory = '';

List<int> navigationStack = [0];

//
class MainActivity extends StatefulWidget {
  const MainActivity({required this.from, super.key});

  final String from;

  @override
  State<MainActivity> createState() => MainActivityState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map? ?? {};
    return CupertinoPageRoute(
      builder: (_) =>
          MainActivity(from: arguments['from'] as String? ?? 'main'),
    );
  }
}

class MainActivityState extends State<MainActivity>
    with TickerProviderStateMixin {
  int currtab = 0;
  static final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final List<dynamic> _pageHistory = [];
  late PageController pageController;
  DateTime? currentBackPressTime;

  final _addListingController = AddListingController();

  bool isChecked = false;

  int get _initialTabIndex => widget.from == 'propertySuccess' ? 3 : 0;

  // Role-switch transition — mirrors ModeSwitchTransition effect
  late final AnimationController _roleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _roleCtrl,
    curve: Curves.easeInOut,
  );
  // User scaffold: slides out left + scales down as ctrl 0→1
  late final Animation<Offset> _userSlide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-1, 0),
  ).animate(_curved);
  late final Animation<double> _userScale = Tween<double>(
    begin: 1,
    end: 0.92,
  ).animate(_curved);
  // Agent dashboard: slides in from right + scales up as ctrl 0→1
  late final Animation<Offset> _agentSlide = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).animate(_curved);
  late final Animation<double> _agentScale = Tween<double>(
    begin: 0.92,
    end: 1,
  ).animate(_curved);
  // Greyscale→colour during second half of incoming animation
  late final Animation<double> _agentSaturate =
      Tween<double>(
        begin: 0,
        end: 1,
      ).animate(
        CurvedAnimation(
          parent: _roleCtrl,
          curve: const Interval(0.4, 1, curve: Curves.easeInOut),
        ),
      );
  // true while user scaffold is fully hidden (agent fully visible, no transition)
  bool _offstageUser = false;
  // Non-null while agent dashboard is visible or animating
  Widget? _agentWidget;

  @override
  void initState() {
    super.initState();
    if (appSettings.isUserActive == false) {
      Future.delayed(
        Duration.zero,
        () async {
          await HiveUtils.logoutUser(context, onLogout: () {});
        },
      );
    }

    GuestChecker.context = context;
    GuestChecker.set('main_activity', isGuest: HiveUtils.isGuest());
    ActiveRoleManager.syncFromHive();
    ActiveRoleManager.notifier.addListener(_onRoleChanged);

    // If app launches directly into agent role, show dashboard immediately
    if (ActiveRoleManager.notifier.value == ActiveRole.agent) {
      _agentWidget = const AgentDashboardScreen();
      _offstageUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _roleCtrl.value = 1;
      });
    }
    final settings = context.read<FetchSystemSettingsCubit>();
    if (!const bool.fromEnvironment(
      'force-disable-demo-mode',
    )) {
      AppSettings.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) as bool? ?? false;
    }
    final numberWithSuffix = settings.getSetting(
      SystemSetting.numberWithSuffix,
    );
    if (numberWithSuffix == '1') {
      Constant.isNumberWithSuffix = true;
    } else {
      Constant.isNumberWithSuffix = false;
    }

    ///This will check for update
    unawaited(versionCheck(settings));

    //This will init page controller
    initPageController();

    // Defer notification permission popup until the user reaches the home
    // screen — not during splash or onboarding.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.requestPermissions());
    });
  }

  void addHistory(int index) {
    final stack = navigationStack;

    if (stack.last != index) {
      if (index == 1 || index == 3) {
        if (!GuestChecker.value) {
          stack.add(index);
          navigationStack = stack;
        }
      } else {
        stack.add(index);
        navigationStack = stack;
      }
    }

    setState(() {});
  }

  void initPageController() {
    currtab = _initialTabIndex;
    navigationStack = [currtab];
    pageController = PageController(initialPage: currtab)
      ..addListener(() {
        _pageHistory.insert(0, pageController.page);
      });
  }

  Future<void> versionCheck(dynamic settings) async {
    var remoteVersion = settings.getSetting(
      Platform.isIOS ? SystemSetting.iosVersion : SystemSetting.androidVersion,
    );
    final remote = remoteVersion;

    final forceUpdate = settings.getSetting(SystemSetting.forceUpdate);

    final packageInfo = await PackageInfo.fromPlatform();

    final current = packageInfo.version;

    final currentVersion = HelperUtils.comparableVersion(packageInfo.version);
    if (remoteVersion == null) {
      return;
    }
    remoteVersion = HelperUtils.comparableVersion(
      remoteVersion?.toString() ?? '',
    );

    if ((remoteVersion > currentVersion) as bool? ?? false) {
      Constant.isUpdateAvailable = true;
      Constant.newVersionNumber =
          settings
              .getSetting(
                Platform.isIOS
                    ? SystemSetting.iosVersion
                    : SystemSetting.androidVersion,
              )
              ?.toString() ??
          '';

      Future.delayed(
        Duration.zero,
        () async {
          if (forceUpdate == '1') {
            ///This is force update
            await UiUtils.showBlurredDialoge(
              context,
              dialog: BlurredDialogBox(
                onAccept: () async {
                  if (Platform.isAndroid) {
                    await launchUrl(
                      Uri.parse(
                        AppSettings.playstoreURLAndroid,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await launchUrl(
                      Uri.parse(
                        AppSettings.appstoreURLios,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                backAllowedButton: false,
                svgImagePath: AppIcons.update,
                isAcceptContainesPush: true,
                svgImageColor: context.color.tertiaryColor,
                showCancleButton: false,
                title: 'updateAvailable'.translate(context),
                acceptTextColor: context.color.buttonColor,
                content: Column(
                  mainAxisSize: .min,
                  children: [
                    CustomText('$current>$remote'),
                    CustomText(
                      'newVersionAvailableForce'.translate(context),
                      textAlign: .center,
                    ),
                  ],
                ),
              ),
            );
          } else {
            await UiUtils.showBlurredDialoge(
              context,
              dialog: BlurredDialogBox(
                onAccept: () async {
                  if (Platform.isAndroid) {
                    await launchUrl(
                      Uri.parse(
                        AppSettings.playstoreURLAndroid,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await launchUrl(
                      Uri.parse(
                        AppSettings.appstoreURLios,
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                svgImagePath: AppIcons.update,
                svgImageColor: context.color.tertiaryColor,
                showCancleButton: true,
                title: 'updateAvailable'.translate(context),
                content: CustomText(
                  'newVersionAvailable'.translate(context),
                ),
              ),
            );
          }
        },
      );
    }
  }

  void _onRoleChanged() {
    final isAgent = ActiveRoleManager.notifier.value == ActiveRole.agent;
    if (isAgent) {
      // Ensure user scaffold visible so it can animate out
      setState(() {
        _offstageUser = false;
        _agentWidget = AgentDashboardScreen(initialTab: currtab);
      });
      unawaited(
        _roleCtrl.forward(from: 0).then((_) {
          // Offstage after slide-out completes — element stays alive
          if (mounted) setState(() => _offstageUser = true);
        }),
      );
    } else {
      // Un-offstage before animation so user scaffold can slide back in
      setState(() => _offstageUser = false);
      unawaited(
        _roleCtrl.reverse().then((_) {
          if (mounted) setState(() => _agentWidget = null);
        }),
      );
    }
  }

  @override
  void dispose() {
    ActiveRoleManager.notifier.removeListener(_onRoleChanged);
    _roleCtrl.dispose();
    pageController.dispose();
    _addListingController.dispose();
    super.dispose();
  }

  late List<Widget> pages = [
    HomeScreen(from: widget.from),
    const ChatListScreen(),
    const CustomText(''),
    const MyListingsScreen(),
    const ProfileScreen(),
  ];

  Widget _buildUserScaffold() {
    return RoleScope(
      role: ActiveRole.user,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;

          if (PropertySheetController.isShowing) {
            PropertySheetController.hide();
            return;
          }

          if (navigationStack.last == 0) {
            final now = DateTime.now();
            if (currentBackPressTime == null ||
                now.difference(currentBackPressTime!) >
                    const Duration(seconds: 2)) {
              currentBackPressTime = now;
              await Fluttertoast.showToast(
                msg: 'pressAgainToExit'.translate(context),
              );
              return;
            }
          } else {
            final length = navigationStack.length;
            final secondLast = navigationStack[length - 2];
            navigationStack.removeLast();
            pageController.jumpToPage(secondLast);
            setState(() {});
            return;
          }

          Future.delayed(Duration.zero, () async {
            await SystemChannels.platform.invokeMethod(
              'SystemNavigator.pop',
            );
          });
        },
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          bottomNavigationBar: Constant.maintenanceMode == '1'
              ? null
              : bottomBar(),
          body: Stack(
            children: <Widget>[
              PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                onPageChanged: onItemSwipe,
                children: pages,
              ),
              if (Constant.maintenanceMode == '1')
                Container(
                  color: Theme.of(context).colorScheme.primaryColor,
                ),
              AddListingOverlay(
                controller: _addListingController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // User scaffold: always in tree. Slides left + scales down on role switch.
        // Offstaged only after forward animation completes (element stays alive).
        IgnorePointer(
          ignoring: _agentWidget != null,
          child: Offstage(
            offstage: _offstageUser,
            child: SlideTransition(
              position: _userSlide,
              child: ScaleTransition(
                scale: _userScale,
                child: _buildUserScaffold(),
              ),
            ),
          ),
        ),
        // Agent dashboard: slides in from right + scales up
        if (_agentWidget != null)
          SlideTransition(
            position: _agentSlide,
            child: ScaleTransition(
              scale: _agentScale,
              child: AnimatedBuilder(
                animation: _agentSaturate,
                builder: (context, child) => child ?? const SizedBox.shrink(),
                child: _agentWidget,
              ),
            ),
          ),
        const InScreenDetailsSheet(),
      ],
    );
  }

  Future<void> onItemTapped(int index) async {
    addHistory(index);

    FocusManager.instance.primaryFocus?.unfocus();
    _addListingController.close();

    if (index != 1) {
      context.read<SearchPropertyCubit>().clearSearch();
    }
    searchbody = {};
    if (index == 1 || index == 3) {
      await GuestChecker.check(
        onNotGuest: () {
          currtab = index;
          pageController.jumpToPage(currtab);
          setState(
            () {},
          );
        },
      );
    } else {
      currtab = index;
      pageController.jumpToPage(currtab);
      setState(() {});
    }
  }

  double degreesToQuarterTurns(double degrees) {
    return degrees / 90;
  }

  void onItemSwipe(int index) {
    addHistory(index);

    FocusManager.instance.primaryFocus?.unfocus();
    _addListingController.close();

    if (index != 1) {
      context.read<SearchPropertyCubit>().clearSearch();
    }
    searchbody = {};
    setState(() {
      currtab = index;
    });
    pageController.jumpToPage(currtab);
  }

  Widget bottomBar() {
    return Container(
      height: 76.rh(context),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        boxShadow: [
          BoxShadow(
            color: context.color.textColorDark.withValues(alpha: 0.2),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: .spaceAround,
        children: <Widget>[
          buildBottomNavigationbarItem(
            0,
            AppIcons.home,
            AppIcons.homeActive,
            'homeTab'.translate(context),
          ),
          buildBottomNavigationbarItem(
            1,
            AppIcons.chat,
            AppIcons.chatActive,
            'chat'.translate(context),
          ),
          Transform.translate(
            offset: Offset(0, -30.rh(context)),
            child: AddListingButton(controller: _addListingController),
          ),
          buildBottomNavigationbarItem(
            3,
            AppIcons.properties,
            AppIcons.propertiesActive,
            'myListings'.translate(context),
          ),
          buildBottomNavigationbarItem(
            4,
            AppIcons.profileOutlined,
            AppIcons.profileActive,
            'profileTab'.translate(context),
          ),
        ],
      ),
    );
  }

  Widget buildBottomNavigationbarItem(
    int index,
    String svgImage,
    String selectedSvgImage,
    String title,
  ) {
    return Expanded(
      child: GestureDetector(
        behavior: .opaque,
        onTap: () => onItemTapped(index),
        child: Padding(
          padding: EdgeInsets.all(4.rh(context)),
          child: Column(
            mainAxisAlignment: .center,
            children: <Widget>[
              AnimatedScale(
                scale: currtab == index ? 1.3 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  alignment: Alignment.center,
                  child: CustomImage(
                    imageUrl: currtab == index ? selectedSvgImage : svgImage,
                    height: 24.rh(context),
                    width: 24.rw(context),
                    color: currtab == index
                        ? context.color.tertiaryColor
                        : context.color.textColorDark.withValues(alpha: .5),
                  ),
                ),
              ),
              SizedBox(height: 4.rh(context)),
              CustomText(
                title,
                maxLines: 1,
                textAlign: .center,
                fontSize: context.font.xs,
                color: currtab == index
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: .5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
