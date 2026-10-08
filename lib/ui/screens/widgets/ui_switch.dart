import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:material_ui/material_ui.dart';

/// A common switch widget used throughout the app.
///
/// Replaces all raw Switch and CupertinoSwitch usages with a consistent
/// style: white thumb, transparent outline, tertiary active track colour, and
/// an optional custom [trackColor] resolver for advanced states (e.g. disabled).
class UiSwitch extends StatelessWidget {
  const UiSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.trackColor,
    this.activeTrackColor,
  });

  final bool value;

  /// Called when the user toggles the switch. Pass `null` to disable.
  final ValueChanged<bool>? onChanged;

  /// Optional custom track-colour resolver. When provided it takes full
  /// control over active, inactive, and disabled colours.
  final WidgetStateProperty<Color>? trackColor;

  /// Override the active (selected) track colour.
  /// Defaults to context.color.tertiaryColor.
  final Color? activeTrackColor;

  @override
  Widget build(BuildContext context) {
    return Switch(
      thumbColor: WidgetStatePropertyAll(context.color.buttonColor),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: WidgetStatePropertyAll(
        Icon(Icons.circle, color: context.color.buttonColor),
      ),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey,
      activeTrackColor: activeTrackColor ?? context.color.tertiaryColor,
      trackColor: trackColor,
      value: value,
      onChanged: onChanged,
    );
  }
}
