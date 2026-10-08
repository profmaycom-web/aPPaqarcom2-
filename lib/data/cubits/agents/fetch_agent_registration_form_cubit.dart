import 'package:ebroker/data/model/agent/agent_registration_form_section_model.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchAgentRegistrationFormState {}

class FetchAgentRegistrationFormInitial
    extends FetchAgentRegistrationFormState {}

class FetchAgentRegistrationFormLoading
    extends FetchAgentRegistrationFormState {}

class FetchAgentRegistrationFormSuccess
    extends FetchAgentRegistrationFormState {
  FetchAgentRegistrationFormSuccess({required this.sections});

  final List<AgentRegistrationFormSectionModel> sections;
}

class FetchAgentRegistrationFormFailure
    extends FetchAgentRegistrationFormState {
  FetchAgentRegistrationFormFailure(this.errorMessage);

  final String errorMessage;
}

class FetchAgentRegistrationFormCubit
    extends Cubit<FetchAgentRegistrationFormState> {
  FetchAgentRegistrationFormCubit()
    : super(FetchAgentRegistrationFormInitial());

  final AgentsRepository _agentsRepository = AgentsRepository();

  Future<void> fetchAgentRegistrationForm({
    required String formType,
  }) async {
    try {
      emit(FetchAgentRegistrationFormLoading());
      final sections = await _agentsRepository.getAgentRegistrationForm(
        formType: formType,
      );
      emit(FetchAgentRegistrationFormSuccess(sections: sections));
    } on Exception catch (e) {
      emit(FetchAgentRegistrationFormFailure(e.toString()));
    }
  }
}
