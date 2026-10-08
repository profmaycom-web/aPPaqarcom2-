import 'dart:developer';

import 'package:ebroker/exports/main_export.dart';

class SystemRepository {
  Future<Map<dynamic, dynamic>> fetchSystemSettings({
    required bool isAnonymouse,
  }) async {
    try {
      final response = await Api.get(
        url: Api.apiGetAppSettings,
        useAuthToken: !isAnonymouse,
      );

      return response;
    } on Exception catch (e, st) {
      log(
        e.toString(),
        stackTrace: st,
        name: 'SYSTEM SETTINGS ERROR',
      );
      rethrow;
    }
  }
}
