import 'package:ebroker/data/cubits/fetch_properties_by_cities_cubit.dart';
import 'package:ebroker/data/cubits/property/home_infinityscroll_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/home_sections.dart';
import 'package:ebroker/ui/screens/widgets/dialog/location_out_of_country_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';

class ChooseLocationMap extends StatefulWidget {
  const ChooseLocationMap({
    super.key,
    this.from,
    this.countryName,
    this.countryId,
    this.initialLat,
    this.initialLng,
  });

  final String? from;
  final String? countryName;
  final String? countryId;
  final double? initialLat;
  final double? initialLng;

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return ChooseLocationMap(
          from: arguments?['from'] as String? ?? '',
          countryName: arguments?['country_name']?.toString() ?? '',
          countryId: arguments?['country_id']?.toString() ?? '',
          initialLat: double.tryParse(arguments?['latitude']?.toString() ?? ''),
          initialLng: double.tryParse(
            arguments?['longitude']?.toString() ?? '',
          ),
        );
      },
    );
  }

  @override
  State<ChooseLocationMap> createState() => _ChooseLocationMapState();
}

class _ChooseLocationMapState extends State<ChooseLocationMap> {
  double radius = double.parse(
    HiveUtils.getRadius()?.toString() ?? AppSettings.minRadius,
  );
  List<AppMapCircle> circles = [];
  final TextEditingController _searchController = TextEditingController();
  String previouseSearchQuery = '';
  LatLng? citylatLong;
  Timer? _timer;
  Timer? _snapDebounceTimer;
  AppMapMarker? marker;
  Map<dynamic, dynamic> map = {};
  AppMapController? _mapController;
  final FocusNode _searchFocus = FocusNode();
  List<PlaceModel>? cities;
  int selectedMarker = 999999999999999;
  int? propertyId;
  ValueNotifier<bool> loadintCitiesInProgress = ValueNotifier<bool>(false);
  bool showGoogleMap = false;
  bool _isApplyInProgress = false;
  double _currentZoom = 16;

  static const String _tagCityTap = 'city-tap';
  static const String _tagProceed = 'proceed';

  String? get _effectiveCountryId {
    if (widget.countryId != null && widget.countryId!.isNotEmpty) {
      return widget.countryId;
    }
    if (widget.countryName != null && widget.countryName!.isNotEmpty) {
      return context
          .read<FetchCountriesCubit>()
          .getCountry(name: widget.countryName)
          ?.id
          ?.toString();
    }
    return null;
  }

  Future<void> searchDelayTimer() async {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }

    _timer = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (_searchController.text.isNotEmpty) {
          if (previouseSearchQuery != _searchController.text) {
            try {
              loadintCitiesInProgress.value = true;
              cities = await MapServiceFactory.createPlaceSearchService()
                  .searchCities(
                    _searchController.text,
                    countryId: _effectiveCountryId,
                    countryName: widget.countryName,
                  );
              loadintCitiesInProgress.value = false;
            } on Exception catch (_) {
              loadintCitiesInProgress.value = false;
            }

            setState(() {});
            previouseSearchQuery = _searchController.text;
          }
        } else {
          cities = null;
        }
      },
    );
    setState(() {});
  }

  late LatLng assigned =
      (widget.initialLat != null && widget.initialLng != null)
      ? LatLng(widget.initialLat!, widget.initialLng!)
      : LatLng(
          double.tryParse(AppSettings.latitude) ?? 0,
          double.tryParse(AppSettings.longitude) ?? 0,
        );
  late LatLng cameraPosition = assigned;

  Future<void> _loadInitialLocation() async {
    if (widget.countryName != null && widget.countryName!.trim().isNotEmpty) {
      final countryCoords = await context
          .read<FetchCountriesCubit>()
          .getCountryCoordinatesAsync(
            name: widget.countryName,
            id: _effectiveCountryId,
          );
      if (widget.initialLat == null && countryCoords != null) {
        cameraPosition = countryCoords;
        marker = _buildDraggableMarker(countryCoords);
        if (widget.from == 'home_location') {
          _addCircle(countryCoords, radius);
        }
        setState(() {});
        if (_mapController != null) {
          await _mapController!.animateTo(countryCoords, zoom: _currentZoom);
        }
        return;
      }

      try {
        final searchService = MapServiceFactory.createPlaceSearchService();
        final results = await searchService.searchCities(
          widget.countryName!.trim(),
          countryId: _effectiveCountryId,
          countryName: widget.countryName,
        );
        if (results.isNotEmpty) {
          PlaceModel? matchingPlace;
          for (final p in results) {
            if (_isLocationInSelectedCountry(p.country, widget.countryName!) ||
                _isLocationInSelectedCountry(
                  p.description,
                  widget.countryName!,
                ) ||
                _isLocationInSelectedCountry(p.city, widget.countryName!)) {
              matchingPlace = p;
              break;
            }
          }
          matchingPlace ??= results.first;

          var lat = double.tryParse(matchingPlace.latitude);
          var lng = double.tryParse(matchingPlace.longitude);

          if (lat == null || lng == null || (lat == 0 && lng == 0)) {
            final details = await searchService.getPlaceDetails(
              placeId: matchingPlace.placeId,
              latitude: matchingPlace.latitude,
              longitude: matchingPlace.longitude,
              countryId: _effectiveCountryId,
            );
            if (_isLocationInSelectedCountry(
              details.country,
              widget.countryName!,
            )) {
              lat = details.lat;
              lng = details.lng;
            }
          }

          if (lat != null && lng != null) {
            final position = LatLng(lat, lng);
            cameraPosition = position;
            marker = _buildDraggableMarker(position);
            if (widget.from == 'home_location') {
              _addCircle(position, radius);
            }
            setState(() {});
            if (_mapController != null) {
              await _mapController!.animateTo(position, zoom: _currentZoom);
            }
            return;
          }
        }
      } on Exception catch (e) {
        debugPrint('Error loading country location: $e');
      }
    }

    // If explicit coordinates are provided (e.g. from manual location selection in wizard steps)
    if (widget.initialLat != null && widget.initialLng != null) {
      final position = LatLng(widget.initialLat!, widget.initialLng!);
      cameraPosition = position;
      marker = _buildDraggableMarker(position);
      if (widget.from == 'home_location') {
        _addCircle(position, radius);
      }
      setState(() {});
      if (_mapController != null) {
        await _mapController!.animateTo(position, zoom: _currentZoom);
      }
      return;
    }

    dynamic lat;
    dynamic long;

    if (widget.from == 'home_location') {
      lat = HiveUtils.getLatitude();
      long = HiveUtils.getLongitude();
    } else {
      lat = HiveUtils.getUserLatitude();
      long = HiveUtils.getUserLongitude();
    }

    final latitude = double.tryParse(lat?.toString() ?? '');
    final longitude = double.tryParse(long?.toString() ?? '');

    if (latitude != null && longitude != null) {
      final position = LatLng(latitude, longitude);
      cameraPosition = position;
      marker = _buildDraggableMarker(position);

      if (widget.from == 'home_location') {
        _addCircle(position, radius);
      }

      // Trigger UI rebuild with the loaded marker and circle
      setState(() {});

      if (_mapController != null) {
        await _mapController!.animateTo(position, zoom: _currentZoom);
      }
    } else {
      await _getCurrentLocation(updateMarker: true);
    }
  }

  bool _isLocationInSelectedCountry(
    String detectedCountry,
    String selectedCountry,
  ) {
    return context.read<FetchCountriesCubit>().isMatchingCountry(
      detectedCountry,
      selectedCountry,
    );
  }

  Future<void> _getCurrentLocation({bool updateMarker = false}) async {
    try {
      final locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied ||
            requestedPermission == LocationPermission.deniedForever) {
          if (mounted) {
            HelperUtils.showSnackBarMessage(
              context,
              'locationPermissionDenied',
              type: .error,
            );
          }
          return;
        }
      } else if (locationPermission == LocationPermission.deniedForever) {
        if (mounted) {
          HelperUtils.showSnackBarMessage(
            context,
            'locationPermissionDenied',
            type: .error,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);

      if (widget.countryName != null &&
          widget.countryName!.trim().isNotEmpty &&
          widget.countryName != 'all') {
        PlaceDetails? details;
        try {
          details = await MapServiceFactory.createPlaceSearchService()
              .getPlaceDetails(
                latitude: position.latitude.toString(),
                longitude: position.longitude.toString(),
                countryId: _effectiveCountryId,
              );
        } on Exception catch (e) {
          debugPrint('Error getting place details for current location: $e');
        }

        if (details != null && details.isSnapped) {
          if (mounted) {
            await LocationOutOfCountryDialog.show(context);
            await _loadInitialLocation();
          }
          return;
        }
      }

      if (_mapController != null) {
        await _mapController!.animateTo(latLng, zoom: _currentZoom);
      }

      if (updateMarker) {
        marker = _buildDraggableMarker(latLng);
        _addCircle(marker!.position, radius);
        setState(() {});
      }
    } on Exception catch (e) {
      debugPrint('Error in _getCurrentLocation: $e');
    }
  }

  bool _isInitialLocationLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlaceDetailsCubit>().reset();
    });
    unawaited(locationPermission());
    _searchController.addListener(searchDelayTimer);

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        showGoogleMap = true;
        setState(() {});
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLocationLoaded) {
      _isInitialLocationLoaded = true;
      unawaited(_loadInitialLocation());
    }
  }

  Future<void> locationPermission() async {
    if ((await Permission.location.status) == PermissionStatus.denied) {
      await Permission.location.request();
    }
  }

  void onTapCity(int index) {
    final selected = cities?.elementAtOrNull(index);
    if (selected == null) return;
    unawaited(
      context.read<PlaceDetailsCubit>().fetch(
        placeId: selected.placeId,
        latitude: selected.latitude,
        longitude: selected.longitude,
        tag: _tagCityTap,
        countryId: _effectiveCountryId,
      ),
    );
  }

  Future<void> _handleCityTapSuccess(PlaceDetails details) async {
    if (details.lat == null || details.lng == null) return;
    final latLng = LatLng(details.lat!, details.lng!);
    if (_mapController != null) {
      await _mapController!.animateTo(latLng, zoom: _currentZoom);
    }
    marker = _buildDraggableMarker(latLng);
    if (widget.from == 'home_location') {
      _addCircle(latLng, radius);
    }
    _searchFocus.unfocus();
    HelperUtils.unfocus();
    cities = null;
    if (mounted) setState(() {});

    if (details.isSnapped && mounted) {
      final targetCountry =
          (details.snappedCountryName != null &&
              details.snappedCountryName!.isNotEmpty)
          ? details.snappedCountryName!
          : (widget.countryName != null && widget.countryName!.isNotEmpty
                ? widget.countryName!
                : 'the selected country');
      HelperUtils.showSnackBarMessage(
        context,
        "That location is outside the selected country, so it's been moved to the nearest point in $targetCountry",
        type: MessageType.warning,
      );
    }
  }

  Future<void> _handleProceedSuccess(PlaceDetails details) async {
    if (marker == null) return;

    final selectedCountry =
        (widget.countryName != null && widget.countryName != 'all')
        ? widget.countryName!
        : '';

    if (details.isSnapped) {
      if (mounted) {
        setState(() => _isApplyInProgress = false);
      }
      final countryCoords = await context
          .read<FetchCountriesCubit>()
          .getCountryCoordinatesAsync(
            name: selectedCountry,
            id: _effectiveCountryId,
          );
      final targetLatLng =
          (details.lat != null && details.lng != null && details.isSnapped)
          ? LatLng(details.lat!, details.lng!)
          : countryCoords;

      if (targetLatLng != null) {
        cameraPosition = targetLatLng;
        marker = _buildDraggableMarker(targetLatLng);
        if (_mapController != null) {
          unawaited(
            _mapController!.animateTo(targetLatLng, zoom: _currentZoom),
          );
        }
        if (widget.from == 'home_location') {
          _addCircle(targetLatLng, radius);
        }
        setState(() {});
      }
      final targetCountry =
          (details.snappedCountryName != null &&
              details.snappedCountryName!.isNotEmpty)
          ? details.snappedCountryName!
          : (selectedCountry.isNotEmpty
                ? selectedCountry
                : 'the selected country');
      if (mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          "That location is outside the selected country, so it's been moved to the nearest point in $targetCountry",
          type: MessageType.warning,
        );
      }
      return;
    }

    final resolvedAddress = details.address.isNotEmpty
        ? details.address
        : [
            details.city,
            details.state,
            details.country,
          ].where((s) => s.isNotEmpty).join(', ');
    final place = Placemark(
      name: resolvedAddress,
      street: resolvedAddress,
      locality: details.city,
      administrativeArea: details.state,
      country: details.country,
    );
    final latitude = marker!.position.latitude.toString();
    final longitude = marker!.position.longitude.toString();
    final radiusValue = radius.toString();

    showGoogleMap = false;
    if (widget.from == 'home_location') {
      await HiveUtils.setHomeLocation(
        city: place.locality.toString(),
        state: place.administrativeArea.toString(),
        latitude: latitude,
        longitude: longitude,
        country: place.country.toString(),
        placeId: HiveUtils.getHomeCityPlaceId()?.toString() ?? '',
        radius: radiusValue,
      );
    } else {
      await HiveUtils.setLocation(
        city: place.locality.toString(),
        state: place.administrativeArea.toString(),
        latitude: latitude,
        longitude: longitude,
        country: place.country.toString(),
        placeId: HiveUtils.getUserCityPlaceId()?.toString() ?? '',
      );
    }
    if (!mounted) return;
    Navigator.pop<Map<dynamic, dynamic>>(context, {
      'latlng': LatLng(marker!.position.latitude, marker!.position.longitude),
      'place': place,
      'address': resolvedAddress,
      'city': details.city,
      'state': details.state,
      'country': details.country,
      if (widget.from == 'home_location') 'radius': radiusValue,
    });
  }

  AppMapMarker _buildDraggableMarker(LatLng position) {
    return AppMapMarker(
      id: '9999999',
      position: position,
      pinType: LocationPinType.selected,
      draggable: true,
      onDrag: (newPosition) {
        setState(() {
          cameraPosition = newPosition;
          marker = _buildDraggableMarker(newPosition);
          _addCircle(newPosition, radius);
        });
      },
      onDragEnd: _onLocationSelected,
    );
  }

  void _onLocationSelected(LatLng latLng) {
    setState(() {
      selectedMarker = 99999999999999;
      cameraPosition = latLng;
      marker = _buildDraggableMarker(cameraPosition);
      _addCircle(
        marker!.position,
        radius,
      );
    });

    _snapDebounceTimer?.cancel();
    _snapDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final selectedCountry =
          (widget.countryName != null && widget.countryName != 'all')
          ? widget.countryName!
          : '';
      try {
        final details = await MapServiceFactory.createPlaceSearchService()
            .getPlaceDetails(
              latitude: latLng.latitude.toString(),
              longitude: latLng.longitude.toString(),
              countryId: _effectiveCountryId,
            );

        if (details.isSnapped && mounted) {
          final countryCoords = await context
              .read<FetchCountriesCubit>()
              .getCountryCoordinatesAsync(
                name: selectedCountry,
                id: _effectiveCountryId,
              );
          final targetLatLng =
              (details.lat != null && details.lng != null && details.isSnapped)
              ? LatLng(details.lat!, details.lng!)
              : countryCoords;

          if (targetLatLng != null) {
            cameraPosition = targetLatLng;
            marker = _buildDraggableMarker(targetLatLng);
            if (_mapController != null) {
              unawaited(
                _mapController!.animateTo(targetLatLng, zoom: _currentZoom),
              );
            }
            if (widget.from == 'home_location') {
              _addCircle(targetLatLng, radius);
            }
            setState(() {});
          }

          final targetCountry =
              (details.snappedCountryName != null &&
                  details.snappedCountryName!.isNotEmpty)
              ? details.snappedCountryName!
              : (selectedCountry.isNotEmpty
                    ? selectedCountry
                    : 'the selected country');

          HelperUtils.showSnackBarMessage(
            context,
            "That location is outside the selected country, so it's been moved to the nearest point in $targetCountry",
            type: MessageType.warning,
          );
        }
      } on Exception catch (e) {
        debugPrint('Error getting place details on location selected: $e');
      }
    });
  }

  @override
  void dispose() {
    _snapDebounceTimer?.cancel();
    _searchController.removeListener(searchDelayTimer);
    _timer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Widget buildSearchIcon() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CustomImage(
        imageUrl: AppIcons.search,
        color: context.color.tertiaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        showGoogleMap = false;
        setState(() {});

        Future.delayed(Duration.zero, () {
          Navigator.of(context).pop();
        });
      },
      child: Scaffold(
        backgroundColor: context.color.secondaryColor,
        appBar: CustomAppBar(
          title: 'chooseLocation'.translate(context),
          actions: [
            if (widget.from == 'home_location' && marker != null)
              GestureDetector(
                onTap: () {
                  marker = null;
                  circles.clear();
                  radius = double.parse(AppSettings.minRadius);
                  setState(() {});
                },
                child: CustomText(
                  'clear'.translate(context),
                  color: context.color.tertiaryColor,
                  fontSize: context.font.sm,
                  fontWeight: .w500,
                ),
              ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: .min,
          children: [
            if (widget.from == 'home_location') buildRadiusSelector(),
            if (widget.from != 'home_location')
              SizedBox(height: 16.rh(context)),
            ValueListenableBuilder<bool>(
              valueListenable: HomeSections.isLoadingNotifier,
              builder: (context, homeSectionsLoading, _) => UiUtils.buildButton(
                context,
                height: 48.rh(context),
                outerPadding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 24,
                ),
                isInProgress:
                    _isApplyInProgress ||
                    homeSectionsLoading ||
                    context.watch<FetchPropertiesByCitiesCubit>().state
                        is FetchPropertiesByCitiesLoading ||
                    context.watch<HomePageInfinityScrollCubit>().state
                        is HomePageInfinityScrollInProgress ||
                    context.watch<PlaceDetailsCubit>().state
                        is PlaceDetailsInProgress,
                onPressed: marker == null
                    ? widget.from == 'home_location'
                          ? () async {
                              if (_isApplyInProgress) return;
                              setState(() => _isApplyInProgress = true);
                              try {
                                await HiveUtils.clearHomeLocation();
                                if (!context.mounted) return;
                                if (!ActiveRoleManager.isAgent) {
                                  await HomeSections.fetchAllHomeSections(
                                    context,
                                    forceRefresh: true,
                                  );
                                  if (!context.mounted) return;
                                  await context
                                      .read<FetchPropertiesByCitiesCubit>()
                                      .fetch();
                                  if (!context.mounted) return;
                                  await context
                                      .read<HomePageInfinityScrollCubit>()
                                      .fetch();
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              } finally {
                                if (mounted) {
                                  setState(() => _isApplyInProgress = false);
                                }
                              }
                            }
                          : () async {
                              return HelperUtils.showSnackBarMessage(
                                context,
                                'pleaseSelectLocation',
                                type: .error,
                              );
                            }
                    : widget.from == 'home_location'
                    ? () async {
                        if (_isApplyInProgress) return;
                        setState(() => _isApplyInProgress = true);
                        final hasInternet = await HelperUtils.checkInternet();
                        if (!hasInternet) {
                          if (!context.mounted) return;
                          if (mounted) {
                            setState(() => _isApplyInProgress = false);
                          }
                          return HelperUtils.showSnackBarMessage(
                            context,
                            'noInternet',
                            type: .error,
                          );
                        }
                        if (!context.mounted) return;
                        unawaited(
                          context.read<PlaceDetailsCubit>().fetch(
                            latitude: marker!.position.latitude.toString(),
                            longitude: marker!.position.longitude.toString(),
                            tag: _tagProceed,
                            countryId: _effectiveCountryId,
                          ),
                        );
                      }
                    : () async {
                        final hasInternet = await HelperUtils.checkInternet();
                        if (!hasInternet) {
                          if (!context.mounted) return;
                          return HelperUtils.showSnackBarMessage(
                            context,
                            'noInternet',
                            type: .error,
                          );
                        }
                        if (!context.mounted) return;
                        unawaited(
                          context.read<PlaceDetailsCubit>().fetch(
                            latitude: marker!.position.latitude.toString(),
                            longitude: marker!.position.longitude.toString(),
                            tag: _tagProceed,
                            countryId: _effectiveCountryId,
                          ),
                        );
                      },
                buttonTitle: widget.from == 'home_location'
                    ? 'apply'.translate(context)
                    : 'proceed'.translate(context),
              ),
            ),
          ],
        ),
        body: BlocListener<PlaceDetailsCubit, PlaceDetailsState>(
          listener: (context, state) {
            if (state is PlaceDetailsSuccess) {
              if (state.tag == _tagCityTap) {
                unawaited(_handleCityTapSuccess(state.details));
              } else if (state.tag == _tagProceed) {
                unawaited(_handleProceedSuccess(state.details));
              }
            } else if (state is PlaceDetailsFail) {
              if (mounted && _isApplyInProgress) {
                setState(() => _isApplyInProgress = false);
              }
              HelperUtils.showSnackBarMessage(
                context,
                state.error.toString().contains('IO_ERROR')
                    ? 'pleaseChangeNetwork'.translate(context)
                    : state.error.toString(),
                type: MessageType.error,
              );
            }
          },
          child: Stack(
            children: [
              SizedBox(
                height: context.screenHeight,
                width: context.screenWidth,
                child: showGoogleMap
                    ? AppMapWidget(
                        config: AppMapConfig(
                          initialLatLng: cameraPosition,
                          initialZoom: _currentZoom,
                          markers: marker != null ? [marker!] : const [],
                          circles: circles,
                          onReady: (controller) async {
                            _mapController = controller;
                            if (marker != null) {
                              await controller.animateTo(
                                marker!.position,
                                zoom: _currentZoom,
                              );
                            }
                            setState(() {});
                          },
                          onTap: (latLng) {
                            if (_mapController != null) {
                              unawaited(
                                _mapController!.animateTo(
                                  latLng,
                                  zoom: _currentZoom,
                                ),
                              );
                            }
                            _onLocationSelected(latLng);
                          },
                          onCameraMove: (position, zoom) {
                            _currentZoom = zoom;
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (cities != null)
                Material(
                  color: context.color.backgroundColor,
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 64.rh(context)),
                    itemCount: cities?.length ?? 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () => onTapCity(index),
                        leading: SvgPicture.asset(
                          AppIcons.location,
                          colorFilter: ColorFilter.mode(
                            context.color.textColorDark,
                            .srcIn,
                          ),
                        ),
                        title: CustomText(cities?.elementAt(index).city ?? ''),
                        subtitle: CustomText(
                          '',
                          isRichText: true,
                          textSpan: TextSpan(
                            text: cities?.elementAt(index).state ?? '',
                            children: [
                              if (cities?.elementAt(index).country != '')
                                TextSpan(
                                  text:
                                      ',${cities?.elementAt(index).country ?? ''}',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ValueListenableBuilder(
                valueListenable: loadintCitiesInProgress,
                builder: (context, value, child) {
                  if (cities == null && loadintCitiesInProgress.value) {
                    return ColoredBox(
                      color: context.color.backgroundColor,
                      child: Center(
                        child: UiUtils.progress(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              PositionedDirectional(
                top: 0,
                start: 0,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: context.color.secondaryColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.color.borderColor),
                      ),
                      margin: const EdgeInsetsDirectional.only(
                        top: 16,
                        start: 16,
                      ),
                      height: 48.rh(context),
                      width: context.screenWidth - 80.rw(context),
                      child: CustomTextFormField(
                        controller: _searchController,
                        borderColor: Colors.transparent,
                        hintText: 'searhCity'.translate(context),
                        prefix: GestureDetector(
                          onTap: () {
                            if (_searchController.text.isEmpty &&
                                cities == null) {
                              return;
                            }
                            cities = null;
                            _searchController.text = '';
                            setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 16,
                              end: 8,
                            ),
                            child: CustomImage(
                              width: 24.rw(context),
                              height: 24.rh(context),
                              imageUrl:
                                  _searchController.text.isEmpty &&
                                      cities == null
                                  ? AppIcons.search
                                  : AppIcons.closeCircle,
                              color: context.color.tertiaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: context.color.secondaryColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.color.borderColor),
                      ),
                      margin: const EdgeInsetsDirectional.only(
                        top: 16,
                        start: 8,
                        end: 16,
                      ),
                      height: 48.rh(context),
                      width: 48.rw(context),
                      child: GestureDetector(
                        onTap: () async {
                          await _getCurrentLocation(updateMarker: true);
                        },
                        child: Icon(
                          Icons.my_location_sharp,
                          color: context.color.textColorDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                bottom: 80.rh(context),
                end: 16.rw(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: context.color.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.color.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      width: 44.rw(context),
                      height: 44.rh(context),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: () {
                            _currentZoom = (_currentZoom + 1).clamp(2.0, 20.0);
                            if (_mapController != null) {
                              unawaited(
                                _mapController!.animateTo(
                                  marker?.position ?? cameraPosition,
                                  zoom: _currentZoom,
                                ),
                              );
                            }
                          },
                          child: Icon(
                            Icons.add,
                            color: context.color.textColorDark,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.rh(context)),
                    Container(
                      decoration: BoxDecoration(
                        color: context.color.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.color.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      width: 44.rw(context),
                      height: 44.rh(context),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: () {
                            _currentZoom = (_currentZoom - 1).clamp(2.0, 20.0);
                            if (_mapController != null) {
                              unawaited(
                                _mapController!.animateTo(
                                  marker?.position ?? cameraPosition,
                                  zoom: _currentZoom,
                                ),
                              );
                            }
                          },
                          child: Icon(
                            Icons.remove,
                            color: context.color.textColorDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRadiusSelector() {
    final minRadius = double.parse(
      AppSettings.minRadius.isEmpty ? '1' : AppSettings.minRadius,
    );
    return Container(
      color: context.color.secondaryColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'selectAreaRange'.translate(context),
            color: context.color.textColorDark,
            fontSize: context.font.md,
            fontWeight: .w500,
          ),
          SizedBox(height: 8.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 8.rh(context)),
          CustomText(
            '${'radius'.translate(context)} : ${radius.toInt()} ${AppSettings.distanceOption.translate(context)}',
            color: context.color.textColorDark,
            fontSize: context.font.sm,
          ),
          SizedBox(height: 12.rh(context)),
          Slider(
            thumbColor: marker == null
                ? context.color.textLightColor
                : context.color.tertiaryColor,
            value: radius < minRadius ? minRadius : radius,
            padding: EdgeInsets.zero,
            min: double.parse(AppSettings.minRadius),
            max: double.parse(AppSettings.maxRadius),
            activeColor: marker == null
                ? context.color.textLightColor
                : context.color.tertiaryColor,
            inactiveColor: context.color.textLightColor.withValues(alpha: 0.1),
            divisions:
                (double.parse(AppSettings.maxRadius) -
                        double.parse(AppSettings.minRadius))
                    .toInt(),
            label:
                '${radius.toInt()} ${AppSettings.distanceOption.translate(context)}',
            onChanged: (value) {
              if (marker == null) {
                return; // Exit early if no location is selected
              }

              // Use a single setState call to update the radius and redraw the circle.
              // This is much more efficient.
              setState(() {
                radius = value;
                _addCircle(
                  LatLng(marker!.position.latitude, marker!.position.longitude),
                  radius,
                );
              });
            },
          ),
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              CustomText(
                '${AppSettings.minRadius} ${AppSettings.distanceOption.translate(context)}',
                color: context.color.textColorDark,
                fontSize: context.font.sm,
                fontWeight: .w400,
              ),
              CustomText(
                '${AppSettings.maxRadius} ${AppSettings.distanceOption.translate(context)}',
                color: context.color.textColorDark,
                fontSize: context.font.sm,
                fontWeight: .w400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addCircle(LatLng position, double radiusInKm) {
    if (widget.from != 'home_location') return;
    final radiusInMeters = radiusInKm * 1000; // Convert km to meters

    circles = [
      AppMapCircle(
        id: 'searchRadius',
        center: position,
        radius: radiusInMeters,
        fillColor: context.color.tertiaryColor.withValues(alpha: .2),
        strokeColor: context.color.tertiaryColor,
      ),
    ];
  }
}
