import 'package:ebroker/exports/main_export.dart';

abstract class RenewListingState {}

class RenewListingInitial extends RenewListingState {}

class RenewListingInProgress extends RenewListingState {}

class RenewListingSuccess extends RenewListingState {
  RenewListingSuccess(this.message);
  final String message;
}

class RenewListingFailure extends RenewListingState {
  RenewListingFailure(this.errorMessage);
  final String errorMessage;
}

class RenewListingCubit extends Cubit<RenewListingState> {
  RenewListingCubit() : super(RenewListingInitial());

  Future<void> renew({required int id, required String type}) async {
    try {
      emit(RenewListingInProgress());
      final response = await Api.post(
        url: Api.apiRenewListing,
        parameter: {'id': id, Api.type: type},
      );
      if (response['error'] == true) {
        emit(RenewListingFailure(response['message']?.toString() ?? ''));
        return;
      }
      final message =
          response['message']?.toString() ?? 'Listing Renewed Successfully';
      emit(RenewListingSuccess(message));
    } on Exception catch (e) {
      emit(RenewListingFailure(e.toString()));
    }
  }
}
