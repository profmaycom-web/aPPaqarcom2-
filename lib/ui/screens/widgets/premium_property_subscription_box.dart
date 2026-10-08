import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class PremiumPropertySubscriptionBox extends StatelessWidget {
  const PremiumPropertySubscriptionBox({
    super.key,
    this.count = 3,
    this.customCountLabel,
    this.onSubscribePressed,
    this.showCloseButton = false,
    this.onClosePressed,
    this.margin,
    this.padding,
  });

  /// The count of more premium properties (e.g. 3). Defaults to 3.
  final int? count;

  /// Optional override for the count label (e.g. "3+").
  final String? customCountLabel;

  /// Callback when user taps "Subscribe Now".
  final VoidCallback? onSubscribePressed;

  /// Whether to show a close "X" button at the top-right (e.g. in dialogs).
  final bool showCloseButton;

  /// Callback when close button is tapped.
  final VoidCallback? onClosePressed;

  /// Outer margin of the box.
  final EdgeInsetsGeometry? margin;

  /// Inner padding of the box.
  final EdgeInsetsGeometry? padding;

  Future<void> _defaultSubscribePress(BuildContext context) async {
    final apiKeyState = context.read<GetApiKeysCubit>().state;
    final isBankTransferEnabled =
        apiKeyState is GetApiKeysSuccess &&
        apiKeyState.bankTransferStatus == '1';

    await Navigator.pushNamed<dynamic>(
      context,
      Routes.subscriptionPackageListRoute,
      arguments: {
        'from': 'home',
        'isBankTransferEnabled': isBankTransferEnabled,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final countText = customCountLabel ?? (count != null ? '$count+' : '3+');

    return Container(
      width: double.infinity,
      margin:
          margin ??
          EdgeInsets.symmetric(
            horizontal: 16.rw(context),
            vertical: 12.rh(context),
          ),
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: 20.rw(context),
            vertical: 24.rh(context),
          ),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.color.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (showCloseButton)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClosePressed ?? () => Navigator.of(context).pop(),
                child: Container(
                  height: 28.rh(context),
                  width: 28.rw(context),
                  decoration: BoxDecoration(
                    color: context.color.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: context.color.inverseSurface,
                    size: 16.rh(context),
                  ),
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.rw(context),
                height: 64.rh(context),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomImage(
                  imageUrl: AppIcons.premium,
                  width: 36.rw(context),
                  height: 36.rh(context),
                ),
              ),
              SizedBox(height: 16.rh(context)),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${'weFound'.translate(context)} ',
                      style: TextStyle(
                        fontSize: context.font.lg.rf(context),
                        fontWeight: FontWeight.w700,
                        color: context.color.textColorDark,
                      ),
                    ),
                    TextSpan(
                      text: '$countText ',
                      style: TextStyle(
                        fontSize: context.font.lg.rf(context),
                        fontWeight: FontWeight.w700,
                        color: context.color.tertiaryColor,
                      ),
                    ),
                    TextSpan(
                      text: 'morePremiumProperties'.translate(context),
                      style: TextStyle(
                        fontSize: context.font.lg.rf(context),
                        fontWeight: FontWeight.w700,
                        color: context.color.textColorDark,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.rh(context)),
              CustomText(
                'needSubscribeValidPlan'.translate(context),
                textAlign: TextAlign.center,
                fontSize: context.font.sm.rf(context),
                color: context.color.textColorDark.withValues(alpha: 0.65),
                maxLines: 3,
              ),
              SizedBox(height: 20.rh(context)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSubscribePressed ?? () => _defaultSubscribePress(context),
                child: Container(
                  width: double.infinity,
                  height: 48.rh(context),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.color.tertiaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomText(
                    'subscribeNow'.translate(context),
                    fontSize: context.font.md.rf(context),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
