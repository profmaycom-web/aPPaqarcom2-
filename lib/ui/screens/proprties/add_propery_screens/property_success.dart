import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class PropertyAddSuccess extends StatefulWidget {
  const PropertyAddSuccess({required this.model, super.key});

  final PropertyModel model;

  @override
  State<PropertyAddSuccess> createState() => _PropertyAddSuccessState();
}

class _PropertyAddSuccessState extends State<PropertyAddSuccess> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              CustomImage(
                imageUrl: AppIcons.propertySubmitted,
                width: 260.rs(context),
                height: 260.rs(context),
              ),
              SizedBox(height: 35.rh(context)),
              CustomText(
                'congratulations'.translate(context),
                fontWeight: .bold,
                fontSize: context.font.xl,
                color: context.color.tertiaryColor,
              ),
              SizedBox(height: 8.rh(context)),
              CustomText(
                'submittedSuccess'.translate(context),
                textAlign: .center,
                fontSize: context.font.md,
              ),
              SizedBox(height: 32.rh(context)),
              UiUtils.buildButton(
                context,
                isInProgress: _isNavigating,
                onPressed: _isNavigating
                    ? () {}
                    : () async {
                        setState(() => _isNavigating = true);
                        try {
                          await HelperUtils.navigateToPropertyDetails(
                            context: context,
                            property: widget.model,
                            fromMyProperty: true,
                            fromSuccess: true,
                          );
                        } on Exception catch (_) {
                          // Property navigation errors are handled by the shared helper flow.
                        } finally {
                          if (mounted) setState(() => _isNavigating = false);
                        }
                      },
                height: 48.rh(context),
                width: 224.rw(context),
                buttonColor: context.color.primaryColor,
                textColor: context.color.tertiaryColor,
                border: BorderSide(color: context.color.tertiaryColor),
                buttonTitle: 'previewProperty'.translate(context),
              ),
              SizedBox(height: 8.rh(context)),
              GestureDetector(
                onTap: () async {
                  await HelperUtils.loadMyProperties(context);
                  await Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.main,
                    (route) => false,
                    arguments: {'from': 'propertySuccess'},
                  );
                },
                child: CustomText(
                  'backToHome'.translate(context),
                  fontSize: context.font.md,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
