import 'package:collection/collection.dart';
import 'package:ebroker/data/cubits/advertisement/fetch_ad_banners_cubit.dart';
import 'package:ebroker/data/model/ad_banner_model.dart';
import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/category_card.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({
    required this.title,
    required this.categories,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: BlocBuilder<FetchAdBannersCubit, FetchAdBannersState>(
        builder: (context, adBannerState) {
          AdBanner? banner;
          if (adBannerState is FetchAdBannersSuccess) {
            banner = adBannerState.banners.firstWhereOrNull(
              (banner) =>
                  banner.placement ==
                  AdBannerPlacementType.belowCategories.value,
            );
          }
          return Column(
            mainAxisSize: .min,
            children: <Widget>[
              TitleHeader(
                title: title,
                enableShowAll: categories.length > 1,
                onSeeAll: () async {
                  await Navigator.pushNamed(context, Routes.categories);
                },
              ),
              SizedBox(
                height: 44.rh(context),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
                  physics: Constant.scrollPhysics,
                  scrollDirection: .horizontal,
                  itemCount: categories.length.clamp(
                    0,
                    AppConfig.maxCategoryShowLengthInHomeScreen,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      frontSpacing: index != 0,
                      onTapCategory: (category) async {
                        Constant.propertyFilter = null;
                        currentVisitingCategoryId = category.id;
                        currentVisitingCategory = category;
                        await Navigator.of(context).pushNamed(
                          Routes.propertiesList,
                          arguments: {
                            'catID': category.id,
                            'catName':
                                category.translatedName ?? category.category,
                          },
                        );
                      },
                      category: category,
                    );
                  },
                ),
              ),
              if (adBannerState is FetchAdBannersSuccess &&
                  adBannerState.banners.isNotEmpty &&
                  banner != null)
                Padding(
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
            ],
          );
        },
      ),
    );
  }
}
