import 'package:ebroker/commons/utils/property_project_add_button_tap.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

// ---------------------------------------------------------------------------
// Controller — shared between AddListingButton (bottom bar) and
// AddListingOverlay (body Stack). Parent owns and disposes it.
// ---------------------------------------------------------------------------

class AddListingController extends ChangeNotifier {
  bool _isOpen = false;
  bool get isOpen => _isOpen;

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void toggle() => _isOpen ? close() : open();
}

// ---------------------------------------------------------------------------
// AddListingOverlay — place this inside the body Stack of each host screen
// so it renders behind the bottom bar.
// ---------------------------------------------------------------------------

class AddListingOverlay extends StatefulWidget {
  const AddListingOverlay({required this.controller, super.key});

  final AddListingController controller;

  @override
  State<AddListingOverlay> createState() => _AddListingOverlayState();
}

class _AddListingOverlayState extends State<AddListingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _projectController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    reverseDuration: const Duration(milliseconds: 400),
  );
  late final AnimationController _propertyController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 300),
  );

  // Values match the original body-Stack Tween values exactly.
  late final Animation<double> _propertyAnim =
      Tween<double>(begin: -60.rh(context), end: 30.rh(context)).animate(
        CurvedAnimation(parent: _propertyController, curve: Curves.easeIn),
      );
  late final Animation<double> _projectAnim =
      Tween<double>(begin: -60.rh(context), end: 80.rh(context)).animate(
        CurvedAnimation(parent: _projectController, curve: Curves.easeIn),
      );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (widget.controller.isOpen) {
      _propertyController.forward();
      _projectController.forward();
    } else {
      _propertyController.reverse();
      _projectController.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _projectController.dispose();
    _propertyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller,
        _propertyController,
        _projectController,
      ]),
      builder: (context, _) {
        final isOpen = widget.controller.isOpen;
        final animating =
            _propertyController.status != .dismissed ||
            _projectController.status != .dismissed;

        if (!isOpen && !animating) return const SizedBox.shrink();

        return SizedBox.expand(
          child: Stack(
            children: [
              if (isOpen)
                GestureDetector(
                  onTap: widget.controller.close,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              _floatingButton(
                tween: _propertyAnim,
                leftOffset: 90.rw(context),
                width: 180.rw(context),
                icon: AppIcons.propertiesIcon,
                label: 'property',
                type: PropertyAddType.property,
              ),
              _floatingButton(
                tween: _projectAnim,
                leftOffset: 64.rw(context),
                width: 128.rw(context),
                icon: AppIcons.upcomingProject,
                label: 'project',
                type: PropertyAddType.project,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _floatingButton({
    required Animation<double> tween,
    required double leftOffset,
    required double width,
    required String icon,
    required String label,
    required PropertyAddType type,
  }) {
    return Positioned(
      bottom: tween.value,
      left: (context.screenWidth / 2) - leftOffset,
      child: GestureDetector(
        onTap: () async {
          widget.controller.close();
          await handleAddPropertyOrProjectTap(context, type);
        },
        child: Container(
          width: width,
          height: 44.rh(context),
          decoration: BoxDecoration(
            color: context.color.tertiaryColor,
            borderRadius: BorderRadius.circular(22.rw(context)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: .center,
            children: [
              CustomImage(
                imageUrl: icon,
                color: context.color.buttonColor,
                width: 20.rw(context),
                height: 20.rh(context),
              ),
              SizedBox(width: 7.rw(context)),
              CustomText(
                label.translate(context),
                fontSize: context.font.xs,
                fontWeight: .w500,
                color: context.color.buttonColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AddListingButton — the FAB placed in the bottom bar.
// ---------------------------------------------------------------------------

class AddListingButton extends StatefulWidget {
  const AddListingButton({required this.controller, super.key});

  final AddListingController controller;

  @override
  State<AddListingButton> createState() => AddListingButtonState();
}

class AddListingButtonState extends State<AddListingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _plusController = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (widget.controller.isOpen) {
      _plusController.forward();
    } else {
      _plusController.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _plusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _plusController]),
      builder: (context, _) {
        final isOpen = widget.controller.isOpen;
        return GestureDetector(
          behavior: .opaque,
          onTap: widget.controller.toggle,
          child: SizedBox(
            width: 56.rw(context),
            height: 56.rh(context),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: .none,
              children: [
                if (context.color.brightness == .light)
                  Container(
                    height: 48.rh(context),
                    width: 46.rw(context),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99999),
                      boxShadow: [
                        BoxShadow(
                          color: context.color.textColorDark.withValues(
                            alpha: 0.5,
                          ),
                          offset: const Offset(0, -1.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                AnimatedScale(
                  scale: isOpen ? 1.15 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedRotation(
                    turns: isOpen ? 1 / 3 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: CustomImage(
                      imageUrl: AppIcons.addButtonShape,
                      color: context.color.tertiaryColor,
                      height: 56.rh(context),
                      width: 56.rw(context),
                    ),
                  ),
                ),
                Container(
                  height: 56.rh(context),
                  width: 56.rw(context),
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: _plusController,
                    builder: (context, child) => Transform.rotate(
                      angle: _plusController.value * (135 * (pi / 180)),
                      child: child,
                    ),
                    child: CustomImage(
                      imageUrl: AppIcons.plusButtonIcon,
                      color: context.color.buttonColor,
                      height: 18.rh(context),
                      width: 18.rw(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
