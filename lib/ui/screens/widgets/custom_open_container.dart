import 'package:animations/animations.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';

/// A centralized, reusable wrapper around [OpenContainer] that pre-applies all
/// shared configuration values used across card widgets in the project.
///
/// Screen-specific overrides (e.g. a different [closedShape] or
/// [transitionDuration]) can still be passed as optional parameters.
class CustomOpenContainer extends StatelessWidget {
  const CustomOpenContainer({
    required this.openBuilder,
    required this.closedBuilder,
    super.key,
    this.closedColor = Colors.transparent,
    this.openColor = Colors.transparent,
    this.closedShape,
    this.transitionDuration,
    this.transitionType,
    this.middleColor,
    this.useRootNavigator = true,
    this.onClosed,
  });

  /// Called when the route pushed by [openBuilder] has been popped.
  final ClosedCallback<dynamic>? onClosed;

  /// Color of the closed container. Defaults to transparent.
  final Color closedColor;

  /// Color of the open container. Defaults to transparent so translucent/image backdrops remain visible.
  final Color openColor;

  /// Builds the screen shown after the container opens.
  final OpenContainerBuilder<dynamic> openBuilder;

  /// Builds the widget shown in the closed (card) state.
  final CloseContainerBuilder closedBuilder;

  /// Override the closed shape. Defaults to a rounded rectangle with 8dp
  /// radius, which is the standard used across most cards.
  final ShapeBorder? closedShape;

  /// Override the transition duration. Defaults to the [OpenContainer] default
  /// (300 ms).
  ///
  final Duration? transitionDuration;

  /// Override the transition type. Defaults to [ContainerTransitionType.fade].
  final ContainerTransitionType? transitionType;

  /// Override the middle color used during the transition.
  final Color? middleColor;

  /// Whether to use the root Navigator to push the openBuilder route.
  /// Defaults to true to avoid overlapping issues with persistent bottom bars.
  final bool useRootNavigator;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      useRootNavigator: useRootNavigator,
      tappable: false,
      closedElevation: 0,
      openElevation: 0,
      closedColor: closedColor,
      openColor: openColor,
      closedShape:
          closedShape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.rw(context)),
          ),
      openShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.rw(context)),
      ),
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 350),
      transitionType: transitionType ?? ContainerTransitionType.fade,
      middleColor: middleColor ?? Colors.transparent,
      onClosed: onClosed,
      openBuilder: openBuilder,
      closedBuilder: (context, openContainer) {
        return RepaintBoundary(
          child: closedBuilder(context, openContainer),
        );
      },
    );
  }
}
