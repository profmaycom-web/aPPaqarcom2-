import 'package:ebroker/data/model/appointment/agent_time_schedule_model.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:table_calendar/table_calendar.dart';

/// Centralized calendar styles for appointment screens
class AppointmentCalendarStyles {
  // Check if a date has any active schedules (by weekday) or extra slots (by exact date)
  // Returns:
  // (hasActiveScheduleForWeekday, hasExtraSlotForDate)
  static ({bool hasSchedule, bool hasExtraSlot}) _checkSchedulesAndExtraSlots(
    DateTime date,
    List<TimeSchedule>? timeSchedules,
    List<ExtraSlot>? extraSlots,
  ) {
    if (timeSchedules == null && extraSlots == null) {
      return (hasSchedule: false, hasExtraSlot: false);
    }

    final dayOfWeek = _getDayOfWeekFromDate(date);
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final hasActiveScheduleForWeekday =
        timeSchedules?.any(
          (schedule) =>
              schedule.dayOfWeek.toLowerCase() == dayOfWeek &&
              schedule.isActive == '1',
        ) ??
        false;

    final hasExtraSlotForDate =
        extraSlots?.any((slot) => slot.date == dateString) ?? false;

    return (
      hasSchedule: hasActiveScheduleForWeekday,
      hasExtraSlot: hasExtraSlotForDate,
    );
  }

  static String _getDayOfWeekFromDate(DateTime date) {
    const days = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
    ];
    return days[date.weekday % 7];
  }

  static CalendarStyle buildCalendarStyle(
    BuildContext context, {
    required bool isFromAllSchedules,
    List<TimeSchedule>? timeSchedules,
    List<ExtraSlot>? extraSlots,
  }) {
    return CalendarStyle(
      todayTextStyle: TextStyle(color: context.color.tertiaryColor),
      todayDecoration: BoxDecoration(
        shape: .circle,
        border: Border.all(color: context.color.tertiaryColor),
      ),
      outsideDaysVisible: false,
      cellMargin: EdgeInsets.zero,
      tablePadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      tableBorder: TableBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12.rh(context)),
        ),
      ),
      defaultTextStyle: TextStyle(
        color: context.color.textColorDark,
        fontSize: context.font.sm,
        fontWeight: .w400,
      ),
      selectedTextStyle: TextStyle(
        color: context.color.buttonColor,
        fontSize: context.font.md,
        fontWeight: .w500,
      ),
      selectedDecoration: BoxDecoration(
        color: context.color.tertiaryColor,
        shape: .circle,
      ),
      disabledDecoration: BoxDecoration(
        color: context.color.textLightColor.withValues(alpha: .2),
        // Keep as rectangle for disabled days
      ),
      disabledTextStyle: TextStyle(
        color: context.color.textLightColor,
        fontSize: context.font.sm,
      ),
      weekendTextStyle: TextStyle(
        color: context.color.textLightColor,
        fontSize: context.font.sm,
      ),
      holidayTextStyle: TextStyle(
        color: context.color.tertiaryColor.withValues(alpha: .7),
        fontSize: context.font.sm,
      ),
    );
  }

  // Custom builder for selected days with margin
  static Widget? selectedBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: const EdgeInsets.all(4), // Only selected days get margin
      decoration: BoxDecoration(
        color: context.color.tertiaryColor,
        shape: .circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: context.color.buttonColor,
            fontSize: context.font.md,
            fontWeight: .w500,
          ),
        ),
      ),
    );
  }

  // Custom builder for today with margin
  static Widget? todayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: const EdgeInsets.all(4), // Only today gets margin
      decoration: BoxDecoration(
        shape: .circle,
        border: Border.all(color: context.color.tertiaryColor),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(color: context.color.tertiaryColor),
        ),
      ),
    );
  }

  // Custom builder for default days with conditional bottom border
  static Widget? defaultBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay, {
    required bool isFromAllSchedules,
    List<TimeSchedule>? timeSchedules,
    List<ExtraSlot>? extraSlots,
    List<String>? availableDateKeys,
  }) {
    final result = _checkSchedulesAndExtraSlots(day, timeSchedules, extraSlots);
    final hasExtraSlots = result.hasExtraSlot;
    final hasSchedule = result.hasSchedule;

    return Container(
      margin: .fromLTRB(
        4.rw(context),
        0,
        4.rw(context),
        12.rh(context),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: context.color.textColorDark,
                fontWeight: .w400,
              ),
            ),
          ),
          SizedBox(height: 4.rh(context)),
          SizedBox(
            height: 2,
            child: Row(
              spacing: 2.rw(context),
              mainAxisSize: .min,
              children: [
                if (hasSchedule)
                  Expanded(
                    child: Container(
                      height: 2.rh(context),
                      decoration: const BoxDecoration(
                        color: infoMessageColor,
                      ),
                    ),
                  ),
                if (hasExtraSlots)
                  Expanded(
                    child: Container(
                      height: 2.rh(context),
                      decoration: const BoxDecoration(
                        color: warningMessageColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static HeaderStyle buildHeaderStyle(BuildContext context) {
    final arrow = Transform.flip(
      flipX: Directionality.of(context) == .rtl,
      child: CustomImage(
        imageUrl: AppIcons.arrowRight,
        height: 24.rh(context),
        width: 24.rw(context),
        color: context.color.textColorDark,
      ),
    );

    return HeaderStyle(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.color.borderColor),
          bottom: BorderSide(color: context.color.borderColor),
        ),
      ),
      titleCentered: true,
      titleTextStyle: TextStyle(
        color: context.color.textColorDark,
        fontSize: context.font.md,
        fontWeight: .w500,
      ),
      headerPadding: EdgeInsets.symmetric(
        horizontal: 12.rw(context),
        vertical: 4.rh(context),
      ),
      formatButtonVisible: false,
      rightChevronIcon: arrow,
      leftChevronIcon: Transform.flip(flipX: true, child: arrow),
      titleTextFormatter: (date, locale) =>
          DateFormat.yMMMM(locale.toString()).format(date),
    );
  }

  static DaysOfWeekStyle buildDaysOfWeekStyle(BuildContext context) {
    return DaysOfWeekStyle(
      dowTextFormatter: (date, locale) =>
          DateFormat.E(locale.toString()).format(date)[0],
      weekdayStyle: TextStyle(
        color: context.color.textColorDark,
        fontSize: context.font.md,
        fontWeight: .w400,
      ),
      weekendStyle: TextStyle(
        color: context.color.textColorDark,
        fontSize: context.font.md,
        fontWeight: .w400,
      ),
    );
  }
}
