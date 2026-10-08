import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/data/repositories/property_repository.dart';
import 'package:ebroker/ui/screens/proprties/view_all.dart';
import 'package:ebroker/utils/network/cache_manger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchPremiumPropertiesState {}

class FetchPremiumPropertiesInitial extends FetchPremiumPropertiesState {}

class FetchPremiumPropertiesInProgress extends FetchPremiumPropertiesState {}

class FetchPremiumPropertiesSuccess extends FetchPremiumPropertiesState
    implements PropertySuccessStateWireframe {
  FetchPremiumPropertiesSuccess({
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

  FetchPremiumPropertiesSuccess copyWith({
    bool? isLoadingMore,
    bool? loadingMoreError,
    List<PropertyModel>? properties,
    int? total,
  }) {
    return FetchPremiumPropertiesSuccess(
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

class FetchPremiumPropertiesFailure extends FetchPremiumPropertiesState
    implements PropertyErrorStateWireframe {
  FetchPremiumPropertiesFailure(this.error);
  @override
  final String error;

  @override
  set error(_) {}
}

class FetchPremiumPropertiesCubit extends Cubit<FetchPremiumPropertiesState>
    implements PropertyCubitWireframe {
  FetchPremiumPropertiesCubit() : super(FetchPremiumPropertiesInitial());

  final PropertyRepository _propertyRepository = PropertyRepository();

  @override
  Future<void> fetch({
    bool? forceRefresh,
    bool? loadWithoutDelay,
  }) async {
    final currentState = state;
    if (!(forceRefresh ?? false) &&
        currentState is FetchPremiumPropertiesSuccess &&
        currentState.properties.isNotEmpty) {
      return;
    }
    try {
      await CacheData().getData(
        forceRefresh: forceRefresh ?? false,
        onProgress: () {
          emit(FetchPremiumPropertiesInProgress());
        },
        delay: loadWithoutDelay ?? false ? 0 : null,
        onNetworkRequest: () async {
          final result = await _propertyRepository.fetchPremiumProperty(
            offset: 0,
          );
          return FetchPremiumPropertiesSuccess(
            properties: result.modelList,
            total: result.total,
          );
        },
        onOfflineData: () {
          final current = state;
          if (current is FetchPremiumPropertiesSuccess) return current;
          return FetchPremiumPropertiesSuccess(properties: const [], total: 0);
        },
        onSuccess: (data) {
          emit(data);
        },
        hasData: state is FetchPremiumPropertiesSuccess,
      );
    } on Exception catch (e) {
      emit(FetchPremiumPropertiesFailure(e.toString()));
    }
  }

  void update(PropertyModel model) {
    final current = state;
    if (current is! FetchPremiumPropertiesSuccess) return;
    final index = current.properties.indexWhere((p) => p.id == model.id);
    if (index == -1) return;
    final updated = List<PropertyModel>.from(current.properties);
    updated[index] = model;
    emit(current.copyWith(properties: updated));
  }

  @override
  Future<void> fetchMore() async {
    final current = state;
    if (current is! FetchPremiumPropertiesSuccess) return;
    if (current.isLoadingMore) return;
    if (current.properties.length >= current.total) return;

    emit(current.copyWith(isLoadingMore: true, loadingMoreError: false));
    try {
      final result = await _propertyRepository.fetchPremiumProperty(
        offset: current.properties.length,
      );

      final latest = state;
      if (latest is! FetchPremiumPropertiesSuccess) return;

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
        FetchPremiumPropertiesSuccess(
          properties: updated,
          total: result.total < updated.length ? updated.length : result.total,
        ),
      );
    } on Exception catch (_) {
      final latest = state;
      if (latest is FetchPremiumPropertiesSuccess) {
        emit(latest.copyWith(isLoadingMore: false, loadingMoreError: true));
      }
    }
  }

  @override
  Future<void> fetchWithFilter(FilterApply? filter, String searchQuery) async {
    // Always lock in the premium flag regardless of what filter provides.
    final merged = (filter ?? FilterApply()).copy()
      ..addOrUpdate(const FlagsFilter(promoted: false, premium: true));
    try {
      emit(FetchPremiumPropertiesInProgress());
      final result = await _propertyRepository.searchProperty(
        searchQuery,
        offset: 0,
        filter: merged,
      );
      emit(
        FetchPremiumPropertiesSuccess(
          properties: result.modelList,
          total: result.total,
        ),
      );
    } on Exception catch (e) {
      emit(FetchPremiumPropertiesFailure(e.toString()));
    }
  }

  @override
  bool hasMoreData() {
    final current = state;
    if (current is! FetchPremiumPropertiesSuccess) return false;
    return current.properties.length < current.total;
  }
}
