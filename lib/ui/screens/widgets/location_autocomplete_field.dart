import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/map/map_service_factory.dart';
import 'package:ebroker/utils/map/place_details.dart';
import 'package:ebroker/utils/map/place_model.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:material_ui/material_ui.dart';

class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    required this.controller,
    required this.hintText,
    required this.onLocationSelected,
    super.key,
    this.countryId,
    this.countryName,
    this.action = TextInputAction.next,
    this.borderColor,
    this.borderRadius = 6,
    this.fillColor,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final String? countryId;
  final String? countryName;
  final void Function(PlaceDetails details, PlaceModel place)
  onLocationSelected;
  final TextInputAction action;
  final Color? borderColor;
  final double borderRadius;
  final Color? fillColor;
  final ValueChanged<String>? onChanged;
  final CustomTextFieldValidator? validator;

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<PlaceModel>(
      controller: widget.controller,
      focusNode: _focusNode,
      builder: (context, textController, focusNode) {
        return CustomTextFormField(
          controller: textController,
          focusNode: focusNode,
          action: widget.action,
          hintText: widget.hintText,
          borderRadius: widget.borderRadius,
          borderColor: widget.borderColor,
          fillColor: widget.fillColor ?? context.color.secondaryColor,
          validator: widget.validator,
          onChange: (val) {
            widget.onChanged?.call(val?.toString() ?? '');
          },
        );
      },
      decorationBuilder: (context, child) {
        return Material(
          type: MaterialType.card,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          color: context.color.secondaryColor,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.color.borderColor.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            constraints: BoxConstraints(maxHeight: 240.rh(context)),
            child: child,
          ),
        );
      },
      emptyBuilder: (context) => const SizedBox.shrink(),
      loadingBuilder: (context) {
        return Container(
          color: context.color.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: SizedBox(
            width: 20.rw(context),
            height: 20.rh(context),
            child: UiUtils.progress(width: 20, height: 20),
          ),
        );
      },
      itemBuilder: (context, place) {
        final title = place.city.isNotEmpty ? place.city : place.description;
        final subtitle =
            place.description.isNotEmpty && place.description != title
            ? place.description
            : [
                if (place.state.isNotEmpty) place.state,
                if (place.country.isNotEmpty) place.country,
              ].join(', ');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.color.borderColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: CustomImage(
                  imageUrl: AppIcons.location,
                  width: 16.rw(context),
                  height: 16.rh(context),
                  color: context.color.textColorDark.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(width: 10.rw(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      title,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.color.textColorDark,
                      maxLines: 1,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      CustomText(
                        subtitle,
                        fontSize: 11.5,
                        color: context.color.textColorDark.withValues(
                          alpha: 0.6,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      suggestionsCallback: (pattern) async {
        if (pattern.trim().length < 2) {
          return <PlaceModel>[];
        }
        try {
          final searchService = MapServiceFactory.createPlaceSearchService();
          final results = await searchService.searchCities(
            pattern.trim(),
            countryId: widget.countryId,
            countryName: widget.countryName,
          );
          return results;
        } on Exception catch (e) {
          debugPrint('Error fetching suggestions: $e');
          return <PlaceModel>[];
        }
      },
      onSelected: (selectedPlace) async {
        _focusNode.unfocus();
        FocusScope.of(context).unfocus();
        try {
          final searchService = MapServiceFactory.createPlaceSearchService();
          final details = await searchService.getPlaceDetails(
            placeId: selectedPlace.placeId,
            latitude: selectedPlace.latitude,
            longitude: selectedPlace.longitude,
            countryId: widget.countryId,
          );
          widget.onLocationSelected(details, selectedPlace);
        } on Exception catch (e) {
          debugPrint('Error getting place details: $e');
          final fallbackDetails = PlaceDetails(
            city: selectedPlace.city,
            state: selectedPlace.state,
            country: selectedPlace.country,
            address: selectedPlace.description,
            lat: double.tryParse(selectedPlace.latitude),
            lng: double.tryParse(selectedPlace.longitude),
          );
          widget.onLocationSelected(fallbackDetails, selectedPlace);
        }
      },
    );
  }
}
