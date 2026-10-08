import 'package:ebroker/data/model/agent/agent_verification_form_fields_model.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class FetchUserVerificationFormFieldsState {}

class FetchUserVerificationFormFieldsInitial
    extends FetchUserVerificationFormFieldsState {}

class FetchUserVerificationFormFieldsLoading
    extends FetchUserVerificationFormFieldsState {}

class FetchUserVerificationFormFieldsSuccess
    extends FetchUserVerificationFormFieldsState {
  FetchUserVerificationFormFieldsSuccess({required this.fields});
  final List<AgentVerificationFormFieldsModel> fields;
}

class FetchUserVerificationFormFieldsFailure
    extends FetchUserVerificationFormFieldsState {
  FetchUserVerificationFormFieldsFailure(this.errorMessage);
  final String errorMessage;
}

class FetchUserVerificationFormFieldsCubit
    extends Cubit<FetchUserVerificationFormFieldsState> {
  FetchUserVerificationFormFieldsCubit()
    : super(FetchUserVerificationFormFieldsInitial());

  final AgentsRepository _agentsRepository = AgentsRepository();

  Future<void> fetch() async {
    try {
      emit(FetchUserVerificationFormFieldsLoading());
      final fields = await _agentsRepository.fetchUserVerificationFormFields();
      emit(FetchUserVerificationFormFieldsSuccess(fields: fields));
    } on Exception catch (e) {
      emit(FetchUserVerificationFormFieldsFailure(e.toString()));
    }
  }
}
