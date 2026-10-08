import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

/// A [CustomAppBar] with search + filter actions that, on tapping search,
/// animates into a full-width search field (title/back-button/filter hidden),
/// similar to Airbnb's search transition.
///
/// Search text is debounced (500ms) before [onSearchChanged] fires.
/// [onFilterApplied] is called with the fully merged (user + locked) filter,
/// matching the contract the old `SearchFilterBar` used.
///
/// Pass [searchingListenable] (owned by the caller) so the caller can react
/// to search-mode toggles too — e.g. to intercept the back gesture with a
/// `PopScope` and close search instead of popping the screen.
class SearchFilterAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SearchFilterAppBar({
    required this.title,
    required this.searchController,
    required this.searchingListenable,
    super.key,
    this.currentFilter,
    this.lockedFilter,
    this.showFilterButton = true,
    this.showPropertyType = true,
    this.isProject = false,
    this.onSearchChanged,
    this.onFilterApplied,
  });

  final String title;
  final TextEditingController searchController;

  /// Owned by the caller; toggled internally and readable externally
  /// (e.g. from a `PopScope` to decide whether to close search on back).
  final ValueNotifier<bool> searchingListenable;

  /// The current user-applied filter (used to compute the badge count).
  final FilterApply? currentFilter;

  /// Filters that are always merged in and excluded from the badge count.
  final FilterApply? lockedFilter;

  final bool showFilterButton;
  final bool showPropertyType;
  final bool isProject;

  /// Called with the trimmed, debounced search query.
  final ValueChanged<String>? onSearchChanged;

  /// Called with the merged (user + locked) filter after the user applies
  /// filters on the FilterScreen.
  final ValueChanged<FilterApply>? onFilterApplied;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchFilterAppBar> createState() => SearchFilterAppBarState();
}

class SearchFilterAppBarState extends State<SearchFilterAppBar> {
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onTextChanged);
    if (widget.searchingListenable.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onTextChanged);
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onSearchChanged?.call(widget.searchController.text.trim());
      }
    });
  }

  void _setSearching(bool searching) {
    widget.searchingListenable.value = searching;
    if (searching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    } else {
      widget.searchController.clear();
    }
  }

  /// Closes search mode if it's open. Returns true if it was open.
  /// Meant to be called from the caller's `PopScope` back-interception.
  bool closeSearchIfOpen() {
    if (widget.searchingListenable.value) {
      _setSearching(false);
      return true;
    }
    return false;
  }

  int get _editableFilterCount {
    final current = widget.currentFilter;
    if (current == null) return 0;
    final locked = widget.lockedFilter;
    if (locked == null) return current.activeFilters.length;
    final lockedTypes = locked.activeFilters.map((f) => f.runtimeType).toSet();
    return current.activeFilters
        .where((f) => !lockedTypes.contains(f.runtimeType))
        .length;
  }

  FilterApply _mergeWithLocked(FilterApply userFilter) {
    final locked = widget.lockedFilter;
    if (locked == null) return userFilter;
    final merged = userFilter.copy();
    locked.activeFilters.forEach(merged.addOrUpdate);
    return merged;
  }

  Future<void> _openFilterScreen() async {
    try {
      final seed = _mergeWithLocked(widget.currentFilter ?? FilterApply());
      final result = await Navigator.pushNamed(
        context,
        Routes.filterScreen,
        arguments: {
          'showPropertyType': widget.showPropertyType,
          'filter': seed,
          'isProject': widget.isProject,
          'lockedFilter': widget.lockedFilter,
        },
      );

      if (result != null && result is FilterApply && mounted) {
        final merged = _mergeWithLocked(result);
        widget.onFilterApplied?.call(merged);
      }
    } on Exception catch (_) {}
  }

  Widget _iconButton({
    required String icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final highlighted = badgeCount > 0;
    final accent = context.color.tertiaryColor;
    // Vertical/end padding keeps the overflowing badge inside the title row,
    // which is clipped by the AnimatedSwitcher's SizeTransition.
    return Padding(
      padding: EdgeInsetsDirectional.only(
        end: 8.rw(context),
        top: 6,
        bottom: 6,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 40.rh(context),
          width: 40.rh(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlighted ? accent.withValues(alpha: 0.15) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: highlighted ? accent : context.color.borderColor,
                  ),
                ),
                child: CustomImage(
                  imageUrl: icon,
                  height: 20.rh(context),
                  width: 20.rh(context),
                  color: highlighted ? accent : context.color.textColorDark,
                ),
              ),
              if (highlighted)
                PositionedDirectional(
                  top: -6,
                  end: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '$badgeCount',
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
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      key: const ValueKey('title-row'),
      children: [
        Expanded(
          child: CustomText(
            widget.title,
            fontSize: context.font.lg,
            fontWeight: .w500,
            color: context.color.textColorDark,
            maxLines: 1,
          ),
        ),
        _iconButton(
          icon: AppIcons.search,
          onTap: () => _setSearching(true),
        ),
        if (widget.showFilterButton)
          _iconButton(
            icon: AppIcons.filter,
            onTap: _openFilterScreen,
            badgeCount: _editableFilterCount,
          ),
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      key: const ValueKey('search-row'),
      children: [
        Expanded(
          child: SizedBox(
            height: 44.rh(context),
            child: CustomTextFormField(
              controller: widget.searchController,
              focusNode: _searchFocusNode,
              borderColor: context.color.borderColor,
              fillColor: context.color.textLightColor.withValues(alpha: 0.08),
              hintText: 'searchHintLbl'.translate(context),
              prefix: Padding(
                padding: .symmetric(horizontal: 12.rw(context)),
                child: CustomImage(
                  imageUrl: AppIcons.search,
                  fit: .contain,
                  color: context.color.textLightColor,
                  height: 20.rh(context),
                  width: 20.rw(context),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 4.rw(context)),
        GestureDetector(
          onTap: () => _setSearching(false),
          child: Padding(
            padding: .all(8.rw(context)),
            child: CustomImage(
              imageUrl: AppIcons.closeCircle,
              color: context.color.textColorDark,
              height: 24.rh(context),
              fit: .contain,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.searchingListenable,
      builder: (context, isSearching, _) {
        return CustomAppBar(
          showBackButton: !isSearching,
          actions: const [],
          titleWidget: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                child: child,
              ),
            ),
            child: isSearching
                ? _buildSearchRow(context)
                : _buildTitleRow(context),
          ),
        );
      },
    );
  }
}
