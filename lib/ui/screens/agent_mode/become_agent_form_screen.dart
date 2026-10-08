import 'package:dio/dio.dart';
import 'package:ebroker/data/cubits/agents/apply_agent_verification_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_agent_registration_form_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_agent_verification_form_values.dart';
import 'package:ebroker/data/model/agent/agent_registration_form_section_model.dart';
import 'package:ebroker/data/model/agent/agent_verification_form_values_model.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/agent_form_fields.dart';
import 'package:material_ui/material_ui.dart';

class BecomeAgentFormScreen extends StatefulWidget {
  const BecomeAgentFormScreen({
    required this.formType,
    super.key,
  });

  final String formType;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => FetchAgentRegistrationFormCubit(),
          ),
          BlocProvider(
            create: (_) => FetchAgentVerificationFormValuesCubit(),
          ),
          BlocProvider(
            create: (_) => ApplyAgentVerificationCubit(),
          ),
        ],
        child: BecomeAgentFormScreen(
          formType: arguments?['form_type'] as String? ?? 'become_agent',
        ),
      ),
    );
  }

  @override
  State<BecomeAgentFormScreen> createState() => _BecomeAgentFormScreenState();
}

class _BecomeAgentFormScreenState extends State<BecomeAgentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};
  final Map<int, AgentDocuments> _selectedDocuments = {};
  int _currentStep = 0;
  bool _isInitialized = false;
  List<AgentRegistrationFormSectionModel>? _sections;
  List<AgentVerificationFormValueModel>? _values;

  @override
  void initState() {
    super.initState();
    unawaited(
      context
          .read<FetchAgentRegistrationFormCubit>()
          .fetchAgentRegistrationForm(
            formType: widget.formType,
          ),
    );
    unawaited(
      context
          .read<FetchAgentVerificationFormValuesCubit>()
          .fetchAgentsVerificationFormValues(
            forceRefresh: true,
            formType: widget.formType,
          ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeFormData({
    required List<AgentRegistrationFormSectionModel> sections,
    required List<AgentVerificationFormValueModel> valuesList,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    final valueModel = valuesList.isNotEmpty ? valuesList.first : null;
    final customerValues = valueModel?.verifyCustomerValues ?? [];
    final socialLinks = valueModel?.socialMediaLinks ?? [];
    final user = valueModel?.user;

    // Hive fallback: use cached agent profile for fields not returned by API
    final cachedProfile = HiveUtils.getAgentProfileData();

    final valuesByFormId = <int, dynamic>{};
    final valuesByName = <String, dynamic>{};

    for (final entry in customerValues) {
      final form = entry.verifyForm;
      final val = entry.value;
      if (val == null) continue;

      if (form?.id != null) {
        valuesByFormId[form!.id!] = val;
      }
      if (entry.verifyCustomerFormId != null) {
        valuesByFormId[entry.verifyCustomerFormId!] = val;
      }
      if (form?.name != null && form!.name!.isNotEmpty) {
        valuesByName[form.name!.toLowerCase().trim()] = val;
      }
    }

    final socialUrlsById = <int, String>{};
    for (final link in socialLinks) {
      if ((link.url ?? '').isNotEmpty) {
        socialUrlsById[link.id] = link.url!;
      }
    }

    for (final section in sections) {
      for (final field in section.fields) {
        if (field.fieldType == 'social_link') {
          final url = socialUrlsById[field.id];
          if (url != null && url.isNotEmpty) {
            _formData[field.name] = url;
            _controllers[field.name] = TextEditingController(text: url);
          }
          continue;
        }

        dynamic val =
            valuesByFormId[field.id] ??
            valuesByName[field.name.toLowerCase().trim()];

        // Customer fallback for Name, Email, Mobile
        if (val == null || val.toString().trim().isEmpty) {
          final lower = field.name.toLowerCase().trim();
          if (lower == 'name' || lower.contains('name')) {
            val = user?.name;
          } else if (lower == 'email' || lower.contains('email')) {
            val = user?.email;
          } else if (lower == 'mobile' ||
              lower.contains('mobile') ||
              lower.contains('phone')) {
            val = user?.mobile;
          }
        }

        // Hive fallback: pre-fill from cached AgentProfileModel
        if ((val == null || val.toString().trim().isEmpty) &&
            cachedProfile != null) {
          val = _hiveValueForField(field.name, field.fieldType, cachedProfile);
        }

        if (val == null) continue;

        switch (field.fieldType) {
          case 'text':
          case 'number':
          case 'textarea':
            final strVal = val.toString();
            if (strVal.isNotEmpty) {
              _formData[field.name] = strVal;
              _controllers[field.name] = TextEditingController(text: strVal);
            }

          case 'chips':
            if (val is List) {
              _formData[field.name] = val.map((e) => e.toString()).toList();
            } else if (val is String && val.trim().isNotEmpty) {
              _formData[field.name] = val
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }

          case 'time':
            final timeStr = val.toString().trim();
            if (timeStr.isNotEmpty) {
              _formData[field.name] = timeStr;
              _controllers[field.name] = TextEditingController(text: timeStr);
            }

          case 'radio':
          case 'dropdown':
            final strVal = val.toString().trim();
            if (strVal.isNotEmpty) {
              _formData[field.name] = strVal;
            }

          case 'checkbox':
            if (val is List) {
              _formData[field.name] = val.join(',');
            } else if (val is String) {
              _formData[field.name] = val;
            }

          case 'file':
            final fileName = val.toString().trim();
            if (fileName.isNotEmpty) {
              _selectedDocuments[field.id] = AgentDocuments(
                name: fileName,
                isExisting: true,
              );
            }
        }
      }
    }
  }

  /// Returns a cached Hive value for the given field based on its name and type.
  dynamic _hiveValueForField(
    String fieldName,
    String fieldType,
    AgentProfileModel cached,
  ) {
    final lower = fieldName.toLowerCase().trim();

    // Service areas / area of operation
    if (lower.contains('service') ||
        (lower.contains('area') && !lower.contains('experience')) ||
        lower.contains('region') ||
        lower.contains('zone') ||
        lower.contains('district') ||
        lower.contains('location')) {
      final areas = cached.serviceAreas;
      if (areas != null && areas.isNotEmpty) {
        return fieldType == 'chips'
            ? areas
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : areas;
      }
    }

    // Languages spoken
    if (lower.contains('language') ||
        lower.contains('lang') ||
        lower.contains('speak') ||
        lower.contains('fluent')) {
      final langs = cached.languages;
      if (langs != null && langs.isNotEmpty) {
        return fieldType == 'chips'
            ? langs
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : langs;
      }
    }

    // Experience / years
    if (lower.contains('experience') ||
        lower == 'exp' ||
        lower.endsWith(' exp') ||
        lower.contains('year')) {
      final exp = cached.experience;
      if (exp != null && exp.isNotEmpty) return exp;
    }

    // Start time / working hours start
    if (lower.contains('start') ||
        lower.contains('begin') ||
        lower.contains('opening') ||
        (lower.contains('from') && lower.length < 15)) {
      final st = cached.startTime;
      if (st != null && st.isNotEmpty) return st;
    }

    // End time / working hours end
    if (lower.contains('end') ||
        lower.contains('close') ||
        lower.contains('until')) {
      final et = cached.endTime;
      if (et != null && et.isNotEmpty) return et;
    }

    // About me
    if (lower.contains('about') ||
        lower.contains('bio') ||
        lower.contains('description')) {
      final about = cached.aboutMe;
      if (about != null && about.isNotEmpty) return about;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: 'agentRegistration'.translate(context),
      ),
      body:
          BlocConsumer<
            FetchAgentRegistrationFormCubit,
            FetchAgentRegistrationFormState
          >(
            listener: (context, sectionsState) {
              if (sectionsState is FetchAgentRegistrationFormSuccess) {
                _sections = sectionsState.sections;
                if (_values != null && !_isInitialized) {
                  setState(() {
                    _initializeFormData(
                      sections: _sections!,
                      valuesList: _values!,
                    );
                  });
                }
              }
            },
            builder: (context, sectionsState) {
              return BlocConsumer<
                FetchAgentVerificationFormValuesCubit,
                FetchAgentVerificationFormValuesState
              >(
                listener: (context, valuesState) {
                  if (valuesState is FetchAgentVerificationFormValuesSuccess) {
                    _values = valuesState.values;
                    if (_sections != null && !_isInitialized) {
                      setState(() {
                        _initializeFormData(
                          sections: _sections!,
                          valuesList: _values!,
                        );
                      });
                    }
                  }
                },
                builder: (context, valuesState) {
                  final isLoading =
                      sectionsState is FetchAgentRegistrationFormLoading ||
                      valuesState is FetchAgentVerificationFormValuesLoading;

                  if (isLoading) {
                    return Center(child: UiUtils.progress());
                  }

                  if (sectionsState is FetchAgentRegistrationFormFailure) {
                    return SomethingWentWrong(
                      errorMessage: sectionsState.errorMessage,
                    );
                  }

                  if (sectionsState is FetchAgentRegistrationFormSuccess) {
                    final sections = sectionsState.sections;
                    if (sections.isEmpty) {
                      return Center(
                        child: CustomText('noDataFound'.translate(context)),
                      );
                    }

                    if (!_isInitialized) {
                      if (valuesState
                          is FetchAgentVerificationFormValuesSuccess) {
                        _initializeFormData(
                          sections: sections,
                          valuesList: valuesState.values,
                        );
                      } else if (valuesState
                          is FetchAgentVerificationFormValuesFailure) {
                        _initializeFormData(sections: sections, valuesList: []);
                      }
                    }

                    return Column(
                      children: [
                        _buildStepper(context, sections),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildStepContent(context, sections),
                          ),
                        ),
                        _buildBottomButtons(context, sections),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
    );
  }

  Widget _buildStepper(
    BuildContext context,
    List<AgentRegistrationFormSectionModel> sections,
  ) {
    return Container(
      color: context.color.secondaryColor,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: List.generate(sections.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < _currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? context.color.tertiaryColor
                    : context.color.borderColor,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final isActive = stepIndex == _currentStep;
          final isCompleted = stepIndex < _currentStep;
          return Column(
            mainAxisSize: .min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: .circle,
                  color: isActive || isCompleted
                      ? context.color.tertiaryColor
                      : context.color.borderColor,
                  border: Border.all(
                    color: isActive || isCompleted
                        ? context.color.tertiaryColor
                        : context.color.borderColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: context.color.buttonColor,
                        )
                      : CustomText(
                          '${stepIndex + 1}',
                          fontSize: context.font.xs,
                          fontWeight: .w600,
                          color: isActive
                              ? context.color.buttonColor
                              : context.color.textLightColor,
                        ),
                ),
              ),
              SizedBox(height: 4.rh(context)),
              SizedBox(
                width: 60,
                child: CustomText(
                  sections[stepIndex].translatedName,
                  fontSize: context.font.xxs,
                  textAlign: .center,
                  color: isActive || isCompleted
                      ? context.color.tertiaryColor
                      : context.color.textLightColor,
                  fontWeight: isActive ? .w600 : .w400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    List<AgentRegistrationFormSectionModel> sections,
  ) {
    final section = sections[_currentStep];
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: .start,
          children: section.fields.map(_buildFormField).toList(),
        ),
      ),
    );
  }

  Widget _buildFormField(AgentRegistrationFormFieldModel field) {
    final fieldValue = _formData[field.name];
    switch (field.fieldType) {
      case 'text':
        return _buildTextField(field, fieldValue?.toString() ?? '');
      case 'number':
        return _buildTextField(field, fieldValue?.toString() ?? '');
      case 'chips':
        return _buildChipsField(field, fieldValue);
      case 'time':
        return _buildTimeField(field, fieldValue?.toString() ?? '');
      case 'social_link':
        return _buildSocialLinkField(field, fieldValue?.toString() ?? '');
      case 'radio':
        return _buildRadioGroup(field, fieldValue?.toString() ?? '');
      case 'checkbox':
        return _buildCheckboxGroup(field, fieldValue);
      case 'dropdown':
        return _buildDropdown(field, fieldValue?.toString() ?? '');
      case 'textarea':
        return _buildTextArea(field, fieldValue?.toString() ?? '');
      case 'file':
        return _buildFilePickerField(field);
      default:
        return const SizedBox.shrink();
    }
  }

  List<AppFormOption> _optionsOf(AgentRegistrationFormFieldModel field) {
    return field.formFieldsValues
        .map(
          (option) => AppFormOption(
            value: option.value,
            translatedValue: option.translatedValue,
          ),
        )
        .toList();
  }

  Widget _buildFilePickerField(AgentRegistrationFormFieldModel field) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        AgentFormFieldTitle(field.translatedName, isRequired: field.isRequired),
        SizedBox(height: 4.rh(context)),
        AgentDocumentPickerField(
          initialDocument: _selectedDocuments[field.id],
          label: '${'uploadBtnLbl'.translate(context)} ${field.translatedName}',
          onDocumentSelected: (doc) {
            setState(() {
              if (doc != null) {
                _selectedDocuments[field.id] = doc;
              } else {
                _selectedDocuments.remove(field.id);
              }
            });
          },
        ),
        SizedBox(height: 16.rh(context)),
      ],
    );
  }

  Widget _buildChipsField(
    AgentRegistrationFormFieldModel field,
    dynamic fieldValue,
  ) {
    var initialValues = <String>[];
    if (fieldValue is List<String>) {
      initialValues = fieldValue;
    } else if (fieldValue is List) {
      initialValues = fieldValue.map((e) => e.toString()).toList();
    } else if (fieldValue is String && fieldValue.trim().isNotEmpty) {
      initialValues = fieldValue
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return AgentChipsFormField(
      key: ValueKey('chips_${field.id}_${initialValues.join(',')}'),
      title: field.translatedName,
      initialValues: initialValues,
      isRequired: field.isRequired,
      onChanged: (chips) => _formData[field.name] = chips,
    );
  }

  Widget _buildTimeField(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    return AgentTimeFormField(
      title: field.translatedName,
      initialValue: fieldValue,
      isRequired: field.isRequired,
      onChanged: (time) => _formData[field.name] = time,
    );
  }

  Widget _buildSocialLinkField(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    if (!_controllers.containsKey(field.name)) {
      _controllers[field.name] = TextEditingController(text: fieldValue);
    }
    return AgentSocialLinkFormField(
      title: field.translatedName,
      iconUrl: field.icon,
      controller: _controllers[field.name]!,
      onChange: (value) => _formData[field.name] = value,
    );
  }

  Widget _buildTextField(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    if (!_controllers.containsKey(field.name)) {
      _controllers[field.name] = TextEditingController(text: fieldValue);
    }
    return AgentTextFormField(
      title: field.translatedName,
      controller: _controllers[field.name]!,
      isNumber: isNumericAgentFormField(field.name, field.fieldType),
      isRequired: field.isRequired,
      onChange: (value) => _formData[field.name] = value,
    );
  }

  Widget _buildTextArea(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    if (!_controllers.containsKey(field.name)) {
      _controllers[field.name] = TextEditingController(text: fieldValue);
    }
    return AgentTextFormField(
      title: field.translatedName,
      controller: _controllers[field.name]!,
      isMultiline: true,
      isRequired: field.isRequired,
      onChange: (value) => _formData[field.name] = value,
    );
  }

  Widget _buildRadioGroup(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    return AgentRadioGroupFormField(
      title: field.translatedName,
      options: _optionsOf(field),
      initialValue: fieldValue,
      isRequired: field.isRequired,
      onChanged: (value) => _formData[field.name] = value,
    );
  }

  Widget _buildCheckboxGroup(
    AgentRegistrationFormFieldModel field,
    dynamic fieldValue,
  ) {
    var initialValues = <String>[];
    if (fieldValue is String) {
      initialValues = fieldValue.split(',').map((e) => e.trim()).toList();
    } else if (fieldValue is List<String>) {
      initialValues = fieldValue;
    }
    return AgentCheckboxGroupFormField(
      title: field.translatedName,
      options: _optionsOf(field),
      initialValues: initialValues,
      isRequired: field.isRequired,
      onChanged: (value) => _formData[field.name] = value.join(','),
    );
  }

  Widget _buildDropdown(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    return AgentDropdownFormField(
      title: field.translatedName,
      options: _optionsOf(field),
      initialValue: (fieldValue?.isNotEmpty ?? false) ? fieldValue : null,
      isRequired: field.isRequired,
      onChanged: (value) => _formData[field.name] = value,
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    List<AgentRegistrationFormSectionModel> sections,
  ) {
    final isLastStep = _currentStep == sections.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: context.color.secondaryColor,
      child: BlocConsumer<ApplyAgentVerificationCubit, ApplyAgentVerificationState>(
        listener: (context, state) {
          if (state is ApplyAgentVerificationSuccess) {
            // Persist submitted values to Hive so they're available next open
            _persistFormDataToHive();
            Navigator.pushReplacementNamed(
              context,
              Routes.agentRegistrationSuccess,
            );
          } else if (state is ApplyAgentVerificationFailure) {
            HelperUtils.showSnackBarMessage(
              context,
              '${'failedTOApplyVerification'.translate(context)}: ${state.errorMessage.translate(context)}',
              type: .error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ApplyAgentVerificationInProgress;
          return Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: UiUtils.buildButton(
                    context,
                    onPressed: () => setState(() => _currentStep--),
                    buttonTitle: 'back'.translate(context),
                  ),
                ),
                SizedBox(width: 12.rw(context)),
              ],
              Expanded(
                child: UiUtils.buildButton(
                  context,
                  isInProgress: isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (isLastStep) {
                        await _submitForm(sections);
                      } else {
                        setState(() => _currentStep++);
                      }
                    }
                  },
                  buttonTitle: isLastStep
                      ? 'submit'.translate(context)
                      : 'next'.translate(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Saves the current form values to the Hive agent profile cache.
  void _persistFormDataToHive() {
    try {
      final existing = HiveUtils.getAgentProfileData();
      String? serviceAreas;
      String? languages;
      String? experience;
      String? startTime;
      String? endTime;
      String? aboutMe;

      for (final entry in _formData.entries) {
        final fieldName = entry.key.toLowerCase().trim();
        final raw = entry.value;
        if (raw == null) continue;

        String strVal;
        if (raw is List) {
          strVal = raw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .join(',');
        } else {
          strVal = raw.toString().trim();
        }
        if (strVal.isEmpty) continue;

        if (serviceAreas == null &&
            (fieldName.contains('service') ||
                (fieldName.contains('area') &&
                    !fieldName.contains('experience')) ||
                fieldName.contains('region') ||
                fieldName.contains('zone') ||
                fieldName.contains('location'))) {
          serviceAreas = strVal;
        } else if (languages == null &&
            (fieldName.contains('language') ||
                fieldName.contains('lang') ||
                fieldName.contains('speak') ||
                fieldName.contains('fluent'))) {
          languages = strVal;
        } else if (experience == null &&
            (fieldName.contains('experience') ||
                fieldName == 'exp' ||
                fieldName.contains('year'))) {
          experience = strVal;
        } else if (startTime == null &&
            (fieldName.contains('start') ||
                fieldName.contains('begin') ||
                fieldName.contains('opening') ||
                (fieldName.contains('from') && fieldName.length < 15))) {
          startTime = strVal;
        } else if (endTime == null &&
            (fieldName.contains('end') ||
                fieldName.contains('close') ||
                fieldName.contains('until'))) {
          endTime = strVal;
        } else if (aboutMe == null &&
            (fieldName.contains('about') ||
                fieldName.contains('bio') ||
                fieldName.contains('description'))) {
          aboutMe = strVal;
        }
      }

      final updated = (existing ?? AgentProfileModel()).copyWith(
        serviceAreas: serviceAreas ?? existing?.serviceAreas,
        languages: languages ?? existing?.languages,
        experience: experience ?? existing?.experience,
        startTime: startTime ?? existing?.startTime,
        endTime: endTime ?? existing?.endTime,
        aboutMe: aboutMe ?? existing?.aboutMe,
      );

      unawaited(HiveUtils.setAgentProfileData(updated.toMap()));
    } on Object catch (_) {
      // Silently ignore cache errors
    }
  }

  Future<void> _submitForm(
    List<AgentRegistrationFormSectionModel> sections,
  ) async {
    final formFields = <Map<String, dynamic>>[];
    final socialMediaLinks = <Map<String, dynamic>>[];

    for (final section in sections) {
      for (final field in section.fields) {
        if (field.fieldType == 'social_link') {
          final urlVal =
              _formData[field.name]?.toString() ??
              _controllers[field.name]?.text ??
              '';
          if (urlVal.trim().isNotEmpty) {
            socialMediaLinks.add({
              'id': field.id,
              'url': urlVal.trim(),
            });
          }
          continue;
        }

        if (field.fieldType == 'file') {
          final doc = _selectedDocuments[field.id];
          if (field.isRequired && doc == null) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseFillAllRequiredFields'.translate(context),
              type: .error,
            );
            return;
          }
          if (doc != null) {
            if (doc.isExisting && doc.file == null) {
              // Existing unmodified file (e.g. re-apply after rejection):
              // send the stored reference so the user needn't re-upload it
              formFields.add({
                'id': field.id.toString(),
                'value': doc.name,
              });
              continue;
            }
            if (doc.file != null) {
              formFields.add({
                'id': field.id.toString(),
                'value': MultipartFile.fromFileSync(
                  doc.file!,
                  filename: doc.name,
                ),
              });
            }
          }
        } else if (field.fieldType == 'chips') {
          final val = _formData[field.name];
          var chips = <String>[];
          if (val is List<String>) {
            chips = val;
          } else if (val is List) {
            chips = val.map((e) => e.toString()).toList();
          } else if (val is String && val.trim().isNotEmpty) {
            chips = val
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
          if (field.isRequired && chips.isEmpty) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseFillAllRequiredFields'.translate(context),
              type: .error,
            );
            return;
          }
          if (chips.isNotEmpty) {
            formFields.add({
              'id': field.id.toString(),
              'value': chips.join(','),
            });
          }
        } else if (field.fieldType == 'time') {
          final timeVal =
              _formData[field.name]?.toString() ??
              _controllers[field.name]?.text ??
              '';
          if (field.isRequired && timeVal.trim().isEmpty) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseFillAllRequiredFields'.translate(context),
              type: .error,
            );
            return;
          }
          if (timeVal.trim().isNotEmpty) {
            final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
            if (!timeRegex.hasMatch(timeVal.trim())) {
              HelperUtils.showSnackBarMessage(
                context,
                'invalidTimeFormat'.translate(context),
                type: .error,
              );
              return;
            }
            formFields.add({
              'id': field.id.toString(),
              'value': timeVal.trim(),
            });
          }
        } else if (field.fieldType == 'checkbox') {
          final value = _formData[field.name];
          if (field.isRequired &&
              (value == null || value.toString().trim().isEmpty)) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseFillAllRequiredFields'.translate(context),
              type: .error,
            );
            return;
          }
          if (value != null && value.toString().isNotEmpty) {
            formFields.add({
              'id': field.id.toString(),
              'value': value.toString(),
            });
          }
        } else {
          final value = _formData[field.name] ?? _controllers[field.name]?.text;
          if (field.isRequired &&
              (value == null || value.toString().trim().isEmpty)) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseFillAllRequiredFields'.translate(context),
              type: .error,
            );
            return;
          }
          if (value != null && value.toString().trim().isNotEmpty) {
            formFields.add({
              'id': field.id.toString(),
              'value': value.toString(),
            });
          }
        }
      }
    }

    final parameters = <String, dynamic>{
      'form_fields': formFields,
      'form_type': 'become_agent',
    };
    if (socialMediaLinks.isNotEmpty) {
      parameters['social_media_links'] = socialMediaLinks;
    }

    await context.read<ApplyAgentVerificationCubit>().applyVerification(
      parameters: parameters,
    );
  }
}
