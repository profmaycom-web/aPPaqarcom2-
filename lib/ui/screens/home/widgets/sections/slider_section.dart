import 'package:carousel_slider/carousel_slider.dart';
import 'package:ebroker/data/model/home_slider.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/custom_open_container.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class SliderSection extends StatelessWidget {
  const SliderSection({required this.banners, super.key});

  static const double _sidePadding = 18;

  final List<HomeSlider> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SliverToBoxAdapter();
    final directionalBanners = Directionality.of(context) == .rtl
        ? banners.reversed.toList()
        : banners;
    return SliverToBoxAdapter(
      child: Column(
        children: <Widget>[
          SizedBox(height: 15.rh(context)),
          CarouselSlider(
            items: directionalBanners
                .map((banner) => _SliderBanner(banner: banner))
                .toList(),
            options: CarouselOptions(
              height: 170.rs(context),
              viewportFraction: 1,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {},
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderBanner extends StatefulWidget {
  const _SliderBanner({required this.banner});

  final HomeSlider banner;

  @override
  State<_SliderBanner> createState() => _SliderBannerState();
}

class _SliderBannerState extends State<_SliderBanner> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;
    final childWidget = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SliderSection._sidePadding,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomImage(
          imageUrl: banner.image.toString(),
          width: context.screenWidth,
        ),
      ),
    );

    if (banner.sliderType == '3' && banner.property != null) {
      final isAddedByMe =
          banner.property!.addedBy.toString() == HiveUtils.getUserId();

      return CustomOpenContainer(
        openBuilder: (context, closeContainer) {
          return PropertyDetails.buildWithProviders(
            property: banner.property!,
            fromMyProperty: isAddedByMe,
          );
        },
        closedBuilder: (context, openContainer) {
          return GestureDetector(
            onTap: () async {
              if (_isNavigating) return;
              final hasInternet = await HelperUtils.checkInternet();

              if (!hasInternet) {
                return HelperUtils.showSnackBarMessage(
                  context,
                  'noInternet',
                  type: .error,
                );
              }

              setState(() {
                _isNavigating = true;
              });
              openContainer();
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    _isNavigating = false;
                  });
                }
              });
            },
            child: childWidget,
          );
        },
      );
    }

    if (banner.sliderType == '3') {
      // Fallback: banner.property is null, fetch via the standard helper.
      return GestureDetector(
        onTap: () async {
          if (_isNavigating) return;
          final hasInternet = await HelperUtils.checkInternet();
          if (!hasInternet) {
            return HelperUtils.showSnackBarMessage(
              context,
              'noInternet',
              type: .error,
            );
          }
          setState(() {
            _isNavigating = true;
          });
          try {
            await HelperUtils.loadAndNavigateToPropertyDetails(
              context: context,
              propertyId: int.parse(banner.propertysId!),
              isMyProperty:
                  banner.property?.addedBy.toString() == HiveUtils.getUserId(),
              showLoader: true,
            );
          } on Exception {
            await Fluttertoast.showToast(
              msg: 'pageNotFoundErrorMsg'.translate(context),
            );
          } finally {
            if (mounted) {
              setState(() {
                _isNavigating = false;
              });
            }
          }
        },
        child: childWidget,
      );
    }

    return GestureDetector(
      onTap: () async {
        if (banner.sliderType == '1') {
          await UiUtils.showFullScreenImage(
            context,
            provider: NetworkImage(banner.image.toString()),
          );
        } else if (banner.sliderType == '2') {
          await Navigator.pushNamed(
            context,
            Routes.propertiesList,
            arguments: {
              'catID': banner.categoryId,
              'catName':
                  banner.category!.translatedName ?? banner.category!.category,
            },
          );
        } else if (banner.sliderType == '4') {
          await url_launcher.launchUrl(Uri.parse(banner.link!));
        }
      },
      child: childWidget,
    );
  }
}
