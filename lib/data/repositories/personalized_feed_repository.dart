import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/extensions/lib/map.dart';
import 'package:material_ui/material_ui.dart';

enum PersonalizedFeedAction { add, edit, get }

class PersonalizedFeedRepository {
  Future<void> addOrUpdate({
    required PersonalizedFeedAction action,
    required List<int> categoryIds,
    List<int>? outdoorFacilityList,
    RangeValues? priceRange,
    List<int>? selectedPropertyType,
    List<int>? countryIds,
  }) async {
    ////List to String
    final categoryStringArray = categoryIds.join(',');
    final outdoorFacilityStringArray = outdoorFacilityList?.join(',') ?? '';
    final priceRangeString = '${priceRange?.start},${priceRange?.end}';
    var propertyTypeString = '';
    if (selectedPropertyType!.length > 1) {
      propertyTypeString = '';
    } else {
      propertyTypeString = selectedPropertyType.join(',');
    }

    final parameters = <String, dynamic>{
      'category_ids': categoryStringArray,
      'outdoor_facilitiy_ids': outdoorFacilityStringArray,
      'price_range': priceRangeString,
      'property_type': propertyTypeString,
    }..removeEmptyKeys();

    // Always sent, an empty value is how "all countries" is stored.
    parameters['country_ids'] = (countryIds ?? []).join(',');

    final result = await Api.post(
      url: Api.personalisedFields,
      parameter: parameters,
    );

    try {
      personalizedInterestSettings = PersonalizedInterestSettings.fromMap(
        result['data'] as Map<String, dynamic>? ?? {},
      );
    } on Exception catch (_) {}
  }

  Future<void> clearPersonalizedSettings(BuildContext context) async {
    try {
      unawaited(Widgets.showLoader(context));
      postFrame((t) async {
        await Api.delete(url: Api.personalisedFields);
      });

      Widgets.hideLoder(context);
      Navigator.pop(context);
      HelperUtils.showSnackBarMessage(
        context,
        'successfullySaved',
        type: .success,
      );
      personalizedInterestSettings = PersonalizedInterestSettings.empty();
    } on Exception catch (_) {
      Widgets.hideLoder(context);
      HelperUtils.showSnackBarMessage(
        context,
        'defaultErrorMsg',
        type: .error,
      );
    }
  }

  Future<PersonalizedInterestSettings> getUserPersonalizedSettings() async {
    if (ActiveRoleManager.isAgent) {
      return PersonalizedInterestSettings.empty();
    }
    try {
      final userPersonalization = await Api.get(
        url: Api.personalisedFields,
      );
      if (userPersonalization['error'] == true) {
        throw ApiException(userPersonalization['message']?.toString() ?? '');
      }

      if (userPersonalization['data'] is List &&
          (userPersonalization['data'] as List).isEmpty) {
        return PersonalizedInterestSettings.empty();
      }

      return PersonalizedInterestSettings.fromMap(
        userPersonalization['data'] as Map<String, dynamic>? ?? {},
      );
    } on Exception catch (_) {
      return PersonalizedInterestSettings.empty();
    }
  }
}
