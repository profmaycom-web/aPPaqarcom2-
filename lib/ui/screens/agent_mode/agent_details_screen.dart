import 'dart:math' as math;

import 'package:ebroker/data/cubits/agents/fetch_projects_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_property_cubit.dart';
import 'package:ebroker/data/cubits/appointment/post/create_appointment_request_cubit.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/customer_data.dart';
import 'package:ebroker/data/model/agent/social_media_link_model.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/data/repositories/agent_profile_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_properties.dart';
import 'package:ebroker/ui/screens/agent_mode/agents_projects.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/ui/screens/chat/helpers/open_chat_screen.dart';
import 'package:ebroker/ui/screens/stories/widgets/story_ring_avatar.dart';
import 'package:ebroker/ui/screens/widgets/follow_button.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_bar.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:ebroker/utils/whatsapp_helper.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentDetailsScreen extends StatefulWidget {
  const AgentDetailsScreen({
    required this.isAdmin,
    required this.agentID,
    this.heroTag,
    this.heroImageUrl,
    this.heroBannerUrl,
    this.agentName,
    this.agentEmail,
    this.isVerified,
    this.isFollowing,
    super.key,
  });

  final bool isAdmin;
  final String agentID;
  final String? heroTag;
  final String? heroImageUrl;
  final String? heroBannerUrl;
  final String? agentName;
  final String? agentEmail;
  final bool? isVerified;
  final bool? isFollowing;

  static Widget buildWithProviders({
    required bool isAdmin,
    required String agentID,
    String? heroTag,
    String? heroImageUrl,
    String? heroBannerUrl,
    String? agentName,
    String? agentEmail,
    bool? isVerified,
    bool? isFollowing,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FetchAgentsPropertyCubit(),
        ),
        BlocProvider(
          create: (_) => FetchAgentsProjectCubit(),
        ),
        BlocProvider(
          create: (_) => CreateAppointmentRequestCubit(),
        ),
      ],
      child: AgentDetailsScreen(
        isAdmin: isAdmin,
        agentID: agentID,
        heroTag: heroTag,
        heroImageUrl: heroImageUrl,
        heroBannerUrl: heroBannerUrl,
        agentName: agentName,
        agentEmail: agentEmail,
        isVerified: isVerified,
        isFollowing: isFollowing,
      ),
    );
  }

  static Route<dynamic> route(RouteSettings routeSettings) {
    final argument = routeSettings.arguments as Map<String, dynamic>? ?? {};

    final isAdmin =
        argument['isAdmin'] == true ||
        argument['isAdmin'] == 1 ||
        argument['isAdmin'] == '1';
    final agentID = argument['agentID']?.toString() ?? '0';

    return CupertinoPageRoute(
      builder: (_) => AgentDetailsScreen.buildWithProviders(
        isAdmin: isAdmin,
        agentID: agentID,
        heroTag: argument['heroTag'] as String?,
        heroImageUrl: argument['heroImageUrl'] as String?,
        heroBannerUrl: argument['heroBannerUrl'] as String?,
        agentName: argument['agentName'] as String?,
        agentEmail: argument['agentEmail'] as String?,
        isVerified: argument['isVerified'] as bool?,
        isFollowing: argument['isFollowing'] as bool?,
      ),
    );
  }

  @override
  State<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends State<AgentDetailsScreen>
    with TickerProviderStateMixin {
  static const double _bannerHeight = 200;
  static const double _cardOverlap = 40;

  /// Real rendered height of the profile card. Font metrics differ per
  /// language (e.g. Urdu glyphs are taller), so the estimated height alone
  /// can overflow the header.
  double? _measuredCardHeight;

  bool showProjects = false;
  bool isProjectAllowed = false;
  TabController? _tabController;
  late ScrollController _scrollController;
  int _currentTabIndex = 0;

  static const double _flingVelocityThreshold = 400;
  int _activePointers = 0;
  ScrollDirection _lastSwipeDirection = ScrollDirection.idle;
  bool _isShowingSubscriptionDialog = false;
  bool _isFollowing = false;
  bool _initialFollowingState = false;
  bool _isFollowingInitialized = false;
  int _followerDelta = 0;
  StreamSubscription<FollowChangeEvent>? _followSubscription;

  late final TextEditingController _searchController;
  Timer? _searchDelay;
  String _previousSearchQuery = '';
  FilterApply? _selectedFilter;

  late final TextEditingController _projectSearchController;
  Timer? _projectSearchDelay;
  String _previousProjectSearchQuery = '';
  FilterApply? _selectedProjectFilter;

  int get _projectsTabIndex => showProjects ? 1 : -1;
  int get _aboutTabIndex => showProjects ? 2 : 1;

  AgentProfileModel? _aboutAgentProfile;
  bool _isLoadingAboutProfile = false;
  bool _hasFetchedAboutProfile = false;

  Future<void> _fetchAboutAgentProfile() async {
    if (_isLoadingAboutProfile || _hasFetchedAboutProfile) return;
    _hasFetchedAboutProfile = true;
    _isLoadingAboutProfile = true;
    if (mounted) {
      setState(() {});
    }
    try {
      final repository = AgentProfileRepository();
      final profile = await repository.getAgentProfile(
        agentId: widget.agentID,
      );
      if (mounted) {
        setState(() {
          _aboutAgentProfile = profile;
          _isLoadingAboutProfile = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingAboutProfile = false;
        });
      }
    }
  }

  void _initTabController(int length) {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
    _currentTabIndex = _tabController?.index ?? 0;
    _tabController?.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted || _tabController == null) {
      return;
    }
    final newIndex = _tabController!.index;
    if (newIndex == _currentTabIndex) {
      return;
    }

    // Gate the Projects tab behind subscription when needed.
    if (newIndex == _projectsTabIndex &&
        showProjects &&
        !isProjectAllowed &&
        !_isShowingSubscriptionDialog) {
      _isShowingSubscriptionDialog = true;
      _tabController!.index = _currentTabIndex;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _isShowingSubscriptionDialog = false;
          return;
        }
        await GuestChecker.check(
          onNotGuest: () async {
            if (!mounted) {
              _isShowingSubscriptionDialog = false;
              return;
            }
            final result = await UiUtils.showBlurredDialoge(
              context,
              dialog: const BlurredSubscriptionDialogBox(
                packageType: SubscriptionPackageType.premiumProjects,
                isAcceptContainesPush: true,
              ),
            );
            _isShowingSubscriptionDialog = false;

            if (result != true && mounted) {
              _tabController?.animateTo(0);
            }
          },
        );
        _isShowingSubscriptionDialog = false;
      });
      return;
    }

    _currentTabIndex = newIndex;
    if (newIndex == _aboutTabIndex) {
      if (!_hasFetchedAboutProfile) {
        unawaited(_fetchAboutAgentProfile());
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final agentId = int.tryParse(widget.agentID) ?? 0;
    final targetId = widget.isAdmin ? 0 : agentId;
    final initialVal = widget.isFollowing ?? false;

    _isFollowing = FollowManager.isFollowingStatus(
      targetId,
      initialValue: initialVal,
      isAdmin: widget.isAdmin,
    );
    _initialFollowingState = _isFollowing;
    _isFollowingInitialized = true;

    _followSubscription = FollowManager.onFollowChanged.listen((event) {
      if (event.agentId == targetId && mounted) {
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

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _searchController = TextEditingController();
    _searchController.addListener(_searchPropertyListener);
    _projectSearchController = TextEditingController();
    _projectSearchController.addListener(_searchProjectListener);
    _initTabController(2);
    HelperUtils.runAfterTransition(context, () {
      if (!mounted) return;
      unawaited(getAgentProjectsAndProperties());
      unawaited(_fetchAboutAgentProfile());
    });
  }

  void _scrollListener() {
    if (_scrollController.isEndReached()) {
      _loadMoreCurrentTab();
    }
  }

  void _loadMoreCurrentTab() {
    if (_currentTabIndex == 0) {
      final propertyCubit = context.read<FetchAgentsPropertyCubit>();
      if (propertyCubit.hasMoreData() && !propertyCubit.isLoadingMore()) {
        unawaited(propertyCubit.fetchMore(isAdmin: widget.isAdmin));
      }
    } else if (_currentTabIndex == 1 && showProjects && isProjectAllowed) {
      final projectCubit = context.read<FetchAgentsProjectCubit>();
      if (projectCubit.hasMoreData() && !projectCubit.isLoadingMore()) {
        unawaited(projectCubit.fetchMore(isAdmin: widget.isAdmin));
      }
    }
  }

  void _searchProjectListener() {
    _projectSearchDelay?.cancel();
    _projectSearchDelay = Timer(
      const Duration(milliseconds: 500),
      _projectSearch,
    );
  }

  Future<void> _projectSearch() async {
    final query = _projectSearchController.text.trim();
    if (_previousProjectSearchQuery != query) {
      _previousProjectSearchQuery = query;
      await context.read<FetchAgentsProjectCubit>().fetchAgentsProject(
        agentId: widget.agentID,
        forceRefresh: true,
        isAdmin: widget.isAdmin,
        filter: _selectedProjectFilter,
        searchQuery: query,
      );
    }
  }

  void _searchPropertyListener() {
    _searchDelay?.cancel();
    _searchDelay = Timer(const Duration(milliseconds: 500), _propertySearch);
  }

  Future<void> _propertySearch() async {
    final query = _searchController.text.trim();
    if (_previousSearchQuery != query) {
      _previousSearchQuery = query;
      await context.read<FetchAgentsPropertyCubit>().fetchAgentsProperty(
        agentId: widget.agentID,
        forceRefresh: true,
        isAdmin: widget.isAdmin,
        filter: _selectedFilter,
        searchQuery: query,
      );
    }
  }

  @override
  void dispose() {
    unawaited(_followSubscription?.cancel());
    _searchController
      ..removeListener(_searchPropertyListener)
      ..dispose();
    _searchDelay?.cancel();
    _projectSearchController
      ..removeListener(_searchProjectListener)
      ..dispose();
    _projectSearchDelay?.cancel();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> getAgentProjectsAndProperties() async {
    await context.read<FetchAgentsProjectCubit>().fetchAgentsProject(
      forceRefresh: true,
      agentId: widget.agentID,
      isAdmin: widget.isAdmin,
      filter: _selectedProjectFilter,
      searchQuery: _projectSearchController.text.trim(),
    );

    final projectState = context.read<FetchAgentsProjectCubit>().state;
    if (projectState is FetchAgentsProjectSuccess) {
      final hasProjects =
          projectState.agentsProperty.customerData.projectCount != '0';

      if (showProjects != hasProjects) {
        setState(() {
          showProjects = hasProjects;
          isProjectAllowed = projectState.agentsProperty.isFeatureAvailable;
          _initTabController(showProjects ? 3 : 2);
        });
      }
    }

    await context.read<FetchAgentsPropertyCubit>().fetchAgentsProperty(
      forceRefresh: true,
      agentId: widget.agentID,
      isAdmin: widget.isAdmin,
      filter: _selectedFilter,
      searchQuery: _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      CreateAppointmentRequestCubit,
      CreateAppointmentRequestState
    >(
      listener: (context, state) {
        if (state is CreateAppointmentRequestSuccess) {
          HelperUtils.showSnackBarMessage(
            context,
            'appointmentScheduledSuccessfully',
            type: .success,
          );
        }
        if (state is CreateAppointmentRequestFailure) {
          HelperUtils.showSnackBarMessage(
            context,
            state.errorMessage,
            type: .error,
          );
        }
      },
      child: BlocBuilder<FetchAgentsProjectCubit, FetchAgentsProjectState>(
        builder: (context, projectState) {
          return BlocBuilder<
            FetchAgentsPropertyCubit,
            FetchAgentsPropertyState
          >(
            builder: (context, propertyState) {
              return Scaffold(
                backgroundColor: context.color.backgroundColor,
                body: SafeArea(
                  child:
                      propertyState is FetchAgentsPropertyLoading ||
                          propertyState is FetchAgentsPropertyInitial ||
                          projectState is FetchAgentsProjectLoading ||
                          projectState is FetchAgentsProjectInitial
                      ? _buildLoadingWithHeroImage()
                      : propertyState is FetchAgentsPropertyFailure
                      ? Center(
                          child: SomethingWentWrong(
                            errorMessage: propertyState.errorMessage,
                          ),
                        )
                      : propertyState is FetchAgentsPropertySuccess
                      ? _buildNestedScrollView(
                          propertyState.agentsProperty.customerData,
                          propertyState,
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingWithHeroImage() {
    final heroTag = widget.heroTag;
    final heroImageUrl = widget.heroImageUrl;

    Widget profileImageWidget = CustomImage(
      imageUrl: heroImageUrl ?? '',
    );

    if (heroTag != null) {
      profileImageWidget = Hero(
        tag: heroTag,
        child: profileImageWidget,
      );
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated Banner (grey placeholder or shimmer)
          Container(
            height: _bannerHeight.rh(context),
            decoration: BoxDecoration(
              color: context.color.textColorDark.withValues(alpha: 0.05),
              borderRadius: .vertical(bottom: .circular(16.rw(context))),
            ),

            child: Stack(
              children: [
                if (heroTag != null && (widget.heroBannerUrl ?? '').isNotEmpty)
                  Positioned.fill(
                    child: Hero(
                      tag: '$heroTag-banner',
                      child: ClipRRect(
                        borderRadius: .vertical(
                          bottom: .circular(16.rw(context)),
                        ),
                        child: CustomImage(
                          imageUrl: widget.heroBannerUrl!,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                PositionedDirectional(
                  top: 8.rh(context),
                  start: 16.rw(context),
                  child: _buildBackButton(),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(0, -_cardOverlap.rh(context)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  border: Border.all(color: context.color.borderColor),
                  borderRadius: BorderRadius.circular(16.rw(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 76.rw(context),
                            height: 76.rw(context),
                            child: profileImageWidget,
                          ),
                        ),
                        SizedBox(width: 12.rw(context)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.agentName != null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: widget.heroTag != null
                                                ? Hero(
                                                    tag:
                                                        '${widget.heroTag}-name',
                                                    child: Material(
                                                      type: MaterialType
                                                          .transparency,
                                                      child: CustomText(
                                                        widget.agentName!
                                                            .firstUpperCase(),
                                                        maxLines: 2,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize:
                                                            context.font.md,
                                                      ),
                                                    ),
                                                  )
                                                : CustomText(
                                                    widget.agentName!
                                                        .firstUpperCase(),
                                                    maxLines: 2,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: context.font.md,
                                                  ),
                                          ),
                                          if (widget.isVerified == true ||
                                              widget.isAdmin) ...[
                                            SizedBox(width: 4.rw(context)),
                                            VerifiedBadge.agent(
                                              size: 14,
                                              heroTag: widget.heroTag != null
                                                  ? '${widget.heroTag}-badge'
                                                  : null,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                CustomShimmer(
                                  width: 120.rw(context),
                                  height: 16.rh(context),
                                  borderRadius: 4,
                                ),
                              SizedBox(height: 8.rh(context)),
                              if (widget.agentEmail != null &&
                                  widget.agentEmail!.isNotEmpty)
                                if (widget.heroTag != null)
                                  Hero(
                                    tag: '${widget.heroTag}-email',
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: CustomText(
                                        widget.agentEmail!,
                                        fontSize: context.font.xs,
                                        color: context.color.textLightColor,
                                        maxLines: 1,
                                      ),
                                    ),
                                  )
                                else
                                  CustomText(
                                    widget.agentEmail!,
                                    fontSize: context.font.xs,
                                    color: context.color.textLightColor,
                                    maxLines: 1,
                                  )
                              else
                                CustomShimmer(
                                  width: 150.rw(context),
                                  height: 12.rh(context),
                                  borderRadius: 4,
                                ),
                              SizedBox(height: 12.rh(context)),
                              Row(
                                children: [
                                  CustomShimmer(
                                    width: 60.rw(context),
                                    height: 20.rh(context),
                                    borderRadius: 6,
                                  ),
                                  SizedBox(width: 8.rw(context)),
                                  CustomShimmer(
                                    width: 60.rw(context),
                                    height: 20.rh(context),
                                    borderRadius: 6,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.rh(context)),
                    Row(
                      spacing: 8.rw(context),
                      children: [
                        CustomShimmer(
                          width: 48.rh(context),
                          height: 48.rh(context),
                          borderRadius: 6,
                        ),
                        Expanded(
                          child: CustomShimmer(
                            height: 48.rh(context),
                            borderRadius: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                CustomShimmer(
                  height: 40.rh(context),
                  borderRadius: 8,
                ),
                SizedBox(height: 16.rh(context)),
                CustomShimmer(
                  height: 180.rh(context),
                  borderRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNestedScrollView(
    CustomerData agent,
    FetchAgentsPropertySuccess propertyState,
  ) {
    final targetId = widget.isAdmin ? 0 : agent.id;
    FollowManager.registerFollowStatus(
      targetId,
      isFollowing: agent.isFollowing,
      isAdmin: widget.isAdmin,
    );
    if (agent.followersCount != null && agent.followersCount!.isNotEmpty) {
      FollowManager.registerFollowersCount(targetId, agent.followersCount!);
    }

    final resolvedStatus = FollowManager.isFollowingStatus(
      targetId,
      initialValue: agent.isFollowing,
      isAdmin: widget.isAdmin,
    );

    if (!_isFollowingInitialized) {
      _isFollowingInitialized = true;
      _isFollowing = resolvedStatus;
      _initialFollowingState = resolvedStatus;
    } else {
      if (resolvedStatus != _isFollowing) {
        _isFollowing = resolvedStatus;
      }
    }

    final showPremiumStrip =
        propertyState.agentsProperty.premiumPropertyCount != '0' &&
        !propertyState.agentsProperty.isPackageAvailable &&
        !propertyState.agentsProperty.isFeatureAvailable;

    final expandedHeight = _getExpandedHeaderHeight(context, showPremiumStrip);

    final mobile = (agent.agentProfile.agentMobile?.isNotEmpty ?? false)
        ? '${agent.agentProfile.agentCountryCode ?? ''}${agent.agentProfile.agentMobile}'
        : agent.mobile;
    final canShowWhatsapp = WhatsappHelper.canShow(
      agent.agentProfile.agentMobile,
      agent.agentProfile.agentCountryCode,
    );
    final canBookAppointment =
        agent.isAppointmentAvailable && widget.agentID != HiveUtils.getUserId();

    final isAboutTab = _currentTabIndex == _aboutTabIndex;
    final appBarHeight = isAboutTab ? _aboutAppBarHeight(context) : 0.0;
    final tabBarHeight = 52.rh(context);
    final minHeight = appBarHeight + tabBarHeight;
    final maxHeight = expandedHeight;

    final rawFollowers = agent.followersCount;
    final baseFollowers = (rawFollowers == null || rawFollowers.isEmpty)
        ? 0
        : int.tryParse(rawFollowers) ?? 0;
    var totalFollowers = (baseFollowers + _followerDelta).clamp(
      0,
      999999999,
    );
    if (_isFollowing && totalFollowers < 1) {
      totalFollowers = 1;
    }
    final formattedCount = HelperUtils.formatFollowerCount(
      totalFollowers,
    );

    // Heavy header pieces are built once per state change rather than on
    // every scroll frame; RepaintBoundary lets the engine reuse their layers
    // while only the position/opacity changes during the collapse animation.
    final expandedHeader = RepaintBoundary(
      child: _buildHeaderSection(agent, propertyState, showPremiumStrip),
    );
    final tabBar = RepaintBoundary(
      child: _buildTabBar(context, agent, showPremiumStrip),
    );
    final collapsedAppBar = isAboutTab
        ? RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                border: Border(
                  bottom: BorderSide(
                    color: context.color.borderColor,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.color.textColorDark.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16.rw(context),
                vertical: 8.rh(context),
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Back, Avatar, Name, Followers, Share
                    Row(
                      children: [
                        _buildBackButton(
                          size: 38.rh(context),
                        ),
                        SizedBox(width: 8.rw(context)),
                        Expanded(
                          child: Row(
                            children: [
                              StoryRingAvatar(
                                agentId: agent.id,
                                isAdmin: widget.isAdmin,
                                borderRadius: 8,
                                child: SizedBox(
                                  width: 36.rw(context),
                                  height: 36.rw(context),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      8.rw(context),
                                    ),
                                    child: CustomImage(
                                      imageUrl: agent.profile,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.rw(context)),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: CustomText(
                                            agent.name.firstUpperCase(),
                                            maxLines: 1,
                                            fontWeight: FontWeight.w600,
                                            fontSize: context.font.md,
                                            color: context.color.textColorDark,
                                          ),
                                        ),
                                        if (agent.isAgentVerified ||
                                            agent.isAdmin) ...[
                                          SizedBox(
                                            width: 4.rw(
                                              context,
                                            ),
                                          ),
                                          const VerifiedBadge.agent(
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (formattedCount.isNotEmpty)
                                      CustomText(
                                        '$formattedCount - ${'followers'.translate(context)}',
                                        fontSize: context.font.xxs,
                                        color: context.color.textLightColor,
                                        maxLines: 1,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.rw(context)),
                        _buildShareButton(
                          agent.slugId,
                          size: 38.rh(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.rh(context)),
                    // Row 2: Contact and Appointment action buttons (same size as in screen)
                    Row(
                      spacing: 8.rw(context),
                      children: [
                        if (canShowWhatsapp || canBookAppointment)
                          _buildCallIconButton(mobile),
                        _buildChatIconButton(agent),
                        if (canShowWhatsapp && canBookAppointment)
                          _buildAppointmentIconButton(),
                        Expanded(
                          child: _buildBigActionButton(
                            agent: agent,
                            mobile: mobile,
                            canShowWhatsapp: canShowWhatsapp,
                            canBookAppointment: canBookAppointment,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Listener(
      onPointerDown: (_) => _activePointers++,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: NestedScrollView(
          controller: _scrollController,
          // Downward drags go to the header first, so the profile card follows
          // the finger on any swipe down, not only once the list hits the top.
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: _AgentDetailsHeaderDelegate(
                    minHeight: minHeight,
                    maxHeight: maxHeight,
                    builder: (context, shrinkOffset, {required overlapsContent}) {
                      final maxShrink = (maxHeight - minHeight).clamp(
                        1.0,
                        double.infinity,
                      );
                      final progress = (shrinkOffset / maxShrink).clamp(
                        0.0,
                        1.0,
                      );

                      // The card simply slides away on the list tabs. On About the
                      // compact bar takes its place, so the two cross-fade over
                      // the middle of the swipe instead of the card vanishing
                      // while it is still on screen.
                      final expandedOpacity = isAboutTab
                          ? 1.0 - ((progress - 0.3) / 0.5).clamp(0.0, 1.0)
                          : 1.0;
                      final collapsedOpacity = ((progress - 0.4) / 0.4).clamp(
                        0.0,
                        1.0,
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Layer 1: Expanded Header (Banner + Card) that scrolls up
                          Positioned(
                            top: -shrinkOffset,
                            left: 0,
                            right: 0,
                            height: maxHeight - tabBarHeight,
                            child: Opacity(
                              opacity: expandedOpacity,
                              child: IgnorePointer(
                                ignoring: isAboutTab && progress > 0.6,
                                child: expandedHeader,
                              ),
                            ),
                          ),
                          // Layer 2: Pinned Large AppBar (Visible when swiped up on About tab)
                          if (isAboutTab)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: appBarHeight,
                              child: Opacity(
                                opacity: collapsedOpacity,
                                child: IgnorePointer(
                                  ignoring: progress < 0.6,
                                  child: collapsedAppBar,
                                ),
                              ),
                            ),
                          // Layer 3: Pinned TabBar at the bottom of the header
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: tabBarHeight,
                            child: tabBar,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPropertiesTab(propertyState),
              if (showProjects) _buildProjectsTab(propertyState),
              _buildAboutTab(agent),
            ],
          ),
        ),
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _lastSwipeDirection = notification.direction;
    } else if (notification is ScrollEndNotification) {
      final drag = notification.dragDetails;
      // Finger lifted slowly, or a fling ran out of speed with the header
      // half open. A fast fling carries the header itself and settles here
      // once it stops.
      final shouldSettle = drag != null
          ? (drag.primaryVelocity ?? 0).abs() < _flingVelocityThreshold
          : _activePointers == 0;
      if (shouldSettle) {
        // Deferred so the scroll view finishes switching activities first.
        scheduleMicrotask(_settleHeader);
      }
    }
    return false;
  }

  void _onPointerUp(PointerEvent event) {
    _activePointers = math.max(0, _activePointers - 1);
  }

  /// Finishes a swipe on the header: even a small swipe down opens the full
  /// profile card, and a swipe up collapses it to full screen.
  ///
  /// Only the outer (header) position is animated, so the list inside keeps
  /// its scroll offset while the card slides in or out above it.
  void _settleHeader() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position is! ScrollActivityDelegate) return;
    final double target;
    switch (_lastSwipeDirection) {
      case ScrollDirection.forward:
        target = position.minScrollExtent;
      case ScrollDirection.reverse:
        target = position.maxScrollExtent;
      case ScrollDirection.idle:
        return;
    }
    if ((position.pixels - target).abs() < 0.5) return;
    position.beginActivity(
      DrivenScrollActivity(
        position as ScrollActivityDelegate,
        from: position.pixels,
        to: target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        vsync: this,
      ),
    );
  }

  double _aboutAppBarHeight(BuildContext context) => 134.rh(context);

  double _getExpandedHeaderHeight(
    BuildContext context,
    bool showPremiumStrip,
  ) {
    final bannerVisible = _bannerHeight.rh(context) - _cardOverlap.rh(context);
    final cardBase = 128.rh(context) + 76.rw(context);
    final estimatedCardHeight =
        cardBase + (showPremiumStrip ? 48.rh(context) : 0);
    final cardHeight = math.max(
      estimatedCardHeight,
      _measuredCardHeight ?? 0,
    );
    final bottomSpacing = 8.rh(context);
    final tabBarHeight = 52.rh(context);
    return bannerVisible + cardHeight + bottomSpacing + tabBarHeight;
  }

  Widget _buildTabBar(
    BuildContext context,
    CustomerData agent,
    bool showPremiumStrip,
  ) {
    final isDark = context.read<AppThemeCubit>().isDarkMode;
    final bgColor = isDark ? primaryColorDark : primaryColor_;

    return ColoredBox(
      color: bgColor,
      child: CustomTabBar(
        margin: EdgeInsets.fromLTRB(
          16.rw(context),
          4.rh(context),
          16.rw(context),
          4.rh(context),
        ),
        tabController: _tabController!,
        isScrollable: false,
        onTap: (index) {
          if (index == _aboutTabIndex) {
            if (!_hasFetchedAboutProfile) {
              unawaited(_fetchAboutAgentProfile());
            }
          }
        },
        tabs: [
          Tab(
            text: '${agent.propertyCount} - ${'properties'.translate(context)}',
          ),
          if (showProjects)
            Tab(
              text: '${agent.projectCount} - ${'projects'.translate(context)}',
            ),
          Tab(text: 'about'.translate(context)),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    CustomerData agent,
    FetchAgentsPropertySuccess propertyState,
    bool showPremiumStrip,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Layer 1: Banner background.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: _bannerHeight.rh(context),
            child: _buildBanner(
              (agent.agentProfile.agentBanner ?? '').isNotEmpty
                  ? agent.agentProfile.agentBanner!
                  : AppIcons.fallbackAgentBanner,
            ),
          ),
        ),
        // Layer 2: Content column reserves banner space at top.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _bannerHeight.rh(context) - _cardOverlap.rh(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SizeReporter(
                onSizeChanged: (size) {
                  if (!mounted) return;
                  final current = _measuredCardHeight;
                  if (current != null && (current - size.height).abs() < 0.5) {
                    return;
                  }
                  setState(() => _measuredCardHeight = size.height);
                },
                child: _buildAgentProfileCard(
                  agent: agent,
                  showPremiumStrip: showPremiumStrip,
                  propertyState: propertyState,
                ),
              ),
            ),
            SizedBox(height: 8.rh(context)),
          ],
        ),
        // Layer 3: Back button overlay.
        PositionedDirectional(
          top: 8.rh(context),
          start: 16.rw(context),
          child: _buildBackButton(),
        ),
        // Layer 4: Share button overlay.
        PositionedDirectional(
          top: 8.rh(context),
          end: 16.rw(context),
          child: _buildShareButton(agent.slugId),
        ),
      ],
    );
  }

  Widget _buildShareButton(String slugId, {double? size}) {
    final s = size ?? 40.rh(context);
    final iconSize = s * (20.0 / 40.0);
    return UiUtils.buildButton(
      context,
      buttonTitle: '',
      radius: 12.rw(context),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () async {
        await HelperUtils.shareAgent(
          context,
          slugId,
          isAdmin: widget.isAdmin,
        );
      },
      height: s,
      width: s,
      buttonColor: context.color.secondaryColor,
      prefixWidget: CustomImage(
        imageUrl: AppIcons.shareApp,
        color: context.color.textColorDark,
        fit: .contain,
        height: iconSize,
        width: iconSize,
      ),
    );
  }

  Widget _buildBanner(String url) {
    final banner = ClipRRect(
      borderRadius: .vertical(bottom: .circular(16.rw(context))),
      child: CustomImage(
        imageUrl: url,
        showFullScreenImage: true,
      ),
    );
    if (widget.heroTag == null) return banner;
    return Hero(tag: '${widget.heroTag}-banner', child: banner);
  }

  Widget _buildBackButton({double? size}) {
    final s = size ?? 40.rh(context);
    final iconSize = s * (24.0 / 40.0);
    return UiUtils.buildButton(
      context,
      buttonTitle: '',
      radius: 12.rw(context),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsetsDirectional.only(start: 4.rw(context)),
      onPressed: () => Navigator.of(context).pop(),
      height: s,
      width: s,
      buttonColor: context.color.secondaryColor,
      prefixWidget: CustomImage(
        imageUrl: AppIcons.arrowLeft,
        color: context.color.textColorDark,
        matchTextDirection: true,
        height: iconSize,
        fit: .contain,
      ),
    );
  }

  Widget _buildAgentProfileCard({
    required CustomerData agent,
    required bool showPremiumStrip,
    required FetchAgentsPropertySuccess propertyState,
  }) {
    final email = agent.agentProfile.agentEmail ?? agent.email;
    final mobile = (agent.agentProfile.agentMobile?.isNotEmpty ?? false)
        ? '${agent.agentProfile.agentCountryCode ?? ''}${agent.agentProfile.agentMobile}'
        : agent.mobile;
    final canShowWhatsapp = WhatsappHelper.canShow(
      agent.agentProfile.agentMobile,
      agent.agentProfile.agentCountryCode,
    );
    final canBookAppointment =
        agent.isAppointmentAvailable && widget.agentID != HiveUtils.getUserId();
    final borderColors = [
      Colors.amberAccent,
      Colors.amberAccent.withValues(alpha: .2),
      Colors.amberAccent.withValues(alpha: .05),
    ];

    final gradientContainerColors = [
      Color.lerp(
            Colors.amberAccent,
            context.color.secondaryColor,
            .7,
          ) ??
          Colors.amberAccent,
      Color.lerp(
            Colors.amberAccent,
            context.color.secondaryColor,
            .9,
          ) ??
          Colors.amberAccent,
    ];

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StoryRingAvatar(
              agentId: agent.id,
              isAdmin: widget.isAdmin,
              borderRadius: 12,
              child: SizedBox(
                width: 76.rw(context),
                height: 76.rw(context),
                child: widget.heroTag != null
                    ? Hero(
                        tag: widget.heroTag!,
                        child: ClipRRect(
                          borderRadius: .circular(8.rw(context)),
                          child: CustomImage(
                            imageUrl: agent.profile,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: .circular(8.rw(context)),
                        child: CustomImage(
                          imageUrl: agent.profile,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 12.rw(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: widget.heroTag != null
                                  ? Hero(
                                      tag: '${widget.heroTag}-name',
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: CustomText(
                                          agent.name.firstUpperCase(),
                                          maxLines: 2,
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.font.md,
                                        ),
                                      ),
                                    )
                                  : CustomText(
                                      agent.name.firstUpperCase(),
                                      maxLines: 2,
                                      fontWeight: FontWeight.w600,
                                      fontSize: context.font.md,
                                    ),
                            ),
                            if (agent.isAgentVerified || agent.isAdmin) ...[
                              SizedBox(width: 4.rw(context)),
                              VerifiedBadge.agent(
                                size: 14,
                                heroTag: widget.heroTag != null
                                    ? '${widget.heroTag}-badge'
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (email.isNotEmpty) ...[
                    SizedBox(height: 4.rh(context)),
                    if (widget.heroTag != null)
                      Hero(
                        tag: '${widget.heroTag}-email',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CustomText(
                            email,
                            fontSize: context.font.xs,
                            color: context.color.textLightColor,
                            maxLines: 1,
                          ),
                        ),
                      )
                    else
                      CustomText(
                        email,
                        fontSize: context.font.xs,
                        color: context.color.textLightColor,
                        maxLines: 1,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.rh(context)),
        Builder(
          builder: (context) {
            final rawFollowers = agent.followersCount;
            final baseFollowers = (rawFollowers == null || rawFollowers.isEmpty)
                ? 0
                : int.tryParse(rawFollowers) ?? 0;
            var totalFollowers = (baseFollowers + _followerDelta).clamp(
              0,
              999999999,
            );
            if (_isFollowing && totalFollowers < 1) {
              totalFollowers = 1;
            }
            final formattedCount = HelperUtils.formatFollowerCount(
              totalFollowers,
            );
            final isSelf =
                !widget.isAdmin &&
                (widget.agentID == HiveUtils.getUserId() ||
                    agent.id.toString() == HiveUtils.getUserId());
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomImage(
                      imageUrl: AppIcons.following,
                      height: 16.rh(context),
                      width: 16.rw(context),
                      color: context.color.tertiaryColor,
                    ),
                    SizedBox(width: 6.rw(context)),
                    CustomText(
                      '$formattedCount - ${'followers'.translate(context)}',
                      fontSize: context.font.xs,
                      color: context.color.textColorDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
                if (!isSelf) ...[
                  FollowButton(
                    isFollowing: _isFollowing,
                    onTap: () async {
                      await GuestChecker.check(
                        onNotGuest: () async {
                          final agentId = int.tryParse(widget.agentID) ?? 0;
                          try {
                            final newStatus = await FollowManager.toggleFollow(
                              agentId,
                              isAdmin: widget.isAdmin,
                            );
                            if (mounted) {
                              setState(() {
                                _isFollowing = newStatus;
                                if (_isFollowing && !_initialFollowingState) {
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
                ],
              ],
            );
          },
        ),
        SizedBox(height: 12.rh(context)),
        Row(
          spacing: 8.rw(context),
          children: [
            // Call icon is redundant when the big button below is Call
            // itself (whatsapp/appointment both unavailable) — hidden then.
            if (canShowWhatsapp || canBookAppointment)
              _buildCallIconButton(mobile),
            _buildChatIconButton(agent),
            // Appointment only needs its own icon slot when WhatsApp has
            // taken over the big-button slot below; otherwise it already
            // has the big button.
            if (canShowWhatsapp && canBookAppointment)
              _buildAppointmentIconButton(),
            Expanded(
              child: _buildBigActionButton(
                agent: agent,
                mobile: mobile,
                canShowWhatsapp: canShowWhatsapp,
                canBookAppointment: canBookAppointment,
              ),
            ),
          ],
        ),
      ],
    );

    if (showPremiumStrip) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.rw(context)),
          gradient: LinearGradient(
            begin: .bottomCenter,
            end: .topCenter,
            colors: borderColors,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(1.rw(context)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(12.rw(context)),
              gradient: LinearGradient(
                begin: .centerStart,
                end: .centerEnd,
                colors: gradientContainerColors,
              ),
            ),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(12.rw(context)),
                  ),
                  child: Padding(
                    padding: .all(12.rw(context)),
                    child: child,
                  ),
                ),
                _buildPremiumStrip(
                  count: propertyState.agentsProperty.premiumPropertyCount,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      padding: .all(12.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(color: context.color.borderColor),
        borderRadius: BorderRadius.circular(16.rw(context)),
      ),
      child: child,
    );
  }

  Widget _buildCallIconButton(String mobile, {double? size}) {
    final s = size ?? 48.rh(context);
    final iconSize = s * (20.0 / 48.0);
    return GestureDetector(
      onTap: mobile.isEmpty ? null : () => _onTapCall(contactNumber: mobile),
      child: Container(
        height: s,
        width: s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.textLightColor.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CustomImage(
          imageUrl: AppIcons.callFilled,
          height: iconSize,
          width: iconSize,
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  Widget _buildChatIconButton(CustomerData agent, {double? size}) {
    final s = size ?? 48.rh(context);
    final iconSize = s * (20.0 / 48.0);
    return GestureDetector(
      onTap: () => _onTapChat(agent: agent),
      child: Container(
        height: s,
        width: s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.textLightColor.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CustomImage(
          imageUrl: AppIcons.chatActive,
          height: iconSize,
          width: iconSize,
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  Widget _buildAppointmentIconButton({double? size}) {
    final s = size ?? 48.rh(context);
    final iconSize = s * (20.0 / 48.0);
    return GestureDetector(
      onTap: _onTapScheduleAppointment,
      child: Container(
        height: s,
        width: s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.textLightColor.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CustomImage(
          imageUrl: AppIcons.appointment,
          height: iconSize,
          width: iconSize,
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  /// The single big CTA button, priority: WhatsApp > Schedule Appointment >
  /// Call. Whichever action wins here is *not* duplicated as a small icon
  /// button elsewhere in the row (see the icon-visibility logic in
  /// [_buildAgentProfileCard]).
  Widget _buildBigActionButton({
    required CustomerData agent,
    required String mobile,
    required bool canShowWhatsapp,
    required bool canBookAppointment,
    double? height,
  }) {
    final h = height ?? 48.rh(context);
    final iconHeight = h * (24.0 / 48.0);
    final vPadding = h * (6.0 / 48.0);
    if (canShowWhatsapp) {
      return UiUtils.buildButton(
        context,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        prefixWidget: Padding(
          padding: EdgeInsetsDirectional.only(end: 8.rw(context)),
          child: CustomImage(
            imageUrl: AppIcons.whatsapp,
            color: context.color.buttonColor,
            height: iconHeight,
            fit: .contain,
          ),
        ),
        onPressed: () => _onTapWhatsapp(
          mobile: agent.agentProfile.agentMobile!,
          countryCode: agent.agentProfile.agentCountryCode!,
        ),
        height: h,
        padding: .symmetric(
          vertical: vPadding,
          horizontal: 12.rw(context),
        ),
        fontSize: context.font.sm,
        buttonTitle: 'whatsapp'.translate(context),
      );
    }
    if (canBookAppointment) {
      return UiUtils.buildButton(
        context,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        prefixWidget: Padding(
          padding: EdgeInsetsDirectional.only(end: 8.rw(context)),
          child: CustomImage(
            imageUrl: AppIcons.appointment,
            color: context.color.buttonColor,
            height: iconHeight,
            fit: .contain,
          ),
        ),
        onPressed: _onTapScheduleAppointment,
        height: h,
        padding: .symmetric(
          vertical: vPadding,
          horizontal: 12.rw(context),
        ),
        fontSize: context.font.sm,
        buttonTitle: 'scheduleAppointment'.translate(context),
      );
    }
    return UiUtils.buildButton(
      context,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      prefixWidget: Padding(
        padding: EdgeInsetsDirectional.only(end: 8.rw(context)),
        child: CustomImage(
          imageUrl: AppIcons.call,
          color: context.color.buttonColor,
          height: iconHeight,
          fit: .contain,
        ),
      ),
      disabled: mobile.isEmpty,
      onPressed: () => _onTapCall(contactNumber: mobile),
      height: h,
      padding: .symmetric(
        vertical: vPadding,
        horizontal: 12.rw(context),
      ),
      fontSize: context.font.sm,
      buttonTitle: 'call'.translate(context),
    );
  }

  Widget _buildPremiumStrip({required String count}) {
    return GestureDetector(
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(
              context,
              Routes.subscriptionPackageListRoute,
              arguments: {
                'from': 'agentDetails',
                'isBankTransferEnabled':
                    (context.read<GetApiKeysCubit>().state as GetApiKeysSuccess)
                        .bankTransferStatus ==
                    '1',
              },
            );
          },
        );
      },
      child: Padding(
        padding: .symmetric(
          horizontal: 16.rw(context),
          vertical: 12.rw(context),
        ),
        child: Row(
          children: [
            CustomImage(
              imageUrl: AppIcons.premium,
              height: 22.rh(context),
              width: 22.rh(context),
            ),
            SizedBox(width: 10.rw(context)),
            Expanded(
              child: CustomText(
                '$count+ ${'premiumProperties'.translate(context)}',
                fontSize: context.font.sm,
                fontWeight: FontWeight.w500,
                maxLines: 1,
              ),
            ),
            Transform.flip(
              flipX: true,
              child: CustomImage(
                imageUrl: AppIcons.arrowLeft,
                height: 24.rh(context),
                width: 24.rh(context),
                fit: .contain,
                matchTextDirection: true,
                color: context.color.textColorDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsTab(FetchAgentsPropertySuccess projectState) {
    return Builder(
      builder: (context) {
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 150) {
              final projectCubit = context.read<FetchAgentsProjectCubit>();
              if (projectCubit.hasMoreData() && !projectCubit.isLoadingMore()) {
                unawaited(projectCubit.fetchMore(isAdmin: widget.isAdmin));
              }
            }
            return false;
          },
          child: CustomScrollView(
            key: const PageStorageKey<String>(
              'projects_tab',
            ),
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchDelegate(
                  height: 64.rh(context),
                  child: SearchFilterBar(
                    controller: _projectSearchController,
                    currentFilter: _selectedProjectFilter,
                    isProject: true,
                    showPropertyType: false,
                    onSearchChanged: (query) async {
                      if (_previousProjectSearchQuery == query) return;
                      _previousProjectSearchQuery = query;
                      _projectSearchDelay?.cancel();
                      await context
                          .read<FetchAgentsProjectCubit>()
                          .fetchAgentsProject(
                            agentId: widget.agentID,
                            forceRefresh: true,
                            isAdmin: widget.isAdmin,
                            filter: _selectedProjectFilter,
                            searchQuery: query,
                          );
                    },
                    onFilterApplied: (filter) async {
                      _selectedProjectFilter = filter;
                      await context
                          .read<FetchAgentsProjectCubit>()
                          .fetchAgentsProject(
                            agentId: widget.agentID,
                            forceRefresh: true,
                            isAdmin: widget.isAdmin,
                            filter: filter,
                            searchQuery: _projectSearchController.text.trim(),
                          );
                      setState(() {});
                    },
                  ),
                ),
              ),
              AgentProjects(
                agentId: projectState.agentsProperty.customerData.id.toString(),
                isAdmin: widget.isAdmin,
                selectedFilter: _selectedProjectFilter,
                searchQuery: _projectSearchController.text.trim(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPropertiesTab(FetchAgentsPropertySuccess propertyState) {
    return Builder(
      builder: (context) {
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 150) {
              final propertyCubit = context.read<FetchAgentsPropertyCubit>();
              if (propertyCubit.hasMoreData() &&
                  !propertyCubit.isLoadingMore()) {
                unawaited(propertyCubit.fetchMore(isAdmin: widget.isAdmin));
              }
            }
            return false;
          },
          child: CustomScrollView(
            key: const PageStorageKey<String>('properties_tab'),
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchDelegate(
                  height: 64.rh(context),
                  child: SearchFilterBar(
                    controller: _searchController,
                    currentFilter: _selectedFilter,
                    onSearchChanged: (query) async {
                      if (_previousSearchQuery == query) return;
                      _previousSearchQuery = query;
                      _searchDelay?.cancel();
                      await context
                          .read<FetchAgentsPropertyCubit>()
                          .fetchAgentsProperty(
                            agentId: widget.agentID,
                            forceRefresh: true,
                            isAdmin: widget.isAdmin,
                            filter: _selectedFilter,
                            searchQuery: query,
                          );
                    },
                    onFilterApplied: (filter) async {
                      _selectedFilter = filter;
                      await context
                          .read<FetchAgentsPropertyCubit>()
                          .fetchAgentsProperty(
                            agentId: widget.agentID,
                            forceRefresh: true,
                            isAdmin: widget.isAdmin,
                            filter: filter,
                            searchQuery: _searchController.text.trim(),
                          );
                      setState(() {});
                    },
                  ),
                ),
              ),
              AgentProperties(
                agentId: propertyState.agentsProperty.customerData.id
                    .toString(),
                isAdmin: widget.isAdmin,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(CustomerData agent) {
    if (!_hasFetchedAboutProfile &&
        !_isLoadingAboutProfile &&
        _tabController?.index == _aboutTabIndex) {
      unawaited(_fetchAboutAgentProfile());
    }

    final cachedProfile = HiveUtils.getAgentProfileData();
    final isCurrentUser = widget.agentID == HiveUtils.getUserId();
    final p = _aboutAgentProfile != null
        ? (isCurrentUser && cachedProfile != null
              ? _aboutAgentProfile!.copyWith(
                  serviceAreas:
                      (_aboutAgentProfile!.serviceAreas?.trim().isNotEmpty ??
                          false)
                      ? _aboutAgentProfile!.serviceAreas
                      : cachedProfile.serviceAreas,
                  languages:
                      (_aboutAgentProfile!.languages?.trim().isNotEmpty ??
                          false)
                      ? _aboutAgentProfile!.languages
                      : cachedProfile.languages,
                  experience:
                      (_aboutAgentProfile!.experience?.trim().isNotEmpty ??
                          false)
                      ? _aboutAgentProfile!.experience
                      : cachedProfile.experience,
                  startTime:
                      (_aboutAgentProfile!.startTime?.trim().isNotEmpty ??
                          false)
                      ? _aboutAgentProfile!.startTime
                      : cachedProfile.startTime,
                  endTime:
                      (_aboutAgentProfile!.endTime?.trim().isNotEmpty ?? false)
                      ? _aboutAgentProfile!.endTime
                      : cachedProfile.endTime,
                )
              : _aboutAgentProfile)
        : (isCurrentUser ? cachedProfile : null);
    final ap = agent.agentProfile;

    final email = (p?.agentEmail?.trim().isNotEmpty ?? false)
        ? p!.agentEmail!.trim()
        : (ap.agentEmail?.trim().isNotEmpty ?? false)
        ? ap.agentEmail!.trim()
        : agent.email.trim();

    final countryCode = (p?.agentCountryCode?.trim().isNotEmpty ?? false)
        ? p!.agentCountryCode!.trim()
        : (ap.agentCountryCode?.trim().isNotEmpty ?? false)
        ? ap.agentCountryCode!.trim()
        : '';

    final rawMobile = (p?.agentMobile?.trim().isNotEmpty ?? false)
        ? p!.agentMobile!.trim()
        : (ap.agentMobile?.trim().isNotEmpty ?? false)
        ? ap.agentMobile!.trim()
        : agent.mobile.trim();

    final mobile = rawMobile.isNotEmpty
        ? (rawMobile.startsWith('+') || countryCode.isEmpty
              ? rawMobile
              : '$countryCode$rawMobile')
        : '';

    final fullAddressFromCustomer = [
      agent.address,
      agent.city,
      agent.state,
      agent.country,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    final address = (p?.agentAddress?.trim().isNotEmpty ?? false)
        ? p!.agentAddress!.trim()
        : (ap.agentAddress?.trim().isNotEmpty ?? false)
        ? ap.agentAddress!.trim()
        : fullAddressFromCustomer;

    final aboutMe = (p?.aboutMe?.trim().isNotEmpty ?? false)
        ? p!.aboutMe!.trim()
        : (ap.aboutMe?.trim().isNotEmpty ?? false)
        ? ap.aboutMe!.trim()
        : '';

    final startTime = (p?.startTime?.trim().isNotEmpty ?? false)
        ? p!.startTime!.trim()
        : (ap.startTime?.trim().isNotEmpty ?? false)
        ? ap.startTime!.trim()
        : null;

    final endTime = (p?.endTime?.trim().isNotEmpty ?? false)
        ? p!.endTime!.trim()
        : (ap.endTime?.trim().isNotEmpty ?? false)
        ? ap.endTime!.trim()
        : null;

    final workingHours = _formatWorkingHoursRange(startTime, endTime);

    final rawExperience = (p?.experience?.trim().isNotEmpty ?? false)
        ? p!.experience!.trim()
        : (ap.experience?.trim().isNotEmpty ?? false)
        ? ap.experience!.trim()
        : null;

    final experience = (rawExperience != null && rawExperience.isNotEmpty)
        ? (rawExperience.toLowerCase().contains('year')
              ? rawExperience
              : '$rawExperience ${'years'.translate(context)}')
        : null;

    final rawServiceAreas = (p?.serviceAreas?.trim().isNotEmpty ?? false)
        ? p!.serviceAreas!.trim()
        : (ap.serviceAreas?.trim().isNotEmpty ?? false)
        ? ap.serviceAreas!.trim()
        : '';

    final serviceAreasList = rawServiceAreas.isNotEmpty
        ? rawServiceAreas
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    final rawLanguages = (p?.languages?.trim().isNotEmpty ?? false)
        ? p!.languages!.trim()
        : (ap.languages?.trim().isNotEmpty ?? false)
        ? ap.languages!.trim()
        : '';

    final languagesList = rawLanguages.isNotEmpty
        ? rawLanguages
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    final socialMediaLinks = (p?.socialMediaLinks.isNotEmpty ?? false)
        ? p!.socialMediaLinks
        : ap.socialMediaLinks;

    // Merge custom fields: fetched profile takes priority, fallback to agent profile
    final customFields = <String, String>{
      ...ap.customFields,
      if (p != null) ...p.customFields,
    };

    final hasWorkingHoursOrExp = workingHours != null || experience != null;
    final hasAreasOrLanguages =
        serviceAreasList.isNotEmpty || languagesList.isNotEmpty;
    final hasContactOrSocial =
        email.isNotEmpty ||
        mobile.isNotEmpty ||
        socialMediaLinks.any(
          (link) => (link.url ?? '').trim().isNotEmpty,
        );
    final hasAddressOrAbout = address.isNotEmpty || aboutMe.isNotEmpty;
    final hasCustomFields = customFields.isNotEmpty;

    if (_isLoadingAboutProfile &&
        _aboutAgentProfile == null &&
        !hasWorkingHoursOrExp &&
        !hasAreasOrLanguages) {
      return Center(child: UiUtils.progress());
    }

    if (!hasWorkingHoursOrExp &&
        !hasAreasOrLanguages &&
        !hasContactOrSocial &&
        !hasAddressOrAbout &&
        !hasCustomFields) {
      return Center(
        child: CustomText(
          'noDataFound'.translate(context),
          color: context.color.textColorDark.withValues(alpha: 0.6),
        ),
      );
    }

    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>('about_tab'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16.rw(context),
                14.rh(context),
                16.rw(context),
                32.rh(context),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    if (hasWorkingHoursOrExp) ...[
                      _buildWorkingHoursExperienceCard(
                        workingHours: workingHours,
                        experience: experience,
                      ),
                      SizedBox(height: 12.rh(context)),
                    ],
                    if (hasAreasOrLanguages) ...[
                      _buildOperationsAndLanguagesCard(
                        serviceAreas: serviceAreasList,
                        languages: languagesList,
                      ),
                      SizedBox(height: 12.rh(context)),
                    ],
                    if (hasCustomFields) ...[
                      _buildCustomFieldsCard(customFields: customFields),
                      SizedBox(height: 12.rh(context)),
                    ],
                    if (hasContactOrSocial) ...[
                      _buildContactAndSocialCard(
                        email: email,
                        mobile: mobile,
                        socialMediaLinks: socialMediaLinks,
                      ),
                      SizedBox(height: 12.rh(context)),
                    ],
                    if (hasAddressOrAbout) ...[
                      _buildAddressAndAboutCard(
                        address: address,
                        aboutMe: aboutMe,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _formatWorkingHoursRange(String? start, String? end) {
    final s = _formatTime(start);
    final e = _formatTime(end);
    if (s.isNotEmpty && e.isNotEmpty) {
      return '$s - $e';
    } else if (s.isNotEmpty) {
      return s;
    } else if (e.isNotEmpty) {
      return e;
    }
    return null;
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    final t = time.trim();
    if (t.isEmpty) return '';
    final upper = t.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) {
      return t.replaceAll(' ', '');
    }
    final parts = t.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        final hStr = displayHour.toString().padLeft(2, '0');
        final mStr = minute.toString().padLeft(2, '0');
        return '$hStr:$mStr$period';
      }
    }
    return t;
  }

  Widget _buildWorkingHoursExperienceCard({
    String? workingHours,
    String? experience,
  }) {
    return _aboutCard(
      child: Column(
        children: [
          if (workingHours != null && workingHours.isNotEmpty)
            Row(
              children: [
                Container(
                  height: 40.rh(context),
                  width: 40.rw(context),
                  decoration: BoxDecoration(
                    color: context.color.tertiaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.rw(context)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.access_time_filled,
                      color: context.color.tertiaryColor,
                      size: 20.rh(context),
                    ),
                  ),
                ),
                SizedBox(width: 14.rw(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'workingHours'.translate(context),
                        fontSize: context.font.xs,
                        color: context.color.textColorDark.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: 3.rh(context)),
                      CustomText(
                        workingHours,
                        fontSize: context.font.sm,
                        fontWeight: FontWeight.w700,
                        color: context.color.textColorDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (workingHours != null &&
              workingHours.isNotEmpty &&
              experience != null &&
              experience.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.rh(context)),
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.color.borderColor.withValues(alpha: 0.5),
              ),
            ),
          if (experience != null && experience.isNotEmpty)
            Row(
              children: [
                Container(
                  height: 40.rh(context),
                  width: 40.rw(context),
                  decoration: BoxDecoration(
                    color: context.color.tertiaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.rw(context)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: context.color.tertiaryColor,
                      size: 20.rh(context),
                    ),
                  ),
                ),
                SizedBox(width: 14.rw(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'experience'.translate(context),
                        fontSize: context.font.xs,
                        color: context.color.textColorDark.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: 3.rh(context)),
                      CustomText(
                        experience,
                        fontSize: context.font.sm,
                        fontWeight: FontWeight.w700,
                        color: context.color.textColorDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOperationsAndLanguagesCard({
    required List<String> serviceAreas,
    required List<String> languages,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBgColor = isDark
        ? context.color.primaryColor
        : const Color(0xFFF2F4F7);

    return _aboutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (serviceAreas.isNotEmpty) ...[
            CustomText(
              'areasOfOperation'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w600,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 10.rh(context)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: serviceAreas.map((area) {
                  return Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.rw(context)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.rw(context),
                        vertical: 8.rh(context),
                      ),
                      decoration: BoxDecoration(
                        color: chipBgColor,
                        borderRadius: BorderRadius.circular(20.rw(context)),
                      ),
                      child: CustomText(
                        area,
                        fontSize: context.font.xs,
                        color: context.color.textColorDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (serviceAreas.isNotEmpty && languages.isNotEmpty)
            SizedBox(height: 16.rh(context)),
          if (languages.isNotEmpty) ...[
            CustomText(
              'spokenLanguages'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w600,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 10.rh(context)),
            Wrap(
              spacing: 8.rw(context),
              runSpacing: 8.rh(context),
              children: languages.map((lang) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.rw(context),
                    vertical: 8.rh(context),
                  ),
                  decoration: BoxDecoration(
                    color: chipBgColor,
                    borderRadius: BorderRadius.circular(20.rw(context)),
                  ),
                  child: CustomText(
                    lang,
                    fontSize: context.font.xs,
                    color: context.color.textColorDark,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomFieldsCard({
    required Map<String, String> customFields,
  }) {
    final entries = customFields.entries.toList();
    return _aboutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'additionalDetails'.translate(context),
            fontSize: context.font.sm,
            fontWeight: FontWeight.w600,
            color: context.color.textColorDark,
          ),
          SizedBox(height: 12.rh(context)),
          ...entries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.rh(context)),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: context.color.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 36.rh(context),
                      width: 36.rw(context),
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8.rw(context)),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: context.color.tertiaryColor,
                          size: 18.rh(context),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.rw(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            entry.key,
                            fontSize: context.font.xs,
                            color: context.color.textColorDark.withValues(
                              alpha: 0.6,
                            ),
                            fontWeight: FontWeight.w400,
                          ),
                          SizedBox(height: 3.rh(context)),
                          CustomText(
                            entry.value,
                            fontSize: context.font.sm,
                            fontWeight: FontWeight.w600,
                            color: context.color.textColorDark,
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactAndSocialCard({
    required String email,
    required String mobile,
    required List<SocialMediaLinkModel> socialMediaLinks,
  }) {
    final activeSocials = socialMediaLinks
        .where((link) => (link.url ?? '').trim().isNotEmpty)
        .toList();

    return _aboutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email.isNotEmpty)
            GestureDetector(
              onTap: () => _onTapEmail(email: email),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 18.rh(context),
                    color: context.color.textColorDark.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 10.rw(context)),
                  Expanded(
                    child: CustomText(
                      email,
                      fontSize: context.font.xs,
                      color: context.color.textColorDark.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          if (email.isNotEmpty && mobile.isNotEmpty)
            SizedBox(height: 10.rh(context)),
          if (mobile.isNotEmpty)
            GestureDetector(
              onTap: () => _onTapCall(contactNumber: mobile),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 18.rh(context),
                    color: context.color.textColorDark.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 10.rw(context)),
                  Expanded(
                    child: CustomText(
                      mobile,
                      fontSize: context.font.xs,
                      color: context.color.textColorDark.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          if ((email.isNotEmpty || mobile.isNotEmpty) &&
              activeSocials.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.rh(context)),
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.color.borderColor.withValues(alpha: 0.5),
              ),
            ),
          if (activeSocials.isNotEmpty) ...[
            Row(
              children: [
                CustomText(
                  'followMeOn'.translate(context),
                  fontSize: context.font.xs,
                  fontWeight: FontWeight.w500,
                  color: context.color.textColorDark,
                ),
                SizedBox(width: 12.rw(context)),
                Expanded(
                  child: Wrap(
                    spacing: 8.rw(context),
                    runSpacing: 8.rh(context),
                    children: activeSocials
                        .map(
                          (link) => _socialButton(
                            name: link.name,
                            iconUrl: link.icon,
                            url: link.url!.trim(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressAndAboutCard({
    required String address,
    required String aboutMe,
  }) {
    final hasAddress = address.trim().isNotEmpty;
    final hasAboutMe = aboutMe.trim().isNotEmpty;

    return _aboutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAddress) ...[
            CustomText(
              'addressLbl'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w600,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 6.rh(context)),
            CustomText(
              address.trim(),
              fontSize: context.font.xs,
              fontWeight: FontWeight.w400,
              color: context.color.textColorDark.withValues(alpha: 0.7),
            ),
          ],
          if (hasAddress && hasAboutMe)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.rh(context)),
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.color.borderColor.withValues(alpha: 0.5),
              ),
            ),
          if (hasAboutMe) ...[
            CustomText(
              'aboutAgent'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w600,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 8.rh(context)),
            CustomText(
              aboutMe.trim(),
              fontSize: context.font.xs,
              fontWeight: FontWeight.w400,
              color: context.color.textColorDark.withValues(alpha: 0.7),
              maxLines: 100,
            ),
          ],
        ],
      ),
    );
  }

  Widget _aboutCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(
          color: context.color.borderColor.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(14.rw(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _socialButton({
    required String name,
    required String url,
    String? iconUrl,
  }) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return const SizedBox.shrink();
    }
    String fallbackIcon;
    switch (name.toLowerCase().trim()) {
      case 'facebook':
        fallbackIcon = AppIcons.facebook;
      case 'twitter':
      case 'x':
        fallbackIcon = AppIcons.twitter;
      case 'instagram':
        fallbackIcon = AppIcons.instagram;
      case 'youtube':
        fallbackIcon = AppIcons.youtube;
      case 'linkedin':
        fallbackIcon = AppIcons.linkedin;
      default:
        fallbackIcon = '';
    }

    final hasNetworkIcon = iconUrl != null && iconUrl.isNotEmpty;
    if (!hasNetworkIcon && fallbackIcon.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _launchUrl(uri),
      child: Container(
        height: 28.rh(context),
        width: 28.rw(context),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        padding: const EdgeInsets.all(5.5),
        child: hasNetworkIcon
            ? CustomImage(
                imageUrl: iconUrl,
                color: Colors.white,
                fit: BoxFit.contain,
              )
            : CustomImage(
                imageUrl: fallbackIcon,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    try {
      await launchUrl(url);
    } on Exception catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _onTapCall({required String contactNumber}) async {
    await GuestChecker.check(
      onNotGuest: () async {
        final cleaned = contactNumber.replaceAll(' ', '');
        final url = Uri.parse(
          cleaned.startsWith('+') ? 'tel:$cleaned' : 'tel:+$cleaned',
        );
        try {
          await launchUrl(url);
        } on Exception catch (e) {
          throw Exception('Error calling $e');
        }
      },
    );
  }

  Future<void> _onTapChat({required CustomerData agent}) async {
    final isAdmin = widget.isAdmin || agent.isAdmin;
    final isSelf =
        !isAdmin &&
        (widget.agentID == HiveUtils.getUserId() ||
            agent.id.toString() == HiveUtils.getUserId());
    if (isSelf) {
      HelperUtils.showSnackBarMessage(
        context,
        'cantChatWithYourself',
        type: .error,
      );
      return;
    }
    final mobile = (agent.agentProfile.agentMobile?.isNotEmpty ?? false)
        ? '${agent.agentProfile.agentCountryCode ?? ''}${agent.agentProfile.agentMobile}'
        : agent.mobile;
    await openChatScreen(
      context,
      chatScreen: ChatScreenNew(
        profilePicture: agent.profile.isNotEmpty
            ? agent.profile
            : (agent.agentProfile.agentProfilePhoto ??
                  widget.heroImageUrl ??
                  ''),
        userName: agent.name.isNotEmpty
            ? agent.name
            : (agent.agentProfile.agentName ?? widget.agentName ?? ''),
        propertyImage: '',
        proeprtyTitle: '',
        userId: isAdmin
            ? '0'
            : (agent.id != 0 ? agent.id.toString() : widget.agentID),
        propertyId: '0',
        isBlockedByMe: false,
        isBlockedByUser: false,
        isAgent: !isAdmin,
        isAgentVerified: agent.isAgentVerified || (widget.isVerified ?? false),
        isUserVerified: false,
        isAdmin: isAdmin,
        phoneNumber: mobile,
        hasProperty: false,
        receiverRoleContext: isAdmin ? 'admin' : 'agent',
        isAppointmentAvailable: agent.isAppointmentAvailable,
        from: 'agent',
      ),
    );
  }

  Future<void> _onTapWhatsapp({
    required String mobile,
    required String countryCode,
  }) async {
    await GuestChecker.check(
      onNotGuest: () async {
        await WhatsappHelper.open(mobile, countryCode);
      },
    );
  }

  Future<void> _onTapEmail({required String email}) async {
    await GuestChecker.check(
      onNotGuest: () async {
        final url = Uri.parse('mailto:${email.trim()}');
        try {
          await launchUrl(url);
        } on Exception catch (e) {
          throw Exception('Error mail $e');
        }
      },
    );
  }

  Future<void> _onTapScheduleAppointment() async {
    await GuestChecker.check(
      onNotGuest: () async {
        final propertyState = context.read<FetchAgentsPropertyCubit>().state;
        if (propertyState is FetchAgentsPropertySuccess) {
          await Navigator.pushNamed(
            context,
            Routes.appointmentFlow,
            arguments: {
              'isAdmin': widget.isAdmin,
              'agentDetails': propertyState.agentsProperty.customerData,
            },
          );
        } else {
          HelperUtils.showSnackBarMessage(
            context,
            'pleaseWaitForProperties',
            type: .warning,
          );
        }
      },
    );
  }
}

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: context.color.backgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _AgentDetailsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _AgentDetailsHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  final double minHeight;
  final double maxHeight;

  final Widget Function(
    BuildContext context,
    double shrinkOffset, {
    required bool overlapsContent,
  })
  builder;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return builder(context, shrinkOffset, overlapsContent: overlapsContent);
  }

  @override
  bool shouldRebuild(covariant _AgentDetailsHeaderDelegate oldDelegate) {
    return true;
  }
}

/// Reports its child's laid-out size after each layout pass where it changed.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSizeChanged, required super.child});

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSizeChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _lastSize) return;
    _lastSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSizeChanged(size));
  }
}
