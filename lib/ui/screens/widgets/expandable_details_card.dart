import 'dart:math' as math;

import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

/// A Myntra-style expandable details card:
/// - Opens as an inset "peek" card over a dimmed backdrop
/// - Swiping up slides the card to full screen and keeps scrolling the
///   content in the same gesture, with native fling/momentum
/// - Swiping down scrolls to the top, collapses to peek, then dismisses
/// - Releasing mid-way snaps to peek or full screen based on velocity
/// - Slides up from the bottom when opened and back down when closed
///
/// The card and its content share a single scroll view, and everything that
/// animates (card position, side inset, corner radius, app bar) is derived
/// from the scroll offset. Only the content's side inset triggers a layout,
/// and only while moving between peek and full screen.
class ExpandableDetailsCard extends StatefulWidget {
  const ExpandableDetailsCard({
    required this.slivers,
    required this.onClose,
    super.key,
    this.bottomNavigationBar,
    this.appBarTitle,
    this.appBarActions,
    this.onExpansionChanged,
  });

  /// Card content, laid out inside the card's scroll view.
  final List<Widget> slivers;

  final FutureOr<void> Function() onClose;
  final Widget? bottomNavigationBar;
  final Widget? appBarTitle;
  final Widget? appBarActions;

  /// Called when the card becomes full screen or leaves full screen.
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<ExpandableDetailsCard> createState() => ExpandableDetailsCardState();
}

class ExpandableDetailsCardState extends State<ExpandableDetailsCard>
    with SingleTickerProviderStateMixin {
  // Open/close slide. Owned here rather than by the route because the card is
  // also shown without a route (in-screen sheet).
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _entrance = CurvedAnimation(
    parent: _entranceController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<Offset> _cardSlide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(_entrance);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  late final ScrollPhysics _physics = _CardScrollPhysics(
    expandExtent: () => _expandExtent,
    canDismiss: () => _dragStartedAtPeek,
    // Deferred so the route isn't popped from inside a scroll activity.
    onDismiss: () => unawaited(Future.microtask(_close)),
  );

  // Distance the card travels from peek to full screen.
  double _expandExtent = 1;
  bool _isExpanded = false;
  bool _isClosing = false;
  // Only a drag that starts with the card at peek may dismiss it. A swipe
  // down from full screen stops at the peek card, like Myntra.
  bool _dragStartedAtPeek = true;

  bool get isExpanded => _isExpanded;

  /// 0 when the card is at peek, 1 when it is full screen.
  ValueListenable<double> get progress => _progress;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _progress.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    _progress.value = (_scrollController.offset / _expandExtent).clamp(
      0.0,
      1.0,
    );
    final expanded = _progress.value >= 0.99;
    if (expanded != _isExpanded) {
      _isExpanded = expanded;
      widget.onExpansionChanged?.call(expanded);
    }
  }

  /// Animates the card to full screen.
  Future<void> expand() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >= _expandExtent) return;
    await _scrollController.animateTo(
      _expandExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _close() async {
    if (_isClosing) return;
    _isClosing = true;
    try {
      await _entranceController.reverse();
      await widget.onClose();
    } finally {
      _isClosing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final appBarHeight = kToolbarHeight + mediaQuery.padding.top;
    _expandExtent = mediaQuery.size.height * 0.12;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!mounted) return;
        await _close();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Semi-transparent backdrop with tap to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: FadeTransition(
                  opacity: _entrance,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: appBarHeight,
              // The clip also limits hit testing, so taps above the card fall
              // through to the backdrop.
              child: SlideTransition(
                position: _cardSlide,
                child: ClipRRect(
                  clipper: _CardClipper(
                    controller: _scrollController,
                    expandExtent: _expandExtent,
                  ),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: Scaffold(
                      backgroundColor: context.color.primaryColor,
                      bottomNavigationBar: widget.bottomNavigationBar,
                      body: NotificationListener<ScrollStartNotification>(
                        onNotification: (notification) {
                          if (notification.depth == 0 &&
                              notification.dragDetails != null) {
                            _dragStartedAtPeek =
                                notification.metrics.pixels <= 1;
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: _physics,
                          slivers: [
                            // Space above the card while it is at peek.
                            SliverToBoxAdapter(
                              child: SizedBox(height: _expandExtent),
                            ),
                            // Inset the content by the same amount the card is
                            // clipped, so its own padding isn't cut off at peek.
                            for (final sliver in widget.slivers)
                              ValueListenableBuilder<double>(
                                valueListenable: _progress,
                                builder: (context, progress, child) =>
                                    SliverPadding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            _CardClipper._sideInset *
                                            (1 - progress),
                                      ),
                                      sliver: child,
                                    ),
                                child: sliver,
                              ),
                            // Short content still needs enough scroll extent for
                            // the card to reach full screen.
                            SliverLayoutBuilder(
                              builder: (context, constraints) {
                                final missing =
                                    _expandExtent +
                                    constraints.viewportMainAxisExtent -
                                    constraints.precedingScrollExtent;
                                return SliverToBoxAdapter(
                                  child: SizedBox(height: math.max(0, missing)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildAppBar(appBarHeight, mediaQuery.padding.top),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(double appBarHeight, double topPadding) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _entrance,
        child: ValueListenableBuilder<double>(
          valueListenable: _progress,
          builder: (context, progress, appBar) {
            if (progress <= 0) return const SizedBox.shrink();
            return Opacity(
              opacity: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.color.primaryColor,
                  boxShadow: [
                    if (progress > 0.5)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15 * progress),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: appBar,
              ),
            );
          },
          child: Container(
            height: appBarHeight,
            padding: EdgeInsets.only(top: topPadding, left: 4, right: 4),
            child: Row(
              children: [
                SizedBox(width: 16.rw(context)),
                HelperUtils.buildBackButton(context, _close, true),
                if (widget.appBarTitle != null)
                  Expanded(child: widget.appBarTitle!)
                else
                  const Spacer(),
                if (widget.appBarActions != null) widget.appBarActions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips the card to its current shape: inset with rounded top corners at
/// peek, edge to edge at full screen. Driven by the scroll offset, so it only
/// triggers a repaint.
class _CardClipper extends CustomClipper<RRect> {
  _CardClipper({required this.controller, required this.expandExtent})
    : super(reclip: controller);

  static const double _sideInset = 16;
  static const double _cornerRadius = 24;

  final ScrollController controller;
  final double expandExtent;

  @override
  RRect getClip(Size size) {
    final offset = controller.hasClients && controller.position.hasPixels
        ? controller.offset
        : 0.0;
    final collapse = 1 - (offset / expandExtent).clamp(0.0, 1.0);
    // Below zero the card follows the finger down (pull to dismiss).
    final top = math.max(0, expandExtent - offset).toDouble();
    final inset = _sideInset * collapse;
    final radius = Radius.circular(_cornerRadius * collapse);
    return RRect.fromLTRBAndCorners(
      inset,
      top,
      size.width - inset,
      size.height,
      topLeft: radius,
      topRight: radius,
    );
  }

  @override
  bool shouldReclip(_CardClipper oldClipper) =>
      oldClipper.controller != controller ||
      oldClipper.expandExtent != expandExtent;
}

/// Scroll physics for [ExpandableDetailsCard]: the first [expandExtent]
/// pixels of scroll move the card between peek and full screen, and a release
/// in that range snaps to the nearest end. Pulling down past peek dismisses.
class _CardScrollPhysics extends BouncingScrollPhysics {
  const _CardScrollPhysics({
    required this.expandExtent,
    required this.canDismiss,
    required this.onDismiss,
    super.parent,
  });

  static const double _dismissDistance = 64;
  static const double _dismissVelocity = 900;
  static const double _snapVelocity = 300;
  // Matches the friction used by iOS style scroll flings.
  static const double _flingDrag = 0.135;

  final ValueGetter<double> expandExtent;
  final ValueGetter<bool> canDismiss;
  final VoidCallback onDismiss;

  static final SpringDescription _snapSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 500);

  @override
  _CardScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CardScrollPhysics(
      expandExtent: expandExtent,
      canDismiss: canDismiss,
      onDismiss: onDismiss,
      parent: buildParent(ancestor),
    );
  }

  double _restingPixels(double pixels, double velocity) =>
      FrictionSimulation(_flingDrag, pixels, velocity).finalX;

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Collapsing from full screen stops at the peek card instead of pulling
    // it down past peek.
    if (!canDismiss() && value < position.minScrollExtent) {
      return value - math.min(position.pixels, position.minScrollExtent);
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final extent = expandExtent();
    final pixels = position.pixels;
    final tolerance = toleranceFor(position);

    if (pixels < 0) {
      if (canDismiss() &&
          (pixels < -_dismissDistance || velocity < -_dismissVelocity)) {
        onDismiss();
      }
      return super.createBallisticSimulation(position, velocity);
    }

    if (pixels >= extent - tolerance.distance || position.outOfRange) {
      // A downward fling in the content stops at the top of the content
      // instead of collapsing the card.
      if (velocity < -tolerance.velocity &&
          pixels > extent &&
          _restingPixels(pixels, velocity) < extent) {
        return FrictionSimulation.through(
          pixels,
          extent,
          velocity,
          -tolerance.velocity,
        );
      }
      return super.createBallisticSimulation(position, velocity);
    }

    // Released between peek and full screen.
    if (velocity > 0 && _restingPixels(pixels, velocity) > extent) {
      // A strong upward fling carries on into the content.
      return super.createBallisticSimulation(position, velocity);
    }
    if (canDismiss() &&
        velocity < -_dismissVelocity &&
        pixels < extent * 0.25) {
      onDismiss();
    }

    final double target;
    if (velocity.abs() > _snapVelocity) {
      target = velocity > 0 ? extent : 0;
    } else {
      final threshold = velocity > 0
          ? 0.25
          : velocity < 0
          ? 0.75
          : 0.5;
      target = pixels / extent >= threshold ? extent : 0;
    }

    if ((pixels - target).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(
      _snapSpring,
      pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
