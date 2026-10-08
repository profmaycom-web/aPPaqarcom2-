import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ebroker/data/model/story_model.dart';
import 'package:ebroker/data/repositories/stories_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchStoriesState {}

class FetchStoriesInitial extends FetchStoriesState {}

class FetchStoriesLoading extends FetchStoriesState {
  FetchStoriesLoading({this.previousData});

  /// Data from the last [FetchStoriesSuccess], if any — lets the UI keep
  /// showing the old row instead of collapsing while a refetch is in
  /// flight (e.g. forceRefresh on categoryId change).
  final StoriesResponseModel? previousData;
}

class FetchStoriesSuccess extends FetchStoriesState {
  FetchStoriesSuccess({required this.data, this.isLoadingMore = false});
  final StoriesResponseModel data;
  final bool isLoadingMore;

  FetchStoriesSuccess copyWith({
    StoriesResponseModel? data,
    bool? isLoadingMore,
  }) {
    return FetchStoriesSuccess(
      data: data ?? this.data,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class FetchStoriesFailure extends FetchStoriesState {
  FetchStoriesFailure(this.errorMessage);
  final String errorMessage;
}

class FetchStoriesCubit extends Cubit<FetchStoriesState> {
  FetchStoriesCubit() : super(FetchStoriesInitial());

  final StoriesRepository _repository = StoriesRepository();

  int? _categoryId;
  int? _agentId;

  Future<void> fetch({
    bool forceRefresh = false,
    int? categoryId,
    int? agentId,
  }) async {
    if (!forceRefresh && state is FetchStoriesSuccess) return;
    _categoryId = categoryId;
    _agentId = agentId;
    final previous = state is FetchStoriesSuccess
        ? (state as FetchStoriesSuccess).data
        : null;
    try {
      emit(FetchStoriesLoading(previousData: previous));
      final data = await _repository.fetchStories(
        categoryId: categoryId,
        agentId: agentId,
      );
      emit(FetchStoriesSuccess(data: data));
    } on ApiException catch (e) {
      emit(FetchStoriesFailure(e.errorMessage));
    } on Exception catch (e) {
      emit(FetchStoriesFailure(e.toString()));
    }
  }

  bool get hasMoreData {
    if (state is! FetchStoriesSuccess) return false;
    return (state as FetchStoriesSuccess).data.pagination?.hasMore ?? false;
  }

  /// Appends the next page of agents (pagination is by uploader, not by
  /// story count — one page = N agents, per spec).
  Future<void> fetchMore() async {
    if (state is! FetchStoriesSuccess) return;
    final current = state as FetchStoriesSuccess;
    if (current.isLoadingMore || !hasMoreData) return;

    emit(FetchStoriesSuccess(data: current.data, isLoadingMore: true));
    try {
      final more = await _repository.fetchStories(
        offset: current.data.agents.length,
        categoryId: _categoryId,
        agentId: _agentId,
      );
      emit(
        FetchStoriesSuccess(
          data: StoriesResponseModel(
            sectionTitle: current.data.sectionTitle,
            isGuest: current.data.isGuest,
            userHasPremiumPropertiesAccess:
                current.data.userHasPremiumPropertiesAccess,
            userHasPremiumProjectsAccess:
                current.data.userHasPremiumProjectsAccess,
            agents: [...current.data.agents, ...more.agents],
            pagination: more.pagination,
          ),
        ),
      );
    } on Exception {
      emit(FetchStoriesSuccess(data: current.data));
    }
  }

  /// Calls the story-view API and, if this cubit's own cached state happens
  /// to hold [storyId] (not guaranteed — callers may be showing data from a
  /// scoped/local cubit or a raw repository call instead of this global
  /// instance), optimistically marks it seen for UI purposes. The API call
  /// itself must not depend on that cache match, or it silently never fires
  /// whenever this cubit hasn't been fetched with matching data — callers
  /// are responsible for their own dedup (e.g. per-viewer-session) since
  /// this cubit's cache can't be relied on for that either.
  void markStorySeen(int agentId, String storyId) {
    unawaited(_repository.markStoryViewed(storyId));

    if (state is! FetchStoriesSuccess) return;

    final currentState = state as FetchStoriesSuccess;
    final current = currentState.data;

    final matchingAgent = current.agents
        .where((agent) => agent.agentId == agentId)
        .firstOrNull;
    final matchingStory = [
      ...?matchingAgent?.premiumStories,
      ...?matchingAgent?.nonPremiumStories,
    ].where((story) => story.storyId == storyId).firstOrNull;

    if (matchingStory == null || matchingStory.isSeen) return;

    StoryItemModel markIfMatch(StoryItemModel story) {
      if (story.storyId != storyId || story.isSeen) return story;
      return StoryItemModel(
        storyId: story.storyId,
        mediaType: story.mediaType,
        mediaUrl: story.mediaUrl,
        thumbnailUrl: story.thumbnailUrl,
        durationSeconds: story.durationSeconds,
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        viewCount: (story.viewCount ?? 0) + 1,
        isPremium: story.isPremium,
        isSeen: true,
        isActive: story.isActive,
        linkedEntity: story.linkedEntity,
        isPremiumTeaser: story.isPremiumTeaser,
      );
    }

    final updatedAgents = current.agents.map((agent) {
      if (agent.agentId != agentId) return agent;
      final premium = agent.premiumStories.map(markIfMatch).toList();
      final nonPremium = agent.nonPremiumStories.map(markIfMatch).toList();
      final hasUnseen = [
        ...premium,
        ...nonPremium,
      ].any((s) => !s.isSeen);
      return StoryAgentModel(
        agentId: agent.agentId,
        agentName: agent.agentName,
        agentProfileImage: agent.agentProfileImage,
        agentMobile: agent.agentMobile,
        agentCountryCode: agent.agentCountryCode,
        hasUnseenStory: hasUnseen,
        premiumStoryCount: agent.premiumStoryCount,
        premiumStories: premium,
        nonPremiumStories: nonPremium,
      );
    }).toList();

    emit(
      FetchStoriesSuccess(
        isLoadingMore: currentState.isLoadingMore,
        data: StoriesResponseModel(
          sectionTitle: current.sectionTitle,
          isGuest: current.isGuest,
          userHasPremiumPropertiesAccess:
              current.userHasPremiumPropertiesAccess,
          userHasPremiumProjectsAccess: current.userHasPremiumProjectsAccess,
          agents: updatedAgents,
          pagination: current.pagination,
        ),
      ),
    );
  }
}
