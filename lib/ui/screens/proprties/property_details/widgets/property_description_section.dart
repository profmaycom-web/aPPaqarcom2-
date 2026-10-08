import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/read_more_text.dart';

class PropertyDescriptionSection extends StatelessWidget {
  const PropertyDescriptionSection({
    required this.property,
    super.key,
  });

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(
          color: context.color.borderColor,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'aboutThisPropLbl'.translate(context),
            fontWeight: .w600,
            fontSize: context.font.md,
            color: context.color.textColorDark,
          ),
          SizedBox(height: 8.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 8.rh(context)),
          ReadMoreText(
            text: property.translatedDescription ?? property.description ?? '',
            style: TextStyle(
              fontSize: context.font.xs,
              fontWeight: .w500,
              color: context.color.textColorDark,
            ),
            readMoreButtonStyle: TextStyle(
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
