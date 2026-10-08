// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------

import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/add_listing_button.dart';

class AgentBottomBar extends StatelessWidget {
  const AgentBottomBar({
    required this.currentTab,
    required this.onTabTapped,
    required this.addListingController,
    super.key,
  });

  final int currentTab;
  final ValueChanged<int> onTabTapped;
  final AddListingController addListingController;

  Widget _navItem(
    BuildContext context,
    int index,
    String icon,
    String activeIcon,
    String label,
  ) {
    final isActive = currentTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: .opaque,
        onTap: () => onTabTapped(index),
        child: AnimatedScale(
          scale: isActive ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              CustomImage(
                imageUrl: isActive ? activeIcon : icon,
                width: 24.rw(context),
                height: 24.rh(context),
                color: isActive
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: .5),
              ),
              SizedBox(height: 4.rh(context)),
              CustomText(
                label,
                fontSize: context.font.xxs,
                color: isActive
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: .5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76.rh(context),
      padding: .symmetric(horizontal: 8.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            color: context.color.textColorDark.withValues(alpha: .2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: .spaceAround,
        children: [
          _navItem(
            context,
            0,
            AppIcons.home,
            AppIcons.homeActive,
            'dashboard'.translate(context),
          ),
          _navItem(
            context,
            1,
            AppIcons.chat,
            AppIcons.chatActive,
            'chat'.translate(context),
          ),
          // Centre FAB
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Transform.translate(
                  offset: Offset(0, -30.rh(context)),
                  child: AddListingButton(controller: addListingController),
                ),
              ],
            ),
          ),
          _navItem(
            context,
            3,
            AppIcons.properties,
            AppIcons.propertiesActive,
            'myListings'.translate(context),
          ),
          _navItem(
            context,
            4,
            AppIcons.profileOutlined,
            AppIcons.profileActive,
            'profileTab'.translate(context),
          ),
        ],
      ),
    );
  }
}
