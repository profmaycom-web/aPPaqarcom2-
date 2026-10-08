import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_dashboard/widgets/common/dashboard_card.dart';
import 'package:material_ui/material_ui.dart';

class VerifyAgentCta extends StatelessWidget {
  const VerifyAgentCta({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentProfileCubit, AgentProfileState>(
      builder: (context, agentState) {
        final user = context.read<UserDetailsCubit>().state.user;
        final agentProfile = agentState is AgentProfileSuccess
            ? agentState.agentProfile.agentProfilePhoto
            : '';

        final isVerified = user?.isAgentVerified ?? false;
        final isVerificationUnderReview =
            user?.agentVerificationStatus == 'pending';
        final isVerificationRejected =
            user?.agentVerificationStatus == 'rejected';
        final agentVerificationRejectReason = agentState is AgentProfileSuccess
            ? agentState.agentProfile.agentVerificationRejectReason
            : null;

        if (isVerified) {
          return const SizedBox.shrink();
        }

        if (isVerificationUnderReview) {
          return DashboardCard(
            padding: EdgeInsets.all(16.rw(context)),
            child: Column(
              children: [
                Container(
                  width: 64.rw(context),
                  height: 64.rh(context),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: .1),
                    shape: .circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 32.rw(context),
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 12.rh(context)),
                CustomText(
                  'agentVerificationUnderReview'.translate(context),
                  fontSize: context.font.xl,
                  fontWeight: .w700,
                  color: context.color.textColorDark,
                  textAlign: .center,
                ),
                SizedBox(height: 6.rh(context)),
                CustomText(
                  'agentVerificationReviewMessage'.translate(context),
                  fontSize: context.font.sm,
                  color: context.color.textLightColor,
                  textAlign: .center,
                  maxLines: 3,
                ),
                SizedBox(height: 14.rh(context)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.rw(context),
                    vertical: 8.rh(context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(
                    'pendingLbl'.translate(context),
                    fontSize: context.font.sm,
                    fontWeight: .w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          );
        }

        if (isVerificationRejected) {
          return DashboardCard(
            padding: EdgeInsets.all(16.rw(context)),
            child: Column(
              children: [
                CustomText(
                  'agentVerificationRejected'.translate(context),
                  fontSize: context.font.xl,
                  fontWeight: .w700,
                  color: context.color.textColorDark,
                  textAlign: .center,
                ),
                SizedBox(height: 6.rh(context)),
                CustomText(
                  'agentVerificationRejectedSubtitle'.translate(context),
                  fontSize: context.font.sm,
                  color: context.color.textLightColor,
                  textAlign: .center,
                  maxLines: 3,
                ),
                if (agentVerificationRejectReason != null &&
                    agentVerificationRejectReason.isNotEmpty) ...[
                  SizedBox(height: 10.rh(context)),
                  GestureDetector(
                    onTap: () async {
                      await UiUtils.showBlurredDialoge(
                        context,
                        dialog: BlurredDialogBox(
                          acceptTextColor: context.color.buttonColor,
                          showCancleButton: false,
                          title: 'agentVerificationRejected'.translate(context),
                          content: CustomText(agentVerificationRejectReason),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: .center,
                      mainAxisSize: .min,
                      children: [
                        CustomImage(
                          imageUrl: AppIcons.info,
                          width: 16.rw(context),
                          height: 16.rh(context),
                          color: Colors.red,
                        ),
                        SizedBox(width: 4.rw(context)),
                        CustomText(
                          'reason'.translate(context),
                          fontSize: context.font.sm,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 14.rh(context)),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      Routes.verifyAgentForm,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 14.rh(context),
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomText(
                        'reApply'.translate(context),
                        fontSize: context.font.md,
                        fontWeight: .w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return DashboardCard(
          padding: EdgeInsets.fromLTRB(
            16.rw(context),
            32.rh(context),
            16.rw(context),
            16.rh(context),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: .none,
                children: [
                  Container(
                    clipBehavior: .hardEdge,
                    width: 80.rw(context),
                    height: 80.rh(context),
                    decoration: BoxDecoration(
                      borderRadius: .circular(8.rw(context)),
                      color: context.color.tertiaryColor.withValues(
                        alpha: .1,
                      ),
                    ),
                    child: CustomImage(imageUrl: agentProfile ?? ''),
                  ),
                  Positioned(
                    bottom: -14.rh(context),
                    child: VerifiedBadge.agentWithBackground(
                      backgroundColor: context.color.tertiaryColor,
                      padding: EdgeInsets.all(8.rw(context)),
                      size: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.rh(context)),
              CustomText(
                'getVerifiedAsTrustedAgent'.translate(context),
                fontSize: context.font.xl,
                fontWeight: .w700,
                color: context.color.textColorDark,
                textAlign: .center,
              ),
              SizedBox(height: 8.rh(context)),
              CustomText(
                'verifiedAgentSubtitle'.translate(context),
                fontSize: context.font.sm,
                color: context.color.textLightColor,
                textAlign: .center,
                maxLines: 3,
              ),
              SizedBox(height: 16.rh(context)),
              UiUtils.buildButton(
                context,
                height: 48.rh(context),
                padding: .all(16.rh(context)),
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.verifyAgentForm),
                buttonTitle: 'verifyNow'.translate(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
