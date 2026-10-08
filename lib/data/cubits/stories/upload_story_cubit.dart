import 'dart:io';

import 'package:ebroker/data/model/story_model.dart';
import 'package:ebroker/data/repositories/stories_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UploadStoryState {}

class UploadStoryInitial extends UploadStoryState {}

class UploadStoryInProgress extends UploadStoryState {}

class UploadStorySuccess extends UploadStoryState {
  UploadStorySuccess(this.story);
  final StoryItemModel story;
}

class UploadStoryFailure extends UploadStoryState {
  UploadStoryFailure(this.errorMessage);
  final String errorMessage;
}

class UploadStoryCubit extends Cubit<UploadStoryState> {
  UploadStoryCubit() : super(UploadStoryInitial());

  final StoriesRepository _repository = StoriesRepository();

  Future<void> upload({
    required File media,
    required String mediaType,
    required String entityType,
    required int entityId,
    int? durationSeconds,
    File? thumbnail,
  }) async {
    try {
      emit(UploadStoryInProgress());
      final story = await _repository.uploadStory(
        media: media,
        mediaType: mediaType,
        entityType: entityType,
        entityId: entityId,
        durationSeconds: durationSeconds,
        thumbnail: thumbnail,
      );
      emit(UploadStorySuccess(story));
    } on ApiException catch (e) {
      emit(UploadStoryFailure(e.errorMessage));
    } on Exception catch (e) {
      emit(UploadStoryFailure(e.toString()));
    }
  }

  void reset() => emit(UploadStoryInitial());
}
