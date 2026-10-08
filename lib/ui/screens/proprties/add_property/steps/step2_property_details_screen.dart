import 'dart:async';

import 'package:ebroker/data/cubits/ai/generate_ai_content_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/data/model/languages_model.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/ui/screens/proprties/add_property/property_wizard_cubit.dart';
import 'package:ebroker/ui/screens/proprties/add_property/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/ui/screens/widgets/generate_with_ai_button.dart';
import 'package:ebroker/ui/screens/widgets/ui_switch.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class Step2PropertyDetailsScreen extends StatefulWidget {
  const Step2PropertyDetailsScreen({
    required this.onNext,
    required this.onBack,
    this.onSaveDraft,
    super.key,
    this.isSavingDraft = false,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onSaveDraft;
  final bool isSavingDraft;

  @override
  State<Step2PropertyDetailsScreen> createState() =>
      _Step2PropertyDetailsScreenState();
}

class _Step2PropertyDetailsScreenState extends State<Step2PropertyDetailsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  int _selectedLanguageIndex = 0;
  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _descControllers = {};
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isGeneratingDescription = false;
  bool _isAutoSlug = true;

  Future<void> _generateDescriptionWithAi(
    String langCode,
    LanguagesModel lang,
  ) async {
    final title = _titleControllers[langCode]?.text.trim() ?? '';
    if (title.isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseFillMainTitle'.translate(context),
        type: MessageType.error,
      );
      return;
    }

    final cubit = context.read<PropertyWizardCubit>();
    final languageId = int.tryParse(lang.id?.toString() ?? '1') ?? 1;
    final propertyTypeStr = cubit.data.propertyForType == 1 ? 'rent' : 'sell';

    setState(() => _isGeneratingDescription = true);

    try {
      await context.read<GenerateAiContentCubit>().generateDescription(
        entityType: EntityType.property,
        languageId: languageId,
        entityId: cubit.data.propertyId?.toString(),
        context: <String, dynamic>{
          'title': title,
          'category_id': cubit.data.selectedCategory?.id,
          'property_type': propertyTypeStr,
          'price': cubit.data.price,
        },
      );
    } on Exception catch (_) {
      if (mounted) {
        setState(() => _isGeneratingDescription = false);
      }
    }
  }

  String _getRentDurationLabel(String duration, BuildContext context) {
    switch (duration.toLowerCase()) {
      case 'daily':
        return 'daily'.translate(context);
      case 'monthly':
        return 'monthly'.translate(context);
      case 'quarterly':
        return 'quarterly'.translate(context);
      case 'yearly':
        return 'yearly'.translate(context);
      default:
        return duration.toLowerCase().translate(context);
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(context.read<FetchCountriesCubit>().fetchCountries());
    final cubit = context.read<PropertyWizardCubit>();
    final data = cubit.data;

    // Load backend languages if available
    if (AppSettings.languages.isNotEmpty) {
      data.languages = List<LanguagesModel>.from(AppSettings.languages);
    }
    if (data.languages.isEmpty) {
      data.languages = [
        LanguagesModel(id: '1', code: 'en', name: 'English'),
      ];
    }

    _selectedLanguageIndex =
        (data.selectedLanguageIndex >= 0 &&
            data.selectedLanguageIndex < data.languages.length)
        ? data.selectedLanguageIndex
        : 0;

    _tabController = TabController(
      length: data.languages.length,
      vsync: this,
      initialIndex: _selectedLanguageIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _selectedLanguageIndex) {
        _syncToCubit();
        setState(() {
          _selectedLanguageIndex = _tabController.index;
        });
      }
    });

    for (final lang in data.languages) {
      if (lang.code != null) {
        _titleControllers[lang.code!] = TextEditingController(
          text: data.titles[lang.code!] ?? '',
        );
        _descControllers[lang.code!] = TextEditingController(
          text: data.descriptions[lang.code!] ?? '',
        );
      }
    }
    _slugController.text = data.slugId;
    if (data.slugId.isNotEmpty) {
      _isAutoSlug = false;
    }
    _priceController.text = data.price;
  }

  String _generateSlug(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'[^\w-]'), '')
        .replaceAll(RegExp('-+'), '-');
  }

  late PropertyWizardCubit _wizardCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wizardCubit = context.read<PropertyWizardCubit>();
  }

  @override
  void dispose() {
    _syncToCubit();
    _tabController.dispose();
    for (final c in _titleControllers.values) {
      c.dispose();
    }
    for (final c in _descControllers.values) {
      c.dispose();
    }
    _slugController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _syncToCubit() {
    final cubit = _wizardCubit;
    for (final entry in _titleControllers.entries) {
      cubit.data.titles[entry.key] = entry.value.text;
    }
    for (final entry in _descControllers.entries) {
      cubit.data.descriptions[entry.key] = entry.value.text;
    }
    cubit.data.slugId = _slugController.text;
    cubit.data.price = _priceController.text;
    cubit.data.selectedLanguageIndex = _selectedLanguageIndex;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PropertyWizardCubit>();
    final data = cubit.data;
    final languages = data.languages;
    final selectedLang =
        languages.isNotEmpty && _selectedLanguageIndex < languages.length
        ? languages[_selectedLanguageIndex]
        : (languages.isNotEmpty
              ? languages.first
              : LanguagesModel(id: '1', code: 'en', name: 'English'));
    final currentLangCode = selectedLang.code ?? 'en';

    final titleController = _titleControllers.putIfAbsent(
      currentLangCode,
      () => TextEditingController(text: data.titles[currentLangCode] ?? ''),
    );
    final descController = _descControllers.putIfAbsent(
      currentLangCode,
      () =>
          TextEditingController(text: data.descriptions[currentLangCode] ?? ''),
    );

    final borderColor = context.color.borderColor;
    final activeCurrencySymbol = data.currencySymbol.isNotEmpty
        ? data.currencySymbol
        : (data.currencyCode.isNotEmpty
              ? data.currencyCode
              : (AppSettings.currencySymbol.isNotEmpty
                    ? AppSettings.currencySymbol
                    : r'$'));

    return BlocListener<GenerateAiContentCubit, GenerateAiContentState>(
      listener: (context, state) {
        if (state is GenerateDescriptionSuccess) {
          setState(() {
            _isGeneratingDescription = false;
            descController.text = state.description.description;
            data.descriptions[currentLangCode] = state.description.description;
          });
        } else if (state is GenerateDescriptionFailure) {
          setState(() => _isGeneratingDescription = false);
          HelperUtils.showSnackBarMessage(
            context,
            state.error,
            type: MessageType.error,
          );
        } else if (state is GenerateDescriptionInProgress) {
          setState(() => _isGeneratingDescription = true);
        }
      },
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          title: 'propertyDetails'.translate(context),
          onTapBackButton: () {
            _syncToCubit();
            widget.onBack();
          },
          preventDefaultPop: true,
          actions: [
            Center(
              child: CustomText(
                '2/7',
                fontSize: context.font.md,
                fontWeight: .w600,
                color: context.color.tertiaryColor,
              ),
            ),
          ],
        ),
        bottomNavigationBar: StepBottomBar(
          nextButtonText: 'Next',
          onNext: () {
            _syncToCubit();
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }
            if (_priceController.text.trim().isEmpty) {
              HelperUtils.showSnackBarMessage(
                context,
                'pleaseEnterPrice'.translate(context),
                type: MessageType.error,
              );
              return;
            }

            final selectedCountry =
                data.selectedCountry ??
                (data.countryId != null
                    ? context.read<FetchCountriesCubit>().getCountry(
                        id: data.countryId.toString(),
                      )
                    : null);
            final countryLangCode = selectedCountry?.primaryLanguageCode;
            final countryLangName = selectedCountry?.primaryLanguageName;

            final defaultCode = languages.isNotEmpty
                ? (languages.first.code ?? 'en')
                : 'en';

            // Check if country's required language title is filled
            if (countryLangCode != null && countryLangCode.isNotEmpty) {
              final countryTitle =
                  (data.titles[countryLangCode] ??
                          _titleControllers[countryLangCode]?.text ??
                          '')
                      .trim();
              if (countryTitle.isEmpty) {
                final targetLangIndex = languages.indexWhere(
                  (l) =>
                      (l.code ?? '').toLowerCase() ==
                      countryLangCode.toLowerCase(),
                );
                if (targetLangIndex >= 0) {
                  _tabController.animateTo(targetLangIndex);
                  setState(() {
                    _selectedLanguageIndex = targetLangIndex;
                  });
                }
                final displayName =
                    countryLangName ??
                    (targetLangIndex >= 0
                        ? languages[targetLangIndex].name ?? countryLangCode
                        : countryLangCode);
                HelperUtils.showSnackBarMessage(
                  context,
                  'Please enter title in $displayName',
                  type: MessageType.error,
                );
                return;
              }
            }

            // Also validate default language title
            final primaryTitle =
                (data.titles[defaultCode] ??
                        _titleControllers[defaultCode]?.text ??
                        '')
                    .trim();
            if (primaryTitle.isEmpty) {
              if (_selectedLanguageIndex != 0) {
                _tabController.animateTo(0);
                setState(() {
                  _selectedLanguageIndex = 0;
                });
              }
              final defaultLangName = languages.isNotEmpty
                  ? (languages.first.name ?? defaultCode)
                  : defaultCode;
              HelperUtils.showSnackBarMessage(
                context,
                'Please enter title in $defaultLangName',
                type: MessageType.error,
              );
              return;
            }

            widget.onNext();
          },
          onSaveDraft: widget.onSaveDraft != null
              ? () {
                  _syncToCubit();
                  widget.onSaveDraft!();
                }
              : null,
          isSavingDraft: widget.isSavingDraft,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Language Selector Bar
                _buildLanguageBar(languages),
                Expanded(
                  child: SingleChildScrollView(
                    physics: Constant.scrollPhysics,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedLanguageIndex == 0) ...[
                          // Is Premium Property Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                'isPremiumProperty'.translate(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.color.textColorDark,
                              ),
                              UiSwitch(
                                value: data.isPremium,
                                onChanged: (val) {
                                  setState(() {
                                    data.isPremium = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16.rh(context)),

                          // Property Type (Sell / For Rent)
                          CustomText(
                            'propertyType'.translate(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.color.textColorDark,
                          ),
                          SizedBox(height: 8.rh(context)),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPropertyTypeOption(
                                  title: 'forSell'.translate(context),
                                  isSelected: data.propertyForType == 0,
                                  borderColor: borderColor,
                                  onTap: () =>
                                      setState(() => data.propertyForType = 0),
                                ),
                              ),
                              SizedBox(width: 12.rh(context)),
                              Expanded(
                                child: _buildPropertyTypeOption(
                                  title: 'forRent'.translate(context),
                                  isSelected: data.propertyForType == 1,
                                  borderColor: borderColor,
                                  onTap: () =>
                                      setState(() => data.propertyForType = 1),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.rh(context)),

                          // List in Country
                          CustomText(
                            'country'.translate(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.color.textColorDark,
                          ),
                          SizedBox(height: 8.rh(context)),
                          BlocBuilder<FetchCountriesCubit, FetchCountriesState>(
                            builder: (context, state) {
                              var countryList = <CountryModel>[];
                              if (state is FetchCountriesSuccess) {
                                countryList = state.countries;
                              } else {
                                countryList = context
                                    .read<FetchCountriesCubit>()
                                    .countries;
                              }

                              // Match selected country if not yet set in cubit data
                              var currentSelected = data.selectedCountry;
                              if (currentSelected == null &&
                                  countryList.isNotEmpty) {
                                if (data.countryId != null) {
                                  final matched = countryList.where(
                                    (c) => c.id == data.countryId,
                                  );
                                  if (matched.isNotEmpty) {
                                    currentSelected = matched.first;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((
                                          _,
                                        ) {
                                          cubit.setCountry(currentSelected);
                                        });
                                  }
                                } else if (data
                                    .selectedCountryName
                                    .isNotEmpty) {
                                  final matched = countryList.where(
                                    (c) =>
                                        (c.name ?? '').toLowerCase() ==
                                        data.selectedCountryName.toLowerCase(),
                                  );
                                  if (matched.isNotEmpty) {
                                    currentSelected = matched.first;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((
                                          _,
                                        ) {
                                          cubit.setCountry(currentSelected);
                                        });
                                  }
                                }
                              }

                              final dropdownValue = countryList.any(
                                (c) => c.id == currentSelected?.id,
                              )
                                  ? countryList.firstWhere(
                                      (c) => c.id == currentSelected?.id,
                                    )
                                  : null;

                              return Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: context.color.secondaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: borderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<CountryModel>(
                                    isExpanded: true,
                                    value: dropdownValue,
                                    hint: CustomText(
                                      'country'.translate(context),
                                      fontSize: 14,
                                      color: context.color.textLightColor,
                                    ),
                                    icon: CustomImage(
                                      imageUrl: AppIcons.downArrow,
                                      color: context.color.textColorDark,
                                    ),
                                    dropdownColor: context.color.secondaryColor,
                                    items: countryList.map((country) {
                                      return DropdownMenuItem<CountryModel>(
                                        value: country,
                                        child: CustomText(
                                          country.name ?? '',
                                          fontSize: 14,
                                          color: context.color.textColorDark,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        // Only the listing's country changes
                                        // here; the app-wide (header) country
                                        // stays whatever the user picked there.
                                        setState(() {
                                          cubit.setCountry(val);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16.rh(context)),

                          // Price & Rent Duration
                          CustomText(
                            data.propertyForType == 1
                                ? 'rentPrice'.translate(context)
                                : 'price'.translate(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.color.textColorDark,
                          ),
                          const SizedBox(height: 8),
                          if (data.propertyForType == 1)
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: _priceController,
                                    keyboard: TextInputType.number,
                                    action: TextInputAction.next,
                                    borderRadius: 6,
                                    borderColor: borderColor,
                                    prefix: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: CustomText(
                                        '$activeCurrencySymbol ',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: context.color.textColorDark,
                                      ),
                                    ),
                                    formaters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d*'),
                                      ),
                                    ],
                                    validator:
                                        CustomTextFieldValidator.priceCheck,
                                    hintText: '00',
                                    fillColor: context.color.secondaryColor,
                                    onChange: (val) =>
                                        data.price = val?.toString() ?? '',
                                  ),
                                ),
                                SizedBox(width: 12.rh(context)),
                                Expanded(
                                  child: Container(
                                    height: 48.rh(context),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.color.secondaryColor,
                                      border: Border.all(color: borderColor),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: Constant.rentDurations
                                            .firstWhere(
                                              (d) =>
                                                  d.toLowerCase() ==
                                                  data.selectedRentDuration
                                                      .toLowerCase(),
                                              orElse: () =>
                                                  Constant.rentDurations.first,
                                            ),
                                        icon: CustomImage(
                                          imageUrl: AppIcons.downArrow,
                                          color: context.color.textColorDark,
                                        ),
                                        dropdownColor:
                                            context.color.secondaryColor,
                                        items: Constant.rentDurations.map((
                                          duration,
                                        ) {
                                          return DropdownMenuItem(
                                            value: duration,
                                            child: CustomText(
                                              _getRentDurationLabel(
                                                duration,
                                                context,
                                              ),
                                              fontSize: 14,
                                              color:
                                                  context.color.textColorDark,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => data.selectedRentDuration =
                                                  val,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            CustomTextFormField(
                              controller: _priceController,
                              keyboard: TextInputType.number,
                              action: TextInputAction.next,
                              borderRadius: 6,
                              borderColor: borderColor,
                              prefix: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: CustomText(
                                  '$activeCurrencySymbol ',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.color.textColorDark,
                                ),
                              ),
                              formaters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d*'),
                                ),
                              ],
                              validator: CustomTextFieldValidator.priceCheck,
                              hintText: '00',
                              fillColor: context.color.secondaryColor,
                              onChange: (val) =>
                                  data.price = val?.toString() ?? '',
                            ),
                          SizedBox(height: 16.rh(context)),
                        ],

                        // Title
                        CustomText(
                          languages.length > 1
                              ? '${'propertyName'.translate(context)} (${selectedLang.name})'
                              : 'propertyName'.translate(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.color.textColorDark,
                        ),
                        SizedBox(height: 8.rh(context)),
                        CustomTextFormField(
                          key: ValueKey('property_title_$currentLangCode'),
                          controller: titleController,
                          action: TextInputAction.next,
                          borderRadius: 6,
                          borderColor: borderColor,
                          validator: _selectedLanguageIndex == 0
                              ? CustomTextFieldValidator.nullCheck
                              : null,
                          hintText: 'propertyName'.translate(context),
                          fillColor: context.color.secondaryColor,
                          onChange: (dynamic val) {
                            final text = val?.toString() ?? '';
                            data.titles[currentLangCode] = text;
                            if (_isAutoSlug && _selectedLanguageIndex == 0) {
                              final generated = _generateSlug(text);
                              _slugController.text = generated;
                              data.slugId = generated;
                            }
                            setState(() {});
                          },
                        ),
                        if (_selectedLanguageIndex == 0) ...[
                          SizedBox(height: 16.rh(context)),

                          // Slug Id
                          CustomText(
                            'slugIdLbl'.translate(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.color.textColorDark,
                          ),
                          SizedBox(height: 8.rh(context)),
                          CustomTextFormField(
                            controller: _slugController,
                            action: TextInputAction.next,
                            borderRadius: 6,
                            borderColor: borderColor,
                            hintText: 'slugIdOptional'.translate(context),
                            fillColor: context.color.secondaryColor,
                            onChange: (val) {
                              final input = val?.toString() ?? '';
                              data.slugId = input;
                              final autoGen = _generateSlug(
                                data.titles[data.languages[0].code ?? 'en'] ??
                                    '',
                              );
                              if (input != autoGen) {
                                _isAutoSlug = false;
                              }
                            },
                          ),
                        ],
                        SizedBox(height: 16.rh(context)),

                        // Description
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              languages.length > 1
                                  ? '${'descriptionLbl'.translate(context)} (${selectedLang.name})'
                                  : 'descriptionLbl'.translate(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.color.textColorDark,
                            ),
                            if (AppSettings.isAIEnabled &&
                                titleController.text.trim().isNotEmpty)
                              GenerateWithAiButton(
                                onTap: () => _generateDescriptionWithAi(
                                  currentLangCode,
                                  selectedLang,
                                ),
                                isLoading: _isGeneratingDescription,
                              ),
                          ],
                        ),
                        SizedBox(height: 8.rh(context)),
                        CustomTextFormField(
                          key: ValueKey('property_desc_$currentLangCode'),
                          controller: descController,
                          borderRadius: 6,
                          borderColor: borderColor,
                          minLine: 4,
                          maxLine: 6,
                          hintText: 'writeSomething'.translate(context),
                          fillColor: context.color.secondaryColor,
                          onChange: (val) =>
                              data.descriptions[currentLangCode] =
                                  val?.toString() ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageBar(List<LanguagesModel> languages) {
    if (languages.isEmpty) return const SizedBox.shrink();

    final isScrollable = languages.length > 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: CustomTabBar(
        tabController: _tabController,
        margin: EdgeInsets.zero,
        tabBackgroundColor: context.color.tertiaryColor,
        isScrollable: isScrollable,
        onTap: (index) {
          FocusScope.of(context).unfocus();
          _syncToCubit();
          setState(() {
            _selectedLanguageIndex = index;
          });
        },
        tabs: languages.map((lang) {
          if (isScrollable) {
            return SizedBox(
              width: 95.rw(context),
              child: Tab(
                text: lang.name ?? '',
              ),
            );
          }
          return Tab(
            text: lang.name ?? '',
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPropertyTypeOption({
    required String title,
    required bool isSelected,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? context.color.tertiaryColor : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected
                  ? context.color.tertiaryColor
                  : context.color.textLightColor,
            ),
            SizedBox(width: 8.rh(context)),
            CustomText(
              title,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              fontSize: 14,
              color: context.color.textColorDark,
            ),
          ],
        ),
      ),
    );
  }
}
