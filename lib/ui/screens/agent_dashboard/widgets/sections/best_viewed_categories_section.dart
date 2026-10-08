import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_category_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_category_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/charts/category_donut_chart.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/dashboard_card.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/range_dropdown.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/value_formatter.dart';

const _palette = <Color>[
  Color(0xFF6366F1),
  Color(0xFFEC4899),
  Color(0xFF3B82F6),
  Color(0xFF1F2937),
  Color(0xFFF59E0B),
];

class BestViewedCategoriesSection extends StatefulWidget {
  const BestViewedCategoriesSection({super.key});

  @override
  State<BestViewedCategoriesSection> createState() =>
      _BestViewedCategoriesSectionState();
}

class _BestViewedCategoriesSectionState
    extends State<BestViewedCategoriesSection> {
  CategoryRange _range = CategoryRange.weekly;

  void _onRangeChanged(CategoryRange r) {
    if (_range == r) return;
    setState(() => _range = r);
    unawaited(
      context.read<AgentDashboardCategoryCubit>().fetch(range: r.apiValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: EdgeInsets.all(16.rw(context)),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'bestViewedCategories'.translate(context),
                  fontSize: context.font.lg,
                  fontWeight: .w700,
                  color: context.color.textColorDark,
                ),
              ),
              RangeDropdown<CategoryRange>(
                value: _range,
                options: CategoryRange.values,
                labelOf: (r) => r.translationKey,
                onChanged: _onRangeChanged,
              ),
            ],
          ),
          SizedBox(height: 16.rh(context)),
          BlocBuilder<AgentDashboardCategoryCubit, AgentDashboardCategoryState>(
            builder: _buildBody,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AgentDashboardCategoryState state,
  ) {
    if (state is AgentDashboardCategoryInitial ||
        state is AgentDashboardCategoryLoading) {
      return CustomShimmer(height: 180.rh(context), borderRadius: 12);
    }

    if (state is AgentDashboardCategoryFailure) {
      return _centered(
        context,
        state.errorMessage,
      );
    }

    if (state is AgentDashboardCategorySuccess) {
      final raw = state.categories;
      if (raw.isEmpty) {
        return _centered(context, 'noDataFound'.translate(context));
      }

      final capped = raw.take(_palette.length).toList();
      final segments = [
        for (int i = 0; i < capped.length; i++)
          DonutSegment(
            value: capped[i].views.toDouble(),
            color: _palette[i],
          ),
      ];

      return Row(
        children: [
          SizedBox(
            width: 160.rw(context),
            height: 160.rh(context),
            child: CategoryDonutChart(segments: segments),
          ),
          SizedBox(width: 16.rw(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                for (int i = 0; i < capped.length; i++) ...[
                  _CategoryLegendRow(
                    category: capped[i],
                    color: _palette[i],
                  ),
                  if (i < capped.length - 1) SizedBox(height: 10.rh(context)),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _centered(BuildContext context, String message) {
    return SizedBox(
      height: 80.rh(context),
      child: Center(
        child: CustomText(
          message,
          fontSize: context.font.xs,
          color: context.color.textLightColor,
        ),
      ),
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({required this.category, required this.color});

  final AgentDashboardCategoryModel category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 5.rh(context)),
          width: 8.rw(context),
          height: 8.rh(context),
          decoration: BoxDecoration(color: color, shape: .circle),
        ),
        SizedBox(width: 8.rw(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              CustomText(
                category.title,
                fontSize: context.font.sm,
                fontWeight: .w600,
                color: context.color.textColorDark,
                maxLines: 1,
              ),
              SizedBox(height: 2.rh(context)),
              CustomText(
                formatCompactNumber(category.views),
                fontSize: context.font.xs,
                color: context.color.textLightColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
