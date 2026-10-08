import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/helpers/chat_helpers.dart';
import 'package:material_ui/material_ui.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    required this.profilePicture,
    required this.userName,
    required this.propertyTitle,
    required this.propertyImage,
    required this.isBlockedByMe,
    required this.isBlockedByUser,
    required this.isAgent,
    required this.isAgentVerified,
    required this.isUserVerified,
    required this.isAdmin,
    required this.isNotificationPermissionGranted,
    required this.userId,
    required this.propertyId,
    required this.onMenuSelected,
    required this.isFrom,
    required this.onTapBackButton,
    this.hasProperty = true,
    this.receiverRoleContext,
    this.chatType = 'sent',
    super.key,
  });

  final String profilePicture;
  final String userName;
  final String propertyTitle;
  final String propertyImage;
  final bool isBlockedByMe;
  final bool isBlockedByUser;
  final bool isAgent;
  final bool isAdmin;
  final bool isAgentVerified;
  final bool isUserVerified;
  final bool isNotificationPermissionGranted;
  final String userId;
  final String propertyId;
  final Future<void> Function(String action) onMenuSelected;
  final String isFrom;
  final VoidCallback onTapBackButton;
  final bool hasProperty;
  final String? receiverRoleContext;
  final String? chatType;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    final color = context.color;
    final isAgentFacing = RoleScope.of(context) == ActiveRole.agent;

    final bool showVerifiedBadge;
    final bool isAgentBadge;
    if (isAgentFacing) {
      showVerifiedBadge = isUserVerified;
      isAgentBadge = false;
    } else {
      final otherRole =
          receiverRoleContext ??
          (isAgent ? 'agent' : (isAdmin ? 'admin' : 'user'));
      if (otherRole == 'agent' || isAdmin) {
        showVerifiedBadge = isAgentVerified;
        isAgentBadge = true;
      } else {
        showVerifiedBadge = isUserVerified;
        isAgentBadge = false;
      }
    }

    final showInlineProperty = hasProperty && propertyTitle.isNotEmpty;

    return CustomAppBar(
      onTapBackButton: onTapBackButton,
      titleWidget: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 4.rw(context),
          top: 6.rh(context),
          bottom: 6.rh(context),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            ClipOval(
              child: profilePicture.isNotEmpty
                  ? CustomImage(
                      imageUrl: profilePicture,
                      showFullScreenImage: true,
                      width: 38.rw(context),
                      height: 38.rh(context),
                    )
                  : Container(
                      width: 38.rw(context),
                      height: 38.rh(context),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CustomText(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        fontSize: context.font.md,
                        fontWeight: FontWeight.w600,
                        color: context.color.tertiaryColor,
                      ),
                    ),
            ),
            SizedBox(width: 10.rw(context)),
            Expanded(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                mainAxisAlignment: .center,
                children: [
                  Row(
                    mainAxisSize: .min,
                    children: [
                      Flexible(
                        child: CustomText(
                          userName,
                          fontSize: context.font.md,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          color: context.color.textColorDark,
                        ),
                      ),
                      if (showVerifiedBadge) ...[
                        SizedBox(width: 4.rw(context)),
                        VerifiedBadge(
                          type: isAgentBadge ? BadgeType.agent : BadgeType.user,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  if (showInlineProperty) ...[
                    SizedBox(height: 2.rh(context)),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (isFrom == 'property') {
                          Navigator.pop(context);
                        } else {
                          await ChatHelpers.onTapPropertyDetails(
                            context,
                            userId,
                            propertyId,
                          );
                        }
                      },
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${'property'.translate(context)} : ',
                              style: TextStyle(
                                fontSize: context.font.xs,
                                color: context.color.textColorDark.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: propertyTitle,
                              style: TextStyle(
                                fontSize: context.font.xs,
                                color: context.color.tertiaryColor,
                                decoration: TextDecoration.underline,
                                decorationColor: context.color.tertiaryColor,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: onMenuSelected,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: color.primaryColor,
          icon: Icon(
            Icons.more_vert,
            color: context.color.tertiaryColor,
          ),
          itemBuilder: (_) => [
            if (RoleScope.of(context) != ActiveRole.agent &&
                (isAdmin || isAgent))
              PopupMenuItem(
                value: 'agentDetails',
                child: CustomText('agentDetails'.translate(context)),
              ),
            if (!isBlockedByMe)
              PopupMenuItem(
                value: 'blockUser',
                child: CustomText('blockUser'.translate(context)),
              ),
            if (isBlockedByMe)
              PopupMenuItem(
                value: 'unblockUser',
                child: CustomText('unblockUser'.translate(context)),
              ),
            if (!(isBlockedByUser || isBlockedByMe)) ...[
              PopupMenuItem(
                value: 'refreshChat',
                child: CustomText('refreshChat'.translate(context)),
              ),
              PopupMenuItem(
                value: 'deleteAllMessages',
                child: CustomText('deleteAllMessages'.translate(context)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
