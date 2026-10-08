import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ebroker/app/app.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class CustomImage extends StatelessWidget {
  const CustomImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.fit = .cover,
    this.color,
    super.key,
    this.isCircular = false,
    this.matchTextDirection = false,
    this.showFullScreenImage = false,
    this.loadingImageHash,
  });

  const CustomImage.circular({
    required this.imageUrl,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.fit = .cover,
    this.color,
    super.key,
    this.isCircular = true,
    this.matchTextDirection = false,
    this.showFullScreenImage = false,
    this.loadingImageHash,
  });

  final String imageUrl;

  final bool isCircular;
  final Alignment alignment;
  final BoxFit fit;
  final Color? color;
  final double? height;
  final double? width;
  final bool matchTextDirection;
  final bool showFullScreenImage;
  final String? loadingImageHash;
  @override
  Widget build(BuildContext context) {
    final errorImg = appSettings.placeholderLogo ?? '';
    final image = imageUrl.isEmpty ? errorImg : imageUrl;

    final isNetworked = image.startsWith('http');
    final isSvg = image.endsWith('.svg');

    final colorFilter = color != null ? ColorFilter.mode(color!, .srcIn) : null;

    // Decode network images near their on-screen size instead of at full
    // resolution. Full-size decodes of large photos block the raster thread
    // and cause dropped frames while lists scroll. The 2x headroom keeps
    // `BoxFit.cover` crops sharp when the image aspect differs from the box.
    final w = width;
    final memCacheWidth = w != null && w.isFinite && w > 0
        ? (math.max(w, (height ?? 0).isFinite ? height ?? 0 : 0) *
                  MediaQuery.devicePixelRatioOf(context) *
                  2)
              .round()
        : null;

    final errorWidget = errorImg.isEmpty
        ? Image.asset(
            'assets/svg/Fallback/placeholder.svg',
            width: width,
            height: height,
            fit: fit,
            matchTextDirection: matchTextDirection,
          )
        : Image.network(
            errorImg,
            width: width,
            height: height,
            fit: fit,
            matchTextDirection: matchTextDirection,
          );

    return GestureDetector(
      onTap: showFullScreenImage
          ? () async {
              await UiUtils.showFullScreenImage(
                context,
                provider: isNetworked ? NetworkImage(image) : AssetImage(image),
                imageUrl: image,
              );
            }
          : null,
      child: SizedBox(
        width: width,
        height: height,
        // Only clip when circular: a zero-radius clip adds a layer per image
        // for nothing, since the image already paints within its box.
        child: _MaybeCircularClip(
          isCircular: isCircular,
          child: switch ((isNetworked, isSvg)) {
            // asset image
            (false, false) => Image.asset(
              image,
              fit: fit,
              alignment: alignment,
              errorBuilder: (_, o, s) => errorWidget,
              matchTextDirection: matchTextDirection,
              color: color,
            ),
            // svg image
            (false, true) => SvgPicture.asset(
              image,
              colorMapper: MyColorMapper(context.color.tertiaryColor),
              fit: fit,
              width: width,
              height: height,
              colorFilter: colorFilter,
              alignment: alignment,
              matchTextDirection: matchTextDirection,
            ),
            // network image
            (true, false) => CachedNetworkImage(
              fit: fit,
              alignment: alignment,
              imageUrl: image,
              placeholder:
                  loadingImageHash != null && loadingImageHash!.isNotEmpty
                  ? (context, url) => _BlurredImagePlaceholder(
                      imageUrl: loadingImageHash!,
                      width: width,
                      height: height,
                      fit: fit,
                      alignment: alignment,
                      matchTextDirection: matchTextDirection,
                    )
                  : (context, url) => _ShimmerBlurPlaceholder(
                      width: width,
                      height: height,
                    ),
              errorWidget: (_, s, o) => errorWidget,
              matchTextDirection: matchTextDirection,
              maxHeightDiskCache: 1000.rs(context).round(),
              memCacheWidth: memCacheWidth,
            ),
            //
            (true, true) => SvgPicture.network(
              image,
              colorFilter: colorFilter,
              fit: fit,
              alignment: alignment,
              matchTextDirection: matchTextDirection,
            ),
          },
        ),
      ),
    );
  }
}

class _MaybeCircularClip extends StatelessWidget {
  const _MaybeCircularClip({required this.isCircular, required this.child});

  final bool isCircular;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isCircular) return child;
    return ClipRRect(borderRadius: BorderRadius.circular(99999), child: child);
  }
}

class MyColorMapper extends ColorMapper {
  const MyColorMapper(this.tertiaryColor);
  final Color tertiaryColor;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == const Color(0xFF087C7C)) {
      return tertiaryColor;
    }
    if (color == const Color(0xff53ADAE)) {
      return tertiaryColor;
    }

    return color;
  }
}

/// Shows a blurred version of the hash/preview image while the full image loads.
class _BlurredImagePlaceholder extends StatelessWidget {
  const _BlurredImagePlaceholder({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final bool matchTextDirection;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          matchTextDirection: matchTextDirection,
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated shimmer blur placeholder shown when no preview image is available.
class _ShimmerBlurPlaceholder extends StatefulWidget {
  const _ShimmerBlurPlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<_ShimmerBlurPlaceholder> createState() =>
      _ShimmerBlurPlaceholderState();
}

class _ShimmerBlurPlaceholderState extends State<_ShimmerBlurPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = context.color.secondaryColor.withValues(alpha: 0.3);
    final highlightColor = context.color.secondaryColor.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      baseColor,
                      Color.lerp(baseColor, highlightColor, _animation.value)!,
                      baseColor,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
