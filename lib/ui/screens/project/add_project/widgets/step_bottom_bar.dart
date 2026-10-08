import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';

class StepBottomBar extends StatelessWidget {
  const StepBottomBar({
    required this.onNext,
    super.key,
    this.onSaveDraft,
    this.isSubmitting = false,
    this.isSavingDraft = false,
    this.isFinalStep = false,
    this.nextButtonText,
  });

  final VoidCallback onNext;
  final VoidCallback? onSaveDraft;
  final bool isSubmitting;
  final bool isSavingDraft;
  final bool isFinalStep;
  final String? nextButtonText;

  @override
  Widget build(BuildContext context) {
    final nextText =
        nextButtonText ??
        (isFinalStep
            ? 'submitBtnLbl'.translate(context)
            : 'continue'.translate(context));

    final primaryTextColor = context.color.textColorDark;
    final outlinedBorderColor = context.color.textColorDark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: BoxDecoration(
          color: context.color.primaryColor,
          boxShadow: [
            BoxShadow(
              color: context.color.textColorDark.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (onSaveDraft != null) ...[
              Expanded(
                child: SizedBox(
                  height: 48.rh(context),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: outlinedBorderColor, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: (isSubmitting || isSavingDraft)
                        ? null
                        : onSaveDraft,
                    child: isSavingDraft
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.color.tertiaryColor,
                            ),
                          )
                        : CustomText(
                            'saveDraft'.translate(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: SizedBox(
                height: 48.rh(context),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.color.tertiaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: (isSubmitting || isSavingDraft) ? null : onNext,
                  child: isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.color.buttonColor,
                          ),
                        )
                      : CustomText(
                          nextText,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.color.buttonColor,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
