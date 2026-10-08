import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

/// Reusable contact actions bar for the chat screen.
/// Renders appointment, WhatsApp, and call actions with responsive flex
/// layout and dynamic theme colors (no hardcoded colors or strings).
class ChatContactActions extends StatelessWidget {
  const ChatContactActions({
    required this.canShowAppointment,
    required this.canShowWhatsapp,
    required this.canShowCall,
    required this.onTapBookAppointment,
    required this.onTapWhatsapp,
    required this.onTapCall,
    super.key,
  });

  final bool canShowAppointment;
  final bool canShowWhatsapp;
  final bool canShowCall;
  final VoidCallback onTapBookAppointment;
  final VoidCallback onTapWhatsapp;
  final VoidCallback onTapCall;

  @override
  Widget build(BuildContext context) {
    if (!canShowAppointment && !canShowWhatsapp && !canShowCall) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.rw(context),
        vertical: 8.rh(context),
      ),
      child: Row(
        children: [
          if (canShowAppointment)
            Expanded(
              flex: 12,
              child: _AppointmentButton(onTap: onTapBookAppointment),
            ),
          if (canShowWhatsapp) ...[
            if (canShowAppointment) SizedBox(width: 10.rw(context)),
            Expanded(
              flex: canShowAppointment ? 5 : 1,
              child: _WhatsappButton(
                onTap: onTapWhatsapp,
                showLabel: !canShowAppointment,
              ),
            ),
          ],
          if (canShowCall) ...[
            if (canShowAppointment || canShowWhatsapp)
              SizedBox(width: 10.rw(context)),
            Expanded(
              flex: canShowAppointment ? 5 : 1,
              child: _CallButton(
                onTap: onTapCall,
                showLabel: !canShowAppointment,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentButton extends StatelessWidget {
  const _AppointmentButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? context.color.secondaryColor : context.color.textColorDark;
    final foregroundColor =
        isDark ? context.color.textColorDark : context.color.buttonColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: isDark
              ? Border.all(
                  color: context.color.borderColor.withValues(alpha: 0.6),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 19,
              color: foregroundColor,
            ),
            SizedBox(width: 8.rw(context)),
            CustomText(
              'bookAppointment'.translate(context),
              color: foregroundColor,
              fontWeight: FontWeight.w600,
              fontSize: context.font.sm,
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsappButton extends StatelessWidget {
  const _WhatsappButton({
    required this.onTap,
    required this.showLabel,
  });

  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.tertiaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImage(
              imageUrl: AppIcons.whatsapp,
              width: 22.rw(context),
              height: 22.rh(context),
              color: context.color.buttonColor,
            ),
            if (showLabel) ...[
              SizedBox(width: 8.rw(context)),
              CustomText(
                'whatsapp'.translate(context),
                color: context.color.buttonColor,
                fontWeight: FontWeight.w600,
                fontSize: context.font.sm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.onTap,
    required this.showLabel,
  });

  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? context.color.secondaryColor : context.color.secondaryColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.color.borderColor.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.call,
              color: context.color.textColorDark,
              size: 21,
            ),
            if (showLabel) ...[
              SizedBox(width: 8.rw(context)),
              CustomText(
                'call'.translate(context),
                color: context.color.textColorDark,
                fontWeight: FontWeight.w600,
                fontSize: context.font.sm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
