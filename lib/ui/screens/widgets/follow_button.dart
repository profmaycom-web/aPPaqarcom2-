import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:material_ui/material_ui.dart';

class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    this.onTap,
    this.text,
    this.isFollowing = false,
    this.padding,
    this.borderRadius = 4,
    this.height,
  });

  final VoidCallback? onTap;
  final String? text;
  final bool isFollowing;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final displayText =
        text ??
        (isFollowing
            ? 'unfollow'.translate(context)
            : 'follow'.translate(context));
    final bgColor = isFollowing
        ? context.color.textLightColor.withValues(alpha: 0.12)
        : context.color.tertiaryColor.withValues(alpha: 0.12);
    final textColor = isFollowing
        ? context.color.textColorDark
        : context.color.tertiaryColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: CustomText(
          displayText,
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: context.font.xs,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
