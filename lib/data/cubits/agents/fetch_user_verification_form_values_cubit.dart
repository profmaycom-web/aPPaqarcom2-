import 'package:ebroker/data/model/agent/agent_verification_form_values_model.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class FetchUserVerificationFormValuesState {}

class FetchUserVerificationFormValuesInitial
    extends FetchUserVerificationFormValuesState {}

class FetchUserVerificationFormValuesLoading
    extends FetchUserVerificationFormValuesState {}

class FetchUserVerificationFormValuesSuccess
    extends FetchUserVerificationFormValuesState {
  FetchUserVerificationFormValuesSuccess({required this.values});
  final List<AgentVerificationFormValueModel> values;
}

class FetchUserVerificationFormValuesFailure
    extends FetchUserVerificationFormValuesState {
  FetchUserVerificationFormValuesFailure(this.errorMessage);
  final String errorMessage;
}

class FetchUserVerificationFormValuesCubit
    extends Cubit<FetchUserVerificationFormValuesState> {
  FetchUserVerificationFormValuesCubit()
    : super(FetchUserVerificationFormValuesInitial());

  final AgentsRepository _agentsRepository = AgentsRepository();

  Future<void> fetch() async {
    try {
      emit(FetchUserVerificationFormValuesLoading());
      final values = await _agentsRepository.getUserVerificationFormValues();
      emit(FetchUserVerificationFormValuesSuccess(values: values));
    } on Exception catch (e) {
      emit(FetchUserVerificationFormValuesFailure(e.toString()));
    }
  }
}
