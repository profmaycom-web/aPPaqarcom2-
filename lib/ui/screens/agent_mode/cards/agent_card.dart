import 'package:ebroker/data/model/agent/agent_model.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/customer_data.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/ui/screens/chat/helpers/open_chat_screen.dart';
import 'package:ebroker/utils/whatsapp_helper.dart';
import 'package:material_ui/material_ui.dart';

class AgentCard extends StatefulWidget {
  const AgentCard({
    required this.agent,
    required this.propertyCount,
    required this.name,
    super.key,
    this.width,
    this.isFirst,
    this.showEndPadding,
    this.showActions = false,
    this.showContactButtons = true,
  });

  final AgentModel agent;
  final bool? isFirst;
  final bool? showEndPadding;
  final String name;
  final String propertyCount;
  final double? width;

  /// Shows the follow icon on the banner and the Chat / Appointment
  /// (or WhatsApp, when appointment isn't available) buttons.
  final bool showActions;

  /// Shows the Chat and Appointment / WhatsApp buttons below the card. Only
  /// applies when [showActions] is true.
  final bool showContactButtons;

  @override
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard> {
  /// agent-list doesn't return appointment/mobile info, so cards fetch the
  /// agent details once and share the result across rebuilds and scrolls.
  static final Map<String, Future<CustomerData?>> _agentDataCache = {};

  bool _isNavigating = false;
  late bool _isFollowing;

  /// Null until the backend data needed to decide the buttons has loaded.
  bool? _canBookAppointment;
  bool _canShowWhatsapp = false;
  StreamSubscription<FollowChangeEvent>? _followSubscription;

  @override
  void initState() {
    super.initState();
    final targetId = widget.agent.isAdmin ? 0 : widget.agent.id;
    final initialCount = widget.agent.followersCount?.toString();
    if (initialCount != null && initialCount.isNotEmpty) {
      FollowManager.registerFollowersCount(targetId, initialCount);
    }
    _isFollowing = FollowManager.isFollowingStatus(
      targetId,
      initialValue: widget.agent.isFollowing,
      isAdmin: widget.agent.isAdmin,
    );

    _followSubscription = FollowManager.onFollowChanged.listen((event) {
      if (event.agentId == targetId && mounted) {
        setState(() {
          _isFollowing = event.isFollowing;
        });
      }
    });

    _resolveAppointmentAvailability();
  }

  /// Same rules as the agent details screen: appointment only when the agent
  /// enabled it (and isn't the logged-in user), WhatsApp only when the backend
  /// setting is on and the agent has a mobile number with country code.
  void _resolveAppointmentAvailability() {
    if (!_showContactButtons) return;
    final card = widget.agent;
    final listHasWhatsapp = WhatsappHelper.canShow(
      card.mobile,
      card.mobileCountryCode,
    );
    // Only fetch details when the list response can't answer both questions.
    if (card.hasAppointmentInfo &&
        (listHasWhatsapp || !AppSettings.showWhatsappButton)) {
      _canBookAppointment = card.isAppointmentAvailable;
      _canShowWhatsapp = listHasWhatsapp;
      return;
    }
    _canBookAppointment = null;
    unawaited(
      _fetchAgentData().then((agent) {
        if (!mounted) return;
        setState(() {
          _canBookAppointment =
              agent?.isAppointmentAvailable ??
              (card.hasAppointmentInfo && card.isAppointmentAvailable);
          _canShowWhatsapp =
              listHasWhatsapp ||
              WhatsappHelper.canShow(
                agent?.agentProfile.agentMobile,
                agent?.agentProfile.agentCountryCode,
              );
        });
      }),
    );
  }

  @override
  void didUpdateWidget(covariant AgentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetId = widget.agent.isAdmin ? 0 : widget.agent.id;
    if (oldWidget.agent.followersCount != widget.agent.followersCount &&
        widget.agent.followersCount != null &&
        widget.agent.followersCount!.isNotEmpty) {
      FollowManager.registerFollowersCount(
        targetId,
        widget.agent.followersCount!,
        force: true,
      );
    }
    if (oldWidget.agent.isFollowing != widget.agent.isFollowing) {
      _isFollowing = FollowManager.isFollowingStatus(
        targetId,
        initialValue: widget.agent.isFollowing,
        isAdmin: widget.agent.isAdmin,
      );
    }
    if (oldWidget.agent.id != widget.agent.id ||
        oldWidget.agent.isAdmin != widget.agent.isAdmin ||
        oldWidget.showActions != widget.showActions ||
        oldWidget.showContactButtons != widget.showContactButtons ||
        oldWidget.agent.isAppointmentAvailable !=
            widget.agent.isAppointmentAvailable) {
      _resolveAppointmentAvailability();
    }
  }

  @override
  void dispose() {
    unawaited(_followSubscription?.cancel());
    super.dispose();
  }

  String get _bannerUrl => widget.agent.banner ?? '';

  /// The logged-in user's own card: no follow action, and the contact buttons
  /// show a snackbar instead of opening chat / appointment / WhatsApp.
  bool get _isSelf =>
      !widget.agent.isAdmin &&
      widget.agent.id.toString() == HiveUtils.getUserId();

  bool get _showActions => widget.showActions && !_isSelf;

  bool get _showContactButtons =>
      widget.showActions && widget.showContactButtons;

  /// Returns true (after showing [messageKey]) when the card is the user's own.
  bool _blockSelfAction(String messageKey) {
    if (!_isSelf) return false;
    HelperUtils.showSnackBarMessage(context, messageKey, type: .error);
    return true;
  }

  Future<void> _openDetails() async {
    if (_isNavigating) return;
    final hasInternet = await HelperUtils.checkInternet();

    if (!hasInternet) {
      if (!mounted) return;
      return HelperUtils.showSnackBarMessage(
        context,
        'noInternet',
        type: .error,
      );
    }
    setState(() {
      _isNavigating = true;
    });

    await Navigator.pushNamed(
      context,
      Routes.agentDetailsScreen,
      arguments: {
        'agentID': widget.agent.isAdmin ? '0' : widget.agent.id.toString(),
        'isAdmin': widget.agent.isAdmin,
        'heroTag': 'agent-hero-${widget.agent.id}',
        'heroImageUrl': widget.agent.profile,
        'heroBannerUrl': _bannerUrl,
        'agentName': widget.agent.name,
        'agentEmail': widget.agent.email,
        'isVerified': widget.agent.isAgentVerified,
        'isFollowing': _isFollowing,
      },
    );

    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    await GuestChecker.check(
      onNotGuest: () async {
        try {
          final newStatus = await FollowManager.toggleFollow(
            widget.agent.id,
            isAdmin: widget.agent.isAdmin,
          );
          if (mounted) setState(() => _isFollowing = newStatus);
        } on Object catch (e) {
          if (mounted) {
            HelperUtils.showSnackBarMessage(
              context,
              e.toString(),
              type: MessageType.error,
            );
          }
        }
      },
    );
  }

  Future<CustomerData?> _fetchAgentData() {
    final card = widget.agent;
    final agentId = card.isAdmin ? '0' : card.id.toString();
    return _agentDataCache.putIfAbsent(agentId, () async {
      try {
        final result = await AgentsRepository().fetchAgentProperties(
          offset: 0,
          agentId: agentId,
          isAdmin: card.isAdmin,
          limit: 1,
        );
        return result.agentsProperty.customerData;
      } on Exception catch (_) {
        // Don't cache failures, so a later tap can retry.
        unawaited(_agentDataCache.remove(agentId));
        return null;
      }
    });
  }

  Future<void> _openAppointment() async {
    if (_blockSelfAction('cantBookAppointmentWithYourself')) return;
    await GuestChecker.check(
      onNotGuest: () async {
        final agent = await _fetchAgentData();
        if (!mounted) return;
        if (agent == null) {
          HelperUtils.showSnackBarMessage(
            context,
            'somethingWentWrong',
            type: MessageType.error,
          );
          return;
        }
        await Navigator.pushNamed(
          context,
          Routes.appointmentFlow,
          arguments: {
            'isAdmin': widget.agent.isAdmin,
            'agentDetails': agent,
          },
        );
      },
    );
  }

  Future<void> _openWhatsapp() async {
    if (_blockSelfAction('cantWhatsappYourself')) return;
    await GuestChecker.check(
      onNotGuest: () async {
        var mobile = widget.agent.mobile;
        var countryCode = widget.agent.mobileCountryCode ?? '';

        if (mobile.isEmpty || countryCode.isEmpty) {
          final agent = await _fetchAgentData();
          if (!mounted) return;
          final profile = agent?.agentProfile;
          if (profile?.agentMobile?.isNotEmpty ?? false) {
            mobile = profile!.agentMobile!;
            countryCode = profile.agentCountryCode ?? countryCode;
          }
        }

        if (mobile.isEmpty || countryCode.isEmpty) {
          if (!mounted) return;
          HelperUtils.showSnackBarMessage(
            context,
            'somethingWentWrong',
            type: MessageType.error,
          );
          return;
        }

        await WhatsappHelper.open(mobile, countryCode);
      },
    );
  }

  Future<void> _openChat() async {
    if (_blockSelfAction('cantChatWithYourself')) return;
    final card = widget.agent;
    // The list API may not return every field (e.g. appointment
    // availability), so load the same data the details screen uses.
    final agent = await _fetchAgentData();
    if (!mounted) return;

    final mobile = agent == null
        ? card.mobile
        : (agent.agentProfile.agentMobile?.isNotEmpty ?? false)
        ? '${agent.agentProfile.agentCountryCode ?? ''}${agent.agentProfile.agentMobile}'
        : agent.mobile;
    final isAdmin = card.isAdmin || (agent?.isAdmin ?? false);
    await openChatScreen(
      context,
      chatScreen: ChatScreenNew(
        profilePicture: (agent?.profile.isNotEmpty ?? false)
            ? agent!.profile
            : (agent?.agentProfile.agentProfilePhoto ?? card.profile),
        userName: (agent?.name.isNotEmpty ?? false)
            ? agent!.name
            : (agent?.agentProfile.agentName ?? card.name),
        propertyImage: '',
        proeprtyTitle: '',
        userId: isAdmin
            ? '0'
            : (agent != null && agent.id != 0)
            ? agent.id.toString()
            : card.id.toString(),
        propertyId: '0',
        isBlockedByMe: false,
        isBlockedByUser: false,
        isAgent: !isAdmin,
        isAgentVerified:
            card.isAgentVerified || (agent?.isAgentVerified ?? false),
        isUserVerified: false,
        isAdmin: isAdmin,
        isAppointmentAvailable:
            card.isAppointmentAvailable ||
            (agent?.isAppointmentAvailable ?? false),
        phoneNumber: mobile,
        hasProperty: false,
        receiverRoleContext: isAdmin ? 'admin' : 'agent',
        from: 'agent',
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    Widget button({
      required String icon,
      required String title,
      required VoidCallback onTap,
      required bool filled,
    }) {
      final fg = filled
          ? context.color.buttonColor
          : context.color.tertiaryColor;
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44.rh(context),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled
                  ? context.color.tertiaryColor
                  : context.color.tertiaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.rw(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomImage(
                  imageUrl: icon,
                  width: 18.rw(context),
                  height: 18.rh(context),
                  color: fg,
                ),
                SizedBox(width: 8.rw(context)),
                Flexible(
                  child: CustomText(
                    title,
                    fontSize: context.font.sm,
                    fontWeight: FontWeight.w500,
                    color: fg,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canBookAppointment = _canBookAppointment;

    return Row(
      spacing: 12.rw(context),
      children: [
        button(
          icon: AppIcons.chatActive,
          title: 'chatNow'.translate(context),
          onTap: _openChat,
          filled: true,
        ),
        // Appointment has priority, then WhatsApp; Chat alone when the backend
        // allows neither. Empty slot while that's still loading.
        if (canBookAppointment == null)
          Expanded(
            child: Container(
              height: 44.rh(context),
              decoration: BoxDecoration(
                color: context.color.tertiaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.rw(context)),
              ),
            ),
          )
        else if (canBookAppointment)
          button(
            icon: AppIcons.appointment,
            title: 'appointment'.translate(context),
            onTap: _openAppointment,
            filled: false,
          )
        else if (_canShowWhatsapp)
          button(
            icon: AppIcons.whatsapp,
            title: 'whatsapp'.translate(context),
            onTap: _openWhatsapp,
            filled: false,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetId = widget.agent.isAdmin ? 0 : widget.agent.id;
    final cachedCount = FollowManager.getFollowersCount(targetId);
    final rawFollowers = cachedCount ?? widget.agent.followersCount?.toString();
    final totalFollowers = (rawFollowers == null || rawFollowers.isEmpty)
        ? 0
        : int.tryParse(rawFollowers) ?? 0;
    final formattedFollowers = HelperUtils.formatFollowerCount(totalFollowers);

    final bannerUrl = _bannerUrl;

    final resolvedHeroTag = 'agent-hero-${widget.agent.id}';

    return GestureDetector(
      onLongPress: () async {
        await HelperUtils.share(context, widget.agent.name);
      },
      onTap: _openDetails,
      child: Container(
        width: widget.width ?? 285.rw(context),
        padding: EdgeInsets.all(12.rw(context)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.rw(context)),
          color: context.color.secondaryColor,
          border: Border.all(
            color: context.color.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 198.rh(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 152.rh(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.rw(context)),
                      child: Hero(
                        tag: '$resolvedHeroTag-banner',
                        child: CustomImage(
                          imageUrl: bannerUrl.isNotEmpty
                              ? bannerUrl
                              : AppIcons.fallbackPlaceholderLogo,
                          height: 152.rh(context),
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  if (_showActions)
                    PositionedDirectional(
                      top: 10.rh(context),
                      end: 10.rw(context),
                      child: GestureDetector(
                        onTap: _toggleFollow,
                        child: Container(
                          height: 34.rw(context),
                          constraints: BoxConstraints(minWidth: 34.rw(context)),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.rw(context),
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8.rw(context)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomImage(
                                imageUrl: _isFollowing
                                    ? AppIcons.userCheck
                                    : AppIcons.userPlus,
                                width: 18.rw(context),
                                height: 18.rw(context),
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.rw(context)),
                              CustomText(
                                (_isFollowing ? 'unfollow' : 'follow')
                                    .translate(context),
                                fontSize: context.font.sm,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 4.rw(context),
                    top: 162.rh(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.rw(context),
                        vertical: 6.rh(context),
                      ),
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8.rw(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomImage(
                            imageUrl: AppIcons.following,
                            width: 14.rw(context),
                            height: 14.rh(context),
                            color: context.color.tertiaryColor,
                          ),
                          SizedBox(width: 5.rw(context)),
                          CustomText(
                            '$formattedFollowers - ${'followers'.translate(context)}',
                            fontSize: 11.5.rw(context),
                            fontWeight: FontWeight.w600,
                            color: context.color.tertiaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6.rw(context),
                    bottom: 0,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 70.rw(context),
                          height: 70.rw(context),
                          decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            borderRadius: BorderRadius.circular(
                              14.rw(context),
                            ),
                            border: Border.all(
                              color: context.color.secondaryColor,
                              width: 3.rw(context),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              11.rw(context),
                            ),
                            child: Hero(
                              tag: 'agent-hero-${widget.agent.id}',
                              child: widget.agent.profile.isNotEmpty
                                  ? CustomImage(
                                      height: 70.rh(context),
                                      width: 70.rw(context),
                                      imageUrl: widget.agent.profile,
                                    )
                                  : Center(
                                      child: CustomImage(
                                        imageUrl: AppIcons.defaultPersonLogo,
                                        color: context.color.tertiaryColor,
                                        width: 28.rw(context),
                                        height: 28.rh(context),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (widget.agent.isAgentVerified ||
                            widget.agent.isAdmin)
                          Positioned(
                            bottom: -5.rh(context),
                            left: 0,
                            right: 0,
                            child: Center(
                              child: VerifiedBadge.agentWithBackground(
                                size: 13,
                                backgroundSize: 22,
                                heroTag: '$resolvedHeroTag-badge',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.rh(context)),
            // Name
            Hero(
              tag: '$resolvedHeroTag-name',
              child: Material(
                type: MaterialType.transparency,
                child: CustomText(
                  widget.agent.name.firstUpperCase(),
                  fontWeight: FontWeight.w600,
                  fontSize: context.font.md,
                  color: context.color.textColorDark,
                  maxLines: 1,
                ),
              ),
            ),
            SizedBox(height: 2.rh(context)),
            // Email
            Hero(
              tag: '$resolvedHeroTag-email',
              child: Material(
                type: MaterialType.transparency,
                child: CustomText(
                  widget.agent.email,
                  fontSize: context.font.xs,
                  fontWeight: FontWeight.w400,
                  color: context.color.textLightColor,
                  maxLines: 1,
                ),
              ),
            ),
            SizedBox(height: 10.rh(context)),
            // Property & Project counts
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 8.rh(context),
                horizontal: 6.rw(context),
              ),
              decoration: BoxDecoration(
                color: context.color.textLightColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(8.rw(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: CustomText(
                        '${'properties'.translate(context)}: ${widget.agent.propertyCount}',
                        fontSize: 12.rw(context),
                        fontWeight: FontWeight.w500,
                        color: context.color.textColorDark,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  Container(
                    width: 1.2.rw(context),
                    height: 16.rh(context),
                    color: context.color.textColorDark.withValues(
                      alpha: 0.25,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: CustomText(
                        '${'projects'.translate(context)}: ${widget.agent.projectsCount}',
                        fontSize: 12.rw(context),
                        fontWeight: FontWeight.w500,
                        color: context.color.textColorDark,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showContactButtons) ...[
              SizedBox(height: 12.rh(context)),
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }
}
