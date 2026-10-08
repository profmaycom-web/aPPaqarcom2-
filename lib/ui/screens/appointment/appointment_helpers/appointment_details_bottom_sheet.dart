import 'package:ebroker/data/model/appointment/appointment_model.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/ui/screens/appointment/appointment_helpers/report_user_dialog.dart';
import 'package:ebroker/ui/screens/home/widgets/sell_rent_label.dart';
import 'package:ebroker/ui/screens/widgets/verified_badge.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:material_ui/material_ui.dart';

class AppointmentDetailsBottomSheet extends StatelessWidget {
  const AppointmentDetailsBottomSheet({
    required this.appointment,
    required this.isFromAgentAppointments,
    required this.isFromPreviousAppointments,
    super.key,
  });

  final AppointmentModel appointment;
  final bool isFromAgentAppointments;
  final bool isFromPreviousAppointments;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: .min,
        children: [
          // Property Details Card
          _buildPropertyDetailsCard(context),

          // User/Contact Details
          _buildUserDetailsSection(context),

          // User Message Section
          _buildUserMessageSection(context),
        ],
      ),
    );
  }

  Widget _buildPropertyDetailsCard(BuildContext context) {
    final property = appointment.property;
    if (property == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: .start,
      children: [
        // Property Details Card
        _buildPropertyCard(context, property),
        SizedBox(height: 10.rh(context)),
        // Facilites
        _buildFacilitesSection(context, property),
        SizedBox(height: 10.rh(context)),
        // Price
        _buildPriceSection(context, property),
        SizedBox(height: 10.rh(context)),
        UiUtils.getDivider(context),
        SizedBox(height: 10.rh(context)),
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context, PropertyModel property) {
    final price =
        property.propertyType?.toLowerCase() == 'sell' ||
            property.propertyType?.toLowerCase() == 'sold'
        ? property.price
        : '${property.price} / ${property.rentduration}';
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        CustomText(
          'price'.translate(context),
          fontWeight: .w500,
          color: context.color.textLightColor,
        ),
        CustomText(
          price?.priceFormat(context: context) ?? '',
          fontSize: context.font.md,
          fontWeight: .w500,
          color: context.color.tertiaryColor,
        ),
      ],
    );
  }

  Widget _buildPropertyCard(BuildContext context, PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CustomImage(
              imageUrl: property.titleImage ?? '',
              height: 82.rh(context),
              width: 120.rw(context),
              loadingImageHash: property.lowQualityTitleImage,
            ),
          ),
          SizedBox(width: 12.rw(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    CustomImage(
                      imageUrl: property.category?.image ?? '',
                      height: 18.rh(context),
                      fit: .contain,
                      width: 18.rw(context),
                    ),
                    SizedBox(width: 4.rw(context)),
                    Expanded(
                      child: CustomText(
                        property.category?.translatedName ??
                            property.category?.category ??
                            '',
                        fontSize: context.font.xxs,
                        fontWeight: .w500,
                      ),
                    ),
                    SellRentLabel(
                      propertyType: property.propertyType ?? '',
                    ),
                  ],
                ),
                SizedBox(height: 8.rh(context)),
                CustomText(
                  property.translatedTitle ?? property.title ?? '',
                  fontSize: context.font.md,
                ),
                SizedBox(height: 4.rh(context)),
                Row(
                  children: [
                    CustomImage(
                      imageUrl: AppIcons.location,
                      height: 18.rh(context),
                      fit: .contain,
                      width: 18.rw(context),
                    ),
                    SizedBox(width: 4.rw(context)),
                    Expanded(
                      child: CustomText(
                        property.address ?? '',
                        fontSize: context.font.xxs,
                        color: context.color.textLightColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitesSection(BuildContext context, PropertyModel property) {
    final parameters = property.parameters;
    if (parameters == null || parameters.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.color.borderColor),
      ),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: List.generate(
          (parameters.length) < 4 ? parameters.length : 4,
          (index) {
            final value = parameters[index].translatedValue?.isNotEmpty == true
                ? parameters[index].translatedValue
                : parameters[index].value;
            final translatedValue = value.runtimeType == List
                ? (value as List?)?.join(', ')
                : value?.toString() ?? '';
            return Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: (index != (parameters.length) - 1)
                      ? BorderDirectional(
                          end: BorderSide(
                            color: context.color.borderColor,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: .min,
                  mainAxisAlignment: .center,
                  children: [
                    CustomImage(
                      imageUrl: parameters[index].image ?? '',
                      height: 18.rh(context),
                      width: 18.rw(context),
                      color: context.color.textColorDark,
                      fit: .contain,
                    ),
                    SizedBox(width: 16.rw(context)),
                    Flexible(
                      child: CustomText(
                        translatedValue ?? '',
                        fontSize: context.font.xxs,
                        color: context.color.textColorDark,
                        maxLines: 3,
                        fontWeight: .w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserDetailsSection(BuildContext context) {
    final user = isFromAgentAppointments ? appointment.user : appointment.agent;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  CustomText(
                    isFromAgentAppointments
                        ? 'userName'.translate(context)
                        : 'agentName'.translate(context),
                    fontSize: context.font.xs,
                    fontWeight: .w500,
                    color: context.color.textLightColor,
                  ),
                  Row(
                    spacing: 4.rw(context),
                    children: [
                      CustomText(
                        user.name ?? '',
                        fontWeight: .w500,
                        maxLines: 2,
                        color: context.color.textColorDark,
                      ),
                      VerifiedBadge.conditional(
                        isAgentVerified: user.isAgentVerified ?? false,
                        isUserVerified: user.isUserVerified ?? false,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isFromAgentAppointments) ...[
              UiUtils.buildButton(
                context,
                onPressed: () => _showReportUserDialog(context),
                buttonColor: context.color.secondaryColor,
                border: BorderSide(color: context.color.textColorDark),
                height: 36.rh(context),
                autoWidth: true,
                showElevation: false,
                fontSize: context.font.md,
                textColor: context.color.textColorDark,
                buttonTitle: 'reportUser'.translate(context),
              ),
            ],
          ],
        ),

        SizedBox(height: 10.rh(context)),
        UiUtils.getDivider(context),
        SizedBox(height: 10.rh(context)),

        // Phone
        _buildDetailRow(
          context,
          AppIcons.call,
          'phone'.translate(context),
          user.mobile ?? '',
        ),
        SizedBox(height: 12.rh(context)),

        // Email
        _buildDetailRow(
          context,
          AppIcons.email,
          'email'.translate(context),
          user.email ?? '',
        ),
        SizedBox(height: 10.rh(context)),
      ],
    );
  }

  Future<void> _showReportUserDialog(BuildContext context) async {
    final user = appointment.user;
    if (user?.id == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) => ReportUserDialog(
        userId: user!.id!,
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String icon,
    String label,
    String value,
  ) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: .start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.color.textColorDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: CustomImage(
            imageUrl: icon,
            height: 16.rh(context),
            width: 16.rw(context),
            color: context.color.textColorDark,
          ),
        ),
        SizedBox(width: 4.rw(context)),
        Column(
          crossAxisAlignment: .start,
          children: [
            CustomText(
              label,
              color: context.color.textColorDark,
            ),
            SizedBox(height: 4.rh(context)),
            CustomText(
              value,
              fontSize: context.font.xs,
              fontWeight: .w500,
              color: context.color.textLightColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserMessageSection(BuildContext context) {
    final note = appointment.notes;
    if (note.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: .start,
      children: [
        UiUtils.getDivider(context),
        SizedBox(height: 10.rh(context)),
        CustomText(
          'userMessage'.translate(context),
          fontWeight: .w500,
          color: context.color.textColorDark,
        ),
        SizedBox(height: 8.rh(context)),
        CustomText(
          note,
          fontSize: context.font.xs,
          color: context.color.textLightColor,
        ),
        SizedBox(height: 10.rh(context)),
      ],
    );
  }
}
