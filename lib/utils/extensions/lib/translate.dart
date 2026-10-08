import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/app/app_localization.dart';

extension TranslateString on String {
  String translate(BuildContext context) {
    return (AppLocalization.of(context)!.getTranslatedValues(this) ?? this)
        .trim();
  }
}
