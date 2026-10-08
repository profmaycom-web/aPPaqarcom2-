import 'dart:async';
import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/ui/screens/map/choose_location_map.dart';
import 'package:ebroker/ui/screens/project/add_project/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/ui/screens/widgets/dialog/country_selection_dialog.dart';
import 'package:ebroker/ui/screens/widgets/dialog/location_out_of_country_dialog.dart';
import 'package:ebroker/ui/screens/widgets/location_autocomplete_field.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/location_pin.dart';
import 'package:ebroker/utils/map/app_map_controller.dart';
import 'package:ebroker/utils/map/app_map_widget.dart';
import 'package:ebroker/utils/map/map_service_factory.dart';
import 'package:ebroker/utils/map/place_details.dart';
import 'package:ebroker/utils/map/place_model.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

class LocationData {
  LocationData({
    this.city = '',
    this.state = '',
    this.country = '',
    this.countryId,
    this.selectedCountry,
    this.address = '',
    this.clientAddress = '',
    this.latitude = '',
    this.longitude = '',
  });

  String city;
  String state;
  String country;
  String? countryId;
  CountryModel? selectedCountry;
  String address;
  String clientAddress;
  String latitude;
  String longitude;

  LocationData clone() {
    return LocationData(
      city: city,
      state: state,
      country: country,
      countryId: countryId,
      selectedCountry: selectedCountry,
      address: address,
      clientAddress: clientAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class LocationStepView extends StatefulWidget {
  const LocationStepView({
    required this.initialData,
    required this.onLocationDataChanged,
    required this.onNext,
    required this.onBack,
    required this.stepIndicator,
    required this.from,
    this.onCountrySelected,
    this.onSaveDraft,
    this.isSavingDraft = false,
    this.addressFieldLabel = 'addressLbl',
    this.clientAddressFieldLabel = 'clientaddressLbl',
    super.key,
  });

  final LocationData initialData;
  final ValueChanged<LocationData> onLocationDataChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String stepIndicator;
  final String from;
  final ValueChanged<CountryModel>? onCountrySelected;
  final VoidCallback? onSaveDraft;
  final bool isSavingDraft;
  final String addressFieldLabel;
  final String clientAddressFieldLabel;

  @override
  State<LocationStepView> createState() => _LocationStepViewState();
}

class _LocationStepViewState extends State<LocationStepView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _addressController;
  late final TextEditingController _clientAddressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  late LocationData _locationData;

  bool _isGettingLocation = false;
  AppMapController? _mapController;
  double _currentZoom = 16;
  LatLng? _currentMapCenter;
  final ValueNotifier<bool> _isMapMoving = ValueNotifier<bool>(false);
  bool _skipNextIdleGeocode = false;
  Timer? _reverseGeocodeDebounce;
  bool _isReverseGeocoding = false;
  LatLng? _lastGeocodedPosition;

  bool _isSameLocation(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.0001 &&
        (a.longitude - b.longitude).abs() < 0.0001;
  }

  @override
  void initState() {
    super.initState();
    _locationData = widget.initialData.clone();
    final countryName = _effectiveCountryName;

    _cityController = TextEditingController(text: _locationData.city);
    _stateController = TextEditingController(text: _locationData.state);
    _countryController = TextEditingController(
      text: _locationData.country.isNotEmpty
          ? _locationData.country
          : countryName,
    );
    _addressController = TextEditingController(text: _locationData.address);
    _clientAddressController = TextEditingController(
      text: _locationData.clientAddress,
    );
    _latitudeController = TextEditingController(text: _locationData.latitude);
    _longitudeController = TextEditingController(text: _locationData.longitude);

    final initialLat = double.tryParse(_locationData.latitude);
    final initialLng = double.tryParse(_locationData.longitude);
    final defaultCoords = _getCountryCoordinates(countryName);

    if (initialLat != null &&
        initialLng != null &&
        initialLat != 0 &&
        initialLng != 0) {
      _currentMapCenter = LatLng(initialLat, initialLng);
      _lastGeocodedPosition = _currentMapCenter;
    } else if (defaultCoords != null) {
      _currentMapCenter = defaultCoords;
      _latitudeController.text = defaultCoords.latitude.toString();
      _longitudeController.text = defaultCoords.longitude.toString();
      _lastGeocodedPosition = defaultCoords;
      _syncData();
    }

    if (countryName.isNotEmpty &&
        (initialLat == null ||
            initialLng == null ||
            initialLat == 0 ||
            initialLng == 0)) {
      unawaited(_resolveCountryLocation(countryName));
    }
  }

  String get _effectiveCountryName {
    if (_locationData.country.trim().isNotEmpty) {
      return _locationData.country.trim();
    }
    if ((_locationData.selectedCountry?.name ?? '').trim().isNotEmpty) {
      return _locationData.selectedCountry!.name!.trim();
    }
    return '';
  }

  String? get _effectiveCountryId {
    if (_locationData.countryId != null &&
        _locationData.countryId!.trim().isNotEmpty) {
      return _locationData.countryId!.trim();
    }
    if (_locationData.selectedCountry?.id != null) {
      return _locationData.selectedCountry!.id!.toString();
    }
    final c = context.read<FetchCountriesCubit>().getCountry(
      name: _selectedCountryName,
    );
    return c?.id?.toString();
  }

  String get _selectedCountryName {
    final countryText = _countryController.text.trim();
    if (countryText.isNotEmpty) {
      return countryText;
    }
    return _effectiveCountryName;
  }

  bool get _hasSelectedCountry {
    final countryText = _countryController.text.trim();
    final directCountry = _effectiveCountryName;
    return countryText.isNotEmpty || directCountry.isNotEmpty;
  }

  LatLng? _getCountryCoordinates(String countryName) {
    if (_locationData.selectedCountry != null &&
        _locationData.selectedCountry!.latitude != null &&
        _locationData.selectedCountry!.longitude != null &&
        (_locationData.selectedCountry!.latitude != 0 ||
            _locationData.selectedCountry!.longitude != 0)) {
      return LatLng(
        _locationData.selectedCountry!.latitude!,
        _locationData.selectedCountry!.longitude!,
      );
    }
    return context.read<FetchCountriesCubit>().getCountryCoordinates(
      name: countryName,
      id: _effectiveCountryId,
    );
  }

  void _syncData() {
    _locationData.city = _cityController.text.trim();
    _locationData.state = _stateController.text.trim();
    _locationData.country = _countryController.text.trim();
    _locationData.address = _addressController.text.trim();
    _locationData.clientAddress = _clientAddressController.text.trim();
    _locationData.latitude = _latitudeController.text.trim();
    _locationData.longitude = _longitudeController.text.trim();
    _locationData.countryId = _effectiveCountryId;
    widget.onLocationDataChanged(_locationData);
  }

  Future<void> _resolveCountryLocation(String countryName) async {
    if (countryName.trim().isEmpty || countryName.toLowerCase() == 'all') {
      return;
    }
    try {
      final countryCoords = await context
          .read<FetchCountriesCubit>()
          .getCountryCoordinatesAsync(
            name: countryName,
            id: _effectiveCountryId,
          );
      if (countryCoords != null) {
        _skipNextIdleGeocode = true;
        _lastGeocodedPosition = countryCoords;
        _currentMapCenter = countryCoords;
        _latitudeController.text = countryCoords.latitude.toString();
        _longitudeController.text = countryCoords.longitude.toString();
        _countryController.text = countryName;
        if (mounted) setState(() {});
        _syncData();
        if (_mapController != null) {
          unawaited(
            _mapController!.animateTo(countryCoords, zoom: _currentZoom),
          );
        }
        return;
      }

      final searchService = MapServiceFactory.createPlaceSearchService();
      final results = await searchService.searchCities(
        countryName,
        countryId: _effectiveCountryId,
        countryName: countryName,
      );
      if (results.isNotEmpty) {
        PlaceModel? matchingPlace;
        for (final p in results) {
          if (p.country.toLowerCase().contains(countryName.toLowerCase()) ||
              p.description.toLowerCase().contains(countryName.toLowerCase()) ||
              p.city.toLowerCase().contains(countryName.toLowerCase())) {
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
          if (!details.isSnapped) {
            lat = details.lat;
            lng = details.lng;
            if (details.country.isNotEmpty && mounted) {
              _countryController.text = details.country;
            }
            if (details.city.isNotEmpty &&
                _cityController.text.isEmpty &&
                mounted) {
              _cityController.text = details.city;
            }
            if (details.state.isNotEmpty &&
                _stateController.text.isEmpty &&
                mounted) {
              _stateController.text = details.state;
            }
            if (details.address.isNotEmpty &&
                _addressController.text.isEmpty &&
                mounted) {
              _addressController.text = details.address;
            }
          }
        }
        if (lat != null && lng != null && mounted) {
          final pos = LatLng(lat, lng);
          _skipNextIdleGeocode = true;
          _lastGeocodedPosition = pos;
          setState(() {
            _latitudeController.text = lat.toString();
            _longitudeController.text = lng.toString();
            _currentMapCenter = pos;
            if (_countryController.text.isEmpty) {
              _countryController.text = countryName;
            }
          });
          _syncData();
          if (_mapController != null) {
            unawaited(_mapController!.animateTo(pos, zoom: _currentZoom));
          }
        }
      }
    } on Exception catch (e) {
      debugPrint('Error resolving country location: $e');
    }
  }

  Future<void> _openCountrySelector() async {
    final selectedCountry = await showDialog<CountryModel>(
      context: context,
      builder: (_) => const CountrySelectionDialog(),
    );
    if (selectedCountry != null &&
        (selectedCountry.name?.trim().isNotEmpty ?? false) &&
        selectedCountry.name != 'all' &&
        mounted) {
      _locationData.selectedCountry = selectedCountry;
      _locationData.country = selectedCountry.name!;
      _locationData.countryId = selectedCountry.id?.toString();
      widget.onCountrySelected?.call(selectedCountry);

      final name = selectedCountry.name!;
      _cityController.clear();
      _stateController.clear();
      _addressController.clear();
      _clientAddressController.clear();

      final lat =
          selectedCountry.latitude ??
          context.read<FetchCountriesCubit>().getCountry(name: name)?.latitude;
      final lng =
          selectedCountry.longitude ??
          context.read<FetchCountriesCubit>().getCountry(name: name)?.longitude;

      if (lat != null && lng != null && (lat != 0 || lng != 0)) {
        final coords = LatLng(lat, lng);
        _skipNextIdleGeocode = true;
        _lastGeocodedPosition = coords;
        setState(() {
          _countryController.text = name;
          _latitudeController.text = lat.toString();
          _longitudeController.text = lng.toString();
          _currentMapCenter = coords;
        });
        _syncData();
        if (_mapController != null) {
          unawaited(_mapController!.animateTo(coords, zoom: _currentZoom));
        }
      } else {
        setState(() {
          _countryController.text = name;
        });
        _syncData();
        await _resolveCountryLocation(name);
      }
    }
  }

  void _handleOutOfCountry(
    String selectedCountry,
    String? snappedCountryName, {
    PlaceDetails? details,
  }) {
    final snappedLatLng = (details?.lat != null && details?.lng != null)
        ? LatLng(details!.lat!, details.lng!)
        : _getCountryCoordinates(selectedCountry);

    if (snappedLatLng != null) {
      _skipNextIdleGeocode = true;
      _lastGeocodedPosition = snappedLatLng;
      _latitudeController.text = snappedLatLng.latitude.toString();
      _longitudeController.text = snappedLatLng.longitude.toString();
      _currentMapCenter = snappedLatLng;
      if (details != null) {
        _cityController.text = details.city;
        _stateController.text = details.state;
        if (details.country.isNotEmpty) {
          _countryController.text = details.country;
        }
        final fullAddr = details.address.isNotEmpty
            ? details.address
            : [
                details.city,
                details.state,
                details.country,
              ].where((s) => s.isNotEmpty).join(', ');
        _addressController.text = fullAddr;
      }
      if (_mapController != null) {
        unawaited(
          _mapController!.animateTo(snappedLatLng, zoom: _currentZoom),
        );
      }
    }

    final targetCountry =
        (snappedCountryName != null && snappedCountryName.isNotEmpty)
        ? snappedCountryName
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
    _syncData();
    if (mounted) setState(() {});
  }

  Future<void> _reverseGeocodePosition(LatLng pos) async {
    if (_isReverseGeocoding) return;
    if (_lastGeocodedPosition != null &&
        _isSameLocation(pos, _lastGeocodedPosition!)) {
      return;
    }
    _isReverseGeocoding = true;
    final latStr = pos.latitude.toString();
    final lngStr = pos.longitude.toString();
    final selectedCountry = _selectedCountryName;
    try {
      final details = await MapServiceFactory.createPlaceSearchService()
          .getPlaceDetails(
            latitude: latStr,
            longitude: lngStr,
            countryId: _effectiveCountryId,
          );

      if (details.isSnapped) {
        _lastGeocodedPosition = (details.lat != null && details.lng != null)
            ? LatLng(details.lat!, details.lng!)
            : pos;
        _handleOutOfCountry(
          selectedCountry,
          details.snappedCountryName,
          details: details,
        );
        return;
      }

      _lastGeocodedPosition = pos;
      _latitudeController.text = latStr;
      _longitudeController.text = lngStr;
      _currentMapCenter = pos;

      _cityController.text = details.city;
      _stateController.text = details.state;
      if (details.country.isNotEmpty) {
        _countryController.text = details.country;
      }
      final fullAddr = details.address.isNotEmpty
          ? details.address
          : [
              details.city,
              details.state,
              details.country,
            ].where((s) => s.isNotEmpty).join(', ');
      _addressController.text = fullAddr;
    } on Exception catch (e) {
      debugPrint('Error during reverse geocoding: $e');
    } finally {
      _isReverseGeocoding = false;
    }
    _syncData();
    if (mounted) setState(() {});
  }

  void _onMinimapTap(LatLng latLng) {
    _currentMapCenter = latLng;
    _skipNextIdleGeocode = true;
    _reverseGeocodeDebounce?.cancel();
    if (_mapController != null) {
      unawaited(
        _mapController!.animateTo(
          latLng,
          zoom: _currentZoom,
        ),
      );
    }
    unawaited(_reverseGeocodePosition(latLng));
  }

  Future<void> _openFullScreenMap() async {
    final currentLat =
        double.tryParse(_latitudeController.text.trim()) ??
        double.tryParse(_locationData.latitude);
    final currentLng =
        double.tryParse(_longitudeController.text.trim()) ??
        double.tryParse(_locationData.longitude);
    final dynamic result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (_) => ChooseLocationMap(
          from: widget.from,
          countryId: _effectiveCountryId,
          countryName: _locationData.country.isNotEmpty
              ? _locationData.country
              : _countryController.text.trim(),
          initialLat: currentLat,
          initialLng: currentLng,
        ),
      ),
    );
    _handleLocationResult(result);
  }

  void _handleLocationResult(dynamic result) {
    if (result != null && result is Map) {
      setState(() {
        if (result['city'] != null) {
          _cityController.text = result['city'].toString();
        }
        if (result['state'] != null) {
          _stateController.text = result['state'].toString();
        }
        if (result['country'] != null) {
          _countryController.text = result['country'].toString();
        }
        if (result['address'] != null) {
          _addressController.text = result['address'].toString();
        }
        if (result['place'] != null) {
          final dynamic p = result['place'];
          if (p.locality != null && p.locality.toString().isNotEmpty) {
            _cityController.text = p.locality.toString();
          }
          if (p.administrativeArea != null &&
              p.administrativeArea.toString().isNotEmpty) {
            _stateController.text = p.administrativeArea.toString();
          }
          if (p.country != null && p.country.toString().isNotEmpty) {
            _countryController.text = p.country.toString();
          }
          if (p.street != null && p.street.toString().isNotEmpty) {
            _addressController.text = p.street.toString();
          }
        }
        if (result['latlng'] != null) {
          final dynamic latlng = result['latlng'];
          final lat = (latlng.latitude as num).toDouble();
          final lng = (latlng.longitude as num).toDouble();
          _latitudeController.text = lat.toString();
          _longitudeController.text = lng.toString();
          final pos = LatLng(lat, lng);
          _currentMapCenter = pos;
          _lastGeocodedPosition = pos;
          _skipNextIdleGeocode = true;
          if (_mapController != null) {
            unawaited(_mapController!.animateTo(pos, zoom: _currentZoom));
          }
        }
      });
      _syncData();
    }
  }

  void _onSuggestionSelected(PlaceDetails details, PlaceModel place) {
    final selectedCountry = _selectedCountryName;

    if (details.isSnapped) {
      _handleOutOfCountry(
        selectedCountry,
        details.snappedCountryName,
        details: details,
      );
      return;
    }

    setState(() {
      _cityController.text = details.city.isNotEmpty
          ? details.city
          : place.city;
      _stateController.text = details.state.isNotEmpty
          ? details.state
          : place.state;
      _countryController.text = details.country.isNotEmpty
          ? details.country
          : place.country;
      _addressController.text = details.address.isNotEmpty
          ? details.address
          : (place.description.isNotEmpty
                ? place.description
                : [
                    place.city,
                    place.state,
                    place.country,
                  ].where((s) => s.isNotEmpty).join(', '));

      var lat = details.lat;
      var lng = details.lng;
      if (lat == null || lng == null) {
        lat = double.tryParse(place.latitude);
        lng = double.tryParse(place.longitude);
      }

      if (lat != null && lng != null) {
        _latitudeController.text = lat.toString();
        _longitudeController.text = lng.toString();
        final pos = LatLng(lat, lng);
        _currentMapCenter = pos;
        _skipNextIdleGeocode = true;
        _lastGeocodedPosition = pos;
        if (_mapController != null) {
          unawaited(_mapController!.animateTo(pos, zoom: _currentZoom));
        }
      }
    });

    _syncData();
  }

  Future<void> _getCurrentLocation() async {
    if (!_hasSelectedCountry) {
      await _openCountrySelector();
      if (!_hasSelectedCountry) {
        return;
      }
    }
    setState(() => _isGettingLocation = true);
    final selectedCountry = _selectedCountryName;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            HelperUtils.showSnackBarMessage(
              context,
              'locationPermissionDenied'.translate(context),
              type: MessageType.error,
            );
          }
          return;
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          HelperUtils.showSnackBarMessage(
            context,
            'locationPermissionDenied'.translate(context),
            type: MessageType.error,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latStr = position.latitude.toString();
      final lngStr = position.longitude.toString();

      PlaceDetails? details;

      try {
        details = await MapServiceFactory.createPlaceSearchService()
            .getPlaceDetails(
              latitude: latStr,
              longitude: lngStr,
              countryId: _effectiveCountryId,
            );
      } on Exception catch (e) {
        debugPrint('Error getting place details for current location: $e');
      }

      if (details != null && details.isSnapped) {
        if (mounted) {
          await LocationOutOfCountryDialog.show(context);
          final countryCoords = (details.lat != null && details.lng != null)
              ? LatLng(details.lat!, details.lng!)
              : _getCountryCoordinates(selectedCountry);
          if (countryCoords != null) {
            _skipNextIdleGeocode = true;
            _latitudeController.text = countryCoords.latitude.toString();
            _longitudeController.text = countryCoords.longitude.toString();
            _currentMapCenter = countryCoords;
            _cityController.text = details.city;
            _stateController.text = details.state;
            if (details.country.isNotEmpty) {
              _countryController.text = details.country;
            }
            _addressController.text = details.address;
            _syncData();
            if (mounted) setState(() {});
            if (_mapController != null) {
              unawaited(
                _mapController!.animateTo(countryCoords, zoom: _currentZoom),
              );
            }
          }
        }
        return;
      }

      _latitudeController.text = latStr;
      _longitudeController.text = lngStr;
      final currentDetails = details;
      if (currentDetails != null) {
        _cityController.text = currentDetails.city;
        _stateController.text = currentDetails.state;
        if (currentDetails.country.isNotEmpty) {
          _countryController.text = currentDetails.country;
        }
        final fullAddr = currentDetails.address.isNotEmpty
            ? currentDetails.address
            : [
                currentDetails.city,
                currentDetails.state,
                currentDetails.country,
              ].where((s) => s.isNotEmpty).join(', ');
        _addressController.text = fullAddr;
      }

      final pos = LatLng(position.latitude, position.longitude);
      _skipNextIdleGeocode = true;
      _lastGeocodedPosition = pos;
      _currentMapCenter = pos;
      if (_mapController != null) {
        unawaited(_mapController!.animateTo(pos, zoom: _currentZoom));
      }

      _syncData();
      if (mounted) {
        setState(() {});
      }
    } on Exception catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          'Failed to get current location',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Widget _buildMapFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: context.color.borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: context.color.textColorDark,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _isMapMoving.dispose();
    _syncData();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _clientAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = context.color.borderColor;

    final fallbackCoords = _getCountryCoordinates(
      _countryController.text.isNotEmpty
          ? _countryController.text
          : _selectedCountryName,
    );
    final lat =
        _currentMapCenter?.latitude ??
        double.tryParse(_latitudeController.text) ??
        fallbackCoords?.latitude ??
        double.tryParse(AppSettings.latitude) ??
        24.5854;
    final lng =
        _currentMapCenter?.longitude ??
        double.tryParse(_longitudeController.text) ??
        fallbackCoords?.longitude ??
        double.tryParse(AppSettings.longitude) ??
        73.7125;

    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'location'.translate(context),
        onTapBackButton: () {
          _syncData();
          widget.onBack();
        },
        preventDefaultPop: true,
        actions: [
          Center(
            child: CustomText(
              widget.stepIndicator,
              fontSize: context.font.md,
              fontWeight: .w600,
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
      bottomNavigationBar: StepBottomBar(
        nextButtonText: 'Next',
        onNext: () {
          _syncData();
          if (!(_formKey.currentState?.validate() ?? false)) {
            return;
          }
          if (_cityController.text.trim().isEmpty ||
              _latitudeController.text.trim().isEmpty ||
              _longitudeController.text.trim().isEmpty) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseSelectLocation'.translate(context),
              type: MessageType.error,
            );
            return;
          }
          widget.onNext();
        },
        onSaveDraft: widget.onSaveDraft != null
            ? () {
                _syncData();
                widget.onSaveDraft!();
              }
            : null,
        isSavingDraft: widget.isSavingDraft,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: Constant.scrollPhysics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 1. MAP PREVIEW WITH SVG LOCATION PIN
                  // ==========================================
                  if (!_hasSelectedCountry)
                    Container(
                      height: 222.rh(context),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 4,
                                sigmaY: 4,
                              ),
                              child: Image.asset(
                                'assets/map.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.15),
                            ),
                            Center(
                              child: UiUtils.buildButton(
                                context,
                                buttonTitle: 'selectCountry'.translate(context),
                                width: 170.rw(context),
                                height: 44.rh(context),
                                radius: 8.rw(context),
                                onPressed: _openCountrySelector,
                              ),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                child: GestureDetector(
                                  onTap: _openCountrySelector,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 250.rh(context),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            AppMapWidget(
                              config: AppMapConfig(
                                initialLatLng: LatLng(lat, lng),
                                initialZoom: _currentZoom,
                                gestureRecognizers:
                                    <Factory<OneSequenceGestureRecognizer>>{
                                      const Factory<
                                        OneSequenceGestureRecognizer
                                      >(
                                        EagerGestureRecognizer.new,
                                      ),
                                    },
                                onReady: (controller) {
                                  _mapController = controller;
                                  if (_currentMapCenter != null) {
                                    unawaited(
                                      controller.animateTo(
                                        _currentMapCenter!,
                                        zoom: _currentZoom,
                                      ),
                                    );
                                  }
                                },
                                onCameraMove: (position, zoom) {
                                  _currentMapCenter = position;
                                  _currentZoom = zoom;
                                  if (!_isMapMoving.value) {
                                    _isMapMoving.value = true;
                                  }
                                },
                                onCameraIdle: () {
                                  if (_isMapMoving.value) {
                                    _isMapMoving.value = false;
                                  }
                                  if (_skipNextIdleGeocode) {
                                    _skipNextIdleGeocode = false;
                                    return;
                                  }
                                  if (_currentMapCenter != null) {
                                    if (_lastGeocodedPosition != null &&
                                        _isSameLocation(
                                          _currentMapCenter!,
                                          _lastGeocodedPosition!,
                                        )) {
                                      return;
                                    }
                                    _reverseGeocodeDebounce?.cancel();
                                    _reverseGeocodeDebounce = Timer(
                                      const Duration(milliseconds: 400),
                                      () {
                                        unawaited(
                                          _reverseGeocodePosition(
                                            _currentMapCenter!,
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                                onTap: _onMinimapTap,
                              ),
                            ),
                            // Center Location Pin with lift & drop animation while moving/swiping
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _isMapMoving,
                                      builder: (context, isMoving, _) {
                                        return Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              width: isMoving
                                                  ? 30.rw(context)
                                                  : 44.rw(context),
                                              height: isMoving
                                                  ? 10.rh(context)
                                                  : 14.rh(context),
                                              decoration: BoxDecoration(
                                                color: context
                                                    .color
                                                    .tertiaryColor
                                                    .withValues(
                                                      alpha: isMoving
                                                          ? 0.2
                                                          : 0.35,
                                                    ),
                                                borderRadius: BorderRadius.all(
                                                  Radius.elliptical(
                                                    isMoving ? 30 : 44,
                                                    isMoving ? 10 : 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            AnimatedPadding(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              curve: Curves.easeOut,
                                              padding: EdgeInsets.only(
                                                bottom: isMoving ? 12 : 2,
                                              ),
                                              child: LocationPin(
                                                width: 34.rw(context),
                                                height: 50.rh(context),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Fullscreen Expand Floating Button
                            Positioned(
                              top: 12.rh(context),
                              right: 12.rw(context),
                              child: _buildMapFloatingButton(
                                icon: Icons.fullscreen,
                                tooltip: 'fullScreen'.translate(context),
                                onTap: _openFullScreenMap,
                              ),
                            ),
                            // Zoom In and Zoom Out Floating Buttons
                            Positioned(
                              bottom: 12.rh(context),
                              right: 12.rw(context),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildMapFloatingButton(
                                    icon: Icons.add,
                                    tooltip: 'Zoom In',
                                    onTap: () {
                                      _currentZoom = (_currentZoom + 1).clamp(
                                        2.0,
                                        20.0,
                                      );
                                      if (_mapController != null) {
                                        unawaited(
                                          _mapController!.animateTo(
                                            _currentMapCenter ??
                                                LatLng(lat, lng),
                                            zoom: _currentZoom,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  SizedBox(height: 8.rh(context)),
                                  _buildMapFloatingButton(
                                    icon: Icons.remove,
                                    tooltip: 'Zoom Out',
                                    onTap: () {
                                      _currentZoom = (_currentZoom - 1).clamp(
                                        2.0,
                                        20.0,
                                      );
                                      if (_mapController != null) {
                                        unawaited(
                                          _mapController!.animateTo(
                                            _currentMapCenter ??
                                                LatLng(lat, lng),
                                            zoom: _currentZoom,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 25.rh(context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              widget.addressFieldLabel.translate(context),
                              fontSize: context.font.md,
                              fontWeight: FontWeight.w600,
                            ),
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              child: GestureDetector(
                                onTap: _getCurrentLocation,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isGettingLocation)
                                        SizedBox(
                                          width: 14.rw(context),
                                          height: 14.rh(context),
                                          child:
                                              const CupertinoActivityIndicator(
                                                radius: 7,
                                              ),
                                        )
                                      else
                                        CustomImage(
                                          imageUrl: AppIcons.locationRound,
                                          width: 16.rw(context),
                                          height: 16.rh(context),
                                          color: context.color.tertiaryColor,
                                        ),
                                      SizedBox(width: 4.rw(context)),
                                      CustomText(
                                        'setLocation'.translate(context),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: context.color.tertiaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.rh(context)),
                        // 3. INPUT FIELDS
                        LocationAutocompleteField(
                          controller: _cityController,
                          hintText: 'city'.translate(context),
                          borderColor: borderColor,
                          fillColor: context.color.secondaryColor,
                          countryId: _effectiveCountryId,
                          countryName: _countryController.text.trim().isNotEmpty
                              ? _countryController.text.trim()
                              : _effectiveCountryName,
                          onChanged: (val) {
                            _locationData.city = val;
                            _syncData();
                          },
                          onLocationSelected: _onSuggestionSelected,
                        ),
                        SizedBox(height: 12.rh(context)),
                        // State
                        LocationAutocompleteField(
                          controller: _stateController,
                          hintText: 'state'.translate(context),
                          borderColor: borderColor,
                          fillColor: context.color.secondaryColor,
                          countryId: _effectiveCountryId,
                          countryName: _countryController.text.trim().isNotEmpty
                              ? _countryController.text.trim()
                              : _effectiveCountryName,
                          onChanged: (val) {
                            _locationData.state = val;
                            _syncData();
                          },
                          onLocationSelected: _onSuggestionSelected,
                        ),
                        SizedBox(height: 12.rh(context)),
                        // Country
                        LocationAutocompleteField(
                          controller: _countryController,
                          hintText: 'country'.translate(context),
                          borderColor: borderColor,
                          fillColor: context.color.secondaryColor,
                          onChanged: (val) {
                            final newVal = val.trim();
                            final prevCountry = _locationData.country.trim();
                            _locationData.country = newVal;
                            if (newVal.isNotEmpty &&
                                newVal.toLowerCase() !=
                                    prevCountry.toLowerCase()) {
                              _cityController.clear();
                              _stateController.clear();
                              _addressController.clear();
                              _clientAddressController.clear();
                              _latitudeController.clear();
                              _longitudeController.clear();
                              _syncData();
                              unawaited(_resolveCountryLocation(newVal));
                            }
                          },
                          onLocationSelected: _onSuggestionSelected,
                        ),
                        SizedBox(height: 12.rh(context)),

                        // Address
                        CustomTextFormField(
                          controller: _addressController,
                          action: TextInputAction.newline,
                          minLine: 2,
                          maxLine: 4,
                          hintText: widget.addressFieldLabel.translate(context),
                          borderRadius: 6,
                          borderColor: borderColor,
                          fillColor: context.color.secondaryColor,
                          onChange: (val) {
                            _locationData.address = val?.toString() ?? '';
                            _syncData();
                          },
                        ),
                        SizedBox(height: 12.rh(context)),
                        // Client Address
                        CustomTextFormField(
                          controller: _clientAddressController,
                          action: TextInputAction.newline,
                          minLine: 2,
                          maxLine: 4,
                          hintText: widget.clientAddressFieldLabel.translate(
                            context,
                          ),
                          borderRadius: 6,
                          borderColor: borderColor,
                          fillColor: context.color.secondaryColor,
                          onChange: (val) {
                            _locationData.clientAddress = val?.toString() ?? '';
                            _syncData();
                          },
                        ),
                        SizedBox(height: 20.rh(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
