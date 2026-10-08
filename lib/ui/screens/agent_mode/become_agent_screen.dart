import 'package:carousel_slider/carousel_slider.dart';
import 'package:ebroker/data/cubits/agents/fetch_agent_packages_cubit.dart';
import 'package:ebroker/data/model/agent_package_model.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:material_ui/material_ui.dart';

class BecomeAgentScreen extends StatefulWidget {
  const BecomeAgentScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => FetchAgentPackagesCubit(),
        child: const BecomeAgentScreen(),
      ),
    );
  }

  @override
  State<BecomeAgentScreen> createState() => _BecomeAgentScreenState();
}

class _BecomeAgentScreenState extends State<BecomeAgentScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<FetchAgentPackagesCubit>().fetchPackages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.secondaryColor,
      appBar: const CustomAppBar(
        backgroundColor: Colors.transparent,
        isTransparent: true,
      ),
      body: BlocBuilder<FetchAgentPackagesCubit, FetchAgentPackagesState>(
        builder: (context, state) {
          if (state is FetchAgentPackagesInProgress) {
            return Center(child: UiUtils.progress());
          }
          if (state is FetchAgentPackagesFailure) {
            if (state.errorMessage is NoInternetConnectionError) {
              return NoInternet(
                onRetry: () async {
                  await context.read<FetchAgentPackagesCubit>().fetchPackages();
                },
              );
            }
            return SomethingWentWrong(
              errorMessage: state.errorMessage,
            );
          }
          if (state is FetchAgentPackagesSuccess) {
            final packages = state.response.packages;

            return SingleChildScrollView(
              physics: Constant.scrollPhysics,
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  _buildMarketingHeader(context),
                  _buildBenefitsGrid(context),
                  UiUtils.buildButton(
                    context,
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.becomeAgentForm,
                        arguments: {'form_type': 'become_agent'},
                      );
                    },
                    suffixWidget: Padding(
                      padding: EdgeInsetsDirectional.only(start: 8.rw(context)),
                      child: Transform.flip(
                        flipX: true,
                        child: CustomImage(
                          imageUrl: AppIcons.arrowLeft,
                          height: 24.rh(context),
                          matchTextDirection: true,
                          color: context.color.buttonColor,
                          fit: .contain,
                        ),
                      ),
                    ),
                    buttonTitle: 'applyNow'.translate(context),
                    outerPadding: .symmetric(
                      horizontal: 24.rw(context),
                      vertical: 24.rh(context),
                    ),
                  ),
                  SizedBox(height: 32.rh(context)),
                  _buildPlansAndPricingSection(context, packages),
                  SizedBox(height: 48.rh(context)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMarketingHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          // Tag Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomText(
              'powerUpYourPropertyListings'.translate(context),
              color: context.color.tertiaryColor,
              fontWeight: .w600,
              fontSize: context.font.sm,
            ),
          ),
          SizedBox(height: 16.rh(context)),
          // Title
          CustomText(
            'introducing'.translate(context),
            fontSize: 32,
            fontWeight: .w400,
            color: context.color.textColorDark,
          ),
          CustomText(
            'theAgentMode'.translate(context),
            fontSize: 32,
            fontWeight: .w600,
            color: context.color.tertiaryColor,
          ),
          SizedBox(height: 12.rh(context)),
          // Subtitle
          CustomText(
            'agentModeSubtitle'.translate(context),
            fontSize: context.font.md,
            color: context.color.textColorDark.withValues(alpha: 0.7),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
        children: [
          _buildBenefitCard(
            context: context,
            icon: AppIcons.shieldTick,
            title: 'verifiedBadge'.translate(context),
            subtitle: 'verifiedBadgeSubtitle'.translate(context),
          ),
          _buildBenefitCard(
            context: context,
            icon: AppIcons.agentProject,
            title: 'projectListing'.translate(context),
            subtitle: 'projectListingSubtitle'.translate(context),
          ),
          _buildBenefitCard(
            context: context,
            icon: AppIcons.chart,
            title: 'promoteListings'.translate(context),
            subtitle: 'promoteListingsSubtitle'.translate(context),
          ),
          _buildBenefitCard(
            context: context,
            icon: AppIcons.dashboard,
            title: 'agentDashboard'.translate(context),
            subtitle: 'agentDashboardSubtitle'.translate(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      clipBehavior: .hardEdge,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.textColorDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: .expand,
        clipBehavior: .none,
        children: [
          PositionedDirectional(
            end: -55.rs(context),
            top: -55.rs(context),
            child: Transform.rotate(
              angle: 15 * (pi / 180),
              child: CustomImage(
                imageUrl: icon,
                fit: .contain,
                height: 124.rh(context),
                color: context.color.borderColor,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: .start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.color.textColorDark,
                  shape: .circle,
                ),
                child: CustomImage(
                  imageUrl: icon,
                  height: 24.rh(context),
                  fit: .contain,
                  color: context.color.secondaryColor,
                ),
              ),
              const Spacer(),
              CustomText(
                title,
                fontWeight: .w600,
                fontSize: context.font.md,
                color: context.color.textColorDark,
              ),
              SizedBox(height: 4.rh(context)),
              CustomText(
                subtitle,
                fontSize: context.font.xs,
                color: context.color.textColorDark,
                maxLines: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlansAndPricingSection(
    BuildContext context,
    List<AgentPackageModel> packages,
  ) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              CustomText(
                'ourBudgetFriendly'.translate(context),
                color: context.color.tertiaryColor,
                fontWeight: .w600,
                fontSize: context.font.md,
              ),
              CustomText(
                'agentPlans'.translate(context),
                fontSize: 28,
                fontWeight: .w400,
                color: context.color.textColorDark,
              ),
            ],
          ),
        ),
        SizedBox(height: 20.rh(context)),
        if (packages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomText(
              'noPackagesFound'.translate(context),
            ),
          )
        else
          CarouselSlider(
            options: CarouselOptions(
              enlargeCenterPage: true,
              initialPage: 1,
              enableInfiniteScroll: false,
              height: 350.rh(context),
              enlargeFactor: .2,
              viewportFraction: .65,
            ),
            items: packages.map((e) => _buildPackageCard(context, e)).toList(),
          ),
      ],
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    AgentPackageModel package,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: context.color.textColorDark,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    package.name,
                    color: context.color.secondaryColor,
                    fontWeight: .w600,
                    fontSize: context.font.lg,
                  ),
                ),
              ],
            ),
          ),
          // Features
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: context.color.borderColor,
                    width: 1.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: Constant.scrollPhysics,
                itemCount: package.packageFeatures.length,
                itemBuilder: (context, index) {
                  final feature = package.packageFeatures[index];
                  final featureId = feature.featureId;
                  if (featureId > 4 && featureId != 8) {
                    return const SizedBox.shrink();
                  }
                  final isIncluded = feature.isIncluded;

                  var featureText = feature.feature.name;
                  if (feature.limit != null && feature.limit! > 0) {
                    featureText += ': ${feature.limit}';
                  } else if (feature.limitType ==
                      AdvertisementLimit.unlimited) {
                    featureText += ': ${'unlimited'.translate(context)}';
                  } else {
                    featureText += ': ${'notIncluded'.translate(context)}';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: .start,
                      children: [
                        Icon(
                          isIncluded
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: isIncluded ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8.rw(context)),
                        Expanded(
                          child: CustomText(
                            featureText,
                            fontSize: context.font.sm,
                            color: context.color.textColorDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Price and Subscribe Button
          Container(
            width: double.infinity,
            padding: .all(16.rw(context)),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.color.borderColor,
                ),
                left: BorderSide(
                  color: context.color.borderColor,
                ),
                right: BorderSide(
                  color: context.color.borderColor,
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Container(
              padding: const .all(.5),
              decoration: BoxDecoration(
                borderRadius: .circular(4),
                gradient: SweepGradient(
                  colors: [
                    context.color.secondaryColor,
                    context.color.tertiaryColor,
                    context.color.tertiaryColor,
                    context.color.secondaryColor,
                    context.color.tertiaryColor,
                    context.color.tertiaryColor,
                    context.color.tertiaryColor,
                    context.color.secondaryColor,
                  ],
                ),
              ),
              child: Container(
                padding: .symmetric(
                  horizontal: 16.rw(context),
                  vertical: 8.rh(context),
                ),
                decoration: BoxDecoration(
                  borderRadius: .circular(3.5),
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                            context.color.tertiaryColor,
                            context.color.secondaryColor,
                            .95,
                          ) ??
                          Colors.transparent,
                      context.color.secondaryColor,
                    ],
                    begin: .centerStart,
                    end: .centerEnd,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    CustomText(
                      package.price == 0 || package.price == null
                          ? 'free'.translate(context)
                          : package.price.toString().priceFormat(
                              context: context,
                            ),
                      fontSize: 24,
                      fontWeight: .bold,
                      color: context.color.textColorDark,
                    ),
                    CustomText(
                      '${HelperUtils.getPackageDuration(duration: package.duration)} ${'days'.translate(context)}',
                      fontSize: context.font.xs,
                      color: context.color.textLightColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
