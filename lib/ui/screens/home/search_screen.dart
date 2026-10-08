import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/stories_section.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_app_bar.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:material_ui/material_ui.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    required this.autoFocus,
    super.key,
  });
  final bool autoFocus;
  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return SearchScreen(
          autoFocus: arguments?['autoFocus'] as bool? ?? false,
        );
      },
    );
  }

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<SearchScreen> {
  @override
  bool get wantKeepAlive => true;
  bool isFocused = false;
  final TextEditingController _searchController = TextEditingController();
  late final ValueNotifier<bool> _isSearching = ValueNotifier(
    widget.autoFocus,
  );
  int offset = 0;
  late ScrollController controller;
  List<PropertyModel> propertylist = [];
  List<dynamic> idlist = [];
  FilterApply? selectedFilter;
  bool showContent = true;
  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<SearchPropertyCubit>().searchProperty(
        '',
        offset: 0,
        filter: selectedFilter,
      ),
    );
    controller = ScrollController()..addListener(pageScrollListen);
  }

  Future<void> pageScrollListen() async {
    if (controller.isEndReached()) {
      if (context.read<SearchPropertyCubit>().hasMoreData()) {
        await context.read<SearchPropertyCubit>().fetchMoreSearchData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          title: 'search'.translate(context),
          searchController: _searchController,
          searchingListenable: _isSearching,
          currentFilter: selectedFilter,
          onSearchChanged: (query) async {
            await context.read<SearchPropertyCubit>().searchProperty(
              query,
              offset: 0,
              filter: selectedFilter,
            );
          },
          onFilterApplied: (filter) async {
            selectedFilter = filter;
            await context.read<SearchPropertyCubit>().searchProperty(
              _searchController.text,
              offset: 0,
              filter: filter,
            );
            setState(() {});
          },
        ),
        bottomNavigationBar: const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: BannerAdWidget(bannerSize: AdSize.banner),
        ),
        body: BlocBuilder<SearchPropertyCubit, SearchPropertyState>(
          builder: (context, state) {
            return CustomScrollView(
              controller: controller,
              physics: Constant.scrollPhysics,
              slivers: [
                const StoriesSection.sliver(),
                SliverToBoxAdapter(child: listWidget(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget listWidget(SearchPropertyState state) {
    if (state is SearchPropertyFetchProgress) {
      return UiUtils.buildHorizontalShimmer(context);
    }
    if (state is SearchPropertyFailure) {
      if (state.errorMessage is NoInternetConnectionError) {
        return NoInternet(
          onRetry: () async {
            await context.read<SearchPropertyCubit>().searchProperty(
              '',
              offset: 0,
              filter: selectedFilter,
            );
          },
        );
      }

      return SomethingWentWrong(
        errorMessage: state.errorMessage,
      );
    }

    if (state is SearchPropertySuccess) {
      if (state.searchedroperties.isEmpty) {
        return Padding(
          padding: .only(top: 64.rh(context)),
          child: NoDataFound(
            onTapRetry: () async {
              await context.read<SearchPropertyCubit>().searchProperty(
                '',
                offset: 0,
                filter: selectedFilter,
              );
            },
            title: 'noPropertiesFound'.translate(context),
            description: 'noPropertyAdded'.translate(context),
          ),
        );
      }
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.rw(context)),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            if (ResponsiveHelper.isLargeTablet(context) ||
                ResponsiveHelper.isLargeTablet(context))
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 130.rh(context),
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.searchedroperties.length,
                itemBuilder: (context, index) {
                  final property = state.searchedroperties[index];
                  final propertiesList = state.searchedroperties;
                  return PropertyHorizontalCard(
                    property: property,
                    properties: propertiesList,
                    isFromSearch: true,
                  );
                },
              )
            else
              ListView.separated(
                separatorBuilder: (context, index) =>
                    SizedBox(height: 8.rh(context)),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.searchedroperties.length,
                itemBuilder: (context, index) {
                  final property = state.searchedroperties[index];
                  final propertiesList = state.searchedroperties;
                  return PropertyHorizontalCard(
                    property: property,
                    properties: propertiesList,
                    isFromSearch: true,
                  );
                },
              ),
            if (state.isLoadingMore)
              UiUtils.progress(
                height: 24.rh(context),
                width: 24.rw(context),
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isSearching.dispose();
    controller.dispose();
    super.dispose();
  }
}
