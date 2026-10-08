import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/agent/agents_property_model.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class FetchAgentsProjectState {}

final class FetchAgentsProjectInitial extends FetchAgentsProjectState {}

final class FetchAgentsProjectLoading extends FetchAgentsProjectState {}

final class FetchAgentsProjectSuccess extends FetchAgentsProjectState {
  FetchAgentsProjectSuccess({
    required this.offset,
    required this.total,
    required this.agentsProperty,
    required this.isLoadingMore,
    required this.hasLoadMoreError,
    this.filter,
    this.searchQuery,
  });

  final int offset;
  final int total;
  final AgentPropertyProjectModel agentsProperty;
  final bool isLoadingMore;
  final bool hasLoadMoreError;
  final FilterApply? filter;
  final String? searchQuery;

  FetchAgentsProjectSuccess copyWith({
    AgentPropertyProjectModel? agentsProperty,
    int? total,
    int? offset,
    bool? isLoadingMore,
    bool? hasLoadMoreError,
    FilterApply? filter,
    String? searchQuery,
  }) {
    return FetchAgentsProjectSuccess(
      agentsProperty: agentsProperty ?? this.agentsProperty,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoadMoreError: hasLoadMoreError ?? this.hasLoadMoreError,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final class FetchAgentsProjectFailure extends FetchAgentsProjectState {
  FetchAgentsProjectFailure(this.errorMessage);

  final String errorMessage;
}

class FetchAgentsProjectCubit extends Cubit<FetchAgentsProjectState> {
  FetchAgentsProjectCubit() : super(FetchAgentsProjectInitial());

  final AgentsRepository agentsRepository = AgentsRepository();

  Future<void> fetchAgentsProject({
    required bool forceRefresh,
    required String agentId,
    required bool isAdmin,
    FilterApply? filter,
    String? searchQuery,
  }) async {
    try {
      emit(FetchAgentsProjectLoading());
      final (:total, :agentsProperty) = await agentsRepository
          .fetchAgentProjects(
            offset: 0,
            isProjects: 1,
            agentId: agentId,
            isAdmin: isAdmin,
            filter: filter,
            searchQuery: searchQuery,
          );
      emit(
        FetchAgentsProjectSuccess(
          offset: 0,
          total: total,
          agentsProperty: agentsProperty,
          isLoadingMore: false,
          hasLoadMoreError: false,
          filter: filter,
          searchQuery: searchQuery,
        ),
      );
    } on ApiException catch (e) {
      emit(FetchAgentsProjectFailure(e.errorMessage));
    }
  }

  bool isLoadingMore() {
    if (state is FetchAgentsProjectSuccess) {
      return (state as FetchAgentsProjectSuccess).isLoadingMore;
    }
    return false;
  }

  Future<void> fetchMore({required bool isAdmin}) async {
    if (state is FetchAgentsProjectSuccess) {
      try {
        final scrollSuccess = state as FetchAgentsProjectSuccess;
        if (scrollSuccess.isLoadingMore) return;
        emit(
          (state as FetchAgentsProjectSuccess).copyWith(isLoadingMore: true),
        );

        final (:total, :agentsProperty) = await agentsRepository
            .fetchAgentProjects(
              offset: (state as FetchAgentsProjectSuccess)
                  .agentsProperty
                  .projectData
                  .length,
              isProjects: 1,
              agentId: (state as FetchAgentsProjectSuccess)
                  .agentsProperty
                  .customerData
                  .id
                  .toString(),
              isAdmin: isAdmin,
              filter: (state as FetchAgentsProjectSuccess).filter,
              searchQuery: (state as FetchAgentsProjectSuccess).searchQuery,
            );

        final currentState = state as FetchAgentsProjectSuccess;

        emit(
          FetchAgentsProjectSuccess(
            isLoadingMore: false,
            hasLoadMoreError: false,
            agentsProperty: currentState.agentsProperty.copyWith(
              projectData: [
                ...currentState.agentsProperty.projectData,
                ...agentsProperty.projectData,
              ],
            ),
            offset: (state as FetchAgentsProjectSuccess)
                .agentsProperty
                .projectData
                .length,
            total: total,
            filter: currentState.filter,
            searchQuery: currentState.searchQuery,
          ),
        );
      } on Object catch (_) {
        emit(
          (state as FetchAgentsProjectSuccess).copyWith(
            isLoadingMore: false,
            hasLoadMoreError: true,
          ),
        );
      }
    }
  }

  bool hasMoreData() {
    if (state is FetchAgentsProjectSuccess) {
      final agentsProperty =
          (state as FetchAgentsProjectSuccess).agentsProperty;
      final total = (state as FetchAgentsProjectSuccess).total;
      return agentsProperty.projectData.length < total;
    }
    return false;
  }
}
