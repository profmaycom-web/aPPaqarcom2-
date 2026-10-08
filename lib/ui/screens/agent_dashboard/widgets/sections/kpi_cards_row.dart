import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_summary_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_summary_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/charts/mini_bar_chart.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/dashboard_card.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/value_formatter.dart';
import 'package:material_ui/material_ui.dart';

class KpiCardsRow extends StatelessWidget {
  const KpiCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentDashboardSummaryCubit, AgentDashboardSummaryState>(
      builder: (context, state) {
        final child =
            state is AgentDashboardSummaryLoading ||
                state is AgentDashboardSummaryInitial
            ? _buildLoading(context)
            : state is AgentDashboardSummaryFailure
            ? _buildError(context, state.errorMessage)
            : _buildCards(
                context,
                (state as AgentDashboardSummarySuccess).data,
              );
        return Padding(
          padding: EdgeInsets.only(bottom: 16.rh(context)),
          child: child,
        );
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return SizedBox(
      height: 140.rh(context),
      child: ListView.separated(
        scrollDirection: .horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.rw(context)),
        itemCount: 3,
        separatorBuilder: (_, _) => SizedBox(width: 12.rw(context)),
        itemBuilder: (_, _) => CustomShimmer(
          width: 220.rw(context),
          height: 140.rh(context),
          borderRadius: 16,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return DashboardCard(
      child: CustomText(
        message,
        fontSize: context.font.xs,
        color: context.color.textLightColor,
      ),
    );
  }

  Widget _buildCards(
    BuildContext context,
    AgentDashboardSummaryModel data,
  ) {
    final cards = <_KpiCardData>[
      _KpiCardData(
        label: 'properties'.translate(context),
        value: data.properties.totalProperties,
        delta: data.properties.currentMonthPropertyCount,
        iconAsset: AppIcons.homeActive,
        accent: context.color.tertiaryColor,
        monthly: data.properties.monthlyPropertyCounts
            .map((e) => e.count)
            .toList(),
      ),
      _KpiCardData(
        label: 'propertyViews'.translate(context),
        value: data.propertiesViews.totalViews,
        delta: data.propertiesViews.currentMonthPropertyViews,
        icon: Icons.remove_red_eye_outlined,
        accent: const Color(0xFF3B82F6),
        monthly: data.propertiesViews.monthlyPropertyViews
            .map((e) => e.count)
            .toList(),
      ),
      _KpiCardData(
        label: 'projects'.translate(context),
        value: data.projects.totalProjects,
        delta: data.projects.currentMonthProjectCount,
        icon: Icons.apartment_outlined,
        accent: const Color(0xFFF59E0B),
        monthly: data.projects.monthlyProjectCounts
            .map((e) => e.count)
            .toList(),
      ),
    ];

    return SizedBox(
      height: 140.rh(context),
      child: ListView.separated(
        scrollDirection: .horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.rw(context)),
        itemCount: cards.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.rw(context)),
        itemBuilder: (_, i) => _KpiCard(data: cards[i]),
      ),
    );
  }
}

class _KpiCardData {
  const _KpiCardData({
    required this.label,
    required this.value,
    required this.delta,
    required this.accent,
    required this.monthly,
    this.iconAsset,
    this.icon,
  });

  final String label;
  final int value;
  final int delta;
  final Color accent;
  final List<int> monthly;
  final String? iconAsset;
  final IconData? icon;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240.rw(context),
      child: DashboardCard(
        margin: .zero,
        padding: EdgeInsets.all(14.rw(context)),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.rw(context),
                  height: 48.rh(context),
                  decoration: BoxDecoration(
                    color: data.accent,
                    borderRadius: BorderRadius.circular(8.rw(context)),
                  ),
                  child: Center(
                    child: data.iconAsset != null
                        ? CustomImage(
                            imageUrl: data.iconAsset!,
                            width: 20.rw(context),
                            height: 20.rh(context),
                            color: Colors.white,
                          )
                        : Icon(
                            data.icon ?? Icons.insights_outlined,
                            size: 22.rw(context),
                            color: Colors.white,
                          ),
                  ),
                ),
                SizedBox(width: 12.rw(context)),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: .start,
                      mainAxisAlignment: .center,
                      children: [
                        CustomText(
                          formatCompactNumber(data.value),
                          fontSize: 24,
                          textAlign: .start,
                          textSpan: data.delta > 0
                              ? TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: .middle,
                                      child: CustomText(
                                        formatCompactNumber(data.value),
                                        fontSize: 22.rf(context),
                                        fontWeight: .w700,
                                        color: context.color.textColorDark,
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: .middle,
                                      child: Container(
                                        margin: .symmetric(
                                          horizontal: 4.rw(context),
                                        ),
                                        padding: .symmetric(
                                          horizontal: 8.rw(context),
                                          vertical: 4.rh(context),
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.color.tertiaryColor
                                              .withValues(
                                                alpha: .2,
                                              ),
                                          borderRadius: .circular(100),
                                        ),

                                        child: CustomText(
                                          '+${formatCompactNumber(data.delta)}',
                                          fontSize: context.font.xs,
                                          fontWeight: .w600,
                                          color: context.color.tertiaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          isRichText: data.delta > 0,
                          fontWeight: .w700,
                          color: context.color.textColorDark,
                        ),
                        CustomText(
                          data.label,
                          fontSize: context.font.sm,
                          color: context.color.textColorDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.rh(context)),
            Expanded(
              child: MiniBarChart(
                values: data.monthly,
                color: data.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
