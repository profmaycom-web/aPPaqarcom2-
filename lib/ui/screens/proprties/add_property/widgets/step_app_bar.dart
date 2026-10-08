import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:material_ui/material_ui.dart';

class StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StepAppBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    super.key,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  String _getStepTitle(BuildContext context, int step) {
    switch (step) {
      case 1:
        return 'selectCategory'.translate(context);
      case 2:
        return 'propertyDetails'.translate(context);
      case 3:
        return 'uploadPictures'.translate(context);
      case 4:
        return 'facilities'.translate(context);
      case 5:
        return 'outdoorFacilities'.translate(context);
      case 6:
        return 'location'.translate(context);
      case 7:
        return 'seoSettings'.translate(context);
      default:
        return 'ddPropertyLbl'.translate(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: _getStepTitle(context, currentStep),
      onTapBackButton: onBack,
      preventDefaultPop: true,
      actions: [
        Center(
          child: CustomText(
            '$currentStep/$totalSteps',
            fontSize: context.font.md,
            fontWeight: .w600,
            color: context.color.tertiaryColor,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
