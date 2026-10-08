import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/home/widgets/property_card_big.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/see_all_handlers.dart';
import 'package:ebroker/utils/sliver_grid_delegate_with_fixed_cross_axis_count_and_fixed_height.dart';

class MostViewedSection extends StatelessWidget {
  const MostViewedSection({
    required this.title,
    required this.mostViewedProperties,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<PropertyModel> mostViewedProperties;

  @override
  Widget build(BuildContext context) {
    if (mostViewedProperties.isEmpty) return const SliverToBoxAdapter();
    final itemCount = mostViewedProperties.length.clamp(
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
            enableShowAll: mostViewedProperties.length > 1,
            onSeeAll: () => onTapMostViewedSeeAll(context, title),
            title: title,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
          sliver: SliverGrid.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                  mainAxisSpacing: 8,
                  crossAxisCount: ResponsiveHelper.isLargeTablet(context)
                      ? 4
                      : ResponsiveHelper.isTablet(context)
                      ? 3
                      : 2,
                  height: 248.rh(context),
                  crossAxisSpacing: 8,
                ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final property = mostViewedProperties[index];
              return PropertyCardBig(
                showEndPadding: false,
                isFirst: index == 0,
                isFromGrid: true,
                isFromCompare: false,
                property: property,
                heroTag: 'most-viewed-property-${property.id}',
              );
            },
          ),
        ),
      ],
    );
  }
}
