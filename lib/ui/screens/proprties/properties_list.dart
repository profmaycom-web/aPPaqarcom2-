import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/stories_section.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_app_bar.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:ebroker/utils/admob/interstitial_ad_manager.dart';
import 'package:material_ui/material_ui.dart';

class PropertiesList extends StatefulWidget {
  const PropertiesList({super.key, this.categoryId, this.categoryName});
  final String? categoryId;
  final String? categoryName;

  @override
  PropertiesListState createState() => PropertiesListState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => PropertiesList(
        categoryId: arguments?['catID'].toString(),
        categoryName: arguments?['catName'].toString() ?? '',
      ),
    );
  }
}

class PropertiesListState extends State<PropertiesList> {
  int offset = 0;
  int total = 0;

  late ScrollController controller;
  List<PropertyModel> propertylist = [];
  int adPosition = 9;
  InterstitialAdManager interstitialAdManager = InterstitialAdManager();

  /// User-applied filter (excludes the locked category filter).
  FilterApply _userFilter = FilterApply();
  String _lastSearchQuery = '';

  /// The category filter is always locked — user cannot remove it.
  FilterApply get _lockedFilter {
    final locked = FilterApply();
    if (widget.categoryId != null) {
      locked.addOrUpdate(CategoryFilter(widget.categoryId));
    }
    return locked;
  }

  FilterApply get _mergedFilter {
    final merged = _userFilter.copy();
    if (widget.categoryId != null) {
      merged.addOrUpdate(CategoryFilter(widget.categoryId));
    }
    return merged;
  }

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    searchbody = {};
    loadAd();
    unawaited(interstitialAdManager.load());
    Constant.propertyFilter = null;
    controller = ScrollController()..addListener(_loadMore);
    unawaited(
      context.read<FetchPropertyFromCategoryCubit>().fetchPropertyFromCategory(
        int.parse(widget.categoryId!),
        showPropertyType: false,
      ),
    );

    Future.delayed(Duration.zero, () {
      selectedcategoryId = widget.categoryId!;
      selectedcategoryName = widget.categoryName!;
      searchbody[Api.categoryId] = widget.categoryId;
      setState(() {});
    });
  }

  void loadAd() {}

  @override
  void dispose() {
    controller
      ..removeListener(_loadMore)
      ..dispose();
    _searchController.dispose();
    _isSearching.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (controller.isEndReached()) {
      if (context.read<FetchPropertyFromCategoryCubit>().hasMoreData()) {
        await context
            .read<FetchPropertyFromCategoryCubit>()
            .fetchPropertyFromCategoryMore(
              catId: int.tryParse(widget.categoryId!) ?? -1,
            );
      }
    }
  }

  Future<void> _refetch() async {
    await context
        .read<FetchPropertyFromCategoryCubit>()
        .fetchPropertyFromCategory(
          int.parse(widget.categoryId!),
          filter: _mergedFilter.hasActiveFilters ? _mergedFilter : null,
          showPropertyType: false,
        );
  }

  void _onSearchChanged(String query) {
    if (_lastSearchQuery == query) return;
    _lastSearchQuery = query;
    // fetchPropertyFromCategory supports filter but not search directly;
    // we pass search via the FilterApply map using the 'search' key by wrapping.
    unawaited(_refetchWithSearch());
  }

  Future<void> _refetchWithSearch() async {
    // Build a merged filter that includes search query.
    // We use the existing filter API — searchQuery will be sent as a filter key.
    final merged = _mergedFilter;
    if (_lastSearchQuery.isNotEmpty) {
      // Pass through a temporary merged filter that includes search;
      // the cubit will forward it to the repository.
      final withSearch = merged.copy();
      // We use the searchProperty API convention: add search to filter map.
      // Since CategoryFilter manages this, we call fetchPropertyFromCategory
      // with the filter that contains everything.
      await context
          .read<FetchPropertyFromCategoryCubit>()
          .fetchPropertyFromCategory(
            int.parse(widget.categoryId!),
            filter: withSearch.hasActiveFilters ? withSearch : null,
            showPropertyType: false,
            searchQuery: _lastSearchQuery,
          );
    } else {
      await _refetch();
    }
  }

  void _onFilterApplied(FilterApply merged) {
    // Strip the locked category filter from what we store as "user filter".
    final userOnly = merged.copy()..remove<CategoryFilter>();
    setState(() {
      _userFilter = userOnly;
    });
    unawaited(_refetchWithSearch());
  }

  Widget? noInternetCheck(dynamic error) {
    if (error is NoInternetConnectionError) {
      return NoInternet(
        onRetry: () async {
          await context
              .read<FetchPropertyFromCategoryCubit>()
              .fetchPropertyFromCategory(
                int.parse(widget.categoryId!),
                showPropertyType: false,
              );
        },
      );
    }

    return null;
  }

  int itemIndex = 0;
  @override
  Widget build(BuildContext context) {
    return bodyWidget();
  }

  Widget bodyWidget() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isSearching.value) {
          _isSearching.value = false;
          return;
        }
        await interstitialAdManager.show();
        Constant.propertyFilter = null;
        Future.delayed(
          Duration.zero,
          () {
            Navigator.pop(context);
          },
        );
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        appBar: SearchFilterAppBar(
          title: selectedcategoryName == ''
              ? widget.categoryName ?? ''
              : selectedcategoryName,
          searchController: _searchController,
          searchingListenable: _isSearching,
          currentFilter: _userFilter,
          lockedFilter: _lockedFilter,
          onSearchChanged: _onSearchChanged,
          onFilterApplied: _onFilterApplied,
        ),
        bottomNavigationBar: const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: BannerAdWidget(bannerSize: AdSize.banner),
        ),
        body: CustomScrollView(
          controller: controller,
          physics: Constant.scrollPhysics,
          slivers: [
            StoriesSection.sliver(
              categoryId: int.tryParse(widget.categoryId ?? ''),
            ),
            BlocBuilder<
              FetchPropertyFromCategoryCubit,
              FetchPropertyFromCategoryState
            >(
              builder: (context, state) {
                if (state is FetchPropertyFromCategoryInProgress) {
                  return SliverToBoxAdapter(
                    child: UiUtils.buildHorizontalShimmer(context),
                  );
                }

                if (state is FetchPropertyFromCategoryFailure) {
                  final error = noInternetCheck(state.errorMessage);
                  if (error != null) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: error,
                    );
                  }
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SomethingWentWrong(
                        errorMessage: state.errorMessage,
                      ),
                    ),
                  );
                }
                if (state is FetchPropertyFromCategorySuccess) {
                  if (state.propertymodel.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: NoDataFound(
                        title: 'noPropertiesFound'.translate(context),
                        description: 'noPropertiesFoundDescription'.translate(
                          context,
                        ),
                        onTapRetry: () async {
                          await context
                              .read<FetchPropertyFromCategoryCubit>()
                              .fetchPropertyFromCategory(
                                int.parse(widget.categoryId!),
                                showPropertyType: false,
                              );
                        },
                      ),
                    );
                  }

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index.isOdd) {
                                return SizedBox(height: 8.rh(context));
                              }
                              final dynamic property =
                                  state.propertymodel[index ~/ 2];
                              if (property is PropertyModel) {
                                return PropertyHorizontalCard(
                                  property: property,
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                            childCount: state.propertymodel.length * 2 - 1,
                          ),
                        ),
                      ),
                      if (state.isLoadingMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 8.rh(context),
                            ),
                            child: Center(
                              child: UiUtils.progress(
                                height: 24.rh(context),
                                width: 24.rw(context),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}
