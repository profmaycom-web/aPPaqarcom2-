import 'package:ebroker/data/repositories/stories_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DeleteStoryState {}

class DeleteStoryInitial extends DeleteStoryState {}

class DeleteStoryInProgress extends DeleteStoryState {}

class DeleteStorySuccess extends DeleteStoryState {
  DeleteStorySuccess(this.storyId);
  final String storyId;
}

class DeleteStoryFailure extends DeleteStoryState {
  DeleteStoryFailure(this.errorMessage);
  final String errorMessage;
}

class DeleteStoryCubit extends Cubit<DeleteStoryState> {
  DeleteStoryCubit() : super(DeleteStoryInitial());

  final StoriesRepository _repository = StoriesRepository();

  Future<void> delete(String storyId) async {
    try {
      emit(DeleteStoryInProgress());
      await _repository.deleteStory(storyId);
      emit(DeleteStorySuccess(storyId));
    } on ApiException catch (e) {
      emit(DeleteStoryFailure(e.errorMessage));
    } on Exception catch (e) {
      emit(DeleteStoryFailure(e.toString()));
    }
  }
}
