import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

class PropertyHeader extends StatelessWidget {
  const PropertyHeader({
    required this.property,
    super.key,
    this.heroTag,
  });

  final PropertyModel property;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(height: 12.rh(context)),
        _buildCategoryAndType(context),
        SizedBox(height: 8.rh(context)),
        _buildTitleAndDate(context),
        SizedBox(height: 6.rh(context)),
        _buildPrice(context),
      ],
    );
  }

  Widget _buildCategoryAndType(BuildContext context) {
    final statusColor =
        (property.propertyType.toString().toLowerCase() == 'sell' ||
            property.propertyType.toString().toLowerCase() == 'sold')
        ? Colors.blue
        : Colors.amber;
    return Row(
      children: [
        CustomImage(
          imageUrl: property.category?.image ?? '',
          width: 24.rw(context),
          height: 24.rh(context),
          color: context.color.textColorDark,
        ),
        SizedBox(width: 10.rw(context)),
        Expanded(
          child: heroTag != null
              ? Hero(
                  tag: '$heroTag-category',
                  child: Material(
                    type: MaterialType.transparency,
                    child: CustomText(
                      property.category?.translatedName ??
                          property.category?.category ??
                          '',
                      fontWeight: .w500,
                      fontSize: context.font.sm,
                      color: context.color.textColorDark,
                    ),
                  ),
                )
              : CustomText(
                  property.category?.translatedName ??
                      property.category?.category ??
                      '',
                  fontWeight: .w500,
                  fontSize: context.font.sm,
                  color: context.color.textColorDark,
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: statusColor.withValues(alpha: 0.1),
          ),
          child: Center(
            child: CustomText(
              property.propertyType.toString().toLowerCase().translate(
                context,
              ),
              fontWeight: .w600,
              fontSize: context.font.sm,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndDate(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Expanded(
          child: heroTag != null
              ? Hero(
                  tag: '$heroTag-title',
                  child: Material(
                    type: MaterialType.transparency,
                    child: CustomText(
                      property.translatedTitle ??
                          property.title?.firstUpperCase() ??
                          '',
                      fontWeight: .w800,
                      fontSize: context.font.md,
                      color: context.color.textColorDark,
                    ),
                  ),
                )
              : CustomText(
                  property.translatedTitle ??
                      property.title?.firstUpperCase() ??
                      '',
                  fontWeight: .w800,
                  fontSize: context.font.md,
                  color: context.color.textColorDark,
                ),
        ),
        CustomText(
          property.postCreated ?? '',
          fontSize: context.font.xs,
          fontWeight: .w500,
          color: context.color.textColorDark,
        ),
      ],
    );
  }

  Widget _buildPrice(BuildContext context) {
    var priceText = (property.price ?? '0').priceFormat(
      enabled: Constant.isNumberWithSuffix,
      context: context,
      currencyCode: property.currencyCode,
      currencySymbol: property.currencySymbol,
    );

    if (property.propertyType.toString().toLowerCase() == 'rent' &&
        property.rentduration != '' &&
        property.rentduration != null) {
      priceText =
          '$priceText / ${(property.rentduration ?? '').toLowerCase().translate(context)}';
    }

    return Row(
      children: [
        if (heroTag != null)
          Hero(
            tag: '$heroTag-price',
            child: Material(
              type: MaterialType.transparency,
              child: CustomText(
                priceText,
                fontWeight: .w700,
                fontSize: context.font.sm,
                color: context.color.tertiaryColor,
              ),
            ),
          )
        else
          CustomText(
            priceText,
            fontWeight: .w700,
            fontSize: context.font.sm,
            color: context.color.tertiaryColor,
          ),
        if (Constant.isNumberWithSuffix &&
            property.propertyType.toString().toLowerCase() != 'rent') ...[
          SizedBox(width: 5.rw(context)),
          CustomText(
            '(${(property.price ?? '0').priceFormat(context: context, enabled: false, currencyCode: property.currencyCode, currencySymbol: property.currencySymbol)})',
            fontWeight: .w500,
            fontSize: context.font.sm,
            color: context.color.tertiaryColor,
          ),
        ],
      ],
    );
  }
}
