import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/home/widgets/property_card_big.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/see_all_handlers.dart';

class NearbyPropertiesSection extends StatelessWidget {
  const NearbyPropertiesSection({
    required this.title,
    required this.nearByProperties,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<PropertyModel> nearByProperties;

  @override
  Widget build(BuildContext context) {
    if (HiveUtils.getHomeCityName().toString().isEmpty ||
        nearByProperties.isEmpty ||
        HiveUtils.getHomeCityName() == null) {
      return const SliverToBoxAdapter();
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          TitleHeader(
            enableShowAll: nearByProperties.length > 1,
            onSeeAll: () => onTapNearByPropertiesAll(context, title),
            title: title,
          ),
          SizedBox(
            height: 284.rh(context),
            child: ListView.separated(
              separatorBuilder: (context, index) =>
                  SizedBox(width: 8.rw(context)),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              physics: Constant.scrollPhysics,
              itemCount: nearByProperties.length.clamp(0, 6),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                var model = nearByProperties[index];
                model = context.watch<PropertyEditCubit>().get(model);
                return PropertyCardBig(
                  property: model,
                  isFromCompare: false,
                  isFromGrid: false,
                  heroTag: 'nearby-property-${model.id}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
