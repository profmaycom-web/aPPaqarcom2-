import 'package:ebroker/ui/screens/agent_dashboard/models/agent_follower_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/repositories/agent_dashboard_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AgentDashboardFollowersState {}

class AgentDashboardFollowersInitial extends AgentDashboardFollowersState {}

class AgentDashboardFollowersLoading extends AgentDashboardFollowersState {}

class AgentDashboardFollowersSuccess extends AgentDashboardFollowersState {
  AgentDashboardFollowersSuccess({
    required this.offset,
    required this.total,
    required this.followers,
    required this.isLoadingMore,
    required this.hasLoadMoreError,
  });

  final int offset;
  final int total;
  final List<AgentFollowerModel> followers;
  final bool isLoadingMore;
  final bool hasLoadMoreError;

  AgentDashboardFollowersSuccess copyWith({
    List<AgentFollowerModel>? followers,
    int? total,
    int? offset,
    bool? isLoadingMore,
    bool? hasLoadMoreError,
  }) {
    return AgentDashboardFollowersSuccess(
      followers: followers ?? this.followers,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoadMoreError: hasLoadMoreError ?? this.hasLoadMoreError,
    );
  }
}

class AgentDashboardFollowersFailure extends AgentDashboardFollowersState {
  AgentDashboardFollowersFailure(this.errorMessage);

  final String errorMessage;
}

class AgentDashboardFollowersCubit extends Cubit<AgentDashboardFollowersState> {
  AgentDashboardFollowersCubit() : super(AgentDashboardFollowersInitial());

  final AgentDashboardRepository _repository = AgentDashboardRepository();

  Future<void> fetchFollowers() async {
    try {
      emit(AgentDashboardFollowersLoading());
      final dataOutput = await _repository.fetchFollowers(offset: 0);
      final cachedProfile = HiveUtils.getAgentProfileData();
      if (cachedProfile != null &&
          cachedProfile.totalFollowers != dataOutput.total.toString()) {
        final updatedProfile = cachedProfile.copyWith(
          totalFollowers: dataOutput.total.toString(),
        );
        await HiveUtils.setAgentProfileData(updatedProfile.toMap());
      }
      emit(
        AgentDashboardFollowersSuccess(
          offset: 0,
          total: dataOutput.total,
          followers: dataOutput.modelList,
          isLoadingMore: false,
          hasLoadMoreError: false,
        ),
      );
    } on ApiException catch (e) {
      emit(AgentDashboardFollowersFailure(e.toString()));
    } on Exception catch (e) {
      emit(AgentDashboardFollowersFailure(e.toString()));
    }
  }

  bool isLoadingMore() {
    if (state is AgentDashboardFollowersSuccess) {
      return (state as AgentDashboardFollowersSuccess).isLoadingMore;
    }
    return false;
  }

  Future<void> fetchMore() async {
    if (state is AgentDashboardFollowersSuccess) {
      try {
        final currentState = state as AgentDashboardFollowersSuccess;
        if (currentState.isLoadingMore) return;
        emit(currentState.copyWith(isLoadingMore: true));

        final dataOutput = await _repository.fetchFollowers(
          offset: currentState.followers.length,
        );

        final updatedFollowers = List<AgentFollowerModel>.from(
          currentState.followers,
        )..addAll(dataOutput.modelList);

        emit(
          AgentDashboardFollowersSuccess(
            isLoadingMore: false,
            hasLoadMoreError: false,
            followers: updatedFollowers,
            offset: updatedFollowers.length,
            total: dataOutput.total,
          ),
        );
      } on Exception {
        emit(
          (state as AgentDashboardFollowersSuccess).copyWith(
            hasLoadMoreError: true,
          ),
        );
      }
    }
  }

  bool hasMoreData() {
    if (state is AgentDashboardFollowersSuccess) {
      final current = state as AgentDashboardFollowersSuccess;
      return current.followers.length < current.total;
    }
    return false;
  }
}
