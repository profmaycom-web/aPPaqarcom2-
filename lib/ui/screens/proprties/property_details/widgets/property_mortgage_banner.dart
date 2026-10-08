import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

class PropertyMortgageBanner extends StatelessWidget {
  const PropertyMortgageBanner({
    required this.property,
    required this.onPressed,
    super.key,
  });

  final PropertyModel property;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66.rh(context),
      padding: const EdgeInsets.all(8),
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            context.color.tertiaryColor.withValues(alpha: 0.05),
            context.color.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: context.color.borderColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            height: 42.rh(context),
            width: 42.rw(context),
            child: CustomImage(
              imageUrl: AppIcons.calculator,
              color: context.color.buttonColor,
            ),
          ),
          SizedBox(width: 12.rw(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisAlignment: .center,
              children: [
                CustomText(
                  'calculateMortgage'.translate(context),
                  maxLines: 1,
                  color: context.color.textColorDark,
                  fontSize: context.font.xs,
                  fontWeight: .w500,
                ),
                CustomText(
                  property.price?.toString().priceFormat(
                        context: context,
                        currencyCode: property.currencyCode,
                        currencySymbol: property.currencySymbol,
                      ) ??
                      '',
                  color: context.color.tertiaryColor,
                  maxLines: 1,
                  fontWeight: .w600,
                  fontSize: context.font.md,
                ),
              ],
            ),
          ),
          UiUtils.buildButton(
            context,
            padding: const EdgeInsetsDirectional.only(end: 10, start: 10),
            height: 36.rh(context),
            autoWidth: true,
            showElevation: false,
            buttonColor: Colors.transparent,
            border: BorderSide(
              color: context.color.tertiaryColor,
            ),
            onPressed: () async {
              await onPressed.call();
            },
            buttonTitle: 'tryNow'.translate(context),
            textColor: context.color.tertiaryColor,
            fontSize: 14,
            radius: 5,
          ),
        ],
      ),
    );
  }
}
