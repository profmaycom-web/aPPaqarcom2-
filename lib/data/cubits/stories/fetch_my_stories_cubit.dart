import 'package:ebroker/data/model/story_model.dart';
import 'package:ebroker/data/repositories/stories_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchMyStoriesState {}

class FetchMyStoriesInitial extends FetchMyStoriesState {}

class FetchMyStoriesLoading extends FetchMyStoriesState {}

class FetchMyStoriesSuccess extends FetchMyStoriesState {
  FetchMyStoriesSuccess(this.data);
  final MyStoriesResponseModel data;
}

class FetchMyStoriesFailure extends FetchMyStoriesState {
  FetchMyStoriesFailure(this.errorMessage);
  final String errorMessage;
}

class FetchMyStoriesCubit extends Cubit<FetchMyStoriesState> {
  FetchMyStoriesCubit() : super(FetchMyStoriesInitial());

  final StoriesRepository _repository = StoriesRepository();

  Future<void> fetch() async {
    try {
      emit(FetchMyStoriesLoading());
      final data = await _repository.fetchMyStories();
      emit(FetchMyStoriesSuccess(data));
    } on ApiException catch (e) {
      emit(FetchMyStoriesFailure(e.errorMessage));
    } on Exception catch (e) {
      emit(FetchMyStoriesFailure(e.toString()));
    }
  }

  void removeStory(String storyId) {
    if (state is! FetchMyStoriesSuccess) return;
    final current = (state as FetchMyStoriesSuccess).data;
    emit(
      FetchMyStoriesSuccess(
        MyStoriesResponseModel(
          premiumStories: current.premiumStories
              .where((s) => s.storyId != storyId)
              .toList(),
          nonPremiumStories: current.nonPremiumStories
              .where((s) => s.storyId != storyId)
              .toList(),
        ),
      ),
    );
  }
}
