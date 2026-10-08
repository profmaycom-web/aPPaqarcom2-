import 'package:ebroker/data/cubits/appointment/get/fetch_agent_previous_appointments_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_agent_time_schedules_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_agent_upcoming_appointments_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_booking_preferences_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_user_previous_appointments_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_user_upcoming_appointments_cubit.dart';
import 'package:ebroker/data/cubits/property/report/property_report_cubit.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/data/repositories/auth_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/agent_status_card.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/profile_menu.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/user_verification_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';

/// Shared scrollable body used by both AgentProfileScreen and
/// UserProfileScreen. All action logic (logout, delete, share, rate) lives
/// here so neither role-specific screen duplicates it.
class ProfileBody extends StatefulWidget {
  const ProfileBody({required this.isGuest, super.key});

  /// Passed down from the parent router so the body reacts to guest-state
  /// changes without owning its own listener.
  final bool isGuest;

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<FetchSystemSettingsCubit>();
    if (!const bool.fromEnvironment('force-disable-demo-mode')) {
      AppSettings.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) as bool? ?? false;
    }
    if (settings.state is FetchSystemSettingsInProgress) {
      return SliverToBoxAdapter(child: _buildProfileLoadingShimmer(context));
    }
    final role = RoleScope.of(context);
    final isAgent = role == ActiveRole.agent;
    return SliverList(
      delegate: SliverChildListDelegate([
        if (!widget.isGuest) ...[
          if (!isAgent && !HiveUtils.isUserVerified()) ...[
            const UserVerificationCard(),
            SizedBox(height: 16.rh(context)),
          ],
          const AgentStatusCard(),
          SizedBox(height: 16.rh(context)),
        ],
        ProfileMenu(
          isGuest: widget.isGuest,
          onShareApp: _shareApp,
          onRateUs: _rateUs,
          onDeleteAccount: () => unawaited(
            _deleteConfirmWidget(
              'deleteProfileMessageTitle'.translate(context),
              'deleteProfileMessageContent'.translate(context),
              true,
            ),
          ),
          onLogout: _logOutConfirmWidget,
        ),
        SizedBox(height: 48.rh(context)),
      ]),
    );
  }

  Widget _buildProfileLoadingShimmer(BuildContext context) {
    return SingleChildScrollView(
      physics: Constant.scrollPhysics,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomShimmer(height: MediaQuery.of(context).size.height * 0.13),
            SizedBox(height: 16.rh(context)),
            CustomShimmer(height: MediaQuery.of(context).size.height),
            SizedBox(height: 16.rh(context)),
            CustomShimmer(height: MediaQuery.of(context).size.height * 0.07),
          ],
        ),
      ),
    );
  }

  // ── Action methods ─────────────────────────────────────────────────────────

  Future<void> _shareApp() async {
    try {
      if (Platform.isAndroid) {
        await SharePlus.instance.share(
          ShareParams(
            text:
                '${Constant.appName}\n${AppSettings.playstoreURLAndroid}\n${'shareApp'.translate(context)}',
            subject: Constant.appName,
          ),
        );
      } else if (Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(
            text:
                '${Constant.appName}\n${AppSettings.appstoreURLios}\n${'shareApp'.translate(context)}',
            subject: Constant.appName,
          ),
        );
      }
    } on Exception catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: .error,
      );
    }
  }

  Future<void> _rateUs() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.openStoreListing();
    }
  }

  Future<void> _logOutConfirmWidget() async {
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
        title: 'confirmLogoutTitle'.translate(context),
        onAccept: () async {
          try {
            reportedProperties.clear();
            final L = HiveUtils.getUserLoginType();
            Constant.interestedPropertyIds.clear();
            context.read<UserDetailsCubit>().clear();
            context.read<LikedPropertiesCubit>().clear();
            context.read<LoadChatMessagesCubit>().clear();
            context.read<GetChatListCubit>().clear();
            context.read<FetchMyPropertiesCubit>().clear();
            context.read<FetchMyProjectsCubit>().clear();
            _clearAppointmentCubits();
            if (L == LoginType.google || L == LoginType.apple) {
              await GoogleSignIn.instance.signOut();
            }
            await HiveUtils.logoutUser(
              context,
              onLogout: () {},
              isRedirect: false,
            );
            if (ActiveRoleManager.isAgent) {
              await ActiveRoleManager.switchToUser(context);
            }
            await HiveUtils.setIsGuest();
            GuestChecker.set('profile_screen', isGuest: true);
            await Navigator.pushReplacementNamed(context, Routes.main);
          } on Exception catch (_) {}
        },
        cancelTextColor: context.color.textColorDark,
        svgImagePath: AppIcons.logoutIllustration,
        acceptTextColor: context.color.buttonColor,
        barrierDismissable: true,
        content: Column(
          mainAxisSize: .min,
          children: [
            CustomText(
              'confirmLogOutMsg'.translate(context),
              textAlign: .center,
            ),
            if (isAgent) ...[
              CustomText(
                'confirmLogoutAgentMessage'.translate(context),
                textAlign: .center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConfirmWidget(
    String title,
    String desc,
    dynamic callDel,
  ) async {
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
        title: title,
        onAccept: () async {
          final L = HiveUtils.getUserLoginType();
          if (callDel as bool? ?? false) {
            try {
              reportedProperties.clear();
              _clearAppointmentCubits();
              if (L == LoginType.phone &&
                  AppSettings.otpServiceProvider == 'firebase') {
                await FirebaseAuth.instance.currentUser?.delete();
              }
              if (L == LoginType.apple || L == LoginType.google) {
                await FirebaseAuth.instance.currentUser?.delete();
              }
              await context.read<DeleteAccountCubit>().deleteUserAccount(
                context,
              );
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
          } else {
            await HiveUtils.logoutUser(context, onLogout: () {});
          }
        },
        content: Column(
          mainAxisSize: .min,
          children: [
            CustomText(desc, textAlign: .center),
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

  void _clearAppointmentCubits() {
    context.read<FetchBookingPreferencesCubit>().clear();
    context.read<FetchAgentUpcomingAppointmentsCubit>().clear();
    context.read<FetchAgentPreviousAppointmentsCubit>().clear();
    context.read<FetchUserUpcomingAppointmentsCubit>().clear();
    context.read<FetchUserPreviousAppointmentsCubit>().clear();
    context.read<FetchAgentTimeSchedulesCubit>().clear();
  }
}
