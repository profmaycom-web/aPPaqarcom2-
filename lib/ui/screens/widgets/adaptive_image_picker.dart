import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:ebroker/ui/screens/proprties/add_propery_screens/add_property_details.dart';
import 'package:ebroker/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/custom_bottom_sheet.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/custom_validator.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

abstract class ImagePickerValue<T> {
  abstract final T value;
}

class UrlValue extends ImagePickerValue<dynamic> {
  UrlValue(this.value, [this.metaData]);

  @override
  final String value;
  final dynamic metaData;
}

class FileValue extends ImagePickerValue<File> {
  FileValue(this.value, this.fileSize);

  @override
  final File value;
  final FileSize? fileSize;
}

class IdentifyValue extends ImagePickerValue<dynamic> {
  IdentifyValue(this.value) {
    if (value is File) {
      final file = value;
      final fileSizeInBytes = file.lengthSync() as int;

      value = FileValue(file as File, formatFileSize(fileSizeInBytes));
      // value = FileValue(
      //   value,
      // );
    }
    if (value is String) {
      value = UrlValue(value?.toString() ?? '');
    }
  }

  @override
  dynamic value;
}

class MultiValue extends ImagePickerValue<dynamic> {
  MultiValue(this.value);

  @override
  List<ImagePickerValue<dynamic>> value;
}

class FileSize {
  const FileSize({
    required this.bytes,
    required this.kb,
    required this.mb,
    required this.gb,
  });

  final double kb;
  final double mb;
  final double gb;
  final int bytes;

  @override
  String toString() {
    return 'FileSize{kb: $kb, mb: $mb, gb: $gb, bytes: $bytes}';
  }
}

class ImageCount {
  ImageCount(this.min, this.max);

  final int min;
  final int max;
}

class AdaptiveImagePickerWidget extends StatefulWidget {
  const AdaptiveImagePickerWidget({
    required this.onSelect,
    required this.title,
    super.key,
    this.value,
    this.multiImage,
    this.onRemove,
    this.isRequired,
    this.count,
    this.allowedSizeBytes,
    this.compressImage = true,
    this.allowCamera = false,
    this.height,
  });

  final String title;
  final ImageCount? count;
  final int? allowedSizeBytes;
  final bool? isRequired;
  final bool? multiImage;
  final ImagePickerValue<dynamic>? value;
  final double? height;
  final void Function(ImagePickerValue<dynamic>?)?
  onRemove; // Changed to accept null
  final void Function(ImagePickerValue<dynamic>? selected) onSelect;
  final bool compressImage;
  final bool allowCamera;

  @override
  State<AdaptiveImagePickerWidget> createState() =>
      _AdaptiveImagePickerWidgetState();
}

class _AdaptiveImagePickerWidgetState extends State<AdaptiveImagePickerWidget> {
  ImagePicker imagePicker = ImagePicker();

  Widget currentWidget = Container();
  ImagePickerValue<dynamic>? imagePickedValue;

  bool _hasAllowedExtension(String path) {
    final allowedExtensions = <String>{'jpg', 'jpeg', 'png', 'webp'};
    final segments = path.split('.');
    if (segments.length < 2) return false;
    final ext = segments.last.toLowerCase();
    return allowedExtensions.contains(ext);
  }

  Future<void> _showImageError() async {
    await UiUtils.showBlurredDialoge(
      context,
      sigmaX: 5,
      sigmaY: 5,
      dialog: BlurredDialogBox(
        svgImagePath: AppIcons.warning,
        title: 'invalidExtension'.translate(context),
        showCancleButton: false,
        onAccept: () async {},
        acceptTextColor: context.color.buttonColor,
        content: CustomText(
          'supportedFormats'.translate(context),
          textAlign: .center,
        ),
      ),
    );
  }

  Widget? get(ImagePickerValue<dynamic> imagePickerValue) {
    if (imagePickerValue is UrlValue) {
      return Image.network(
        imagePickerValue.value,
        fit: .cover,
      );
    }
    if (imagePickerValue is FileValue) {
      return Image.file(
        imagePickerValue.value,
        fit: .cover,
      );
    }
    if (imagePickerValue is IdentifyValue) {
      return get(
        imagePickerValue.value as ImagePickerValue<dynamic>,
      ); // Access the .value property
    }
    return null; // Explicitly return null for unhandled cases
  }

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      imagePickedValue = widget.value;
    }
  }

  @override
  void didUpdateWidget(covariant AdaptiveImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      imagePickedValue = widget.value;
    }
  }

  dynamic getProvider(ImagePickerValue<dynamic> imagePickerValue) {
    if (imagePickerValue is FileValue) {
      return FileImage(imagePickerValue.value);
    }
    if (imagePickerValue is UrlValue) {
      return NetworkImage(imagePickerValue.value);
    }
    if (imagePickerValue is IdentifyValue) {
      // Fix recursive call by accessing the value property
      return getProvider(imagePickerValue.value as ImagePickerValue<dynamic>);
    }
    return null; // Return null for unhandled cases
  }

  Future<ImageSource?> _showSourceSelector() async {
    return CustomBottomSheet.show<ImageSource>(
      context: context,
      borderRadius: 18,
      padding: EdgeInsets.all(16.rw(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.rh(context),
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            child: SizedBox(
              height: 40.rh(context),
              child: Row(
                spacing: 8.rw(context),
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: context.color.textColorDark,
                  ),
                  CustomText(
                    'gallery'.translate(context),
                    color: context.color.textColorDark,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
            child: SizedBox(
              height: 40.rh(context),
              child: Row(
                spacing: 8.rw(context),
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: context.color.textColorDark,
                  ),
                  CustomText(
                    'camera'.translate(context),
                    color: context.color.textColorDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPick(FormFieldState<dynamic> state) async {
    // _pickTitleImage.pick(pickMultiple: false);
    // titleImageURL = "";

    if (widget.multiImage ?? false) {
      final list = await imagePicker.pickMultiImage();

      final multiImages = <FileValue>[];
      var invalidFound = false;
      for (final e in list) {
        var file = File(e.path);
        if (!_hasAllowedExtension(file.path)) {
          invalidFound = true;
          continue;
        }
        if (widget.compressImage) {
          final compressed = await HelperUtils.compressImageFile(file);
          if (compressed != null) {
            file = compressed;
          }
        }
        final fileSizeInBytes = file.lengthSync();
        multiImages.add(FileValue(file, formatFileSize(fileSizeInBytes)));
      }

      if (imagePickedValue == null) {
        imagePickedValue = MultiValue(multiImages);
      } else {
        final multiValue = imagePickedValue! as MultiValue;
        final list = List<ImagePickerValue<dynamic>>.from(multiValue.value)
          ..addAll(multiImages);
        multiValue.value = list;
      }

      state.didChange(imagePickedValue);

      widget.onSelect(imagePickedValue! as MultiValue);
      setState(() {});
      if (invalidFound) {
        await _showImageError();
      }
      return;
    }
    var source = ImageSource.gallery;
    if (widget.allowCamera) {
      final selectedSource = await _showSourceSelector();
      if (selectedSource == null) return;
      source = selectedSource;
    }
    final xFile = await imagePicker.pickImage(source: source);

    if (xFile != null) {
      var file = File(xFile.path);
      if (!_hasAllowedExtension(file.path)) {
        await _showImageError();
        setState(() {});
        return;
      }
      if (widget.compressImage) {
        final compressed = await HelperUtils.compressImageFile(file);
        if (compressed != null) {
          file = compressed;
        }
      }
      final fileSizeInBytes = file.lengthSync();
      imagePickedValue = FileValue(file, formatFileSize(fileSizeInBytes));
      state.didChange(imagePickedValue);
      widget.onSelect(imagePickedValue! as FileValue);
    }

    setState(() {});
  }

  void _onRemove(
    ImagePickerValue<dynamic>? value,
    FormFieldState<dynamic> state,
  ) {
    if (widget.multiImage ?? false) {
      if (imagePickedValue is MultiValue && value != null) {
        final multiValue = imagePickedValue! as MultiValue;
        final list = List<ImagePickerValue<dynamic>>.from(multiValue.value)
          ..remove(value);
        multiValue.value = list;
        widget.onRemove?.call(value);
      }
      widget.onSelect(imagePickedValue);
    } else {
      imagePickedValue = null;
      state.didChange(null);
      widget.onRemove?.call(null);

      widget.onSelect(null);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (imagePickedValue is MultiValue) {}
    if (imagePickedValue != null) {
      currentWidget = GestureDetector(
        onTap: () async {
          if (imagePickedValue != null) {
            final provider = getProvider(imagePickedValue!);
            if (provider != null) {
              await UiUtils.showFullScreenImage(
                context,
                provider: provider as ImageProvider<Object>,
              );
            }
          }
        },
        child: Column(
          children: [
            Container(
              width: 100.rw(context),
              height: 100.rh(context),
              clipBehavior: .antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              child: imagePickedValue != null
                  ? (get(imagePickedValue!) ?? const SizedBox())
                  : const SizedBox(),
            ),
          ],
        ),
      );
    } else {
      currentWidget = Container();
    }
    return CustomValidator<ImagePickerValue<dynamic>>(
      initialValue: widget.value,
      validator: (value) {
        if (widget.isRequired ?? false) {
          if (value == null) {
            return 'pleasePickImage'.translate(context);
          }
          if (value is MultiValue) {
            if (value.value.isEmpty) {
              return 'pleasePickImage'.translate(context);
            }
          }

          if (value is FileValue) {
            if (!widget.compressImage &&
                widget.allowedSizeBytes != null &&
                value.fileSize != null &&
                value.fileSize!.bytes > widget.allowedSizeBytes!) {
              final size = formatFileSize(widget.allowedSizeBytes!);
              return '${'maxLbl'.translate(context)} ${size.kb ~/ 1}KB ${'yourFileSize'.translate(context)}: ${value.fileSize!.kb ~/ 1}KB';
            }
          }
          if (widget.count != null &&
              (widget.multiImage ?? false) &&
              (widget.isRequired ?? false) &&
              imagePickedValue is MultiValue) {
            final images = (imagePickedValue! as MultiValue).value.length;
            if (widget.count?.min != null && images < widget.count!.min) {
              return '${'minimum'.translate(context)} ${widget.count!.min} ${'imagesRequired'.translate(context)}';
            }

            if (widget.count?.max != null && images > widget.count!.max) {
              return '${'maximum'.translate(context)} ${widget.count!.max} ${'imagesAllowed'.translate(context)}';
            }
          }
        }

        return null;
      },
      builder: (state) {
        return Wrap(
          children: [
            if (imagePickedValue == null)
              DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: state.hasError
                      ? context.color.error
                      : context.color.textLightColor,
                  radius: const Radius.circular(4),
                ),
                child: GestureDetector(
                  onTap: () async {
                    await _onPick(state);
                  },
                  child: Container(
                    clipBehavior: .antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    height: widget.height ?? 48.rh(context),
                    child: CustomText(widget.title),
                  ),
                ),
              ),
            if (imagePickedValue is! MultiValue && imagePickedValue != null)
              Stack(
                children: [
                  currentWidget,
                  closeButton(context, () {
                    _onRemove(null, state);
                  }),
                ],
              ),
            if (imagePickedValue is MultiValue) ...{
              ...(imagePickedValue! as MultiValue).value.map((
                impvalue,
              ) {
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final provider = getProvider(impvalue);
                        if (provider != null) {
                          await UiUtils.showFullScreenImage(
                            context,
                            provider: provider as ImageProvider<Object>,
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsetsDirectional.only(
                              bottom: 8,
                              end: 8,
                            ),
                            width: 100.rw(context),
                            height: 100.rh(context),
                            clipBehavior: .antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: get(impvalue) ?? const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    closeButton(context, () {
                      _onRemove(impvalue, state);
                    }),
                  ],
                );
              }),
            },
            SizedBox(width: 8.rw(context)),
            if (imagePickedValue != null)
              uploadPhotoCard(
                context,
                onTap: () async {
                  await _onPick(state);
                },
              ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
          ],
        );
      },
    );
  }
}

FileSize formatFileSize(int fileSizeInBytes) {
  const kb = 1024;
  const mb = 1024 * kb;
  const gb = 1024 * mb;
  return FileSize(
    bytes: fileSizeInBytes,
    mb: fileSizeInBytes / mb,
    gb: fileSizeInBytes / gb,
    kb: fileSizeInBytes / kb,
  );
}
