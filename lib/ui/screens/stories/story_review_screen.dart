import 'package:ebroker/data/cubits/stories/upload_story_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/stories/select_story_listing_screen.dart';
import 'package:ebroker/ui/screens/stories/widgets/add_story_appbar.dart';
import 'package:ebroker/ui/screens/widgets/image_cropper.dart';
import 'package:material_ui/material_ui.dart';

const int _maxThumbnailSizeBytes = 5 * 1024 * 1024;
const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

class StoryReviewScreen extends StatefulWidget {
  const StoryReviewScreen({
    required this.entity,
    required this.media,
    required this.mediaType,
    required this.durationSeconds,
    super.key,
  });

  final StorySourceEntity entity;
  final File media;
  final String mediaType;

  /// Always sent explicitly on upload (5 for images, trimmed length for
  /// video) so the viewer never needs to fall back to a default.
  final int durationSeconds;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) => StoryReviewScreen(
        entity: args['entity']! as StorySourceEntity,
        media: args['media']! as File,
        mediaType: args['mediaType']! as String,
        durationSeconds: args['durationSeconds']! as int,
      ),
    );
  }

  @override
  State<StoryReviewScreen> createState() => _StoryReviewScreenState();
}

class _StoryReviewScreenState extends State<StoryReviewScreen> {
  File? _thumbnail;
  late File _media = widget.media;

  bool get _isImage => widget.mediaType == 'image';

  Future<void> _onTapCrop() async {
    CropImage.context = context;
    final cropped = await CropImage.crop(
      filePath: _media.path,
      aspectRatio: null,
      lockAspectRatio: false,
    );
    if (cropped == null || !mounted) return;
    setState(() => _media = File(cropped.path));
  }

  Future<void> _pickThumbnail() async {
    final file = await AppFilePicker.pickFile(
      allowedExtensions: _imageExtensions,
    );
    if (file?.path == null) return;
    if (file!.size > _maxThumbnailSizeBytes) {
      if (mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          'thumbnailFileTooLarge',
          type: .error,
        );
      }
      return;
    }
    setState(() => _thumbnail = File(file.path!));
  }

  void _onTapSubmit() {
    unawaited(
      context.read<UploadStoryCubit>().upload(
        media: _media,
        mediaType: widget.mediaType,
        entityType: widget.entity.entityType,
        entityId: widget.entity.entityId,
        durationSeconds: widget.durationSeconds,
        thumbnail: _thumbnail,
      ),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.color.textColorDark,
        body: Column(
          children: [
            AddStoryAppbar(
              actionIcon: widget.mediaType == 'video'
                  ? Icons.image_outlined
                  : null,
              actionLabel: widget.mediaType == 'video'
                  ? 'thumbnail'.translate(context)
                  : null,
              onActionTap: widget.mediaType == 'video'
                  ? () => unawaited(_pickThumbnail())
                  : null,
              actions: _isImage
                  ? [
                      AddStoryIconAction(
                        icon: Icons.crop,
                        onTap: () => unawaited(_onTapCrop()),
                      ),
                    ]
                  : null,
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.mediaType == 'video')
                      CustomVideoPlayer(videoFile: widget.media)
                    else
                      Image.file(
                        _media,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    if (_thumbnail != null)
                      PositionedDirectional(
                        end: 16.rw(context),
                        bottom: 16.rh(context),
                        child: Container(
                          clipBehavior: .hardEdge,
                          decoration: BoxDecoration(
                            borderRadius: .circular(8.rw(context)),
                          ),
                          height: 178.rh(context),
                          width: 100.rw(context),
                          child: Image.file(
                            _thumbnail!,
                            fit: .fill,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _bottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _bottomSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.color.buttonColor,
        borderRadius: .vertical(top: .circular(16.rw(context))),
      ),
      padding: .all(16.rw(context)),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              if (widget.entity.image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImage(
                    imageUrl: widget.entity.image,
                    width: 48.rw(context),
                    height: 48.rh(context),
                  ),
                ),
              if (widget.entity.image.isNotEmpty)
                SizedBox(width: 12.rw(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            widget.entity.title,
                            fontWeight: FontWeight.w600,
                            fontSize: context.font.sm,
                            maxLines: 1,
                          ),
                        ),
                        if (widget.entity.propertyType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.color.tertiaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: CustomText(
                              widget.entity.propertyType,
                              fontSize: context.font.xxs,
                              color: context.color.tertiaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (widget.entity.address.isNotEmpty) ...[
                      SizedBox(height: 4.rh(context)),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14.rw(context),
                            color: context.color.textLightColor,
                          ),
                          SizedBox(width: 4.rw(context)),
                          Expanded(
                            child: CustomText(
                              widget.entity.address,
                              fontSize: context.font.xs,
                              color: context.color.textLightColor,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.rh(context)),
          UiUtils.buildButton(
            context,
            buttonTitle: 'uploadStory'.translate(context),
            onPressed: _onTapSubmit,
          ),
        ],
      ),
    );
  }
}
