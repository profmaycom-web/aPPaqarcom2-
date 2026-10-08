import 'package:ebroker/data/repositories/subscription_repository.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class AssignFreePackageState {}

class AssignFreePackageInitial extends AssignFreePackageState {}

class AssignFreePackageInProgress extends AssignFreePackageState {
  AssignFreePackageInProgress([this.packageId]);
  final int? packageId;
}

class AssignFreePackageSuccess extends AssignFreePackageState {}

class AssignFreePackageFail extends AssignFreePackageState {
  AssignFreePackageFail(this.error);
  final String error;
}

class AssignFreePackageCubit extends Cubit<AssignFreePackageState> {
  AssignFreePackageCubit() : super(AssignFreePackageInitial());

  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository();

  Future<void> assign(
    int packageId,
  ) async {
    try {
      emit(AssignFreePackageInProgress(packageId));
      await _subscriptionRepository.assignFreePackage(
        packageId,
      );
      emit(AssignFreePackageSuccess());
    } on Exception catch (e) {
      emit(AssignFreePackageFail(e.toString()));
    }
  }
}
