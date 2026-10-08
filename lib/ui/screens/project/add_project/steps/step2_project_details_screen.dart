import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/cubits/ai/generate_ai_content_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_countries_cubit.dart';
import 'package:ebroker/data/model/country_model.dart';
import 'package:ebroker/data/model/languages_model.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/ui/screens/project/add_project/project_wizard_cubit.dart';
import 'package:ebroker/ui/screens/project/add_project/widgets/step_bottom_bar.dart';
import 'package:ebroker/ui/screens/widgets/custom_text_form_field.dart';
import 'package:ebroker/ui/screens/widgets/generate_with_ai_button.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class Step2ProjectDetailsScreen extends StatefulWidget {
  const Step2ProjectDetailsScreen({
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
  State<Step2ProjectDetailsScreen> createState() =>
      _Step2ProjectDetailsScreenState();
}

class _Step2ProjectDetailsScreenState extends State<Step2ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late List<LanguagesModel> _languages;
  int _selectedLanguageIndex = 0;
  late TabController _tabController;
  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _descControllers = {};
  late final TextEditingController _slugController;

  bool _isGeneratingDescription = false;
  bool _isAutoSlug = true;

  @override
  void initState() {
    super.initState();
    final data = context.read<ProjectWizardCubit>().data;
    _languages = data.languages;
    _selectedLanguageIndex = data.selectedLanguageIndex;

    _tabController = TabController(
      length: _languages.length,
      vsync: this,
      initialIndex:
          (_selectedLanguageIndex >= 0 &&
              _selectedLanguageIndex < _languages.length)
          ? _selectedLanguageIndex
          : 0,
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

    for (final lang in _languages) {
      final code = lang.code ?? 'en';
      _titleControllers[code] = TextEditingController(
        text: data.titles[code] ?? '',
      );
      _descControllers[code] = TextEditingController(
        text: data.descriptions[code] ?? '',
      );
    }

    _slugController = TextEditingController(text: data.slugId);
    if (data.slugId.isNotEmpty) {
      _isAutoSlug = false;
    }
  }

  late ProjectWizardCubit _wizardCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wizardCubit = context.read<ProjectWizardCubit>();
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
    cubit.data.selectedLanguageIndex = _selectedLanguageIndex;
  }

  String _generateSlug(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'[^\w-]'), '')
        .replaceAll(RegExp('-+'), '-');
  }

  Future<void> _generateDescriptionWithAi() async {
    final currentCode = _languages[_selectedLanguageIndex].code ?? 'en';
    final title = _titleControllers[currentCode]?.text.trim() ?? '';
    if (title.isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseFillMainTitle'.translate(context),
        type: MessageType.error,
      );
      return;
    }

    final cubit = context.read<ProjectWizardCubit>();
    final currentLang = _languages[_selectedLanguageIndex];
    final languageId = int.tryParse(currentLang.id?.toString() ?? '1') ?? 1;

    setState(() => _isGeneratingDescription = true);

    try {
      await context.read<GenerateAiContentCubit>().generateDescription(
        entityType: EntityType.project,
        languageId: languageId,
        entityId: cubit.data.projectId?.toString(),
        context: <String, dynamic>{
          'title': title,
          'category_id': cubit.data.selectedCategory?.id,
          'type': cubit.data.projectType,
        },
      );
    } on Exception catch (_) {
      setState(() => _isGeneratingDescription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ProjectWizardCubit>();
    final data = cubit.data;

    final currentLang = _languages[_selectedLanguageIndex];
    final currentCode = currentLang.code ?? 'en';
    final currentTitleController =
        _titleControllers[currentCode] ?? TextEditingController();
    final currentDescController =
        _descControllers[currentCode] ?? TextEditingController();

    final primaryTextColor = context.color.textColorDark;
    final borderColor = context.color.borderColor;

    return BlocListener<GenerateAiContentCubit, GenerateAiContentState>(
      listener: (context, state) {
        if (state is GenerateDescriptionSuccess) {
          setState(() {
            _isGeneratingDescription = false;
            currentDescController.text = state.description.description;
            data.descriptions[currentCode] = state.description.description;
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
          title: 'projectDetails'.translate(context),
          onTapBackButton: () {
            _syncToCubit();
            widget.onBack();
          },
          preventDefaultPop: true,
          actions: [
            Center(
              child: CustomText(
                '2/6',
                fontSize: context.font.md,
                fontWeight: .w600,
                color: context.color.tertiaryColor,
              ),
            ),
          ],
        ),
        bottomNavigationBar: StepBottomBar(
          onNext: () {
            _syncToCubit();
            if (!_formKey.currentState!.validate()) {
              return;
            }

            final cubit = context.read<ProjectWizardCubit>();
            final countries = context.read<FetchCountriesCubit>().countries;
            if (countries.isNotEmpty &&
                cubit.data.countryId.trim().isEmpty &&
                (cubit.data.selectedCountry?.name ?? cubit.data.country)
                    .trim()
                    .isEmpty) {
              HelperUtils.showSnackBarMessage(
                context,
                'pleaseSelectCountry'.translate(context),
                type: MessageType.error,
              );
              return;
            }

            final selectedCountry =
                cubit.data.selectedCountry ??
                (cubit.data.countryId.isNotEmpty
                    ? context.read<FetchCountriesCubit>().getCountry(
                        id: cubit.data.countryId,
                      )
                    : null);
            final countryLangCode = selectedCountry?.primaryLanguageCode;
            final countryLangName = selectedCountry?.primaryLanguageName;

            final defaultCode = _languages.isNotEmpty
                ? (_languages.first.code ?? 'en')
                : 'en';

            // 1. Check country's required language first
            if (countryLangCode != null && countryLangCode.isNotEmpty) {
              final countryTitle =
                  (_titleControllers[countryLangCode]?.text ??
                          cubit.data.titles[countryLangCode] ??
                          '')
                      .trim();
              if (countryTitle.isEmpty) {
                final targetLangIndex = _languages.indexWhere(
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
                        ? _languages[targetLangIndex].name ?? countryLangCode
                        : countryLangCode);
                HelperUtils.showSnackBarMessage(
                  context,
                  'Please fill title in $displayName',
                  type: MessageType.error,
                );
                return;
              }
            }

            // 2. Also check default language title
            final primaryTitle =
                (_titleControllers[defaultCode]?.text ??
                        cubit.data.titles[defaultCode] ??
                        '')
                    .trim();
            if (primaryTitle.isEmpty) {
              if (_selectedLanguageIndex != 0) {
                _tabController.animateTo(0);
                setState(() {
                  _selectedLanguageIndex = 0;
                });
              }
              final defaultLangName = _languages.isNotEmpty
                  ? (_languages.first.name ?? defaultCode)
                  : defaultCode;
              HelperUtils.showSnackBarMessage(
                context,
                'Please fill title in $defaultLangName',
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
                // ==========================================
                // 1. Language Selector Bar
                // ==========================================
                _buildLanguageBar(_languages),
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
                          // ==========================================
                          // 2. Is Premium Project? Switch
                          // ==========================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                'isPremiumProject'.translate(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: primaryTextColor,
                              ),
                              CupertinoSwitch(
                                value: data.isPremium,
                                activeTrackColor: context.color.tertiaryColor,
                                onChanged: (val) {
                                  setState(() {
                                    data
                                      ..isPremium = val
                                      ..isPromoted = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 18.rh(context)),
                          // ==========================================
                          // 3. Project Status (Upcoming / Under Construction)
                          // ==========================================
                          CustomText(
                            'projectStatus'.translate(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
                          ),
                          SizedBox(height: 10.rh(context)),
                          _buildStatusRadioCard(
                            title: 'upcoming'.translate(context),
                            value: 'upcoming',
                            groupValue: data.projectType,
                            onTap: () {
                              setState(() {
                                data.projectType = 'upcoming';
                              });
                            },
                          ),
                          SizedBox(height: 10.rh(context)),
                          _buildStatusRadioCard(
                            title: 'under_construction'.translate(context),
                            value: 'under_construction',
                            groupValue: data.projectType,
                            onTap: () {
                              setState(() {
                                data.projectType = 'under_construction';
                              });
                            },
                          ),
                          SizedBox(height: 18.rh(context)),

                          // List in Country
                          CustomText(
                            'country'.translate(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
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
                                if (data.countryId.isNotEmpty) {
                                  final matched = countryList.where(
                                    (c) => c.id?.toString() == data.countryId,
                                  );
                                  if (matched.isNotEmpty) {
                                    currentSelected = matched.first;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((
                                          _,
                                        ) {
                                          cubit.setCountry(currentSelected!);
                                        });
                                  }
                                } else if (data.country.isNotEmpty) {
                                  final matched = countryList.where(
                                    (c) =>
                                        (c.name ?? '').toLowerCase() ==
                                        data.country.toLowerCase(),
                                  );
                                  if (matched.isNotEmpty) {
                                    currentSelected = matched.first;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((
                                          _,
                                        ) {
                                          cubit.setCountry(currentSelected!);
                                        });
                                  }
                                }
                              }

                              final dropdownValue =
                                  countryList.any(
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
                          SizedBox(height: 18.rh(context)),
                        ],
                        // ==========================================
                        // 4. Project Title
                        // ==========================================
                        CustomText(
                          _languages.length > 1
                              ? '${'projectTitle'.translate(context)} (${currentLang.name})'
                              : 'projectTitle'.translate(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                        SizedBox(height: 8.rh(context)),
                        CustomTextFormField(
                          key: ValueKey('project_title_$currentCode'),
                          controller: currentTitleController,
                          action: TextInputAction.next,
                          hintText: 'projectName'.translate(context),
                          borderRadius: 6,
                          borderColor: borderColor,
                          fillColor: context.color.secondaryColor,
                          onChange: (val) {
                            final str = val?.toString() ?? '';
                            data.titles[currentCode] = str;
                            if (_isAutoSlug && _selectedLanguageIndex == 0) {
                              final generated = _generateSlug(str);
                              _slugController.text = generated;
                              data.slugId = generated;
                            }
                            setState(() {});
                          },
                          validator: _selectedLanguageIndex == 0
                              ? CustomTextFieldValidator.nullCheck
                              : null,
                        ),
                        if (_selectedLanguageIndex == 0) ...[
                          SizedBox(height: 18.rh(context)),
                          // ==========================================
                          // 5. Slug Id
                          // ==========================================
                          CustomText(
                            'slugIdLbl'.translate(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
                          ),
                          SizedBox(height: 8.rh(context)),
                          CustomTextFormField(
                            controller: _slugController,
                            action: TextInputAction.next,
                            hintText: 'slugIdOptional'.translate(context),
                            borderRadius: 6,
                            borderColor: borderColor,
                            fillColor: context.color.secondaryColor,
                            onChange: (val) {
                              _isAutoSlug = false;
                              data.slugId = val?.toString() ?? '';
                            },
                          ),
                        ],
                        SizedBox(height: 18.rh(context)),

                        // ==========================================
                        // 6. Description & AI Generate
                        // ==========================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              _languages.length > 1
                                  ? '${'descriptionLbl'.translate(context)} (${currentLang.name})'
                                  : 'descriptionLbl'.translate(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: primaryTextColor,
                            ),
                            if (AppSettings.isAIEnabled &&
                                currentTitleController.text.trim().isNotEmpty)
                              GenerateWithAiButton(
                                onTap: _generateDescriptionWithAi,
                                isLoading: _isGeneratingDescription,
                              ),
                          ],
                        ),
                        SizedBox(height: 8.rh(context)),
                        CustomTextFormField(
                          key: ValueKey('project_desc_$currentCode'),
                          controller: currentDescController,
                          action: TextInputAction.newline,
                          minLine: 4,
                          maxLine: 6,
                          hintText: 'writeSomething'.translate(context),
                          borderRadius: 6,
                          borderColor: borderColor,
                          fillColor: context.color.secondaryColor,
                          onChange: (val) {
                            data.descriptions[currentCode] =
                                val?.toString() ?? '';
                          },
                        ),
                        SizedBox(height: 24.rh(context)),
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

  Widget _buildStatusRadioCard({
    required String title,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    final primaryTextColor = context.color.textColorDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? context.color.tertiaryColor
                : context.color.borderColor,
            width: isSelected ? 1.2 : 1,
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
            SizedBox(width: 10.rw(context)),
            CustomText(
              title,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: primaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
