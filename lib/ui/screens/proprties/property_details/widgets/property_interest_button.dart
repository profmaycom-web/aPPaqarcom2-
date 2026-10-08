import 'package:ebroker/data/cubits/property/interest/change_interest_in_property_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';

class PropertyInterestButton extends StatelessWidget {
  const PropertyInterestButton({
    required this.property,
    super.key,
  });

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final interestedProperty = Constant.interestedPropertyIds.contains(
      property.id,
    );

    dynamic icon = AppIcons.interested;
    if (interestedProperty || property.isInterested == '1') {
      icon = Icons.not_interested_outlined;
    }

    return BlocBuilder<
      ChangeInterestInPropertyCubit,
      ChangeInterestInPropertyState
    >(
      builder: (context, state) {
        if (state is ChangeInterestInPropertySuccess) {
          icon = state.interest == PropertyInterest.interested
              ? Icons.not_interested_outlined
              : AppIcons.interested;
        }

        return UiUtils.buildButton(
          context,
          height: 48.rh(context),
          isInProgress: state is ChangeInterestInPropertyInProgress,
          onPressed: () async {
            PropertyInterest interest;

            final contains = Constant.interestedPropertyIds.contains(
              property.id,
            );

            if (contains || property.isInterested == '1') {
              interest = PropertyInterest.notInterested;
            } else {
              interest = PropertyInterest.interested;
            }

            await context.read<ChangeInterestInPropertyCubit>().changeInterest(
              propertyId: property.id!.toString(),
              interest: interest,
            );
          },
          buttonTitle: (icon == Icons.not_interested_outlined
              ? 'interested'.translate(context)
              : 'interest'.translate(context)),
          fontSize: context.font.md,
          textColor: context.color.secondaryColor,
          buttonColor: context.color.textColorDark,
          prefixWidget: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: icon is String
                ? Container(
                    alignment: Alignment.center,
                    child: CustomImage(
                      imageUrl: icon.toString(),
                      width: 18.rw(context),
                      height: 18.rh(context),
                      color: context.color.secondaryColor,
                    ),
                  )
                : Icon(
                    icon as IconData,
                    color: context.color.secondaryColor,
                    size: 18.rh(context),
                  ),
          ),
        );
      },
    );
  }
}
