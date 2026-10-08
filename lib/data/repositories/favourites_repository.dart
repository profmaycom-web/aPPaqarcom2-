import 'package:ebroker/config/app_config.dart';
import 'package:ebroker/data/model/data_output.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/utils/active_role_manager.dart';
import 'package:ebroker/utils/api.dart';

class FavoriteRepository {
  Future<void> addToFavorite(int id, String type) async {
    final paramerters = <String, dynamic>{Api.propertyId: id, Api.type: type};

    await Api.post(
      url: Api.addFavourite,
      parameter: paramerters,
    );
  }

  Future<DataOutput<PropertyModel>> fechFavorites({
    required int offset,
  }) async {
    if (ActiveRoleManager.isAgent) {
      return DataOutput<PropertyModel>(total: 0, modelList: []);
    }
    final parameters = <String, dynamic>{
      Api.offset: offset,
      Api.limit: AppConfig.apiDataLoadLimit,
    };

    final response = await Api.get(
      url: Api.getFavoriteProperty,
      queryParameters: parameters,
    );

    final modelList = (response['data'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map<PropertyModel>((map) {
          final model = PropertyModel.fromMap(map);
          return model.copyWith(isFavourite: '1');
        })
        .toList();

    return DataOutput<PropertyModel>(
      total: response['total'] as int? ?? 0,
      modelList: modelList,
    );
  }
}
