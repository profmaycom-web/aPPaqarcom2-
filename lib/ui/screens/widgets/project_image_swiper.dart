import 'dart:math' as math;

import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class ProjectImageSwiper extends StatefulWidget {
  const ProjectImageSwiper({
    required this.images,
    required this.heroTag,
    required this.width,
    required this.height,
    required this.borderRadius,
    this.lowQualityImage,
    this.onTap,
    this.dotSize,
    super.key,
  });

  final List<String> images;
  final String heroTag;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final String? lowQualityImage;
  final VoidCallback? onTap;

  /// Overrides the height-based dot size, e.g. for compact horizontal cards.
  final double? dotSize;

  @override
  State<ProjectImageSwiper> createState() => _ProjectImageSwiperState();
}

class _ProjectImageSwiperState extends State<ProjectImageSwiper> {
  int _currentIndex = 0;
  late final PageController _pageController;

  static const int _kInitialPageMultiplier = 1000;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.images.length > 1
        ? _kInitialPageMultiplier * widget.images.length
        : 0;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: CustomImage(
            imageUrl: '',
            width: widget.width,
            height: widget.height,
          ),
        ),
      );
    }

    if (widget.images.length == 1) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: CustomImage(
            imageUrl: widget.images.first,
            width: widget.width,
            height: widget.height,
            loadingImageHash: widget.lowQualityImage,
          ),
        ),
      );
    }

    final content = RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  final realIndex =
                      (index % widget.images.length + widget.images.length) %
                      widget.images.length;
                  setState(() {
                    _currentIndex = realIndex;
                  });
                },
                itemBuilder: (context, index) {
                  final realIndex =
                      (index % widget.images.length + widget.images.length) %
                      widget.images.length;
                  return CustomImage(
                    imageUrl: widget.images[realIndex],
                    width: widget.width,
                    height: widget.height,
                    loadingImageHash: realIndex == 0
                        ? widget.lowQualityImage
                        : null,
                  );
                },
              ),
              PositionedDirectional(
                bottom: 6.rh(context),
                start: 8.rw(context),
                child: ScrollingDotsIndicator(
                  controller: _pageController,
                  count: widget.images.length,
                  currentIndex: _currentIndex,
                  // Dots scale with the image so small grid cards get
                  // smaller dots than the big cards.
                  dotSize:
                      widget.dotSize ?? (widget.height * 0.045).clamp(4.0, 8.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Instagram-style dot indicator showing at most [_kMaxVisibleDots] dots that
/// taper from big to small. With a [controller] it follows the swipe
/// continuously; without one it animates to [currentIndex].
class ScrollingDotsIndicator extends StatelessWidget {
  const ScrollingDotsIndicator({
    required this.count,
    required this.currentIndex,
    required this.dotSize,
    this.controller,
    super.key,
  });

  final PageController? controller;
  final int count;
  final int currentIndex;
  final double dotSize;

  static const int _kMaxVisibleDots = 4;
  static const Color _kActiveColor = Color(0xFF333333);
  static const Color _kInactiveColor = Color(0xFF6B6B6B);
  static const Duration _kWindowDuration = Duration(milliseconds: 300);

  double get _activeDotSize => dotSize * 1.7;
  double get _slotWidth => _activeDotSize + dotSize * 0.6;

  @override
  Widget build(BuildContext context) {
    final visible = count < _kMaxVisibleDots ? count : _kMaxVisibleDots;
    // Keep the current dot first so the row reads big -> small; the row
    // slides left as you swipe until the last dots come into view.
    final targetStart = currentIndex.clamp(0, count - visible).toDouble();

    return SizedBox(
      width: visible * _slotWidth,
      height: _activeDotSize,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: targetStart),
          duration: _kWindowDuration,
          curve: Curves.easeOutCubic,
          builder: (context, windowStart, _) {
            final pageController = controller;
            if (pageController != null) {
              return AnimatedBuilder(
                animation: pageController,
                builder: (context, _) => _buildDots(
                  _realPage(pageController),
                  windowStart,
                  visible,
                ),
              );
            }
            return TweenAnimationBuilder<double>(
              tween: Tween(end: currentIndex.toDouble()),
              duration: _kWindowDuration,
              curve: Curves.easeOutCubic,
              builder: (context, page, _) =>
                  _buildDots(page, windowStart, visible),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDots(double page, double windowStart, int visible) {
    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(count, (index) {
        final relative = index - windowStart;
        if (relative < -1 || relative > visible) {
          return const SizedBox.shrink();
        }

        // 1 when this dot is the current page, 0 when a full
        // page away; wraps around for the looping PageView.
        var distance = (page - index).abs();
        distance = distance < count - distance ? distance : count - distance;
        final activeness = (1 - distance).clamp(0.0, 1.0);

        // Current dot is biggest; each step away shrinks it,
        // so sizes taper off smoothly on both sides.
        final size =
            _activeDotSize *
            math.pow(0.72, distance).toDouble().clamp(0.3, 1.0);

        return Positioned(
          left: relative * _slotWidth + (_slotWidth - size) / 2,
          top: (_activeDotSize - size) / 2,
          // Inactive: grey dot. Active: white dot with a grey ring.
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                _kInactiveColor,
                Colors.white,
                activeness,
              ),
              border: Border.all(
                color: Color.lerp(
                  _kInactiveColor,
                  _kActiveColor,
                  activeness,
                )!,
                width: 0.5 + dotSize * 0.25 * activeness,
              ),
            ),
          ),
        );
      }),
    );
  }

  double _realPage(PageController controller) {
    final page = controller.hasClients && controller.position.haveDimensions
        ? controller.page ?? currentIndex.toDouble()
        : currentIndex.toDouble();
    return page % count;
  }
}
