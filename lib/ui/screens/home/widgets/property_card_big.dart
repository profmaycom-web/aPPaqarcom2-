import 'package:ebroker/data/cubits/property/fetch_compare_properties_cubit.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/sell_rent_label.dart';
import 'package:ebroker/ui/screens/widgets/like_button_widget.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

class PropertyCardBig extends StatefulWidget {
  const PropertyCardBig({
    required this.property,
    required this.isFromCompare,
    required this.isFromGrid,
    this.sourceProperty,
    super.key,
    this.isFirst,
    this.showEndPadding,
    this.showLikeButton,
    this.disableTap,
    this.showFeatured,
    this.heroTag,
  });

  final PropertyModel property;
  final bool isFromCompare;
  final bool isFromGrid;
  final PropertyModel? sourceProperty;
  final bool? isFirst;
  final bool? showEndPadding;
  final bool? showLikeButton;
  final bool? disableTap;
  final bool? showFeatured;
  final String? heroTag;

  @override
  State<PropertyCardBig> createState() => _PropertyCardBigState();
}

class _PropertyCardBigState extends State<PropertyCardBig> {
  bool _isNavigating = false;
  bool _isComparing = false;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void dispose() {
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final isFromCompare = widget.isFromCompare;
    final sourceProperty = widget.sourceProperty;
    final showLikeButton = widget.showLikeButton;
    final disableTap = widget.disableTap;
    final showFeatured = widget.showFeatured;
    final resolvedHeroTag = widget.heroTag ?? 'property-hero-${property.id}';

    final price = (property.price != null && property.price!.isNotEmpty)
        ? property.price!.priceFormat(
            enabled: Constant.isNumberWithSuffix,
            context: context,
            currencyCode: property.currencyCode,
            currencySymbol: property.currencySymbol,
          )
        : '';
    final isPremium = property.isPremium ?? false;
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
        property: property,
        fromMyProperty: isAddedByMe,
        heroTag: resolvedHeroTag,
      );
    }

    Future<void> handleCardTap() async {
      if (_isNavigating) return;
      if (disableTap ?? false) return;

      // final hasInternet = await HelperUtils.checkInternet();

      // if (!hasInternet) {
      //   return HelperUtils.showSnackBarMessage(
      //     context,
      //     'noInternet',
      //     type: .error,
      //   );
      // }

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

                if (_checkPackageCubit.state is CheckPackageFail) {
                  if (context.mounted) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      (_checkPackageCubit.state as CheckPackageFail).error,
                      type: .error,
                    );
                  }
                  return;
                }

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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: handleCardTap,
      child: Container(
        padding: EdgeInsets.all(8.rh(context)),
        width: widget.isFromGrid ? 254.rw(context) : 290.rw(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.color.secondaryColor,
          border: Border.all(
            color: context.color.borderColor,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Stack(
                  children: [
                    ProjectImageSwiper(
                      images: propertyImages,
                      heroTag: resolvedHeroTag,
                      width: double.infinity,
                      height: widget.isFromGrid
                          ? 96.rh(context)
                          : 132.rh(context),
                      borderRadius: BorderRadius.circular(4),
                      lowQualityImage: property.lowQualityTitleImage,
                      onTap: handleCardTap,
                    ),

                    if (isPromoted || (showFeatured ?? false))
                      const PositionedDirectional(
                        end: 10,
                        bottom: 10,
                        child: PromotedCard(),
                      ),
                  ],
                ),
                SizedBox(height: 8.rh(context)),
                Row(
                  children: [
                    CustomImage(
                      imageUrl: property.category?.image ?? '',
                      color: context.color.textLightColor,
                      width: 18.rw(context),
                      height: 18.rh(context),
                    ),
                    SizedBox(width: 4.rw(context)),
                    Expanded(
                      child: CustomText(
                        property.category?.translatedName ??
                            property.category?.category ??
                            '',
                        fontWeight: .w600,
                        fontSize: context.font.xs,
                        color: context.color.textLightColor,
                        maxLines: 1,
                      ),
                    ),
                    if (isPremium) ...[
                      SizedBox(width: 4.rw(context)),
                      CustomText(
                        'premium'.translate(context),
                        color: Colors.orangeAccent,
                        fontSize: context.font.xxs,
                        fontWeight: .w600,
                      ),
                      SizedBox(width: 4.rw(context)),
                      CustomImage(
                        imageUrl: AppIcons.premium,
                        height: 18.rh(context),
                        width: 18.rw(context),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8.rh(context)),
                CustomText(
                  property.translatedTitle ?? property.title ?? '',
                  maxLines: 1,
                  fontSize: context.font.md,
                  fontWeight: .w600,
                  color: context.color.textColorDark,
                ),
                if (property.city != '') ...[
                  SizedBox(height: 8.rh(context)),
                  Row(
                    mainAxisSize: .min,
                    children: [
                      CustomImage(
                        imageUrl: AppIcons.location,
                        height: 18.rh(context),
                        width: 18.rw(context),
                        color: context.color.textLightColor,
                      ),
                      SizedBox(width: 5.rw(context)),
                      CustomText(
                        property.city ?? '',
                        maxLines: 1,
                        color: context.color.textLightColor,
                        fontSize: context.font.xs,
                        fontWeight: .w400,
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 8.rh(context)),
                UiUtils.getDivider(context),
                SizedBox(height: 8.rh(context)),
                Row(
                  crossAxisAlignment: .start,
                  children: [
                    Expanded(
                      child: _buildPrice(
                        context,
                        price,
                        isRent,
                        resolvedHeroTag,
                      ),
                    ),
                    SellRentLabel(
                      propertyType: isRent ? 'rent' : 'sell',
                    ),
                  ],
                ),
                if (isFromCompare) ...[
                  SizedBox(height: 8.rh(context)),
                  UiUtils.getDivider(context),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: UiUtils.buildButton(
                          context,
                          onPressed: handleCardTap,
                          buttonTitle: 'viewProperty'.translate(context),
                          buttonColor: context.color.secondaryColor,
                          border: BorderSide(
                            color: context.color.tertiaryColor,
                          ),
                          textColor: context.color.tertiaryColor,
                          fontSize: context.font.sm,
                          height: 44.rh(context),
                        ),
                      ),
                      SizedBox(
                        width: 8.rw(context),
                      ),
                      Expanded(
                        child: UiUtils.buildButton(
                          context,
                          isInProgress: _isComparing,
                          onPressed: () async {
                            if (_isComparing) return;
                            Future<void> runCompare() async {
                              if (!mounted) return;
                              setState(() {
                                _isComparing = true;
                              });
                              try {
                                if (sourceProperty?.id == null ||
                                    property.id == null) {
                                  if (mounted) {
                                    setState(() {
                                      _isComparing = false;
                                    });
                                    HelperUtils.showSnackBarMessage(
                                      context,
                                      'somethingWentWrong',
                                      type: .error,
                                    );
                                  }
                                  return;
                                }

                                // Get a property to compare with
                                final targetPropertyId = property.id!;

                                // Fetch comparison data using the cubit
                                final comparePropertiesCubit =
                                    FetchComparePropertiesCubit();
                                await comparePropertiesCubit
                                    .fetchCompareProperties(
                                      sourcePropertyId: sourceProperty!.id!,
                                      targetPropertyId: targetPropertyId,
                                    );

                                final state = comparePropertiesCubit.state;

                                if (!mounted) return;

                                if (state is FetchComparePropertiesSuccess) {
                                  setState(() {
                                    _isComparing = false;
                                  });
                                  final sourcePropertyData = sourceProperty;
                                  final targetPropertyData = property;

                                  // Navigate to compare property screen with the fetched data
                                  await HelperUtils.goToNextPage(
                                    Routes.comparePropertiesScreen,
                                    context,
                                    false,
                                    args: {
                                      'comparisionData': state.comparisionData,
                                      'category': property.category,
                                      'isSourcePremium':
                                          sourcePropertyData.isPremium ==
                                              true ||
                                          sourcePropertyData
                                                  .allPropData?['is_premium'] ==
                                              true ||
                                          sourcePropertyData
                                                  .allPropData?['is_premium'] ==
                                              1 ||
                                          sourcePropertyData
                                                  .allPropData?['is_premium'] ==
                                              '1',
                                      'isTargetPremium':
                                          targetPropertyData.isPremium ==
                                              true ||
                                          targetPropertyData
                                                  .allPropData?['is_premium'] ==
                                              true ||
                                          targetPropertyData
                                                  .allPropData?['is_premium'] ==
                                              1 ||
                                          targetPropertyData
                                                  .allPropData?['is_premium'] ==
                                              '1',
                                      'isSourcePromoted':
                                          sourcePropertyData.promoted ?? false,
                                      'isTargetPromoted':
                                          targetPropertyData.promoted ?? false,
                                    },
                                  );
                                } else if (state
                                    is FetchComparePropertiesFailure) {
                                  setState(() {
                                    _isComparing = false;
                                  });
                                  final msg = state.errorMessage.toLowerCase();
                                  if (msg.contains('package') ||
                                      msg.contains('subscription') ||
                                      msg.contains('subscribe')) {
                                    await UiUtils.showBlurredDialoge(
                                      context,
                                      dialog:
                                          const BlurredSubscriptionDialogBox(
                                            packageType: SubscriptionPackageType
                                                .premiumProperties,
                                          ),
                                    );
                                  } else {
                                    HelperUtils.showSnackBarMessage(
                                      context,
                                      state.errorMessage.isNotEmpty
                                          ? state.errorMessage
                                          : 'somethingWentWrong'.translate(
                                              context,
                                            ),
                                      type: .error,
                                    );
                                  }
                                } else {
                                  setState(() {
                                    _isComparing = false;
                                  });
                                  HelperUtils.showSnackBarMessage(
                                    context,
                                    'somethingWentWrong',
                                    type: .error,
                                  );
                                }
                              } on Object catch (e) {
                                if (mounted) {
                                  setState(() {
                                    _isComparing = false;
                                  });
                                  HelperUtils.showSnackBarMessage(
                                    context,
                                    e.toString(),
                                    type: .error,
                                  );
                                }
                              } finally {
                                if (mounted && _isComparing) {
                                  setState(() {
                                    _isComparing = false;
                                  });
                                }
                              }
                            }

                            if (isPremium) {
                              await GuestChecker.check(
                                onNotGuest: runCompare,
                              );
                            } else {
                              await runCompare();
                            }
                          },
                          buttonTitle: 'compareProperty'.translate(context),
                          height: 44.rh(context),
                          fontSize: context.font.sm,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if ((showLikeButton ?? true) && !isAddedByMe)
              PositionedDirectional(
                end: 4.rw(context),
                top: 4.rh(context),
                child: SizedBox(
                  height: 34.rh(context),
                  width: 34.rw(context),
                  child: LikeButtonWidget(
                    propertyId: property.id!,
                    isFavourite: property.isFavourite == '1',
                    backgroundColor: Colors.black26,
                  ),
                ),
              ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          price,
          fontWeight: .w500,
          fontSize: context.font.md,
          maxLines: 1,
          color: context.color.tertiaryColor,
        ),
        if (isRent) ...[
          SizedBox(width: 4.rw(context)),
          CustomText(
            '${isRent ? ' /' : ''}${widget.property.rentduration?.toLowerCase().translate(context)}',
            fontWeight: .w500,
            maxLines: 1,
            fontSize: context.font.xxs,
            color: context.color.tertiaryColor,
          ),
        ],
      ],
    );
  }
}
