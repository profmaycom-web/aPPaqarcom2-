import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/data/repositories/property_repository.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchMyPropertiesState {}

class FetchMyPropertiesInitial extends FetchMyPropertiesState {}

class FetchMyPropertiesInProgress extends FetchMyPropertiesState {}

class FetchMyPropertiesSuccess extends FetchMyPropertiesState {
  FetchMyPropertiesSuccess({
    required this.total,
    required this.offset,
    required this.isLoadingMore,
    required this.hasError,
    required this.myProperty,
    this.refreshing = false,
  });
  final int total;
  final int offset;
  final bool isLoadingMore;
  final bool hasError;
  final List<PropertyModel> myProperty;
  bool refreshing;

  FetchMyPropertiesSuccess copyWith({
    int? total,
    int? offset,
    bool? isLoadingMore,
    bool? hasMoreData,
    List<PropertyModel>? myProperty,
    bool? refreshing,
  }) {
    return FetchMyPropertiesSuccess(
      total: total ?? this.total,
      offset: offset ?? this.offset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasMoreData ?? hasError,
      myProperty: myProperty ?? this.myProperty,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class FetchMyPropertiesFailure extends FetchMyPropertiesState {
  FetchMyPropertiesFailure(this.errorMessage, {this.errorKey});
  final String errorMessage;
  final String? errorKey;
}

class FetchMyPropertiesCubit extends Cubit<FetchMyPropertiesState> {
  FetchMyPropertiesCubit() : super(FetchMyPropertiesInitial());

  final PropertyRepository _propertyRepository = PropertyRepository();
  Future<void> fetchMyProperties({
    required String type,
    required String requestStatus,
    required String status,
  }) async {
    try {
      if (state is FetchMyPropertiesSuccess &&
          (state as FetchMyPropertiesSuccess).myProperty.isNotEmpty) {
        emit((state as FetchMyPropertiesSuccess).copyWith(refreshing: true));
      } else {
        emit(FetchMyPropertiesInProgress());
      }

      final result = await _propertyRepository.fetchMyProperties(
        offset: 0,
        type: type,
        requestStatus: requestStatus,
        status: status,
      );
      emit(
        FetchMyPropertiesSuccess(
          hasError: false,
          isLoadingMore: false,
          myProperty: result.modelList,
          total: result.total,
          offset: 0,
        ),
      );
    } on ApiException catch (e) {
      emit(FetchMyPropertiesFailure(e.errorMessage));
    }
  }

  void updateStatus(int propertyId, String currentType) {
    try {
      if (state is FetchMyPropertiesSuccess) {
        final propertyList = (state as FetchMyPropertiesSuccess).myProperty;
        final index = propertyList.indexWhere((element) {
          return element.id == propertyId;
        });

        if (currentType.toLowerCase() == 'sell') {
          propertyList[index].propertyType = 'sell';
        }
        if (currentType.toLowerCase() == 'rent') {
          propertyList[index].propertyType = 'rent';
        }

        if (currentType.toLowerCase() == 'sold') {
          propertyList[index].propertyType = 'sold';
        }
        if (currentType.toLowerCase() == 'rented') {
          propertyList[index].propertyType = 'rented';
        }

        emit(
          (state as FetchMyPropertiesSuccess).copyWith(
            myProperty: propertyList,
          ),
        );
      }
    } on Exception catch (e) {
      emit(FetchMyPropertiesFailure(e.toString()));
    }
  }

  void update(PropertyModel model) {
    if (state is FetchMyPropertiesSuccess) {
      final properties = (state as FetchMyPropertiesSuccess).myProperty;

      final index = properties.indexWhere((element) => element.id == model.id);

      if (index != -1) {
        properties[index] = model;
      }

      emit(
        (state as FetchMyPropertiesSuccess).copyWith(myProperty: properties),
      );
    }
  }

  Future<void> fetchMoreProperties({
    required String type,
    required String requestStatus,
    required String status,
  }) async {
    try {
      if (state is FetchMyPropertiesSuccess) {
        if ((state as FetchMyPropertiesSuccess).isLoadingMore) {
          return;
        }

        final currentState = state as FetchMyPropertiesSuccess;
        emit(currentState.copyWith(isLoadingMore: true));

        final result = await _propertyRepository.fetchMyProperties(
          offset: currentState.myProperty.length,
          type: type,
          requestStatus: requestStatus,
          status: status,
        );

        final updatedProperties = [
          ...currentState.myProperty,
          ...result.modelList,
        ];

        emit(
          FetchMyPropertiesSuccess(
            isLoadingMore: false,
            hasError: false,
            myProperty: updatedProperties,
            offset: updatedProperties.length,
            total: result.total,
          ),
        );
      }
    } on Exception catch (_) {
      if (state is FetchMyPropertiesSuccess) {
        emit(
          (state as FetchMyPropertiesSuccess).copyWith(
            isLoadingMore: false,
            hasMoreData: true, // Fixed from hasMoreData to hasError
          ),
        );
      }
    }
  }

  bool hasMoreData() {
    if (state is FetchMyPropertiesSuccess) {
      return (state as FetchMyPropertiesSuccess).myProperty.length <
          (state as FetchMyPropertiesSuccess).total;
    }
    return false;
  }

  bool isLoadingMore() {
    if (state is FetchMyPropertiesSuccess) {
      return (state as FetchMyPropertiesSuccess).isLoadingMore;
    }
    return false;
  }

  void clear() {
    emit(FetchMyPropertiesInitial());
  }
}
