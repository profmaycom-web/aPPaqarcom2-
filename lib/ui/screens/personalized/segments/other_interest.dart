part of '../personalized_property_screen.dart';

class OtherInterests extends StatefulWidget {
  const OtherInterests({
    required this.onInteraction,
    required this.type,
    super.key,
  });

  final PersonalizedVisitType type;
  final dynamic Function(
    RangeValues priceRange,
    List<int> countryIds,
    List<int> propertyType,
  )
  onInteraction;

  @override
  State<OtherInterests> createState() => _OtherInterestsState();
}

class _OtherInterestsState extends State<OtherInterests> {
  /// Countries sent to the API as `country_ids`. Empty means "all countries".
  List<int> _selectedCountryIds = [];
  final TextEditingController _countryController = TextEditingController();
  late final double min = personalizedInterestSettings.priceRange.first;
  late final double max = personalizedInterestSettings.priceRange.last;
  RangeValues _priceRangeValues = const RangeValues(0, 100);
  RangeValues _selectedRangeValues = const RangeValues(0, 50);
  final _minTextController = TextEditingController();
  final _maxTextController = TextEditingController();

  List<int> selectedPropertyType = [0, 1];

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () async {
        selectedPropertyType = personalizedInterestSettings.propertyType;
        _minTextController.text = personalizedInterestSettings.priceRange.first
            .toString();
        _maxTextController.text = personalizedInterestSettings.priceRange.last
            .toString();
        await _restoreSavedCountries();

        widget.onInteraction.call(
          _selectedRangeValues,
          _selectedCountryIds,
          selectedPropertyType,
        );
        setState(() {});
        final state = context.read<FetchSystemSettingsCubit>().state;
        if (state is FetchSystemSettingsSuccess) {
          final settingsData = state.settings['data'];
          final minPrice = double.parse(
            settingsData['min_price']?.toString() ?? '',
          );
          final maxPrice = double.parse(
            settingsData['max_price']?.toString() ?? '',
          );
          _priceRangeValues = RangeValues(minPrice, maxPrice);
          if (min != 0.0 && max != 0.0) {
            _selectedRangeValues = RangeValues(min, max);
          } else {
            _selectedRangeValues = RangeValues(minPrice, maxPrice / 4);
          }
          // Update text controllers with initial values
          _updateTextControllers(_selectedRangeValues);
        }
      },
    );

    // Add listeners to text controllers
    _minTextController.addListener(_handleMinTextChange);
    _maxTextController.addListener(_handleMaxTextChange);
  }

  @override
  void dispose() {
    // Remove listeners when disposing
    _minTextController.removeListener(_handleMinTextChange);
    _maxTextController.removeListener(_handleMaxTextChange);
    _minTextController.dispose();
    _maxTextController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // Update text controllers when range slider changes
  void _updateTextControllers(RangeValues values) {
    _minTextController.text = values.start.toInt().toString();
    _maxTextController.text = values.end.toInt().toString();
  }

  // Handle changes in minimum value text field
  void _handleMinTextChange() {
    if (_minTextController.text.isEmpty) return;

    var newStart = double.tryParse(_minTextController.text);
    if (newStart != null) {
      if (newStart < _priceRangeValues.start) {
        newStart = _priceRangeValues.start;
        _minTextController.text = newStart.toInt().toString();
      }
      if (newStart > _selectedRangeValues.end) {
        newStart = _selectedRangeValues.end;
        _minTextController.text = newStart.toInt().toString();
      }

      setState(() {
        _selectedRangeValues = RangeValues(newStart!, _selectedRangeValues.end);
      });
      widget.onInteraction.call(
        _selectedRangeValues,
        _selectedCountryIds,
        selectedPropertyType,
      );
    }
  }

  // Handle changes in maximum value text field
  void _handleMaxTextChange() {
    if (_maxTextController.text.isEmpty) return;

    var newEnd = double.tryParse(_maxTextController.text);
    if (newEnd != null) {
      if (newEnd > _priceRangeValues.end) {
        newEnd = _priceRangeValues.end;
        _maxTextController.text = newEnd.toInt().toString();
      }
      if (newEnd < _selectedRangeValues.start) {
        newEnd = _selectedRangeValues.start;
        _maxTextController.text = newEnd.toInt().toString();
      }

      setState(() {
        _selectedRangeValues = RangeValues(_selectedRangeValues.start, newEnd!);
      });
      widget.onInteraction.call(
        _selectedRangeValues,
        _selectedCountryIds,
        selectedPropertyType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirstTime = widget.type == PersonalizedVisitType.firstTime;
    final currencySymbol = context.read<FetchSystemSettingsCubit>().getSetting(
      SystemSetting.currencySymbol,
    );
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: CustomAppBar(
        title: 'personalizedFeed'.translate(context),
        actions: [
          if (isFirstTime)
            GestureDetector(
              onTap: () async {
                await HelperUtils.killPreviousPages(
                  context,
                  Routes.main,
                  {'from': 'login'},
                );
              },
              child: Chip(
                label: CustomText(
                  'skip'.translate(context),
                  color: context.color.buttonColor,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              CustomText(
                'selectCountryYouWantToSee'.translate(context),
                maxLines: 2,
                fontSize: context.font.md,
                color: context.color.textColorDark,
                fontWeight: .w500,
              ),
              const SizedBox(
                height: 24,
              ),
              CustomText(
                'country'.translate(context),
                fontSize: context.font.sm,
                color: context.color.textColorDark,
                fontWeight: .w400,
              ),
              SizedBox(height: 8.rh(context)),
              buildCountrySelector(context),
              if (_selectedCountryIds.isNotEmpty) ...[
                const SizedBox(
                  height: 8,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      CustomText(
                        'selectedLocation'.translate(context),
                        fontSize: context.font.sm,
                        fontWeight: .w500,
                        color: context.color.textColorDark,
                      ),
                      SizedBox(width: 4.rw(context)),
                      Expanded(
                        child: CustomText(
                          _countryController.text,
                          fontSize: context.font.md,
                          fontWeight: .w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 12.rh(context)),
              CustomText(
                'choosePropertyType'.translate(context),
                fontSize: context.font.sm,
                color: context.color.textColorDark,
                fontWeight: .w500,
              ),
              SizedBox(height: 8.rh(context)),
              PropertyTypeSelector(
                onInteraction: (values) {
                  selectedPropertyType = values;
                  widget.onInteraction.call(
                    _selectedRangeValues,
                    _selectedCountryIds,
                    values,
                  );

                  setState(() {});
                },
              ),
              SizedBox(height: 28.rh(context)),
              CustomText(
                'chooseTheBudeget'.translate(context),
                fontSize: context.font.md,
                color: context.color.textColorDark,
                fontWeight: .w500,
              ),
              SizedBox(height: 24.rh(context)),
              CustomText(
                'budgetLbl'.translate(context),
                color: context.color.textColorDark,
                fontSize: context.font.sm,
                fontWeight: .w400,
              ),
              SizedBox(height: 8.rh(context)),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        action: .next,
                        controller: _minTextController,
                        isReadOnly: false,
                        prefix: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: CustomText(
                            currencySymbol.toString(),
                            fontSize: context.font.md,
                            fontWeight: .w500,
                            color: context.color.textColorDark,
                          ),
                        ),
                        keyboard: TextInputType.number,
                        validator: CustomTextFieldValidator.nullCheck,
                        hintText: 'min'.translate(context),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: CustomTextFormField(
                        action: .next,
                        controller: _maxTextController,
                        prefix: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: CustomText(
                            currencySymbol.toString(),
                            fontSize: context.font.md,
                            fontWeight: .w500,
                            color: context.color.textColorDark,
                          ),
                        ),
                        isReadOnly: false,
                        keyboard: TextInputType.number,
                        validator: CustomTextFieldValidator.nullCheck,
                        hintText: 'max'.translate(context),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.rh(context)),
              Row(
                children: [
                  CustomText(
                    'priceRange'.translate(context),
                    fontSize: context.font.sm,
                    color: context.color.textColorDark,
                    fontWeight: .w500,
                  ),
                  SizedBox(width: 4.rw(context)),
                  CustomText(
                    '$currencySymbol ${_priceRangeValues.start.round()} ${'to'.translate(context).toUpperCase()} $currencySymbol ${_priceRangeValues.end.round()}',
                    fontSize: context.font.sm,
                    color: context.color.tertiaryColor,
                    fontWeight: .w400,
                  ),
                ],
              ),
              SizedBox(height: 12.rh(context)),
              RangeSlider(
                activeColor: context.color.tertiaryColor,
                inactiveColor: context.color.borderColor,
                values: _selectedRangeValues,
                onChanged: (value) {
                  setState(() {
                    _selectedRangeValues = value;
                    _updateTextControllers(
                      value,
                    ); // Update text controllers when slider changes
                  });
                  widget.onInteraction.call(
                    _selectedRangeValues,
                    _selectedCountryIds,
                    selectedPropertyType,
                  );
                },
                min: _priceRangeValues.start,
                max: _priceRangeValues.end,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Prefills the field with the countries saved on the personalized feed,
  /// falling back to the country selected in the header on a first visit.
  Future<void> _restoreSavedCountries() async {
    var savedIds = personalizedInterestSettings.countryIds;
    if (savedIds.isEmpty) {
      final headerCountryId = int.tryParse(
        HiveUtils.getSelectedCountryId() ?? '',
      );
      if (headerCountryId != null) savedIds = [headerCountryId];
    }
    if (savedIds.isEmpty) {
      _applySelectedCountries([]);
      return;
    }

    final countriesCubit = context.read<FetchCountriesCubit>();
    if (countriesCubit.countries.isEmpty) {
      await countriesCubit.fetchCountries();
    }
    if (!mounted) return;
    _applySelectedCountries(savedIds);
  }

  /// Keeps the picked countries and the field label in sync.
  void _applySelectedCountries(List<int> ids) {
    _selectedCountryIds = ids;
    final names = ids
        .map(
          (id) => context
              .read<FetchCountriesCubit>()
              .getCountry(id: id.toString())
              ?.name,
        )
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
    _countryController.text = names.isEmpty
        ? 'allCountries'.translate(context)
        : names.join(', ');
  }

  Widget buildCountrySelector(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final selected = await CountryMultiSelectionBottomSheet.show(
          context,
          initialSelectedIds: _selectedCountryIds,
        );
        if (selected != null && mounted) {
          _applySelectedCountries(
            selected.map((c) => c.id).whereType<int>().toList(),
          );
          widget.onInteraction.call(
            _selectedRangeValues,
            _selectedCountryIds,
            selectedPropertyType,
          );
          setState(() {});
        }
      },
      child: Container(
        height: 48.rh(context),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.color.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomText(
                _countryController.text.isNotEmpty
                    ? _countryController.text
                    : 'selectCountry'.translate(context),
                fontSize: context.font.md,
                color: _countryController.text.isNotEmpty
                    ? context.color.textColorDark
                    : context.color.textLightColor,
              ),
            ),
            CustomImage(
              imageUrl: AppIcons.downArrow,
              color: context.color.textColorDark,
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyTypeSelector extends StatefulWidget {
  const PropertyTypeSelector({
    required this.onInteraction,
    super.key,
  });

  final dynamic Function(List<int> values) onInteraction;

  @override
  State<PropertyTypeSelector> createState() => _PropertyTypeSelectorState();
}

class _PropertyTypeSelectorState extends State<PropertyTypeSelector> {
  // Define dropdown options as static lists
  static const List<int> sellOption = [0];
  static const List<int> rentOption = [1];

  List<int> selectedPropertyType = sellOption;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        if (personalizedInterestSettings.propertyType.isNotEmpty) {
          // Match the saved property type with dropdown options
          final savedType = personalizedInterestSettings.propertyType;
          if (savedType.length == 1 && savedType[0] == 0) {
            selectedPropertyType = sellOption;
          } else if (savedType.length == 1 && savedType[0] == 1) {
            selectedPropertyType = rentOption;
          } else {
            // Default to sell if no exact match
            selectedPropertyType = sellOption;
          }
        }

        widget.onInteraction.call(selectedPropertyType);
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.rh(context),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.color.borderColor),
      ),
      child: DropdownButtonFormField<List<int>>(
        key: ValueKey(selectedPropertyType),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        initialValue: selectedPropertyType,
        itemHeight: 48.rh(context),
        dropdownColor: context.color.secondaryColor,
        iconSize: 22.rh(context),
        icon: Padding(
          padding: EdgeInsetsDirectional.only(end: 16.rw(context)),
          child: CustomImage(
            imageUrl: AppIcons.downArrow,
            color: context.color.textColorDark,
          ),
        ),
        items: [
          DropdownMenuItem(
            value: sellOption,
            child: CustomText('sell'.translate(context)),
          ),
          DropdownMenuItem(
            value: rentOption,
            child: CustomText('rent'.translate(context)),
          ),
        ],
        onChanged: (value) {
          selectedPropertyType = value!;
          widget.onInteraction.call(selectedPropertyType);
          setState(() {});
        },
      ),
    );
  }
}
