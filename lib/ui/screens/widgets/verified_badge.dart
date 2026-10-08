import 'package:ebroker/ui/theme/theme.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';

enum BadgeType {
  agent,
  user,
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    this.type = BadgeType.agent,
    this.showBackground = false,
    this.size,
    this.width,
    this.height,
    this.backgroundSize,
    this.backgroundColor,
    this.color,
    this.fit = BoxFit.contain,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.padding,
    this.heroTag,
    this.onTap,
  });

  /// 1. Agent without background
  const VerifiedBadge.agent({
    super.key,
    this.showBackground = false,
    this.size,
    this.width,
    this.height,
    this.backgroundSize,
    this.backgroundColor,
    this.color,
    this.fit = BoxFit.contain,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.padding,
    this.heroTag,
    this.onTap,
  }) : type = BadgeType.agent;

  /// 2. Agent with background
  const VerifiedBadge.agentWithBackground({
    super.key,
    this.size,
    this.width,
    this.height,
    this.backgroundSize,
    this.backgroundColor,
    this.color = Colors.white,
    this.fit = BoxFit.contain,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.padding,
    this.heroTag,
    this.onTap,
  }) : type = BadgeType.agent,
       showBackground = true;

  /// 3. User without background
  const VerifiedBadge.user({
    super.key,
    this.showBackground = false,
    this.size,
    this.width,
    this.height,
    this.backgroundSize,
    this.backgroundColor,
    this.color,
    this.fit = BoxFit.contain,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.padding,
    this.heroTag,
    this.onTap,
  }) : type = BadgeType.user;

  /// 4. User with background
  const VerifiedBadge.userWithBackground({
    super.key,
    this.size,
    this.width,
    this.height,
    this.backgroundSize,
    this.backgroundColor,
    this.color = Colors.white,
    this.fit = BoxFit.contain,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.padding,
    this.heroTag,
    this.onTap,
  }) : type = BadgeType.user,
       showBackground = true;

  /// Convenience constructor based on bool [isAgent]
  const VerifiedBadge.fromType({
    required bool isAgent,
    super.key,
    this.showBackground = false,
    this.size,
    this.width,
    this.height,
    this.backgroundSize,
    this.backgroundColor,
    this.color,
    this.fit = BoxFit.contain,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.padding,
    this.heroTag,
    this.onTap,
  }) : type = isAgent ? BadgeType.agent : BadgeType.user;

  /// Conditionally displays the badge if verified/admin, or returns [SizedBox.shrink]
  static Widget conditional({
    bool isAgentVerified = false,
    bool isUserVerified = false,
    bool isAdmin = false,
    bool showBackground = false,
    String? roleContext,
    double? size,
    double? width,
    double? height,
    double? backgroundSize,
    Color? backgroundColor,
    Color? color,
    BoxFit fit = BoxFit.contain,
    BoxShape shape = BoxShape.circle,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry? padding,
    String? heroTag,
    VoidCallback? onTap,
  }) {
    final isAgent =
        isAdmin ||
        (isAgentVerified && (roleContext == null || roleContext == 'agent')) ||
        (isAgentVerified && !isUserVerified);
    final isUser = isUserVerified && !isAgentVerified;

    if (!isAgent && !isUser && !isAdmin) {
      return const SizedBox.shrink();
    }

    return VerifiedBadge(
      type: isAgent ? BadgeType.agent : BadgeType.user,
      showBackground: showBackground,
      size: size,
      width: width,
      height: height,
      backgroundSize: backgroundSize,
      backgroundColor: backgroundColor,
      color: color,
      fit: fit,
      shape: shape,
      borderRadius: borderRadius,
      padding: padding,
      heroTag: heroTag,
      onTap: onTap,
    );
  }

  final BadgeType type;
  final bool showBackground;
  final double? size;
  final double? width;
  final double? height;
  final double? backgroundSize;
  final Color? backgroundColor;
  final Color? color;
  final BoxFit fit;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final String? heroTag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final defaultIconSize = showBackground ? 14.0 : 16.0;
    final badgeWidth =
        width ??
        (size != null ? size!.rw(context) : defaultIconSize.rw(context));
    final badgeHeight =
        height ??
        (size != null ? size!.rh(context) : defaultIconSize.rh(context));
    final iconUrl = type == BadgeType.agent
        ? AppIcons.agentBadge
        : AppIcons.userBadge;

    final resolvedIconColor =
        color ?? (showBackground ? Colors.white : infoMessageColor);
    final resolvedBgColor = backgroundColor ?? infoMessageColor;

    Widget badge = CustomImage(
      imageUrl: iconUrl,
      color: resolvedIconColor,
      width: badgeWidth,
      height: badgeHeight,
      fit: fit,
    );

    if (showBackground) {
      final bgWidth = backgroundSize != null
          ? backgroundSize!.rw(context)
          : (badgeWidth + 14.rw(context));
      final bgHeight = backgroundSize != null
          ? backgroundSize!.rw(context)
          : (badgeHeight + 14.rw(context));

      badge = Container(
        width: padding != null ? null : bgWidth,
        height: padding != null ? null : bgHeight,
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: resolvedBgColor,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : borderRadius,
        ),
        child: Center(child: badge),
      );
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      badge = Hero(
        tag: heroTag!,
        child: badge,
      );
    }

    if (onTap != null) {
      badge = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }
}
