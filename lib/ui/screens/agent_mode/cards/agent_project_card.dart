import 'dart:async';

import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/project_data.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:ebroker/ui/screens/widgets/project_image_swiper.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/guest_checker.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class AgentProjectCardBig extends StatefulWidget {
  const AgentProjectCardBig({
    required this.project,
    this.color,
    super.key,
    this.heroTag,
  });

  final ProjectData project;
  final Color? color;
  final String? heroTag;

  @override
  State<AgentProjectCardBig> createState() => _AgentProjectCardBigState();
}

class _AgentProjectCardBigState extends State<AgentProjectCardBig> {
  bool _isNavigating = false;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void dispose() {
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMyProject = widget.project.addedBy == HiveUtils.getUserId();
    final resolvedHeroTag =
        widget.heroTag ?? 'project-hero-${widget.project.id}';

    final projectImages = <String>[
      if (widget.project.image.isNotEmpty) widget.project.image,
      ...widget.project.galleryImages
          .map((e) => e.name)
          .where((url) => url.isNotEmpty),
    ];

    final projectModel = ProjectModel(
      id: widget.project.id,
      title: widget.project.title,
      image: widget.project.image,
      addedBy: widget.project.addedBy,
      isPremium: widget.project.isPremium,
      isPromoted: widget.project.isFeatured,
      category: ProjectCategory(
        id: widget.project.category.id,
        category: widget.project.category.category,
        image: widget.project.category.image,
        translatedName: widget.project.category.translatedName,
      ),
      city: widget.project.city,
      state: widget.project.state,
      country: widget.project.country,
      type: widget.project.type,
    );

    Future<void> openDetails() async {
      await Navigator.pushNamed(
        context,
        Routes.projectDetailsScreen,
        arguments: {
          'project': projectModel,
          'heroTag': resolvedHeroTag,
          'fromAgentDetails': true,
        },
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
        try {
          if (widget.project.isPremium) {
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
        height: 258.rh(context),
        width: 264.rw(context),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: widget.color ?? context.color.secondaryColor,
          border: Border.all(
            color: context.color.borderColor,
          ),
        ),
        child: Column(
          children: [
            Flexible(
              child: Stack(
                children: [
                  ProjectImageSwiper(
                    images: projectImages,
                    heroTag: resolvedHeroTag,
                    width: MediaQuery.of(context).size.width,
                    height: 138.rh(context),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                    lowQualityImage: widget.project.lowQualityImage,
                  ),
                  if (widget.project.isPremium)
                    PositionedDirectional(
                      start: 8,
                      top: 8,
                      child: CustomImage(
                        imageUrl: AppIcons.premium,
                        width: 24.rw(context),
                        height: 24.rh(context),
                      ),
                    ),
                  if (widget.project.isFeatured)
                    const PositionedDirectional(
                      bottom: 8,
                      end: 8,
                      child: PromotedCard(),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: .start,
                children: <Widget>[
                  Row(
                    children: [
                      CustomImage(
                        imageUrl: widget.project.category.image ?? '',
                        width: 18.rw(context),
                        height: 18.rh(context),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: CustomText(
                          widget.project.category.translatedName ??
                              widget.project.category.category ??
                              '',
                          fontWeight: .w400,
                          fontSize: context.font.xs,
                          color: context.color.textLightColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  CustomText(
                    widget.project.translatedTitle ?? widget.project.title,
                    maxLines: 1,
                    fontSize: context.font.lg,
                    fontWeight: .w500,
                    color: context.color.textColorDark,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  CustomText(
                    '${widget.project.city}, ${widget.project.state}, ${widget.project.country}',
                    maxLines: 1,
                    fontSize: context.font.xs,
                    fontWeight: .w400,
                    color: context.color.textColorDark,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: context.color.textLightColor.withValues(
                      alpha: .1,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  CustomText(
                    widget.project.type.translate(context),
                    maxLines: 1,
                    fontSize: context.font.sm,
                    fontWeight: .w600,
                    color: context.color.tertiaryColor,
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
