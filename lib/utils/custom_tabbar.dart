import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    required this.tabController,
    required this.tabs,
    required this.isScrollable,
    this.onTap,
    this.margin,
    this.tabBackgroundColor,
    super.key,
  });
  final TabController tabController;
  final List<Widget> tabs;
  final bool isScrollable;
  final void Function(int)? onTap;
  final EdgeInsets? margin;
  final Color? tabBackgroundColor;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedIndicatorColor =
        tabBackgroundColor ??
        (isDark ? const Color(0xFF333333) : context.color.textColorDark);

    final selectedTextColor = isDark
        ? context.color.textColorDark
        : context.color.secondaryColor;

    final unselectedTextColor = isDark
        ? context.color.textLightColor
        : context.color.textColorDark;

    return Container(
      height: 48.rh(context),
      padding: const EdgeInsets.all(4),
      margin:
          margin ??
          EdgeInsets.symmetric(
            horizontal: 16.rw(context),
            vertical: 16.rh(context),
          ),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.color.borderColor),
      ),

      child: TabBar(
        onTap: onTap ?? (value) {},
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelColor: selectedTextColor,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        unselectedLabelColor: unselectedTextColor,
        indicatorSize: .tab,
        physics: isScrollable ? Constant.scrollPhysics : null,
        indicator: BoxDecoration(
          color: selectedIndicatorColor,
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: TextStyle(
          fontSize: context.font.xs.rf(context),
          fontWeight: .w600,
          color: selectedTextColor,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: context.font.xs.rf(context),
          fontWeight: .w500,
          color: unselectedTextColor,
        ),
        tabAlignment: isScrollable ? TabAlignment.center : TabAlignment.fill,
        isScrollable: isScrollable,
        controller: tabController,
        tabs: tabs,
      ),
    );
  }
}
