import 'package:ebroker/data/cubits/appointment/get/fetch_agent_previous_appointments_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_agent_time_schedules_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_agent_upcoming_appointments_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_booking_preferences_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_user_previous_appointments_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_user_upcoming_appointments_cubit.dart';
import 'package:ebroker/data/cubits/property/report/property_report_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/data/repositories/auth_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/profile_tile.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/country_selection_bottomsheet.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/language_selection_bottomsheet.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/theme_selection_bottomsheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

class PreferencesSettingsScreen extends StatefulWidget {
  const PreferencesSettingsScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const PreferencesSettingsScreen(),
    );
  }

  @override
  State<PreferencesSettingsScreen> createState() =>
      _PreferencesSettingsScreenState();
}

class _PreferencesSettingsScreenState extends State<PreferencesSettingsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<FetchCountriesCubit>().fetchCountries());
  }

  void _clearAppointmentCubits(BuildContext context) {
    context.read<FetchBookingPreferencesCubit>().clear();
    context.read<FetchAgentUpcomingAppointmentsCubit>().clear();
    context.read<FetchAgentPreviousAppointmentsCubit>().clear();
    context.read<FetchUserUpcomingAppointmentsCubit>().clear();
    context.read<FetchUserPreviousAppointmentsCubit>().clear();
    context.read<FetchAgentTimeSchedulesCubit>().clear();
  }

  Future<void> _deleteConfirmWidget(BuildContext context) async {
    final hasInternet = await HelperUtils.checkInternet();
    final isAgent =
        context.read<UserDetailsCubit>().state.user?.isAgent ?? false;
    if (!hasInternet) {
      return HelperUtils.showSnackBarMessage(
        context,
        'noInternet',
        type: MessageType.error,
      );
    }
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'deleteProfileMessageTitle'.translate(context),
        onAccept: () async {
          final L = HiveUtils.getUserLoginType();
          try {
            reportedProperties.clear();
            _clearAppointmentCubits(context);
            if (L == LoginType.phone &&
                AppSettings.otpServiceProvider == 'firebase') {
              await FirebaseAuth.instance.currentUser?.delete();
            }
            if (L == LoginType.apple || L == LoginType.google) {
              await FirebaseAuth.instance.currentUser?.delete();
            }
            await context.read<DeleteAccountCubit>().deleteUserAccount(context);
            if (L == LoginType.email) {
              Constant.interestedPropertyIds.clear();
              context.read<LoadChatMessagesCubit>().clear();
              context.read<GetChatListCubit>().clear();
              context.read<FetchMyPropertiesCubit>().clear();
              context.read<FetchMyProjectsCubit>().clear();
              context.read<LikedPropertiesCubit>().clear();
            }
          } on Exception catch (e) {
            if (e is FirebaseAuthException) {
              if (e.code == 'requires-recent-login') {
                await UiUtils.showBlurredDialoge(
                  context,
                  dialog: BlurredDialogBox(
                    title: 'Recent login required'.translate(context),
                    acceptTextColor: context.color.buttonColor,
                    showCancleButton: false,
                    content: CustomText(
                      'logoutAndLoginAgain'.translate(context),
                      textAlign: .center,
                    ),
                  ),
                );
              }
            } else {
              await UiUtils.showBlurredDialoge(
                context,
                dialog: BlurredDialogBox(
                  title: 'somethingWentWrong'.translate(context),
                  acceptTextColor: context.color.buttonColor,
                  showCancleButton: false,
                  content: CustomText(e.toString()),
                ),
              );
            }
          }
        },
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              'deleteProfileMessageContent'.translate(context),
              textAlign: .center,
            ),
            if (isAgent) ...[
              CustomText(
                'confirmDeleteAgentMessage'.translate(context),
                textAlign: .center,
              ),
            ],
          ],
        ),
        acceptButtonName: 'deleteBtnLbl'.translate(context),
        acceptTextColor: context.color.buttonColor,
        cancelTextColor: context.color.textColorDark,
        svgImagePath: AppIcons.deleteIllustration,
        isAcceptContainesPush: true,
        barrierDismissable: true,
      ),
    );
  }

  Future<void> _logOutConfirmWidget(BuildContext context) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'logoutConfirmation'.translate(context),
        onAccept: () async {
          await HiveUtils.logoutUser(context, onLogout: () {});
        },
        content: CustomText(
          'areYouSureToLogout'.translate(context),
          textAlign: TextAlign.center,
        ),
        acceptButtonName: 'logoutBtnLbl'.translate(context),
        acceptTextColor: context.color.buttonColor,
        cancelTextColor: context.color.textColorDark,
        svgImagePath: AppIcons.logoutIllustration,
        isAcceptContainesPush: true,
        barrierDismissable: true,
      ),
    );
  }

  Widget _divider(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Container(height: 1, color: context.color.borderColor),
  );

  @override
  Widget build(BuildContext context) {
    final isGuest = GuestChecker.value;
    final role = RoleScope.of(context);
    final languageLoader =
        context.watch<LanguageCubit>().state as LanguageLoader;
    final langCode = languageLoader.languageCode.toString().toUpperCase();

    final currentTheme = context.watch<AppThemeCubit>().state;
    var currentThemeLabel = 'systemDefault';
    if (currentTheme == ThemeMode.light) {
      currentThemeLabel = 'lightTheme';
    } else if (currentTheme == ThemeMode.dark) {
      currentThemeLabel = 'darkTheme';
    }

    final chevronTrailing = CustomImage(
      imageUrl: AppIcons.arrowRight,
      height: 16.rh(context),
      matchTextDirection: true,
      fit: .contain,
      color: context.color.textLightColor,
    );

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'preferencesSettings'.translate(context),
      ),
      body: BlocListener<DeleteAccountCubit, DeleteAccountState>(
        listener: (context, state) async {
          if (state is AccountDeleted) {
            context.read<UserDetailsCubit>().clear();
            if (ActiveRoleManager.isAgent) {
              await ActiveRoleManager.switchToUser(context);
            }
            await HiveUtils.setIsGuest();
            GuestChecker.set('profile_screen', isGuest: true);
            await Navigator.pushReplacementNamed(context, Routes.main);
          }
        },
        child: SingleChildScrollView(
          physics: Constant.scrollPhysics,
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: context.color.borderColor),
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Country (Fetched from Backend Country API)
                ProfileTile(
                  title: 'country'.translate(context),
                  onTap: () async {
                    // The sheet already persists the country, switches the
                    // language and refreshes the app data, so only rebuild here.
                    final selected = await CountrySelectionBottomSheet.show(
                      context,
                    );
                    if (selected != null && mounted) {
                      setState(() {});
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlocBuilder<FetchCountriesCubit, FetchCountriesState>(
                        builder: (context, state) {
                          final selectedId =
                              HiveUtils.getSelectedCountryId() ??
                              AppSettings.currentCountryId;
                          final selectedName =
                              HiveUtils.getSelectedCountryName();

                          final countries = state is FetchCountriesSuccess
                              ? state.countries
                              : context.read<FetchCountriesCubit>().countries;
                          String? displayName;

                          if (selectedName?.toLowerCase() == 'all' ||
                              (selectedId.isEmpty &&
                                  (selectedName == null ||
                                      selectedName.isEmpty))) {
                            displayName = 'allCountries'.translate(context);
                          } else if (selectedId.isNotEmpty) {
                            final match = countries.where(
                              (c) => c.id?.toString() == selectedId,
                            );
                            if (match.isNotEmpty) {
                              displayName = match.first.name;
                            }
                          }

                          if (displayName == null || displayName.isEmpty) {
                            if (selectedName != null &&
                                selectedName.trim().isNotEmpty) {
                              final match = countries.where(
                                (c) =>
                                    c.name?.toLowerCase() ==
                                    selectedName.trim().toLowerCase(),
                              );
                              if (match.isNotEmpty) {
                                displayName = match.first.name;
                              } else {
                                displayName = selectedName.trim();
                              }
                            }
                          }

                          return CustomText(
                            (displayName != null && displayName.isNotEmpty)
                                ? displayName
                                : 'allCountries'.translate(context),
                            color: context.color.textLightColor,
                            fontSize: context.font.sm,
                          );
                        },
                      ),
                      SizedBox(width: 8.rw(context)),
                      chevronTrailing,
                    ],
                  ),
                ),
                _divider(context),

                // 2. Language
                ProfileTile(
                  title: 'language'.translate(context),
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: context.color.secondaryColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) =>
                          const LanguageSelectionBottomSheet(),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        langCode,
                        color: context.color.textLightColor,
                        fontSize: context.font.sm,
                      ),
                      SizedBox(width: 8.rw(context)),
                      chevronTrailing,
                    ],
                  ),
                ),
                _divider(context),

                // 3. Theme
                ProfileTile(
                  title: 'theme'.translate(context),
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: context.color.secondaryColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => const ThemeSelectionBottomSheet(),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        currentThemeLabel.translate(context),
                        color: context.color.textLightColor,
                        fontSize: context.font.sm,
                      ),
                      SizedBox(width: 8.rw(context)),
                      chevronTrailing,
                    ],
                  ),
                ),

                // 4. Personalized Feed (visible only for non-agent role)
                if (role != ActiveRole.agent) ...[
                  _divider(context),
                  ProfileTile(
                    title: 'personalizedFeed'.translate(context),
                    onTap: () async {
                      await GuestChecker.check(
                        onNotGuest: () async {
                          await Navigator.pushNamed(
                            context,
                            Routes.personalizedPropertyScreen,
                            arguments: {'type': PersonalizedVisitType.normal},
                          );
                        },
                      );
                    },
                    trailing: chevronTrailing,
                  ),
                ],

                // 5. Logout (visible when logged in)
                if (!isGuest) ...[
                  _divider(context),
                  ProfileTile(
                    title: 'logout'.translate(context),
                    onTap: () async {
                      await _logOutConfirmWidget(context);
                    },
                    trailing: chevronTrailing,
                  ),
                ],

                // 6. Delete Account (only visible for user role when logged in)
                if (!isGuest && role != ActiveRole.agent) ...[
                  _divider(context),
                  ProfileTile(
                    title: 'deleteAccount'.translate(context),
                    onTap: () async {
                      if (AppSettings.isDemoModeOn &&
                          (HiveUtils.getUserDetails().isDemoUser ?? false)) {
                        HelperUtils.showSnackBarMessage(
                          context,
                          'thisActionNotValidDemo',
                          type: .error,
                        );
                        return;
                      }
                      await _deleteConfirmWidget(context);
                    },
                    trailing: chevronTrailing,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
