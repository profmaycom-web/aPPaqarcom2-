import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_active_packages_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/repositories/agent_dashboard_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AgentDashboardActivePackagesState {}

class AgentDashboardActivePackagesInitial
    extends AgentDashboardActivePackagesState {}

class AgentDashboardActivePackagesLoading
    extends AgentDashboardActivePackagesState {}

class AgentDashboardActivePackagesSuccess
    extends AgentDashboardActivePackagesState {
  AgentDashboardActivePackagesSuccess(this.packages);
  final List<AgentDashboardActivePackageModel> packages;
}

class AgentDashboardActivePackagesFailure
    extends AgentDashboardActivePackagesState {
  AgentDashboardActivePackagesFailure(this.errorMessage);
  final String errorMessage;
}

class AgentDashboardActivePackagesCubit
    extends Cubit<AgentDashboardActivePackagesState> {
  AgentDashboardActivePackagesCubit()
    : super(AgentDashboardActivePackagesInitial());

  final AgentDashboardRepository _repository = AgentDashboardRepository();

  Future<void> fetch() async {
    try {
      emit(AgentDashboardActivePackagesLoading());
      final packages = await _repository.fetchActivePackages();
      emit(AgentDashboardActivePackagesSuccess(packages));
    } on ApiException catch (e) {
      emit(AgentDashboardActivePackagesFailure(e.toString()));
    } on Exception catch (e) {
      emit(AgentDashboardActivePackagesFailure(e.toString()));
    }
  }
}
