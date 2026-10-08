import 'package:ebroker/utils/map/map_service_factory.dart';
import 'package:ebroker/utils/map/place_details.dart';
import 'package:ebroker/utils/map/place_search_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PlaceDetailsState {}

class PlaceDetailsInitial extends PlaceDetailsState {}

class PlaceDetailsInProgress extends PlaceDetailsState {
  PlaceDetailsInProgress({this.tag});
  final String? tag;
}

class PlaceDetailsSuccess extends PlaceDetailsState {
  PlaceDetailsSuccess(this.details, {this.tag});
  final PlaceDetails details;
  final String? tag;
}

class PlaceDetailsFail extends PlaceDetailsState {
  PlaceDetailsFail(this.error, {this.tag});
  final Object error;
  final String? tag;
}

class PlaceDetailsCubit extends Cubit<PlaceDetailsState> {
  PlaceDetailsCubit() : super(PlaceDetailsInitial());

  final PlaceSearchService _searchService =
      MapServiceFactory.createPlaceSearchService();

  Future<void> fetch({
    required String latitude,
    required String longitude,
    String? placeId,
    String? tag,
    String? countryId,
  }) async {
    try {
      emit(PlaceDetailsInProgress(tag: tag));
      final details = await _searchService.getPlaceDetails(
        latitude: latitude,
        longitude: longitude,
        placeId: placeId,
        countryId: countryId,
      );
      emit(PlaceDetailsSuccess(details, tag: tag));
    } on Exception catch (e) {
      emit(PlaceDetailsFail(e, tag: tag));
    }
  }

  void reset() => emit(PlaceDetailsInitial());
}
