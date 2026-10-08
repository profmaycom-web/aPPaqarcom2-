import 'dart:ui' show lerpDouble;

import 'package:collection/collection.dart';
import 'package:ebroker/data/cubits/stories/fetch_stories_cubit.dart';
import 'package:ebroker/data/model/story_model.dart';
import 'package:ebroker/exports/main_export.dart';

class StoriesSection extends StatefulWidget {
  const StoriesSection({super.key})
    : categoryId = null,
      _scoped = false,
      _asSliver = false;

  /// A self-contained stories row that owns its own [FetchStoriesCubit]
  /// instead of reading the app-wide singleton — for screens (like
  /// ViewAllScreen) that need a filtered view without disturbing the
  /// home screen's unfiltered state.
  const StoriesSection.scoped({this.categoryId, super.key})
    : _scoped = true,
      _asSliver = false;

  /// Same as [StoriesSection.scoped], but returns a sliver — a pinned
  /// header that shrinks from full story cards down to a row of rings
  /// as the surrounding [CustomScrollView] scrolls — instead of a boxed
  /// widget. Place directly inside a `CustomScrollView`'s `slivers:` list.
  const StoriesSection.sliver({this.categoryId, super.key})
    : _scoped = true,
      _asSliver = true;

  final int? categoryId;
  final bool _scoped;
  final bool _asSliver;

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  static const double _maxHeight = 224;
  static const double _minHeight = 104;

  final _scrollController = ScrollController();
  FetchStoriesCubit? _localCubit;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget._scoped) {
      _localCubit = FetchStoriesCubit();
      unawaited(
        _localCubit!.fetch(categoryId: widget.categoryId, forceRefresh: true),
      );
    }
  }

  @override
  void didUpdateWidget(covariant StoriesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._scoped && widget.categoryId != oldWidget.categoryId) {
      unawaited(
        _localCubit?.fetch(categoryId: widget.categoryId, forceRefresh: true),
      );
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    unawaited(_localCubit?.close());
    super.dispose();
  }

  FetchStoriesCubit _cubit(BuildContext context) =>
      _localCubit ?? context.read<FetchStoriesCubit>();

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      unawaited(_cubit(context).fetchMore());
    }
  }

  Future<void> _openStory(
    BuildContext context,
    StoriesResponseModel data,
    List<StoryAgentModel> agents,
    int index,
  ) async {
    await Navigator.pushNamed(
      context,
      Routes.storyViewer,
      arguments: {
        'agents': agents,
        'initialAgentIndex': index,
        'userHasPremiumPropertiesAccess': data.userHasPremiumPropertiesAccess,
        'userHasPremiumProjectsAccess': data.userHasPremiumProjectsAccess,
        'isGuest': data.isGuest,
      },
    );
    // Refresh with the same filter this row was showing so seen/unseen
    // state reflects what was just viewed.
    if (mounted) {
      unawaited(
        _cubit(context).fetch(
          categoryId: widget.categoryId,
          forceRefresh: true,
        ),
      );
    }
  }

  Widget _row(
    BuildContext context,
    StoriesResponseModel data,
    List<StoryAgentModel> agents,
    double shrinkT,
    double itemHeight,
  ) {
    return ListView.separated(
      controller: _scrollController,
      scrollDirection: .horizontal,
      physics: Constant.scrollPhysics,
      padding: EdgeInsets.symmetric(
        horizontal: 18.rw(context),
        vertical: 16.rh(context),
      ),
      itemCount: agents.length,
      separatorBuilder: (context, index) => SizedBox(
        width: lerpDouble(16.rw(context), 8.rw(context), shrinkT),
      ),
      itemBuilder: (context, index) => _StoryBubble(
        agent: agents[index],
        shrinkT: shrinkT,
        itemHeight: itemHeight,
        onTap: () => _openStory(context, data, agents, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchStoriesCubit, FetchStoriesState>(
      bloc: _localCubit,
      builder: (context, state) {
        // Keep showing the previous row while a forceRefresh is in flight
        // (e.g. categoryId change) instead of collapsing to nothing.
        final data = switch (state) {
          FetchStoriesSuccess(:final data) => data,
          FetchStoriesLoading(:final previousData) => previousData,
          _ => null,
        };

        if (data == null || data.agents.isEmpty) {
          return widget._asSliver
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : const SizedBox.shrink();
        }

        final agents = data.agents
            .where((agent) => agent.orderedStories.isNotEmpty)
            .toList();
        if (agents.isEmpty) {
          return widget._asSliver
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : const SizedBox.shrink();
        }

        if (!widget._asSliver) {
          return SizedBox(
            height: _maxHeight.rh(context),
            child: _row(context, data, agents, 0, _maxHeight.rh(context)),
          );
        }

        return SliverPersistentHeader(
          pinned: true,
          delegate: _StoriesShrinkDelegate(
            maxExtentPx: _maxHeight.rh(context),
            minExtentPx: _minHeight.rh(context),
            backgroundColor: context.color.backgroundColor,
            rowBuilder: (shrinkT, itemHeight) =>
                _row(context, data, agents, shrinkT, itemHeight),
          ),
        );
      },
    );
  }
}

class _StoriesShrinkDelegate extends SliverPersistentHeaderDelegate {
  _StoriesShrinkDelegate({
    required this.maxExtentPx,
    required this.minExtentPx,
    required this.backgroundColor,
    required this.rowBuilder,
  });

  final double maxExtentPx;
  final double minExtentPx;
  final Color backgroundColor;
  final Widget Function(double shrinkT, double itemHeight) rowBuilder;

  @override
  double get minExtent => minExtentPx;

  @override
  double get maxExtent => maxExtentPx;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtentPx - minExtentPx;
    final t = range <= 0 ? 0.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final currentExtent = maxExtentPx - shrinkOffset.clamp(0.0, range);
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox(
        height: currentExtent,
        child: rowBuilder(t, currentExtent),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StoriesShrinkDelegate oldDelegate) => true;
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.agent,
    required this.onTap,
    required this.itemHeight,
    this.shrinkT = 0,
  });

  final StoryAgentModel agent;
  final VoidCallback onTap;

  /// The row's current height — the bubble sizes/positions itself to
  /// exactly fill it (no leftover whitespace at any point in the shrink).
  final double itemHeight;

  /// 0 = fully expanded card, 1 = fully shrunk (ring only, name kept).
  final double shrinkT;

  StoryItemModel? get _previewStory => agent.orderedStories.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final previewImage =
        _previewStory?.thumbnailUrl ?? _previewStory?.mediaUrl ?? '';
    final ringColor = agent.hasUnseenStory
        ? context.color.tertiaryColor
        : context.color.borderColor;

    final t = shrinkT.clamp(0.0, 1.0);
    final cardOpacity = (1 - t / 0.6).clamp(0.0, 1.0);

    final cardWidth = 128.rw(context);
    final cardHeight = 172.rh(context);
    final ringSizeExpanded = 48.rw(context);
    final ringSizeShrunk = 56.rw(context);
    final ringSize = lerpDouble(ringSizeExpanded, ringSizeShrunk, t)!;
    final compactWidth = ringSizeShrunk + 16.rw(context);
    final itemWidth = lerpDouble(cardWidth, compactWidth, t)!;

    // Ring's top offset when fully expanded matches the original design
    // (overlapping the bottom of the card); when fully shrunk it sits
    // near the top of the compact bar, with the name directly beneath.
    final ringTopExpanded = cardHeight - ringSize + 16.rh(context);
    final ringTopShrunk = 8.rh(context);
    final ringTop = lerpDouble(ringTopExpanded, ringTopShrunk, t)!;
    final nameTop = ringTop + ringSize + 4.rh(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: itemWidth,
        height: itemHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (cardOpacity > 0)
              Positioned(
                top: 0,
                left: (itemWidth - cardWidth) / 2,
                child: Opacity(
                  opacity: cardOpacity,
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.rw(context)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18.rw(context)),
                      child: CustomImage(
                        imageUrl: previewImage,
                        width: cardWidth,
                        height: cardHeight,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: ringTop,
              left: (itemWidth - ringSize) / 2,
              child: Container(
                width: ringSize,
                height: ringSize,
                padding: EdgeInsets.all(2.rw(context)),
                decoration: BoxDecoration(
                  color: context.color.primaryColor,
                  shape: .circle,
                  border: Border.all(color: ringColor, width: 2),
                ),
                child: ClipOval(
                  child: CustomImage(
                    imageUrl: agent.agentProfileImage ?? '',
                    width: ringSize.rw(context),
                    height: ringSize.rw(context),
                  ),
                ),
              ),
            ),
            Positioned(
              top: nameTop,
              left: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: CustomText(
                      agent.agentName ?? '',
                      fontSize: lerpDouble(
                        context.font.xs,
                        context.font.xs - 2,
                        t,
                      ),
                      fontWeight: .w600,
                      color: context.color.textColorDark,
                      maxLines: 1,
                      textAlign: .center,
                    ),
                  ),
                  if (agent.isAgentVerified || agent.isAdmin) ...[
                    SizedBox(width: 4.rw(context)),
                    const VerifiedBadge.agent(
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
