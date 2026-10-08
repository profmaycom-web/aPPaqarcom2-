import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.bottom,
    this.bottomHeight = 52,
    this.actions,
    this.isTransparent = false,
    this.onTapBackButton,
    this.showBackButton = true,
    this.backgroundColor,
    this.showShadow = true,
    this.isFromHome = false,
    this.preventDefaultPop = false,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? bottom;
  final VoidCallback? onTapBackButton;
  final List<Widget>? actions;
  final bool showShadow;
  final bool isTransparent;
  final double bottomHeight;
  final bool showBackButton;
  final Color? backgroundColor;
  final bool isFromHome;
  final bool preventDefaultPop;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: UiUtils.getSystemUiOverlayStyle(context: context),
      scrolledUnderElevation: 1.5,
      leadingWidth: showBackButton ? 56.rw(context) : context.screenWidth,
      forceMaterialTransparency: isTransparent,
      shadowColor: showShadow
          ? context.color.inverseSurface.withValues(alpha: .12)
          : null,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      elevation: isTransparent ? 0 : 1.5,
      centerTitle: false,
      backgroundColor:
          backgroundColor ??
          (isTransparent ? null : context.color.secondaryColor),
      leading: showBackButton
          ? HelperUtils.buildBackButton(
              context,
              onTapBackButton,
              preventDefaultPop,
            )
          : null,
      titleSpacing: showBackButton ? 0 : 16.rw(context),
      title:
          titleWidget ??
          CustomText(
            title ?? '',
            fontSize: isFromHome ? context.font.xl : context.font.lg,
            fontWeight: .w500,
            color: context.color.textColorDark,
            maxLines: 1,
          ),
      actions:
          actions ??
          [Padding(padding: EdgeInsetsDirectional.only(end: 4.rw(context)))],
      actionsPadding: EdgeInsetsDirectional.only(end: 16.rw(context)),
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: Size.fromHeight(bottomHeight),
              child: Container(
                child: bottom,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => bottom == null
      ? const Size.fromHeight(kToolbarHeight)
      : Size.fromHeight(kToolbarHeight + bottomHeight);
}
