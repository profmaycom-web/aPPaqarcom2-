import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class NoDataFound extends StatelessWidget {
  const NoDataFound({
    required this.onTapRetry,
    required this.title,
    required this.description,
    super.key,
    this.onTapMainButton,
    this.height,
    this.mainButtonTitle,
    this.showMainButton,
    this.showRetryButton = true,
    this.svgImagePath,
  });

  final double? height;
  final String? svgImagePath;

  final VoidCallback onTapRetry;
  final VoidCallback? onTapMainButton;

  final String title;
  final String description;
  final String? mainButtonTitle;
  final bool? showMainButton;
  final bool showRetryButton;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        children: [
          CustomImage(
            imageUrl: svgImagePath ?? AppIcons.noDataFound,
            height: height ?? 240.rs(context),
          ),
          SizedBox(height: 16.rh(context)),
          CustomText(
            title,
            fontWeight: .w600,
            fontSize: context.font.xl,
            textAlign: .center,
            color: context.color.tertiaryColor,
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 16.rh(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomText(
                description,
                textAlign: .center,
                fontSize: context.font.md,
              ),
            ),
          ],
          if (showMainButton ?? false) ...[
            SizedBox(height: 48.rh(context)),

            UiUtils.buildButton(
              context,
              outerPadding: const EdgeInsets.symmetric(horizontal: 20),
              onPressed: onTapMainButton ?? () {},
              buttonTitle: mainButtonTitle ?? '',
              height: 48.rh(context),
              showElevation: false,
            ),
          ],
          if (showRetryButton) ...[
            SizedBox(height: 8.rh(context)),
            TextButton(
              onPressed: onTapRetry,
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(
                  context.color.tertiaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: CustomText(
                'retry'.translate(context),
                color: context.color.tertiaryColor,
                fontSize: 16,
                fontWeight: .w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
