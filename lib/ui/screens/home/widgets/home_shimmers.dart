import 'package:ebroker/ui/screens/widgets/custom_shimmer.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';

class PromotedPropertiesShimmer extends StatelessWidget {
  const PromotedPropertiesShimmer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: SizedBox(
        height: 261,
        child: ListView.builder(
          itemCount: 5,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          scrollDirection: .horizontal,
          physics: Constant.scrollPhysics,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 8),
              child: const CustomShimmer(
                height: 272,
                width: 250,
              ),
            );
          },
        ),
      ),
    );
  }
}

class NearbyPropertiesShimmer extends StatelessWidget {
  const NearbyPropertiesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          itemCount: 5,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          scrollDirection: .horizontal,
          physics: Constant.scrollPhysics,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 8),
              child: const CustomShimmer(
                height: 200,
                width: 300,
              ),
            );
          },
        ),
      ),
    );
  }
}

class HorizontalCardsShimmer extends StatelessWidget {
  const HorizontalCardsShimmer({
    super.key,
    this.height = 240,
    this.cardWidth = 260,
    this.count = 5,
  });

  final double height;
  final double cardWidth;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: SizedBox(
        height: height.rh(context),
        child: ListView.builder(
          itemCount: count,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: .horizontal,
          physics: Constant.scrollPhysics,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == count - 1 ? 0 : 10,
              ),
              child: CustomShimmer(
                height: height.rh(context),
                width: cardWidth.rw(context),
              ),
            );
          },
        ),
      ),
    );
  }
}
