import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/project_repository.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class FetchProjectsListState {}

class FetchProjectsListInitial extends FetchProjectsListState {}

class FetchProjectsListInProgress extends FetchProjectsListState {}

class FetchProjectsListSuccess extends FetchProjectsListState {
  FetchProjectsListSuccess({
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

  FetchProjectsListSuccess copyWith({
    bool? isLoadingMore,
    bool? hasError,
    int? total,
    List<ProjectModel>? projects,
    int? offset,
  }) {
    return FetchProjectsListSuccess(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      total: total ?? this.total,
      projects: projects ?? this.projects,
      offset: offset ?? this.offset,
    );
  }
}

class FetchProjectsListFail extends FetchProjectsListState {
  FetchProjectsListFail(this.error, {this.errorKey});
  final dynamic error;
  final String? errorKey;
}

class FetchProjectsListCubit extends Cubit<FetchProjectsListState> {
  FetchProjectsListCubit() : super(FetchProjectsListInitial());
  final ProjectRepository _projectRepository = ProjectRepository();

  // Store last-used filter/search for pagination.
  FilterApply? _lastFilter;
  String _lastSearchQuery = '';

  Future<void> fetch({
    FilterApply? filter,
    String? searchQuery,
  }) async {
    _lastFilter = filter;
    _lastSearchQuery = searchQuery ?? '';
    try {
      emit(FetchProjectsListInProgress());
      final dataOutput = await _projectRepository.fetchAllProjects(
        offset: 0,
        filter: filter,
        searchQuery: searchQuery,
      );

      emit(
        FetchProjectsListSuccess(
          hasError: false,
          isLoadingMore: false,
          offset: 0,
          total: dataOutput.total,
          projects: dataOutput.modelList,
        ),
      );
    } on Exception catch (e) {
      emit(
        FetchProjectsListFail(
          e,
          errorKey: e is ApiException ? e.errorKey : null,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchProjectsListSuccess) {
      return (state as FetchProjectsListSuccess).projects
              .whereType<ProjectModel>()
              .length <
          (state as FetchProjectsListSuccess).total;
    }
    return false;
  }

  Future<void> fetchMore() async {
    try {
      final scrollSuccess = state as FetchProjectsListSuccess;
      if (scrollSuccess.isLoadingMore) return;
      emit(
        (state as FetchProjectsListSuccess).copyWith(isLoadingMore: true),
      );
      final result = await _projectRepository.fetchAllProjects(
        offset: (state as FetchProjectsListSuccess).projects.length,
        filter: _lastFilter,
        searchQuery: _lastSearchQuery.isEmpty ? null : _lastSearchQuery,
      );

      final currentState = state as FetchProjectsListSuccess;
      final updatedProjects = currentState.projects..addAll(result.modelList);

      emit(
        FetchProjectsListSuccess(
          projects: updatedProjects,
          isLoadingMore: false,
          hasError: false,
          offset: updatedProjects.length,
          total: result.total,
        ),
      );
    } on Exception catch (_) {
      emit(
        (state as FetchProjectsListSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  void clear() {
    emit(FetchProjectsListInitial());
  }
}
