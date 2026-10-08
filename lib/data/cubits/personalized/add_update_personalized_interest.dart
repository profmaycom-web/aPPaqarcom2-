import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

abstract class AddUpdatePersonalizedInterestState {}

class AddUpdatePersonalizedInterestInitial
    extends AddUpdatePersonalizedInterestState {}

class AddUpdatePersonalizedInterestInProgress
    extends AddUpdatePersonalizedInterestState {}

class AddUpdatePersonalizedInterestSuccess
    extends AddUpdatePersonalizedInterestState {}

class AddUpdatePersonalizedInterestFail
    extends AddUpdatePersonalizedInterestState {
  AddUpdatePersonalizedInterestFail(this.error);
  final dynamic error;
}

class AddUpdatePersonalizedInterest
    extends Cubit<AddUpdatePersonalizedInterestState> {
  AddUpdatePersonalizedInterest()
    : super(AddUpdatePersonalizedInterestInitial());
  PersonalizedFeedRepository personalizedFeedRepository =
      PersonalizedFeedRepository();
  Future<void> addOrUpdate({
    required PersonalizedFeedAction action,
    required List<int> categoryIds,
    List<int>? outdoorFacilityList,
    RangeValues? priceRange,
    List<int>? selectedPropertyType,
    List<int>? countryIds,
  }) async {
    try {
      emit(AddUpdatePersonalizedInterestInProgress());
      await personalizedFeedRepository.addOrUpdate(
        action: action,
        categoryIds: categoryIds,
        outdoorFacilityList: outdoorFacilityList,
        priceRange: priceRange,
        countryIds: countryIds,
        selectedPropertyType: selectedPropertyType,
      );
      emit(AddUpdatePersonalizedInterestSuccess());
    } on Exception catch (e) {
      emit(AddUpdatePersonalizedInterestFail(e));
    }
  }
}
