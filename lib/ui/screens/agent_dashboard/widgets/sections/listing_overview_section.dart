import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_listings_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/models/agent_dashboard_listings_model.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/charts/listing_line_chart.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/dashboard_card.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/range_dropdown.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/tab_pill_group.dart';
import 'package:fl_chart/fl_chart.dart';

class ListingOverviewSection extends StatefulWidget {
  const ListingOverviewSection({super.key});

  @override
  State<ListingOverviewSection> createState() => _ListingOverviewSectionState();
}

class _ListingOverviewSectionState extends State<ListingOverviewSection> {
  int _tab = 0;
  ListingOverviewRange _range = ListingOverviewRange.weekly;

  String get _type => _tab == 0 ? 'property' : 'project';

  void _refetch() {
    unawaited(
      context.read<AgentDashboardListingsCubit>().fetch(
        type: _type,
        range: _range.apiValue,
      ),
    );
  }

  void _onTabChanged(int i) {
    if (_tab == i) return;
    setState(() => _tab = i);
    _refetch();
  }

  void _onRangeChanged(ListingOverviewRange r) {
    if (_range == r) return;
    setState(() => _range = r);
    _refetch();
  }

  String _labelFor(AgentDashboardListingsEntry e) {
    switch (_range) {
      case ListingOverviewRange.weekly:
        final d = e.dayName.toLowerCase().translate(context);
        return d.length <= 3 ? d : d.substring(0, 3);
      case ListingOverviewRange.monthly:
        final parts = e.date.split('-');
        return parts.length == 3 ? parts[2] : e.date;
      case ListingOverviewRange.yearly:
        final mKey = e.month.split(' ').first.substring(0, 3);
        final m = mKey.toLowerCase().translate(context);
        return m.length > 3 ? m.substring(0, 3) : m;
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableColor = context.color.tertiaryColor;
    const rentedColor = Color(0xFF3B82F6);
    const soldColor = Color(0xFFF59E0B);

    return DashboardCard(
      padding: EdgeInsets.all(16.rw(context)),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'listingOverview'.translate(context),
                  fontSize: context.font.lg,
                  fontWeight: .w700,
                  color: context.color.textColorDark,
                ),
              ),
              RangeDropdown<ListingOverviewRange>(
                value: _range,
                options: ListingOverviewRange.values,
                labelOf: (r) => r.translationKey,
                onChanged: _onRangeChanged,
              ),
            ],
          ),
          SizedBox(height: 14.rh(context)),
          TabPillGroup(
            labels: [
              'properties'.translate(context),
              'projects'.translate(context),
            ],
            selectedIndex: _tab,
            onChanged: _onTabChanged,
          ),
          SizedBox(height: 16.rh(context)),
          BlocBuilder<AgentDashboardListingsCubit, AgentDashboardListingsState>(
            builder: (context, state) => _buildBody(
              context,
              state,
              availableColor: availableColor,
              rentedColor: rentedColor,
              soldColor: soldColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AgentDashboardListingsState state, {
    required Color availableColor,
    required Color rentedColor,
    required Color soldColor,
  }) {
    if (state is AgentDashboardListingsInitial ||
        state is AgentDashboardListingsLoading) {
      return CustomShimmer(height: 240.rh(context), borderRadius: 12);
    }

    if (state is AgentDashboardListingsFailure) {
      return _InlineError(
        message: state.errorMessage,
        onRetry: _refetch,
      );
    }

    if (state is AgentDashboardListingsSuccess) {
      final entries = state.data.rangeWise;
      if (entries.isEmpty) {
        return _EmptyHint(text: 'noDataFound'.translate(context));
      }

      List<FlSpot> toSpots(int Function(AgentDashboardListingsEntry e) pick) =>
          [
            for (int i = 0; i < entries.length; i++)
              FlSpot(i.toDouble(), pick(entries[i]).toDouble()),
          ];

      final labels = entries.map(_labelFor).toList();
      final isProject = _tab == 1;

      final series = isProject
          ? [
              LineChartSeries(
                label: 'upcoming'.translate(context),
                color: rentedColor,
                spots: toSpots((e) => e.sellProperties),
              ),
              LineChartSeries(
                label: 'under_construction'.translate(context),
                color: soldColor,
                spots: toSpots((e) => e.rentProperties),
              ),
            ]
          : [
              LineChartSeries(
                label: 'total'.translate(context),
                color: availableColor,
                spots: toSpots((e) => e.totalProperties),
              ),
              LineChartSeries(
                label: 'sell'.translate(context),
                color: rentedColor,
                spots: toSpots((e) => e.sellProperties),
              ),
              LineChartSeries(
                label: 'rent'.translate(context),
                color: soldColor,
                spots: toSpots((e) => e.rentProperties),
              ),
            ];

      final chips = isProject
          ? [
              _OverallChip(
                label: 'upcoming'.translate(context),
                value: state.data.overall.sellProperties,
                color: rentedColor,
              ),
              _OverallChip(
                label: 'under_construction'.translate(context),
                value: state.data.overall.rentProperties,
                color: soldColor,
              ),
            ]
          : [
              _OverallChip(
                label: 'total'.translate(context),
                value: state.data.overall.totalProperties,
                color: availableColor,
              ),
              _OverallChip(
                label: 'sell'.translate(context),
                value: state.data.overall.sellProperties,
                color: rentedColor,
              ),
              _OverallChip(
                label: 'rent'.translate(context),
                value: state.data.overall.rentProperties,
                color: soldColor,
              ),
            ];

      return Column(
        children: [
          SizedBox(
            height: 220.rh(context),
            child: ListingLineChart(xLabels: labels, series: series),
          ),
          SizedBox(height: 16.rh(context)),
          Row(
            children: [
              for (final c in chips) Expanded(child: c),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _OverallChip extends StatelessWidget {
  const _OverallChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomText(
          value.toString(),
          fontSize: context.font.lg,
          fontWeight: .w700,
          color: context.color.textColorDark,
        ),
        SizedBox(height: 4.rh(context)),
        Row(
          mainAxisAlignment: .center,
          children: [
            Container(
              width: 8.rw(context),
              height: 8.rh(context),
              decoration: BoxDecoration(color: color, shape: .circle),
            ),
            SizedBox(width: 6.rw(context)),
            CustomText(
              label,
              fontSize: context.font.xs,
              color: context.color.textLightColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomText(
          message,
          fontSize: context.font.xs,
          color: context.color.textLightColor,
        ),
        SizedBox(height: 8.rh(context)),
        GestureDetector(
          onTap: onRetry,
          child: CustomText(
            'retry'.translate(context),
            fontSize: context.font.sm,
            fontWeight: .w600,
            color: context.color.tertiaryColor,
            showUnderline: true,
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.rh(context),
      child: Center(
        child: CustomText(
          text,
          fontSize: context.font.xs,
          color: context.color.textLightColor,
        ),
      ),
    );
  }
}
