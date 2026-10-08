import 'package:ebroker/data/cubits/system/user_details.dart';
import 'package:ebroker/data/helper/custom_exception.dart';
import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GetUserDataState {}

class GetUserDataInitial extends GetUserDataState {}

class GetUserDataInProgress extends GetUserDataState {}

class GetUserDataSuccess extends GetUserDataState {
  GetUserDataSuccess();
}

class GetUserDataFailure extends GetUserDataState {
  GetUserDataFailure(this.errorMessage);
  final String errorMessage;
}

class GetUserDataCubit extends Cubit<GetUserDataState> {
  GetUserDataCubit(this._userDetailsCubit) : super(GetUserDataInitial());

  final UserDetailsCubit _userDetailsCubit;

  Future<void> getUserData() async {
    emit(GetUserDataInProgress());
    try {
      await getUserProfileData();
      _userDetailsCubit.fill(HiveUtils.getUserDetails());
      emit(GetUserDataSuccess());
    } on Exception catch (e) {
      emit(GetUserDataFailure(e.toString()));
    }
  }
}

Future<void> getUserProfileData() async {
  try {
    final response = await Api.get(
      url: Api.apiGetUserData,
      passCountryId: false,
    );

    if (response[Api.error] as bool) {
      throw CustomException(response[Api.message]);
    }
    await HiveUtils.setUserData(response['data'] as Map<String, dynamic>);
  } on Exception catch (e) {
    throw CustomException(e.toString());
  }
}
