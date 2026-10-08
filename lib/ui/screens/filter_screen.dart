// filter_screen.dart - Optimized version

import 'package:ebroker/data/cubits/utility/fetch_facilities_cubit.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/data/model/facilities_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/range_dropdown.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/choose_location_bottomsheet.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:material_ui/material_ui.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({
    super.key,
    this.showPropertyType = false,
    this.selectedFilter,
    this.isProject = false,
    this.lockedFilter,
  });

  final bool showPropertyType;
  final FilterApply? selectedFilter;
  final bool isProject;
  final FilterApply? lockedFilter;

  @override
  FilterScreenState createState() => FilterScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => FilterScreen(
        selectedFilter: arguments?['filter'] as FilterApply? ?? FilterApply(),
        showPropertyType: arguments?['showPropertyType'] as bool? ?? false,
        isProject: arguments?['isProject'] as bool? ?? false,
        lockedFilter: arguments?['lockedFilter'] as FilterApply?,
      ),
    );
  }
}

class FilterScreenState extends State<FilterScreen> {
  // Lock checks helper getters
  bool get _isPremiumLocked =>
      widget.lockedFilter?.get<FlagsFilter>().premium ?? false;
  bool get _isPromotedLocked =>
      widget.lockedFilter?.get<FlagsFilter>().promoted ?? false;
  bool get _isLocationLocked =>
      !(widget.lockedFilter?.get<LocationFilter>().isEmpty ?? true);
  bool get _isCategoryLocked =>
      !(widget.lockedFilter?.get<CategoryFilter>().isEmpty ?? true);
  bool get _isPropertyTypeLocked =>
      !(widget.lockedFilter?.get<PropertyTypeFilter>().isEmpty ?? true);
  bool get _isProjectTypeLocked =>
      !(widget.lockedFilter?.get<ProjectTypeFilter>().isEmpty ?? true);

  // Controllers
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  // Filter state
  late FilterApply _filter;

  // Location state
  String? _city;
  String? _state;
  String? _country;

  // Selection state
  Category? _selectedCategory;
  // Added facilities (backend parameters) -> selected value.
  // Insertion order is preserved so the list renders in the order added.
  final Map<int, Object?> _facilityValues = {};
  final Map<int, TextEditingController> _facilityTextControllers = {};

  // Flags state
  bool _promoted = false;
  bool _premium = false;

  // Constants for posted since options
  static const List<({PostedSinceDuration duration, String labelKey})>
  _postedSinceOptions = [
    (labelKey: 'anytimeLbl', duration: PostedSinceDuration.anytime),
    (labelKey: 'lastWeekLbl', duration: PostedSinceDuration.lastWeek),
    (labelKey: 'yesterdayLbl', duration: PostedSinceDuration.yesterday),
    (labelKey: 'lastMonthLbl', duration: PostedSinceDuration.lastMonth),
    (
      labelKey: 'lastThreeMonthLbl',
      duration: PostedSinceDuration.lastThreeMonth,
    ),
    (labelKey: 'lastSixMonthLbl', duration: PostedSinceDuration.lastSixMonth),
  ];
  //Nearby Places
  final Map<int, TextEditingController> distanceFieldList = {};
  final Set<int> _addedNearbyPlaceIds = {};
  double _minPriceLimit = 0;
  double _maxPriceLimit = 100000;
  @override
  void initState() {
    super.initState();
    _initializeFilter();
    _initializeControllers();
    _initializeBudgetLimits();
    unawaited(_fetchFacilities());
  }

  void _initializeFilter() {
    _filter = widget.selectedFilter?.copy() ?? FilterApply();

    // Initialize from existing filter
    final category = _filter.get<CategoryFilter>();
    final facilities = _filter.get<FacilitiesFilter>();
    final location = _filter.get<LocationFilter>();
    final nearbyPlaces = _filter.get<NearbyPlacesFilter>();
    final flags = _filter.get<FlagsFilter>();

    // Set initial values
    if (category.categoryId != null) {
      _selectedCategory = Category(id: int.tryParse(category.categoryId!) ?? 0);
    }

    for (final facility in facilities.facilities) {
      final value = facility.value;
      _facilityValues[facility.id] = value is List
          ? value.map((e) => e.toString()).toList()
          : value;
      if (value is String) {
        _facilityTextControllers[facility.id] = TextEditingController(
          text: value,
        );
      }
    }

    _city = location.city;
    _state = location.state;
    _country = location.country;

    _promoted = flags.promoted;
    _premium = flags.premium;

    // Initialize nearby places controllers and added IDs
    for (final place in nearbyPlaces.nearbyPlaces) {
      distanceFieldList[place.id] = TextEditingController(
        text: place.value,
      );
      _addedNearbyPlaceIds.add(place.id);
    }
  }

  void _initializeControllers() {
    final minMax = _filter.get<MinMaxBudget>();
    _minController = TextEditingController(text: minMax.min ?? '');
    _maxController = TextEditingController(text: minMax.max ?? '');
  }

  void _initializeBudgetLimits() {
    final state = context.read<FetchSystemSettingsCubit>().state;
    if (state is FetchSystemSettingsSuccess) {
      final settingsData = state.settings['data'];
      _minPriceLimit =
          double.tryParse(settingsData['min_price']?.toString() ?? '') ?? 0.0;
      _maxPriceLimit =
          double.tryParse(settingsData['max_price']?.toString() ?? '') ??
          100000.0;
    }
  }

  Future<void> _fetchFacilities() async {
    if (!mounted) return;
    await context.read<FetchFacilitiesCubit>().fetch();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    for (final controller in distanceFieldList.values) {
      controller.dispose();
    }
    for (final controller in _facilityTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filter.clear();
      widget.lockedFilter?.activeFilters.forEach(_filter.addOrUpdate);

      _minController.clear();
      _maxController.clear();
      _selectedCategory = _isCategoryLocked
          ? (widget.lockedFilter?.get<CategoryFilter>().categoryId != null
                ? Category(
                    id:
                        int.tryParse(
                          widget.lockedFilter!
                              .get<CategoryFilter>()
                              .categoryId!,
                        ) ??
                        0,
                  )
                : null)
          : null;
      _facilityValues.clear();
      for (final controller in _facilityTextControllers.values) {
        controller.clear();
      }
      _city = _isLocationLocked
          ? widget.lockedFilter?.get<LocationFilter>().city
          : null;
      _state = _isLocationLocked
          ? widget.lockedFilter?.get<LocationFilter>().state
          : null;
      _country = _isLocationLocked
          ? widget.lockedFilter?.get<LocationFilter>().country
          : null;
      _promoted = _isPromotedLocked;
      _premium = _isPremiumLocked;

      _addedNearbyPlaceIds.clear();
      // Clear distance field controllers
      for (final controller in distanceFieldList.values) {
        controller.clear();
      }
    });
  }

  void _applyFilters() {
    // Update filter with current values
    if (!widget.isProject) {
      _filter
        ..addOrUpdate(
          MinMaxBudget(
            min: _minController.text.trim().isEmpty
                ? null
                : _minController.text,
            max: _maxController.text.trim().isEmpty
                ? null
                : _maxController.text,
          ),
        )
        ..addOrUpdate(
          FacilitiesFilter([
            for (final entry in _facilityValues.entries)
              FacilityValue(id: entry.key, value: entry.value),
          ]),
        );

      // Add nearby places filter
      final nearbyPlaces = <NearbyPlace>[];
      for (final entry in distanceFieldList.entries) {
        if (!_addedNearbyPlaceIds.contains(entry.key)) continue;
        final text = entry.value.text.trim();
        if (text.isNotEmpty) {
          final distance = int.tryParse(text);
          if (distance != null) {
            nearbyPlaces.add(
              NearbyPlace(
                id: entry.key,
                value: distance.toString(),
              ),
            );
          }
        }
      }

      if (nearbyPlaces.isNotEmpty) {
        _filter.addOrUpdate(NearbyPlacesFilter(nearbyPlaces));
      } else {
        _filter.remove<NearbyPlacesFilter>();
      }
    }

    // Set category name for display
    if (widget.showPropertyType || widget.isProject) {
      selectedcategoryName = _selectedCategory?.category ?? '';
    }

    final lockedFlags = widget.lockedFilter?.get<FlagsFilter>();
    _filter.addOrUpdate(
      FlagsFilter(
        promoted: _promoted,
        premium: _premium,
        adminCurated: lockedFlags?.adminCurated ?? false,
        mostLiked: lockedFlags?.mostLiked ?? false,
        mostViewed: lockedFlags?.mostViewed ?? false,
      ),
    );

    Navigator.pop(context, _filter);
  }

  void _removeNearbyPlace(int facilityId) {
    setState(() {
      _addedNearbyPlaceIds.remove(facilityId);
      distanceFieldList[facilityId]?.clear();
    });
  }

  void _addNearbyPlace(int facilityId) {
    setState(() {
      _addedNearbyPlaceIds.add(facilityId);
      distanceFieldList.putIfAbsent(facilityId, TextEditingController.new);
    });
  }

  void _showAddNearbyPlacesBottomSheet() {
    _showAddItemsBottomSheet(
      title: 'chooseNearbyPlaces'.translate(context),
      showIcon: true,
      itemsOf: (state) => [
        for (final facility in state.outdoorFacilities)
          if (facility.id != null &&
              !_addedNearbyPlaceIds.contains(facility.id))
            (
              id: facility.id!,
              name: _nameOf(facility.translatedName, facility.name),
              image: facility.image ?? '',
            ),
      ],
      onAdd: _addNearbyPlace,
    );
  }

  void _showAddFacilitiesBottomSheet() {
    _showAddItemsBottomSheet(
      title: 'facilities'.translate(context),
      showIcon: false,
      itemsOf: (state) => [
        for (final facility in state.facilities)
          if (facility.id != null &&
              !_facilityValues.containsKey(facility.id) &&
              _isFilterableType(facility.typeOfParameter))
            (
              id: facility.id!,
              name: _nameOf(facility.translatedName, facility.name),
              image: facility.image ?? '',
            ),
      ],
      onAdd: _addFacility,
    );
  }

  /// Bottom sheet listing backend items that can be added to the filter.
  void _showAddItemsBottomSheet({
    required String title,
    required bool showIcon,
    required List<({int id, String name, String image})> Function(
      FetchFacilitiesSuccess state,
    )
    itemsOf,
    required ValueChanged<int> onAdd,
  }) {
    unawaited(
      CustomBottomSheet.show<void>(
        context: context,
        title: '',
        showDragHandle: false,
        isScrollControlled: true,
        padding: EdgeInsets.fromLTRB(
          16.rw(context),
          20.rh(context),
          16.rw(context),
          8.rh(context),
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return BlocBuilder<FetchFacilitiesCubit, FetchFacilitiesState>(
              builder: (context, state) {
                if (state is! FetchFacilitiesSuccess) {
                  return const SizedBox.shrink();
                }
                final items = itemsOf(state);

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: CustomText(
                              title,
                              fontSize: context.font.lg,
                              fontWeight: FontWeight.w700,
                              color: context.color.textColorDark,
                            ),
                          ),
                          SizedBox(width: 12.rw(context)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: CustomImage(
                              imageUrl: AppIcons.closeCircle,
                              height: 24.rh(context),
                              width: 24.rw(context),
                              color: context.color.textColorDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.rh(context)),
                      UiUtils.getDivider(context),
                      SizedBox(height: 16.rh(context)),
                      if (items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: CustomText(
                              'noDetailsFound'.translate(context),
                              color: context.color.textColorDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.rw(context),
                            ),
                            separatorBuilder: (_, _) =>
                                SizedBox(height: 16.rh(context)),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Row(
                                children: [
                                  if (showIcon) ...[
                                    Container(
                                      height: 48.rh(context),
                                      width: 48.rw(context),
                                      padding: EdgeInsets.all(8.rw(context)),
                                      decoration: BoxDecoration(
                                        color: context.color.textColorDark
                                            .withValues(alpha: 0.05),
                                        borderRadius: .circular(
                                          4.rw(context),
                                        ),
                                      ),
                                      child: CustomImage(
                                        imageUrl: item.image,
                                        color: context.color.textColorDark,
                                      ),
                                    ),
                                    SizedBox(width: 12.rw(context)),
                                  ],
                                  Expanded(
                                    child: CustomText(
                                      item.name,
                                      fontSize: context.font.md,
                                      color: context.color.textColorDark,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      onAdd(item.id);
                                      setSheetState(() {});
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4.rw(context)),
                                      decoration: const BoxDecoration(
                                        color: successMessageColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: context.color.secondaryColor,
                                        size: 16.rh(context),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _nameOf(String? translated, String? name) =>
      (translated?.isNotEmpty ?? false) ? translated! : (name ?? '');

  /// File uploads can't be used as a search criterion.
  bool _isFilterableType(String? type) => type?.toLowerCase() != 'file';

  void _addFacility(int facilityId) {
    // A dropdown shows its first option until changed, so start with that
    // value to keep the applied filter in sync with what the user sees.
    final state = context.read<FetchFacilitiesCubit>().state;
    final facility = state is FetchFacilitiesSuccess
        ? state.facilities.where((f) => f.id == facilityId).firstOrNull
        : null;
    final initialValue = facility?.typeOfParameter?.toLowerCase() == 'dropdown'
        ? _facilityOptions(facility!).firstOrNull?.value
        : null;
    setState(() {
      _facilityValues.putIfAbsent(facilityId, () => initialValue);
    });
  }

  void _removeFacility(int facilityId) {
    setState(() {
      _facilityValues.remove(facilityId);
      _facilityTextControllers[facilityId]?.clear();
    });
  }

  Future<void> _selectLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await CustomBottomSheet.show<GooglePlaceModel>(
      context: context,
      isScrollControlled: true,
      title: 'selectLocation'.translate(context),
      child: const ChooseLocatonBottomSheet(),
    );
    if (result != null && mounted) {
      setState(() {
        _city = result.city;
        _country = result.country;
        _state = result.state;

        _filter.addOrUpdate(
          LocationFilter(
            placeId: result.placeId,
            city: result.city,
            state: result.state,
            country: result.country,
          ),
        );
      });
    }
  }

  void _clearLocation() {
    setState(() {
      _city = null;
      _state = null;
      _country = null;
      _filter.remove<LocationFilter>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          title: 'filterTitle'.translate(context),
        ),
        bottomNavigationBar: _buildBottomBar(),
        body: SingleChildScrollView(
          physics: Constant.scrollPhysics,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.rh(context)),
              _buildPropertyTypeToggle(),
              if (widget.showPropertyType || widget.isProject) ...[
                SizedBox(height: 16.rh(context)),
                _buildCategorySection(),
              ],
              if (!widget.isProject) ...[
                SizedBox(height: 16.rh(context)),
                _buildBudgetSection(),
              ],
              SizedBox(height: 16.rh(context)),
              _buildPostedSinceSection(),
              SizedBox(height: 16.rh(context)),
              _buildLocationSection(),
              SizedBox(height: 16.rh(context)),
              _buildFlagsSection(),
              if (!widget.isProject) ...[
                SizedBox(height: 16.rh(context)),
                _buildFacilitiesSection(),
                SizedBox(height: 16.rh(context)),
                _buildAddedNearbyPlacesSection(),
              ],
              SizedBox(height: 16.rh(context)),
              const Center(
                child: BannerAdWidget(bannerSize: AdSize.banner),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      height: 72.rh(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: context.color.primaryColor,
      child: Row(
        children: [
          Expanded(
            child: UiUtils.buildButton(
              context,
              onPressed: _resetFilters,
              buttonColor: context.color.secondaryColor,
              showElevation: false,
              textColor: context.color.tertiaryColor,
              border: BorderSide(color: context.color.tertiaryColor),
              buttonTitle: 'clearfilter'.translate(context),
            ),
          ),
          SizedBox(width: 16.rw(context)),
          Expanded(
            child: UiUtils.buildButton(
              context,
              buttonTitle: 'applyFilter'.translate(context),
              onPressed: _applyFilters,
              buttonColor: context.color.tertiaryColor,
              textColor: context.color.buttonColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeToggle() {
    if (widget.isProject) {
      final projectType = _filter.get<ProjectTypeFilter>().type;
      final isLocked = _isProjectTypeLocked;

      return Container(
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.color.borderColor),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                title: 'upcoming'.translate(context),
                isSelected: projectType == 'upcoming' || projectType == '0',
                isLocked: isLocked,
                onTap: () {
                  if (isLocked) return;
                  setState(() {
                    _filter.addOrUpdate(
                      ProjectTypeFilter(
                        (projectType == 'upcoming' || projectType == '0')
                            ? ''
                            : 'upcoming',
                      ),
                    );
                  });
                },
              ),
            ),
            Expanded(
              child: _buildToggleButton(
                title: 'under_construction'.translate(context),
                isSelected:
                    projectType == 'under_construction' || projectType == '1',
                isLocked: isLocked,
                onTap: () {
                  if (isLocked) return;
                  setState(() {
                    _filter.addOrUpdate(
                      ProjectTypeFilter(
                        (projectType == 'under_construction' ||
                                projectType == '1')
                            ? ''
                            : 'under_construction',
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    final propertyType = _filter.get<PropertyTypeFilter>().type;
    final isLocked = _isPropertyTypeLocked;

    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.borderColor),
      ),
      padding: .all(4.rw(context)),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              title: 'forSell'.translate(context),
              isSelected: propertyType == Constant.valSellBuy,
              isLocked: isLocked,
              onTap: () {
                if (isLocked) return;
                setState(() {
                  _filter.addOrUpdate(
                    PropertyTypeFilter(
                      propertyType == Constant.valSellBuy
                          ? ''
                          : Constant.valSellBuy,
                    ),
                  );
                });
              },
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              title: 'forRent'.translate(context),
              isSelected: propertyType == Constant.valRent,
              isLocked: isLocked,
              onTap: () {
                if (isLocked) return;
                setState(() {
                  _filter.addOrUpdate(
                    PropertyTypeFilter(
                      propertyType == Constant.valRent ? '' : Constant.valRent,
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Opacity(
      opacity: (isLocked && !isSelected) ? 0.4 : 1.0,
      child: UiUtils.buildButton(
        context,
        height: 48.rh(context),
        outerPadding: .zero,
        padding: .zero,
        onPressed: onTap,
        showElevation: false,
        textColor: isSelected
            ? context.color.buttonColor
            : context.color.textColorDark.withValues(alpha: 0.6),
        buttonColor: isSelected
            ? context.color.tertiaryColor
            : Colors.transparent,
        fontSize: context.font.md,
        radius: 4,
        buttonTitle: title,
        suffixWidget: isLocked && isSelected
            ? Padding(
                padding: .only(left: 6.rw(context)),
                child: CustomImage(
                  imageUrl: AppIcons.lock,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.buttonColor,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCategorySection() {
    final isLocked = _isCategoryLocked;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            CustomText(
              'category'.translate(context),
              fontSize: context.font.sm,
            ),
            if (isLocked) ...[
              SizedBox(width: 6.rw(context)),
              CustomImage(
                imageUrl: AppIcons.lock,
                height: 14.rh(context),
                fit: .contain,
                color: context.color.textColorDark.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.rh(context)),
        BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
          builder: (context, state) {
            if (state is! FetchCategorySuccess) return const SizedBox.shrink();

            final categories = [null, ...state.categories];

            return SizedBox(
              height: 32.rh(context),
              child: ListView.separated(
                scrollDirection: .horizontal,
                physics: Constant.scrollPhysics,
                separatorBuilder: (_, _) => SizedBox(width: 12.rw(context)),
                itemCount: isLocked ? 1 : categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category?.id == _selectedCategory?.id;
                  if (isLocked) {
                    final lockedCategory = categories.firstWhere(
                      (cat) => cat?.id == _selectedCategory?.id,
                      orElse: () => null,
                    );
                    return _buildCategoryChip(
                      lockedCategory,
                      true,
                      isLocked,
                    );
                  }

                  return GestureDetector(
                    onTap: isLocked
                        ? null
                        : () {
                            setState(() {
                              _selectedCategory = category;
                              _filter.addOrUpdate(
                                CategoryFilter(category?.id?.toString()),
                              );
                            });
                          },
                    child: _buildCategoryChip(category, isSelected, isLocked),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    Category? category,
    bool isSelected, [
    bool isLocked = false,
  ]) {
    final baseColor = isSelected
        ? context.color.tertiaryColor.withValues(alpha: 0.1)
        : context.color.secondaryColor;

    final border = isSelected
        ? Border.all(
            color: context.color.tertiaryColor.withValues(alpha: .2),
            width: .5,
          )
        : Border.all(color: context.color.borderColor, width: .5);

    final opacity = (isLocked && !isSelected) ? 0.4 : 1.0;

    final child = category == null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'all'.translate(context),
                color: isSelected
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: 0.8),
              ),
              if (isLocked && isSelected) ...[
                SizedBox(width: 6.rw(context)),
                CustomImage(
                  imageUrl: AppIcons.lock,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.tertiaryColor,
                ),
              ],
            ],
          )
        : Row(
            children: [
              CustomImage(
                imageUrl: category.image ?? '',
                height: 18.rh(context),
                width: 18.rw(context),
                color: isSelected
                    ? context.color.tertiaryColor
                    : context.color.textLightColor,
              ),
              SizedBox(width: 8.rw(context)),
              CustomText(
                category.translatedName ?? category.category ?? '',
                color: isSelected
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: 0.8),
              ),
              if (isLocked && isSelected) ...[
                SizedBox(width: 6.rw(context)),
                CustomImage(
                  imageUrl: AppIcons.lock,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.tertiaryColor,
                ),
              ],
            ],
          );

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: .symmetric(horizontal: 12.rw(context)),
        alignment: .center,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: .circular(4.rw(context)),
          border: border,
        ),
        child: child,
      ),
    );
  }

  Widget _buildBudgetSection() {
    final currentMin = double.tryParse(_minController.text) ?? _minPriceLimit;
    final currentMax = double.tryParse(_maxController.text) ?? _maxPriceLimit;

    final clampedMin = currentMin.clamp(_minPriceLimit, _maxPriceLimit);
    final clampedMax = currentMax.clamp(_minPriceLimit, _maxPriceLimit);
    final rangeValues = RangeValues(
      clampedMin <= clampedMax ? clampedMin : clampedMax,
      clampedMax,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'budgetLbl'.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.rh(context)),
        Row(
          children: [
            Expanded(
              child: _buildBudgetField(
                controller: _minController,
                label: 'minLbl'.translate(context),
                validator: _validateMin,
              ),
            ),
            SizedBox(width: 16.rw(context)),
            Expanded(
              child: _buildBudgetField(
                controller: _maxController,
                label: 'maxLbl'.translate(context),
                validator: _validateMax,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.rh(context)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: context.color.tertiaryColor,
            inactiveTrackColor: context.color.borderColor,
            trackHeight: 4,
            thumbColor: context.color.tertiaryColor,
            overlayColor: context.color.tertiaryColor.withValues(alpha: 0.2),
            valueIndicatorColor: context.color.tertiaryColor,
          ),
          child: RangeSlider(
            values: rangeValues,
            min: _minPriceLimit,
            max: _maxPriceLimit,
            onChanged: (values) {
              setState(() {
                _minController.text = values.start.toInt().toString();
                _maxController.text = values.end.toInt().toString();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: TextInputAction.done,
      validator: validator,
      onChanged: (val) {
        setState(() {});
      },
      decoration: InputDecoration(
        isDense: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.color.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.color.borderColor),
        ),
        labelStyle: TextStyle(
          color: context.color.textColorDark.withValues(alpha: 0.6),
        ),
        hintText: '00',
        label: CustomText(label),
        prefixText: '${AppSettings.currencySymbol} ',
        prefixStyle: TextStyle(color: context.color.textColorDark),
        fillColor: context.color.secondaryColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      style: TextStyle(color: context.color.textColorDark),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  String? _validateMin(String? value) {
    if (value?.isEmpty ?? true) return null;
    if (_maxController.text.isEmpty) return null;

    final min = num.tryParse(value!) ?? 0;
    final max = num.tryParse(_maxController.text) ?? 0;

    if (min >= max) {
      return '${'enterSmallerThan'.translate(context)} ${_maxController.text}';
    }
    return null;
  }

  String? _validateMax(String? value) {
    if (value?.isEmpty ?? true) return null;
    if (_minController.text.isEmpty) return null;

    final max = num.tryParse(value!) ?? 0;
    final min = num.tryParse(_minController.text) ?? 0;

    if (max <= min) {
      return '${'enterBiggerThan'.translate(context)} ${_minController.text}';
    }
    return null;
  }

  Widget _buildPostedSinceSection() {
    final currentDuration = _filter.get<PostedSince>().since;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'postedSinceLbl'.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.rh(context)),
        SizedBox(
          height: 36.rh(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            separatorBuilder: (context, index) =>
                SizedBox(width: 12.rw(context)),
            itemCount: _postedSinceOptions.length,
            itemBuilder: (context, index) {
              final option = _postedSinceOptions[index];
              final isSelected = currentDuration == option.duration;

              return UiUtils.buildButton(
                context,
                fontSize: context.font.sm,
                showElevation: false,
                autoWidth: true,
                radius: 4,
                buttonColor: isSelected
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: 0.05),
                textColor: isSelected
                    ? context.color.buttonColor
                    : context.color.textColorDark,
                buttonTitle: option.labelKey.translate(context),
                onPressed: () {
                  setState(() {
                    _filter.addOrUpdate(PostedSince(option.duration));
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _city != null && _city!.isNotEmpty;
    final isLocked = _isLocationLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomText(
              'locationLbl'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w500,
            ),
            if (isLocked) ...[
              SizedBox(width: 6.rw(context)),
              CustomImage(
                imageUrl: AppIcons.lock,
                height: 14.rh(context),
                fit: .contain,
                color: context.color.textColorDark.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.rh(context)),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isLocked ? null : _selectLocation,
                child: Container(
                  height: 48.rh(context),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? context.color.secondaryColor.withValues(alpha: 0.5)
                        : context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.color.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: context.color.textColorDark.withValues(
                          alpha: 0.5,
                        ),
                        size: 20,
                      ),
                      SizedBox(width: 8.rw(context)),
                      Expanded(
                        child: CustomText(
                          hasLocation
                              ? '$_city, $_state, $_country'
                              : 'selectLocationOptional'.translate(context),
                          maxLines: 1,
                          color: isLocked
                              ? context.color.textColorDark.withValues(
                                  alpha: 0.6,
                                )
                              : context.color.textColorDark,
                        ),
                      ),
                      if (hasLocation && !isLocked)
                        GestureDetector(
                          onTap: _clearLocation,
                          child: Icon(
                            Icons.close,
                            color: context.color.textColorDark,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.rw(context)),
            GestureDetector(
              onTap: isLocked ? null : _selectLocation,
              child: Container(
                height: 48.rh(context),
                width: 48.rh(context),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLocked
                      ? context.color.secondaryColor.withValues(alpha: 0.5)
                      : context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.color.borderColor),
                ),
                child: Opacity(
                  opacity: isLocked ? 0.5 : 1.0,
                  child: Icon(
                    Icons.gps_fixed,
                    color: context.color.tertiaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.rw(context),
              vertical: 8.rh(context),
            ),
            child: Column(
              children: [
                _buildFlagRow(
                  title: 'featured'.translate(context),
                  iconUrl: AppIcons.featuredBolt,
                  value: _promoted,
                  onChanged: _isPromotedLocked
                      ? null
                      : (val) {
                          setState(() {
                            _promoted = val;
                          });
                        },
                ),
                SizedBox(height: 8.rh(context)),
                UiUtils.getDivider(context),
                SizedBox(height: 8.rh(context)),
                _buildFlagRow(
                  title: 'premium'.translate(context),
                  iconUrl: AppIcons.subscription,
                  value: _premium,
                  onChanged: _isPremiumLocked
                      ? null
                      : (val) {
                          setState(() {
                            _premium = val;
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlagRow({
    required String title,
    required String iconUrl,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final isLocked = onChanged == null;
    return Row(
      children: [
        CustomImage(
          imageUrl: iconUrl,
          height: 24.rh(context),
          fit: .contain,
          color: context.color.textColorDark,
        ),
        SizedBox(width: 8.rw(context)),
        Expanded(
          child: Row(
            children: [
              CustomText(
                title,
                fontSize: context.font.md,
                color: isLocked
                    ? context.color.textLightColor
                    : context.color.textColorDark,
              ),
              if (isLocked) ...[
                SizedBox(width: 6.rw(context)),
                CustomImage(
                  imageUrl: AppIcons.lock,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.textLightColor,
                ),
              ],
            ],
          ),
        ),
        UiSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFacilitiesSection() {
    return BlocBuilder<FetchFacilitiesCubit, FetchFacilitiesState>(
      builder: (context, state) {
        if (state is! FetchFacilitiesSuccess || state.facilities.isEmpty) {
          return const SizedBox.shrink();
        }

        final facilitiesById = {
          for (final facility in state.facilities)
            if (facility.id != null) facility.id!: facility,
        };
        final addedFacilities = [
          for (final id in _facilityValues.keys)
            if (facilitiesById[id] != null) facilitiesById[id]!,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'facilities'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(height: 12.rh(context)),
            for (final facility in addedFacilities) ...[
              _buildFacilityItem(facility),
              SizedBox(height: 12.rh(context)),
            ],
            UiUtils.buildButton(
              context,
              height: 48,
              showElevation: false,
              buttonTitle: 'addMore'.translate(context),
              onPressed: _showAddFacilitiesBottomSheet,
              buttonColor: context.color.secondaryColor,
              textColor: context.color.tertiaryColor,
              border: BorderSide(color: context.color.tertiaryColor),
            ),
          ],
        );
      },
    );
  }

  /// Options of a dropdown/radio/checkbox parameter as (raw value, label).
  /// The raw value is sent to the API, the label is shown to the user.
  List<({String value, String label})> _facilityOptions(
    FacilitiesModel facility,
  ) {
    final translated = facility.translatedValues ?? const [];
    if (translated.isNotEmpty) {
      return [
        for (final option in translated)
          if (option.value?.isNotEmpty ?? false)
            (
              value: option.value!,
              label: (option.translated?.isNotEmpty ?? false)
                  ? option.translated!
                  : option.value!,
            ),
      ];
    }
    return [
      for (final value in facility.typeValues ?? const <String>[])
        if (value.isNotEmpty) (value: value, label: value),
    ];
  }

  Widget _buildFacilityItem(FacilitiesModel facility) {
    final id = facility.id!;
    final type = facility.typeOfParameter?.toLowerCase() ?? '';
    final name = _nameOf(facility.translatedName, facility.name);

    final header = <Widget>[
      _buildRemoveButton(() => _removeFacility(id)),
      SizedBox(width: 12.rw(context)),
    ];

    switch (type) {
      case 'radiobutton':
      case 'checkbox':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...header,
                Expanded(child: _buildFacilityName(name)),
              ],
            ),
            SizedBox(height: 8.rh(context)),
            _buildFacilityChips(
              id: id,
              options: _facilityOptions(facility),
              multiSelect: type == 'checkbox',
            ),
          ],
        );
      case 'number':
        return Row(
          children: [
            ...header,
            Expanded(child: _buildFacilityName(name)),
            _buildFacilityStepper(id),
          ],
        );
      case 'dropdown':
        final options = _facilityOptions(facility);
        final current = _facilityValues[id];
        return Row(
          children: [
            ...header,
            Expanded(child: _buildFacilityName(name)),
            if (options.isNotEmpty) ...[
              SizedBox(width: 12.rw(context)),
              RangeDropdown<String>(
                value: options.any((o) => o.value == current)
                    ? current! as String
                    : options.first.value,
                options: [for (final option in options) option.value],
                labelOf: (value) =>
                    options.firstWhere((o) => o.value == value).label,
                onChanged: (val) => setState(() => _facilityValues[id] = val),
              ),
            ],
          ],
        );
      default:
        // textbox / textarea
        return Row(
          children: [
            ...header,
            Expanded(flex: 2, child: _buildFacilityName(name)),
            SizedBox(width: 12.rw(context)),
            Expanded(flex: 3, child: _buildFacilityTextField(id)),
          ],
        );
    }
  }

  Widget _buildRemoveButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.remove, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildFacilityName(String name) {
    return CustomText(
      name,
      color: context.color.textColorDark,
      fontSize: context.font.md,
      maxLines: 2,
    );
  }

  Widget _buildFacilityChips({
    required int id,
    required List<({String value, String label})> options,
    required bool multiSelect,
  }) {
    final current = _facilityValues[id];
    final selected = multiSelect
        ? {...(current as List?)?.cast<String>() ?? const <String>[]}
        : {if (current is String) current};

    return Wrap(
      spacing: 8.rw(context),
      runSpacing: 8.rh(context),
      children: [
        for (final option in options)
          GestureDetector(
            onTap: () {
              setState(() {
                final isSelected = selected.contains(option.value);
                if (multiSelect) {
                  isSelected
                      ? selected.remove(option.value)
                      : selected.add(option.value);
                  _facilityValues[id] = selected.toList();
                } else {
                  // Tapping the selected option again clears it (= any value).
                  _facilityValues[id] = isSelected ? null : option.value;
                }
              });
            },
            child: _buildOptionChip(
              option.label,
              isSelected: selected.contains(option.value),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? context.color.tertiaryColor
            : context.color.textColorDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomText(
        label,
        color: isSelected
            ? context.color.buttonColor
            : context.color.textColorDark,
        fontSize: context.font.sm,
      ),
    );
  }

  Widget _buildFacilityStepper(int id) {
    final count = int.tryParse(_facilityValues[id]?.toString() ?? '') ?? 0;

    void update(int value) {
      setState(() {
        // 0 means no specific count (= any value).
        _facilityValues[id] = value <= 0 ? null : value.toString();
      });
    }

    Widget stepButton(IconData icon, VoidCallback? onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 28.rh(context),
          width: 28.rh(context),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null
                ? context.color.textLightColor
                : context.color.textColorDark,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        stepButton(Icons.remove, count > 0 ? () => update(count - 1) : null),
        SizedBox(
          width: 32.rw(context),
          child: CustomText(
            '$count',
            textAlign: TextAlign.center,
            color: context.color.textColorDark,
            fontSize: context.font.md,
          ),
        ),
        stepButton(Icons.add, () => update(count + 1)),
      ],
    );
  }

  Widget _buildFacilityTextField(int id) {
    final controller = _facilityTextControllers.putIfAbsent(
      id,
      () => TextEditingController(
        text: _facilityValues[id] is String
            ? _facilityValues[id]! as String
            : '',
      ),
    );

    return TextFormField(
      controller: controller,
      onChanged: (val) => _facilityValues[id] = val.trim().isEmpty ? null : val,
      style: TextStyle(color: context.color.textColorDark),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.color.secondaryColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.color.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.color.borderColor),
        ),
      ),
    );
  }

  Widget _buildAddedNearbyPlacesSection() {
    return BlocBuilder<FetchFacilitiesCubit, FetchFacilitiesState>(
      builder: (context, state) {
        if (state is! FetchFacilitiesSuccess) {
          return const SizedBox.shrink();
        }

        final addedFacilities = state.outdoorFacilities
            .where(
              (facility) => _addedNearbyPlaceIds.contains(facility.id),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomText(
                  'chooseNearbyPlaces'.translate(context),
                  fontSize: context.font.sm,
                  fontWeight: FontWeight.w500,
                ),
                CustomText(
                  '${'withinDistance'.translate(context)} ${AppSettings.distanceOption}',
                  fontSize: context.font.sm,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
            SizedBox(height: 12.rh(context)),
            if (addedFacilities.isNotEmpty)
              ListView.separated(
                itemCount: addedFacilities.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) =>
                    SizedBox(height: 12.rh(context)),
                itemBuilder: (context, index) {
                  final facility = addedFacilities[index];

                  // Ensure controller exists
                  distanceFieldList.putIfAbsent(
                    facility.id!,
                    TextEditingController.new,
                  );

                  return Row(
                    children: [
                      _buildRemoveButton(
                        () => _removeNearbyPlace(facility.id!),
                      ),
                      SizedBox(width: 12.rw(context)),

                      // Icon in light grey box
                      Container(
                        height: 48.rh(context),
                        width: 48.rw(context),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.color.textColorDark.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomImage(
                          imageUrl: facility.image ?? '',
                          color: context.color.textColorDark,
                        ),
                      ),
                      SizedBox(width: 12.rw(context)),

                      // Name
                      Expanded(
                        flex: 2,
                        child: CustomText(
                          facility.translatedName ?? facility.name ?? '',
                          color: context.color.textColorDark,
                          fontSize: context.font.md,
                        ),
                      ),
                      SizedBox(width: 12.rw(context)),

                      // Distance input
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: distanceFieldList[facility.id],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            color: context.color.textColorDark,
                          ),
                          decoration: InputDecoration(
                            hintText: AppSettings.distanceOption,
                            suffixText: AppSettings.distanceOption,
                            suffixStyle: TextStyle(
                              color: context.color.textColorDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: context.color.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: context.color.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: context.color.borderColor,
                              ),
                            ),
                            isDense: true,
                            fillColor: context.color.secondaryColor,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            SizedBox(height: 12.rh(context)),
            // Add More Button
            UiUtils.buildButton(
              context,
              height: 48,
              showElevation: false,
              buttonTitle: 'addMore'.translate(context),
              onPressed: _showAddNearbyPlacesBottomSheet,
              buttonColor: context.color.secondaryColor,
              textColor: context.color.tertiaryColor,
              border: BorderSide(color: context.color.tertiaryColor),
            ),
          ],
        );
      },
    );
  }
}
