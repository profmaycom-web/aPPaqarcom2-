import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';
import 'package:ebroker/ui/screens/home/widgets/property_card_big.dart';
import 'package:ebroker/ui/screens/home/widgets/sections/see_all_handlers.dart';

class PersonalizedSection extends StatelessWidget {
  const PersonalizedSection({
    required this.title,
    required this.personalizedProperties,
    super.key,
  });

  static const double _sidePadding = 18;

  final String title;
  final List<PropertyModel> personalizedProperties;

  @override
  Widget build(BuildContext context) {
    if (personalizedProperties.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          TitleHeader(
            enableShowAll: personalizedProperties.length > 1,
            onSeeAll: () => onTapPersonalizedSeeAll(context, title),
            title: title,
          ),
          SizedBox(
            height: 284.rh(context),
            child: ListView.separated(
              separatorBuilder: (context, index) =>
                  SizedBox(width: 8.rw(context)),
              itemCount: personalizedProperties.length.clamp(0, 6),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              physics: Constant.scrollPhysics,
              scrollDirection: .horizontal,
              itemBuilder: (context, index) {
                var model = personalizedProperties[index];
                model = context.watch<PropertyEditCubit>().get(model);
                return PropertyCardBig(
                  key: ValueKey(personalizedProperties[index].id),
                  showEndPadding: true,
                  isFromCompare: false,
                  isFirst: index == 0,
                  isFromGrid: false,
                  property: model,
                  heroTag: 'personalized-property-${model.id}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
