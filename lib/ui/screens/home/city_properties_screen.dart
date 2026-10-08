import 'package:ebroker/data/cubits/property/fetch_city_property_list.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_bar.dart';
import 'package:material_ui/material_ui.dart';

class CityPropertiesScreen extends StatefulWidget {
  const CityPropertiesScreen({required this.cityName, super.key});

  final String cityName;

  static Widget buildWithProviders({required String cityName}) {
    return CityPropertiesScreen(cityName: cityName);
  }

  static Route<dynamic> route(RouteSettings routeSettings) {
    final argument = routeSettings.arguments! as Map;

    return CupertinoPageRoute(
      builder: (_) => CityPropertiesScreen.buildWithProviders(
        cityName: argument['cityName'] as String,
      ),
    );
  }

  @override
  State<CityPropertiesScreen> createState() => _CityPropertiesScreenState();
}

class _CityPropertiesScreenState extends State<CityPropertiesScreen> {
  // Search + filter state
  final TextEditingController _searchController = TextEditingController();
  FilterApply _userFilter = FilterApply();
  String _lastSearchQuery = '';

  // The city filter is always locked — the user cannot remove it.
  FilterApply get _lockedFilter {
    final locked = FilterApply()
      ..addOrUpdate(
        LocationFilter(city: widget.cityName),
      );
    return locked;
  }

  ScrollController cityPropertiesScreenController = ScrollController();

  @override
  void initState() {
    super.initState();
    cityPropertiesScreenController.addListener(_onScroll);
    // Initial data fetch (city filter applied by cubit via cityName parameter)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FetchCityPropertyList>().fetch(
        cityName: widget.cityName,
      );
    });
  }

  Future<void> _onScroll() async {
    if (cityPropertiesScreenController.position.pixels >=
        cityPropertiesScreenController.position.maxScrollExtent - 100) {
      final fetchCubit = context.read<FetchCityPropertyList>();
      if (!fetchCubit.isLoadingMore() && fetchCubit.hasMoreData()) {
        await fetchCubit.fetchMore();
      }
    }
  }

  Future<void> _refetch({bool forceRefresh = true}) async {
    await context.read<FetchCityPropertyList>().fetch(
      cityName: widget.cityName,
      forceRefresh: forceRefresh,
      filter: _userFilter.hasActiveFilters ? _userFilter : null,
      searchQuery: _lastSearchQuery.isEmpty ? null : _lastSearchQuery,
    );
  }

  void _onSearchChanged(String query) {
    if (_lastSearchQuery == query) return;
    _lastSearchQuery = query;
    unawaited(_refetch());
  }

  void _onFilterApplied(FilterApply merged) {
    // Strip the locked city filter out of what we store as "user filter"
    // so the badge only counts user-editable filters.
    final userOnly = merged.copy()..remove<LocationFilter>();
    setState(() {
      _userFilter = userOnly;
    });
    unawaited(_refetch());
  }

  @override
  void dispose() {
    cityPropertiesScreenController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: widget.cityName,
      ),
      body: Column(
        children: [
          SearchFilterBar(
            controller: _searchController,
            currentFilter: _userFilter,
            lockedFilter: _lockedFilter,
            onSearchChanged: _onSearchChanged,
            onFilterApplied: _onFilterApplied,
          ),
          Expanded(
            child: BlocBuilder<FetchCityPropertyList, FetchCityPropertyListState>(
              builder: (context, state) {
                return CustomRefreshIndicator(
                  onRefresh: _refetch,
                  child: Column(
                    children: [
                      if (state is FetchCityPropertyInProgress)
                        Expanded(child: UiUtils.buildHorizontalShimmer(context))
                      else if (state is FetchCityPropertyFail)
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.7,
                          width: MediaQuery.sizeOf(context).width,
                          child: Center(
                            child: SomethingWentWrong(
                              errorMessage: state.error.toString(),
                            ),
                          ),
                        )
                      else if (state is FetchCityPropertySuccess &&
                          state.properties.isNotEmpty)
                        Expanded(
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height,
                            width: MediaQuery.sizeOf(context).width,
                            child:
                                ResponsiveHelper.isLargeTablet(context) ||
                                    ResponsiveHelper.isTablet(context)
                                ? GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                        ),
                                    controller: cityPropertiesScreenController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.properties.length,
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) {
                                      final property = state.properties[index];
                                      return PropertyHorizontalCard(
                                        property: property,
                                        showLikeButton: true,
                                      );
                                    },
                                  )
                                : ListView.separated(
                                    controller: cityPropertiesScreenController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.properties.length,
                                    shrinkWrap: true,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final property = state.properties[index];
                                      return PropertyHorizontalCard(
                                        property: property,
                                        showLikeButton: true,
                                      );
                                    },
                                  ),
                          ),
                        )
                      else
                        Center(
                          child: NoDataFound(
                            title: 'noPropertyAdded'.translate(context),
                            description: 'noPropertyAddedDescription'.translate(
                              context,
                            ),
                            onTapRetry: () => unawaited(_refetch()),
                          ),
                        ),
                      if (context
                          .watch<FetchCityPropertyList>()
                          .isLoadingMore())
                        Center(child: UiUtils.progress()),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
