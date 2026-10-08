import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_followers_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_follower_model.dart';
import 'package:material_ui/material_ui.dart';

class AgentFollowersScreen extends StatefulWidget {
  const AgentFollowersScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => AgentDashboardFollowersCubit(),
        child: const AgentFollowersScreen(),
      ),
    );
  }

  @override
  State<AgentFollowersScreen> createState() => _AgentFollowersScreenState();
}

class _AgentFollowersScreenState extends State<AgentFollowersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(context.read<AgentDashboardFollowersCubit>().fetchFollowers());
    _scrollController.addListener(_pageScrollListener);
  }

  void _pageScrollListener() {
    if (_scrollController.isEndReached()) {
      if (mounted) {
        final cubit = context.read<AgentDashboardFollowersCubit>();
        if (cubit.hasMoreData()) {
          unawaited(cubit.fetchMore());
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'followers'.translate(context),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: Constant.scrollPhysics,
        child: Column(
          children: [
            BlocBuilder<
              AgentDashboardFollowersCubit,
              AgentDashboardFollowersState
            >(
              builder: (context, state) {
                if (state is AgentDashboardFollowersFailure) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: Center(
                      child: SomethingWentWrong(
                        errorMessage: state.errorMessage,
                      ),
                    ),
                  );
                }

                if (state is AgentDashboardFollowersLoading ||
                    state is AgentDashboardFollowersInitial) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(
                        6,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomShimmer(
                            height: 72.rh(context),
                            borderRadius: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (state is AgentDashboardFollowersSuccess &&
                    state.followers.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height,
                    child: Center(
                      child: NoDataFound(
                        title: 'noFollowersFound'.translate(context),
                        description: 'noFollowersFoundDescription'.translate(
                          context,
                        ),
                        onTapRetry: () async {
                          await context
                              .read<AgentDashboardFollowersCubit>()
                              .fetchFollowers();
                        },
                      ),
                    ),
                  );
                }

                if (state is AgentDashboardFollowersSuccess &&
                    state.followers.isNotEmpty) {
                  return _buildFollowersList(context, state.followers);
                }

                return const SizedBox.shrink();
              },
            ),
            if (context
                .watch<AgentDashboardFollowersCubit>()
                .isLoadingMore()) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: UiUtils.progress(
                    height: 30.rh(context),
                    width: 30.rw(context),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowersList(
    BuildContext context,
    List<AgentFollowerModel> followers,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(followers.length, (index) {
          final follower = followers[index];
          final isLast = index == followers.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50.rw(context),
                      height: 50.rh(context),
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: CustomImage(
                        imageUrl: follower.profile.isNotEmpty
                            ? follower.profile
                            : AppIcons.profile,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            follower.name.isNotEmpty
                                ? follower.name
                                : follower.slugId,
                            fontSize: context.font.md,
                            fontWeight: FontWeight.w600,
                            color: context.color.textColorDark,
                            maxLines: 1,
                          ),
                          if (follower.email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            CustomText(
                              follower.email,
                              fontSize: context.font.sm,
                              color: context.color.textLightColor,
                              maxLines: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) UiUtils.getDivider(context),
            ],
          );
        }),
      ),
    );
  }
}
