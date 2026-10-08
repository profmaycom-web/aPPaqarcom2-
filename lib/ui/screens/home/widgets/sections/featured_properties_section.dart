import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/home/widgets/property_card_big.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/see_all_handlers.dart';

class FeaturedPropertiesSection extends StatelessWidget {
  const FeaturedPropertiesSection({
    required this.title,
    required this.featuredProperties,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<PropertyModel> featuredProperties;

  @override
  Widget build(BuildContext context) {
    if (featuredProperties.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          TitleHeader(
            enableShowAll: featuredProperties.length > 1,
            onSeeAll: () => onTapPromotedSeeAll(context, title),
            title: title,
          ),
          SizedBox(
            height: 284.rh(context),
            child: ListView.separated(
              separatorBuilder: (context, index) =>
                  SizedBox(width: 8.rw(context)),
              itemCount: featuredProperties.length.clamp(0, 6),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              physics: Constant.scrollPhysics,
              scrollDirection: .horizontal,
              itemBuilder: (context, index) {
                return PropertyCardBig(
                  key: ValueKey(featuredProperties[index].id),
                  isFromGrid: false,
                  isFirst: index == 0,
                  property: featuredProperties[index],
                  isFromCompare: false,
                  heroTag: 'featured-property-${featuredProperties[index].id}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
