import 'package:ebroker/exports/main_export.dart';

class UserVerificationCard extends StatelessWidget {
  const UserVerificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userVerificationStatus =
        context.watch<UserDetailsCubit>().state.user?.userVerificationStatus ??
        HiveUtils.getUserDetails().userVerificationStatus;

    if (userVerificationStatus == 'not_applied') {
      return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, Routes.userVerificationForm);
        },
        child: Container(
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'verifyYourAccount'.translate(context),
                      fontSize: context.font.md,
                      fontWeight: .w500,
                    ),
                    SizedBox(height: 4.rh(context)),
                    CustomText(
                      'verifyAccountSubtitle'.translate(context),
                      fontSize: context.font.xs,
                      color: context.color.textLightColor,
                      maxLines: 3,
                    ),
                    UiUtils.buildButton(
                      context,
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
                          Routes.userVerificationForm,
                        );
                      },
                      buttonTitle: 'verifyNow'.translate(context),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.rw(context)),
              CustomImage(
                imageUrl: AppIcons.userBadge,
                height: 100.rh(context),
                fit: .contain,
                color: infoMessageColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      );
    } else if (userVerificationStatus == 'pending') {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'userVerificationUnderReview'.translate(context),
              fontSize: context.font.md,
              fontWeight: FontWeight.w700,
            ),
            SizedBox(height: 4.rh(context)),
            CustomText(
              'userVerificationReviewMessage'.translate(context),
              fontSize: context.font.sm,
              color: context.color.tertiaryColor,
              maxLines: 3,
            ),
          ],
        ),
      );
    } else if (userVerificationStatus == 'rejected') {
      final rejectReason =
          context
              .watch<UserDetailsCubit>()
              .state
              .user
              ?.userVerificationRejectReason ??
          HiveUtils.getUserDetails().userVerificationRejectReason;
      return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, Routes.userVerificationForm);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomText(
                    'userVerificationRejected'.translate(context),
                    fontSize: context.font.lg,
                    fontWeight: FontWeight.w600,
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
                            title: 'userVerificationRejected'.translate(
                              context,
                            ),
                            content: CustomText(rejectReason),
                          ),
                        );
                      },
                      child: CustomImage(
                        imageUrl: AppIcons.info,
                        width: 18.rw(context),
                        height: 18.rh(context),
                        color: context.color.error,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4.rh(context)),
              CustomText(
                'userRejectedMessage'.translate(context),
                fontSize: context.font.sm,
                color: context.color.textLightColor,
              ),
              SizedBox(height: 12.rh(context)),
              UiUtils.buildButton(
                context,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.userVerificationForm,
                  );
                },
                autoWidth: true,
                fontSize: 14.rf(context),
                height: 32.rh(context),
                buttonTitle: 'reApply'.translate(context),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
