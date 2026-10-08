import 'package:dio/dio.dart';
import 'package:ebroker/data/cubits/agents/apply_agent_verification_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_agent_registration_form_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_agent_verification_form_values.dart';
import 'package:ebroker/data/model/agent/agent_registration_form_section_model.dart';
import 'package:ebroker/data/model/agent/agent_verification_form_values_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/agent_form_fields.dart';
import 'package:material_ui/material_ui.dart';

class VerifyAgentFormScreen extends StatelessWidget {
  const VerifyAgentFormScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
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
        child: const _VerifyAgentFormBody(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _VerifyAgentFormBody();
  }
}

class _VerifyAgentFormBody extends StatefulWidget {
  const _VerifyAgentFormBody();

  @override
  State<_VerifyAgentFormBody> createState() => _VerifyAgentFormBodyState();
}

class _VerifyAgentFormBodyState extends State<_VerifyAgentFormBody> {
  static const _formType = 'verify_agent';

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};
  final Map<int, AgentDocuments> _selectedDocuments = {};
  int _currentStep = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      context
          .read<FetchAgentRegistrationFormCubit>()
          .fetchAgentRegistrationForm(formType: _formType),
    );
    unawaited(
      context
          .read<FetchAgentVerificationFormValuesCubit>()
          .fetchAgentsVerificationFormValues(
            forceRefresh: true,
            formType: _formType,
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

  void _initializeFormData(
    List<AgentVerificationFormValueModel> values, {
    List<AgentRegistrationFormSectionModel>? sections,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    if (values.isEmpty) return;
    final valueModel = values.first;
    final customerValues = valueModel.verifyCustomerValues ?? [];
    final socialLinks = valueModel.socialMediaLinks ?? [];

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

    if (sections != null) {
      for (final section in sections) {
        for (final field in section.fields) {
          final key = field.id.toString();
          if (field.fieldType == 'social_link') {
            final url = socialUrlsById[field.id];
            if (url != null && url.isNotEmpty) {
              _formData[key] = url;
              _controllers[key] = TextEditingController(text: url);
            }
            continue;
          }

          final val = valuesByFormId[field.id] ??
              valuesByName[field.name.toLowerCase().trim()];
          if (val == null) continue;

          switch (field.fieldType) {
            case 'text':
            case 'number':
            case 'textarea':
              final str = val.toString();
              if (str.isNotEmpty) {
                _controllers[key] = TextEditingController(text: str);
                _formData[key] = str;
              }
            case 'time':
              final str = val.toString().trim();
              if (str.isNotEmpty) {
                _controllers[key] = TextEditingController(text: str);
                _formData[key] = str;
              }
            case 'chips':
              if (val is List) {
                _formData[key] = val.map((e) => e.toString()).toList();
              } else if (val is String && val.trim().isNotEmpty) {
                _formData[key] = val
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            case 'radio':
            case 'dropdown':
              _formData[key] = val.toString().trim();
            case 'checkbox':
              if (val is List) {
                _formData[key] = val.join(',');
              } else {
                _formData[key] = val.toString();
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
    } else {
      for (final entry in customerValues) {
        final form = entry.verifyForm;
        final fieldType = form?.fieldType ?? '';
        final fieldId = (form?.id ?? entry.verifyCustomerFormId)?.toString();
        if (fieldId == null) continue;
        final rawVal = entry.value;

        if (rawVal == null) continue;

        switch (fieldType) {
          case 'text':
          case 'number':
          case 'textarea':
            final str = rawVal.toString();
            if (str.isNotEmpty) {
              _controllers[fieldId] = TextEditingController(text: str);
              _formData[fieldId] = str;
            }
          case 'time':
            final str = rawVal.toString().trim();
            if (str.isNotEmpty) {
              _controllers[fieldId] = TextEditingController(text: str);
              _formData[fieldId] = str;
            }
          case 'chips':
            if (rawVal is List) {
              _formData[fieldId] = rawVal.map((e) => e.toString()).toList();
            } else if (rawVal is String && rawVal.trim().isNotEmpty) {
              _formData[fieldId] = rawVal
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          case 'radio':
          case 'dropdown':
            _formData[fieldId] = rawVal.toString();
          case 'checkbox':
            if (rawVal is List) {
              _formData[fieldId] = rawVal.join(',');
            } else {
              _formData[fieldId] = rawVal.toString();
            }
          case 'file':
            final idNum = int.tryParse(fieldId);
            if (idNum != null) {
              _selectedDocuments[idNum] = AgentDocuments(
                name: rawVal.toString(),
                isExisting: true,
              );
            }
        }
      }

      for (final link in socialLinks) {
        final key = link.id.toString();
        if ((link.url ?? '').isNotEmpty) {
          _formData[key] = link.url;
          _controllers[key] = TextEditingController(text: link.url);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: 'verifyAgent'.translate(context),
      ),
      body:
          BlocBuilder<
            FetchAgentRegistrationFormCubit,
            FetchAgentRegistrationFormState
          >(
            builder: (context, sectionsState) {
              return BlocBuilder<
                FetchAgentVerificationFormValuesCubit,
                FetchAgentVerificationFormValuesState
              >(
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

                    // Pre-fill once both states are ready
                    if (valuesState
                        is FetchAgentVerificationFormValuesSuccess) {
                      _initializeFormData(valuesState.values, sections: sections);
                    }

                    if (sections.isEmpty) {
                      return Center(
                        child: CustomText('noDataFound'.translate(context)),
                      );
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: context.color.secondaryColor,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        crossAxisAlignment: .start,
        children: List.generate(sections.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < _currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6.rh(context),
                margin: .symmetric(
                  vertical: 8.rh(context),
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? context.color.tertiaryColor
                      : context.color.borderColor,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final isActive = stepIndex == _currentStep;
          final isCompleted = stepIndex < _currentStep;
          return Column(
            mainAxisSize: .min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24.rw(context),
                height: 24.rh(context),
                padding: EdgeInsets.all(isCompleted || isActive ? 2 : 6),
                decoration: BoxDecoration(
                  shape: .circle,
                  color: context.color.secondaryColor,
                  border: Border.all(
                    color: isActive || isCompleted
                        ? context.color.tertiaryColor
                        : context.color.borderColor,
                    width: 2,
                  ),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isActive || isCompleted
                        ? context.color.tertiaryColor
                        : context.color.borderColor,
                    shape: .circle,
                  ),
                ),
              ),
              CustomText(
                sections[stepIndex].translatedName,
                color: context.color.textColorDark,
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
    switch (field.fieldType) {
      case 'text':
        return _buildTextField(field);
      case 'number':
        return _buildTextField(field);
      case 'chips':
        return _buildChipsField(field);
      case 'time':
        return _buildTimeField(field);
      case 'social_link':
        return _buildSocialLinkField(field);
      case 'radio':
        return _buildRadioGroup(field);
      case 'checkbox':
        return _buildCheckboxGroup(field);
      case 'dropdown':
        return _buildDropdown(field);
      case 'textarea':
        return _buildTextArea(field);
      case 'file':
        return Column(
          crossAxisAlignment: .start,
          children: [
            AgentFormFieldTitle(
              field.translatedName,
              isRequired: field.isRequired,
            ),
            SizedBox(height: 4.rh(context)),
            AgentDocumentPickerField(
              initialDocument: _selectedDocuments[field.id],
              showExistingFileName: true,
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
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChipsField(AgentRegistrationFormFieldModel field) {
    final key = field.id.toString();
    final fieldValue = _formData[key];
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
      onChanged: (chips) => _formData[key] = chips,
    );
  }

  Widget _buildTimeField(AgentRegistrationFormFieldModel field) {
    final key = field.id.toString();
    return AgentTimeFormField(
      title: field.translatedName,
      initialValue: _formData[key]?.toString(),
      isRequired: field.isRequired,
      onChanged: (time) => _formData[key] = time,
    );
  }

  Widget _buildSocialLinkField(AgentRegistrationFormFieldModel field) {
    final key = field.id.toString();
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(
        text: _formData[key]?.toString() ?? '',
      );
    }
    return AgentSocialLinkFormField(
      title: field.translatedName,
      iconUrl: field.icon,
      controller: _controllers[key]!,
      onChange: (value) => _formData[key] = value,
    );
  }

  List<AppFormOption> _optionsOf(AgentRegistrationFormFieldModel field) {
    // Deduplicate by trimmed value to handle API inconsistencies.
    final unique = {
      for (final option in field.formFieldsValues) option.value.trim(): option,
    };
    return unique.values
        .map(
          (option) => AppFormOption(
            value: option.value.trim(),
            translatedValue: option.translatedValue,
          ),
        )
        .toList();
  }

  Widget _buildTextField(AgentRegistrationFormFieldModel field) {
    final key = field.id.toString();
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(
        text: _formData[key]?.toString() ?? '',
      );
    }
    return AgentTextFormField(
      title: field.translatedName,
      controller: _controllers[key]!,
      isNumber: isNumericAgentFormField(field.name, field.fieldType),
      isRequired: field.isRequired,
      onChange: (value) => _formData[key] = value,
    );
  }

  Widget _buildTextArea(AgentRegistrationFormFieldModel field) {
    final key = field.id.toString();
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(
        text: _formData[key]?.toString() ?? '',
      );
    }
    return AgentTextFormField(
      title: field.translatedName,
      controller: _controllers[key]!,
      isMultiline: true,
      isRequired: field.isRequired,
      onChange: (value) => _formData[key] = value,
    );
  }

  Widget _buildRadioGroup(AgentRegistrationFormFieldModel field) {
    final key = field.id.toString();
    final savedValue = _formData[key]?.toString().trim();
    final firstValue = field.formFieldsValues.first.value.trim();
    final initialValue = (savedValue != null && savedValue.isNotEmpty)
        ? savedValue
        : firstValue;
    return AgentRadioGroupFormField(
      fieldKey: ValueKey('radio_${field.id}'),
      title: field.translatedName,
      options: _optionsOf(field),
      initialValue: initialValue,
      isRequired: field.isRequired,
      onChanged: (value) => _formData[key] = value,
    );
  }

  Widget _buildCheckboxGroup(AgentRegistrationFormFieldModel field) {
    final key = field.id.toString();
    final savedValue = _formData[key];
    var initialValues = <String>[];
    if (savedValue is String && savedValue.isNotEmpty) {
      initialValues = savedValue.split(',').map((e) => e.trim()).toList();
    } else if (savedValue is List<String>) {
      initialValues = savedValue;
    }
    return AgentCheckboxGroupFormField(
      fieldKey: ValueKey('checkbox_${field.id}'),
      title: field.translatedName,
      options: _optionsOf(field),
      initialValues: initialValues,
      isRequired: field.isRequired,
      onChanged: (value) => _formData[key] = value.join(','),
    );
  }

  Widget _buildDropdown(AgentRegistrationFormFieldModel field) {
    if (field.formFieldsValues.isEmpty) return const SizedBox.shrink();
    final key = field.id.toString();
    // Use saved value keyed by field.id (unique) to avoid cross-section contamination
    final savedValue = _formData[key]?.toString().trim();
    final firstValue = field.formFieldsValues.first.value.trim();
    final initialValue = (savedValue != null && savedValue.isNotEmpty)
        ? savedValue
        : firstValue;
    return AgentDropdownFormField(
      fieldKey: ValueKey('dropdown_${field.id}'),
      title: field.translatedName,
      options: _optionsOf(field),
      initialValue: initialValue,
      isRequired: field.isRequired,
      onChanged: (value) => _formData[key] = value,
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
            spacing: 12.rw(context),
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.color.tertiaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: CustomText(
                      'back'.translate(context),
                      color: context.color.tertiaryColor,
                      fontWeight: .w600,
                    ),
                  ),
                ),
              Expanded(
                child: UiUtils.buildButton(
                  context,

                  buttonTitle: isLastStep
                      ? 'submit'.translate(context)
                      : 'next'.translate(context),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitForm(
    List<AgentRegistrationFormSectionModel> sections,
  ) async {
    final formFields = <Map<String, dynamic>>[];
    final socialMediaLinks = <Map<String, dynamic>>[];

    for (final section in sections) {
      for (final field in section.fields) {
        final key = field.id.toString();

        if (field.fieldType == 'social_link') {
          final urlVal = _formData[key]?.toString() ??
              _controllers[key]?.text ??
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
              // Existing unmodified file: send the name reference
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
          final val = _formData[key];
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
          final timeVal = _formData[key]?.toString() ??
              _controllers[key]?.text ??
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
          final value = _formData[key];
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
          final value = _formData[key] ?? _controllers[key]?.text;
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
      'form_type': _formType,
    };
    if (socialMediaLinks.isNotEmpty) {
      parameters['social_media_links'] = socialMediaLinks;
    }

    await context.read<ApplyAgentVerificationCubit>().applyVerification(
      parameters: parameters,
    );
  }
}
