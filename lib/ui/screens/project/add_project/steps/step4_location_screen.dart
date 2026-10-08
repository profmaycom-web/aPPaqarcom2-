import 'package:ebroker/ui/screens/project/add_project/project_wizard_cubit.dart';
import 'package:ebroker/ui/screens/widgets/location_step_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Step4LocationScreen extends StatelessWidget {
  const Step4LocationScreen({
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
    final cubit = context.read<ProjectWizardCubit>();
    final data = cubit.data;

    final initialLocation = LocationData(
      city: data.city,
      state: data.state,
      country: data.country.isNotEmpty
          ? data.country
          : (data.selectedCountry?.name ?? ''),
      countryId: data.countryId.isNotEmpty
          ? data.countryId
          : data.selectedCountry?.id?.toString(),
      selectedCountry: data.selectedCountry,
      address: data.address,
      clientAddress: data.clientAddress,
      latitude: data.latitude,
      longitude: data.longitude,
    );

    return LocationStepView(
      initialData: initialLocation,
      stepIndicator: '4/6',
      from: 'addProject',
      onLocationDataChanged: (loc) {
        final projectData = context.read<ProjectWizardCubit>().data;
        projectData
          ..city = loc.city
          ..state = loc.state
          ..country = loc.country
          ..countryId = loc.countryId ?? projectData.countryId
          ..address = loc.address
          ..clientAddress = loc.clientAddress
          ..latitude = loc.latitude
          ..longitude = loc.longitude;
        if (loc.selectedCountry != null) {
          projectData
            ..selectedCountry = loc.selectedCountry
            ..country = loc.selectedCountry!.name ?? loc.country
            ..countryId =
                loc.selectedCountry!.id?.toString() ?? projectData.countryId;
        }
      },
      onCountrySelected: (country) {
        context.read<ProjectWizardCubit>().setCountry(country);
      },
      onNext: onNext,
      onBack: onBack,
      onSaveDraft: onSaveDraft,
      isSavingDraft: isSavingDraft,
    );
  }
}
