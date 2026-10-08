import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/stories/widgets/story_ring_avatar.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({
    required this.isGuest,
    // required this.followersCount,
    // required this.agentProfile,
    super.key,
  });
  //final String? followersCount;
  final bool isGuest;
  //final AgentProfileModel? agentProfile;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.isGuest) {
        final role = RoleScope.of(context);
        if (role == ActiveRole.agent) {
          unawaited(context.read<AgentProfileCubit>().fetchAgentProfile());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserDetailsCubit>().state.user;
    final role = RoleScope.of(context);
    final isAgent = role == ActiveRole.agent;
    final agentState = context.watch<AgentProfileCubit>().state;
    final agentProfile = agentState is AgentProfileSuccess
        ? agentState.agentProfile
        : null;

    final displayName = isAgent
        ? (agentProfile?.agentName?.isEmpty == false
              ? agentProfile?.agentName
              : null)
        : user?.name;
    final displayEmail = isAgent
        ? (agentProfile?.agentEmail?.isEmpty == false
              ? agentProfile?.agentEmail
              : null)
        : user?.email;
    final displayProfile = isAgent
        ? agentProfile?.agentProfilePhoto
        : user?.profile;

    final username = widget.isGuest
        ? 'anonymous'.translate(context)
        : displayName?.firstUpperCase() ?? '';
    final email = widget.isGuest
        ? 'notLoggedIn'.translate(context)
        : displayEmail ?? '';

    return Container(
      padding: .all(12.rw(context)),
      margin: .symmetric(horizontal: 16.rw(context)),
      decoration: BoxDecoration(
        border: Border.all(color: context.color.borderColor, width: 1.5),
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12.rw(context)),
      ),
      child: Row(
        children: [
          if (isAgent && !widget.isGuest)
            StoryRingAvatar(
              agentId: int.tryParse(HiveUtils.getUserId() ?? ''),
              borderRadius: 8.rw(context),
              showAddButton: true,
              onAddTap: () async {
                await Navigator.pushNamed(
                  context,
                  Routes.selectStoryListing,
                );
              },
              child: _profileImgWidget(
                context,
                (displayProfile ?? '').trim(),
                isAgent,
              ),
            )
          else
            _profileImgWidget(
              context,
              (displayProfile ?? '').trim(),
              isAgent,
            ),
          SizedBox(width: 12.rw(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  spacing: 4.rw(context),
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: CustomText(
                              username,
                              color: context.color.inverseSurface,
                              fontSize: context.font.md,
                              fontWeight: .w700,
                              maxLines: 2,
                            ),
                          ),
                          SizedBox(width: 6.rw(context)),
                          if (!widget.isGuest)
                            _verifiedBadge(context, isAgent: isAgent),
                        ],
                      ),
                    ),

                    _buildEditOrLogin(context),
                  ],
                ),

                CustomText(
                  email,
                  color: context.color.textColorDark,
                  fontSize: context.font.xs,
                  maxLines: 1,
                ),
                if (isAgent && !widget.isGuest) ...[
                  SizedBox(height: 4.rh(context)),
                  GestureDetector(
                    onTap: () async {
                      await HelperUtils.goToNextPage(
                        Routes.agentFollowersScreen,
                        context,
                        false,
                      );
                      if (mounted && isAgent) {
                        unawaited(
                          context.read<AgentProfileCubit>().fetchAgentProfile(),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        CustomImage(
                          imageUrl: AppIcons.following,
                          height: 14.rh(context),
                          width: 14.rw(context),
                          color: context.color.tertiaryColor,
                        ),
                        SizedBox(width: 4.rw(context)),
                        Builder(
                          builder: (context) {
                            final rawFollowers = agentProfile?.totalFollowers
                                ?.toString();
                            final baseFollowers =
                                (rawFollowers == null || rawFollowers.isEmpty)
                                ? 0
                                : int.tryParse(rawFollowers) ?? 0;
                            final formattedCount =
                                HelperUtils.formatFollowerCount(baseFollowers);
                            return CustomText(
                              '$formattedCount ${'followers'.translate(context)}',
                              fontSize: context.font.xs,
                              color: context.color.tertiaryColor,
                              fontWeight: FontWeight.w500,
                            );
                          },
                        ),
                        const Spacer(),
                        CustomImage(
                          imageUrl: AppIcons.arrowRightSolid,
                          height: 12.rh(context),
                          width: 12.rw(context),
                          color: context.color.tertiaryColor,
                          matchTextDirection: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedBadge(BuildContext context, {required bool isAgent}) {
    final user = context.watch<UserDetailsCubit>().state.user;
    final isVerified = isAgent
        ? (user?.isAgentVerified ?? HiveUtils.isAgentVerified())
        : (user?.isUserVerified ?? HiveUtils.isUserVerified());

    if (!isVerified) {
      return const SizedBox.shrink();
    }

    return VerifiedBadge.fromType(
      isAgent: isAgent,
    );
  }

  Widget _buildEditOrLogin(BuildContext context) {
    return widget.isGuest
        ? Container(
            child: UiUtils.buildButton(
              context,
              height: 32.rh(context),
              fontSize: context.font.xs,
              showElevation: false,
              buttonTitle: 'login'.translate(context),
              buttonColor: context.color.secondaryColor,
              textColor: context.color.textLightColor,
              autoWidth: true,
              border: BorderSide(color: context.color.borderColor),
              onPressed: () async {
                await Navigator.pushReplacementNamed(
                  context,
                  Routes.login,
                );
              },
            ),
          )
        : GestureDetector(
            onTap: () async {
              final route = RoleScope.of(context) == ActiveRole.agent
                  ? Routes.editAgentProfile
                  : Routes.editProfile;
              await HelperUtils.goToNextPage(
                route,
                context,
                false,
                args: {'from': 'profile'},
              );
            },
            child: Container(
              padding: .all(8.rw(context)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.color.textColorDark.withValues(alpha: 0.06),
              ),
              child: Center(
                child: CustomImage(
                  imageUrl: AppIcons.edit,
                  color: context.color.textColorDark,
                  fit: .contain,
                  height: 18.rh(context),
                ),
              ),
            ),
          );
  }

  Widget _profileImgWidget(
    BuildContext context,
    String profileUrl,
    bool isAgent,
  ) {
    return profileUrl.isEmpty
        ? _buildDefaultPersonSVG(context, isAgent)
        : ClipRRect(
            borderRadius: BorderRadius.circular(isAgent ? 8.rw(context) : 999),
            child: CustomImage(
              imageUrl: profileUrl,
              width: 80.rw(context),
              height: 80.rh(context),
            ),
          );
  }

  Widget _buildDefaultPersonSVG(BuildContext context, bool isAgent) {
    return Container(
      width: 80.rw(context),
      height: 80.rh(context),
      decoration: BoxDecoration(
        shape: isAgent ? .rectangle : .circle,
        borderRadius: isAgent ? .all(.circular(8.rw(context))) : null,
        color: context.color.tertiaryColor.withValues(alpha: 0.1),
      ),
      child: FittedBox(
        fit: .none,
        child: CustomImage(
          imageUrl: AppIcons.defaultPersonLogo,
          color: context.color.tertiaryColor,
          width: 32.rw(context),
          height: 32.rh(context),
        ),
      ),
    );
  }
}
