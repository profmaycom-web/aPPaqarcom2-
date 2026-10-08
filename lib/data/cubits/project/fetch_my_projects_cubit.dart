import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/project_repository.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class FetchMyProjectsState {}

class FetchMyProjectsInitial extends FetchMyProjectsState {}

class FetchMyProjectsInProgress extends FetchMyProjectsState {}

class FetchMyProjectsSuccess extends FetchMyProjectsState {
  FetchMyProjectsSuccess({
    required this.isLoadingMore,
    required this.hasError,
    required this.total,
    required this.projects,
    required this.offset,
  });
  final bool isLoadingMore;
  final bool hasError;
  final int total;
  final List<ProjectModel> projects;
  final int offset;

  FetchMyProjectsSuccess copyWith({
    bool? isLoadingMore,
    bool? hasError,
    int? total,
    List<ProjectModel>? projects,
    int? offset,
  }) {
    return FetchMyProjectsSuccess(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      total: total ?? this.total,
      projects: projects ?? this.projects,
      offset: offset ?? this.offset,
    );
  }
}

class FetchMyProjectsFail extends FetchMyProjectsState {
  FetchMyProjectsFail(this.error, {this.errorKey});
  final dynamic error;
  final String? errorKey;
}

class FetchMyProjectsCubit extends Cubit<FetchMyProjectsState> {
  FetchMyProjectsCubit() : super(FetchMyProjectsInitial());
  final ProjectRepository _projectRepository = ProjectRepository();

  Future<void> fetchMyProjects({
    String? type,
    String? status,
  }) async {
    try {
      if (state is FetchMyProjectsSuccess) {
        emit(
          (state as FetchMyProjectsSuccess).copyWith(isLoadingMore: false),
        );
      } else {
        emit(FetchMyProjectsInProgress());
      }

      final dataOutput = await _projectRepository.getMyProjects(
        offset: 0,
        type: type,
        status: status,
      );

      emit(
        FetchMyProjectsSuccess(
          hasError: false,
          isLoadingMore: false,
          offset: 0,
          total: dataOutput.total,
          projects: dataOutput.modelList,
        ),
      );
    } on Exception catch (e) {
      emit(
        FetchMyProjectsFail(
          e,
          errorKey: e is ApiException ? e.errorKey : null,
        ),
      );
    }
  }

  Future<void> fetchMoreMyProjects({
    String? type,
    String? status,
  }) async {
    try {
      final scrollSuccess = state as FetchMyProjectsSuccess;
      if (scrollSuccess.isLoadingMore) return;
      emit(
        (state as FetchMyProjectsSuccess).copyWith(isLoadingMore: true),
      );
      final result = await _projectRepository.getMyProjects(
        offset: (state as FetchMyProjectsSuccess).projects.length,
        type: type,
        status: status,
      );

      final currentState = state as FetchMyProjectsSuccess;
      final updatedProjects = currentState.projects..addAll(result.modelList);

      emit(
        FetchMyProjectsSuccess(
          projects: updatedProjects,
          isLoadingMore: false,
          hasError: false,
          offset: updatedProjects.length,
          total: result.total,
        ),
      );
    } on Exception catch (_) {
      emit(
        (state as FetchMyProjectsSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  void delete(int id) {
    if (state is FetchMyProjectsSuccess) {
      final current = state as FetchMyProjectsSuccess;
      final updatedList = List<ProjectModel>.from(current.projects)
        ..removeWhere((element) => element.id == id);
      final newTotal = current.total > 0 ? current.total - 1 : 0;
      emit(
        current.copyWith(
          projects: updatedList,
          total: newTotal,
        ),
      );
    }
  }

  void update(ProjectModel model) {
    if (state is FetchMyProjectsSuccess) {
      final indexWhere = (state as FetchMyProjectsSuccess).projects.indexWhere(
        (element) => element.id == model.id,
      );
      if (indexWhere.isNegative) {
        (state as FetchMyProjectsSuccess).projects.add(model);
      } else {
        (state as FetchMyProjectsSuccess).projects[indexWhere] = model;
      }
      emit(
        (state as FetchMyProjectsSuccess).copyWith(
          projects: (state as FetchMyProjectsSuccess).projects,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchMyProjectsSuccess) {
      return (state as FetchMyProjectsSuccess).projects
              .whereType<ProjectModel>()
              .length <
          (state as FetchMyProjectsSuccess).total;
    }
    return false;
  }

  void clear() {
    emit(FetchMyProjectsInitial());
  }
}
