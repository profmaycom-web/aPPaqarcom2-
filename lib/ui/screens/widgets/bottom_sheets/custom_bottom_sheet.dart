import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class CustomBottomSheet extends StatelessWidget {
  const CustomBottomSheet({
    required this.child,
    super.key,
    this.title,
    this.padding,
    this.showDragHandle = true,
    this.useSafeArea = true,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final bool showDragHandle;
  final bool useSafeArea;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = false,
    bool showDragHandle = true,
    bool useSafeArea = true,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    double? borderRadius,
    bool enableDrag = true,
    AnimationStyle? sheetAnimationStyle,
    double? elevation,
    BoxConstraints? constraints,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      sheetAnimationStyle: sheetAnimationStyle,
      elevation: elevation,
      constraints: constraints,
      backgroundColor: backgroundColor ?? context.color.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius ?? 20),
        ),
      ),
      builder: (context) => CustomBottomSheet(
        title: title,
        padding: padding,
        showDragHandle: showDragHandle,
        useSafeArea: useSafeArea,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final resolvedPadding =
        (padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 16)).add(
          EdgeInsets.only(bottom: viewInsetsBottom),
        );
    Widget content = Padding(
      padding: resolvedPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDragHandle) ...[
            Center(
              child: Container(
                width: 40.rw(context),
                height: 4.rh(context),
                margin: EdgeInsets.symmetric(vertical: 16.rh(context)),
                decoration: BoxDecoration(
                  color: context.color.textColorDark.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
          if (title != null && title!.isNotEmpty) ...[
            CustomText(
              title!,
              fontSize: context.font.lg,
              fontWeight: FontWeight.w700,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 16.rh(context)),
          ],
          Flexible(child: child),
          SizedBox(height: 16.rh(context)),
        ],
      ),
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}
