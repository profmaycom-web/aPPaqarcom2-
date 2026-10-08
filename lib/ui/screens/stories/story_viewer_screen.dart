import 'package:ebroker/data/cubits/stories/fetch_stories_cubit.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/model/story_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/stories/widgets/story_progress_bar.dart';
import 'package:ebroker/ui/screens/stories/widgets/story_video_player.dart';
import 'package:ebroker/ui/screens/widgets/like_button_widget.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Guest (not-logged-in) view cap, mirroring web: capped at 5 story views,
/// tracked purely in memory so it resets on app restart (not persisted).
class _GuestStoryViewGate {
  _GuestStoryViewGate._();
  static const int maxViews = 5;
  static int viewCount = 0;
}

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    required this.agents,
    required this.initialAgentIndex,
    required this.userHasPremiumPropertiesAccess,
    required this.userHasPremiumProjectsAccess,
    required this.isGuest,
    this.trackView = true,
    this.isAdmin = false,
    super.key,
  });

  final List<StoryAgentModel> agents;
  final int initialAgentIndex;
  final bool userHasPremiumPropertiesAccess;
  final bool userHasPremiumProjectsAccess;
  final bool isGuest;

  /// Whether opening/advancing a story here should call the story-view API.
  /// False for the signed-in agent viewing their own stories (self-view
  /// shouldn't count as a view).
  final bool trackView;

  /// Whether the current viewer is an admin — used when sharing a story's
  /// agent so the share link is tagged with `is_admin` for that context.
  final bool isAdmin;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map? ?? {};
    return CupertinoPageRoute(
      builder: (_) => StoryViewerScreen(
        agents:
            (arguments['agents'] as List?)?.cast<StoryAgentModel>() ?? const [],
        initialAgentIndex: arguments['initialAgentIndex'] as int? ?? 0,
        userHasPremiumPropertiesAccess:
            arguments['userHasPremiumPropertiesAccess'] as bool? ?? false,
        userHasPremiumProjectsAccess:
            arguments['userHasPremiumProjectsAccess'] as bool? ?? false,
        isGuest: arguments['isGuest'] as bool? ?? false,
        trackView: arguments['trackView'] as bool? ?? true,
        isAdmin: arguments['isAdmin'] as bool? ?? false,
      ),
    );
  }

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late final PageController _agentPageController;
  late int _agentIndex;
  int _storyIndex = 0;
  late AnimationController _progressController;
  // Deliberately never reassigned: keeping the same GlobalKey across story
  // transitions lets Flutter reuse the same StoryVideoPlayerState (via
  // didUpdateWidget) for consecutive video stories instead of tearing down
  // and recreating it, which raced the old video's native decoder teardown
  // against the new one's setup and froze playback on some devices.
  final GlobalKey<StoryVideoPlayerState> _videoPlayerKey =
      GlobalKey<StoryVideoPlayerState>();
  double _dragOffset = 0;
  bool _guestLimitReached = false;
  // Captured in didChangeDependencies, not read in dispose() — by the time
  // dispose() runs the element tree can already be deactivated, and
  // Provider.of/context.read throw "deactivated widget's ancestor" then.
  FetchStoriesCubit? _fetchStoriesCubit;
  // Fired once per (agent, story) actually shown this session — dedup key
  // is "agentId:storyId". Called directly from _playCurrentStory instead of
  // batched on agent-leave, so the call reliably fires for every story the
  // viewer actually reaches, including the last agent/story before close.
  final Set<String> _viewedStoryKeys = {};

  @override
  void initState() {
    super.initState();
    _agentIndex = widget.initialAgentIndex;
    _storyIndex = _firstUnseenIndex(_storiesFor(widget.agents[_agentIndex]));
    _agentPageController = PageController(initialPage: _agentIndex);
    _progressController = AnimationController(vsync: this)
      ..addStatusListener(_onProgressStatusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCurrentStory());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchStoriesCubit = context.read<FetchStoriesCubit>();
  }

  /// Index of the agent's first unseen story, or 0 if all are seen.
  int _firstUnseenIndex(List<StoryItemModel> stories) {
    final index = stories.indexWhere((s) => !s.isSeen);
    return index == -1 ? 0 : index;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _agentPageController.dispose();
    super.dispose();
  }

  /// Fires the story-view API for the current story, once per (agent,
  /// story) per session. No-op for guests, self-view (trackView disabled),
  /// premium teaser cards (not a real story), or stories already marked
  /// seen by the server.
  void _markCurrentStorySeen() {
    if (!widget.trackView ||
        widget.isGuest ||
        _currentStory.isPremiumTeaser ||
        _currentStory.isSeen) {
      return;
    }
    final agentId = _currentAgent.agentId;
    final storyId = _currentStory.storyId;
    if (agentId == null || storyId == null) return;
    if (!_viewedStoryKeys.add('$agentId:$storyId')) return;
    _fetchStoriesCubit?.markStorySeen(agentId, storyId);
  }

  List<StoryItemModel> _storiesFor(StoryAgentModel agent) {
    return agent.orderedStories;
  }

  StoryAgentModel get _currentAgent => widget.agents[_agentIndex];
  List<StoryItemModel> get _currentStories => _storiesFor(_currentAgent);
  StoryItemModel get _currentStory => _currentStories[_storyIndex];

  /// Hero tag for the linked-entity thumbnail, keyed by story so the
  /// image morphs into the property details header instead of the
  /// destination screen popping in with blank labels while it loads.
  String get _linkedEntityHeroTag =>
      'story-linked-entity-${_currentAgent.agentId}-${_currentStory.storyId}';

  bool get _isCurrentVideo =>
      _currentStories.isNotEmpty && _currentStory.mediaType == 'video';

  bool get _isLocked {
    if (_currentStory.isPremiumTeaser) return false;
    final entity = _currentStory.linkedEntity;
    if (entity == null || !_currentStory.isPremium) return false;
    if (entity.type == 'property') {
      return !widget.userHasPremiumPropertiesAccess;
    }
    if (entity.type == 'project') {
      return !widget.userHasPremiumProjectsAccess;
    }
    return false;
  }

  void _pausePlayback() {
    _progressController.stop();
    if (_isCurrentVideo) _videoPlayerKey.currentState?.pause();
  }

  void _resumePlayback() {
    _progressController.forward();
    if (_isCurrentVideo) _videoPlayerKey.currentState?.play();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _pausePlayback();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0, double.infinity);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = details.primaryVelocity ?? 0;
    final crossedThreshold = _dragOffset > screenHeight * 0.2 || velocity > 800;
    if (crossedThreshold) {
      Navigator.pop(context);
      return;
    }
    unawaited(_snapBackFromDrag());
  }

  Future<void> _snapBackFromDrag() async {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    final animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    void listener() {
      if (mounted) setState(() => _dragOffset = animation.value);
    }

    animation.addListener(listener);
    await controller.forward();
    animation.removeListener(listener);
    controller.dispose();
    if (!mounted) return;
    _resumePlayback();
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goToNextStory();
    }
  }

  void _playCurrentStory() {
    if (!mounted) return;
    if (_currentStories.isEmpty) {
      _progressController.stop();
      return;
    }

    if (widget.isGuest) {
      _GuestStoryViewGate.viewCount++;
      if (_GuestStoryViewGate.viewCount > _GuestStoryViewGate.maxViews) {
        _progressController.stop();
        setState(() => _guestLimitReached = true);
        return;
      }
    }

    _progressController
      ..stop()
      ..reset();

    _markCurrentStorySeen();

    if (_currentStory.mediaType == 'video' && !_isLocked) {
      // StoryVideoPlayer.onReady (below) sets the real duration and starts
      // both the progress bar and playback together once initialized.
      return;
    }

    final seconds = _currentStory.isPremiumTeaser
        ? 6
        : (_isLocked ? 5 : (_currentStory.durationSeconds ?? 6));
    _progressController.duration = Duration(
      seconds: seconds <= 0 ? 6 : seconds,
    );
    _progressController.forward();
  }

  void _onVideoReady(Duration duration) {
    if (!mounted) return;
    _progressController.duration = duration > Duration.zero
        ? duration
        : const Duration(seconds: 6);
    _progressController.forward();
    _videoPlayerKey.currentState?.play();
  }

  void _onVideoEnded() {
    if (!mounted) return;
    // Drive the existing AnimationStatus.completed → _goToNextStory path
    // as the single source of truth, instead of calling it directly here
    // (avoids a double-advance if both fire around the same moment).
    _progressController.value = 1;
  }

  void _onVideoError() {
    if (!mounted) return;
    _goToNextStory();
  }

  void _goToNextStory() {
    if (_storyIndex < _currentStories.length - 1) {
      setState(() => _storyIndex++);
      _playCurrentStory();
    } else {
      _goToNextAgent();
    }
  }

  void _goToPreviousStory() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _playCurrentStory();
    } else {
      _goToPreviousAgent();
    }
  }

  void _goToNextAgent() {
    if (_agentIndex < widget.agents.length - 1) {
      if (!_agentPageController.hasClients) {
        _onAgentPageChanged(_agentIndex + 1);
        return;
      }

      _agentPageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousAgent() {
    if (_agentIndex > 0) {
      if (!_agentPageController.hasClients) {
        _onAgentPageChanged(_agentIndex - 1);
        return;
      }
      _agentPageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onAgentPageChanged(int index) {
    setState(() {
      _agentIndex = index;
      _storyIndex = _firstUnseenIndex(_storiesFor(widget.agents[index]));
    });
    _playCurrentStory();
  }

  Future<void> _onTapLinkedEntity() async {
    final entity = _currentStory.linkedEntity;
    if (entity?.id == null) return;
    _pausePlayback();
    if (entity!.type == 'property') {
      await Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {
          'propertyData': PropertyModel(
            id: entity.id,
            title: entity.title,
            translatedTitle: entity.title,
            price: entity.price,
            titleImage: entity.image,
            city: entity.city,
            address: entity.address,
            propertyType: entity.propertyType,
            isPremium: entity.isPremium,
          ),
          'heroTag': _linkedEntityHeroTag,
          // trackView is false only for the signed-in agent viewing their
          // own stories — in that case the linked property is always
          // theirs, so fetch it via the my-properties endpoint (which
          // surfaces pending/unlisted listings) instead of the public one.
          'fromMyProperty': !widget.trackView,
        },
      );
    } else if (entity.type == 'project') {
      await Navigator.pushNamed(
        context,
        Routes.projectDetailsScreen,
        arguments: {'project': ProjectModel(id: entity.id)},
      );
    }
    if (mounted) _resumePlayback();
  }

  Future<void> _onTapGuestLogin() async {
    await Navigator.pushReplacementNamed(context, Routes.login);
  }

  Future<void> _onTapViewProfile() async {
    final agentId = _currentAgent.agentId;
    if (agentId == null) return;
    _pausePlayback();
    await Navigator.pushNamed(
      context,
      Routes.agentDetailsScreen,
      arguments: {
        'isAdmin': _currentAgent.isAdmin,
        'agentID': _currentAgent.isAdmin ? '0' : agentId.toString(),
        'agentName': _currentAgent.agentName,
        'heroImageUrl': _currentAgent.agentProfileImage,
        'isVerified': _currentAgent.isAgentVerified,
      },
    );
    if (mounted) _resumePlayback();
  }

  Future<void> _onTapShareEntity() async {
    final entity = _currentStory.linkedEntity;
    final slug = entity?.slug;
    if (entity == null || slug == null || slug.isEmpty) return;
    _pausePlayback();
    if (entity.type == 'project') {
      await HelperUtils.shareProject(context, slug);
    } else {
      await HelperUtils.share(context, slug);
    }
    if (mounted) _resumePlayback();
  }

  Future<void> _onTapAddMore() async {
    _pausePlayback();
    await Navigator.pushNamed(context, Routes.selectStoryListing);
    if (mounted) _resumePlayback();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.agents.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    if (_guestLimitReached) {
      return _GuestLimitOverlay(onLogin: _onTapGuestLogin);
    }
    final screenHeight = MediaQuery.of(context).size.height;
    final dragRatio = (_dragOffset / screenHeight).clamp(0.0, 1.0);
    final scale = 1 - dragRatio * 0.3;
    final opacity = 1 - dragRatio * 0.5;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: .expand,
        children: [
          Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: PageView.builder(
                  controller: _agentPageController,
                  itemCount: widget.agents.length,
                  onPageChanged: _onAgentPageChanged,
                  itemBuilder: (context, agentIndex) {
                    final agent = widget.agents[agentIndex];
                    final stories = _storiesFor(agent);
                    if (agentIndex != _agentIndex || stories.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final story = stories[_storyIndex];
                    return GestureDetector(
                      onTapUp: (details) {
                        final width = MediaQuery.of(context).size.width;
                        final isRtl =
                            Directionality.of(context) == TextDirection.rtl;
                        final tappedStart =
                            details.globalPosition.dx < width / 3;
                        final tappedEnd =
                            details.globalPosition.dx > width * 2 / 3;
                        if (tappedStart) {
                          isRtl ? _goToNextStory() : _goToPreviousStory();
                        } else if (tappedEnd) {
                          isRtl ? _goToPreviousStory() : _goToNextStory();
                        }
                      },
                      onLongPressStart: (_) => _pausePlayback(),
                      onLongPressEnd: (_) => _resumePlayback(),
                      onVerticalDragStart: _onVerticalDragStart,
                      onVerticalDragUpdate: _onVerticalDragUpdate,
                      onVerticalDragEnd: _onVerticalDragEnd,
                      child: Center(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _StoryMedia(
                              story: story,
                              isLocked: _isLocked,
                              premiumStoryCount: agent.premiumStoryCount,
                              videoPlayerKey: _videoPlayerKey,
                              onVideoReady: _onVideoReady,
                              onVideoEnded: _onVideoEnded,
                              onVideoError: _onVideoError,
                            ),
                            Positioned(
                              top:
                                  MediaQuery.of(context).padding.top +
                                  8.rh(context),
                              left: 12.rw(context),
                              right: 12.rw(context),
                              child: StoryProgressBar(
                                count: stories.length,
                                currentIndex: _storyIndex,
                                controller: _progressController,
                              ),
                            ),
                            Positioned(
                              top:
                                  MediaQuery.of(context).padding.top +
                                  20.rh(context),
                              left: 12.rw(context),
                              right: 12.rw(context),
                              child: _StoryHeader(
                                agent: agent,
                                story: story,
                                isSelf: !widget.trackView,
                                onBack: () => Navigator.pop(context),
                                onViewProfile: _onTapViewProfile,
                                onAddMore: _onTapAddMore,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (_currentStories.isNotEmpty && _currentStory.linkedEntity != null)
            PositionedDirectional(
              bottom: 16,
              start: 0,
              end: 0,
              child: _StoryLinkedEntityCard(
                entity: _currentStory.linkedEntity!,
                heroTag: _linkedEntityHeroTag,
                onTap: _onTapLinkedEntity,
                onTapShare: _onTapShareEntity,
              ),
            ),
        ],
      ),
    );
  }
}

/// Blocks further story viewing once a guest hits the view cap, matching
/// web's "Enjoying Stories?" sign-in prompt.
class _GuestLimitOverlay extends StatelessWidget {
  const _GuestLimitOverlay({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PositionedDirectional(
              top: 8,
              start: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.rw(context)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomImage(
                      imageUrl: AppIcons.logout,
                      height: 75.rh(context),
                      color: Colors.white,
                      fit: .contain,
                    ),
                    CustomText(
                      'enjoyingStories'.translate(context),
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: context.font.lg,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.rh(context)),
                    CustomText(
                      'loginToKeepWatchingStories'.translate(context),
                      color: Colors.white70,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.rh(context)),
                    UiUtils.buildButton(
                      context,
                      buttonTitle: 'loginNow'.translate(context),
                      onPressed: onLogin,
                      height: 48.rh(context),
                      autoWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryHeader extends StatelessWidget {
  const _StoryHeader({
    required this.agent,
    required this.story,
    required this.isSelf,
    required this.onBack,
    required this.onViewProfile,
    required this.onAddMore,
  });

  final StoryAgentModel agent;
  final StoryItemModel story;
  final bool isSelf;
  final VoidCallback onBack;
  final VoidCallback onViewProfile;
  final VoidCallback onAddMore;

  /// e.g. "12h" — story createdAt relative to now, since stories expire in
  /// 24h. Falls back to empty when createdAt is missing/unparsable.
  String get _timeAgo {
    final createdAt = story.createdAt;
    if (createdAt == null || createdAt.isEmpty) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    return timeago.format(date, locale: 'en_short');
  }

  @override
  Widget build(BuildContext context) {
    return isSelf
        ? Row(
            children: [
              _HeaderIconButton(
                onTap: onBack,
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 10.rw(context)),
              Expanded(
                child: CustomText(
                  'myStory'.translate(context),
                  color: Colors.white,
                  fontSize: context.font.lg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: onAddMore,
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: 12.rw(context),
                    vertical: 8.rh(context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomImage(
                        imageUrl: AppIcons.plusButtonIcon,
                        width: 14.rw(context),
                        height: 14.rh(context),
                        color: Colors.white,
                      ),
                      SizedBox(width: 6.rw(context)),
                      CustomText(
                        'addMore'.translate(context),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              _HeaderIconButton(
                onTap: onBack,
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 10.rw(context)),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.rw(context)),
                  border: .all(color: context.color.buttonColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.rw(context)),
                  child: CustomImage(
                    imageUrl: agent.agentProfileImage ?? '',
                    width: 44.rw(context),
                    height: 44.rh(context),
                  ),
                ),
              ),
              SizedBox(width: 8.rw(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: CustomText(
                            agent.agentName ?? '',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                          ),
                        ),
                        if (agent.isAgentVerified || agent.isAdmin) ...[
                          SizedBox(width: 4.rw(context)),
                          const VerifiedBadge.agent(
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                        if (_timeAgo.isNotEmpty) ...[
                          SizedBox(width: 6.rw(context)),
                          CustomText(
                            _timeAgo,
                            color: Colors.white70,
                            fontSize: context.font.xs,
                          ),
                        ],
                      ],
                    ),
                    GestureDetector(
                      onTap: onViewProfile,
                      child: CustomText(
                        'viewProfile'.translate(context),
                        color: Colors.white,
                        fontSize: context.font.xs,
                        showUnderline: true,
                        underlineOrLineColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.rw(context),
        height: 36.rh(context),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _StoryMedia extends StatelessWidget {
  const _StoryMedia({
    required this.story,
    required this.isLocked,
    required this.premiumStoryCount,
    required this.videoPlayerKey,
    required this.onVideoReady,
    required this.onVideoEnded,
    required this.onVideoError,
  });

  final StoryItemModel story;
  final bool isLocked;
  final int premiumStoryCount;
  final GlobalKey<StoryVideoPlayerState> videoPlayerKey;
  final void Function(Duration duration) onVideoReady;
  final VoidCallback onVideoEnded;
  final VoidCallback onVideoError;

  @override
  Widget build(BuildContext context) {
    if (story.isPremiumTeaser) {
      return _PremiumTeaserCard(count: premiumStoryCount);
    }

    if (isLocked) {
      return _PremiumLockCard(message: 'premiumStoryLocked'.translate(context));
    }

    if (story.mediaType == 'video') {
      return StoryVideoPlayer(
        key: videoPlayerKey,
        videoUrl: story.mediaUrl,
        onReady: onVideoReady,
        onEnded: onVideoEnded,
        onError: onVideoError,
      );
    }

    return CustomImage(
      imageUrl: story.mediaUrl ?? '',
      fit: .contain,
    );
  }
}

/// End-of-agent card shown when the API withheld premium stories because
/// the viewer lacks premium access, in place of the per-story lock overlay.
class _PremiumTeaserCard extends StatelessWidget {
  const _PremiumTeaserCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _PremiumLockCard(
      message: '$count ${'morePremiumStoriesLocked'.translate(context)}',
    );
  }
}

/// Shared black lock-icon/message/"unlock" card used both for a single
/// locked premium story and the end-of-agent premium teaser.
class _PremiumLockCard extends StatelessWidget {
  const _PremiumLockCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomImage(
          imageUrl: AppSettings.loginBackground,
          width: double.infinity,
          height: double.infinity,
        ),
        BackdropFilter(
          filter: .blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomImage(
                  imageUrl: AppIcons.premium,
                  width: 64.rw(context),
                ),
                SizedBox(height: 16.rh(context)),
                CustomText(
                  message,
                  color: Colors.white,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.rh(context)),
                UiUtils.buildButton(
                  context,
                  buttonTitle: 'viewPlans'.translate(context),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    Routes.subscriptionPackageListRoute,
                  ),
                  autoWidth: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryLinkedEntityCard extends StatelessWidget {
  const _StoryLinkedEntityCard({
    required this.entity,
    required this.heroTag,
    required this.onTap,
    required this.onTapShare,
  });

  final StoryLinkedEntityModel entity;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback onTapShare;

  @override
  Widget build(BuildContext context) {
    final priceText = entity.price?.priceFormat(context: context) ?? '';

    return Container(
      padding: .all(12.rw(context)),
      margin: .all(16.rw(context)),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .3),
            blurRadius: 4,
          ),
        ],
        color: Colors.black54,
        borderRadius: BorderRadius.circular(14.rw(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: entity.type == 'property'
                        ? Hero(
                            tag: heroTag,
                            child: CustomImage(
                              imageUrl: entity.image ?? '',
                              width: 44.rw(context),
                              height: 44.rh(context),
                            ),
                          )
                        : CustomImage(
                            imageUrl: entity.image ?? '',
                            width: 44.rw(context),
                            height: 44.rh(context),
                          ),
                  ),
                  SizedBox(width: 10.rw(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          entity.title ?? '',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                        ),
                        if (priceText.isNotEmpty) ...[
                          SizedBox(height: 2.rh(context)),
                          CustomText(
                            priceText,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: context.font.sm,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.rw(context)),
          Container(
            padding: .symmetric(
              horizontal: entity.type == 'property'
                  ? 12.rw(context)
                  : 8.rw(context),
              vertical: 8.rh(context),
            ),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: .circular(999),
            ),
            child: Row(
              children: [
                _RoundIconButton(icon: AppIcons.shareIcon, onTap: onTapShare),
                if (entity.type == 'property' && entity.id != null) ...[
                  Container(
                    width: 1,
                    height: 22.rh(context),
                    margin: EdgeInsetsDirectional.symmetric(
                      horizontal: 14.rw(context),
                    ),
                    color: context.color.borderColor,
                  ),
                  BlocProvider(
                    create: (context) => AddToFavoriteCubitCubit(),
                    child: BlocBuilder<FavoriteIDsCubit, FavoriteIDsState>(
                      builder: (context, state) => LikeButtonWidget(
                        propertyId: entity.id!,
                        size: 18.rw(context),
                        isFavourite: state.list.contains(entity.id),
                        backgroundColor: Colors.transparent,
                      ),
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
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FittedBox(
        child: CustomImage(
          imageUrl: icon,
          height: 18.rh(context),
          fit: .contain,
          color: Colors.white,
        ),
      ),
    );
  }
}
