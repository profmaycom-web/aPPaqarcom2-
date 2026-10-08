import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/stories/select_story_listing_screen.dart';
import 'package:ebroker/ui/screens/stories/video_trim_screen.dart';
import 'package:ebroker/ui/screens/stories/widgets/add_story_appbar.dart';
import 'package:ebroker/ui/screens/stories/widgets/listing_gallery_picker_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

const int _maxMediaSizeBytes = 100 * 1024 * 1024;
const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
const List<String> _videoExtensions = ['mp4', 'mov'];

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({required this.entity, super.key});

  final StorySourceEntity entity;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) =>
          AddStoryScreen(entity: args['entity']! as StorySourceEntity),
    );
  }

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  Future<void> _onTapRecord() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: CustomText('photo'.translate(sheetContext)),
              onTap: () => Navigator.pop(sheetContext, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: CustomText('video'.translate(sheetContext)),
              onTap: () => Navigator.pop(sheetContext, 'video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'photo') {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (picked == null || !mounted) return;
      await _onImagePicked(File(picked.path));
    } else {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.camera,
      );
      if (picked == null || !mounted) return;
      await _onVideoPicked(File(picked.path));
    }
  }

  Future<void> _onTapUploadVideo() async {
    final file = await AppFilePicker.pickFile(
      allowedExtensions: _videoExtensions,
    );
    if (file?.path == null) return;
    if (file!.size > _maxMediaSizeBytes) {
      if (mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          'mediaFileTooLarge',
          type: .error,
        );
      }
      return;
    }
    await _onVideoPicked(File(file.path!));
  }

  Future<void> _onTapUploadImage() async {
    final file = await AppFilePicker.pickFile(
      allowedExtensions: _imageExtensions,
    );
    if (file?.path == null) return;
    if (file!.size > _maxMediaSizeBytes) {
      if (mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          'mediaFileTooLarge',
          type: .error,
        );
      }
      return;
    }
    await _onImagePicked(File(file.path!));
  }

  Future<void> _onTapListingGallery() async {
    final file = await ListingGalleryPickerSheet.show(
      context,
      titleImage: widget.entity.image,
      galleryImages: widget.entity.galleryImages,
    );
    if (file == null || !mounted) return;
    await _onImagePicked(file);
  }

  Future<void> _onVideoPicked(File rawVideo) async {
    if (!mounted) return;
    final trimmed = await Navigator.push<TrimmedVideoResult>(
      context,
      MaterialPageRoute(builder: (_) => VideoTrimScreen(rawVideo: rawVideo)),
    );
    if (trimmed == null || !mounted) return;
    await Navigator.pushNamed(
      context,
      Routes.uploadStory,
      arguments: {
        'entity': widget.entity,
        'media': trimmed.file,
        'mediaType': 'video',
        'durationSeconds': trimmed.durationSeconds,
      },
    );
  }

  Future<void> _onImagePicked(File image) async {
    if (!mounted) return;
    if (image.lengthSync() > _maxMediaSizeBytes) {
      HelperUtils.showSnackBarMessage(
        context,
        'mediaFileTooLarge',
        type: .error,
      );
      return;
    }
    await Navigator.pushNamed(
      context,
      Routes.uploadStory,
      arguments: {
        'entity': widget.entity,
        'media': image,
        'mediaType': 'image',
        'durationSeconds': 5,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasListingImages =
        widget.entity.image.isNotEmpty ||
        widget.entity.galleryImages.isNotEmpty;
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.color.textColorDark,
        body: ColoredBox(
          color: context.color.textColorDark,
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const AddStoryAppbar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: .center,
                    spacing: 8.rh(context),
                    children: [
                      SizedBox(height: 32.rh(context)),
                      CustomImage(
                        imageUrl: AppIcons.videoCall,
                        width: 64.rw(context),
                        height: 64.rh(context),
                        color: context.color.buttonColor,
                      ),
                      CustomText(
                        'recordOrUploadStory'.translate(context),
                        fontWeight: .w700,
                        fontSize: context.font.lg,
                        color: context.color.buttonColor,
                      ),
                      CustomText(
                        'recordOrUploadStoryDescription'.translate(context),
                        textAlign: .center,
                        color: context.color.buttonColor,
                      ),
                      CustomText(
                        '${'maxSizeLabel'.translate(context)}: '
                        '${_maxMediaSizeBytes ~/ (1024 * 1024)}MB, '
                        '${'maxDurationLabel'.translate(context)}: '
                        '${AppSettings.storyMaxDurationSeconds}s',
                        textAlign: .center,
                        fontSize: context.font.xs,
                        color: context.color.buttonColor,
                      ),
                    ],
                  ),
                ),
              ),
              _bottomBarOptions(hasListingImages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBarOptions(bool hasListingImages) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: .vertical(top: .circular(16.rw(context))),
      ),
      padding: .symmetric(
        horizontal: 16.rw(context),
        vertical: 14.rw(context),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          Row(
            spacing: 8.rw(context),
            children: [
              Expanded(
                child: _SourceOption(
                  icon: AppIcons.videoCall,
                  label: 'record'.translate(context),
                  onTap: () => unawaited(_onTapRecord()),
                ),
              ),
              Expanded(
                child: _SourceOption(
                  icon: AppIcons.videoCall,
                  label: 'uploadVideo'.translate(context),
                  onTap: () => unawaited(_onTapUploadVideo()),
                ),
              ),
              Expanded(
                child: _SourceOption(
                  icon: AppIcons.gallery,
                  label: 'uploadImage'.translate(context),
                  onTap: () => unawaited(_onTapUploadImage()),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.rh(context)),
          if (hasListingImages) ...[
            UiUtils.buildButton(
              context,
              buttonTitle: 'selectStoryImage'.translate(context),
              onPressed: () => unawaited(_onTapListingGallery()),
            ),
            SizedBox(height: 8.rh(context)),
          ],
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.rh(context)),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CustomImage(
              imageUrl: icon,
              width: 24.rw(context),
              height: 24.rh(context),
              color: context.color.textColorDark,
            ),
            SizedBox(height: 8.rh(context)),
            CustomText(
              label,
              fontSize: context.font.xs,
              textAlign: .center,
            ),
          ],
        ),
      ),
    );
  }
}
