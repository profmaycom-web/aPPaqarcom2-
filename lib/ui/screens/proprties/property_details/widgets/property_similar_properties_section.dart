import 'package:collection/collection.dart';
import 'package:ebroker/data/cubits/advertisement/fetch_ad_banners_cubit.dart';
import 'package:ebroker/data/cubits/property/fetch_similar_properties_cubit.dart';
import 'package:ebroker/data/model/ad_banner_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/property_card_big.dart';

class PropertySimilarPropertiesSection extends StatelessWidget {
  const PropertySimilarPropertiesSection({
    required this.property,
    super.key,
  });

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchAdBannersCubit, FetchAdBannersState>(
      builder: (context, adBannerState) {
        return BlocBuilder<
          FetchSimilarPropertiesCubit,
          FetchSimilarPropertiesState
        >(
          builder: (context, state) {
            if (state is! FetchSimilarPropertiesSuccess ||
                state.properties.isEmpty ||
                property.requestStatus.toString() == 'pending' ||
                property.requestStatus.toString() == 'rejected') {
              return const SizedBox.shrink();
            }

            AdBanner? banner;
            if (adBannerState is FetchAdBannersSuccess) {
              banner = adBannerState.banners.firstWhereOrNull(
                (item) =>
                    item.placement ==
                    AdBannerPlacementType.aboveSimilarProperties.value,
              );
            }

            return Column(
              children: [
                if (adBannerState is FetchAdBannersSuccess &&
                    adBannerState.banners.isNotEmpty &&
                    banner != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 18,
                    ),
                    child: GestureDetector(
                      onTap: () => HelperUtils.onTapBanner(
                        context,
                        banner,
                      ),
                      child: CustomImage(
                        imageUrl: banner.image ?? '',
                        width: context.screenWidth,
                        height: 80.rs(context),
                        fit: .fill,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: context.color.borderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: CustomText(
                          'similarProperties'.translate(context),
                          fontWeight: .w600,
                          fontSize: context.font.md,
                          color: context.color.textColorDark,
                        ),
                      ),
                      SizedBox(height: 10.rh(context)),
                      SizedBox(
                        height: 360.rh(context),
                        child: ListView.builder(
                          scrollDirection: .horizontal,
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          itemCount: state.properties.length,
                          itemBuilder: (context, index) {
                            return BlocProvider(
                              create: (context) {
                                return AddToFavoriteCubitCubit();
                              },
                              child: Container(
                                margin: const EdgeInsetsDirectional.only(
                                  end: 16,
                                ),
                                child: PropertyCardBig(
                                  key: UniqueKey(),
                                  showEndPadding: true,
                                  isFromCompare: true,
                                  isFromGrid: false,
                                  isFirst: index == 0,
                                  property: state.properties[index],
                                  sourceProperty: property,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
