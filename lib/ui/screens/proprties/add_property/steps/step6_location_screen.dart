import 'package:ebroker/ui/screens/proprties/add_property/property_wizard_cubit.dart';
import 'package:ebroker/ui/screens/widgets/location_step_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Step6LocationScreen extends StatelessWidget {
  const Step6LocationScreen({
    required this.onNext,
    required this.onBack,
    this.onSaveDraft,
    this.isSavingDraft = false,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onSaveDraft;
  final bool isSavingDraft;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PropertyWizardCubit>();
    final data = cubit.data;

    final initialLocation = LocationData(
      city: data.city,
      state: data.state,
      country: data.selectedCountryName.isNotEmpty
          ? data.selectedCountryName
          : (data.selectedCountry?.name ?? data.country),
      countryId:
          data.countryId?.toString() ?? data.selectedCountry?.id?.toString(),
      selectedCountry: data.selectedCountry,
      address: data.address,
      clientAddress: data.clientAddress,
      latitude: data.latitude,
      longitude: data.longitude,
    );

    return LocationStepView(
      initialData: initialLocation,
      stepIndicator: '6/7',
      from: 'addProperty',
      onLocationDataChanged: (loc) {
        final propertyData = context.read<PropertyWizardCubit>().data;
        propertyData
          ..city = loc.city
          ..state = loc.state
          ..country = loc.country
          ..selectedCountryName = loc.country
          ..countryId =
              int.tryParse(loc.countryId ?? '') ?? propertyData.countryId
          ..address = loc.address
          ..clientAddress = loc.clientAddress
          ..latitude = loc.latitude
          ..longitude = loc.longitude;
        if (loc.selectedCountry != null) {
          propertyData
            ..selectedCountry = loc.selectedCountry
            ..selectedCountryName = loc.selectedCountry!.name ?? loc.country
            ..countryId = loc.selectedCountry!.id ?? propertyData.countryId;
        }
      },
      onCountrySelected: (country) {
        context.read<PropertyWizardCubit>().setCountry(country);
      },
      onNext: onNext,
      onBack: onBack,
      onSaveDraft: onSaveDraft,
      isSavingDraft: isSavingDraft,
    );
  }
}
