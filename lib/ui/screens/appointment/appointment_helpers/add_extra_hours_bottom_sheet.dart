import 'package:ebroker/data/cubits/appointment/delete/delete_extra_time_slot_cubit.dart';
import 'package:ebroker/data/cubits/appointment/post/manage_extra_time_slot_cubit.dart';
import 'package:ebroker/data/model/appointment/agent_time_schedule_model.dart';
import 'package:ebroker/data/model/appointment/booking_preferences_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/appointment/appointment_helpers/appointment_widgets_export.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:table_calendar/table_calendar.dart';

class ExtraTimeSlot {
  ExtraTimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.date,
  });
  final String id;
  final String startTime;
  final String endTime;
  final String date;

  ExtraTimeSlot copyWith({
    String? id,
    String? startTime,
    String? endTime,
    String? date,
  }) {
    return ExtraTimeSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
    };

    if (id.isNotEmpty && !id.startsWith('temp_')) {
      json['id'] = id;
    }

    return json;
  }
}

class AddExtraHoursBottomSheet extends StatefulWidget {
  const AddExtraHoursBottomSheet({
    required this.selectedDate,
    required this.bookingPreferences,
    required this.existingTimeSlots,
    required this.extraSlots,
    this.onSave,
    super.key,
  });

  final DateTime selectedDate;
  final BookingPreferencesModel bookingPreferences;
  final List<TimeSchedule> existingTimeSlots;
  final List<ExtraSlot> extraSlots;
  final VoidCallback? onSave;

  @override
  State<AddExtraHoursBottomSheet> createState() =>
      _AddExtraHoursBottomSheetState();
}

class _AddExtraHoursBottomSheetState extends State<AddExtraHoursBottomSheet> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  List<ExtraTimeSlot> _timeSlots = [];
  final List<String> _slotsToDelete = [];
  late int _bufferTimeMinutes;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate;
    _focusedDay = widget.selectedDate;
    _bufferTimeMinutes =
        int.tryParse(widget.bookingPreferences.bufferTimeMinutes) ?? 0;
    _loadSlotsForSelectedDay();
  }

  String _formatTimeFromApi(String apiTime) {
    try {
      return apiTime.length >= 5 ? apiTime.substring(0, 5) : apiTime;
    } on Exception catch (_) {
      return apiTime;
    }
  }

  void _loadSlotsForSelectedDay() {
    final dateString = AppointmentHelper.getDateKey(_selectedDay);
    final existingForDay = widget.extraSlots
        .where((slot) => slot.date == dateString)
        .map(
          (extraSlot) => ExtraTimeSlot(
            id: extraSlot.id,
            startTime: _formatTimeFromApi(extraSlot.startTime),
            endTime: _formatTimeFromApi(extraSlot.endTime),
            date: extraSlot.date,
          ),
        )
        .toList();
    setState(() {
      _timeSlots = existingForDay;
      _slotsToDelete.clear();
    });
  }

  void _addTimeSlot() {
    final dateString = AppointmentHelper.getDateKey(_selectedDay);
    setState(() {
      _timeSlots.add(
        ExtraTimeSlot(
          id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
          startTime: '',
          endTime: '',
          date: dateString,
        ),
      );
    });
  }

  void _removeTimeSlot(String slotId) {
    setState(() {
      _timeSlots.removeWhere((slot) => slot.id == slotId);
    });
  }

  void _markSlotForDeletion(String slotId) {
    setState(() {
      if (!_slotsToDelete.contains(slotId)) {
        _slotsToDelete.add(slotId);
      }
      _timeSlots.removeWhere((slot) => slot.id == slotId);
    });
  }

  void _updateTimeSlot(String slotId, {String? startTime, String? endTime}) {
    if (startTime == null && endTime == null) return;

    if (startTime != null && endTime != null) {
      try {
        final f = DateFormat('HH:mm');
        if (!f.parse(endTime).isAfter(f.parse(startTime))) {
          HelperUtils.showSnackBarMessage(
            context,
            'endTimeMustBeAfterStartTime',
            type: MessageType.error,
          );
          return;
        }
      } on Exception catch (_) {}
    }

    setState(() {
      _timeSlots = _timeSlots.map((slot) {
        if (slot.id == slotId) {
          return slot.copyWith(
            startTime: startTime ?? slot.startTime,
            endTime: endTime ?? slot.endTime,
          );
        }
        return slot;
      }).toList();
    });
  }

  bool _isDateAvailable(DateTime date) {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return !dateOnly.isBefore(todayOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * 0.8,
      ),
      child: Padding(
        padding: .all(16.rw(context)),
        child: Column(
          mainAxisSize: .min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.rh(context)),
                    _buildCalendarSection(),
                    SizedBox(height: 12.rh(context)),
                    UiUtils.getDivider(context),
                    SizedBox(height: 16.rh(context)),
                    _buildDateTitle(),
                    SizedBox(height: 16.rh(context)),
                    _buildSlotsListSection(),
                    SizedBox(height: 16.rh(context)),
                    _buildAddSlotButton(),
                    SizedBox(height: 24.rh(context)),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            'addExtraHours'.translate(context),
            color: context.color.textColorDark,
            fontSize: context.font.lg,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: CustomImage(
            imageUrl: AppIcons.closeCircle,
            color: context.color.textColorDark,
            fit: .contain,
            width: 24.rw(context),
            height: 24.rh(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return TableCalendar<dynamic>(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      locale: HiveUtils.getLanguageCode(),
      enabledDayPredicate: _isDateAvailable,
      daysOfWeekHeight: 40.rh(context),
      daysOfWeekStyle: AppointmentCalendarStyles.buildDaysOfWeekStyle(context),
      availableGestures: AvailableGestures.none,
      headerStyle: AppointmentCalendarStyles.buildHeaderStyle(context),
      calendarStyle: AppointmentCalendarStyles.buildCalendarStyle(
        context,
        isFromAllSchedules: true,
        timeSchedules: widget.existingTimeSlots,
        extraSlots: widget.extraSlots,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _loadSlotsForSelectedDay();
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        selectedBuilder: AppointmentCalendarStyles.selectedBuilder,
        todayBuilder: AppointmentCalendarStyles.todayBuilder,
        defaultBuilder: (context, day, focusedDay) =>
            AppointmentCalendarStyles.defaultBuilder(
              context,
              day,
              focusedDay,
              isFromAllSchedules: true,
              timeSchedules: widget.existingTimeSlots,
              extraSlots: widget.extraSlots,
            ),
      ),
    );
  }

  Widget _buildDateTitle() {
    return Row(
      children: [
        CustomImage(
          imageUrl: AppIcons.calendar,
          width: 20.rw(context),
          height: 20.rh(context),
          color: context.color.textColorDark,
        ),
        SizedBox(width: 8.rw(context)),
        CustomText(
          DateFormat('dd MMMM, yyyy').format(_selectedDay),
          color: context.color.textColorDark,
          fontSize: context.font.md,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  Widget _buildSlotsListSection() {
    if (_timeSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: .all(16.rw(context)),
        decoration: BoxDecoration(
          color: context.color.primaryColor,
          border: Border.all(color: context.color.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: CustomText(
          'noSchedulesOrTimeSlotsAvailableYet'.translate(context),
          color: context.color.textColorDark,
          fontSize: context.font.sm,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: _timeSlots.map(_buildSlotRow).toList(),
    );
  }

  Widget _buildSlotRow(ExtraTimeSlot slot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: AppointmentTimePicker(
              startTime: slot.startTime,
              endTime: slot.endTime,
              onChanged: (newStart, newEnd) {
                _updateTimeSlot(slot.id, startTime: newStart, endTime: newEnd);
              },
              selectedDate: _selectedDay,
            ),
          ),
          SizedBox(width: 12.rw(context)),
          GestureDetector(
            onTap: () {
              if (slot.id.isEmpty || slot.id.startsWith('temp_')) {
                _removeTimeSlot(slot.id);
              } else {
                _markSlotForDeletion(slot.id);
              }
            },
            child: Container(
              height: 44.rh(context),
              width: 44.rw(context),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSlotButton() {
    return GestureDetector(
      onTap: _addTimeSlot,
      child: Container(
        width: double.infinity,
        height: 44.rh(context),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.tertiaryColor),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              'addSlot'.translate(context),
              color: context.color.tertiaryColor,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(width: 8.rw(context)),
            Icon(
              Icons.add_rounded,
              color: context.color.tertiaryColor,
              size: 20.rh(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<ManageExtraTimeSlotCubit, ManageExtraTimeSlotState>(
      builder: (context, state) {
        final isSaving = state is ManageExtraTimeSlotInProgress;
        return BlocBuilder<DeleteExtraTimeSlotCubit, DeleteExtraTimeSlotState>(
          builder: (context, deleteState) {
            final isDeleting = deleteState is DeleteExtraTimeSlotInProgress;
            final isLoading = isSaving || isDeleting;

            return Row(
              children: [
                Expanded(
                  child: UiUtils.buildButton(
                    context,
                    onPressed: isLoading ? () {} : () => Navigator.pop(context),
                    buttonTitle: 'cancelLbl'.translate(context),
                    fontSize: context.font.sm,
                    height: 48.rh(context),
                    buttonColor: context.color.secondaryColor,
                    textColor: context.color.tertiaryColor,
                    border: BorderSide(color: context.color.tertiaryColor),
                  ),
                ),
                SizedBox(width: 12.rw(context)),
                Expanded(
                  child: UiUtils.buildButton(
                    context,
                    onPressed: isLoading ? () {} : _saveExtraTimeSlot,
                    buttonTitle: 'save'.translate(context),
                    fontSize: context.font.sm,
                    height: 48.rh(context),
                    isInProgress: isLoading,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveExtraTimeSlot() async {
    try {
      if (_timeSlots.isEmpty && _slotsToDelete.isEmpty) {
        HelperUtils.showSnackBarMessage(
          context,
          'noChangesToSave',
          type: MessageType.error,
        );
        return;
      }

      for (final slot in _timeSlots) {
        if (slot.startTime.isEmpty || slot.endTime.isEmpty) {
          HelperUtils.showSnackBarMessage(
            context,
            'pleaseSelectTimeSlot',
            type: MessageType.error,
          );
          return;
        }

        if (!AppointmentHelper.isValidTimeSlot(slot.startTime, slot.endTime)) {
          HelperUtils.showSnackBarMessage(
            context,
            'endTimeMustBeAfterStartTimeForAllSlots',
            type: MessageType.error,
          );
          return;
        }
      }

      for (final slot in _timeSlots) {
        if (_hasConflictWithExisting(slot.id, slot.startTime, slot.endTime)) {
          await Fluttertoast.showToast(
            msg: 'timeConflictsWithExistingSlots'.translate(context),
          );
          return;
        }
        if (_hasConflictWithinNewSlots(slot.id, slot.startTime, slot.endTime)) {
          await Fluttertoast.showToast(
            msg: 'timeConflictsWithNewSlots'.translate(context),
          );
          return;
        }
      }

      if (_slotsToDelete.isNotEmpty) {
        await _deleteMarkedSlots();
      }

      if (_timeSlots.isNotEmpty) {
        await _saveTimeSlots();
      }

      widget.onSave?.call();
      Navigator.pop(context, true);
    } on Exception catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: MessageType.error,
      );
    }
  }

  Future<void> _deleteMarkedSlots() async {
    final parameters = <String, dynamic>{};
    for (var i = 0; i < _slotsToDelete.length; i++) {
      parameters['slot_ids[$i]'] = _slotsToDelete[i];
    }
    await context.read<DeleteExtraTimeSlotCubit>().deleteExtraTimeSlot(
      parameters: parameters,
    );
  }

  Future<void> _saveTimeSlots() async {
    final parameters = <String, dynamic>{};
    for (var i = 0; i < _timeSlots.length; i++) {
      final slot = _timeSlots[i];
      final slotJson = slot.toJson();
      parameters['extra_time_slots[$i][date]'] = slotJson['date'];
      parameters['extra_time_slots[$i][start_time]'] = slotJson['start_time'];
      parameters['extra_time_slots[$i][end_time]'] = slotJson['end_time'];
      if (slotJson['id'] != null && slotJson['id'] != '') {
        parameters['extra_time_slots[$i][id]'] = slotJson['id'];
      }
    }
    await context.read<ManageExtraTimeSlotCubit>().manageExtraTimeSlots(
      parameters: parameters,
    );
  }

  bool _hasConflictWithinNewSlots(
    String slotId,
    String startTime,
    String endTime,
  ) {
    try {
      final timeFormat = DateFormat('HH:mm');
      final rangeStart = timeFormat.parse(startTime);
      final rangeEnd = timeFormat.parse(endTime);
      for (final other in _timeSlots) {
        if (other.id == slotId) continue;
        if (other.startTime.isEmpty || other.endTime.isEmpty) continue;
        final otherStart = timeFormat.parse(other.startTime);
        final otherEnd = timeFormat.parse(other.endTime);

        final otherStartWithBuffer = otherStart.subtract(
          Duration(minutes: _bufferTimeMinutes),
        );
        final otherEndWithBuffer = otherEnd.add(
          Duration(minutes: _bufferTimeMinutes),
        );

        if (rangeStart.isBefore(otherEndWithBuffer) &&
            rangeEnd.isAfter(otherStartWithBuffer)) {
          return true;
        }
      }
    } on Exception {
      return true;
    }
    return false;
  }

  bool _hasConflictWithExisting(
    String slotId,
    String startTime,
    String endTime,
  ) {
    try {
      final timeFormat = DateFormat('HH:mm');
      final rangeStart = timeFormat.parse(startTime);
      final rangeEnd = timeFormat.parse(endTime);

      final dayString = AppointmentHelper.getDateKey(_selectedDay);
      final dayOfWeek = DateFormat('EEEE').format(_selectedDay).toLowerCase();

      // Check conflict with weekly schedule slots
      for (final schedule in widget.existingTimeSlots) {
        if (schedule.dayOfWeek.toLowerCase() != dayOfWeek ||
            schedule.isActive != '1') {
          continue;
        }
        final existingStart = timeFormat.parse(
          _formatTimeFromApi(schedule.startTime),
        );
        final existingEnd = timeFormat.parse(
          _formatTimeFromApi(schedule.endTime),
        );
        final existingStartWithBuffer = existingStart.subtract(
          Duration(minutes: _bufferTimeMinutes),
        );
        final existingEndWithBuffer = existingEnd.add(
          Duration(minutes: _bufferTimeMinutes),
        );
        if (rangeStart.isBefore(existingEndWithBuffer) &&
            rangeEnd.isAfter(existingStartWithBuffer)) {
          return true;
        }
      }

      // Check conflict with extra slots on same day from database
      for (final extra in widget.extraSlots) {
        if (extra.date != dayString) continue;
        // Skip check if it is the current slot we are updating or deleting
        if (extra.id == slotId) continue;
        if (_slotsToDelete.contains(extra.id)) continue;
        if (_timeSlots.any((s) => s.id == extra.id && s.id != slotId)) continue;

        final existingStart = timeFormat.parse(
          _formatTimeFromApi(extra.startTime),
        );
        final existingEnd = timeFormat.parse(
          _formatTimeFromApi(extra.endTime),
        );
        final existingStartWithBuffer = existingStart.subtract(
          Duration(minutes: _bufferTimeMinutes),
        );
        final existingEndWithBuffer = existingEnd.add(
          Duration(minutes: _bufferTimeMinutes),
        );
        if (rangeStart.isBefore(existingEndWithBuffer) &&
            rangeEnd.isAfter(existingStartWithBuffer)) {
          return true;
        }
      }
    } on Exception {
      return true;
    }
    return false;
  }
}
