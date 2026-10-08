import 'package:ebroker/data/model/custom_page_model.dart';
import 'package:ebroker/data/repositories/custom_pages_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchCustomPagesState {}

class FetchCustomPagesInitial extends FetchCustomPagesState {}

class FetchCustomPagesInProgress extends FetchCustomPagesState {}

class FetchCustomPagesSuccess extends FetchCustomPagesState {
  FetchCustomPagesSuccess({
    required this.pages,
    required this.total,
  });
  final List<CustomPageModel> pages;
  final int total;
}

class FetchCustomPagesFailure extends FetchCustomPagesState {
  FetchCustomPagesFailure(this.errorMessage);
  final String errorMessage;
}

class FetchCustomPagesCubit extends Cubit<FetchCustomPagesState> {
  FetchCustomPagesCubit() : super(FetchCustomPagesInitial());

  final CustomPagesRepository _repository = CustomPagesRepository();

  Future<void> fetchCustomPages() async {
    try {
      emit(FetchCustomPagesInProgress());
      final output = await _repository.fetchCustomPages(offset: 0);
      emit(
        FetchCustomPagesSuccess(pages: output.modelList, total: output.total),
      );
    } on Exception catch (e) {
      emit(FetchCustomPagesFailure(e.toString()));
    }
  }

  List<CustomPageModel> get pages {
    if (state is FetchCustomPagesSuccess) {
      return (state as FetchCustomPagesSuccess).pages;
    }
    return [];
  }
}
