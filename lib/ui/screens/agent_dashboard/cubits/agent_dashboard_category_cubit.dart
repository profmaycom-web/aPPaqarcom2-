import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_category_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/repositories/agent_dashboard_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AgentDashboardCategoryState {}

class AgentDashboardCategoryInitial extends AgentDashboardCategoryState {}

class AgentDashboardCategoryLoading extends AgentDashboardCategoryState {}

class AgentDashboardCategorySuccess extends AgentDashboardCategoryState {
  AgentDashboardCategorySuccess(this.categories);
  final List<AgentDashboardCategoryModel> categories;
}

class AgentDashboardCategoryFailure extends AgentDashboardCategoryState {
  AgentDashboardCategoryFailure(this.errorMessage);
  final String errorMessage;
}

class AgentDashboardCategoryCubit extends Cubit<AgentDashboardCategoryState> {
  AgentDashboardCategoryCubit() : super(AgentDashboardCategoryInitial());

  final AgentDashboardRepository _repository = AgentDashboardRepository();

  Future<void> fetch({required String range}) async {
    try {
      emit(AgentDashboardCategoryLoading());
      final categories = await _repository.fetchMostViewedCategories(
        range: range,
      );
      emit(AgentDashboardCategorySuccess(categories));
    } on ApiException catch (e) {
      emit(AgentDashboardCategoryFailure(e.toString()));
    } on Exception catch (e) {
      emit(AgentDashboardCategoryFailure(e.toString()));
    }
  }
}
