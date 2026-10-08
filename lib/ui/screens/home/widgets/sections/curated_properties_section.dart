import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/home/widgets/property_card_big.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/see_all_handlers.dart';

class CuratedPropertiesSection extends StatelessWidget {
  const CuratedPropertiesSection({
    required this.title,
    required this.curatedProperties,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<PropertyModel> curatedProperties;

  @override
  Widget build(BuildContext context) {
    if (curatedProperties.isEmpty) return const SliverToBoxAdapter();
    final displayItems = curatedProperties.take(10).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleHeader(
            enableShowAll: curatedProperties.length > 1,
            onSeeAll: () => onTapCuratedPropertiesSeeAll(context, title),
            title: title,
          ),
          SizedBox(
            height: 284.rh(context),
            child: ListView.separated(
              separatorBuilder: (context, index) =>
                  SizedBox(width: 8.rw(context)),
              itemCount: displayItems.length,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              physics: Constant.scrollPhysics,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return PropertyCardBig(
                  key: ValueKey(displayItems[index].id),
                  isFromGrid: false,
                  isFirst: index == 0,
                  property: displayItems[index],
                  isFromCompare: false,
                  heroTag: 'curated-property-${displayItems[index].id}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
