import 'package:carousel_slider/carousel_slider.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/like_button_widget.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:flutter/material.dart';

class PropertyImageCarousel extends StatelessWidget {
  const PropertyImageCarousel({
    required this.property,
    required this.currentIndex,
    required this.onPageChanged,
    this.galleryItems,
    super.key,
    this.heroTag,
  });

  final PropertyModel property;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final List<Gallery>? galleryItems;
  final String? heroTag;

  void _openFullGallery(BuildContext context, {int initialIndex = 0}) {
    final effectiveGallery =
        galleryItems ?? property.gallery ?? const <Gallery>[];
    final hasTitleInGallery = effectiveGallery.any(
      (g) =>
          g.imageUrl == property.titleImage || g.image == property.titleImage,
    );

    final allImages = <dynamic>[
      if (property.titleImage != null &&
          property.titleImage!.trim().isNotEmpty &&
          !hasTitleInGallery)
        Gallery(
          id: -1,
          image: property.titleImage!,
          imageUrl: property.titleImage!,
        ),
      ...effectiveGallery,
    ];

    if (allImages.isEmpty) return;

    unawaited(
      UiUtils.imageGallaryView(
        context,
        images: allImages,
        initalIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoUrl = property.video?.trim();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    final effectiveGallery =
        galleryItems ?? property.gallery ?? const <Gallery>[];
    final hasTitleInGallery = effectiveGallery.any(
      (g) =>
          g.imageUrl == property.titleImage || g.image == property.titleImage,
    );
    final totalGalleryCount =
        (property.titleImage != null &&
                property.titleImage!.trim().isNotEmpty &&
                !hasTitleInGallery
            ? 1
            : 0) +
        effectiveGallery.length;

    final imageUrls = <String>[
      if (property.titleImage != null && property.titleImage!.isNotEmpty)
        property.titleImage!,
      ...?property.gallery
          ?.where((element) => !(element.isVideo ?? false))
          .map((e) => e.imageUrl),
    ];

    // Build carousel items: title image first, then video (if exists),
    // then remaining images.
    final carouselItems = <Widget>[
      ...imageUrls.asMap().entries.map((entry) {
        Widget image = CustomImage(
          imageUrl: entry.value,
          width: double.infinity,
          height: 218.rs(context),
        );
        // Wrap the first image in a Hero for shared-element transition
        if (entry.key == 0 && heroTag != null) {
          image = Hero(tag: heroTag!, child: image);
        }
        return GestureDetector(
          onTap: () => _openFullGallery(context, initialIndex: currentIndex),
          child: image,
        );
      }),
    ];

    // Insert video after the first image (title image)
    if (hasVideo) {
      final videoWidget = _buildVideoThumbnailItem(videoUrl);
      if (carouselItems.isNotEmpty) {
        carouselItems.insert(1, videoWidget);
      } else {
        carouselItems.add(videoWidget);
      }
    }

    final totalItems = carouselItems.length;

    return SizedBox(
      height: 218.rs(context),
      child: Stack(
        children: [
          if (totalItems > 1)
            Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: !hasVideo,
                    viewportFraction: 1,
                    height: 218.rs(context),
                    onPageChanged: (index, reason) {
                      onPageChanged(index);
                    },
                  ),
                  items: carouselItems,
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: .center,
                    children: List.generate(totalItems, (index) {
                      // Video is at index 1 when images exist, or index 0
                      // when there are no images.
                      final videoIndex = imageUrls.isNotEmpty ? 1 : 0;
                      if (hasVideo && index == videoIndex) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: Colors.white.withValues(
                              alpha: currentIndex == index ? 0.9 : 0.4,
                            ),
                          ),
                        );
                      }

                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          shape: .circle,
                          color: Colors.white.withValues(
                            alpha: currentIndex == index ? 0.9 : 0.4,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            )
          else if (totalItems == 1)
            carouselItems.first
          else
            GestureDetector(
              onTap: () => _openFullGallery(context),
              child: Container(
                alignment: Alignment.center,
                child: CustomImage(
                  imageUrl: property.titleImage ?? '',
                  width: double.infinity,
                  height: 218.rs(context),
                  loadingImageHash: property.lowQualityTitleImage,
                ),
              ),
            ),
          if (totalGalleryCount > 1)
            PositionedDirectional(
              bottom: 12.rh(context),
              end: 16.rw(context),
              child: GestureDetector(
                onTap: () =>
                    _openFullGallery(context, initialIndex: currentIndex),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.rw(context),
                    vertical: 4.rh(context),
                  ),
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.color.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: context.color.textColorDark,
                        size: 14.rs(context),
                      ),
                      SizedBox(width: 4.rw(context)),
                      CustomText(
                        '$totalGalleryCount',
                        color: context.color.textColorDark,
                        fontSize: context.font.xs,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (property.id != null &&
              property.addedBy.toString() != HiveUtils.getUserId())
            PositionedDirectional(
              top: 16.rh(context),
              end: 16.rh(context),
              child: LikeButtonWidget(
                size: 36,
                propertyId: property.id!,
                isFavourite: property.isFavourite == '1',
              ),
            ),
          if (property.isPremium == true ||
              property.allPropData?['is_premium'] == true)
            PositionedDirectional(
              start: 16.rh(context),
              top: 16.rh(context),
              child: Container(
                alignment: Alignment.center,
                child: heroTag != null
                    ? Hero(
                        tag: '$heroTag-premium',
                        child: CustomImage(
                          imageUrl: AppIcons.premium,
                          height: 24.rh(context),
                          width: 24.rw(context),
                        ),
                      )
                    : CustomImage(
                        imageUrl: AppIcons.premium,
                        height: 24.rh(context),
                        width: 24.rw(context),
                      ),
              ),
            ),
          if (property.promoted == true)
            PositionedDirectional(
              bottom: 16.rh(context),
              start: 16.rh(context),
              child: heroTag != null
                  ? Hero(
                      tag: '$heroTag-promoted',
                      child: const PromotedCard(),
                    )
                  : const PromotedCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnailItem(String videoUrl) {
    return CustomVideoPlayer(
      videoUrl: videoUrl,
      autoPlay: true,
    );
  }
}
