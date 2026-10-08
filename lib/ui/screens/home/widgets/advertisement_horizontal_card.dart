import 'package:ebroker/data/cubits/delete_advertisment_cubit.dart';
import 'package:ebroker/data/cubits/project/delete_project_cubit.dart';
import 'package:ebroker/data/cubits/project/fetch_my_promoted_projects.dart';
import 'package:ebroker/data/cubits/property/fetch_my_promoted_propertys_cubit.dart';
import 'package:ebroker/data/cubits/property/renew_listing_cubit.dart';
import 'package:ebroker/data/model/advertisement_model.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/sell_rent_label.dart';
import 'package:ebroker/ui/screens/widgets/custom_open_container.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

/// Base class for advertisement cards with common UI structure
abstract class BaseAdvertisementHorizontalCard extends StatelessWidget {
  const BaseAdvertisementHorizontalCard({
    super.key,
    this.statusButton,
    this.showDeleteButton,
    this.onDeleteTap,
    this.showLikeButton,
    this.isPromoted,
    this.isPremium,
  });

  final StatusButton? statusButton;
  final bool? showDeleteButton;
  final VoidCallback? onDeleteTap;
  final bool? showLikeButton;
  final bool? isPromoted;
  final bool? isPremium;

  // Abstract methods to be implemented by subclasses

  String get rentduration;

  String get advertisementId;

  String get itemId;

  String get titleImage;

  String get itemType;

  String get categoryImage;

  String get categoryName;

  String get price;

  String get title;

  String get city;

  String get status;

  // Abstract methods for actions
  void onCardTap(BuildContext context);

  void onShareAction(BuildContext context);

  void onDeleteSuccess(BuildContext context);

  String? get resolvedHeroTag => null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onShareAction(context),
      onTap: () => onCardTap(context),
      child: Container(
        padding: EdgeInsets.all(8.rw(context)),
        height: 126.rh(context),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.color.borderColor,
          ),
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8.rw(context)),
        ),
        child: Stack(
          fit: .expand,
          children: [
            Row(
              children: [
                _buildImageSection(context),
                SizedBox(width: 12.rw(context)),
                _buildInfoSection(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CustomImage(
        imageUrl: titleImage,
        height: double.infinity,
        width: 124.rw(context),
      ),
    );
    if (resolvedHeroTag != null) {
      image = Hero(
        tag: resolvedHeroTag!,
        child: image,
      );
    }
    return Stack(
      children: [
        image,
        if (isPremium ?? false)
          PositionedDirectional(
            start: 4.rw(context),
            top: 4.rh(context),
            child: resolvedHeroTag != null
                ? Hero(
                    tag: '$resolvedHeroTag-premium',
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
        if (isPromoted ?? false)
          PositionedDirectional(
            start: 4.rw(context),
            bottom: 4.rh(context),
            child: resolvedHeroTag != null
                ? Hero(
                    tag: '$resolvedHeroTag-promoted',
                    child: const PromotedCard(iconOnly: true),
                  )
                : const PromotedCard(iconOnly: true),
          ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              CustomImage(
                imageUrl: categoryImage,
                color: context.color.textLightColor,
                width: 18.rw(context),
                height: 18.rh(context),
              ),
              const SizedBox(
                width: 4,
              ),
              Expanded(
                child: resolvedHeroTag != null
                    ? Hero(
                        tag: '$resolvedHeroTag-category',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CustomText(
                            categoryName,
                            maxLines: 1,
                            fontWeight: .w400,
                            fontSize: context.font.xxs,
                            color: context.color.textLightColor,
                          ),
                        ),
                      )
                    : CustomText(
                        categoryName,
                        maxLines: 1,
                        fontWeight: .w400,
                        fontSize: context.font.xxs,
                        color: context.color.textLightColor,
                      ),
              ),
              if (statusButton != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusButton!.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  height: 20.rh(context),
                  child: Center(
                    child: CustomText(
                      statusButton!.lable,
                      fontWeight: .bold,
                      fontSize: context.font.xxs,
                      color: statusButton?.textColor ?? Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.rh(context)),
          // Title
          if (resolvedHeroTag != null)
            Hero(
              tag: '$resolvedHeroTag-title',
              child: Material(
                type: MaterialType.transparency,
                child: CustomText(
                  title.firstUpperCase(),
                  maxLines: 1,
                  fontSize: context.font.sm,
                  color: context.color.textColorDark,
                ),
              ),
            )
          else
            CustomText(
              title.firstUpperCase(),
              maxLines: 1,
              fontSize: context.font.sm,
              color: context.color.textColorDark,
            ),
          SizedBox(height: 4.rh(context)),
          // City
          if (city != '')
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
                    city.trim(),
                    maxLines: 1,
                    fontSize: context.font.xs,
                    fontWeight: .w500,
                    color: context.color.textLightColor,
                  ),
                ),
              ],
            ),
          // Divider
          SizedBox(height: 6.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 6.rh(context)),
          // Price & Type
          if (itemType.toLowerCase() == 'rent' ||
              itemType.toLowerCase() == 'sell')
            Row(
              children: [
                Expanded(
                  child: _buildPrice(
                    context,
                    price.priceFormat(context: context),
                    itemType.toLowerCase() == 'rent',
                  ),
                ),
                SellRentLabel(
                  propertyType: itemType.toLowerCase() == 'rent'
                      ? 'rent'
                      : 'sell',
                ),
                if (showDeleteButton ?? false) SizedBox(width: 4.rw(context)),
                if (showDeleteButton ?? false) _buildDeleteButton(context),
              ],
            )
          else
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                if (resolvedHeroTag != null)
                  Hero(
                    tag: '$resolvedHeroTag-type',
                    child: Material(
                      type: MaterialType.transparency,
                      child: CustomText(
                        itemType.toLowerCase().translate(context),
                        fontWeight: .w600,
                        fontSize: context.font.xs,
                        color: context.color.tertiaryColor,
                      ),
                    ),
                  )
                else
                  CustomText(
                    itemType.toLowerCase().translate(context),
                    fontWeight: .w600,
                    fontSize: context.font.xs,
                    color: context.color.tertiaryColor,
                  ),
                if (showDeleteButton ?? false) _buildDeleteButton(context),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPrice(BuildContext context, String price, bool isRent) {
    return Row(
      crossAxisAlignment: .end,
      children: [
        Flexible(
          
          child: resolvedHeroTag != null
              ? Hero(
                  tag: '$resolvedHeroTag-price',
                  child: Material(
                    type: MaterialType.transparency,
                    child: CustomText(
                      price +
                          (isRent
                              ? ' / ${rentduration.toLowerCase().translate(context)}'
                              : ''),
                      fontWeight: .w600,
                      maxLines: 1,
                      fontSize: context.font.sm,
                      color: context.color.tertiaryColor,
                    ),
                  ),
                )
              : CustomText(
                  price +
                      (isRent
                          ? ' / ${rentduration.toLowerCase().translate(context)}'
                          : ''),
                  fontWeight: .w600,
                  maxLines: 1,
                  fontSize: context.font.sm,
                  color: context.color.tertiaryColor,
                ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return BlocConsumer<DeleteAdvertismentCubit, DeleteAdvertismentState>(
      listener: (context, state) {
        if (state is DeleteAdvertismentSuccess) {
          onDeleteSuccess(context);
        }
      },
      builder: (context, state) {
        if (status != '1') {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTap: () async {
            await UiUtils.showBlurredDialoge(
              context,
              dialog: BlurredDialogBox(
                title: 'deleteBtnLbl'.translate(context),
                onAccept: () async {
                  if (AppSettings.isDemoModeOn) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      'thisActionNotValidDemo',
                      type: .error,
                    );
                  } else {
                    await context.read<DeleteAdvertismentCubit>().delete(
                      advertisementId,
                    );
                  }
                },
                content: CustomText(
                  'confirmDeleteAdvert'.translate(context),
                ),
              ),
            );
          },
          child: Container(
            width: 24.rw(context),
            height: 24.rh(context),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.color.error.withValues(alpha: 0.1),
              shape: .circle,
            ),
            child: CustomImage(
              imageUrl: AppIcons.delete,
              color: context.color.error,
            ),
          ),
        );
      },
    );
  }
}

/// Advertisement Card For Property
class MyAdvertisementPropertyHorizontalCard
    extends BaseAdvertisementHorizontalCard {
  const MyAdvertisementPropertyHorizontalCard({
    required this.advertisement,
    required this.isPropertyPromoted,
    required this.isPropertyPremium,
    super.key,
    super.statusButton,
    super.showDeleteButton,
    super.onDeleteTap,
    super.showLikeButton,
    this.heroTag,
  });

  final AdvertisementProperty? advertisement;
  final bool isPropertyPromoted;
  final bool isPropertyPremium;
  final String? heroTag;

  @override
  String get rentduration => advertisement?.property.rentduration ?? '';

  @override
  String get advertisementId => advertisement?.id.toString() ?? '';

  @override
  String get itemId => advertisement?.propertyId ?? '';

  @override
  String get titleImage => advertisement?.property.titleImage ?? '';

  @override
  String get itemType => advertisement?.property.propertyType ?? '';

  @override
  String get categoryImage => advertisement?.property.category?.image ?? '';

  @override
  String get categoryName => advertisement?.property.category?.category ?? '';

  @override
  String get price => advertisement?.property.price ?? '';

  @override
  String get title => advertisement?.property.title ?? '';

  @override
  String get city => advertisement?.property.city ?? '';

  @override
  String get status => advertisement?.status ?? '';

  @override
  bool get isPremium => isPropertyPremium;

  @override
  bool get isPromoted => isPropertyPromoted;

  @override
  String? get resolvedHeroTag =>
      heroTag ?? 'property-hero-${advertisement?.property.id}';

  @override
  Future<void> onShareAction(BuildContext context) async {
    await HelperUtils.share(
      context,
      advertisement?.property.slugId ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final deleteCubit = context.read<DeleteAdvertismentCubit>();
    final resolvedHeroTag =
        heroTag ?? 'property-hero-${advertisement?.property.id}';

    return CustomOpenContainer(
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.rw(context))),
      ),
      openBuilder: (context, closeContainer) {
        return PropertyDetails.buildWithProviders(
          property: advertisement?.property ?? PropertyModel(),
          fromMyProperty: true,
          heroTag: resolvedHeroTag,
        );
      },
      closedBuilder: (context, openContainer) {
        return BlocProvider.value(
          value: deleteCubit,
          child: Builder(
            builder: (innerContext) {
              return GestureDetector(
                onLongPress: () => onShareAction(innerContext),
                onTap: () async {
                  final hasInternet = await HelperUtils.checkInternet();

                  if (!hasInternet) {
                    return HelperUtils.showSnackBarMessage(
                      innerContext,
                      'noInternet',
                      type: .error,
                    );
                  }
                  openContainer();
                },
                child: Container(
                  padding: EdgeInsets.all(8.rw(innerContext)),
                  height: 126.rh(innerContext),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: innerContext.color.borderColor,
                    ),
                    color: innerContext.color.secondaryColor,
                    borderRadius: BorderRadius.circular(8.rw(innerContext)),
                  ),
                  child: Stack(
                    fit: .expand,
                    children: [
                      Row(
                        children: [
                          _buildImageSection(innerContext),
                          SizedBox(width: 12.rw(innerContext)),
                          _buildInfoSection(innerContext),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void onCardTap(BuildContext context) {}

  @override
  void onDeleteSuccess(BuildContext context) {
    unawaited(
      context.read<FetchMyPromotedPropertysCubit>().fetchMyPromotedPropertys(),
    );
    unawaited(HelperUtils.loadMyProperties(context));
  }
}

/// Advertisement Card For project
class MyAdvertisementProjectHorizontalCard
    extends BaseAdvertisementHorizontalCard {
  const MyAdvertisementProjectHorizontalCard({
    required this.advertisement,
    required this.isProjectPromoted,
    required this.isProjectPremium,
    super.key,
    super.statusButton,
    super.showDeleteButton,
    super.onDeleteTap,
    super.showLikeButton,
    this.heroTag,
  });

  final AdvertisementProject? advertisement;
  final bool isProjectPromoted;
  final bool isProjectPremium;
  final String? heroTag;

  @override
  String get rentduration => '';

  @override
  String get advertisementId => advertisement?.id.toString() ?? '';

  @override
  String get itemId => advertisement?.projectId ?? '';

  @override
  String get titleImage => advertisement?.project.image ?? '';

  @override
  String get itemType => advertisement?.project.type ?? '';

  @override
  String get categoryImage => advertisement?.project.category?.image ?? '';

  @override
  String get categoryName => advertisement?.project.category?.category ?? '';

  @override
  String get price => '';

  @override
  String get title => advertisement?.project.title ?? '';

  @override
  String get city => advertisement?.project.city ?? '';

  @override
  String get status => advertisement?.status ?? '';

  @override
  bool get isPremium => isProjectPremium;

  @override
  bool get isPromoted => isProjectPromoted;

  @override
  String? get resolvedHeroTag =>
      heroTag ?? 'project-hero-${advertisement?.projectId}';

  @override
  Future<void> onShareAction(BuildContext context) async {
    await HelperUtils.share(
      context,
      advertisement?.project.slugId ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final deleteCubit = context.read<DeleteAdvertismentCubit>();
    final resolvedHeroTag =
        heroTag ?? 'project-hero-${advertisement?.projectId}';

    final projectModel = ProjectModel(
      id: int.parse(advertisement?.projectId ?? '0'),
      title: advertisement?.project.title,
      image: advertisement?.project.image,
      addedBy: advertisement?.project.addedBy,
      isPremium: isProjectPremium,
      isPromoted: isProjectPromoted,
      category: ProjectCategory(
        id: advertisement?.project.category?.id,
        category: advertisement?.project.category?.category,
        image: advertisement?.project.category?.image,
        translatedName: advertisement?.project.category?.translatedName,
      ),
      city: advertisement?.project.city,
      state: advertisement?.project.state,
      country: advertisement?.project.country,
      type: advertisement?.project.type,
    );

    return CustomOpenContainer(
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.rw(context))),
      ),
      openBuilder: (context, closeContainer) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => DeleteProjectCubit()),
            BlocProvider(create: (context) => RenewListingCubit()),
          ],
          child: ProjectDetailsScreen(
            project: projectModel,
            heroTag: resolvedHeroTag,
          ),
        );
      },
      closedBuilder: (context, openContainer) {
        return BlocProvider.value(
          value: deleteCubit,
          child: Builder(
            builder: (innerContext) {
              return GestureDetector(
                onLongPress: () => onShareAction(innerContext),
                onTap: () async {
                  final hasInternet = await HelperUtils.checkInternet();

                  if (!hasInternet) {
                    return HelperUtils.showSnackBarMessage(
                      innerContext,
                      'noInternet',
                      type: .error,
                    );
                  }
                  openContainer();
                },
                child: Container(
                  padding: EdgeInsets.all(8.rw(innerContext)),
                  height: 126.rh(innerContext),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: innerContext.color.borderColor,
                    ),
                    color: innerContext.color.secondaryColor,
                    borderRadius: BorderRadius.circular(8.rw(innerContext)),
                  ),
                  child: Stack(
                    fit: .expand,
                    children: [
                      Row(
                        children: [
                          _buildImageSection(innerContext),
                          SizedBox(width: 12.rw(innerContext)),
                          _buildInfoSection(innerContext),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void onCardTap(BuildContext context) {}

  @override
  void onDeleteSuccess(BuildContext context) {
    unawaited(
      context.read<FetchMyPromotedProjectsCubit>().fetchMyPromotedProjects(),
    );
    unawaited(
      context.read<FetchMyProjectsCubit>().fetchMyProjects(),
    );
  }
}
