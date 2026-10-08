import 'package:ebroker/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:ebroker/data/model/company.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CompanyState {}

class CompanyInitial extends CompanyState {}

class CompanyFetchProgress extends CompanyState {}

class CompanyFetchSuccess extends CompanyState {
  CompanyFetchSuccess(this.companyData);
  Company companyData;
}

class CompanyFetchFailure extends CompanyState {
  CompanyFetchFailure(this.error);
  final dynamic error;
}

class CompanyCubit extends Cubit<CompanyState> {
  CompanyCubit() : super(CompanyInitial());

  /// Retrieves company data from the [FetchSystemSettingsCubit] cache.
  Future<void> fetchCompany({
    required FetchSystemSettingsCubit systemSettingsCubit,
  }) async {
    emit(CompanyFetchProgress());

    try {
      final cached = systemSettingsCubit.companyData;
      if (cached != null) {
        emit(CompanyFetchSuccess(cached));
      } else {
        emit(
          CompanyFetchFailure(
            'Company data not yet loaded. Please wait for settings to finish.',
          ),
        );
      }
    } on Exception catch (e) {
      emit(CompanyFetchFailure(e));
    }
  }
}
