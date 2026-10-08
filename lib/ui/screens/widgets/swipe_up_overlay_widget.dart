import 'dart:async';

import 'package:ebroker/utils/custom_text.dart';
import 'package:material_ui/material_ui.dart';

class OneTimeSwipeUpOverlayWidget extends StatefulWidget {
  const OneTimeSwipeUpOverlayWidget({super.key});

  static bool hasShownInSession = false;

  @override
  State<OneTimeSwipeUpOverlayWidget> createState() =>
      _OneTimeSwipeUpOverlayWidgetState();
}

class _OneTimeSwipeUpOverlayWidgetState
    extends State<OneTimeSwipeUpOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    if (OneTimeSwipeUpOverlayWidget.hasShownInSession) {
      _isVisible = false;
      _controller = AnimationController(vsync: this);
      return;
    }

    OneTimeSwipeUpOverlayWidget.hasShownInSession = true;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _positionAnimation =
        Tween<double>(
          begin: 35,
          end: -35,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOutCubic,
          ),
        );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 25),
    ]).animate(_controller);

    unawaited(
      _controller.forward().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _positionAnimation.value),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CustomText(
                  'Swipe up for details',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
