import 'dart:async';

import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';

/// A reusable search + filter bar widget for discovery/exploration screens.
///
/// Features:
/// - Debounced search input (500 ms)
/// - Filter button that navigates to FilterScreen
/// - Active filter count badge (excludes locked filters from count)
/// - Support for locked/persistent filters that survive user "Clear All" actions
///
/// Usage:
/// ```dart
/// SearchFilterBar(
///   controller: _searchController,
///   currentFilter: _userFilter,
///   lockedFilter: FilterApply()..addOrUpdate(FlagsFilter(premium: true, promoted: false)),
///   onSearchChanged: (query) => _fetchWithQuery(query),
///   onFilterApplied: (merged) => _applyFilter(merged),
/// )
/// ```
class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({
    super.key,
    this.controller,
    this.hintText,
    this.onSearchChanged,
    this.currentFilter,
    this.lockedFilter,
    this.showPropertyType = true,
    this.isProject = false,
    this.onFilterApplied,
    this.padding,
    this.height = 48,
    this.showFilterButton = true,
  });

  /// Optional external controller. If null, an internal one is created.
  final TextEditingController? controller;

  final String? hintText;

  /// Called with the search query after 500 ms debounce.
  final ValueChanged<String>? onSearchChanged;

  /// The current user-applied filter (used to compute badge count and passed
  /// as seed to the filter screen).
  final FilterApply? currentFilter;

  /// Filters that are always merged into the result and excluded from the
  /// active-filter badge count. The user cannot remove these via the filter
  /// screen.
  final FilterApply? lockedFilter;

  /// Passed to FilterScreen as `showPropertyType`.
  final bool showPropertyType;

  /// Passed to FilterScreen as `isProject`.
  final bool isProject;

  /// Called with the merged (user + locked) filter after the user applies
  /// filters. The caller should store this as `currentFilter` so the badge
  /// reflects the correct count.
  final ValueChanged<FilterApply>? onFilterApplied;

  /// Padding around the row. Defaults to symmetric 16 h / 8 v.
  final EdgeInsetsGeometry? padding;

  /// Height of both the search field and the filter button.
  final double height;

  final bool showFilterButton;

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late TextEditingController _controller;
  bool _ownsController = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onSearchChanged?.call(_controller.text.trim());
      }
    });
  }

  /// Returns the number of active filters that are NOT locked.
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

  /// Merges the user-returned filter with the locked filters.
  /// Locked filters always win (they overwrite matching types).
  FilterApply _mergeWithLocked(FilterApply userFilter) {
    final locked = widget.lockedFilter;
    if (locked == null) return userFilter;

    final merged = userFilter.copy();
    locked.activeFilters.forEach(merged.addOrUpdate);
    return merged;
  }

  Future<void> _openFilterScreen() async {
    try {
      // Seed the filter screen with the full current filter (user + locked),
      // but the user will be editing only the user-editable portion.
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
        // Always re-merge locked filters after the user applies or clears.
        final merged = _mergeWithLocked(result);
        widget.onFilterApplied?.call(merged);
      }
    } on Exception catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final padding =
        widget.padding ??
        EdgeInsets.symmetric(
          horizontal: 16.rw(context),
          vertical: 8.rh(context),
        );
    final h = widget.height.rh(context);
    final count = _editableFilterCount;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: h,
              child: CustomTextFormField(
                borderColor: context.color.borderColor,
                controller: _controller,
                fillColor: context.color.textLightColor.withValues(alpha: 0.08),
                hintText: widget.hintText ?? 'searchHintLbl'.translate(context),
                prefix: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.rw(context)),
                  child: CustomImage(
                    imageUrl: AppIcons.search,
                    fit: BoxFit.contain,
                    color: context.color.textLightColor,
                    height: 20.rh(context),
                    width: 20.rw(context),
                  ),
                ),
              ),
            ),
          ),
          if (widget.showFilterButton) ...[
            SizedBox(width: 8.rw(context)),
            GestureDetector(
              onTap: _openFilterScreen,
              child: SizedBox(
                height: h,
                width: h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: h,
                      width: h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: count > 0
                            ? context.color.tertiaryColor.withValues(
                                alpha: 0.15,
                              )
                            : context.color.textLightColor.withValues(
                                alpha: .08,
                              ),
                        borderRadius: BorderRadius.circular(6),
                        border: count > 0
                            ? Border.all(
                                color: context.color.tertiaryColor,
                                width: 1.5,
                              )
                            : Border.all(
                                color: context.color.borderColor,
                              ),
                      ),
                      child: CustomImage(
                        imageUrl: AppIcons.filter,
                        height: 20.rh(context),
                        width: 20.rh(context),
                        color: count > 0
                            ? context.color.tertiaryColor
                            : context.color.textColorDark,
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A [SliverPersistentHeaderDelegate] that pins a [SearchFilterBar] (or any
/// widget) to the top of a [CustomScrollView].
class StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  const StickySearchBarDelegate({
    required this.child,
    required this.height,
    this.backgroundColor,
  });

  final Widget child;
  final double height;
  final Color? backgroundColor;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor ?? context.color.backgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickySearchBarDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
