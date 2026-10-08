import 'package:ebroker/data/model/project_sections_model.dart';
import 'package:ebroker/data/repositories/home_screen_data_repository.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class FetchProjectSectionsState {}

class FetchProjectSectionsInitial extends FetchProjectSectionsState {}

class FetchProjectSectionsLoading extends FetchProjectSectionsState {}

class FetchProjectSectionsSuccess extends FetchProjectSectionsState {
  FetchProjectSectionsSuccess({required this.data});

  final ProjectSectionsModel data;
}

class FetchProjectSectionsFailure extends FetchProjectSectionsState {
  FetchProjectSectionsFailure(this.errorMessage);

  final String errorMessage;
}

class FetchProjectSectionsCubit extends Cubit<FetchProjectSectionsState> {
  FetchProjectSectionsCubit() : super(FetchProjectSectionsInitial());

  final HomeScreenDataRepository _repository = HomeScreenDataRepository();

  Future<void> fetch({
    bool forceRefresh = false,
    bool isSilent = false,
  }) async {
    try {
      if (!isSilent &&
          (forceRefresh || state is! FetchProjectSectionsSuccess)) {
        emit(FetchProjectSectionsLoading());
      }
      final data = await _repository.fetchProjectSections();
      emit(FetchProjectSectionsSuccess(data: data));
    } on ApiException catch (e) {
      if (!isSilent) emit(FetchProjectSectionsFailure(e.errorMessage));
    }
  }
}
