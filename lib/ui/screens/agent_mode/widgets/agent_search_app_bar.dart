import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

/// App bar with a title, a search button and a filter button. Tapping search
/// slides a search field in over the title from left to right; tapping it
/// again (now a close icon) slides it out and clears the query.
class AgentSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  const AgentSearchAppBar({
    required this.title,
    required this.onSearchChanged,
    required this.onFilterTap,
    this.filterCount = 0,
    this.hintText,
    super.key,
  });

  final String title;
  final String? hintText;
  final int filterCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AgentSearchAppBar> createState() => _AgentSearchAppBarState();
}

class _AgentSearchAppBarState extends State<AgentSearchAppBar> {
  static const _duration = Duration(milliseconds: 320);
  static const Curve _curve = Curves.easeInOutCubic;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isSearching = false;
  String _lastSent = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _emit(String value) {
    final query = value.trim();
    if (query == _lastSent) return;
    _lastSent = query;
    widget.onSearchChanged(query);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _emit(value));
  }

  void _toggleSearch() {
    _debounce?.cancel();
    setState(() => _isSearching = !_isSearching);
    if (_isSearching) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      _controller.clear();
      _emit('');
    }
  }

  Widget _squareButton({
    required VoidCallback onTap,
    required Widget child,
    bool highlighted = false,
  }) {
    final accent = context.color.tertiaryColor;
    final size = 40.rh(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted
              ? accent.withValues(alpha: 0.15)
              : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlighted ? accent : context.color.borderColor,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _icon(String asset, {Color? color}) => CustomImage(
    imageUrl: asset,
    height: 20.rh(context),
    width: 20.rh(context),
    color: color ?? context.color.textColorDark,
  );

  Widget _buildSearchField() {
    return Container(
      height: 40.rh(context),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.borderColor),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.rw(context)),
      child: Row(
        children: [
          _icon(AppIcons.search, color: context.color.textLightColor),
          SizedBox(width: 8.rw(context)),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmitted: _emit,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: context.color.textColorDark,
                fontSize: context.font.md,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: TextStyle(color: context.color.textLightColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.filterCount;
    return AppBar(
      systemOverlayStyle: UiUtils.getSystemUiOverlayStyle(context: context),
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      elevation: 1.5,
      scrolledUnderElevation: 1.5,
      shadowColor: context.color.inverseSurface.withValues(alpha: .12),
      backgroundColor: context.color.secondaryColor,
      centerTitle: false,
      titleSpacing: 0,
      leadingWidth: 56.rw(context),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          alignment: Alignment.center,
          child: CustomImage(
            imageUrl: AppIcons.arrowLeft,
            width: 24.rh(context),
            height: 24.rh(context),
            matchTextDirection: true,
            color: context.color.textColorDark,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                // Title slides out to the right and fades while searching.
                AnimatedSlide(
                  duration: _duration,
                  curve: _curve,
                  offset: _isSearching ? const Offset(0.25, 0) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: _duration,
                    opacity: _isSearching ? 0 : 1,
                    child: CustomText(
                      widget.title,
                      fontSize: context.font.lg,
                      fontWeight: FontWeight.w500,
                      color: context.color.textColorDark,
                      maxLines: 1,
                    ),
                  ),
                ),
                // Search field reveals from the left edge towards the right.
                IgnorePointer(
                  ignoring: !_isSearching,
                  child: ClipRect(
                    child: AnimatedAlign(
                      duration: _duration,
                      curve: _curve,
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: _isSearching ? 1 : 0,
                      child: AnimatedOpacity(
                        duration: _duration,
                        opacity: _isSearching ? 1 : 0,
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: 12.rw(context),
                            ),
                            child: _buildSearchField(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: EdgeInsetsDirectional.only(end: 16.rw(context)),
      actions: [
        _squareButton(
          onTap: _toggleSearch,
          child: AnimatedSwitcher(
            duration: _duration,
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _icon(
              _isSearching ? AppIcons.closeCircle : AppIcons.search,
            ),
          ),
        ),
        SizedBox(width: 8.rw(context)),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _squareButton(
              onTap: widget.onFilterTap,
              highlighted: count > 0,
              child: _icon(
                AppIcons.filter,
                color: count > 0 ? context.color.tertiaryColor : null,
              ),
            ),
            if (count > 0)
              PositionedDirectional(
                top: -6,
                end: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.color.tertiaryColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: context.color.buttonColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
