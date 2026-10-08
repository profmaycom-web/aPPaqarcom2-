import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class PropertyEnableDisableSection extends StatelessWidget {
  const PropertyEnableDisableSection({
    required this.isEnabled,
    required this.onChanged,
    required this.isDisabled,
    super.key,
  });

  final ValueNotifier<bool> isEnabled;
  final ValueChanged<bool>? onChanged;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.rh(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Row(
        children: [
          CustomText(
            'updatePropertyStatus'.translate(context),
            fontSize: context.font.sm,
            color: context.color.textColorDark,
            fontWeight: .w500,
          ),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: isEnabled,
            builder: (context, value, child) {
              return UiSwitch(
                trackColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.disabled)) {
                      return context.color.textColorDark.withValues(alpha: 0.1);
                    }
                    if (states.contains(WidgetState.selected)) {
                      return context.color.tertiaryColor;
                    }
                    return Colors.grey;
                  },
                ),
                value: value,
                onChanged: isDisabled ? null : onChanged,
              );
            },
          ),
        ],
      ),
    );
  }
}
