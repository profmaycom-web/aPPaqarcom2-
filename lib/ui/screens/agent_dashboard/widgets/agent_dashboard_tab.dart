import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_active_packages_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_category_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_listings_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_most_viewed_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_summary_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/sections/best_viewed_categories_section.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/sections/current_plan_section.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/sections/dashboard_header.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/sections/kpi_cards_row.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/sections/listing_overview_section.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/sections/most_viewed_listings_section.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/sections/verify_agent_cta.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart'
    as refresh;
import 'package:material_ui/material_ui.dart';

class AgentHomeTab extends StatefulWidget {
  const AgentHomeTab({super.key});

  @override
  State<AgentHomeTab> createState() => _AgentHomeTabState();
}

class _AgentHomeTabState extends State<AgentHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchIfNeeded();
    });
  }

  void _fetchIfNeeded() {
    if (context.read<AgentDashboardSummaryCubit>().state
        is AgentDashboardSummaryInitial) {
      unawaited(context.read<AgentDashboardSummaryCubit>().fetch());
    }
    if (context.read<AgentDashboardListingsCubit>().state
        is AgentDashboardListingsInitial) {
      unawaited(
        context.read<AgentDashboardListingsCubit>().fetch(
          type: 'property',
          range: 'weekly',
        ),
      );
    }
    if (context.read<AgentDashboardCategoryCubit>().state
        is AgentDashboardCategoryInitial) {
      unawaited(
        context.read<AgentDashboardCategoryCubit>().fetch(range: 'weekly'),
      );
    }
    if (context.read<AgentDashboardMostViewedCubit>().state
        is AgentDashboardMostViewedInitial) {
      unawaited(
        context.read<AgentDashboardMostViewedCubit>().fetch(
          type: 'property',
          range: 'weekly',
        ),
      );
    }
    if (context.read<AgentDashboardActivePackagesCubit>().state
        is AgentDashboardActivePackagesInitial) {
      unawaited(context.read<AgentDashboardActivePackagesCubit>().fetch());
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<AgentDashboardSummaryCubit>().fetch(),
      context.read<AgentDashboardListingsCubit>().fetch(
        type: 'property',
        range: 'weekly',
      ),
      context.read<AgentDashboardCategoryCubit>().fetch(range: 'weekly'),
      context.read<AgentDashboardMostViewedCubit>().fetch(
        type: 'property',
        range: 'weekly',
      ),
      context.read<AgentDashboardActivePackagesCubit>().fetch(),
      context.read<AgentProfileCubit>().fetchAgentProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      body: SafeArea(
        child: refresh.CustomRefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: Constant.scrollPhysics,
            child: const Column(
              crossAxisAlignment: .start,
              children: [
                DashboardHeader(),
                KpiCardsRow(),
                ListingOverviewSection(),
                BestViewedCategoriesSection(),
                VerifyAgentCta(),
                CurrentPlanSection(),
                MostViewedListingsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
