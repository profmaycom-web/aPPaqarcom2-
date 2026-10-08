import 'package:ebroker/utils/api.dart';

class PaymentIntentRepository {
  Future<Map<String, dynamic>> fetchPaymentIntent({
    required String paymentMethod,
    int? packageId,
    int? payAsYouGoId,
    int? listingId,
    String? listingType,
  }) async {
    final response = await Api.post(
      url: Api.createPaymentIntent,
      parameter: <String, dynamic>{
        'platform_type': 'app',
        'package_id': ?packageId,
        'pay_as_you_go_id': ?payAsYouGoId,
        'listing_id': ?listingId,
        'listing_type': ?listingType,
        'payment_method': paymentMethod,
      },
    );

    if (response['error'] == true) {
      throw Exception(response['message'] ?? 'Failed to create payment intent');
    }

    final data = Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    final intent = Map<String, dynamic>.from(
      data['payment_intent'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );

    if (intent.isEmpty) {
      throw Exception('Payment intent not found');
    }

    return intent;
  }
}
