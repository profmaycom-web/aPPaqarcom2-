import 'package:ebroker/config/app_config.dart';
import 'package:ebroker/data/model/city_model.dart';
import 'package:ebroker/data/model/data_output.dart';
import 'package:ebroker/utils/api.dart';

class CitiesRepository {
  Future<DataOutput<City>> fetchAllCities({
    required int offset,
  }) async {
    try {
      final response = await Api.get(
        url: Api.getCitiesData,
        queryParameters: {
          Api.limit: AppConfig.apiDataLoadLimit,
          Api.offset: offset,
        },
      );
      final modelList = (response['data'] as List)
          .cast<Map<String, dynamic>>()
          .map<City>(City.fromMap)
          .toList();
      return DataOutput(
        total: response['total'] as int? ?? 0,
        modelList: modelList,
      );
    } on ApiException catch (_) {
      rethrow;
    }
  }
}
