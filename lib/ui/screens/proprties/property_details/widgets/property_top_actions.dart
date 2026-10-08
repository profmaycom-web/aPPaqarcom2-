import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class PropertyTopActions extends StatelessWidget {
  const PropertyTopActions({
    required this.property,
    required this.isThreeDImageAvailable,
    required this.onActionSelected,
    required this.onTapThreeDView,
    super.key,
  });

  final PropertyModel property;
  final bool isThreeDImageAvailable;
  final Future<void> Function(String value) onActionSelected;
  final Future<void> Function() onTapThreeDView;

  bool get _isOwner => property.addedBy.toString() == HiveUtils.getUserId();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        if (isThreeDImageAvailable)
          GestureDetector(
            onTap: () async {
              await onTapThreeDView();
            },
            child: Container(
              height: 32.rh(context),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
              margin: EdgeInsetsDirectional.only(end: 8.rw(context)),
              decoration: BoxDecoration(
                color: context.color.tertiaryColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  SizedBox(
                    height: 16.rh(context),
                    width: 16.rw(context),
                    child: CustomImage(
                      imageUrl: AppIcons.v360Degree,
                      color: context.color.tertiaryColor,
                      fit: .contain,
                    ),
                  ),
                  SizedBox(width: 4.rw(context)),
                  CustomText(
                    '360°',
                    color: context.color.tertiaryColor,
                    fontSize: context.font.xxs,
                    fontWeight: .w500,
                  ),
                ],
              ),
            ),
          ),
        if (_isOwner && !HiveUtils.isGuest())
          PopupMenuButton<String>(
            color: context.color.secondaryColor,
            position: PopupMenuPosition.under,
            padding: .zero,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: context.color.borderColor),
              borderRadius: .circular(12.rw(context)),
            ),

            menuPadding: .symmetric(
              horizontal: 12.rw(context),
              vertical: 8.rh(context),
            ),
            onSelected: (value) async {
              await onActionSelected(value);
            },

            itemBuilder: (context) {
              return [
                _buildPopupMenuItem(
                  context: context,
                  title: 'share',
                  icon: AppIcons.shareIcon,
                ),
                _buildPopupMenuItem(
                  context: context,
                  title: 'interestedUsers',
                  icon: AppIcons.interestedUsers,
                ),
                if (property.propertyType != 'sold' &&
                    property.requestStatus.toString() == 'approved' &&
                    property.status.toString() == '1')
                  _buildPopupMenuItem(
                    context: context,
                    title: property.propertyType == 'rent'
                        ? 'markAsRented'
                        : property.propertyType == 'rented'
                        ? 'markAsRent'
                        : 'markAsSold',
                    icon: AppIcons.changeStatus,
                  ),
                if (property.isExpired ?? false)
                  _buildPopupMenuItem(
                    context: context,
                    title: 'renewListing',
                    icon: AppIcons.changeStatus,
                  ),
              ];
            },
            child: Container(
              margin: const EdgeInsetsDirectional.only(end: 16),
              alignment: Alignment.center,
              child: Icon(
                Icons.more_horiz_rounded,
                size: 24.rh(context),
                color: context.color.textColorDark,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () async {
              await onActionSelected('share');
            },
            child: Container(
              margin: const EdgeInsetsDirectional.only(end: 16),
              alignment: Alignment.center,
              child: CustomImage(
                imageUrl: AppIcons.shareIcon,
                height: 24.rh(context),
                color: context.color.textColorDark,
              ),
            ),
          ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required BuildContext context,
    required String title,
    required String icon,
  }) {
    return PopupMenuItem<String>(
      value: title,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            height: 20.rh(context),
            width: 20.rw(context),
            alignment: Alignment.center,
            child: CustomImage(
              imageUrl: icon,
              color: context.color.textColorDark,
            ),
          ),
          SizedBox(width: 8.rw(context)),
          CustomText(title.translate(context)),
        ],
      ),
    );
  }
}
