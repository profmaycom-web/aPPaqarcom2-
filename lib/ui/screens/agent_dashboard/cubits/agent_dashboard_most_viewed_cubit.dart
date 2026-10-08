import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_most_viewed_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/repositories/agent_dashboard_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AgentDashboardMostViewedState {}

class AgentDashboardMostViewedInitial extends AgentDashboardMostViewedState {}

class AgentDashboardMostViewedLoading extends AgentDashboardMostViewedState {}

class AgentDashboardMostViewedSuccess extends AgentDashboardMostViewedState {
  AgentDashboardMostViewedSuccess(this.listings);
  final List<AgentDashboardMostViewedModel> listings;
}

class AgentDashboardMostViewedFailure extends AgentDashboardMostViewedState {
  AgentDashboardMostViewedFailure(this.errorMessage);
  final String errorMessage;
}

class AgentDashboardMostViewedCubit
    extends Cubit<AgentDashboardMostViewedState> {
  AgentDashboardMostViewedCubit() : super(AgentDashboardMostViewedInitial());

  final AgentDashboardRepository _repository = AgentDashboardRepository();

  Future<void> fetch({required String type, required String range}) async {
    try {
      emit(AgentDashboardMostViewedLoading());
      final listings = await _repository.fetchMostViewedListings(
        type: type,
        range: range,
      );
      emit(AgentDashboardMostViewedSuccess(listings));
    } on ApiException catch (e) {
      emit(AgentDashboardMostViewedFailure(e.toString()));
    } on Exception catch (e) {
      emit(AgentDashboardMostViewedFailure(e.toString()));
    }
  }
}
