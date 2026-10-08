import 'package:ebroker/config/app_config.dart';
import 'package:ebroker/data/helper/custom_exception.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ProfileSettingState {}

class ProfileSettingInitial extends ProfileSettingState {}

class ProfileSettingFetchProgress extends ProfileSettingState {}

class ProfileSettingFetchSuccess extends ProfileSettingState {
  ProfileSettingFetchSuccess({required this.data});

  String data;
}

class ProfileSettingFetchFailure extends ProfileSettingState {
  ProfileSettingFetchFailure(this.errmsg);
  final dynamic errmsg;
}

class ProfileSettingCubit extends Cubit<ProfileSettingState> {
  ProfileSettingCubit() : super(ProfileSettingInitial());

  void emitPreloaded(String content) {
    emit(ProfileSettingFetchSuccess(data: content));
  }

  Future<void> fetchProfileSetting(
    String title, {
    bool? forceRefresh,
  }) async {
    if (forceRefresh != true) {
      if (state is ProfileSettingFetchSuccess) {
        await Future<dynamic>.delayed(
          const Duration(seconds: AppConfig.hiddenAPIProcessDelay),
        );
      } else {
        emit(ProfileSettingFetchProgress());
      }
    } else {
      emit(ProfileSettingFetchProgress());
    }

    if (forceRefresh ?? false) {
      await fetchProfileSettingFromDb(title)
          .then((value) {
            emit(ProfileSettingFetchSuccess(data: value ?? ''));
          })
          .catchError((dynamic e, stack) {
            emit(ProfileSettingFetchFailure(e));
          });
    } else {
      if (state is! ProfileSettingFetchSuccess) {
        await fetchProfileSettingFromDb(title)
            .then((value) {
              emit(ProfileSettingFetchSuccess(data: value ?? ''));
            })
            .catchError((dynamic e, stack) {
              emit(ProfileSettingFetchFailure(e));
            });
      } else {
        emit(
          ProfileSettingFetchSuccess(
            data: (state as ProfileSettingFetchSuccess).data,
          ),
        );
      }
    }
  }

  Future<String?> fetchProfileSettingFromDb(
    String title,
  ) async {
    try {
      String? profileSettingData;
      var apiUrl = '';
      if (title == Api.termsAndConditions) {
        apiUrl = Api.apiGetTermsAndConditions;
      } else if (title == Api.privacyPolicy) {
        apiUrl = Api.apiGetPrivacyPolicy;
      } else if (title == Api.aboutApp) {
        apiUrl = Api.apiGetAboutUs;
      }

      if (apiUrl.isEmpty) {
        return null;
      }

      final response = await Api.get(
        url: apiUrl,
      );

      if (response[Api.error] as bool) {
        throw CustomException(response[Api.message]);
      } else if (response['data'] == '') {
        throw ApiException('noDataFound');
      } else {
        final data = response['data'] as Map<String, dynamic>;
        profileSettingData = data['data'].toString();
      }

      return profileSettingData;
    } on Exception catch (_) {
      rethrow;
    }
  }
}
