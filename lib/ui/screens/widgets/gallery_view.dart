import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/ui/screens/widgets/custom_video_player.dart';
import 'package:ebroker/utils/admob/interstitial_ad_manager.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/material.dart';

class GalleryViewWidget extends StatefulWidget {
  const GalleryViewWidget({
    required this.images,
    required this.initalIndex,
    super.key,
  });
  final List<dynamic> images;
  final int initalIndex;

  @override
  State<GalleryViewWidget> createState() => _GalleryViewWidgetState();
}

class _GalleryViewWidgetState extends State<GalleryViewWidget> {
  List<dynamic> images = [];
  late PageController controller;
  late ScrollController _thumbController;
  late int page;
  final InterstitialAdManager admanager = InterstitialAdManager();

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
      return item.imageUrl.isNotEmpty ? item.imageUrl : item.image;
    }
    if (item is ProjectGalleryModel) {
      return item.imageUrl;
    }
    if (item is Map) {
      return item['image_url']?.toString() ?? item['image']?.toString() ?? '';
    }
    return '';
  }

  String _getYoutubeThumbnail(dynamic item) {
    final videoUrl = _getVideoUrl(item);
    if (videoUrl.isNotEmpty && HelperUtils.isYoutubeVideo(videoUrl)) {
      final id = HelperUtils.getYoutubeVideoId(videoUrl);
      if (id != null) {
        return HelperUtils.getYoutubeThumbnail(id);
      }
    }
    return '';
  }

  @override
  void initState() {
    super.initState();

    images = List.from(widget.images)
      ..removeWhere((e) => e == null || (e is String && e.trim().isEmpty));

    final validIndex = widget.initalIndex.clamp(
      0,
      images.isEmpty ? 0 : images.length - 1,
    );
    page = validIndex;
    controller = PageController(initialPage: validIndex);
    _thumbController = ScrollController();
    unawaited(admanager.load());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToThumbnail(validIndex);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  void _scrollToThumbnail(int index) {
    if (!_thumbController.hasClients) return;
    if (_thumbController.position.maxScrollExtent <= 0) return;
    final itemWidth = 56.rw(context) + 8.rw(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset =
        (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _thumbController.animateTo(
      targetOffset.clamp(0.0, _thumbController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildThumbnailItem(int index, double itemWidth) {
    final item = images[index];
    final isSelected = index == page;
    final isVideo = _isVideoItem(item);
    final thumbUrl = isVideo ? _getYoutubeThumbnail(item) : _getImageUrl(item);

    return GestureDetector(
      onTap: () {
        controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: itemWidth,
        height: 64.rh(context),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? context.color.tertiaryColor
                : context.color.borderColor,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: isSelected ? 1.0 : 0.5,
                child: thumbUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => ColoredBox(
                          color: context.color.secondaryColor,
                          child: Icon(
                            Icons.image,
                            color: context.color.textLightColor,
                            size: 20,
                          ),
                        ),
                      )
                    : ColoredBox(
                        color: context.color.secondaryColor,
                        child: Icon(
                          Icons.image,
                          color: context.color.textLightColor,
                          size: 20,
                        ),
                      ),
              ),
              if (isVideo)
                Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: context.color.tertiaryColor,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          if (images.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.rw(context),
                vertical: 4.rh(context),
              ),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.color.borderColor,
                ),
              ),
              child: CustomText(
                '${page + 1} / ${images.length}',
                color: context.color.textColorDark,
                fontWeight: FontWeight.w600,
                fontSize: context.font.sm,
              ),
            ),
        ],
      ),
      backgroundColor: context.color.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              onPageChanged: (value) async {
                setState(() {
                  page = value;
                });
                _scrollToThumbnail(value);
                if (page.isEven) {
                  await admanager.show();
                }
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                final item = images[index];
                if (_isVideoItem(item)) {
                  final videoUrl = _getVideoUrl(item);
                  final thumbUrl = _getYoutubeThumbnail(item);
                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (thumbUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: thumbUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        GestureDetector(
                          onTap: () async {
                            await CustomVideoPlayer.showFullScreenDialog(
                              context,
                              videoUrl: videoUrl,
                            );
                          },
                          child: Container(
                            width: 64.rw(context),
                            height: 64.rh(context),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.color.tertiaryColor.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final imageUrl = _getImageUrl(item);
                return InteractiveViewer(
                  maxScale: 5,
                  minScale: 1,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: context.color.tertiaryColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: context.color.textLightColor,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Bottom Thumbnails Strip
          if (images.length > 1)
            Container(
              height: 64.rh(context),
              width: double.infinity,
              alignment: .center,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 12,
                top: 16,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = 64.rw(context);
                  final horizontalPadding = 16.rw(context);

                  return SingleChildScrollView(
                    controller: _thumbController,
                    scrollDirection: Axis.horizontal,
                    physics: Constant.scrollPhysics,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Row(
                      spacing: 8.rw(context),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (index) {
                        return _buildThumbnailItem(index, itemWidth);
                      }),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
