import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_summary_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/repositories/agent_dashboard_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AgentDashboardSummaryState {}

class AgentDashboardSummaryInitial extends AgentDashboardSummaryState {}

class AgentDashboardSummaryLoading extends AgentDashboardSummaryState {}

class AgentDashboardSummarySuccess extends AgentDashboardSummaryState {
  AgentDashboardSummarySuccess(this.data);
  final AgentDashboardSummaryModel data;
}

class AgentDashboardSummaryFailure extends AgentDashboardSummaryState {
  AgentDashboardSummaryFailure(this.errorMessage);
  final String errorMessage;
}

class AgentDashboardSummaryCubit extends Cubit<AgentDashboardSummaryState> {
  AgentDashboardSummaryCubit() : super(AgentDashboardSummaryInitial());

  final AgentDashboardRepository _repository = AgentDashboardRepository();

  Future<void> fetch() async {
    try {
      emit(AgentDashboardSummaryLoading());
      final data = await _repository.fetchSummary();
      emit(AgentDashboardSummarySuccess(data));
    } on ApiException catch (e) {
      emit(AgentDashboardSummaryFailure(e.toString()));
    } on Exception catch (e) {
      emit(AgentDashboardSummaryFailure(e.toString()));
    }
  }
}
