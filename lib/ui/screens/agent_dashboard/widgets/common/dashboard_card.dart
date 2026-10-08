import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          margin ??
          .only(
            bottom: 16.rh(context),
            right: 16.rw(context),
            left: 16.rw(context),
          ),
      alignment: .center,
      padding: padding ?? EdgeInsets.all(16.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.color.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
