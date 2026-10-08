import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/properties_data.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/sell_rent_label.dart';
import 'package:ebroker/ui/screens/widgets/like_button_widget.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

class AgentPropertyCard extends StatefulWidget {
  const AgentPropertyCard({
    required this.agentPropertiesData,
    required this.isSelected,
    required this.isSelectable,
    super.key,
    this.onTap,
    this.useRow,
    this.addBottom,
    this.additionalHeight,
    this.statusButton,
    this.onDeleteTap,
    this.showLikeButton,
    this.additionalImageWidth,
    this.heroTag,
  });

  final PropertiesData agentPropertiesData;
  final VoidCallback? onTap;
  final List<Widget>? addBottom;
  final double? additionalHeight;
  final StatusButton? statusButton;
  final bool? useRow;
  final VoidCallback? onDeleteTap;
  final double? additionalImageWidth;
  final bool? showLikeButton;
  final bool isSelected;
  final bool isSelectable;
  final String? heroTag;

  @override
  State<AgentPropertyCard> createState() => _AgentPropertyCardState();
}

class _AgentPropertyCardState extends State<AgentPropertyCard> {
  bool _isNavigating = false;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void dispose() {
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  PropertyModel _toPropertyModel(PropertiesData data) {
    return PropertyModel(
      id: data.id,
      slugId: data.slugId,
      city: data.city,
      state: data.state,
      country: data.country,
      price: data.price,
      propertyType: data.propertyType,
      title: data.title,
      translatedTitle: data.translatedTitle,
      translatedDescription: data.translatedDescription,
      titleImage: data.titleImage,
      isPremium: data.isPremium == '1',
      address: data.address,
      addedBy: data.addedBy,
      promoted: data.promoted,
      isFavourite: data.isFavourite,
      category: Categorys(
        id: data.category.id,
        category: data.category.category,
        image: data.category.image,
        translatedName: data.category.translatedName,
      ),
      rentduration: data.rentduration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentPropertiesData = widget.agentPropertiesData;
    final isSelected = widget.isSelected;
    final onTap = widget.onTap;
    final statusButton = widget.statusButton;
    final showLikeButton = widget.showLikeButton;
    final resolvedHeroTag =
        widget.heroTag ?? 'property-hero-${agentPropertiesData.id}';

    final price = agentPropertiesData.price.priceFormat(
      enabled: Constant.isNumberWithSuffix,
      context: context,
      currencyCode: agentPropertiesData.currencyCode,
      currencySymbol: agentPropertiesData.currencySymbol,
    );

    final isPremium = agentPropertiesData.isPremium == '1';
    final isPromoted = agentPropertiesData.promoted;
    final isAddedByMe = agentPropertiesData.addedBy == HiveUtils.getUserId();
    final isRent =
        agentPropertiesData.propertyType.toLowerCase() == 'rent' ||
        agentPropertiesData.propertyType.toLowerCase() == 'rented';
    final propertyModel = _toPropertyModel(agentPropertiesData);
    final propertyImages = <String>[
      if (propertyModel.titleImage != null &&
          propertyModel.titleImage!.isNotEmpty)
        propertyModel.titleImage!,
      ...?propertyModel.gallery
          ?.where((element) => !(element.isVideo ?? false))
          .map((e) => e.imageUrl)
          .where((url) => url.isNotEmpty),
    ];

    Future<void> openDetails() async {
      await Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {
          'propertyData': propertyModel,
          'fromMyProperty': isAddedByMe,
          'fromAgentDetails': true,
          'heroTag': resolvedHeroTag,
        },
      );
    }

    return BlocProvider(
      create: (context) => AddToFavoriteCubitCubit(),
      child: GestureDetector(
        onTap:
            onTap ??
            () async {
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
                              packageType:
                                  SubscriptionPackageType.premiumProperties,
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
            },
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          height: 122.rh(context),
          decoration: BoxDecoration(
            border: Border.all(
              width: isSelected ? 2 : 1,
              color: isSelected
                  ? context.color.tertiaryColor
                  : context.color.borderColor,
            ),
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
                    width: 112.rw(context),
                    height: double.infinity,
                    dotSize: 4,
                    borderRadius: BorderRadius.circular(4),
                    lowQualityImage: agentPropertiesData.titleImage,
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
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    // Category
                    Row(
                      children: [
                        CustomImage(
                          imageUrl: agentPropertiesData.category.image ?? '',
                          width: 18.rw(context),
                          height: 18.rh(context),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: CustomText(
                            agentPropertiesData.category.translatedName ??
                                agentPropertiesData.category.category ??
                                '',
                            maxLines: 1,
                            fontWeight: .w500,
                            fontSize: context.font.xs,
                            color: context.color.textLightColor,
                          ),
                        ),
                        // Like Button
                        if ((showLikeButton ?? true) && !isAddedByMe)
                          LikeButtonWidget(
                            propertyId: agentPropertiesData.id,
                            isFavourite: agentPropertiesData.isFavourite == '1',
                          ),
                        if (showLikeButton == false && statusButton == null)
                          SizedBox(width: 24.rw(context)),
                        if (statusButton != null)
                          Container(
                            decoration: BoxDecoration(
                              color: statusButton.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: .center,
                              children: [
                                Center(
                                  child: CustomText(
                                    statusButton.lable,
                                    fontWeight: .bold,
                                    fontSize: context.font.xs,
                                    color:
                                        statusButton.textColor ??
                                        context.color.textColorDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Title
                    CustomText(
                      agentPropertiesData.translatedTitle ??
                          agentPropertiesData.title.firstUpperCase(),
                      maxLines: 1,
                      fontSize: context.font.sm,
                      color: context.color.textColorDark,
                    ),
                    // City
                    if (agentPropertiesData.city != '')
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
                              agentPropertiesData.city.trim(),
                              maxLines: 1,
                              fontSize: context.font.xs,
                              fontWeight: .w500,
                              color: context.color.textLightColor,
                            ),
                          ),
                        ],
                      ),
                    // Divider
                    SizedBox(height: 8.rh(context)),
                    Divider(
                      height: 1,
                      endIndent: 0,
                      indent: 0,
                      color: context.color.borderColor,
                    ),
                    // Price & Type
                    SizedBox(height: 8.rh(context)),
                    Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Flexible(
                          child: _buildPrice(
                            context,
                            price,
                            isRent,
                            resolvedHeroTag,
                          ),
                        ),
                        SellRentLabel(
                          propertyType: agentPropertiesData.propertyType,
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
            price +
                ((isRent && widget.agentPropertiesData.rentduration != '')
                    ? ' /'
                    : ''),
            fontWeight: .w600,
            fontSize: context.font.md,
            color: context.color.tertiaryColor,
            maxLines: 1,
          ),
        ),
        if (isRent) ...[
          SizedBox(width: 4.rw(context)),
          CustomText(
            widget.agentPropertiesData.rentduration.translate(context),
            fontWeight: .w600,
            fontSize: context.font.xs,
            color: context.color.tertiaryColor,
          ),
        ],
      ],
    );
  }
}

class StatusButton {
  StatusButton({
    required this.lable,
    required this.color,
    this.textColor,
  });

  final String lable;
  final Color color;
  final Color? textColor;
}
