import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
// TODO(R): update country_picker and then remove flutter/material whenever
// it updates to adapt with material_ui package
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Reusable phone-number input: text field + country picker, combined.
///
/// Consolidates the country-picker dialog, max-length derivation, and
/// live phone-number formatting that were previously copy-pasted across
/// every screen with a phone field.
class PhoneField extends StatefulWidget {
  const PhoneField({
    required this.controller,
    this.focusNode,
    this.validator,
    this.hintText = '0000000000',
    this.enabled = true,
    this.initialCountryCode,
    this.onCountryChanged,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final CustomTextFieldValidator? validator;
  final String hintText;
  final bool enabled;

  /// If provided, this wins over SIM-detected country on first build.
  /// Pass the caller's stored/known country code (e.g. from the user's
  /// saved profile) to avoid it being clobbered by SIM detection.
  final String? initialCountryCode;
  final ValueChanged<String>? onCountryChanged;
  final ValueChanged<String>? onChanged;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late String _countryCode = widget.initialCountryCode ?? '';
  String _flagEmoji = '';

  @override
  void initState() {
    super.initState();
    unawaited(_resolveInitialCountry());
  }

  Future<void> _resolveInitialCountry() async {
    final requestedCode = widget.initialCountryCode;
    if (requestedCode != null && requestedCode.isNotEmpty) {
      final countryList = CountryService().getAll();
      final matched = countryList.firstWhere(
        (country) => country.phoneCode == requestedCode,
        orElse: () => countryList.first,
      );
      if (!mounted) return;
      setState(() {
        _countryCode = matched.phoneCode;
        _flagEmoji = matched.flagEmoji;
      });
      widget.onCountryChanged?.call(matched.phoneCode);
      return;
    }

    final simCountry = await HelperUtils.getSimCountry();
    if (!mounted) return;
    setState(() {
      _countryCode = simCountry.phoneCode;
      _flagEmoji = simCountry.flagEmoji;
    });
    widget.onCountryChanged?.call(simCountry.phoneCode);
  }

  void _openCountryPicker() {
    if (!widget.enabled) return;
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(8),
        backgroundColor: context.color.backgroundColor,
        searchTextStyle: TextStyle(color: context.color.textColorDark),
        textStyle: TextStyle(color: context.color.textColorDark),
        inputDecoration: m.InputDecoration(
          hintStyle: TextStyle(color: context.color.textColorDark),
          helperStyle: TextStyle(color: context.color.textColorDark),
          prefixIcon: const Icon(Icons.search),
          iconColor: context.color.tertiaryColor,
          prefixIconColor: context.color.tertiaryColor,
          focusedBorder: m.OutlineInputBorder(
            borderSide: BorderSide(color: context.color.tertiaryColor),
          ),
          floatingLabelStyle: TextStyle(color: context.color.tertiaryColor),
          labelText: 'search'.translate(context),
          labelStyle: TextStyle(color: context.color.textColorDark),
          border: const m.OutlineInputBorder(),
        ),
      ),
      onSelect: (value) {
        setState(() {
          _flagEmoji = value.flagEmoji;
          _countryCode = value.phoneCode;
        });
        widget.onCountryChanged?.call(value.phoneCode);
      },
    );
  }

  void _handleChange(dynamic rawValue) {
    final formatted = HelperUtils.formatPhoneNumber(
      rawValue.toString(),
      _countryCode,
    );
    setState(() {
      widget.controller.text = formatted;
    });
    widget.onChanged?.call(formatted);
  }

  @override
  Widget build(BuildContext context) {
    // Container/picker placement follows the ambient app direction
    // (Flutter mirrors InputDecoration.prefixIcon automatically under
    // RTL), but the phone digits, country code, and cursor always read
    // left-to-right regardless of app direction.
    return CustomTextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: widget.hintText,
      textDirection: TextDirection.ltr,
      keyboard: TextInputType.phone,
      isReadOnly: !widget.enabled,
      validator: widget.validator,
      maxLength: HelperUtils.getMaxPhoneLength(_countryCode),
      formaters: [FilteringTextInputFormatter.digitsOnly],
      onChange: _handleChange,
      prefix: _CountryPickerChip(
        flagEmoji: _flagEmoji,
        countryCode: _countryCode,
        enabled: widget.enabled,
        onTap: _openCountryPicker,
      ),
    );
  }
}

/// Display-only chip: flag emoji + down-arrow + divider + "+<code>".
/// Private to this file — nothing outside [PhoneField] uses it standalone.
class _CountryPickerChip extends StatelessWidget {
  const _CountryPickerChip({
    required this.flagEmoji,
    required this.countryCode,
    required this.enabled,
    required this.onTap,
  });

  final String? flagEmoji;
  final String? countryCode;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsetsDirectional.only(start: 10),
          height: 48.rh(context),
          alignment: Alignment.center,
          // Flag, arrow, divider, "+code" always render in this fixed
          // left-to-right order — even inside an RTL app — so the chip's
          // internal layout and the country code never mirror.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                CustomText(
                  flagEmoji ?? '',
                  fontSize: context.font.xxl,
                ),
                SizedBox(width: 4.rw(context)),
                CustomImage(
                  imageUrl: AppIcons.downArrow,
                  height: 16.rh(context),
                  width: 16.rw(context),
                  color: context.color.tertiaryColor,
                ),
                SizedBox(width: 4.rw(context)),
                Container(
                  height: 24.rh(context),
                  width: 1,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                SizedBox(width: 4.rw(context)),
                CustomText(
                  '+${countryCode ?? ''}',
                  fontSize: context.font.md,
                  color: context.color.textColorDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
