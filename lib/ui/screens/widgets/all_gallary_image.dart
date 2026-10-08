import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class AllGallaryImages extends StatelessWidget {
  const AllGallaryImages({
    required this.images,
    super.key,
    this.youtubeThumbnail,
  });
  final List<dynamic> images;
  final String? youtubeThumbnail;

  bool _isVideoItem(dynamic item) {
    if (item is Gallery) {
      return item.isVideo ?? false;
    }
    if (item is ProjectGalleryModel) {
      return item.isVideo;
    }
    if (item is Map) {
      return item['is_video'] == true;
    }
    return false;
  }

  String _getVideoUrl(dynamic item) {
    if (item is Gallery) {
      return item.image;
    }
    if (item is ProjectGalleryModel) {
      return item.imageUrl;
    }
    if (item is Map) {
      return item['video_url']?.toString() ??
          item['image']?.toString() ??
          item['image_url']?.toString() ??
          '';
    }
    return '';
  }

  String _getImageUrl(dynamic item) {
    if (item is String) {
      return item;
    }
    if (item is Gallery) {
      return item.imageUrl;
    }
    if (item is ProjectGalleryModel) {
      return item.imageUrl;
    }
    if (item is Map) {
      return item['image_url']?.toString() ??
          item['image']?.toString() ??
          '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: 'gallery'.translate(context),
      ),
      body: GridView.builder(
        itemCount: images.length,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemBuilder: (context, index) {
          final item = images[index];
          final isVideo = _isVideoItem(item);

          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GestureDetector(
              onTap: () async {
                if (isVideo) {
                  final videoUrl = _getVideoUrl(item);
                  if (videoUrl.isNotEmpty) {
                    await CustomVideoPlayer.showFullScreenDialog(
                      context,
                      videoUrl: videoUrl,
                    );
                  }
                } else {
                  final stringImages = images
                      .where((e) => !_isVideoItem(e))
                      .map(_getImageUrl)
                      .where((url) => url.trim().isNotEmpty)
                      .toList();

                  final currentTargetUrl = _getImageUrl(item);
                  final targetIndex = stringImages.indexOf(currentTargetUrl);
                  final initialIndex = targetIndex != -1 ? targetIndex : 0;

                  await UiUtils.imageGallaryView(
                    context,
                    images: stringImages,
                    initalIndex: initialIndex,
                    then: () {},
                  );
                }
              },
              child: SizedBox(
                width: 76.rw(context),
                height: 76.rh(context),
                child: isVideo
                    ? Stack(
                        fit: .expand,
                        children: [
                          CustomImage(
                            imageUrl: youtubeThumbnail ?? '',
                          ),
                          const Icon(
                            Icons.play_arrow,
                            size: 28,
                          ),
                        ],
                      )
                    : CustomImage(
                        imageUrl: _getImageUrl(item),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
