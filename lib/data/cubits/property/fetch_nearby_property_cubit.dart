import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/data/repositories/property_repository.dart';
import 'package:ebroker/ui/screens/proprties/view_all.dart';
import 'package:ebroker/utils/active_role_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchNearbyPropertiesState {}

class FetchNearbyPropertiesInitial extends FetchNearbyPropertiesState {}

class FetchNearbyPropertiesInProgress extends FetchNearbyPropertiesState {}

class FetchNearbyPropertiesSuccess extends FetchNearbyPropertiesState
    implements PropertySuccessStateWireframe {
  FetchNearbyPropertiesSuccess({
    required this.properties,
    required this.total,
    this.isLoadingMore = false,
    this.loadingMoreError = false,
  });

  @override
  final bool isLoadingMore;
  final bool loadingMoreError;
  @override
  final List<PropertyModel> properties;
  final int total;

  FetchNearbyPropertiesSuccess copyWith({
    bool? isLoadingMore,
    bool? loadingMoreError,
    List<PropertyModel>? properties,
    int? total,
  }) {
    return FetchNearbyPropertiesSuccess(
      properties: properties ?? this.properties,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadingMoreError: loadingMoreError ?? this.loadingMoreError,
    );
  }

  @override
  set isLoadingMore(bool isLoadingMore) {}

  @override
  set properties(List<PropertyModel> properties) {}
}

class FetchNearbyPropertiesFailure extends FetchNearbyPropertiesState
    implements PropertyErrorStateWireframe {
  FetchNearbyPropertiesFailure(this.error);
  @override
  final dynamic error;

  @override
  set error(_) {}
}

class FetchNearbyPropertiesCubit extends Cubit<FetchNearbyPropertiesState>
    implements PropertyCubitWireframe {
  FetchNearbyPropertiesCubit() : super(FetchNearbyPropertiesInitial());

  final PropertyRepository _propertyRepository = PropertyRepository();

  @override
  Future<void> fetch({
    bool? forceRefresh,
    bool? loadWithoutDelay,
  }) async {
    if (ActiveRoleManager.isAgent) return;
    final currentState = state;
    if (!(forceRefresh ?? false) &&
        currentState is FetchNearbyPropertiesSuccess &&
        currentState.properties.isNotEmpty) {
      return;
    }
    try {
      final result = await _propertyRepository.fetchNearByProperty(offset: 0);
      emit(
        FetchNearbyPropertiesSuccess(
          properties: result.modelList,
          total: result.total,
        ),
      );
    } on Exception catch (e) {
      emit(FetchNearbyPropertiesFailure(e as dynamic));
    }
  }

  void update(PropertyModel model) {
    final current = state;
    if (current is! FetchNearbyPropertiesSuccess) return;
    final index = current.properties.indexWhere((p) => p.id == model.id);
    if (index == -1) return;
    final updated = List<PropertyModel>.from(current.properties);
    updated[index] = model;
    emit(current.copyWith(properties: updated));
  }

  @override
  Future<void> fetchMore() async {
    if (ActiveRoleManager.isAgent) return;
    final current = state;
    if (current is! FetchNearbyPropertiesSuccess) return;
    if (current.isLoadingMore) return;
    if (current.properties.length >= current.total) return;

    emit(current.copyWith(isLoadingMore: true, loadingMoreError: false));
    try {
      final result = await _propertyRepository.fetchNearByProperty(
        offset: current.properties.length,
      );

      final latest = state;
      if (latest is! FetchNearbyPropertiesSuccess) return;

      final existingIds = latest.properties.map((p) => p.id).toSet();
      final newItems = result.modelList
          .where((p) => !existingIds.contains(p.id))
          .toList();

      if (newItems.isEmpty) {
        emit(
          latest.copyWith(
            isLoadingMore: false,
            total: latest.properties.length,
          ),
        );
        return;
      }

      final updated = List<PropertyModel>.from(latest.properties)
        ..addAll(newItems);

      emit(
        FetchNearbyPropertiesSuccess(
          properties: updated,
          total: result.total < updated.length ? updated.length : result.total,
        ),
      );
    } on Exception catch (_) {
      final latest = state;
      if (latest is FetchNearbyPropertiesSuccess) {
        emit(latest.copyWith(isLoadingMore: false, loadingMoreError: true));
      }
    }
  }

  @override
  Future<void> fetchWithFilter(FilterApply? filter, String searchQuery) async {
    try {
      emit(FetchNearbyPropertiesInProgress());
      final result = await _propertyRepository.searchProperty(
        searchQuery,
        offset: 0,
        filter: filter,
      );
      emit(
        FetchNearbyPropertiesSuccess(
          properties: result.modelList,
          total: result.total,
        ),
      );
    } on Exception catch (e) {
      emit(FetchNearbyPropertiesFailure(e as dynamic));
    }
  }

  @override
  bool hasMoreData() {
    final current = state;
    if (current is! FetchNearbyPropertiesSuccess) return false;
    return current.properties.length < current.total;
  }
}
