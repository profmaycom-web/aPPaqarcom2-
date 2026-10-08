import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ebroker/data/model/story_model.dart';
import 'package:ebroker/utils/api.dart';

class StoriesRepository {
  Future<StoriesResponseModel> fetchStories({
    int limit = 10,
    int offset = 0,
    int? categoryId,
    int? agentId,
    bool isAdmin = false,
  }) async {
    final response = await Api.get(
      url: Api.getStories,
      queryParameters: <String, dynamic>{
        Api.limit: limit,
        Api.offset: offset,
        Api.categoryId: categoryId,
        Api.agentId: isAdmin ? 0 : agentId,
        if (isAdmin) 'is_admin': '1',
      },
    );

    final data = response['data'];
    if (data is Map) {
      return StoriesResponseModel.fromJson(Map<String, dynamic>.from(data));
    }
    return StoriesResponseModel();
  }

  /// Marks [storyId] as seen for the current user and increments its
  /// view_count. The backend backfills earlier same-agent stories as seen
  /// automatically — do not call this per-story-in-a-loop.
  Future<void> markStoryViewed(String storyId) async {
    await Api.post(
      url: Api.storyView,
      parameter: <String, dynamic>{Api.storyId: storyId},
    );
  }

  Future<StoryItemModel> uploadStory({
    required File media,
    required String mediaType,
    required String entityType,
    required int entityId,
    int? durationSeconds,
    File? thumbnail,
  }) async {
    final parameters = <String, dynamic>{
      Api.media: await MultipartFile.fromFile(media.path),
      Api.mediaType: mediaType,
      Api.entityType: entityType,
      Api.entityId: entityId,
      Api.durationSeconds: ?durationSeconds,
    };
    if (thumbnail != null) {
      parameters[Api.thumbnail] = await MultipartFile.fromFile(thumbnail.path);
    }

    final response = await Api.post(
      url: Api.uploadStory,
      parameter: parameters,
    );
    return StoryItemModel.fromJson(
      Map<String, dynamic>.from(response['data'] as Map? ?? {}),
    );
  }

  Future<void> deleteStory(String storyId) async {
    await Api.delete(url: '${Api.deleteStory}?${Api.storyId}=$storyId');
  }

  Future<MyStoriesResponseModel> fetchMyStories() async {
    final response = await Api.get(url: Api.myStories);
    final data = response['data'];
    if (data is Map) {
      return MyStoriesResponseModel.fromJson(Map<String, dynamic>.from(data));
    }
    return MyStoriesResponseModel();
  }
}
