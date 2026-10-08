import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:material_ui/material_ui.dart';

class ProjectHorizontalCard extends StatefulWidget {
  const ProjectHorizontalCard({
    required this.project,
    required this.isRejected,
    super.key,
    this.statusButton,
    this.disableTap,
    this.showFeatured,
    this.heroTag,
  });

  final ProjectModel project;
  final bool isRejected;

  final StatusButton? statusButton;

  final bool? disableTap;
  final bool? showFeatured;
  final String? heroTag;

  @override
  State<ProjectHorizontalCard> createState() => _ProjectHorizontalCardState();
}

class _ProjectHorizontalCardState extends State<ProjectHorizontalCard> {
  bool _isNavigating = false;
  ProjectModel? _loadedProject;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void dispose() {
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMyProject =
        widget.project.addedBy.toString() == HiveUtils.getUserId();
    final resolvedHeroTag =
        widget.heroTag ?? 'project-hero-${widget.project.id}';
    final projectImages = <String>[
      if (widget.project.image != null && widget.project.image!.isNotEmpty)
        widget.project.image!,
      ...?widget.project.gallaryImages
          ?.where((element) => !element.isVideo)
          .map((e) => e.imageUrl)
          .where((url) => url.isNotEmpty),
    ];
    Future<void> openDetails() async {
      await ProjectDetailsScreen.open(
        context,
        project: _loadedProject ?? widget.project,
        heroTag: resolvedHeroTag,
      );
    }

    return GestureDetector(
      onTap: () async {
        // Prevent multiple taps
        if (_isNavigating) return;

        // if (disableTap ?? false) return;
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
          if (widget.project.isPremium ?? false) {
            await GuestChecker.check(
              onNotGuest: () async {
                if (isMyProject) {
                  await openDetails();
                } else {
                  final packageAvailable = await _checkPackageCubit
                      .checkAvailability(
                        packageType: PackageType.premiumProjects,
                      );

                  if (packageAvailable) {
                    await openDetails();
                  } else {
                    await UiUtils.showBlurredDialoge(
                      context,
                      dialog: const BlurredSubscriptionDialogBox(
                        packageType: SubscriptionPackageType.premiumProjects,
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
        } finally {
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        }
      },
      child: Container(
        height: 130.rh(context),
        width: MediaQuery.sizeOf(context).width,
        padding: EdgeInsets.all(8.rw(context)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.color.borderColor),
          color: context.color.secondaryColor,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ProjectImageSwiper(
                  images: projectImages,
                  heroTag: resolvedHeroTag,
                  width: 127.rw(context),
                  height: 114.rh(context),
                  dotSize: 4,
                  borderRadius: BorderRadius.circular(4),
                  lowQualityImage: widget.project.lowQualityImage,
                ),
                if ((widget.project.isPromoted ?? false) ||
                    (widget.showFeatured ?? false))
                  PositionedDirectional(
                    bottom: 4.rh(context),
                    end: 4.rw(context),
                    child: const PromotedCard(iconOnly: true),
                  ),
                if (widget.project.isPremium ?? false)
                  PositionedDirectional(
                    start: 4.rh(context),
                    top: 4.rh(context),
                    child: CustomImage(
                      imageUrl: AppIcons.premium,
                      width: 18.rw(context),
                      height: 18.rh(context),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.rw(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: <Widget>[
                  Row(
                    children: [
                      CustomImage(
                        imageUrl: widget.project.category?.image ?? '',
                        color: context.color.textLightColor,
                        width: 18.rw(context),
                        height: 18.rh(context),
                      ),
                      SizedBox(width: 4.rw(context)),
                      Expanded(
                        child: CustomText(
                          widget.project.category?.translatedName ??
                              widget.project.category?.category ??
                              '',
                          fontWeight: .w600,
                          fontSize: context.font.xxs,
                          color: context.color.textLightColor,
                          maxLines: 1,
                        ),
                      ),
                      if (isMyProject &&
                          widget.project.requestStatus == 'approved') ...[
                        SizedBox(width: 4.rw(context)),
                        CustomText(
                          widget.project.isExpired ?? false
                              ? 'expired'.translate(context)
                              : UiUtils.getExpiryCountdown(
                                  context,
                                  widget.project.expiryDate,
                                ),
                          maxLines: 1,
                          fontSize: context.font.xxs,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8.rh(context)),
                  CustomText(
                    widget.project.translatedTitle ??
                        widget.project.title ??
                        '',
                    maxLines: 1,
                    fontSize: context.font.sm,
                    fontWeight: .w400,
                    color: context.color.textColorDark,
                  ),
                  SizedBox(height: 4.rh(context)),
                  CustomText(
                    '${widget.project.city}, ${widget.project.state}, ${widget.project.country}',
                    maxLines: 1,
                    fontSize: context.font.xs,
                    fontWeight: .w400,
                    color: context.color.textColorDark,
                  ),
                  SizedBox(height: 8.rh(context)),
                  UiUtils.getDivider(context),
                  SizedBox(height: 8.rh(context)),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          widget.project.type?.toLowerCase().translate(
                                context,
                              ) ??
                              '',
                          maxLines: 2,
                          fontSize: context.font.xxs,
                          fontWeight: .w600,
                          color: context.color.tertiaryColor,
                        ),
                      ),
                      if (widget.statusButton != null &&
                          widget.project.isExpired != true) ...[
                        GestureDetector(
                          onTap: () async {
                            if (widget.isRejected) {
                              await UiUtils.showBlurredDialoge(
                                context,
                                dialog: BlurredDialogBox(
                                  acceptTextColor: context.color.buttonColor,
                                  showCancleButton: false,
                                  title: widget.statusButton!.lable,
                                  content: CustomText(
                                    widget.project.rejectReason?.reason
                                            .toString() ??
                                        '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.statusButton!.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                CustomText(
                                  widget.statusButton!.lable,
                                  fontWeight: .bold,
                                  fontSize: context.font.xxs,
                                  color:
                                      widget.statusButton?.textColor ??
                                      Colors.black,
                                ),
                                if (widget.project.editReason != null &&
                                    widget.project.editReason!.isNotEmpty) ...[
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
                                            widget.project.editReason ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                    child: CustomImage(
                                      imageUrl: AppIcons.info,
                                      width: 16,
                                      height: 16,
                                      color: widget.statusButton!.textColor,
                                    ),
                                  ),
                                ],
                                if (widget.isRejected) ...[
                                  SizedBox(width: 2.rw(context)),
                                  CustomImage(
                                    imageUrl: AppIcons.info,
                                    width: 16,
                                    height: 16,
                                    color: widget.statusButton!.textColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
