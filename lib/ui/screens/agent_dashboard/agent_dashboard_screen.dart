import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_active_packages_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_category_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_listings_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_most_viewed_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/cubits/agent_dashboard_summary_cubit.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/agent_bottom_bar.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/agent_dashboard_tab.dart';
import 'package:ebroker/ui/screens/chat/chat_list_screen.dart';
import 'package:ebroker/ui/screens/my_listings_screen.dart';
import 'package:ebroker/ui/screens/profile/profile_screen.dart';
import 'package:ebroker/ui/screens/widgets/add_listing_button.dart';
import 'package:material_ui/material_ui.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  late int _currentTab = widget.initialTab;
  late final PageController _pageController = PageController(
    initialPage: _tabIndexToPagePosition(widget.initialTab),
  );
  final _addListingController = AddListingController();

  static int _tabIndexToPagePosition(int tabIndex) => switch (tabIndex) {
    1 => 1,
    3 => 2,
    4 => 3,
    _ => 0,
  };

  final List<Widget> _pages = [
    const AgentHomeTab(),
    const _AgentChatTab(),
    const _AgentMyListingsTab(),
    const _AgentProfileTab(),
  ];

  void _onTabTapped(int index) {
    _addListingController.close();
    setState(() => _currentTab = index);
    _pageController.jumpToPage(_tabIndexToPagePosition(index));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addListingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleScope(
      role: ActiveRole.agent,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AgentDashboardSummaryCubit()),
          BlocProvider(create: (_) => AgentDashboardListingsCubit()),
          BlocProvider(create: (_) => AgentDashboardCategoryCubit()),
          BlocProvider(create: (_) => AgentDashboardMostViewedCubit()),
          BlocProvider(create: (_) => AgentDashboardActivePackagesCubit()),
        ],
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _pages,
              ),
              AddListingOverlay(controller: _addListingController),
            ],
          ),
          bottomNavigationBar: AgentBottomBar(
            currentTab: _currentTab,
            onTabTapped: _onTabTapped,
            addListingController: _addListingController,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat tab — reuses ChatListScreen, force-refreshes with agent header
// ---------------------------------------------------------------------------

class _AgentChatTab extends StatelessWidget {
  const _AgentChatTab();

  @override
  Widget build(BuildContext context) => const ChatListScreen();
}

// ---------------------------------------------------------------------------
// My Listings tab — reuses PropertiesScreen, force-refreshes with agent header
// ---------------------------------------------------------------------------

class _AgentMyListingsTab extends StatelessWidget {
  const _AgentMyListingsTab();

  @override
  Widget build(BuildContext context) => const MyListingsScreen();
}

// ---------------------------------------------------------------------------
// Profile tab — reuses ProfileScreen; shows "Switch to User" when in agent mode
// ---------------------------------------------------------------------------

class _AgentProfileTab extends StatelessWidget {
  const _AgentProfileTab();

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
