import 'package:ebroker/utils/api.dart';

enum ListingType {
  property('property'),
  project('project');

  const ListingType(this.value);
  final String value;
}

class ListingActivationResult {
  ListingActivationResult({
    required this.success,
    required this.message,
    required this.packageLimitExceeded,
  });

  final bool success;
  final String message;
  final bool packageLimitExceeded;
}

class ListingActivationRepository {
  Future<ListingActivationResult> activate({
    required int id,
    required ListingType type,
  }) async {
    final response = await Api.post(
      url: Api.activateListing,
      parameter: {
        'id': id,
        'listing_type': type.value,
      },
    );

    final isError = response['error'] == true;
    final message = response['message']?.toString() ?? '';
    final packageLimitExceeded =
        isError && message.toLowerCase().contains('package limit');

    return ListingActivationResult(
      success: !isError,
      message: message,
      packageLimitExceeded: packageLimitExceeded,
    );
  }
}
