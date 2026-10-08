import 'package:ebroker/utils/map/map_service_factory.dart';
import 'package:ebroker/utils/map/place_model.dart';
import 'package:ebroker/utils/map/place_search_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PlaceAutocompleteState {}

class PlaceAutocompleteInitial extends PlaceAutocompleteState {}

class PlaceAutocompleteInProgress extends PlaceAutocompleteState {}

class PlaceAutocompleteSuccess extends PlaceAutocompleteState {
  PlaceAutocompleteSuccess(this.autocompleteResult);
  final List<PlaceModel> autocompleteResult;
}

class PlaceAutocompleteFail extends PlaceAutocompleteState {
  PlaceAutocompleteFail(this.error);
  final dynamic error;
}

class PlaceAutocompleteCubit extends Cubit<PlaceAutocompleteState> {
  PlaceAutocompleteCubit() : super(PlaceAutocompleteInitial());
  final PlaceSearchService _searchService =
      MapServiceFactory.createPlaceSearchService();

  Future<void> getLocationFromText({
    required String text,
  }) async {
    try {
      emit(PlaceAutocompleteInProgress());
      final autocompleteResponse = await _searchService.searchCities(text);
      emit(PlaceAutocompleteSuccess(autocompleteResponse));
    } on Exception catch (e) {
      emit(PlaceAutocompleteFail(e));
      rethrow;
    }
  }

  void clearCubit() {
    emit(PlaceAutocompleteSuccess([]));
    Future.delayed(const Duration(microseconds: 300), () {
      emit(PlaceAutocompleteInitial());
    });
  }
}

// Temporary aliases for compatibility during refactoring
typedef GooglePlaceAutocompleteState = PlaceAutocompleteState;
typedef GooglePlaceAutocompleteInitial = PlaceAutocompleteInitial;
typedef GooglePlaceAutocompleteInProgress = PlaceAutocompleteInProgress;
typedef GooglePlaceAutocompleteSuccess = PlaceAutocompleteSuccess;
typedef GooglePlaceAutocompleteFail = PlaceAutocompleteFail;
typedef GooglePlaceAutocompleteCubit = PlaceAutocompleteCubit;
