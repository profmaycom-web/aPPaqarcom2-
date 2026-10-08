import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/utils/api.dart';

class CountryRepository {
  Future<List<CountryModel>> fetchCountries() async {
    try {
      final response = await Api.get(
        url: Api.getCountries,
      );

      dynamic data = response['data'];
      if (data is Map && data['data'] is List) {
        data = data['data'];
      }
      if (data is List) {
        return data
            .map(
              (item) =>
                  CountryModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }
}
