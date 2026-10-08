import 'package:ebroker/data/repositories/listing_activation_repository.dart';
import 'package:ebroker/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class ListingActivationHandler {
  /// Returns `true` if user navigated away to subscription screen
  /// (caller should skip popping).
  static Future<bool> activate({
    required BuildContext context,
    required int id,
    required ListingType type,
    Future<void> Function()? onSuccess,
  }) async {
    final repo = ListingActivationRepository();
    try {
      final result = await repo.activate(id: id, type: type);
      if (!context.mounted) return false;

      if (result.success) {
        HelperUtils.showSnackBarMessage(
          context,
          result.message.isNotEmpty
              ? result.message
              : 'Listing Activated Successfully',
          type: .success,
        );
        if (onSuccess != null) await onSuccess();
        return false;
      }

      if (result.packageLimitExceeded) {
        final dialogResult = await UiUtils.showBlurredDialoge(
          context,
          dialog: BlurredSubscriptionDialogBox(
            packageType: type == ListingType.property
                ? SubscriptionPackageType.propertyList
                : SubscriptionPackageType.projectList,
            isAcceptContainesPush: true,
            linkedListingId: id,
            linkedListingType: type.value,
            onPaymentSuccess: () async {
              await activate(
                context: context,
                id: id,
                type: type,
                onSuccess: onSuccess,
              );
            },
          ),
        );
        return dialogResult == 'view_plans' ||
            dialogResult == 'bank_transfer_pending';
      }

      HelperUtils.showSnackBarMessage(
        context,
        result.message.isNotEmpty ? result.message : 'somethingWentWrong',
        type: MessageType.error,
      );
      return false;
    } on Exception catch (e) {
      if (!context.mounted) return false;
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: MessageType.error,
      );
      return false;
    }
  }
}
