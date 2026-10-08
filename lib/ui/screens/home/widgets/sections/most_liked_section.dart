import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/home/widgets/property_card_big.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/see_all_handlers.dart';
import 'package:ebroker/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';

class MostLikedSection extends StatelessWidget {
  const MostLikedSection({
    required this.title,
    required this.mostLikedProperties,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<PropertyModel> mostLikedProperties;

  @override
  Widget build(BuildContext context) {
    if (mostLikedProperties.isEmpty) return const SliverToBoxAdapter();
    final itemCount = mostLikedProperties.length.clamp(
      0,
      ResponsiveHelper.isLargeTablet(context)
          ? 8
          : ResponsiveHelper.isTablet(context)
          ? 6
          : 4,
    );
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: TitleHeader(
            enableShowAll: mostLikedProperties.length > 1,
            onSeeAll: () => onTapMostLikedAll(context, title),
            title: title,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
          sliver: SliverGrid.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                  mainAxisSpacing: 6,
                  crossAxisCount: ResponsiveHelper.isLargeTablet(context)
                      ? 4
                      : ResponsiveHelper.isTablet(context)
                      ? 3
                      : 2,
                  height: 248.rh(context),
                  crossAxisSpacing: 6,
                ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final property = mostLikedProperties[index];
              return PropertyCardBig(
                isFromCompare: false,
                showEndPadding: false,
                isFromGrid: true,
                isFirst: index == 0,
                property: property,
                heroTag: 'most-liked-property-${property.id}',
              );
            },
          ),
        ),
      ],
    );
  }
}
