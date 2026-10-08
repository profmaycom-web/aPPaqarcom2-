import 'package:ebroker/data/model/agent/agent_filter_options_model.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchAgentFilterOptionsState {}

class FetchAgentFilterOptionsInitial extends FetchAgentFilterOptionsState {}

class FetchAgentFilterOptionsInProgress
    extends FetchAgentFilterOptionsState {}

class FetchAgentFilterOptionsSuccess extends FetchAgentFilterOptionsState {
  FetchAgentFilterOptionsSuccess({required this.options});
  final AgentFilterOptionsModel options;
}

class FetchAgentFilterOptionsFailure extends FetchAgentFilterOptionsState {
  FetchAgentFilterOptionsFailure(this.errorMessage);
  final String errorMessage;
}

class FetchAgentFilterOptionsCubit
    extends Cubit<FetchAgentFilterOptionsState> {
  FetchAgentFilterOptionsCubit() : super(FetchAgentFilterOptionsInitial());
  final AgentsRepository _agentsRepository = AgentsRepository();

  Future<void> fetchOptions() async {
    try {
      emit(FetchAgentFilterOptionsInProgress());
      final options = await _agentsRepository.fetchAgentFilterOptions();
      emit(FetchAgentFilterOptionsSuccess(options: options));
    } on ApiException catch (e) {
      emit(FetchAgentFilterOptionsFailure(e.errorMessage));
    }
  }
}
