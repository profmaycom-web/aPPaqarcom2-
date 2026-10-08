import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/data/cubits/auth/get_user_data_cubit.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/profile_header.dart';
import 'package:ebroker/ui/screens/profile/widgets/profile_body.dart';
import 'package:material_ui/material_ui.dart';

/// Role display is read from the enclosing [RoleScope] — the user scaffold
/// provides [ActiveRole.user], the agent dashboard provides [ActiveRole.agent].
/// Each instance keeps its parent's role during role-switch animations so the
/// outgoing tree preserves its look while the incoming tree shows the new role.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin<ProfileScreen> {
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<FetchSystemSettingsCubit>();
    isGuest = GuestChecker.value;
    GuestChecker.listen().addListener(_onGuestChanged);
    if (!const bool.fromEnvironment('force-disable-demo-mode')) {
      AppSettings.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) as bool? ?? false;
    }
    unawaited(
      Future.microtask(() async {
        if (!GuestChecker.value &&
            mounted &&
            context.read<UserDetailsCubit>().state.user == null) {
          await context.read<GetUserDataCubit>().getUserData();
        }
      }),
    );
  }

  void _onGuestChanged() {
    if (mounted) setState(() => isGuest = GuestChecker.value);
  }

  @override
  void dispose() {
    GuestChecker.listen().removeListener(_onGuestChanged);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch these states to ensure the screen updates live when they change
    final userDetailsState = context.watch<UserDetailsCubit>().state;
    final getUserDataState = context.watch<GetUserDataCubit>().state;
    final agentProfileState = context.watch<AgentProfileCubit>().state;

    final role = RoleScope.of(context);
    final isAgent = role == ActiveRole.agent;
    if (isAgent) {
      final agentCubit = context.read<AgentProfileCubit>();
      if (agentCubit.state is! AgentProfileSuccess &&
          agentCubit.state is! AgentProfileInProgress) {
        unawaited(agentCubit.fetchAgentProfile());
      }
    }
    final statusBarIconBrightness = context.color.brightness == .dark
        ? Brightness.light
        : Brightness.dark;
    final statusBarColor = isAgent
        ? Colors.transparent
        : context.color.tertiaryColor;
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: statusBarIconBrightness,
        statusBarBrightness: context.color.brightness,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarColor: context.color.secondaryColor,
        systemNavigationBarIconBrightness: context.color.brightness == .light
            ? .dark
            : .light,
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
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
            child: CustomRefreshIndicator(
              onRefresh: () async {
                if (!mounted) return;
                await context.read<FetchSystemSettingsCubit>().fetchSettings(
                  isAnonymous: GuestChecker.value,
                );
                if (!mounted) return;
                await context.read<GetApiKeysCubit>().fetch();
                if (!mounted) return;
                if (!GuestChecker.value) {
                  await context.read<GetUserDataCubit>().getUserData();
                  if (!mounted) return;
                  if (isAgent) {
                    await context.read<AgentProfileCubit>().fetchAgentProfile();
                  }
                }
              },
              child: Builder(
                builder: (context) {
                  // Show shimmer if user details are not yet loaded and user is fetching them
                  if (!isGuest &&
                      getUserDataState is GetUserDataInProgress &&
                      userDetailsState.user == null) {
                    return _buildProfileLoadingShimmer(context);
                  }

                  // Show error if user data fetch failed and there are no cached details
                  if (!isGuest &&
                      getUserDataState is GetUserDataFailure &&
                      userDetailsState.user == null) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.7,
                        child: Center(
                          child: SomethingWentWrong(
                            errorMessage: getUserDataState.errorMessage,
                          ),
                        ),
                      ),
                    );
                  }

                  return CustomScrollView(
                    physics: Constant.scrollPhysics,
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _ProfileStickyHeaderDelegate(
                          isAgent: isAgent,
                          isGuest: isGuest,
                          headerHeight: 142.rh(context),
                          bannerHeight: isAgent
                              ? 215.rh(context)
                              : 124.rh(context),
                          overlap: 64,
                          backgroundColor: context.color.primaryColor,
                          userDetailsState: userDetailsState,
                          agentProfileState: agentProfileState,
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.rw(context),
                        ),
                        sliver: ProfileBody(isGuest: isGuest),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileLoadingShimmer(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomShimmer(height: MediaQuery.sizeOf(context).height * 0.13),
            SizedBox(height: 16.rh(context)),
            CustomShimmer(height: MediaQuery.sizeOf(context).height),
          ],
        ),
      ),
    );
  }
}

class _ProfileStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProfileStickyHeaderDelegate({
    required this.isAgent,
    required this.isGuest,
    required this.headerHeight,
    required this.bannerHeight,
    required this.overlap,
    required this.backgroundColor,
    required this.userDetailsState,
    required this.agentProfileState,
  });

  final bool isAgent;
  final bool isGuest;
  final double headerHeight;
  final double bannerHeight;
  final double overlap;
  final Color backgroundColor;
  final UserDetailsState userDetailsState;
  final AgentProfileState agentProfileState;

  @override
  double get minExtent => headerHeight;

  @override
  double get maxExtent => bannerHeight + headerHeight - overlap;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bannerVisibleBottom = (bannerHeight - shrinkOffset).clamp(
      0.0,
      double.infinity,
    );
    final headerTop = (bannerHeight - overlap - shrinkOffset).clamp(
      0.0,
      double.infinity,
    );
    return ClipRect(
      child: Stack(
        clipBehavior: .none,
        children: [
          Positioned(
            top: bannerVisibleBottom,
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(color: backgroundColor),
          ),
          Positioned(
            top: -shrinkOffset,
            left: 0,
            right: 0,
            child: SizedBox(
              height: bannerHeight,
              child: isAgent
                  ? BlocBuilder<AgentProfileCubit, AgentProfileState>(
                      builder: (context, state) {
                        final url = state is AgentProfileSuccess
                            ? state.agentProfile.agentBanner ?? ''
                            : '';
                        return CustomImage(
                          imageUrl: url,
                          width: double.infinity,
                          height: bannerHeight,
                        );
                      },
                    )
                  : ColoredBox(
                      color: context.color.tertiaryColor,
                    ),
            ),
          ),
          Positioned(
            top: headerTop + 16.rh(context),
            left: 0,
            right: 0,
            child: ProfileHeader(
              isGuest: isGuest,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileStickyHeaderDelegate oldDelegate) {
    return oldDelegate.isAgent != isAgent ||
        oldDelegate.isGuest != isGuest ||
        oldDelegate.headerHeight != headerHeight ||
        oldDelegate.bannerHeight != bannerHeight ||
        oldDelegate.overlap != overlap ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.userDetailsState != userDetailsState ||
        oldDelegate.agentProfileState != agentProfileState;
  }
}
