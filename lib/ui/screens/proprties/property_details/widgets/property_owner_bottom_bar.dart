import 'package:ebroker/exports/main_export.dart';

class PropertyOwnerBottomBar extends StatelessWidget {
  const PropertyOwnerBottomBar({
    required this.showFeatureButton,
    required this.showEditButton,
    required this.onDeletePressed,
    required this.onEditPressed,
    this.onFeaturePressed,
    super.key,
  });

  final bool showFeatureButton;
  final bool showEditButton;
  final Future<void> Function() onDeletePressed;
  final Future<void> Function() onEditPressed;
  final Future<void> Function(GetSubscriptionPackageLimitsState state)?
  onFeaturePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        boxShadow: [
          BoxShadow(
            color: context.color.textColorDark.withValues(alpha: 0.12),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      height: 72.rh(context),
      child: Row(
        mainAxisSize: .min,
        children: [
          if (showFeatureButton) ...[
            Expanded(
              child:
                  BlocBuilder<
                    GetSubsctiptionPackageLimitsCubit,
                    GetSubscriptionPackageLimitsState
                  >(
                    builder: (context, state) {
                      return _buildActionButton(
                        context,
                        title: 'feature'.translate(context),
                        icon: AppIcons.promoted,
                        onPressed: () {
                          if (onFeaturePressed != null) {
                            unawaited(onFeaturePressed!.call(state));
                          }
                        },
                      );
                    },
                  ),
            ),
            SizedBox(width: 16.rw(context)),
          ],
          if (showEditButton) ...[
            Expanded(
              child: _buildActionButton(
                context,
                title: 'edit'.translate(context),
                icon: AppIcons.edit,
                onPressed: () {
                  unawaited(onEditPressed.call());
                },
              ),
            ),
            SizedBox(width: 16.rw(context)),
          ],
          Expanded(
            child: _buildActionButton(
              context,
              title: 'deleteBtnLbl'.translate(context),
              icon: AppIcons.delete,
              onPressed: () {
                unawaited(onDeletePressed.call());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String icon,
    required VoidCallback onPressed,
  }) {
    return UiUtils.buildButton(
      context,
      fontSize: context.font.md,
      buttonTitle: title,
      padding: const EdgeInsets.all(2),
      height: 48.rh(context),
      onPressed: onPressed,
      prefixWidget: Container(
        alignment: Alignment.center,
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: CustomImage(
          imageUrl: icon,
          color: context.color.buttonColor,
          width: 18.rw(context),
          height: 18.rh(context),
        ),
      ),
    );
  }
}
