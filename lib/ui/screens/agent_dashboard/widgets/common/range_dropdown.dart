import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

enum MostViewedListingsRange {
  weekly('weekly', 'weekly'),
  monthly('monthly', 'monthly'),
  lastThreeMonths('last_three_months', 'lastThreeMonths');

  const MostViewedListingsRange(this.apiValue, this.translationKey);

  final String apiValue;
  final String translationKey;
}

enum ListingOverviewRange {
  weekly('weekly', 'weekly'),
  monthly('monthly', 'monthly'),
  yearly('yearly', 'yearly');

  const ListingOverviewRange(this.apiValue, this.translationKey);

  final String apiValue;
  final String translationKey;
}

enum CategoryRange {
  weekly('weekly', 'weekly'),
  monthly('monthly', 'monthly'),
  yearly('yearly', 'yearly');

  const CategoryRange(this.apiValue, this.translationKey);

  final String apiValue;
  final String translationKey;
}

class RangeDropdown<T> extends StatelessWidget {
  const RangeDropdown({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onChanged,
      color: context.color.secondaryColor,
      position: PopupMenuPosition.under,
      padding: .zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.color.borderColor),
        borderRadius: .circular(12.rw(context)),
      ),

      menuPadding: .all(8.rw(context)),
      itemBuilder: (context) => options
          .map(
            (o) => PopupMenuItem<T>(
              value: o,
              height: 32.rh(context),
              padding: EdgeInsets.zero,
              child: Container(
                alignment: .center,
                padding: .symmetric(
                  horizontal: 12.rw(context),
                  vertical: 8.rh(context),
                ),
                decoration: BoxDecoration(
                  color: o == value
                      ? context.color.tertiaryColor.withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      labelOf(o).translate(context),
                      fontSize: context.font.sm,
                      color: context.color.textColorDark,
                    ),
                    if (o == value)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: context.color.tertiaryColor,
                      ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
      child: Row(
        mainAxisSize: .min,
        children: [
          CustomText(
            labelOf(value).translate(context),
            fontSize: context.font.sm,
            fontWeight: .w600,
            color: context.color.textColorDark,
            showUnderline: true,
          ),
          SizedBox(width: 4.rw(context)),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16.rw(context),
            color: context.color.textColorDark,
          ),
        ],
      ),
    );
  }
}
