import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    required this.title,
    required this.onTap,
    super.key,
    this.svgImagePath,
    this.isSwitchBox = false,
    this.trailing,
  });

  final String? svgImagePath;
  final String title;
  final VoidCallback onTap;
  final bool isSwitchBox;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final hasInternet = await HelperUtils.checkInternet();
        if (!hasInternet) {
          return HelperUtils.showSnackBarMessage(
            context,
            'noInternet',
            type: MessageType.error,
          );
        }
        onTap.call();
      },
      child: AbsorbPointer(
        absorbing: !isSwitchBox && trailing == null,
        child: Row(
          children: [
            if (svgImagePath != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.color.textColorDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FittedBox(
                  fit: .none,
                  child: CustomImage(
                    imageUrl: svgImagePath!,
                    height: 24.rh(context),
                    width: 24.rw(context),
                    color: context.color.textColorDark,
                  ),
                ),
              ),
              SizedBox(width: 8.rw(context)),
            ],
            Expanded(
              child: CustomText(
                title,
                fontSize: context.font.md,
                fontWeight: .w700,
                color: context.color.textColorDark,
              ),
            ),
            if (isSwitchBox) ...[
              const _ThemeModeSelector(),
            ] else if (trailing != null) ...[
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = context.read<AppThemeCubit>().isDarkMode;
        return UiSwitch(
          value: isDark,
          onChanged: (val) {
            final newTheme = isDark ? ThemeMode.light : ThemeMode.dark;
            unawaited(context.read<AppThemeCubit>().changeTheme(newTheme));
          },
        );
      },
    );
  }
}
