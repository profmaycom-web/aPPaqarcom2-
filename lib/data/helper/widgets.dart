import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class Widgets {
  static bool isLoaderShowing = false;
  static BuildContext? _loaderDialogContext;
  static bool _pendingDismiss = false;

  static Future<void> showLoader(BuildContext? context) async {
    if (context == null || !context.mounted) return;
    if (isLoaderShowing) return;

    try {
      isLoaderShowing = true;
      _pendingDismiss = false;

      await showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          _loaderDialogContext = dialogContext;
          if (_pendingDismiss) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            });
          }
          return SafeArea(
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Center(
                child: UiUtils.progress(
                  normalProgressColor: context.color.tertiaryColor,
                ),
              ),
            ),
          );
        },
      );
    } on Object catch (e) {
      debugPrint('Error showing loader: $e');
    } finally {
      isLoaderShowing = false;
      _loaderDialogContext = null;
      _pendingDismiss = false;
    }
  }

  static void hideLoader(BuildContext? context) {
    if (!isLoaderShowing) return;

    _pendingDismiss = true;

    if (_loaderDialogContext != null && _loaderDialogContext!.mounted) {
      try {
        Navigator.of(_loaderDialogContext!).pop();
      } on Object catch (e) {
        debugPrint('Error dismissing loader via dialogContext: $e');
      }
      _loaderDialogContext = null;
      isLoaderShowing = false;
      return;
    }

    isLoaderShowing = false;
  }

  // Keeping old method for backward compatibility
  static void hideLoder(BuildContext? context) {
    hideLoader(context);
  }

  static Center noDataFound(String errorMsg) {
    return Center(child: CustomText(errorMsg));
  }
}
