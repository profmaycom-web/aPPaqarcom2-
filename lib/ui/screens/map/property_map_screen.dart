import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/map_bounds.dart';
import 'package:ebroker/data/repositories/map.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_app_bar.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

class PropertyMapScreen extends StatefulWidget {
  const PropertyMapScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return const PropertyMapScreen();
      },
    );
  }

  @override
  State<PropertyMapScreen> createState() => _PropertyMapScreenState();
}

class _PropertyMapScreenState extends State<PropertyMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);
  FilterApply _userFilter = FilterApply();
  LatLng? citylatLong;
  List<AppMapMarker> marker = [];
  Map<dynamic, dynamic> map = {};
  AppMapController? _mapController;
  bool isMapCreated = false;
  List<PlaceModel>? cities;
  int selectedMarker = 999999999999999;
  int? propertyId;
  ValueNotifier<bool> isLoadingProperty = ValueNotifier<bool>(false);
  PropertyModel? activePropertyModal;
  List<PropertyModel>? activePropertiesList;
  ValueNotifier<bool> loadintCitiesInProgress = ValueNotifier<bool>(false);
  bool showSellRentLables = false;
  bool showGoogleMap = true;
  ScrollController? _sheetScrollController;
  double _currentZoom = AppConfig.propertyMapScreenZoom;
  Timer? _mapIdleDebounce;
  bool _isProgrammaticMove = false;
  final PlaceSearchService _searchService =
      MapServiceFactory.createPlaceSearchService();

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      cities = null;
      if (mounted) setState(() {});
      return;
    }
    try {
      loadintCitiesInProgress.value = true;
      cities = await _searchService.searchCities(query);
      loadintCitiesInProgress.value = false;
    } on Exception catch (_) {
      loadintCitiesInProgress.value = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _onFilterApplied(FilterApply filter) async {
    _userFilter = filter;
    if (mounted) setState(() {});
    await loadAll();
  }

  @override
  void initState() {
    super.initState();
    unawaited(loadAll());
  }

  LatLng getCameraPosition() {
    if (AppSettings.latitude.isNotEmpty && AppSettings.longitude.isNotEmpty) {
      return LatLng(
        double.parse(AppSettings.latitude),
        double.parse(AppSettings.longitude),
      );
    }
    return const LatLng(20.5937, 78.9629);
  }

  Future<void> loadAll({MapBounds? bounds}) async {
    try {
      isLoadingProperty.value = true;
      final activeBounds = bounds ?? await _mapController?.getVisibleBounds();
      final pointList = await GMap.getNearByProperty(
        '',
        '',
        '',
        '',
        filter: _userFilter.hasActiveFilters ? _userFilter : null,
        bounds: activeBounds,
      );
      activePropertiesList = pointList;

      await loopMarker(activePropertiesList ?? []);
      isLoadingProperty.value = false;
    } on Exception catch (e) {
      isLoadingProperty.value = false;
      HelperUtils.showSnackBarMessage(
        context,
        '$e',
        type: .error,
      );
    } finally {
      isLoadingProperty.value = false;
    }
  }

  Future<void> onTapCity(int index) async {
    try {
      unawaited(Widgets.showLoader(context));
      final pointList = await GMap.getNearByProperty(
        cities?.elementAt(index).city ?? '',
        cities?.elementAt(index).latitude ?? '',
        cities?.elementAt(index).longitude ?? '',
        cities?.elementAt(index).placeId ?? '',
        filter: _userFilter.hasActiveFilters ? _userFilter : null,
      );
      activePropertiesList = pointList;

      if (pointList.isEmpty) {
        marker = [];
        if (mounted) setState(() {});
      }

      final latLng = await getCityLatLong(
        latitude: cities?.elementAt(index).latitude ?? '',
        longitude: cities?.elementAt(index).longitude ?? '',
        placeId: cities?.elementAt(index).placeId ?? '',
      );

      try {
        if (latLng != null && _mapController != null) {
          await _mapController!.animateTo(latLng, zoom: 7);
        }
      } on Exception catch (e) {
        HelperUtils.showSnackBarMessage(
          context,
          '$e',
          type: .error,
        );
      }

      await loopMarker(activePropertiesList ?? []);
      _isSearching.value = false;
      HelperUtils.unfocus();
      Future.delayed(
        Duration.zero,
        () {
          Widgets.hideLoder(context);
        },
      );
      cities = null;
      if (mounted) setState(() {});
    } on Exception catch (e) {
      Widgets.hideLoder(context);
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: .error,
      );
    }
  }

  Future<void> selectPropertyAt(int index, {bool movePage = false}) async {
    final list = activePropertiesList ?? [];
    if (list.isEmpty || index < 0 || index >= list.length) return;
    final element = list[index];

    selectedMarker = index;
    propertyId = element.id;
    activePropertyModal = element;
    await loopMarker(list);

    final lat = double.tryParse(element.latitude ?? '');
    final lng = double.tryParse(element.longitude ?? '');
    if (lat != null && lng != null && _mapController != null) {
      _isProgrammaticMove = true;
      try {
        await _mapController!.animateTo(LatLng(lat, lng), zoom: _currentZoom);
      } finally {
        Future.delayed(const Duration(milliseconds: 600), () {
          _isProgrammaticMove = false;
        });
      }
    }

    if (mounted) setState(() {});

    if (movePage &&
        _sheetScrollController != null &&
        _sheetScrollController!.hasClients) {
      final cardHeight = 144.rh(context);
      final targetOffset = (index * cardHeight).clamp(
        0.0,
        _sheetScrollController!.position.maxScrollExtent,
      );
      await _sheetScrollController!.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> loopMarker(List<PropertyModel> pointList) async {
    marker.clear();
    for (var i = 0; i < pointList.length; i++) {
      final element = pointList[i];

      double? lat;
      double? lng;

      try {
        lat = element.latitude!.isNotEmpty
            ? double.parse(element.latitude!)
            : null;
        lng = element.longitude!.isNotEmpty
            ? double.parse(element.longitude!)
            : null;
      } on Exception catch (_) {
        continue;
      }

      if (lat != null && lng != null) {
        marker.add(
          AppMapMarker(
            id: '$i',
            position: LatLng(lat, lng),
            pinType: selectedMarker == i
                ? LocationPinType.selected
                : element.propertyType.toString().toLowerCase() == 'sell'
                ? LocationPinType.sell
                : LocationPinType.rent,
            property: element,
            onTap: () async {
              try {
                await selectPropertyAt(i, movePage: true);
              } on Exception catch (e) {
                HelperUtils.showSnackBarMessage(
                  context,
                  '$e',
                  type: .error,
                );
              }
            },
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<LatLng?> getCityLatLong({
    required String latitude,
    required String longitude,
    required String placeId,
  }) async {
    final details = await _searchService.getPlaceDetails(
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
    );
    if (details.lat == null || details.lng == null) return null;
    return LatLng(details.lat!, details.lng!);
  }

  @override
  void dispose() {
    _mapIdleDebounce?.cancel();
    _searchController.dispose();
    _isSearching.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isSearching.value) {
          _isSearching.value = false;
          return;
        }
        showGoogleMap = false;
        setState(() {});
        Future.delayed(Duration.zero, () {
          Navigator.of(context).pop();
        });
      },
      child: Scaffold(
        backgroundColor: context.color.secondaryColor,
        appBar: SearchFilterAppBar(
          title: 'propertyMap'.translate(context),
          searchController: _searchController,
          searchingListenable: _isSearching,
          currentFilter: _userFilter,
          onSearchChanged: _onSearchChanged,
          onFilterApplied: _onFilterApplied,
        ),
        body: Stack(
          children: [
            // Map View
            if (showGoogleMap)
              AppMapWidget(
                config: AppMapConfig(
                  initialLatLng: getCameraPosition(),
                  initialZoom: AppConfig.propertyMapScreenZoom,
                  markers: marker,

                  onReady: (controller) async {
                    _mapController = controller;
                    isMapCreated = true;
                    showSellRentLables = true;
                    if (mounted) setState(() {});
                    final bounds = await controller.getVisibleBounds();
                    if (bounds != null && bounds.isValid) {
                      await loadAll(bounds: bounds);
                    }
                  },
                  onCameraIdle: () {
                    _mapIdleDebounce?.cancel();
                    _mapIdleDebounce = Timer(
                      const Duration(seconds: 1),
                      () async {
                        if (_mapController != null && mounted) {
                          final bounds = await _mapController!
                              .getVisibleBounds();
                          if (bounds != null && bounds.isValid) {
                            await loadAll(bounds: bounds);
                          } else {
                            isLoadingProperty.value = false;
                          }
                        }
                      },
                    );
                  },
                  onTap: (latLng) {
                    activePropertyModal = null;
                    selectedMarker = 99999999999999;
                    setState(() {});
                  },
                  onCameraMove: (position, zoom) {
                    _currentZoom = zoom;
                    HelperUtils.unfocus();
                    if (!_isProgrammaticMove && activePropertyModal != null) {
                      activePropertyModal = null;
                      selectedMarker = 99999999999999;
                      setState(() {});
                    }
                    if (!isLoadingProperty.value) {
                      isLoadingProperty.value = true;
                    }
                  },
                ),
              ),

            // Cities List
            if (cities != null)
              ColoredBox(
                color: context.color.backgroundColor,
                child: ListView.builder(
                  itemCount: cities?.length ?? 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () async {
                        activePropertyModal = null;
                        setState(() {});
                        await onTapCity(index);
                      },
                      leading: SvgPicture.asset(
                        AppIcons.location,
                        colorFilter: ColorFilter.mode(
                          context.color.textColorDark,
                          .srcIn,
                        ),
                      ),
                      title: CustomText(
                        cities?.elementAt(index).city ?? '',
                      ),
                      subtitle: CustomText(
                        "${cities?.elementAt(index).state ?? ""},${cities?.elementAt(index).country ?? ""}",
                      ),
                    );
                  },
                ),
              ),

            // Loading Indicator
            PositionedDirectional(
              top: 8.rh(context),
              end: 8.rw(context),
              child: ValueListenableBuilder(
                valueListenable: isLoadingProperty,
                builder: (context, va, c) {
                  if (!va) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsetsDirectional.only(
                      end: 8,
                      top: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: .circle,
                      color: Color.lerp(
                        context.color.tertiaryColor,
                        context.color.secondaryColor,
                        0.8,
                      ),
                    ),
                    child: UiUtils.progress(
                      height: 20.rh(context),
                      width: 20.rw(context),
                    ),
                  );
                },
              ),
            ),

            // Draggable Property Sheet
            _buildDraggablePropertySheet(context),

            // Floating Marker Property Preview Box
            _buildMarkerPropertyPreviewBox(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggablePropertySheet(BuildContext context) {
    if (cities != null) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      maxChildSize: 0.8,
      snap: true,
      snapSizes: const [0.35, 0.5],
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;
        return Container(
          padding: EdgeInsets.all(
            16.rh(context),
          ),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            spacing: 16.rh(context),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Property Listings & Rent / Sell Legend Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    _propertyListingsTitle(context),
                    fontSize: context.font.md,
                    fontWeight: FontWeight.w600,
                    color: context.color.textColorDark,
                  ),
                  Row(
                    children: [
                      _buildLegendItem(
                        label: 'rent'.translate(context),
                        color: const Color(0xFF0088FF),
                      ),
                      SizedBox(width: 16.rw(context)),
                      _buildLegendItem(
                        label: 'sell'.translate(context),
                        color: const Color(0xFFE59400),
                      ),
                    ],
                  ),
                ],
              ),
              // List of properties or Shimmer loading
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: isLoadingProperty,
                  builder: (context, isLoading, child) {
                    if (isLoading || activePropertiesList == null) {
                      return UiUtils.buildHorizontalShimmer(context);
                    }
                    final list = activePropertiesList ?? [];
                    if (list.isEmpty) {
                      return Center(
                        child: NoDataFound(
                          onTapRetry: loadAll,
                          height: 80.rh(context),
                          title:
                              'noPropertiesFound'.translate(context) ==
                                  'noPropertiesFound'.translate(context)
                              ? 'No Properties Found'.translate(context)
                              : 'noPropertiesFound'.translate(context),
                          description: '',
                          showRetryButton: false,
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      separatorBuilder: (context, index) => SizedBox(
                        height: 12.rh(context),
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final property = list[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            unawaited(
                              HelperUtils.goToNextPage(
                                Routes.propertyDetails,
                                context,
                                false,
                                args: {
                                  'propertyData': property,
                                  'heroTag': 'map-list-${property.id}',
                                },
                              ),
                            );
                          },
                          child: AbsorbPointer(
                            child: PropertyHorizontalCard(
                              property: property,
                              showLikeButton: true,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _propertyListingsTitle(BuildContext context) {
    final translated = 'propertyListings'.translate(context);
    return translated == 'propertyListings' ? 'Property Listings' : translated;
  }

  Widget _buildLegendItem({
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18.rw(context),
          height: 18.rh(context),
          margin: EdgeInsets.only(right: 6.rw(context)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.color.secondaryColor,
            border: Border.all(
              color: color,
              width: 3.5.rw(context),
            ),
          ),
        ),
        CustomText(
          label,
          fontSize: context.font.sm,
          color: context.color.textColorDark,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }

  Widget _buildMarkerPropertyPreviewBox(BuildContext context) {
    final property = activePropertyModal;
    if (property == null || cities != null) {
      return const SizedBox.shrink();
    }

    final formattedPrice = property.price != null
        ? property.price!.priceFormat(
            enabled: Constant.isNumberWithSuffix,
            context: context,
            currencyCode: property.currencyCode,
            currencySymbol: property.currencySymbol,
          )
        : '';
    return Positioned(
      bottom: (MediaQuery.of(context).size.height * 0.46) + 12.rh(context),
      left: 14.rw(context),
      right: 14.rw(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: 260.rw(context)),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  onTap: () {
                    unawaited(
                      HelperUtils.goToNextPage(
                        Routes.propertyDetails,
                        context,
                        false,
                        args: {
                          'propertyData': property,
                          'heroTag': 'map-preview-${property.id}',
                        },
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8.rw(context)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Property Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CustomImage(
                            imageUrl: property.titleImage ?? '',
                            height: 84.rh(context),
                            width: 88.rw(context),
                          ),
                        ),
                        SizedBox(width: 10.rw(context)),
                        // Right: Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Row: Category (Icon + Name) & Close Button
                              Row(
                                children: [
                                  if (property.category?.image != null &&
                                      property.category!.image!.isNotEmpty)
                                    CustomImage(
                                      imageUrl: property.category!.image!,
                                      width: 14.rw(context),
                                      height: 14.rh(context),
                                      color: context.color.textColorDark
                                          .withValues(alpha: 0.7),
                                    )
                                  else
                                    Icon(
                                      Icons.home_outlined,
                                      size: 14,
                                      color: context.color.textColorDark
                                          .withValues(alpha: 0.7),
                                    ),
                                  SizedBox(width: 4.rw(context)),
                                  Expanded(
                                    child: CustomText(
                                      property.category?.translatedName ??
                                          property.category?.category ??
                                          'home'.translate(context),
                                      fontSize: context.font.xs,
                                      color: context.color.textColorDark
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w400,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3.rh(context)),
                              // Title
                              CustomText(
                                property.translatedTitle ??
                                    property.title ??
                                    '',
                                fontSize: context.font.sm,
                                fontWeight: FontWeight.bold,
                                color: context.color.textColorDark,
                                maxLines: 2,
                              ),

                              SizedBox(height: 6.rh(context)),
                              // Bottom Row: Price & Sell/Rent Label
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (formattedPrice.isNotEmpty)
                                    CustomText(
                                      formattedPrice,
                                      fontSize: context.font.sm,
                                      fontWeight: FontWeight.bold,
                                      color: context.color.tertiaryColor,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: Size(14.rw(context), 7.rh(context)),
              painter: _BubblePointerPainter(
                color: context.color.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubblePointerPainter extends CustomPainter {
  const _BubblePointerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
