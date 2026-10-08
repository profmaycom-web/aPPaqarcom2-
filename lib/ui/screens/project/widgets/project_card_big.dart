import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:material_ui/material_ui.dart';

class ProjectCardBig extends StatefulWidget {
  const ProjectCardBig({
    required this.project,
    this.color,
    this.disableTap,
    this.showFeatured,
    super.key,
    this.heroTag,
  });

  final ProjectModel project;
  final Color? color;
  final bool? disableTap;
  final bool? showFeatured;
  final String? heroTag;

  @override
  State<ProjectCardBig> createState() => _ProjectCardBigState();
}

class _ProjectCardBigState extends State<ProjectCardBig> {
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
        } on Exception catch (_) {
          // Project navigation errors are handled by the shared helper flow.
        } finally {
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        }
      },
      child: Container(
        width: 263.rw(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: widget.color ?? context.color.secondaryColor,
        ),
        child: Column(
          mainAxisSize: .min,
          children: [
            Stack(
              children: [
                ProjectImageSwiper(
                  images: projectImages,
                  heroTag: resolvedHeroTag,
                  width: MediaQuery.of(context).size.width,
                  height: 148.rh(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  lowQualityImage: widget.project.lowQualityImage,
                ),

                if ((widget.project.isPromoted ?? false) ||
                    (widget.showFeatured ?? false))
                  PositionedDirectional(
                    bottom: 8.rh(context),
                    end: 8.rw(context),
                    child: const PromotedCard(),
                  ),
              ],
            ),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8.rw(context)),
                    bottomRight: Radius.circular(8.rw(context)),
                  ),
                  border: Border(
                    bottom: BorderSide(color: context.color.borderColor),
                    right: BorderSide(color: context.color.borderColor),
                    left: BorderSide(color: context.color.borderColor),
                  ),
                ),
                padding: EdgeInsets.all(8.rh(context)),
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: <Widget>[
                    Row(
                      children: [
                        CustomImage(
                          imageUrl: widget.project.category?.image ?? '',
                          color: context.color.textLightColor,
                          width: 18.rw(context),
                          height: 18.rh(context),
                        ),
                        SizedBox(width: 8.rw(context)),
                        Expanded(
                          child: CustomText(
                            widget.project.category?.translatedName ??
                                widget.project.category?.category ??
                                '',
                            fontWeight: .w400,
                            maxLines: 1,
                            fontSize: context.font.xs,
                            color: context.color.textLightColor,
                          ),
                        ),
                        if (widget.project.isPremium ?? false) ...[
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
                      widget.project.translatedTitle ??
                          widget.project.title ??
                          '',
                      maxLines: 1,
                      fontSize: context.font.md,
                      fontWeight: .w500,
                      color: context.color.textColorDark,
                    ),
                    SizedBox(height: 4.rh(context)),
                    CustomText(
                      '${widget.project.city}, ${widget.project.state}, ${widget.project.country}',
                      maxLines: 1,
                      fontSize: context.font.sm,
                      fontWeight: .w400,
                      color: context.color.textColorDark,
                    ),
                    SizedBox(height: 8.rh(context)),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.rw(context),
                          vertical: 8.rh(context),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: .centerStart,
                            end: .centerEnd,
                            colors: [
                              context.color.tertiaryColor.withValues(
                                alpha: 0.1,
                              ),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          widget.project.type?.toLowerCase().translate(
                                context,
                              ) ??
                              '',
                          maxLines: 1,
                          fontSize: context.font.sm,
                          fontWeight: .w600,
                          color: context.color.tertiaryColor,
                        ),
                      ),
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
