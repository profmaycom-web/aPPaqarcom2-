import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class ThemeSelectionBottomSheet extends StatelessWidget {
  const ThemeSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.watch<AppThemeCubit>().state;

    final options = [
      (
        mode: ThemeMode.system,
        label: 'systemDefault',
        icon: Icons.settings_suggest_rounded,
      ),
      (
        mode: ThemeMode.light,
        label: 'lightTheme',
        icon: Icons.light_mode_rounded,
      ),
      (
        mode: ThemeMode.dark,
        label: 'darkTheme',
        icon: Icons.dark_mode_rounded,
      ),
    ];

    return CustomBottomSheet(
      title: 'theme'.translate(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = currentTheme == opt.mode;
          final itemColor = isSelected
              ? context.color.tertiaryColor
              : context.color.textLightColor.withValues(
                  alpha: 0.03,
                );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                unawaited(
                  context.read<AppThemeCubit>().changeTheme(opt.mode),
                );
                Navigator.pop(context);
              },
              child: Container(
                height: 48.rh(context),
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      opt.icon,
                      color: isSelected
                          ? context.color.buttonColor
                          : context.color.textColorDark,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomText(
                        opt.label.translate(context),
                        fontWeight: .bold,
                        fontSize: context.font.md,
                        color: isSelected
                            ? context.color.buttonColor
                            : context.color.textColorDark,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        color: context.color.buttonColor,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
