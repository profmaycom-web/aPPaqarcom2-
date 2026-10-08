import 'package:ebroker/exports/main_export.dart';

class LocationOutOfCountryDialog {
  static bool _isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      final loc = AppLocalization.of(context);
      final rawTitle = loc?.getTranslatedValues('locationOutOfCountry');
      final title =
          (rawTitle != null &&
              rawTitle.isNotEmpty &&
              rawTitle != 'locationOutOfCountry')
          ? rawTitle
          : 'Location Outside Selected Country';

      final rawDesc = loc?.getTranslatedValues('locationOutOfCountryDesc');
      final desc =
          (rawDesc != null &&
              rawDesc.isNotEmpty &&
              rawDesc != 'locationOutOfCountryDesc')
          ? rawDesc
          : "You cannot use 'Set Your Location' because your current location is outside your selected country.";

      final rawOk = loc?.getTranslatedValues('ok');
      final ok = (rawOk != null && rawOk.isNotEmpty && rawOk != 'ok')
          ? rawOk
          : 'OK';

      await UiUtils.showBlurredDialoge(
        context,
        dialog: BlurredDialogBox(
          title: title,
          content: CustomText(
            desc,
            fontSize: 14,
            color: context.color.textColorDark.withValues(alpha: 0.8),
          ),
          showCancleButton: false,
          acceptButtonName: ok,
          backAllowedButton: true,
        ),
      );
    } finally {
      _isShowing = false;
    }
  }
}
