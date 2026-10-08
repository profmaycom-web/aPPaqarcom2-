import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';

class PromotedCard extends StatelessWidget {
  const PromotedCard({super.key, this.iconOnly = false});

  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: iconOnly
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImage(
            imageUrl: AppIcons.featuredBolt,
            color: Colors.white,
            width: 16.rw(context),
            height: 16.rh(context),
          ),
          if (!iconOnly) ...[
            SizedBox(width: 4.rw(context)),
            CustomText(
              'featured'.translate(context),
              fontWeight: .bold,
              color: Colors.white,
              fontSize: context.font.xs,
            ),
          ],
        ],
      ),
    );
  }
}
