import 'package:ebroker/data/cubits/agents/fetch_projects_cubit.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_mode/cards/agent_project_card.dart';

class AgentProjects extends StatefulWidget {
  const AgentProjects({
    required this.agentId,
    required this.isAdmin,
    this.selectedFilter,
    this.searchQuery,
    super.key,
  });

  final bool isAdmin;
  final String agentId;
  final FilterApply? selectedFilter;
  final String? searchQuery;

  @override
  State<AgentProjects> createState() => _AgentProjectsState();
}

class _AgentProjectsState extends State<AgentProjects> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchAgentsProjectCubit, FetchAgentsProjectState>(
      builder: (context, state) {
        if (state is FetchAgentsProjectLoading) {
          return SliverToBoxAdapter(
            child: Center(
              child: UiUtils.progress(
                normalProgressColor: context.color.tertiaryColor,
              ),
            ),
          );
        }
        if (state is FetchAgentsProjectFailure) {
          return SliverToBoxAdapter(
            child: SomethingWentWrong(
              errorMessage: state.errorMessage,
            ),
          );
        }
        if (state is FetchAgentsProjectSuccess &&
            state.agentsProperty.projectData.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              clipBehavior: .antiAlias,
              margin: .symmetric(horizontal: 16.rw(context)),
              padding: .symmetric(
                horizontal: 8.rw(context),
                vertical: 24.rh(context),
              ),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                border: Border.all(color: context.color.borderColor),
                borderRadius: .all(Radius.circular(4.rw(context))),
              ),
              child: NoDataFound(
                title: 'noProjectFound'.translate(context),
                description: 'noProjectFoundDescription'.translate(context),
                onTapRetry: () async {
                  await context
                      .read<FetchAgentsProjectCubit>()
                      .fetchAgentsProject(
                        agentId: widget.agentId,
                        forceRefresh: true,
                        isAdmin: widget.isAdmin,
                        filter: widget.selectedFilter,
                        searchQuery: widget.searchQuery,
                      );
                },
              ),
            ),
          );
        }
        if (state is FetchAgentsProjectSuccess) {
          final projects = state.agentsProperty.projectData;
          // Lazily built sliver list: only visible cards are laid out, so the
          // outer NestedScrollView stays smooth as more pages are loaded.
          return SliverPadding(
            padding: EdgeInsets.only(
              left: 16.rw(context),
              right: 16.rw(context),
              bottom: 16.rh(context),
            ),
            sliver: DecoratedSliver(
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                border: Border.all(color: context.color.borderColor),
                borderRadius: .all(Radius.circular(4.rw(context))),
              ),
              sliver: SliverPadding(
                padding: EdgeInsets.all(12.rw(context)),
                sliver: SliverList.builder(
                  itemCount: projects.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= projects.length) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: 12.rh(context),
                          bottom: 8.rh(context),
                        ),
                        child: Center(
                          child: UiUtils.progress(
                            normalProgressColor: context.color.tertiaryColor,
                          ),
                        ),
                      );
                    }
                    return AgentProjectCardBig(project: projects[index]);
                  },
                ),
              ),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}
