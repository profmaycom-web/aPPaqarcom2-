import 'package:collection/collection.dart';
import 'package:ebroker/data/cubits/advertisement/fetch_ad_banners_cubit.dart';
import 'package:ebroker/data/cubits/fetch_home_sections_data_cubit.dart';
import 'package:ebroker/data/cubits/property/home_infinityscroll_cubit.dart';
import 'package:ebroker/data/model/ad_banner_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';

class AllPropertiesSection extends StatelessWidget {
  const AllPropertiesSection({super.key});

  static const double _sidePadding = 18;

  @override
  Widget build(BuildContext context) {
    final sectionsState = context.watch<FetchHomeSectionsDataCubit>().state;
    if (sectionsState is FetchHomeSectionsDataSuccess &&
        !sectionsState.data.allPropertiesSection) {
      return const SliverToBoxAdapter();
    }

    return BlocBuilder<
      HomePageInfinityScrollCubit,
      HomePageInfinityScrollState
    >(
      builder: (context, state) {
        if (state is HomePageInfinityScrollInProgress) {
          return SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, c) => UiUtils.buildHorizontalShimmer(context),
            ),
          );
        }
        if (state is! HomePageInfinityScrollSuccess) {
          return const SliverToBoxAdapter();
        }
        if (state.properties.isEmpty) {
          return const SliverToBoxAdapter();
        }

        final isTablet =
            ResponsiveHelper.isLargeTablet(context) ||
            ResponsiveHelper.isTablet(context);
        final isLoadingMore = context
            .watch<HomePageInfinityScrollCubit>()
            .isLoadingMore();

        return SliverMainAxisGroup(
          slivers: [
            BlocBuilder<FetchAdBannersCubit, FetchAdBannersState>(
              builder: (context, adBannerState) {
                AdBanner? banner;
                if (adBannerState is FetchAdBannersSuccess) {
                  banner = adBannerState.banners.firstWhereOrNull(
                    (banner) =>
                        banner.placement ==
                        AdBannerPlacementType.aboveAllProperties.value,
                  );
                }
                if (adBannerState is FetchAdBannersSuccess &&
                    adBannerState.banners.isNotEmpty &&
                    banner != null) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: _sidePadding,
                      ),
                      child: GestureDetector(
                        onTap: () => HelperUtils.onTapBanner(context, banner),
                        child: CustomImage(
                          imageUrl: banner.image ?? '',
                          width: context.screenWidth,
                          height: 80.rs(context),
                          fit: .fill,
                        ),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter();
              },
            ),
            SliverToBoxAdapter(
              child: TitleHeader(
                enableShowAll: false,
                title: 'allProperties'.translate(context),
              ),
            ),
            if (isTablet)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sidePadding,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 132.rh(context),
                  ),
                  itemCount: state.properties.length,
                  itemBuilder: (context, index) {
                    return PropertyHorizontalCard(
                      property: state.properties[index],
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _sidePadding,
                ),
                sliver: SliverList.separated(
                  itemCount: state.properties.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 8.rh(context)),
                  itemBuilder: (context, index) {
                    return PropertyHorizontalCard(
                      property: state.properties[index],
                    );
                  },
                ),
              ),
            if (isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: UiUtils.progress(
                      height: 30.rh(context),
                      width: 30.rw(context),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
