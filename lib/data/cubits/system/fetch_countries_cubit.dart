import 'package:collection/collection.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/data/repositories/country_repository.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

abstract class FetchCountriesState {}

class FetchCountriesInitial extends FetchCountriesState {}

class FetchCountriesInProgress extends FetchCountriesState {}

class FetchCountriesSuccess extends FetchCountriesState {
  FetchCountriesSuccess(this.countries);
  final List<CountryModel> countries;
}

class FetchCountriesFailure extends FetchCountriesState {
  FetchCountriesFailure(this.errorMessage);
  final String errorMessage;
}

class FetchCountriesCubit extends Cubit<FetchCountriesState> {
  FetchCountriesCubit() : super(FetchCountriesInitial());

  final CountryRepository _repository = CountryRepository();
  List<CountryModel> _cachedCountries = [];

  List<CountryModel> get countries => _cachedCountries;

  CountryModel? getCountry({String? name, String? id, String? code}) {
    if (_cachedCountries.isEmpty) return null;
    if (id != null && id.isNotEmpty) {
      final match = _cachedCountries.firstWhereOrNull(
        (c) => c.id.toString() == id,
      );
      if (match != null) return match;
    }
    if (code != null && code.trim().isNotEmpty) {
      final cd = code.trim().toLowerCase();
      final match = _cachedCountries.firstWhereOrNull(
        (c) => (c.code ?? '').toLowerCase() == cd,
      );
      if (match != null) return match;
    }
    if (name != null && name.trim().isNotEmpty) {
      final n = name.trim().toLowerCase();
      final match = _cachedCountries.firstWhereOrNull((c) {
        final cName = (c.name ?? '').toLowerCase();
        final cCode = (c.code ?? '').toLowerCase();
        return cName == n ||
            cCode == n ||
            cName.contains(n) ||
            n.contains(cName);
      });
      if (match != null) return match;
    }
    return null;
  }

  bool isMatchingCountry(String locationCountry, String selectedCountry) {
    if (selectedCountry.trim().isEmpty || locationCountry.trim().isEmpty) {
      return true;
    }
    final c1 = locationCountry.trim().toLowerCase().replaceAll(
      RegExp('[^a-z0-9]'),
      '',
    );
    final c2 = selectedCountry.trim().toLowerCase().replaceAll(
      RegExp('[^a-z0-9]'),
      '',
    );
    if (c1 == c2 || c1.contains(c2) || c2.contains(c1)) {
      return true;
    }

    final match1 = getCountry(name: locationCountry, code: locationCountry);
    final match2 = getCountry(name: selectedCountry, code: selectedCountry);

    if (match1 != null && match2 != null && match1.id == match2.id) {
      return true;
    }

    for (final c in _cachedCountries) {
      final cName = (c.name ?? '').trim().toLowerCase().replaceAll(
        RegExp('[^a-z0-9]'),
        '',
      );
      final cCode = (c.code ?? '').trim().toLowerCase().replaceAll(
        RegExp('[^a-z0-9]'),
        '',
      );

      final matches1 =
          (cName.isNotEmpty &&
              (c1 == cName || c1.contains(cName) || cName.contains(c1))) ||
          (cCode.isNotEmpty && c1 == cCode);
      final matches2 =
          (cName.isNotEmpty &&
              (c2 == cName || c2.contains(cName) || cName.contains(c2))) ||
          (cCode.isNotEmpty && c2 == cCode);

      if (matches1 && matches2) {
        return true;
      }
    }
    return false;
  }

  LatLng? getCountryCoordinates({String? name, String? id, String? code}) {
    final country = getCountry(name: name, id: id, code: code);
    if (country != null &&
        country.latitude != null &&
        country.longitude != null) {
      return LatLng(country.latitude!, country.longitude!);
    }
    return null;
  }

  Future<LatLng?> getCountryCoordinatesAsync({
    String? name,
    String? id,
    String? code,
  }) async {
    if (_cachedCountries.isEmpty) {
      await fetchCountries();
    }
    return getCountryCoordinates(name: name, id: id, code: code);
  }

  Future<void> fetchCountries({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCountries.isNotEmpty) {
      emit(FetchCountriesSuccess(_cachedCountries));
      return;
    }

    emit(FetchCountriesInProgress());
    try {
      final result = await _repository.fetchCountries();
      _cachedCountries = result;
      await _backfillSelectedCountryCurrency();
      emit(FetchCountriesSuccess(result));
    } on Exception catch (e) {
      emit(FetchCountriesFailure(e.toString()));
    }
  }

  /// Countries picked before the app stored a currency per country have none
  /// saved, so fill it in from the freshly fetched list.
  Future<void> _backfillSelectedCountryCurrency() async {
    final selectedId = HiveUtils.getSelectedCountryId() ?? '';
    if (selectedId.isEmpty) return;
    if ((HiveUtils.getSelectedCountryCurrencySymbol() ?? '').isNotEmpty) return;

    final country = getCountry(id: selectedId);
    if (country == null) return;
    if ((country.currencySymbol ?? '').isEmpty &&
        (country.currencyCode ?? '').isEmpty) {
      return;
    }

    await HiveUtils.setSelectedCountry(
      name: HiveUtils.getSelectedCountryName() ?? country.name ?? '',
      id: selectedId,
      currencyCode: country.currencyCode ?? '',
      currencySymbol: country.currencySymbol ?? '',
    );
  }
}
