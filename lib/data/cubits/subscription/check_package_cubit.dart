import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';

abstract class CheckPackageState {}

class CheckPackageInitial extends CheckPackageState {}

class CheckPackageInProgress extends CheckPackageState {}

class CheckPackageSuccess extends CheckPackageState {
  CheckPackageSuccess({required this.isAvailable, required this.packageType});
  final bool isAvailable;
  final PackageType packageType;
}

class CheckPackageFail extends CheckPackageState {
  CheckPackageFail(this.error);
  final String error;
}

class CheckPackageCubit extends Cubit<CheckPackageState> {
  CheckPackageCubit() : super(CheckPackageInitial());

  final CheckPackage _checkPackage = CheckPackage();

  Future<bool> checkAvailability({required PackageType packageType}) async {
    try {
      emit(CheckPackageInProgress());
      final available = await _checkPackage.checkPackageAvailable(
        packageType: packageType,
      );
      emit(
        CheckPackageSuccess(isAvailable: available, packageType: packageType),
      );
      return available;
    } on Exception catch (e) {
      emit(CheckPackageFail(e.toString()));
      return false;
    }
  }
}
