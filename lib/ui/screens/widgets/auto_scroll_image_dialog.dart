import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class AutoScrollImageDialog extends StatefulWidget implements BlurDialoge {
  const AutoScrollImageDialog({
    required this.images,
    this.autoScrollDuration = const Duration(seconds: 2),
    this.title,
    this.category,
    this.type,
    this.location,
    super.key,
  });

  final List<String> images;
  final Duration autoScrollDuration;
  final String? title;
  final String? category;
  final String? type;
  final String? location;

  @override
  State<AutoScrollImageDialog> createState() => _AutoScrollImageDialogState();
}

class _AutoScrollImageDialogState extends State<AutoScrollImageDialog> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  static const int _kInitialPageMultiplier = 1000;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.images.length > 1
        ? _kInitialPageMultiplier * widget.images.length
        : 0;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = 350.rs(context);

    return Container(
      width: dialogWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          SizedBox(
            height: 193.rs(context),
            child: Stack(
              children: [
                // Auto-scrolling PageView
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (widget.images.isEmpty) return;
                    final realIndex =
                        (index % widget.images.length + widget.images.length) %
                        widget.images.length;
                    setState(() {
                      _currentIndex = realIndex;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (widget.images.isEmpty) return const SizedBox.shrink();
                    final realIndex =
                        (index % widget.images.length + widget.images.length) %
                        widget.images.length;
                    final imageUrl = widget.images[realIndex];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        unawaited(
                          UiUtils.imageGallaryView(
                            context,
                            images: widget.images,
                            initalIndex: realIndex,
                          ),
                        );
                      },
                      child: CustomImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    );
                  },
                ),

                // Bottom Indicator dots
                if (widget.images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? context.color.tertiaryColor
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.category != null && widget.category!.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 16,
                    left: 16,
                    child: CustomText(
                      widget.category!,
                      maxLines: 1,
                      color: context.color.tertiaryColor,
                      fontSize: 12.rf(context),
                      fontWeight: .w500,
                    ),
                  ),
              ],
            ),
          ),
          if ((widget.title != null && widget.title!.isNotEmpty) ||
              (widget.type != null && widget.type!.isNotEmpty) ||
              (widget.location != null && widget.location!.isNotEmpty))
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 14.rw(context),
                vertical: 12.rh(context),
              ),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
              ),
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  if (widget.category != null && widget.category!.isNotEmpty ||
                      widget.type != null && widget.type!.isNotEmpty)
                    SizedBox(height: 4.rh(context)),
                  if (widget.title != null && widget.title!.isNotEmpty) ...[
                    CustomText(
                      widget.title!,
                      maxLines: 1,

                      color: context.color.textColorDark,
                      fontSize: 15.rf(context),
                      fontWeight: .bold,
                    ),

                    SizedBox(height: 4.rh(context)),
                  ],
                  if (widget.location != null &&
                      widget.location!.isNotEmpty) ...[
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
                            widget.location!,
                            maxLines: 1,
                            color: context.color.textLightColor,
                            fontSize: 12.rf(context),
                          ),
                        ),
                        if (widget.type != null && widget.type!.isNotEmpty) ...[
                          SizedBox(width: 8.rw(context)),
                          Container(
                            padding: .symmetric(
                              horizontal: 8.rw(context),
                              vertical: 3.rh(context),
                            ),
                            decoration: BoxDecoration(
                              color: context.color.tertiaryColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: .circular(6),
                            ),
                            child: CustomText(
                              widget.type!.translate(context),

                              color: context.color.tertiaryColor,
                              fontSize: 10.rf(context),
                              fontWeight: .bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
