import 'package:ebroker/data/cubits/agents/fetch_property_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_mode/cards/agent_property_card.dart';

class AgentProperties extends StatefulWidget {
  const AgentProperties({
    required this.agentId,
    required this.isAdmin,
    super.key,
  });
  final bool isAdmin;
  final String agentId;

  @override
  State<AgentProperties> createState() => _AgentPropertiesState();
}

class _AgentPropertiesState extends State<AgentProperties> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchAgentsPropertyCubit, FetchAgentsPropertyState>(
      builder: (agentsContext, state) {
        if (state is FetchAgentsPropertyLoading) {
          return SliverToBoxAdapter(child: Center(child: UiUtils.progress()));
        }
        if (state is FetchAgentsPropertySuccess &&
            state.agentsProperty.propertiesData.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              clipBehavior: .antiAlias,
              margin: .only(
                left: 16.rw(context),
                right: 16.rw(context),
                bottom: 8.rh(context),
              ),
              padding: EdgeInsets.only(top: 16.rh(context)),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                border: Border.all(
                  color: context.color.borderColor,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(4),
                ),
              ),
              child: NoDataFound(
                title: 'noPropertiesFound'.translate(context),
                description: 'noPropertiesFoundForAgentDescription'.translate(
                  context,
                ),
                height: MediaQuery.of(context).size.height * 0.25,
                onTapRetry: () async {
                  // Re-fetch while preserving the existing filter and search
                  // query so retrying a zero-result search doesn't widen the
                  // results by silently dropping the applied filter.
                  final existingState = agentsContext
                      .read<FetchAgentsPropertyCubit>()
                      .state;
                  final existingFilter =
                      existingState is FetchAgentsPropertySuccess
                      ? existingState.filter
                      : null;
                  final existingSearch =
                      existingState is FetchAgentsPropertySuccess
                      ? existingState.searchQuery
                      : null;
                  await agentsContext
                      .read<FetchAgentsPropertyCubit>()
                      .fetchAgentsProperty(
                        agentId: widget.agentId,
                        forceRefresh: true,
                        isAdmin: widget.isAdmin,
                        filter: existingFilter,
                        searchQuery: existingSearch,
                      );
                },
              ),
            ),
          );
        }
        if (state is FetchAgentsPropertySuccess &&
            state.agentsProperty.propertiesData.isNotEmpty) {
          final properties = state.agentsProperty.propertiesData;
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
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              sliver: SliverPadding(
                padding: EdgeInsets.all(12.rw(context)),
                sliver: SliverList.builder(
                  itemCount: properties.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= properties.length) {
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
                    return AgentPropertyCard(
                      isSelected: false,
                      isSelectable: false,
                      agentPropertiesData: properties[index],
                    );
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
