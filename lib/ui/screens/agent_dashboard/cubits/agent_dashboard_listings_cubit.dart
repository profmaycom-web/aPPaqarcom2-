import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_listings_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/repositories/agent_dashboard_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AgentDashboardListingsState {}

class AgentDashboardListingsInitial extends AgentDashboardListingsState {}

class AgentDashboardListingsLoading extends AgentDashboardListingsState {}

class AgentDashboardListingsSuccess extends AgentDashboardListingsState {
  AgentDashboardListingsSuccess(this.data);
  final AgentDashboardListingsModel data;
}

class AgentDashboardListingsFailure extends AgentDashboardListingsState {
  AgentDashboardListingsFailure(this.errorMessage);
  final String errorMessage;
}

class AgentDashboardListingsCubit extends Cubit<AgentDashboardListingsState> {
  AgentDashboardListingsCubit() : super(AgentDashboardListingsInitial());

  final AgentDashboardRepository _repository = AgentDashboardRepository();

  Future<void> fetch({required String type, required String range}) async {
    try {
      emit(AgentDashboardListingsLoading());
      final data = await _repository.fetchListings(type: type, range: range);
      emit(AgentDashboardListingsSuccess(data));
    } on ApiException catch (e) {
      emit(AgentDashboardListingsFailure(e.toString()));
    } on Exception catch (e) {
      emit(AgentDashboardListingsFailure(e.toString()));
    }
  }
}
