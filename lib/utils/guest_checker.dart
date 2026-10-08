import 'package:ebroker/app/routes.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/custom_bottom_sheet.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class GuestChecker {
  static final ValueNotifier<bool?> _isGuest = ValueNotifier(
    HiveUtils.isGuest(),
  );
  static BuildContext? _context;

  static void set(String from, {required bool isGuest}) {
    _isGuest.value = isGuest;
  }

  static BuildContext? get context => _context;

  static set context(BuildContext context) {
    _context = context;
  }

  static Future<void> check({required dynamic Function() onNotGuest}) async {
    if (_isGuest.value ?? false) {
      await _loginBox();
    } else {
      await onNotGuest.call();
    }
  }

  static bool get value {
    return _isGuest.value ?? false;
  }

  static ValueNotifier<bool?> listen() {
    return _isGuest;
  }

  static Widget updateUI({
    required dynamic Function({bool? isGuest}) onChangeStatus,
  }) {
    return ValueListenableBuilder<bool?>(
      valueListenable: _isGuest,
      builder: (context, value, c) {
        return onChangeStatus.call(isGuest: value) as Widget? ??
            const SizedBox.shrink();
      },
    );
  }

  static Future<void> _loginBox() async {
    await CustomBottomSheet.show<dynamic>(
      context: _context!,
      enableDrag: false,
      showDragHandle: false,
      borderRadius: 8,
      padding: EdgeInsets.fromLTRB(
        32.rw(_context!),
        24.rh(_context!),
        32.rw(_context!),
        32.rh(_context!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'loginIsRequired'.translate(_context!),
            fontSize: _context!.font.lg,
          ),
          SizedBox(height: 4.rh(_context!)),
          CustomText(
            'tapOnLogin'.translate(_context!),
            fontSize: _context!.font.xs,
          ),
          SizedBox(height: 8.rh(_context!)),
          UiUtils.buildButton(
            _context!,
            autoWidth: true,
            height: 32.rh(_context!),
            fontSize: 14.rf(_context!),
            onPressed: () async {
              Navigator.pop(_context!);
              await Navigator.pushNamed(_context!, Routes.login);
            },
            buttonTitle: 'loginNow'.translate(_context!),
          ),
        ],
      ),
    );
  }
}
