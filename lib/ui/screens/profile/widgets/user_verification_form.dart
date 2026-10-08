import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:ebroker/data/cubits/agents/apply_user_verification_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_user_verification_form_fields_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_user_verification_form_values_cubit.dart';
import 'package:ebroker/data/cubits/auth/get_user_data_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:ebroker/data/model/agent/agent_verification_form_fields_model.dart';
import 'package:ebroker/data/model/agent/agent_verification_form_values_model.dart';
import 'package:ebroker/ui/screens/widgets/agent_form_fields.dart';
import 'package:ebroker/ui/screens/widgets/errors/no_data_found.dart';
import 'package:ebroker/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class UserVerificationForm extends StatefulWidget {
  const UserVerificationForm({super.key});

  @override
  State<UserVerificationForm> createState() => _UserVerificationFormState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => FetchUserVerificationFormValuesCubit(),
          ),
          BlocProvider(
            create: (context) => FetchUserVerificationFormFieldsCubit(),
          ),
          BlocProvider(
            create: (context) => ApplyUserVerificationCubit(),
          ),
        ],
        child: const UserVerificationForm(),
      ),
    );
  }
}

class _UserVerificationFormState extends State<UserVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};
  bool _isFormInitialized = false;
  final Map<int, AgentDocuments> _selectedDocuments = {};

  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<FetchUserVerificationFormFieldsCubit>().fetch(),
    );
    unawaited(
      context.read<FetchUserVerificationFormValuesCubit>().fetch(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: 'userVerificationForm'.translate(context),
      ),
      body: BlocProvider.value(
        value: context.read<FetchUserVerificationFormValuesCubit>(),
        child:
            BlocBuilder<
              FetchUserVerificationFormFieldsCubit,
              FetchUserVerificationFormFieldsState
            >(
              builder: (context, fieldsState) {
                return BlocBuilder<
                  FetchUserVerificationFormValuesCubit,
                  FetchUserVerificationFormValuesState
                >(
                  builder: (context, valuesState) {
                    if (fieldsState is FetchUserVerificationFormFieldsSuccess &&
                        valuesState is FetchUserVerificationFormValuesSuccess) {
                      // Call _initializeFormData here,
                      // when both states are successful
                      if (!_isFormInitialized &&
                          valuesState.values.isNotEmpty) {
                        _initializeFormData(valuesState.values.first);
                      }
                      return _buildForm(context, fieldsState, valuesState);
                    } else if (fieldsState
                            is FetchUserVerificationFormFieldsSuccess &&
                        valuesState is FetchUserVerificationFormValuesFailure) {
                      if (fieldsState.fields.isEmpty) {
                        return NoDataFound(
                          title: 'noVerificationFormFieldsFound'.translate(
                            context,
                          ),
                          description:
                              'noVerificationFormFieldsFoundDescription'
                                  .translate(context),
                          onTapRetry: () async {
                            await context
                                .read<FetchUserVerificationFormFieldsCubit>()
                                .fetch();
                          },
                        );
                      }
                      // Handle the case where values failed to load
                      return _buildFormWithoutValues(context, fieldsState);
                    } else if (fieldsState
                            is FetchUserVerificationFormFieldsLoading ||
                        valuesState is FetchUserVerificationFormValuesLoading) {
                      return Center(child: UiUtils.progress());
                    } else if (fieldsState
                        is FetchUserVerificationFormFieldsFailure) {
                      return SomethingWentWrong(
                        errorMessage: fieldsState.errorMessage,
                      );
                    }
                    return Container();
                  },
                );
              },
            ),
      ),
    );
  }

  Widget _buildFormWithoutValues(
    BuildContext context,
    FetchUserVerificationFormFieldsSuccess fieldsState,
  ) {
    // Build the form with empty or default values
    return _buildForm(
      context,
      fieldsState,
      FetchUserVerificationFormValuesSuccess(values: []),
    );
  }

  Widget _buildForm(
    BuildContext context,
    FetchUserVerificationFormFieldsSuccess fieldsState,
    FetchUserVerificationFormValuesSuccess valuesState,
  ) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: .start,
            children: [
              ...fieldsState.fields.map(_buildFormField),
              SizedBox(height: 16.rh(context)),
              BlocConsumer<
                ApplyUserVerificationCubit,
                ApplyUserVerificationState
              >(
                listener: (context, state) async {
                  if (state is ApplyUserVerificationSuccess) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      'verificationApplied',
                      type: .success,
                    );
                    await context.read<GetUserDataCubit>().getUserData();
                    await context
                        .read<FetchSystemSettingsCubit>()
                        .fetchSettings(
                          isAnonymous: false,
                          forceRefresh: true,
                        );
                    Navigator.pop(context);
                  } else if (state is ApplyUserVerificationFailure) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      '''${'failedTOApplyVerification'.translate(context)}: ${state.errorMessage.translate(context)}''',
                      type: .error,
                    );
                  }
                },
                builder: (context, state) {
                  return UiUtils.buildButton(
                    context,
                    onPressed: _submitForm,
                    buttonTitle: state is ApplyUserVerificationInProgress
                        ? ''
                        : 'submit'.translate(context),
                    prefixWidget: state is ApplyUserVerificationInProgress
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.color.buttonColor,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(AgentVerificationFormFieldsModel field) {
    final fieldValue = _formData[field.name];

    switch (field.fieldType) {
      case 'text':
        return _buildTextField(field, fieldValue?.toString() ?? '');
      case 'number':
        return _buildTextField(field, fieldValue?.toString() ?? '');
      case 'radio':
        return _buildRadioGroup(field, fieldValue?.toString() ?? '');
      case 'checkbox':
        return _buildCheckboxGroup(field, fieldValue);
      case 'dropdown':
        return _buildDropdown(field, fieldValue?.toString() ?? '');
      case 'textarea':
        return _buildTextArea(field, fieldValue?.toString() ?? '');
      case 'file':
        return Column(
          crossAxisAlignment: .start,
          children: [
            AgentFormFieldTitle(field.translatedName ?? field.name),
            SizedBox(height: 4.rh(context)),
            AgentDocumentPickerField(
              initialDocument: _selectedDocuments[field.id],
              showDownloadLink: true,
              onDocumentSelected: (document) {
                setState(() {
                  if (document != null) {
                    _selectedDocuments[field.id] = document;
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
        return Container();
    }
  }

  Widget _buildTextField(
    AgentVerificationFormFieldsModel field,
    String? fieldValue,
  ) {
    if (!_controllers.containsKey(field.name)) {
      _controllers[field.name] = TextEditingController(text: fieldValue);
    }

    return AgentTextFormField(
      title: field.translatedName ?? field.name,
      controller: _controllers[field.name]!,
      isNumber: field.fieldType == 'number',
      onChange: (value) => _formData[field.name] = value,
    );
  }

  List<AppFormOption> _optionsOf(AgentVerificationFormFieldsModel field) {
    return field.formFieldsValues
        .map(
          (option) => AppFormOption(
            value: option.value,
            translatedValue: option.translatedValue,
          ),
        )
        .toList();
  }

  Widget _buildRadioGroup(
    AgentVerificationFormFieldsModel field,
    String? fieldValue,
  ) {
    return AgentRadioGroupFormField(
      title: field.translatedName ?? field.name,
      options: _optionsOf(field),
      initialValue: fieldValue,
      onChanged: (value) => _formData[field.name] = value,
    );
  }

  Widget _buildCheckboxGroup(
    AgentVerificationFormFieldsModel field,
    dynamic fieldValue,
  ) {
    var initialValues = <String>[];
    if (fieldValue is String) {
      initialValues = fieldValue.split(',').map((e) => e.trim()).toList();
    } else if (fieldValue is List<String>) {
      initialValues = fieldValue;
    }

    return AgentCheckboxGroupFormField(
      title: field.translatedName ?? field.name,
      options: _optionsOf(field),
      initialValues: initialValues,
      onChanged: (value) => _formData[field.name] = value.join(','),
    );
  }

  Widget _buildDropdown(
    AgentVerificationFormFieldsModel field,
    String? fieldValue,
  ) {
    return AgentDropdownFormField(
      title: field.translatedName ?? field.name,
      options: _optionsOf(field),
      onChanged: (value) => _formData[field.name] = value,
    );
  }

  Widget _buildTextArea(
    AgentVerificationFormFieldsModel field,
    String? fieldValue,
  ) {
    if (!_controllers.containsKey(field.name)) {
      _controllers[field.name] = TextEditingController(text: fieldValue);
    }

    return AgentTextFormField(
      title: field.translatedName ?? field.name,
      controller: _controllers[field.name]!,
      isMultiline: true,
      onChange: (value) => _formData[field.name] = value,
    );
  }

  void _initializeFormData(AgentVerificationFormValueModel values) {
    if (_isFormInitialized) return;

    try {
      final userFormValues = values;

      if (userFormValues.verifyCustomerValues != null) {
        for (final value in userFormValues.verifyCustomerValues!) {
          final fieldName = value.verifyForm?.name;
          final fieldValue = value.value;
          final fieldId = value.verifyForm?.id;
          final fieldType = value.verifyForm?.fieldType;

          if (fieldName == null || fieldType == null) continue;

          switch (fieldType) {
            case 'checkbox':
              _formData[fieldName] = _parseCheckboxValue(fieldValue).join(',');
            case 'file':
              if (fieldId != null && fieldValue != null) {
                _selectedDocuments[fieldId] = AgentDocuments(
                  id: fieldId,
                  name: fieldValue.toString(),
                  isExisting: true,
                );
              }
            case 'radio':
            case 'dropdown':
              _formData[fieldName] = fieldValue?.toString();
            default:
              _formData[fieldName] = fieldValue?.toString() ?? '';
              _controllers[fieldName] = TextEditingController(
                text: fieldValue?.toString() ?? '',
              );
          }
        }
      }
    } on Exception catch (e, stackTrace) {
      debugPrint('Error initializing form data: $e\n$stackTrace');
      // Handle error appropriately
    } finally {
      _isFormInitialized = true;
    }
  }

  List<String> _parseCheckboxValue(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  Future<void> _submitForm() async {
    try {
      if (_formKey.currentState!.validate()) {
        final fetchFormFieldsState = context
            .read<FetchUserVerificationFormFieldsCubit>()
            .state;
        if (fetchFormFieldsState is FetchUserVerificationFormFieldsSuccess) {
          final formFields = <Map<String, dynamic>>[];

          for (final field in fetchFormFieldsState.fields) {
            if (field.fieldType == 'file') {
              final selectedDocument = _selectedDocuments[field.id];
              if (selectedDocument == null) {
                HelperUtils.showSnackBarMessage(
                  context,
                  'pleaseSelectAValidDocument',
                  type: .error,
                );
                return;
              }

              if (selectedDocument.isExisting &&
                  selectedDocument.file == null) {
                continue;
              }

              final documentField = prepareDocumentForFormField(
                field.id,
                selectedDocument,
              );

              if (documentField.isNotEmpty) {
                formFields.add(documentField);
              } else {
                HelperUtils.showSnackBarMessage(
                  context,
                  'pleaseSelectAValidDocument',
                  type: .error,
                );
                return;
              }
            } else if (field.fieldType == 'checkbox') {
              final value = _formData[field.name];
              if (value != null && value.toString().isNotEmpty) {
                formFields.add({
                  'id': field.id.toString(),
                  'value': value.toString(),
                });
              }
            } else {
              final value = _formData[field.name];
              if (value != null) {
                formFields.add({
                  'id': field.id.toString(),
                  'value': value.toString(),
                });
              }
            }
          }

          final submissionData = {'form_fields': formFields};

          await context.read<ApplyUserVerificationCubit>().applyVerification(
            parameters: submissionData,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText('unableToSubmitForm'.translate(context)),
            ),
          );
        }
      }
    } on Exception catch (_) {
      HelperUtils.showSnackBarMessage(
        context,
        'unableToSubmitForm',
        type: .error,
      );
    }
  }
}
