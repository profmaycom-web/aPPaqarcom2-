import 'package:ebroker/data/repositories/agents_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ApplyUserVerificationState {}

class ApplyUserVerificationInitial extends ApplyUserVerificationState {}

class ApplyUserVerificationInProgress extends ApplyUserVerificationState {}

class ApplyUserVerificationSuccess extends ApplyUserVerificationState {
  ApplyUserVerificationSuccess(this.response);
  final Map<String, dynamic> response;
}

class ApplyUserVerificationFailure extends ApplyUserVerificationState {
  ApplyUserVerificationFailure(this.errorMessage);
  final String errorMessage;
}

class ApplyUserVerificationCubit extends Cubit<ApplyUserVerificationState> {
  ApplyUserVerificationCubit() : super(ApplyUserVerificationInitial());
  final AgentsRepository _agentsRepository = AgentsRepository();

  Future<void> applyVerification({
    required Map<String, dynamic> parameters,
  }) async {
    try {
      emit(ApplyUserVerificationInProgress());
      final result = await _agentsRepository.applyUserVerification(
        parameters: parameters,
      );
      if (result['error'] == false) {
        emit(ApplyUserVerificationSuccess(result));
      } else {
        emit(ApplyUserVerificationFailure(result['message'].toString()));
      }
    } on Exception catch (e) {
      emit(ApplyUserVerificationFailure(e.toString()));
    }
  }
}
