import 'package:ebroker/data/cubits/agents/fetch_agents_cubit.dart';
import 'package:ebroker/data/model/agent/agent_list_filter.dart';
import 'package:ebroker/data/model/agent/agent_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_filter_screen.dart';
import 'package:ebroker/ui/screens/agent_mode/cards/agent_card.dart';
import 'package:ebroker/ui/screens/agent_mode/widgets/agent_search_app_bar.dart';
import 'package:ebroker/ui/screens/widgets/follow_button.dart';
import 'package:material_ui/material_ui.dart';

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({
    super.key,
    this.title,
    this.isFollowings = false,
  });

  final String? title;
  final bool isFollowings;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>? ?? {};
    return CupertinoPageRoute(
      builder: (_) => AgentListScreen(
        title: args['title'] as String? ?? '',
        isFollowings: args['isFollowings'] as bool? ?? false,
      ),
    );
  }

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  final ScrollController _scrollController = ScrollController();
  AgentListFilter _filter = const AgentListFilter();

  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<FetchAgentsCubit>().fetchAgents(
        forceRefresh: true,
        isFollowing: widget.isFollowings,
        filter: _filter,
      ),
    );
    addPageScrollListener();
  }

  void addPageScrollListener() {
    _scrollController.addListener(pageScrollListener);
  }

  Future<void> pageScrollListener() async {
    ///This will load data on page end
    if (_scrollController.isEndReached()) {
      if (mounted) {
        if (context.read<FetchAgentsCubit>().hasMoreData()) {
          await context.read<FetchAgentsCubit>().fetchMore();
        }
      }
    }
  }

  Future<void> _applyFilter(AgentListFilter filter) async {
    _filter = filter;
    setState(() {});
    await context.read<FetchAgentsCubit>().fetchAgents(
      forceRefresh: true,
      isFollowing: widget.isFollowings,
      filter: filter,
    );
  }

  Future<void> _openFilterSheet() async {
    final result = await AgentFilterScreen.open(
      context,
      initial: _filter,
    );
    if (result != null && mounted) await _applyFilter(result);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: buildAgentsList(context));
  }

  Widget buildAgentsList(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: widget.isFollowings
          ? CustomAppBar(
              title: widget.title != null && widget.title!.isNotEmpty
                  ? widget.title!
                  : 'followings'.translate(context),
            )
          : AgentSearchAppBar(
              title: widget.title != null && widget.title!.isNotEmpty
                  ? widget.title!
                  : 'agents'.translate(context),
              hintText: 'searchAgents'.translate(context),
              filterCount: _filter.activeCount,
              onSearchChanged: (query) {
                if (query == _filter.search) return;
                unawaited(_applyFilter(_filter.copyWith(search: query)));
              },
              onFilterTap: _openFilterSheet,
            ),
      body: SingleChildScrollView(
        physics: Constant.scrollPhysics,
        controller: _scrollController,
        child: Column(
          children: <Widget>[
            BlocBuilder<FetchAgentsCubit, FetchAgentsState>(
              builder: (context, state) {
                if (state is FetchAgentsFailure) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: Center(
                      child: SomethingWentWrong(
                        errorMessage: state.errorMessage,
                      ),
                    ),
                  );
                }
                if (state is FetchAgentsLoading) {
                  if (widget.isFollowings) {
                    return _buildFollowingsShimmer();
                  }
                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.rw(context),
                      vertical: 12.rh(context),
                    ),
                    itemCount: 4,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 14.rh(context)),
                    itemBuilder: (context, index) {
                      return CustomShimmer(
                        height: 310.rh(context),
                        width: double.infinity,
                        borderRadius: 16.rw(context),
                      );
                    },
                  );
                }
                if (state is FetchAgentsSuccess && state.agents.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: Center(
                      child: NoDataFound(
                        title: 'noAgentsFound'.translate(context),
                        description: 'noAgentsFoundDescription'.translate(
                          context,
                        ),
                        onTapRetry: () async {
                          await context.read<FetchAgentsCubit>().fetchAgents(
                            forceRefresh: true,
                            isFollowing: widget.isFollowings,
                            filter: _filter,
                          );
                        },
                      ),
                    ),
                  );
                }
                if (state is FetchAgentsSuccess && state.agents.isNotEmpty) {
                  if (widget.isFollowings) {
                    return _buildFollowingsListView(state.agents);
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.rw(context),
                      vertical: 12.rh(context),
                    ),
                    itemCount: state.agents.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 14.rh(context)),
                    itemBuilder: (context, index) {
                      final agent = state.agents[index];
                      return AgentCard(
                        agent: agent,
                        propertyCount: agent.propertyCount,
                        name: agent.name,
                        width: double.infinity,
                        showActions: true,
                      );
                    },
                  );
                }
                return Container();
              },
            ),
            if (context.watch<FetchAgentsCubit>().isLoadingMore()) ...[
              Center(
                child: UiUtils.progress(
                  height: 30.rh(context),
                  width: 30.rw(context),
                ),
              ),
            ],
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowingsShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.color.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(6, (index) {
          final isLast = index == 5;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const CustomShimmer(
                      height: 52,
                      width: 52,
                      borderRadius: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomShimmer(
                            height: 14,
                            width: 120.rw(context),
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CustomShimmer(
                      height: 36.rh(context),
                      width: 80.rw(context),
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.color.borderColor.withValues(alpha: 0.4),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFollowingsListView(List<AgentModel> agents) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.color.borderColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(agents.length, (index) {
            final agent = agents[index];
            final isLast = index == agents.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final targetId = agent.isAdmin ? 0 : agent.id;
                          final isCurrentlyFollowing =
                              FollowManager.isFollowingStatus(
                                targetId,
                                initialValue: agent.isFollowing,
                                isAdmin: agent.isAdmin,
                              );
                          await Navigator.pushNamed(
                            context,
                            Routes.agentDetailsScreen,
                            arguments: {
                              'agentID': agent.isAdmin
                                  ? '0'
                                  : agent.id.toString(),
                              'isAdmin': agent.isAdmin,
                              'heroTag': 'agent-hero-${agent.id}',
                              'isFollowing': isCurrentlyFollowing,
                            },
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 52.rw(context),
                              height: 52.rh(context),
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: CustomImage(
                                imageUrl: agent.profile,
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final targetId = agent.isAdmin ? 0 : agent.id;
                            final isCurrentlyFollowing =
                                FollowManager.isFollowingStatus(
                                  targetId,
                                  initialValue: agent.isFollowing,
                                  isAdmin: agent.isAdmin,
                                );
                            await Navigator.pushNamed(
                              context,
                              Routes.agentDetailsScreen,
                              arguments: {
                                'agentID': agent.isAdmin
                                    ? '0'
                                    : agent.id.toString(),
                                'isAdmin': agent.isAdmin,
                                'heroTag': 'agent-hero-${agent.id}',
                                'isFollowing': isCurrentlyFollowing,
                              },
                            );
                          },
                          child: CustomText(
                            agent.name,
                            fontSize: context.font.md,
                            fontWeight: FontWeight.w600,
                            color: context.color.textColorDark,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _FollowingItemButton(
                        agent: agent,
                      ),
                    ],
                  ),
                ),
                if (!isLast) UiUtils.getDivider(context),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _FollowingItemButton extends StatefulWidget {
  const _FollowingItemButton({
    required this.agent,
  });
  final AgentModel agent;

  @override
  State<_FollowingItemButton> createState() => _FollowingItemButtonState();
}

class _FollowingItemButtonState extends State<_FollowingItemButton> {
  bool _isLoading = false;
  late bool _isFollowing;
  StreamSubscription<FollowChangeEvent>? _followSubscription;

  @override
  void initState() {
    super.initState();
    final targetId = widget.agent.isAdmin ? 0 : widget.agent.id;
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
  }

  @override
  void didUpdateWidget(covariant _FollowingItemButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agent.isFollowing != widget.agent.isFollowing) {
      final targetId = widget.agent.isAdmin ? 0 : widget.agent.id;
      _isFollowing = FollowManager.isFollowingStatus(
        targetId,
        initialValue: widget.agent.isFollowing,
        isAdmin: widget.agent.isAdmin,
      );
    }
  }

  @override
  void dispose() {
    unawaited(_followSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FollowButton(
      isFollowing: _isFollowing,
      height: 36.rh(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: () async {
        if (_isLoading) return;
        await GuestChecker.check(
          onNotGuest: () async {
            setState(() {
              _isLoading = true;
            });
            try {
              final newStatus = await FollowManager.toggleFollow(
                widget.agent.id,
                isAdmin: widget.agent.isAdmin,
              );
              if (mounted) {
                setState(() {
                  _isFollowing = newStatus;
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
            } finally {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
        );
      },
    );
  }
}
