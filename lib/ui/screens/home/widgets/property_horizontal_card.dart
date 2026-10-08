import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/advertisement_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/sell_rent_label.dart';
import 'package:ebroker/ui/screens/widgets/like_button_widget.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/utils/price_format.dart';

class PropertyHorizontalCard extends StatefulWidget {
  const PropertyHorizontalCard({
    required this.property,
    this.advertisement,
    this.properties,
    super.key,
    this.statusButton,
    this.showDeleteButton,
    this.showLikeButton,
    this.additionalImageWidth,
    this.isFromSearch,
    this.disableTap,
    this.showFeatured,
    this.heroTag,
  });

  final PropertyModel property;
  final AdvertisementProperty? advertisement;
  final List<PropertyModel>? properties;
  final StatusButton? statusButton;
  final bool? showDeleteButton;
  final double? additionalImageWidth;
  final bool? showLikeButton;
  final bool? isFromSearch;
  final bool? disableTap;
  final bool? showFeatured;
  final String? heroTag;

  @override
  State<PropertyHorizontalCard> createState() => _PropertyHorizontalCardState();
}

class _PropertyHorizontalCardState extends State<PropertyHorizontalCard> {
  bool _isNavigating = false;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void dispose() {
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final statusButton = widget.statusButton;
    final showLikeButton = widget.showLikeButton;
    final resolvedHeroTag = widget.heroTag ?? 'property-hero-${property.id}';

    final price = property.price!.priceFormat(
      enabled: Constant.isNumberWithSuffix,
      context: context,
      currencyCode: property.currencyCode,
      currencySymbol: property.currencySymbol,
    );

    final isPremium =
        property.isPremium == true ||
        property.allPropData?['is_premium'] == true;
    final isPromoted = property.promoted ?? false;
    final isAddedByMe = property.addedBy.toString() == HiveUtils.getUserId();
    final isRent = property.propertyType.toString().toLowerCase() == 'rent';

    final propertyImages = <String>[
      if (property.titleImage != null && property.titleImage!.isNotEmpty)
        property.titleImage!,
      ...?property.gallery
          ?.where((element) => !(element.isVideo ?? false))
          .map((e) => e.imageUrl)
          .where((url) => url.isNotEmpty),
    ];

    Future<void> openDetails() async {
      await PropertyDetailsScreen.open(
        context,
        property: widget.property,
        fromMyProperty: isAddedByMe,
        heroTag: resolvedHeroTag,
      );
    }

    Future<void> handleCardTap() async {
      if (_isNavigating) return;
      if (widget.disableTap ?? false) return;
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
        if (isPremium) {
          await GuestChecker.check(
            onNotGuest: () async {
              if (isAddedByMe) {
                await openDetails();
              } else {
                final packageAvailable = await _checkPackageCubit
                    .checkAvailability(
                      packageType: PackageType.premiumProperties,
                    );
                if (packageAvailable) {
                  await openDetails();
                } else {
                  await UiUtils.showBlurredDialoge(
                    context,
                    dialog: const BlurredSubscriptionDialogBox(
                      packageType: SubscriptionPackageType.premiumProperties,
                      isAcceptContainesPush: true,
                    ),
                  );
                }
              }
            },
          );
        } else {
          await openDetails();
        }
      } on Exception catch (_) {
        // Property navigation errors are handled by the shared helper flow.
      } finally {
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
      }
    }

    return BlocProvider(
      create: (context) => AddToFavoriteCubitCubit(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleCardTap,
        child: Container(
          padding: EdgeInsets.all(8.rh(context)),
          height: 132.rh(context),
          decoration: BoxDecoration(
            border: Border.all(color: context.color.borderColor),
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ProjectImageSwiper(
                    images: propertyImages,
                    heroTag: resolvedHeroTag,
                    width: 127.rw(context),
                    height: double.infinity,
                    dotSize: 4,
                    borderRadius: BorderRadius.circular(4),
                    lowQualityImage: property.lowQualityTitleImage,
                    onTap: handleCardTap,
                  ),
                  if (isPremium)
                    PositionedDirectional(
                      start: 4.rw(context),
                      top: 4.rh(context),
                      child: CustomImage(
                        imageUrl: AppIcons.premium,
                        height: 24.rh(context),
                        width: 24.rw(context),
                      ),
                    ),
                  if (isPromoted)
                    PositionedDirectional(
                      end: 4.rw(context),
                      bottom: 4.rh(context),
                      child: const PromotedCard(iconOnly: true),
                    ),
                ],
              ),
              SizedBox(width: 8.rw(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    // Category
                    Row(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          child: CustomImage(
                            imageUrl: property.category?.image ?? '',
                            color: context.color.textLightColor,
                            width: 18.rw(context),
                            height: 18.rh(context),
                          ),
                        ),
                        SizedBox(width: 4.rw(context)),
                        Expanded(
                          child: CustomText(
                            property.category?.translatedName ??
                                property.category?.category ??
                                '',
                            maxLines: 1,
                            fontWeight: .w500,
                            fontSize: context.font.xxs,
                            color: context.color.textLightColor,
                          ),
                        ),
                        // Like Button
                        if ((showLikeButton ?? true) && !isAddedByMe)
                          LikeButtonWidget(
                            propertyId: property.id!,
                            isFavourite: property.isFavourite == '1',
                          )
                        else if (isAddedByMe)
                          CustomText(
                            property.isExpired ?? false
                                ? 'expired'.translate(context)
                                : UiUtils.getExpiryCountdown(
                                    context,
                                    property.expiryDate,
                                  ),
                            fontSize: context.font.xxs,
                            fontWeight: .w500,
                            color: context.color.textLightColor,
                          ),
                      ],
                    ),
                    SizedBox(height: 8.rh(context)),
                    // Title
                    CustomText(
                      property.translatedTitle ??
                          property.title?.firstUpperCase() ??
                          '',
                      maxLines: 1,
                      fontWeight: .w400,
                      fontSize: context.font.sm,
                      color: context.color.textColorDark,
                    ),
                    SizedBox(height: 4.rh(context)),
                    // City
                    if (property.city != '')
                      Row(
                        children: [
                          CustomImage(
                            imageUrl: AppIcons.location,
                            width: 18.rw(context),
                            height: 18.rh(context),
                            color: context.color.textLightColor,
                          ),
                          SizedBox(width: 4.rw(context)),
                          Expanded(
                            child: CustomText(
                              property.city?.trim() ?? '',
                              maxLines: 1,
                              fontSize: context.font.xs,
                              fontWeight: .w400,
                              color: context.color.textLightColor,
                            ),
                          ),
                        ],
                      ),
                    // Divider
                    SizedBox(height: 8.rh(context)),
                    UiUtils.getDivider(context),
                    SizedBox(height: 8.rh(context)),
                    // Price & Type
                    Row(
                      children: [
                        Expanded(
                          child: _buildPrice(
                            context,
                            price,
                            isRent,
                            resolvedHeroTag,
                          ),
                        ),
                        if (statusButton != null && property.isExpired != true)
                          Container(
                            height: 24.rh(context),
                            decoration: BoxDecoration(
                              color: statusButton.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: .center,
                              children: [
                                Center(
                                  child: CustomText(
                                    statusButton.lable,
                                    fontWeight: .bold,
                                    fontSize: context.font.xxs,
                                    color:
                                        statusButton.textColor ??
                                        context.color.textColorDark,
                                  ),
                                ),
                                if (property.editReason != null &&
                                    property.editReason!.isNotEmpty) ...[
                                  SizedBox(width: 8.rw(context)),
                                  GestureDetector(
                                    onTap: () async {
                                      await UiUtils.showBlurredDialoge(
                                        context,
                                        dialog: BlurredDialogBox(
                                          acceptTextColor:
                                              context.color.buttonColor,
                                          showCancleButton: false,
                                          title: 'editedByAdmin'.translate(
                                            context,
                                          ),
                                          content: CustomText(
                                            property.editReason ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                    child: CustomImage(
                                      imageUrl: AppIcons.info,
                                      width: 18.rw(context),
                                      height: 18.rh(context),
                                      color: statusButton.textColor,
                                    ),
                                  ),
                                ],
                                if (property.requestStatus.toString() ==
                                    'rejected') ...[
                                  SizedBox(width: 8.rw(context)),
                                  GestureDetector(
                                    onTap: () async {
                                      await UiUtils.showBlurredDialoge(
                                        context,
                                        dialog: BlurredDialogBox(
                                          acceptTextColor:
                                              context.color.buttonColor,
                                          showCancleButton: false,
                                          title: statusButton.lable,
                                          content: CustomText(
                                            property.rejectReason?.reason
                                                    .toString() ??
                                                '',
                                          ),
                                        ),
                                      );
                                    },
                                    child: CustomImage(
                                      imageUrl: AppIcons.info,
                                      width: 18.rw(context),
                                      height: 18.rh(context),
                                      color: statusButton.textColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else if (property.isExpired != true)
                          SellRentLabel(
                            propertyType: property.propertyType.toString(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrice(
    BuildContext context,
    String price,
    bool isRent,
    String resolvedHeroTag,
  ) {
    return Row(
      crossAxisAlignment: .end,
      children: [
        Flexible(
          child: CustomText(
            price + (isRent ? ' /' : ''),
            fontWeight: .w500,
            fontSize: context.font.md,
            color: context.color.tertiaryColor,
            maxLines: 1,
          ),
        ),
        if (isRent) ...[
          SizedBox(width: 4.rw(context)),
          Flexible(
            child: CustomText(
              '${widget.property.rentduration?.toLowerCase().translate(context)}',
              fontWeight: .w500,
              maxLines: 1,
              fontSize: context.font.xxs,
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ],
    );
  }
}

class StatusButton {
  StatusButton({required this.lable, required this.color, this.textColor});

  final String lable;
  final Color color;
  final Color? textColor;
}
