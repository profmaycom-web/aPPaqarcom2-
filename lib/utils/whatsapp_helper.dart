import 'package:ebroker/settings.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappHelper {
  WhatsappHelper._();

  /// True when the WhatsApp button should render: the app setting is on and
  /// both [mobile] and [countryCode] are present. No fallback to a
  /// mobile-only value — a `wa.me` link without a country code is
  /// ambiguous/broken, so the button simply doesn't render.
  static bool canShow(String? mobile, String? countryCode) {
    return AppSettings.showWhatsappButton &&
        (mobile?.isNotEmpty ?? false) &&
        (countryCode?.isNotEmpty ?? false);
  }

  static Future<void> open(String mobile, String countryCode) async {
    final cleanCountryCode = countryCode.replaceAll(RegExp('[^0-9]'), '');
    final cleanMobile = mobile.replaceAll(RegExp('[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanCountryCode$cleanMobile');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
