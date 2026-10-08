import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';

/// Pill badge for a project's construction stage ('upcoming' /
/// 'under_construction'), styled to match SellRentLabel.
class ProjectTypeLabel extends StatelessWidget {
  const ProjectTypeLabel({required this.projectType, super.key});
  final String projectType;

  @override
  Widget build(BuildContext context) {
    final color = projectType.toLowerCase() == 'upcoming'
        ? Colors.blue
        : Colors.amber;
    return Container(
      height: 24.rh(context),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(48),
      ),
      child: CustomText(
        projectType.toLowerCase().translate(context),
        fontWeight: .w500,
        fontSize: context.font.xxs,
        color: color,
      ),
    );
  }
}
