import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/city_card.dart';
import 'package:ebroker/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';
import 'package:material_ui/material_ui.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({
    required this.isWithImage,
    super.key,
    this.from,
    this.title,
  });

  final String? from;
  final bool isWithImage;
  final String? title;

  @override
  State<CityListScreen> createState() => _CityListScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>?;
    return CupertinoPageRoute(
      builder: (_) => CityListScreen(
        from: args?['from'] as String? ?? '',
        title: args?['title'] as String? ?? '',
        isWithImage: args?['isWithImage'] as bool? ?? false,
      ),
    );
  }
}

class _CityListScreenState extends State<CityListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    unawaited(
      context.read<FetchCityCategoryCubit>().fetchCityCategory(
        forceRefresh: false,
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
        if (context.read<FetchCityCategoryCubit>().hasMoreData()) {
          await context.read<FetchCityCategoryCubit>().fetchMore();
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
        title: widget.title ?? 'allCities'.translate(context),
      ),
      body: BlocBuilder<FetchCityCategoryCubit, FetchCityCategoryState>(
        builder: (context, state) {
          if (state is FetchCityCategoryInProgress) {
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.only(
                left: 18,
                right: 18,
                top: 8,
                bottom: 25,
              ),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    crossAxisCount: widget.isWithImage ? 2 : 3,
                    height: (widget.isWithImage ? 260 : 126).rh(
                      context,
                    ),
                  ),
              itemCount: 25,
              itemBuilder: (context, index) {
                return const CustomShimmer();
              },
            );
          }
          if (state is FetchCityCategoryFail) {
            return SomethingWentWrong(
              errorMessage: state.error.toString(),
            );
          }
          if (state is FetchCityCategorySuccess && state.cities.isEmpty) {
            return NoDataFound(
              title: 'noCityFound'.translate(context),
              description: 'noCityFoundDescription'.translate(
                context,
              ),
              onTapRetry: () async {
                await context.read<FetchCityCategoryCubit>().fetchCityCategory(
                  forceRefresh: true,
                );
              },
            );
          }
          if (state is FetchCityCategorySuccess && state.cities.isNotEmpty) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: Constant.scrollPhysics,
              child: Column(
                children: <Widget>[
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      left: 18,
                      right: 18,
                      top: 8,
                      bottom: 25,
                    ),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          crossAxisCount: widget.isWithImage ? 2 : 3,
                          height: (widget.isWithImage ? 260 : 126).rh(
                            context,
                          ),
                        ),
                    itemCount: state.cities.length,
                    itemBuilder: (context, index) {
                      final city = state.cities[index];
                      return CityCard(
                        count: city.count,
                        name: city.name,
                        city: city,
                        isWithImage: widget.isWithImage,
                      );
                    },
                  ),
                  if (context
                      .watch<FetchCityCategoryCubit>()
                      .isLoadingMore()) ...[
                    Center(child: UiUtils.progress()),
                  ],
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
