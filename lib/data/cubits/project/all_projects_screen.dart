import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/project_card_horizontal.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/stories_section.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_app_bar.dart';
import 'package:material_ui/material_ui.dart';

class AllProjectsScreen extends StatefulWidget {
  const AllProjectsScreen({
    super.key,
    this.title,
    this.lockedFilter,
  });

  final String? title;

  /// Filter that is always merged in and cannot be changed by the user.
  /// Pass `FilterApply()..addOrUpdate(FlagsFilter(promoted: true, premium: false))`
  /// for featured projects, or `..addOrUpdate(FlagsFilter(promoted: false, premium: true))`
  /// for premium projects.
  final FilterApply? lockedFilter;

  static Route<dynamic> route(RouteSettings settings) {
    final args = settings.arguments as Map?;
    final title = args?['title'] as String? ?? '';

    // Build locked filter from route arguments.
    FilterApply? lockedFilter;
    final isPremium = args?['isPremium'] as bool? ?? false;
    final isPromoted = args?['isPromoted'] as bool? ?? false;
    final isAdminCurated = args?['isAdminCurated'] as bool? ?? false;
    if (isAdminCurated) {
      lockedFilter = FilterApply()
        ..addOrUpdate(
          const FlagsFilter(
            promoted: false,
            premium: false,
            adminCurated: true,
          ),
        );
    } else if (isPremium) {
      lockedFilter = FilterApply()
        ..addOrUpdate(const FlagsFilter(promoted: false, premium: true));
    } else if (isPromoted) {
      lockedFilter = FilterApply()
        ..addOrUpdate(const FlagsFilter(promoted: true, premium: false));
    }

    return CupertinoPageRoute(
      builder: (context) {
        return AllProjectsScreen(
          title: title,
          lockedFilter: lockedFilter,
        );
      },
    );
  }

  @override
  State<AllProjectsScreen> createState() => _AllProjectsScreenState();
}

class _AllProjectsScreenState extends State<AllProjectsScreen> {
  final ScrollController _controller = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);

  FilterApply _userFilter = FilterApply();
  String _lastSearchQuery = '';

  /// Merges the user-chosen filter with any locked filter (locked takes precedence).
  FilterApply get _mergedFilter {
    final locked = widget.lockedFilter;
    if (locked == null) return _userFilter;
    final merged = _userFilter.copy();
    locked.activeFilters.forEach(merged.addOrUpdate);
    return merged;
  }

  @override
  void initState() {
    super.initState();
    unawaited(fetchProjects());
    _controller.addListener(pageScrollListener);
  }

  Future<void> fetchProjects() async {
    final merged = _mergedFilter;
    await context.read<FetchProjectsListCubit>().fetch(
      filter: merged.hasActiveFilters ? merged : null,
    );
  }

  Future<void> _refetch() async {
    final merged = _mergedFilter;
    await context.read<FetchProjectsListCubit>().fetch(
      filter: merged.hasActiveFilters ? merged : null,
      searchQuery: _lastSearchQuery.isEmpty ? null : _lastSearchQuery,
    );
  }

  void _onSearchChanged(String query) {
    if (_lastSearchQuery == query) return;
    _lastSearchQuery = query;
    unawaited(_refetch());
  }

  void _onFilterApplied(FilterApply merged) {
    final userOnly = merged.copy();
    // Strip the locked flags from the user portion so they don't duplicate.
    if (widget.lockedFilter != null) {
      userOnly.remove<FlagsFilter>();
    }
    setState(() {
      _userFilter = userOnly;
    });
    unawaited(_refetch());
  }

  void pageScrollListener() {
    if (_controller.isEndReached()) {
      if (mounted) {
        if (context.read<FetchProjectsListCubit>().hasMoreData()) {
          unawaited(context.read<FetchProjectsListCubit>().fetchMore());
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _isSearching.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = (widget.title?.isNotEmpty ?? false)
        ? widget.title
        : 'projects'.translate(context);

    return ValueListenableBuilder<bool>(
      valueListenable: _isSearching,
      builder: (context, isSearching, child) {
        return PopScope(
          canPop: !isSearching,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && isSearching) _isSearching.value = false;
          },
          child: child!,
        );
      },
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: SearchFilterAppBar(
          title: appBarTitle ?? '',
          searchController: _searchController,
          searchingListenable: _isSearching,
          currentFilter: _userFilter,
          lockedFilter: widget.lockedFilter,
          isProject: true,
          showPropertyType: false,
          onSearchChanged: _onSearchChanged,
          onFilterApplied: _onFilterApplied,
        ),
        body: CustomScrollView(
          controller: _controller,
          physics: Constant.scrollPhysics,
          slivers: [
            const StoriesSection.sliver(),
            SliverToBoxAdapter(
              child:
                  BlocBuilder<FetchProjectsListCubit, FetchProjectsListState>(
                    builder: (context, state) {
                      if (state is FetchProjectsListInProgress) {
                        return UiUtils.buildHorizontalShimmer(context);
                      }
                      if (state is FetchProjectsListFail) {
                        return SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.7,
                          child: Center(
                            child: SomethingWentWrong(
                              errorMessage: state.error.toString(),
                            ),
                          ),
                        );
                      }
                      if (state is FetchProjectsListSuccess) {
                        if (state.projects.isEmpty) {
                          return NoDataFound(
                            title: 'noProjectAdded'.translate(context),
                            description: 'noProjectAddedDescription'.translate(
                              context,
                            ),
                            onTapRetry: () => unawaited(_refetch()),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                          ),
                          child: Column(
                            children: [
                              if (ResponsiveHelper.isLargeTablet(context))
                                GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisExtent: 130.rh(context),
                                        crossAxisSpacing: 12,
                                      ),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.projects.length,
                                  itemBuilder: (context, index) {
                                    final project = state.projects[index];
                                    return ProjectHorizontalCard(
                                      project: project,
                                      isRejected: false,
                                    );
                                  },
                                )
                              else
                                ListView.separated(
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        height: 8.rh(context),
                                      ),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.projects.length,
                                  itemBuilder: (context, index) {
                                    final project = state.projects[index];
                                    return ProjectHorizontalCard(
                                      project: project,
                                      isRejected: false,
                                    );
                                  },
                                ),
                              if (context
                                  .watch<FetchProjectsListCubit>()
                                  .hasMoreData()) ...[
                                SizedBox(height: 8.rh(context)),
                                Center(
                                  child: UiUtils.progress(
                                    height: 24.rh(context),
                                    width: 24.rh(context),
                                  ),
                                ),
                              ],
                              SizedBox(height: 24.rh(context)),
                            ],
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
