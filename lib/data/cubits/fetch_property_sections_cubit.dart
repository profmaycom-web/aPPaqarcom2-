import 'package:ebroker/data/model/property_sections_model.dart';
import 'package:ebroker/data/repositories/home_screen_data_repository.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class FetchPropertySectionsState {}

class FetchPropertySectionsInitial extends FetchPropertySectionsState {}

class FetchPropertySectionsLoading extends FetchPropertySectionsState {}

class FetchPropertySectionsSuccess extends FetchPropertySectionsState {
  FetchPropertySectionsSuccess({required this.data});

  final PropertySectionsModel data;
}

class FetchPropertySectionsFailure extends FetchPropertySectionsState {
  FetchPropertySectionsFailure(this.errorMessage);

  final String errorMessage;
}

class FetchPropertySectionsCubit extends Cubit<FetchPropertySectionsState> {
  FetchPropertySectionsCubit() : super(FetchPropertySectionsInitial());

  final HomeScreenDataRepository _repository = HomeScreenDataRepository();

  Future<void> fetch({
    bool forceRefresh = false,
    bool isSilent = false,
  }) async {
    try {
      if (!isSilent &&
          (forceRefresh || state is! FetchPropertySectionsSuccess)) {
        emit(FetchPropertySectionsLoading());
      }
      final data = await _repository.fetchPropertySections();
      emit(FetchPropertySectionsSuccess(data: data));
    } on ApiException catch (e) {
      if (!isSilent) emit(FetchPropertySectionsFailure(e.errorMessage));
    }
  }
}
