import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class AddStoryAppbar extends StatelessWidget {
  const AddStoryAppbar({
    super.key,
    this.actionIcon,
    this.actionLabel,
    this.onActionTap,
    this.actions,
  });

  final IconData? actionIcon;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  /// When provided, rendered instead of the single [actionIcon]/[actionLabel]
  /// button — lets a screen expose several trailing actions (e.g. crop and
  /// fit-toggle) at once.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .only(top: 16.rh(context)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: .all(12.rw(context)),
              margin: EdgeInsetsDirectional.only(start: 16.rw(context)),
              decoration: const BoxDecoration(
                color: Colors.black12,
                shape: .circle,
              ),
              child: CustomImage(
                imageUrl: AppIcons.arrowLeft,
                matchTextDirection: true,
                height: 24.rh(context),
                color: context.color.buttonColor,
              ),
            ),
          ),
          SizedBox(width: 8.rw(context)),
          CustomText(
            'addStory'.translate(context),
            fontSize: context.font.md,
            color: context.color.buttonColor,
          ),
          const Spacer(),
          if (actions != null && actions!.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(end: 12.rw(context)),
              child: Row(
                mainAxisSize: .min,
                spacing: 8.rw(context),
                children: actions!,
              ),
            )
          else if (onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.rw(context),
                  vertical: 10.rh(context),
                ),
                margin: EdgeInsetsDirectional.only(end: 16.rw(context)),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: .min,
                  spacing: 6.rw(context),
                  children: [
                    if (actionIcon != null)
                      Icon(
                        actionIcon,
                        size: 18.rw(context),
                        color: context.color.buttonColor,
                      ),
                    if (actionLabel != null)
                      CustomText(
                        actionLabel!,
                        fontSize: context.font.xs,
                        color: context.color.buttonColor,
                        fontWeight: FontWeight.w600,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single circular icon action for [AddStoryAppbar.actions], matching the
/// pill button's visual style.
class AddStoryIconAction extends StatelessWidget {
  const AddStoryIconAction({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Highlights the button (e.g. the fit-toggle while "fit to screen" is on).
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: .all(10.rw(context)),
        decoration: BoxDecoration(
          color: isActive ? context.color.tertiaryColor : Colors.black26,
          shape: .circle,
        ),
        child: Icon(
          icon,
          size: 18.rw(context),
          color: context.color.buttonColor,
        ),
      ),
    );
  }
}
