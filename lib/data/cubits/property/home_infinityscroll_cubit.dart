import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/admob/native_ad_manager.dart';

abstract class HomePageInfinityScrollState {}

class HomePageInfinityScrollInitial extends HomePageInfinityScrollState {}

class HomePageInfinityScrollInProgress extends HomePageInfinityScrollState {}

class HomePageInfinityScrollSuccess extends HomePageInfinityScrollState {
  HomePageInfinityScrollSuccess({
    required this.properties,
    required this.total,
    this.offset = 0,
    this.isLoadingMore = false,
    this.hasLoadMoreError = false,
  });

  final int offset;
  final int total;
  final List<PropertyModel> properties;
  final bool isLoadingMore;
  final bool hasLoadMoreError;

  HomePageInfinityScrollSuccess copyWith({
    int? offset,
    int? total,
    List<PropertyModel>? properties,
    bool? isLoadingMore,
    bool? hasLoadMoreError,
  }) {
    return HomePageInfinityScrollSuccess(
      offset: offset ?? this.offset,
      total: total ?? this.total,
      properties: properties ?? this.properties,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoadMoreError: hasLoadMoreError ?? this.hasLoadMoreError,
    );
  }
}

class HomePageInfinityScrollFailure extends HomePageInfinityScrollState {
  HomePageInfinityScrollFailure(this.error);

  final dynamic error;
}

class HomePageInfinityScrollCubit extends Cubit<HomePageInfinityScrollState> {
  HomePageInfinityScrollCubit() : super(HomePageInfinityScrollInitial()) {
    injector(
      (conditions) {
        conditions
          ..afterIndex = 7
          ..setInjectSetting(perLength: 10, count: 10)
          ..minListCount = 7;
      },
    );
  }

  final NativeAdInjector injector = NativeAdInjector();
  PropertyRepository propertyRepository = PropertyRepository();

  Future<void> fetch() async {
    try {
      emit(HomePageInfinityScrollInProgress());
      final dataOutput = await propertyRepository.fetchAllProperties(
        offset: 0,
      );
      emit(
        HomePageInfinityScrollSuccess(
          properties: dataOutput.modelList,
          total: dataOutput.total,
        ),
      );
    } on Exception catch (e) {
      emit(HomePageInfinityScrollFailure(e));
    }
  }

  bool isLoadingMore() {
    final current = state;
    if (current is! HomePageInfinityScrollSuccess) return false;
    return current.isLoadingMore;
  }

  bool hasMoreData() {
    final current = state;
    if (current is! HomePageInfinityScrollSuccess) return false;
    return current.properties.length < current.total;
  }

  Future<void> fetchMore() async {
    final current = state;
    if (current is! HomePageInfinityScrollSuccess) return;
    if (current.isLoadingMore) return;
    if (current.properties.length >= current.total) return;

    emit(current.copyWith(isLoadingMore: true, hasLoadMoreError: false));
    try {
      final dataOutput = await propertyRepository.fetchAllProperties(
        offset: current.properties.length,
      );

      final latest = state;
      if (latest is! HomePageInfinityScrollSuccess) return;

      final existingIds = latest.properties.map((p) => p.id).toSet();
      final newItems = dataOutput.modelList
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
        HomePageInfinityScrollSuccess(
          properties: updated,
          total: dataOutput.total < updated.length
              ? updated.length
              : dataOutput.total,
          offset: updated.length,
        ),
      );
    } on Exception catch (_) {
      final latest = state;
      if (latest is HomePageInfinityScrollSuccess) {
        emit(latest.copyWith(isLoadingMore: false, hasLoadMoreError: true));
      }
    }
  }
}
