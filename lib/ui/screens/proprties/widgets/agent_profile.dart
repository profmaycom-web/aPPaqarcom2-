import 'dart:async';

import 'package:ebroker/data/cubits/agents/fetch_property_cubit.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_details_screen.dart';
import 'package:ebroker/ui/screens/stories/widgets/story_ring_avatar.dart';
import 'package:ebroker/ui/screens/widgets/custom_open_container.dart';
import 'package:ebroker/ui/screens/widgets/follow_button.dart';
import 'package:ebroker/ui/screens/widgets/verified_badge.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/follow_manager.dart';
import 'package:ebroker/utils/guest_checker.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class AgentProfileWidget extends StatefulWidget {
  const AgentProfileWidget({
    required this.addedBy,
    required this.profileImage,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.isAgent,
    required this.isAgentVerified,
    required this.isUserVerified,
    required this.propertiesCount,
    required this.projectsCount,
    required this.canScheduleAppointment,
    this.onScheduleAppointment,
    this.agentProfile,
    this.followersCount,
    this.isFollowing = false,
    this.roleContext,
    this.popOnTap = false,
    super.key,
  });
  final String addedBy;
  final String profileImage;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isAgent;
  final bool isAgentVerified;
  final bool isUserVerified;
  final String propertiesCount;
  final String projectsCount;
  final bool canScheduleAppointment;
  final Future<void> Function()? onScheduleAppointment;
  final AgentProfileModel? agentProfile;
  final String? followersCount;
  final bool isFollowing;
  final String? roleContext;
  final bool popOnTap;

  @override
  State<AgentProfileWidget> createState() => _AgentProfileWidgetState();
}

class _AgentProfileWidgetState extends State<AgentProfileWidget> {
  bool? isAdmin;
  bool _isNavigating = false;
  bool _isFollowing = false;
  bool _initialFollowingState = false;
  bool _isFollowingInitialized = false;
  String? _fetchedFollowersCount;
  int _followerDelta = 0;
  StreamSubscription<FollowChangeEvent>? _followSubscription;

  String get _name =>
      (widget.roleContext == 'agent' ? widget.agentProfile?.agentName : null) ??
      widget.name;
  String get _email =>
      (widget.roleContext == 'agent'
          ? widget.agentProfile?.agentEmail
          : null) ??
      widget.email;
  String get _profileImage =>
      (widget.roleContext == 'agent'
          ? widget.agentProfile?.agentProfilePhoto
          : null) ??
      widget.profileImage;

  int get targetId {
    final addedById = int.tryParse(widget.addedBy) ?? 0;
    final customerId = widget.agentProfile?.customerId;
    final isAdm =
        isAdmin ?? (widget.isAdmin || widget.addedBy == '0' || customerId == 0);
    return isAdm ? 0 : (customerId ?? addedById);
  }

  @override
  void initState() {
    super.initState();
    final addedById = int.tryParse(widget.addedBy) ?? 0;
    final customerId = widget.agentProfile?.customerId;
    isAdmin = widget.isAdmin || widget.addedBy == '0' || customerId == 0;
    final isAdm = isAdmin ?? false;
    final targetId = isAdm ? 0 : (customerId ?? addedById);
    final secId = isAdm ? null : (customerId != null ? addedById : null);

    if (widget.isFollowing) {
      FollowManager.registerFollowStatus(
        targetId,
        isFollowing: true,
        secondaryId: secId,
        isAdmin: isAdm,
      );
    }

    final initialApiFollow = widget.isFollowing;
    final resolvedStatus = FollowManager.isFollowingStatus(
      targetId,
      initialValue: initialApiFollow,
      secondaryId: secId,
      isAdmin: isAdm,
    );

    _isFollowing = resolvedStatus;
    _initialFollowingState = initialApiFollow;
    _isFollowingInitialized = true;

    if (_isFollowing && !_initialFollowingState) {
      _followerDelta = 1;
    } else if (!_isFollowing && _initialFollowingState) {
      _followerDelta = -1;
    } else {
      _followerDelta = 0;
    }

    final initialCount =
        (widget.followersCount != null &&
            widget.followersCount!.isNotEmpty &&
            widget.followersCount != '0')
        ? widget.followersCount
        : (widget.agentProfile?.totalFollowers != null &&
              widget.agentProfile!.totalFollowers!.isNotEmpty &&
              widget.agentProfile!.totalFollowers != '0')
        ? widget.agentProfile?.totalFollowers
        : FollowManager.getFollowersCount(targetId);

    if (initialCount != null &&
        initialCount.isNotEmpty &&
        initialCount != '0') {
      _fetchedFollowersCount = initialCount;
      FollowManager.registerFollowersCount(targetId, initialCount);
    } else if (targetId > 0 || isAdm) {
      unawaited(_fetchFollowersAsync(targetId, isAdm));
    }

    _followSubscription = FollowManager.onFollowChanged.listen((event) {
      final matchesAdmin =
          (isAdm || event.agentId == 0) &&
          (isAdm || addedById == 0 || customerId == 0);
      final matchesAgent =
          !isAdm &&
          (event.agentId == addedById ||
              (customerId != null && event.agentId == customerId));

      if ((matchesAdmin || matchesAgent) && mounted) {
        setState(() {
          _isFollowing = event.isFollowing;
          if (_isFollowing && !_initialFollowingState) {
            _followerDelta = 1;
          } else if (!_isFollowing && _initialFollowingState) {
            _followerDelta = -1;
          } else {
            _followerDelta = 0;
          }
        });
      }
    });
  }

  Future<void> _fetchFollowersAsync(int targetId, bool isAdm) async {
    final count = await FollowManager.fetchFollowersCount(
      targetId,
      isAdmin: isAdm,
    );
    if (count != null && count.isNotEmpty && mounted) {
      setState(() {
        _fetchedFollowersCount = count;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AgentProfileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      setState(() {
        _isFollowing = widget.isFollowing;
        _initialFollowingState = widget.isFollowing;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_followSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFollowingInitialized) {
      _isFollowingInitialized = true;
      _isFollowing = widget.isFollowing;
      _initialFollowingState = widget.isFollowing;
    }
    final canNavigate =
        widget.isAdmin || (widget.isAgent && widget.roleContext == 'agent');
    final isUser =
        widget.roleContext == 'user' ||
        (!widget.isAdmin && !widget.isAgent && widget.addedBy != '0');

    return BlocBuilder<FetchAgentsPropertyCubit, FetchAgentsPropertyState>(
      builder: (context, state) {
        return IntrinsicHeight(
          child: CustomOpenContainer(
            closedShape: const RoundedRectangleBorder(),
            closedBuilder: (context, openContainer) {
              final storyAgentId =
                  widget.agentProfile?.customerId ??
                  (widget.isAdmin ? 0 : null);
              final avatar = Container(
                width: 58.rw(context),
                height: 58.rh(context),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: isUser
                      ? null
                      : BorderRadius.circular(6.rw(context)),
                  shape: isUser ? BoxShape.circle : BoxShape.rectangle,
                  border: isUser
                      ? null
                      : Border.all(
                          color: context.color.tertiaryColor,
                          width: 1.5,
                        ),
                ),
                child: Hero(
                  tag: 'agent-hero-${widget.addedBy}',
                  child: CustomImage(
                    imageUrl: _profileImage,
                  ),
                ),
              );

              Future<void> handleNavigate() async {
                if (!canNavigate) return;
                if (widget.popOnTap) {
                  return Navigator.of(context).pop();
                }
                if (_isNavigating) return;
                final hasInternet = await HelperUtils.checkInternet();

                if (!hasInternet) {
                  return HelperUtils.showSnackBarMessage(
                    context,
                    'noInternet',
                    type: .error,
                  );
                }
                setState(() {
                  _isNavigating = true;
                });
                openContainer();
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _isNavigating = false;
                    });
                  }
                });
              }

              final showAppointmentButton =
                  widget.canScheduleAppointment &&
                  widget.onScheduleAppointment != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: handleNavigate,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (storyAgentId != null)
                          StoryRingAvatar(
                            agentId: storyAgentId,
                            borderRadius: isUser ? null : 6.rw(context),
                            child: avatar,
                          )
                        else
                          avatar,
                        SizedBox(width: 10.rw(context)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: CustomText(
                                            _name,
                                            fontWeight: FontWeight.w600,
                                            fontSize: context.font.sm,
                                            maxLines: 1,
                                          ),
                                        ),
                                        if (widget.isAgentVerified ||
                                            widget.isUserVerified ||
                                            widget.isAdmin) ...[
                                          SizedBox(width: 4.rw(context)),
                                          VerifiedBadge.conditional(
                                            isAgentVerified:
                                                widget.isAgentVerified,
                                            isUserVerified:
                                                widget.isUserVerified,
                                            isAdmin: widget.isAdmin,
                                            roleContext: widget.roleContext,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isUser && _email.isNotEmpty) ...[
                                SizedBox(height: 2.rh(context)),
                                CustomText(
                                  _email,
                                  fontSize: context.font.xs,
                                  color: context.color.textColorDark.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w400,
                                  maxLines: 1,
                                ),
                              ],
                              if (!isUser) ...[
                                SizedBox(height: 2.rh(context)),
                                Row(
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
                                        final fc =
                                            _fetchedFollowersCount ??
                                            (widget.followersCount != null &&
                                                    widget
                                                        .followersCount!
                                                        .isNotEmpty
                                                ? widget.followersCount
                                                : FollowManager.getFollowersCount(
                                                    targetId,
                                                  ));
                                        final apFc = widget
                                            .agentProfile
                                            ?.totalFollowers
                                            ?.toString();
                                        final rawFollowers =
                                            (fc != null &&
                                                fc.isNotEmpty &&
                                                fc != '0')
                                            ? fc
                                            : (apFc != null &&
                                                  apFc.isNotEmpty &&
                                                  apFc != '0')
                                            ? apFc
                                            : null;
                                        final baseFollowers =
                                            (rawFollowers == null ||
                                                rawFollowers.isEmpty)
                                            ? 0
                                            : int.tryParse(rawFollowers) ?? 0;
                                        var totalFollowers =
                                            (baseFollowers + _followerDelta)
                                                .clamp(0, 999999999);
                                        if (_isFollowing &&
                                            totalFollowers < 1) {
                                          totalFollowers = 1;
                                        }
                                        final formattedCount =
                                            HelperUtils.formatFollowerCount(
                                              totalFollowers,
                                            );
                                        return CustomText(
                                          '$formattedCount - ${'followers'.translate(context)}',
                                          fontSize: 12,
                                          color: context.color.secondary,
                                          fontWeight: FontWeight.w700,
                                        );
                                      },
                                    ),
                                    if (canNavigate) ...[
                                      const Spacer(),
                                      CustomImage(
                                        imageUrl: AppIcons.arrowRightSolid,
                                        height: 16.rh(context),
                                        width: 16.rw(context),
                                        matchTextDirection: true,
                                        color: context.color.textColorDark
                                            .withValues(alpha: 0.8),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              SizedBox(height: 6.rh(context)),
                              Row(
                                children: [
                                  CustomText(
                                    '${widget.propertiesCount.isEmpty ? '0' : widget.propertiesCount} ${'properties'.translate(context)}',
                                    fontSize: 13,
                                    color: context.color.textColorDark
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.rw(context),
                                    ),
                                    child: CustomText(
                                      '|',
                                      fontSize: 13,
                                      color: context.color.textLightColor,
                                    ),
                                  ),
                                  CustomText(
                                    '${widget.projectsCount.isEmpty ? '0' : widget.projectsCount} ${'projects'.translate(context)}',
                                    fontSize: 13,
                                    color: context.color.textColorDark
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUser) ...[
                    SizedBox(height: 10.rh(context)),
                    Row(
                      children: [
                        if (showAppointmentButton) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await widget.onScheduleAppointment?.call();
                              },
                              child: Container(
                                height: 36.rh(context),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.color.tertiaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: CustomText(
                                  'Appointment'.translate(context),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: context.font.xs,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.rw(context)),
                        ],
                        Expanded(
                          child: FollowButton(
                            height: 36.rh(context),
                            isFollowing: _isFollowing,
                            onTap: () async {
                              await GuestChecker.check(
                                onNotGuest: () async {
                                  final isAdm =
                                      widget.isAdmin || widget.addedBy == '0';
                                  final addedById =
                                      int.tryParse(widget.addedBy) ?? 0;
                                  final customerId =
                                      widget.agentProfile?.customerId;
                                  final agentId = isAdm
                                      ? 0
                                      : (customerId ?? addedById);
                                  final secId = isAdm
                                      ? null
                                      : (customerId != null ? addedById : null);
                                  try {
                                    final newStatus =
                                        await FollowManager.toggleFollow(
                                          agentId,
                                          secondaryId: secId,
                                          isAdmin: isAdm,
                                        );
                                    if (mounted) {
                                      setState(() {
                                        _isFollowing = newStatus;
                                        if (_isFollowing &&
                                            !_initialFollowingState) {
                                          _followerDelta = 1;
                                        } else if (!_isFollowing &&
                                            _initialFollowingState) {
                                          _followerDelta = -1;
                                        } else {
                                          _followerDelta = 0;
                                        }
                                      });
                                    }
                                  } on Object catch (e) {
                                    if (context.mounted) {
                                      HelperUtils.showSnackBarMessage(
                                        context,
                                        e.toString(),
                                        type: MessageType.error,
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
            openBuilder: (context, closeContainer) {
              final isAdm = isAdmin ?? (widget.addedBy == '0');
              final targetAgentId = isAdm
                  ? '0'
                  : (widget.agentProfile?.customerId?.toString() ??
                        widget.addedBy);
              return AgentDetailsScreen.buildWithProviders(
                agentID: targetAgentId,
                isAdmin: isAdm,
                heroTag: 'agent-hero-${widget.addedBy}',
                heroImageUrl: _profileImage,
                isFollowing: _isFollowing,
              );
            },
          ),
        );
      },
    );
  }
}
