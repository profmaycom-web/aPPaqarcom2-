import 'dart:async';

import 'package:ebroker/data/cubits/utility/place_autocomplete_cubit.dart';
import 'package:ebroker/data/cubits/utility/place_details_cubit.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/map/place_model.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

///This will show when you will need to fill your location,
///
class ChooseLocatonBottomSheet extends StatefulWidget {
  const ChooseLocatonBottomSheet({super.key});

  @override
  State<ChooseLocatonBottomSheet> createState() =>
      ChooseLocatonBottomSheetState();
}

class ChooseLocatonBottomSheetState extends State<ChooseLocatonBottomSheet> {
  final TextEditingController _searchLocation = TextEditingController();
  Timer? delayTimer;
  dynamic cubitReferance;
  int previouseLength = 0;
  PlaceModel? _pendingPlace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlaceDetailsCubit>().reset();
    });

    ///This will create listener which will listen to out text change in text field
    _searchLocation.addListener(() {
      ///If there is no text in text field so we don't need to call an API.
      ///Therefor we are cancel this timer
      ///
      if (_searchLocation.text.isEmpty) {
        delayTimer?.cancel();
      }

      if (delayTimer?.isActive ?? false) delayTimer?.cancel();

      ///Create new timer after cancel previous one
      delayTimer = Timer(const Duration(milliseconds: 500), () async {
        ///Search only if text field is not empty otherwise it will call when we tap on search field,
        if (_searchLocation.text.isNotEmpty) {
          ///Only call when our text doesn't match with our previous text,
          ///When we search `Hello` then it will call API and search city named hello, when we write again hello so it will call again, So why do we need to call it when we have it's data already available?
          if (_searchLocation.text.length != previouseLength) {
            await context.read<PlaceAutocompleteCubit>().getLocationFromText(
              text: _searchLocation.text,
            );

            ///set previous text length
            previouseLength = _searchLocation.text.length;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _searchLocation.dispose();
    delayTimer?.cancel();
    cubitReferance.clearCubit();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    cubitReferance = context.read<PlaceAutocompleteCubit>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaceDetailsCubit, PlaceDetailsState>(
      listener: (context, state) {
        if (state is PlaceDetailsSuccess) {
          final pending = _pendingPlace;
          if (pending == null) return;
          final updated = pending.copyWith(
            latitude: state.details.lat?.toString() ?? '',
            longitude: state.details.lng?.toString() ?? '',
          );
          _pendingPlace = null;
          Navigator.pop(context, updated);
        } else if (state is PlaceDetailsFail) {
          _pendingPlace = null;
        }
      },
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: <Widget>[
            CustomTextFormField(
              controller: _searchLocation,
              fillColor: context.color.tertiaryColor.withValues(
                alpha: 0.01,
              ),
              prefix: Padding(
                padding: .symmetric(horizontal: 8.rw(context)),
                child: CustomImage(
                  imageUrl: AppIcons.search,
                  fit: .contain,
                  color: context.color.tertiaryColor,
                  height: 24.rh(context),
                ),
              ),
              hintText: 'enterLocation'.translate(context),
            ),
            Expanded(
              child:
                  BlocBuilder<PlaceAutocompleteCubit, PlaceAutocompleteState>(
                    builder: (context, googlePlaceState) {
                      if (googlePlaceState is PlaceAutocompleteSuccess) {
                        if (googlePlaceState.autocompleteResult.isNotEmpty) {
                          return ListView.builder(
                            itemCount:
                                googlePlaceState.autocompleteResult.length,
                            itemBuilder: (context, i) {
                              return ListTile(
                                onTap: () {
                                  final selected =
                                      googlePlaceState.autocompleteResult[i];
                                  _pendingPlace = selected;
                                  unawaited(
                                    context.read<PlaceDetailsCubit>().fetch(
                                      placeId: selected.placeId,
                                      latitude: selected.latitude,
                                      longitude: selected.longitude,
                                    ),
                                  );
                                },
                                leading: const Icon(Icons.location_city),
                                title: CustomText(
                                  googlePlaceState
                                      .autocompleteResult[i]
                                      .description,
                                ),
                              );
                            },
                          );
                        }
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(top: 8),
                          child: Center(
                            child: CustomText('noDataFound'.translate(context)),
                          ),
                        );
                      }

                      ///Show progress when loading
                      if (googlePlaceState is PlaceAutocompleteInProgress) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(top: 8),
                          child: Center(
                            child: UiUtils.progress(
                              normalProgressColor: context.color.tertiaryColor,
                            ),
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
