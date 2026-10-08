import 'package:ebroker/data/model/user_model.dart';
import 'package:ebroker/exports/main_export.dart';

class AgentStatusCard extends StatelessWidget {
  const AgentStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserDetailsCubit>().state.user;
    final isAgent = RoleScope.of(context) == ActiveRole.agent;
    final becomeAgentStatus = user?.becomeAgentStatus ?? '';
    return _buildCard(context, isAgent, becomeAgentStatus, user);
  }

  Widget _buildCard(
    BuildContext context,
    bool isAgent,
    String becomeAgentStatus,
    UserModel? user,
  ) {
    if (becomeAgentStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [
              context.color.tertiaryColor.withValues(alpha: 0.05),
              context.color.primaryColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: context.color.tertiaryColor.withValues(alpha: .1),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            CustomText(
              'agentProfileUnderReview'.translate(context),
              fontSize: context.font.md,
              fontWeight: .w700,
            ),
            SizedBox(height: 4.rh(context)),
            CustomText(
              'agentReviewMessage'.translate(context),
              fontSize: context.font.sm,
              color: context.color.tertiaryColor,
              maxLines: 3,
            ),
          ],
        ),
      );
    }

    if (becomeAgentStatus == 'rejected') {
      final rejectReason = user?.becomeAgentRejectReason;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.color.borderColor),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                CustomText(
                  'agentRequestRejected'.translate(context),
                  fontSize: context.font.md,
                  fontWeight: .w700,
                  color: context.color.error,
                ),
                if (rejectReason != null && rejectReason.isNotEmpty) ...[
                  SizedBox(width: 8.rw(context)),
                  GestureDetector(
                    onTap: () async {
                      await UiUtils.showBlurredDialoge(
                        context,
                        dialog: BlurredDialogBox(
                          acceptTextColor: context.color.buttonColor,
                          showCancleButton: false,
                          title: 'agentRequestRejected'.translate(
                            context,
                          ),
                          content: CustomText(rejectReason),
                        ),
                      );
                    },
                    child: CustomImage(
                      imageUrl: AppIcons.info,
                      width: 18,
                      height: 18,
                      color: context.color.error,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 4.rh(context)),
            CustomText(
              'agentRejectedMessage'.translate(context),
              fontSize: context.font.sm,
              color: context.color.textLightColor,
              maxLines: 3,
            ),
            SizedBox(height: 12.rh(context)),
            UiUtils.buildButton(
              context,
              buttonTitle: 'reApply'.translate(context),
              autoWidth: true,
              fontSize: 14.rf(context),
              height: 32.rh(context),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.becomeAgentForm,
                  arguments: {'form_type': 'become_agent'},
                );
              },
            ),
          ],
        ),
      );
    }

    if (becomeAgentStatus == 'not_applied' || becomeAgentStatus == '') {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.rw(context),
          vertical: 12.rh(context),
        ),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.color.borderColor),
        ),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  CustomText(
                    'becomeAgentForFree'.translate(context),
                    fontSize: context.font.md,
                    fontWeight: .w500,
                  ),
                  SizedBox(height: 4.rh(context)),
                  CustomText(
                    'becomeAgentSubtitle'.translate(context),
                    fontSize: context.font.xs,
                    color: context.color.textLightColor,
                    maxLines: 3,
                  ),
                  UiUtils.buildButton(
                    context,
                    buttonTitle: 'getStarted'.translate(context),
                    fontSize: 14.rf(context),
                    outerPadding: EdgeInsets.zero,
                    padding: EdgeInsets.symmetric(
                      vertical: 6.rh(context),
                      horizontal: 12.rw(context),
                    ),
                    height: 20.rh(context),
                    autoWidth: true,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.becomeAgentScreen,
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.rw(context)),
            CustomImage(
              imageUrl: AppIcons.becomeAgentIcon,
              height: 100.rh(context),
              fit: .contain,
            ),
          ],
        ),
      );
    }

    if (becomeAgentStatus == 'approved') {
      return Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [
              context.color.tertiaryColor.withValues(alpha: 0.05),
              context.color.primaryColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: context.color.tertiaryColor.withValues(alpha: .1),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  CustomText(
                    isAgent
                        ? 'switchBackToUser'.translate(context)
                        : 'switchToAgent'.translate(context),
                    fontSize: context.font.md,
                    fontWeight: .w700,
                  ),
                  SizedBox(height: 4.rh(context)),
                  CustomText(
                    isAgent
                        ? 'backToHome'.translate(context)
                        : 'exploreAgentDashboard'.translate(context),
                    fontSize: context.font.sm,
                    color: context.color.tertiaryColor,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.rw(context)),
            UiUtils.buildButton(
              context,
              buttonTitle: 'switchNow'.translate(context),
              fontSize: 14,
              onPressed: () {
                if (isAgent) {
                  unawaited(ActiveRoleManager.switchToUser(context));
                } else {
                  unawaited(ActiveRoleManager.switchToAgent(context));
                }
              },
              height: 22.rh(context),
              padding: EdgeInsets.symmetric(
                horizontal: 12.rw(context),
                vertical: 6.rh(context),
              ),
              autoWidth: true,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
