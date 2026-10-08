import 'package:ebroker/data/cubits/appointment/get/fetch_agent_time_schedules_cubit.dart';
import 'package:ebroker/data/cubits/appointment/get/fetch_booking_preferences_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/appointment/configuration_screens/all_schedules_screen.dart';
import 'package:ebroker/ui/screens/appointment/configuration_screens/booking_preferences.dart';
import 'package:ebroker/ui/screens/appointment/configuration_screens/set_business_hours_screen.dart';
import 'package:material_ui/material_ui.dart';

class AppointmentConfigurationScreen extends StatefulWidget {
  const AppointmentConfigurationScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute<dynamic>(
      builder: (context) => const AppointmentConfigurationScreen(),
    );
  }

  @override
  State<AppointmentConfigurationScreen> createState() =>
      _AppointmentConfigurationScreenState();
}

class _AppointmentConfigurationScreenState
    extends State<AppointmentConfigurationScreen> {
  @override
  void initState() {
    super.initState();
    // Load booking preferences initially to ensure validation states are populated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        context.read<FetchBookingPreferencesCubit>().fetchBookingPreferences(),
      );
    });
  }

  bool _areBookingPreferencesValid() {
    final bookingPrefsState = context
        .read<FetchBookingPreferencesCubit>()
        .state;

    if (bookingPrefsState is FetchBookingPreferencesLoading) {
      HelperUtils.showSnackBarMessage(
        context,
        'loading'.translate(context),
        type: MessageType.warning,
      );
      return false;
    }

    if (bookingPrefsState is! FetchBookingPreferencesSuccess) {
      return false;
    }

    final preferences = bookingPrefsState.bookingPreferences;

    // Check all required fields except autoConfirm
    return preferences.meetingDurationMinutes.isNotEmpty &&
        preferences.bufferTimeMinutes.isNotEmpty &&
        preferences.leadTimeMinutes.isNotEmpty &&
        preferences.availableMeetingTypes.isNotEmpty;
  }

  Future<void> _showValidationWarning() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 48.rw(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: context.color.secondaryColor,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  CustomText(
                    'incomplete'.translate(context),
                    color: context.color.textColorDark,
                    fontSize: context.font.lg,
                    fontWeight: .w600,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: CustomImage(
                      imageUrl: AppIcons.closeCircle,
                      color: context.color.textColorDark,
                      fit: .contain,
                      height: 24.rh(context),
                      width: 24.rw(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.rh(context)),
              UiUtils.getDivider(context),
              SizedBox(height: 16.rh(context)),
              CustomText(
                'pleaseFillAllFieldsInBookingPreferences'.translate(context),
                color: context.color.textColorDark,
                fontSize: context.font.md,
              ),
              SizedBox(height: 16.rh(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubScreen(Widget screen, String title) {
    Navigator.push(
      context,
      CupertinoPageRoute<dynamic>(
        builder: (context) => Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: CustomAppBar(
            title: title,
          ),
          body: Padding(
            padding: .all(16.rw(context)),
            child: screen,
          ),
        ),
      ),
    );
  }

  void _onNavigateToScreen(Widget screen, String title) {
    if (!_areBookingPreferencesValid()) {
      unawaited(_showValidationWarning());
    } else {
      _navigateToSubScreen(screen, title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      FetchBookingPreferencesCubit,
      FetchBookingPreferencesState
    >(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            clearAppointmentCubits();
            Navigator.pop(context);
          },
          child: Scaffold(
            backgroundColor: context.color.primaryColor,
            appBar: CustomAppBar(
              title: 'appointmentConfiguration'.translate(context),
              onTapBackButton: clearAppointmentCubits,
            ),
            body: state is FetchBookingPreferencesLoading
                ? Padding(
                    padding: EdgeInsets.all(16.rw(context)),
                    child: CustomShimmer(
                      height: 180.rh(context),
                      width: double.infinity,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: .all(16.rw(context)),
                    child: Container(
                      padding: EdgeInsets.all(12.rw(context)),
                      decoration: BoxDecoration(
                        color: context.color.secondaryColor,
                        borderRadius: BorderRadius.circular(8.rh(context)),
                        border: Border.all(color: context.color.borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            context: context,
                            title: 'bookingPreferences'.translate(context),
                            iconPath: AppIcons.preferences,
                            onTap: () {
                              _navigateToSubScreen(
                                const BookingPreferecesScreen(),
                                'bookingPreferences'.translate(context),
                              );
                            },
                          ),
                          _buildDivider(context),
                          _buildMenuItem(
                            context: context,
                            title: 'setBusinessHours'.translate(context),
                            iconPath: AppIcons.transaction,
                            onTap: () {
                              _onNavigateToScreen(
                                const SetBusinessHoursScreen(),
                                'setBusinessHours'.translate(context),
                              );
                            },
                          ),
                          _buildDivider(context),
                          _buildMenuItem(
                            context: context,
                            title: 'allSchedules'.translate(context),
                            iconPath: AppIcons.calendarFilled,
                            onTap: () {
                              _onNavigateToScreen(
                                const AllSchedulesScreen(),
                                'allSchedules'.translate(context),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: .all(8.rw(context)),
            decoration: BoxDecoration(
              color: context.color.textColorDark.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6.rh(context)),
            ),
            alignment: Alignment.center,
            child: CustomImage(
              imageUrl: iconPath,
              color: context.color.textColorDark,
              fit: .contain,
              height: 20.rh(context),
            ),
          ),
          SizedBox(width: 16.rw(context)),
          Expanded(
            child: CustomText(
              title,
              color: context.color.textColorDark,
              fontSize: context.font.md,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 12.rh(context)),
        UiUtils.getDivider(context),
        SizedBox(height: 12.rh(context)),
      ],
    );
  }

  void clearAppointmentCubits() {
    context.read<FetchBookingPreferencesCubit>().clear();
    context.read<FetchAgentTimeSchedulesCubit>().clear();
  }
}
