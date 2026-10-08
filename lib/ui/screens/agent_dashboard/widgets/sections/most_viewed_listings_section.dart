import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_most_viewed_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/dashboard_card.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/range_dropdown.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/tab_pill_group.dart';

class MostViewedListingsSection extends StatefulWidget {
  const MostViewedListingsSection({super.key});

  @override
  State<MostViewedListingsSection> createState() =>
      _MostViewedListingsSectionState();
}

class _MostViewedListingsSectionState extends State<MostViewedListingsSection> {
  int _tab = 0;
  MostViewedListingsRange _range = MostViewedListingsRange.weekly;

  String get _type => _tab == 0 ? 'property' : 'project';

  void _refetch() {
    unawaited(
      context.read<AgentDashboardMostViewedCubit>().fetch(
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

  void _onRangeChanged(MostViewedListingsRange r) {
    if (_range == r) return;
    setState(() => _range = r);
    _refetch();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: EdgeInsets.all(16.rw(context)),
      margin: .only(
        bottom: 48.rh(context),
        right: 16.rw(context),
        left: 16.rw(context),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'mostViewedListings'.translate(context),
                  fontSize: context.font.lg,
                  fontWeight: .w700,
                  color: context.color.textColorDark,
                ),
              ),
              RangeDropdown<MostViewedListingsRange>(
                value: _range,
                options: MostViewedListingsRange.values,
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
          BlocBuilder<
            AgentDashboardMostViewedCubit,
            AgentDashboardMostViewedState
          >(
            builder: _buildBody,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AgentDashboardMostViewedState state) {
    if (state is AgentDashboardMostViewedInitial ||
        state is AgentDashboardMostViewedLoading) {
      return Column(
        children: List.generate(
          4,
          (_) => Padding(
            padding: EdgeInsets.only(bottom: 10.rh(context)),
            child: CustomShimmer(height: 36.rh(context), borderRadius: 8),
          ),
        ),
      );
    }

    if (state is AgentDashboardMostViewedFailure) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.rh(context)),
        child: Center(
          child: CustomText(
            state.errorMessage.translate(context),
            fontSize: context.font.xs,
            color: context.color.textLightColor,
          ),
        ),
      );
    }

    if (state is AgentDashboardMostViewedSuccess) {
      final listings = state.listings;
      if (listings.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.rh(context)),
          child: Center(
            child: CustomText(
              'noDataFound'.translate(context),
              fontSize: context.font.xs,
              color: context.color.textLightColor,
            ),
          ),
        );
      }

      final maxViews = listings
          .map((e) => e.views)
          .fold<int>(0, (m, v) => v > m ? v : m);
      final safeMax = maxViews <= 0 ? 1 : maxViews;

      return Column(
        children: [
          for (int i = 0; i < listings.length; i++) ...[
            if (i > 0) SizedBox(height: 14.rh(context)),
            _ListingRow(
              title: listings[i].title,
              views: listings[i].views,
              fraction: listings[i].views / safeMax,
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({
    required this.title,
    required this.views,
    required this.fraction,
  });

  final String title;
  final int views;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText(
          title,
          fontSize: context.font.sm,
          fontWeight: .w600,
          color: context.color.textColorDark,
          maxLines: 1,
        ),
        SizedBox(height: 8.rh(context)),
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 8.rh(context),
                    decoration: BoxDecoration(
                      color: context.color.tertiaryColor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) => Container(
                      height: 8.rh(context),
                      width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.rw(context)),
            CustomText(
              views.toString(),
              fontSize: context.font.sm,
              fontWeight: .w700,
              color: context.color.textColorDark,
            ),
            SizedBox(width: 6.rw(context)),
            CustomImage(
              imageUrl: AppIcons.eye,
              height: 16.rw(context),
              color: context.color.tertiaryColor,
            ),
          ],
        ),
      ],
    );
  }
}
