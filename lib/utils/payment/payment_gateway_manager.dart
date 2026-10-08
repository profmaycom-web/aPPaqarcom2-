import 'package:ebroker/data/cubits/payment/payment_intent_cubit.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/payment/lib/purchase_package.dart';
import 'package:ebroker/utils/payment/payment_webview_screen.dart';

class PaymentGatewayManager {
  factory PaymentGatewayManager() => _instance;
  PaymentGatewayManager._internal();
  // Singleton pattern
  static final PaymentGatewayManager _instance =
      PaymentGatewayManager._internal();

  /// Main method to initiate payment. Returns `true` on successful payment.
  Future<bool> pay({
    required BuildContext context,
    required String paymentMethod,
    SubscriptionPackageModel? package,
    PayAsYouGoModel? payAsYouGo,
    int? listingId,
    String? listingType,
  }) async {
    try {
      // 1. Create Payment Intent
      final paymentIntent = await context
          .read<PaymentIntentCubit>()
          .createIntent(
            paymentMethod: paymentMethod.toLowerCase(),
            packageId: package?.id,
            payAsYouGoId: payAsYouGo?.id,
            listingId: listingId,
            listingType: listingType,
          );

      if (paymentIntent == null) {
        throw ApiException('Failed to create payment intent');
      }

      final paymentUrl = paymentIntent['payment_url']?.toString();

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw ApiException('Payment URL is missing from response');
      }

      // 2. Open WebView
      final result = await Navigator.push<bool>(
        context,
        CupertinoPageRoute(
          builder: (context) => PaymentWebViewScreen(
            url: paymentUrl,
            gateway: paymentMethod,
          ),
        ),
      );

      // 3. Handle Result
      if (result ?? false) {
        // Success
        await PurchasePackage().purchase(
          context,
          popToRoot: payAsYouGo == null,
        );
        return true;
      } else {
        // Failure or Cancel
        HelperUtils.showSnackBarMessage(
          context,
          'purchaseFailed', // Loc key
          type: MessageType.error,
        );
      }
    } on Exception catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: MessageType.error,
      );
    }
    return false;
  }
}
