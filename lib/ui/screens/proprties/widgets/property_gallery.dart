import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/all_gallary_image.dart';

import 'package:material_ui/material_ui.dart';

class PropertyGallery extends StatelessWidget {
  const PropertyGallery({
    required this.gallary,
    super.key,
  });
  final List<Gallery>? gallary;

  String get _youtubeVideoThumbnail {
    final videoGallery = gallary?.where((e) => e.isVideo ?? false).firstOrNull;
    if (videoGallery != null &&
        HelperUtils.isYoutubeVideo(videoGallery.image)) {
      final id = HelperUtils.getYoutubeVideoId(videoGallery.image);
      if (id != null) {
        return HelperUtils.getYoutubeThumbnail(id);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (gallary?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText(
          'gallery'.translate(context),
          fontWeight: .w600,
          color: context.color.textColorDark,
          fontSize: context.font.md,
        ),
        SizedBox(height: 8.rh(context)),
        SizedBox(
          height: 90.rh(context),
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: .horizontal,
            itemCount: gallary?.length.clamp(0, 5) ?? 0,
            separatorBuilder: (context, index) =>
                SizedBox(width: 8.rw(context)),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (gallary?[index].isVideo ?? false) {
                        return;
                      }

                      final images = gallary?.map((e) => e.imageUrl).toList();

                      await UiUtils.imageGallaryView(
                        context,
                        images: images!,
                        initalIndex: index,
                        then: () {},
                      );
                    },
                    child: SizedBox(
                      width: 90.rw(context),
                      height: 90.rh(context),
                      child: gallary?[index].isVideo ?? false
                          ? CustomImage(imageUrl: _youtubeVideoThumbnail)
                          : CustomImage(
                              imageUrl: gallary?[index].imageUrl ?? '',
                            ),
                    ),
                  ),
                  _buildVideoOverlay(context, index),
                  _buildMoreImagesOverlay(context, index),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoOverlay(BuildContext context, int index) {
    if (!(gallary?[index].isVideo ?? false)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await CustomVideoPlayer.showFullScreenDialog(
            context,
            videoUrl: gallary?[index].image,
          );
        },
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.3),
          child: FittedBox(
            fit: .none,
            child: Container(
              decoration: BoxDecoration(
                shape: .circle,
                color: context.color.tertiaryColor.withValues(alpha: 0.8),
              ),
              width: 30,
              height: 30,
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreImagesOverlay(BuildContext context, int index) {
    if (index != 4 || (gallary?.length ?? 0) <= 5) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            CupertinoPageRoute<dynamic>(
              builder: (context) {
                return AllGallaryImages(
                  youtubeThumbnail: _youtubeVideoThumbnail,
                  images: gallary ?? [],
                );
              },
            ),
          );
        },
        child: Container(
          alignment: Alignment.center,
          color: Colors.black.withValues(alpha: 0.3),
          child: CustomText(
            '+${(gallary?.length ?? 0) - 3}',
            fontWeight: .bold,
            fontSize: context.font.md,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ProjectGallery extends StatelessWidget {
  const ProjectGallery({
    required this.gallary,
    super.key,
  });
  final List<ProjectGalleryModel>? gallary;
  String get _youtubeVideoThumbnail {
    final videoGallery = gallary?.where((e) => e.isVideo).firstOrNull;
    if (videoGallery != null &&
        HelperUtils.isYoutubeVideo(videoGallery.imageUrl)) {
      final id = HelperUtils.getYoutubeVideoId(videoGallery.imageUrl);
      if (id != null) {
        return HelperUtils.getYoutubeThumbnail(id);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (gallary?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText(
          'gallery'.translate(context),
          fontWeight: .w600,
          color: context.color.textColorDark,
          fontSize: context.font.md,
        ),
        SizedBox(height: 8.rh(context)),
        SizedBox(
          height: 90.rh(context),
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: .horizontal,
            itemCount: gallary?.length.clamp(0, 5) ?? 0,
            separatorBuilder: (context, index) =>
                SizedBox(width: 8.rw(context)),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (gallary?[index].isVideo ?? false) {
                        return;
                      }
                      final images = gallary?.map((e) => e.imageUrl).toList();

                      await UiUtils.imageGallaryView(
                        context,
                        images: images!,
                        initalIndex: index,
                        then: () {},
                      );
                    },
                    child: SizedBox(
                      width: 90.rw(context),
                      height: 90.rh(context),
                      child: gallary?[index].isVideo ?? false
                          ? CustomImage(imageUrl: _youtubeVideoThumbnail)
                          : CustomImage(
                              imageUrl: gallary?[index].imageUrl ?? '',
                            ),
                    ),
                  ),
                  _buildVideoOverlay(context, index),
                  _buildMoreImagesOverlay(context, index),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreImagesOverlay(BuildContext context, int index) {
    if (index != 4 || (gallary?.length ?? 0) <= 5) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            CupertinoPageRoute<dynamic>(
              builder: (context) {
                return AllGallaryImages(
                  youtubeThumbnail: '',
                  images: gallary ?? [],
                );
              },
            ),
          );
        },
        child: Container(
          alignment: Alignment.center,
          color: Colors.black.withValues(alpha: 0.3),
          child: CustomText(
            '+${(gallary?.length ?? 0) - 3}',
            fontWeight: .bold,
            fontSize: context.font.md,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoOverlay(BuildContext context, int index) {
    if (!(gallary?[index].isVideo ?? false)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await CustomVideoPlayer.showFullScreenDialog(
            context,
            videoUrl: gallary?[index].imageUrl,
          );
        },
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.3),
          child: FittedBox(
            fit: .none,
            child: Container(
              decoration: BoxDecoration(
                shape: .circle,
                color: context.color.tertiaryColor.withValues(alpha: 0.8),
              ),
              width: 30,
              height: 30,
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
