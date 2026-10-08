import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_active_packages_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_active_packages_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/dashboard_card.dart';
import 'package:ebroker/ui/screens/subscription/widget/package_tile.dart';
import 'package:material_ui/material_ui.dart';

class CurrentPlanSection extends StatelessWidget {
  const CurrentPlanSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      AgentDashboardActivePackagesCubit,
      AgentDashboardActivePackagesState
    >(
      builder: (context, state) {
        if (state is AgentDashboardActivePackagesInitial ||
            state is AgentDashboardActivePackagesLoading) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.rw(context)),
            child: CustomShimmer(
              height: 200.rh(context),
              borderRadius: 16,
            ),
          );
        }
        if (state is AgentDashboardActivePackagesFailure) {
          return _wrapper(
            context,
            CustomText(
              state.errorMessage,
              fontSize: context.font.xs,
              color: context.color.textLightColor,
            ),
          );
        }
        if (state is AgentDashboardActivePackagesSuccess) {
          if (state.packages.isEmpty) {
            return _checkoutPlans(context);
          }
          return _PlanCard(package: state.packages.first);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _wrapper(BuildContext context, Widget child) {
    return DashboardCard(child: child);
  }

  Widget _checkoutPlans(BuildContext context) {
    return DashboardCard(
      padding: EdgeInsets.all(16.rw(context)),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Column(
            children: [
              CustomText(
                'noMyPackagesFoundDescription'.translate(context),
                fontSize: context.font.md,
                fontWeight: .w700,
                color: context.color.textColorDark,
              ),
              SizedBox(height: 16.rh(context)),
              _OutlineButton(
                label: 'viewPlans'.translate(context),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.subscriptionPackageListRoute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.package});

  final AgentDashboardActivePackageModel package;

  String _calculateRemainingTime(
    DateTime endDate,
    BuildContext context,
  ) {
    final now = DateTime.now();
    final end = endDate;
    final timeDiff = end.difference(now).inMilliseconds;

    if (timeDiff <= 0) {
      return "${"no".translate(context)} ${"timeLeft".translate(context)}";
    }
    //If duration is in minutes (less than 60 minutes)
    if (timeDiff < (1000 * 60 * 60)) {
      final remainingMinutes = (timeDiff / (1000 * 60)).ceil();
      return "$remainingMinutes ${"minutesLeft".translate(context)}";
    }
    // If duration is in hours (less than 24 hours)
    if (timeDiff < (1000 * 60 * 60 * 24)) {
      final remainingHours = (timeDiff / (1000 * 60 * 60)).ceil();
      return "$remainingHours ${"hoursLeft".translate(context)}";
    }

    // Otherwise, calculate remaining days
    final remainingDays = (timeDiff / (1000 * 60 * 60 * 24)).ceil();
    return "$remainingDays ${"daysLeft".translate(context)}";
  }

  @override
  Widget build(BuildContext context) {
    final planName = package.translatedName.isNotEmpty
        ? package.translatedName
        : package.name;

    final startDateFormatted =
        package.startDate?.formatDate(format: 'EEE, d MMM, y') ?? '-';
    final endDateFormatted =
        package.endDate?.formatDate(format: 'EEE, d MMM, y') ?? '-';
    final endDateTime = package.endDate != null
        ? DateTime.tryParse(package.endDate!)
        : null;
    final timeLeft = endDateTime != null
        ? _calculateRemainingTime(endDateTime, context)
        : null;

    return DashboardCard(
      padding: EdgeInsets.all(16.rw(context)),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'currentPlan'.translate(context),
                  fontSize: context.font.md,
                  fontWeight: .w700,
                  color: context.color.textColorDark,
                ),
              ),
              CustomText(
                planName,
                fontSize: context.font.md,
                fontWeight: .w700,
                color: context.color.tertiaryColor,
              ),
            ],
          ),
          if (package.features.isNotEmpty) ...[
            SizedBox(height: 14.rh(context)),
            Row(
              children: [
                CustomImage(
                  imageUrl: AppIcons.listingFeature,
                ),
                SizedBox(width: 12.rw(context)),
                CustomText(
                  'listing'.translate(context),
                  fontSize: context.font.sm,
                  fontWeight: .w700,
                  color: context.color.inverseSurface,
                ),
              ],
            ),
            SizedBox(height: 14.rh(context)),
            Row(
              children: [
                for (int i = 0; i < package.features.length && i < 2; i++) ...[
                  if (i > 0) SizedBox(width: 24.rw(context)),
                  Expanded(
                    child: _FeatureProgress(
                      feature: package.features[i],
                    ),
                  ),
                ],
              ],
            ),
          ],
          SizedBox(height: 14.rh(context)),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: .start,
                      children: [
                        CustomText(
                          'startedOn'.translate(context),
                          fontSize: context.font.xs,
                          color: context.color.inverseSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        SizedBox(height: 4.rh(context)),
                        CustomText(
                          startDateFormatted,
                          fontSize: context.font.xs,
                          fontWeight: .w600,
                          color: context.color.inverseSurface,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: .end,
                      children: [
                        CustomText(
                          'willEndOn'.translate(context),
                          fontSize: context.font.xs,
                          color: context.color.inverseSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        SizedBox(height: 4.rh(context)),
                        CustomText(
                          endDateFormatted,
                          fontSize: context.font.xs,
                          fontWeight: .w600,
                          color: context.color.inverseSurface,
                        ),
                      ],
                    ),
                  ],
                ),
                if (timeLeft != null) ...[
                  SizedBox(height: 16.rh(context)),
                  MySeparator(
                    color: context.color.tertiaryColor,
                  ),
                  SizedBox(height: 16.rh(context)),
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: context.color.tertiaryColor,
                        size: 18,
                      ),
                      SizedBox(width: 8.rw(context)),
                      CustomText(
                        timeLeft,
                        fontSize: context.font.sm,
                        underlineOrLineColor: context.color.tertiaryColor,
                        fontWeight: .w500,
                        color: context.color.tertiaryColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 14.rh(context)),

          _OutlineButton(
            label: 'viewMore'.translate(context),
            onTap: () => Navigator.pushNamed(
              context,
              Routes.subscriptionPackageListRoute,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureProgress extends StatelessWidget {
  const _FeatureProgress({required this.feature});

  final AgentDashboardActivePackageFeature feature;

  @override
  Widget build(BuildContext context) {
    final used = feature.usedLimit ?? 0;
    final total = feature.totalLimit ?? feature.limit ?? 0;
    final label = feature.translatedName.isNotEmpty
        ? feature.translatedName
        : feature.name;
    final isUnlimited = feature.isUnlimited;

    var progress = 0.0;
    if (total > 0) {
      progress = used / total;
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText(
          label,
          fontSize: context.font.sm,
          fontWeight: .w600,
          color: context.color.inverseSurface,
        ),
        SizedBox(height: 8.rh(context)),
        if (isUnlimited) ...[
          CustomText(
            'unlimited'.translate(context),
            fontSize: context.font.md,
            fontWeight: .w700,
            color: context.color.tertiaryColor,
          ),
        ] else ...[
          Row(
            children: [
              CustomText(
                '$used',
                fontSize: context.font.sm,
                fontWeight: .w500,
                color: context.color.inverseSurface,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              CustomText(
                '$total',
                fontSize: context.font.sm,
                fontWeight: .w500,
                color: context.color.inverseSurface,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.rh(context)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.color.borderColor),
        ),
        child: CustomText(
          label,
          fontSize: context.font.sm,
          fontWeight: .w600,
          color: context.color.textColorDark,
        ),
      ),
    );
  }
}
