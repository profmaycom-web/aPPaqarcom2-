import 'package:ebroker/data/model/agent/agent_list_filter.dart';
import 'package:ebroker/data/model/agent/agent_model.dart';
import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchAgentsState {}

class FetchAgentsInitial extends FetchAgentsState {}

class FetchAgentsLoading extends FetchAgentsState {}

class FetchAgentsSuccess extends FetchAgentsState {
  FetchAgentsSuccess({
    required this.offset,
    required this.total,
    required this.agents,
    required this.isLoadingMore,
    required this.hasLoadMoreError,
  });

  final int offset;
  final int total;
  final List<AgentModel> agents;
  final bool isLoadingMore;
  final bool hasLoadMoreError;

  FetchAgentsSuccess copyWith({
    List<AgentModel>? agents,
    int? total,
    int? offset,
    bool? isLoadingMore,
    bool? hasLoadMoreError,
  }) {
    return FetchAgentsSuccess(
      agents: agents ?? this.agents,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoadMoreError: hasLoadMoreError ?? this.hasLoadMoreError,
    );
  }
}

class FetchAgentsFailure extends FetchAgentsState {
  FetchAgentsFailure(this.errorMessage);

  final String errorMessage;
}

class FetchAgentsCubit extends Cubit<FetchAgentsState> {
  FetchAgentsCubit() : super(FetchAgentsInitial());

  final AgentsRepository _agentsRepository = AgentsRepository();
  bool _isFollowingMode = false;
  AgentListFilter _filter = const AgentListFilter();

  AgentListFilter get filter => _filter;

  bool get isFollowingMode => _isFollowingMode;

  Future<void> fetchAgents({
    required bool forceRefresh,
    bool isFollowing = false,
    AgentListFilter? filter,
  }) async {
    try {
      _isFollowingMode = isFollowing;
      _filter = filter ?? _filter;
      emit(FetchAgentsLoading());
      final dataOutput = _isFollowingMode
          ? await _agentsRepository.fetchFollowingAgents(offset: 0)
          : await _agentsRepository.fetchAllAgents(offset: 0, filter: _filter);

      final agents = List<AgentModel>.from(dataOutput.modelList);

      emit(
        FetchAgentsSuccess(
          offset: 0,
          total: dataOutput.total,
          agents: agents,
          isLoadingMore: false,
          hasLoadMoreError: false,
        ),
      );
    } on ApiException catch (e) {
      emit(FetchAgentsFailure(e.toString()));
    }
  }

  bool isLoadingMore() {
    if (state is FetchAgentsSuccess) {
      return (state as FetchAgentsSuccess).isLoadingMore;
    }
    return false;
  }

  Future<void> fetchMore() async {
    if (state is FetchAgentsSuccess) {
      try {
        final scrollSuccess = state as FetchAgentsSuccess;
        if (scrollSuccess.isLoadingMore) return;
        emit(
          (state as FetchAgentsSuccess).copyWith(isLoadingMore: true),
        );

        final dataOutput = _isFollowingMode
            ? await _agentsRepository.fetchFollowingAgents(
                offset: (state as FetchAgentsSuccess).agents.length,
              )
            : await _agentsRepository.fetchAllAgents(
                offset: (state as FetchAgentsSuccess).agents.length,
                filter: _filter,
              );

        final currentState = state as FetchAgentsSuccess;
        final updatedAgents = currentState.agents..addAll(dataOutput.modelList);
        emit(
          FetchAgentsSuccess(
            isLoadingMore: false,
            hasLoadMoreError: false,
            agents: updatedAgents,
            offset: updatedAgents.length,
            total: dataOutput.total,
          ),
        );
      } on ApiException {
        emit(
          (state as FetchAgentsSuccess).copyWith(hasLoadMoreError: true),
        );
      }
    }
  }

  bool hasMoreData() {
    if (state is FetchAgentsSuccess) {
      return (state as FetchAgentsSuccess).agents
              .whereType<AgentModel>()
              .length <
          (state as FetchAgentsSuccess).total;
    }
    return false;
  }

  void removeAgent(int agentId) {
    if (state is FetchAgentsSuccess) {
      final currentState = state as FetchAgentsSuccess;
      final updatedAgents = currentState.agents
          .where((agent) => agent.id != agentId)
          .toList();
      final updatedTotal = currentState.total > 0 ? currentState.total - 1 : 0;
      emit(
        currentState.copyWith(
          agents: updatedAgents,
          total: updatedTotal,
        ),
      );
    }
  }

  bool isAgentsEmpty() {
    if (state is FetchAgentsSuccess) {
      return (state as FetchAgentsSuccess).agents.isEmpty &&
          !(state as FetchAgentsSuccess).isLoadingMore;
    }
    return true;
  }
}
