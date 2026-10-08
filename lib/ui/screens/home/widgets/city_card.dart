import 'package:ebroker/data/model/city_model.dart';
import 'package:ebroker/exports/main_export.dart';

class CityCard extends StatefulWidget {
  const CityCard({
    required this.city,
    required this.name,
    required this.count,
    required this.isWithImage,
    super.key,
    this.showEndPadding,
  });

  final City city;
  final String count;
  final bool isWithImage;
  final String name;
  final bool? showEndPadding;

  @override
  State<CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<CityCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isWithImage) {
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
          await HelperUtils.navigateToCityProperties(
            context: context,
            cityName: widget.city.name,
          );
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.color.borderColor,
            ),
          ),
          padding: const EdgeInsets.all(12),
          width: 126.rw(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34.rw(context),
                height: 34.rh(context),
                decoration: BoxDecoration(
                  color: context.color.tertiaryColor.withValues(
                    alpha: 0.2,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: CustomImage(
                  imageUrl: AppIcons.location,
                  color: context.color.tertiaryColor,
                  width: 24.rw(context),
                  height: 24.rh(context),
                ),
              ),
              SizedBox(height: 24.rh(context)),
              CustomText(widget.city.name, maxLines: 1),
              SizedBox(height: 8.rh(context)),
              Flexible(
                child: CustomText(
                  '${widget.city.count} ${'properties'.translate(context)}',
                  fontSize: context.font.xs,
                  color: context.color.tertiaryColor,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
        await HelperUtils.navigateToCityProperties(
          context: context,
          cityName: widget.city.name,
        );
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: context.color.secondaryColor,
        ),
        clipBehavior: Clip.antiAlias,
        height: MediaQuery.of(context).size.height * 0.35,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomImage(
                  imageUrl: widget.city.image,
                  height: 100,
                  width: 100,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    CustomText(
                      widget.city.name.firstUpperCase(),
                      fontWeight: FontWeight.bold,
                      fontSize: context.font.md,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    CustomText(
                      '${'properties'.translate(context)} (${widget.city.count})',
                      fontSize: context.font.sm,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
