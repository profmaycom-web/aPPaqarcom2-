import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:material_ui/material_ui.dart';

//This will open image crop SDK
class CropImage {
  static BuildContext? _context;

  static BuildContext? get context => _context;

  static set context(BuildContext context) {
    _context = context;
  }

  static Future<CroppedFile?>? crop({
    required String filePath,
    CropAspectRatio? aspectRatio = const CropAspectRatio(ratioX: 1, ratioY: 1),
    bool lockAspectRatio = true,
  }) async {
    if (_context == null) {
      return null;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      aspectRatio: aspectRatio,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: _context!.color.tertiaryColor,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: false,
          activeControlsWidgetColor: _context!.color.tertiaryColor,
          lockAspectRatio: lockAspectRatio,
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioLockEnabled: lockAspectRatio,
        ),
        WebUiSettings(
          context: _context!,
        ),
      ],
    );

    return croppedFile;
  }
}
