import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/stories_section.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_app_bar.dart';
import 'package:material_ui/material_ui.dart';

///In this file https://dart.dev/language/generics generic types are used For more info you can see this

///This [PropertySuccessStateWireframe] this will force class to have properties list

abstract class PropertySuccessStateWireframe {
  abstract List<PropertyModel> properties;
  abstract bool isLoadingMore;
}

///this will force class to have error field
abstract class PropertyErrorStateWireframe {
  dynamic error;
}

///This implementation is for cubit this will force property cubit to implement this methods.
abstract class PropertyCubitWireframe {
  void fetch();

  bool hasMoreData();

  void fetchMore();

  /// Fetch with filter + search query. Default falls back to basic [fetch].
  /// Cubits that implement filtering should override this.
  Future<void> fetchWithFilter(FilterApply? filter, String searchQuery) async {
    fetch();
  }
}

class ViewAllScreen<T extends StateStreamable<C>, C> extends StatefulWidget {
  const ViewAllScreen({
    required this.title,
    required this.map,
    super.key,
    this.lockedFilter,
    this.initialFilter,
    this.showFilterButton = true,
  }) : assert(
         T is! PropertyErrorStateWireframe,
         'Please Extend PropertyErrorStateWireframe in cubit',
       );

  final String title;
  final StateMap<
    dynamic,
    dynamic,
    PropertySuccessStateWireframe,
    PropertyErrorStateWireframe
  >
  map;

  /// Filters that cannot be removed by the user (e.g. `premium`, `promoted`).
  final FilterApply? lockedFilter;

  /// Initial user-editable filter applied when the screen opens.
  final FilterApply? initialFilter;

  final bool showFilterButton;

  Future<void> open(BuildContext context) async {
    await Navigator.push(
      context,
      CupertinoPageRoute<dynamic>(
        builder: (context) {
          return ViewAllScreen<T, C>(
            title: title,
            map: map,
            lockedFilter: lockedFilter,
            initialFilter: initialFilter,
            showFilterButton: showFilterButton,
          );
        },
      ),
    );
  }

  @override
  ViewAllScreenState<T, C> createState() => ViewAllScreenState<T, C>();
}

class ViewAllScreenState<T extends StateStreamable<C>, C>
    extends State<ViewAllScreen<dynamic, dynamic>> {
  final ScrollController _pageScrollListener = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);

  /// Only the filters the user has explicitly set (no locked filters).
  FilterApply _userFilter = FilterApply();
  String _lastSearchQuery = '';

  /// Full merged filter = user filter + locked filter (locked always wins).
  FilterApply get _mergedFilter {
    final locked = widget.lockedFilter;
    if (locked == null) return _userFilter;
    final merged = _userFilter.copy();
    locked.activeFilters.forEach(merged.addOrUpdate);
    return merged;
  }

  /// The active category filter's id, if any — passed to the scoped
  /// stories row so it narrows to this category, or shows all stories
  /// when no category is currently applied.
  int? get _storiesCategoryId {
    final categoryFilter = _mergedFilter.get<CategoryFilter>();
    if (categoryFilter.isEmpty) return null;
    return int.tryParse(categoryFilter.categoryId ?? '');
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _userFilter = widget.initialFilter!.copy();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWithFilter();
    });

    _pageScrollListener.addListener(onPageEnd);
  }

  @override
  void dispose() {
    _pageScrollListener.dispose();
    _searchController.dispose();
    _isSearching.dispose();
    super.dispose();
  }

  bool isSubtype<S, U>() => <S>[] is List<U>;

  void onPageEnd() {
    if (_pageScrollListener.isEndReached()) {
      if (isSubtype<T, PropertyCubitWireframe>()) {
        if ((context.read<T>() as PropertyCubitWireframe).hasMoreData()) {
          (context.read<T>() as PropertyCubitWireframe).fetchMore();
        }
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_lastSearchQuery == query) return;
    _lastSearchQuery = query;
    _fetchWithFilter();
  }

  /// Called when the user returns from FilterScreen.
  /// [merged] already has locked filters re-applied by [SearchFilterAppBar].
  /// We compute "user only" by stripping locked filter types.
  void _onFilterApplied(FilterApply merged) {
    final userOnly = merged.copy();
    final locked = widget.lockedFilter;
    if (locked != null) {
      // Strip locked filter types so badge only counts user-editable filters.
      for (final lockedFilter in locked.activeFilters) {
        switch (lockedFilter) {
          case FlagsFilter():
            userOnly.remove<FlagsFilter>();
          case LocationFilter():
            userOnly.remove<LocationFilter>();
          case CategoryFilter():
            userOnly.remove<CategoryFilter>();
          case PropertyTypeFilter():
            userOnly.remove<PropertyTypeFilter>();
          case ProjectTypeFilter():
            userOnly.remove<ProjectTypeFilter>();
          case MinMaxBudget():
            userOnly.remove<MinMaxBudget>();
          case FacilitiesFilter():
            userOnly.remove<FacilitiesFilter>();
          case PostedSince():
            userOnly.remove<PostedSince>();
          case NearbyPlacesFilter():
            userOnly.remove<NearbyPlacesFilter>();
        }
      }
    }
    setState(() {
      _userFilter = userOnly;
    });
    _fetchWithFilter();
  }

  void _fetchWithFilter() {
    final cubit = context.read<T>();
    if (cubit is PropertyCubitWireframe) {
      final merged = _mergedFilter;
      unawaited(
        (cubit as PropertyCubitWireframe).fetchWithFilter(
          merged.hasActiveFilters ? merged : null,
          _lastSearchQuery,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<T, C>(
      builder: (context, state) {
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
              title: widget.title,
              searchController: _searchController,
              searchingListenable: _isSearching,
              currentFilter: _userFilter,
              lockedFilter: widget.lockedFilter,
              showFilterButton: widget.showFilterButton,
              onSearchChanged: _onSearchChanged,
              onFilterApplied: _onFilterApplied,
            ),
            bottomNavigationBar:
                state is PropertySuccessStateWireframe && state.isLoadingMore
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.rh(context)),
                    child: UiUtils.progress(
                      height: 30.rh(context),
                      width: 30.rw(context),
                    ),
                  )
                : null,
            body: CustomScrollView(
              controller: _pageScrollListener,
              physics: Constant.scrollPhysics,
              slivers: [
                StoriesSection.sliver(categoryId: _storiesCategoryId),
                ...widget.map._buildSlivers(state, context),
              ],
            ),
          ),
        );
      },
    );
  }
}

///From generic type we are getting state so we can return ui according to that state
class StateMap<
  INITIAL,
  PROGRESS,
  SUCCESS extends PropertySuccessStateWireframe,
  FAIL extends PropertyErrorStateWireframe
> {
  List<Widget> _buildSlivers(dynamic state, BuildContext context) {
    if (state is INITIAL) {
      return const [SliverToBoxAdapter(child: SizedBox.shrink())];
    }
    if (state is PROGRESS) {
      return [
        SliverToBoxAdapter(child: UiUtils.buildHorizontalShimmer(context)),
      ];
    }
    if (state is FAIL) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SomethingWentWrong(
              errorMessage: state.error.toString(),
            ),
          ),
        ),
      ];
    }
    if (state is SUCCESS && state.properties.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: NoDataFound(
            title: 'noPropertiesFound'.translate(context),
            description: 'noPropertiesFoundDescription'.translate(context),
            onTapRetry: () {
              context.read<PropertyCubitWireframe>().fetch();
            },
            showRetryButton: false,
          ),
        ),
      ];
    }
    if (state is SUCCESS && state.properties.isNotEmpty) {
      final isGridLayout =
          ResponsiveHelper.isLargeTablet(context) ||
          ResponsiveHelper.isTablet(context);
      if (isGridLayout) {
        return [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 130.rh(context),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    PropertyHorizontalCard(property: state.properties[index]),
                childCount: state.properties.length,
              ),
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) return SizedBox(height: 8.rh(context));
                final model = state.properties[index ~/ 2];
                return PropertyHorizontalCard(property: model);
              },
              childCount: state.properties.length * 2 - 1,
            ),
          ),
        ),
      ];
    }

    return const [SliverToBoxAdapter(child: SizedBox.shrink())];
  }
}
