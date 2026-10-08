// Field option value for the become-agent form.
// Uses `agent_verification_form_id` key (not `verify_customer_form_id`).
class AgentRegistrationFieldValue {
  AgentRegistrationFieldValue({
    required this.id,
    required this.agentVerificationFormId,
    required this.value,
    required this.translatedValue,
  });

  factory AgentRegistrationFieldValue.fromJson(Map<String, dynamic> json) {
    return AgentRegistrationFieldValue(
      id: json['id'] as int? ?? 0,
      agentVerificationFormId: json['agent_verification_form_id'] as int? ?? 0,
      value: json['value']?.toString() ?? '',
      translatedValue: json['translated_value']?.toString() ?? '',
    );
  }

  final int id;
  final int agentVerificationFormId;
  final String value;
  final String? translatedValue;
}

class AgentRegistrationFormFieldModel {
  AgentRegistrationFormFieldModel({
    required this.id,
    required this.agentVerificationFormSectionId,
    required this.name,
    required this.fieldType,
    required this.sequence,
    required this.translatedName,
    required this.formFieldsValues,
    this.isRequired = false,
    this.icon,
  });

  factory AgentRegistrationFormFieldModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AgentRegistrationFormFieldModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      agentVerificationFormSectionId:
          json['agent_verification_form_section_id'] is int
          ? json['agent_verification_form_section_id'] as int
          : int.tryParse(
                  json['agent_verification_form_section_id']?.toString() ?? '',
                ) ??
                0,
      name: json['name']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? '',
      sequence: json['sequence'] as int? ?? 0,
      translatedName:
          json['translated_name']?.toString() ?? json['name']?.toString() ?? '',
      isRequired:
          json['is_required'] == true ||
          json['is_required'] == 1 ||
          json['is_required'] == '1',
      icon: json['icon']?.toString(),
      formFieldsValues: json['form_fields_values'] != null
          ? List<AgentRegistrationFieldValue>.from(
              (json['form_fields_values'] as List).map(
                (x) => AgentRegistrationFieldValue.fromJson(
                  x as Map<String, dynamic>,
                ),
              ),
            )
          : [],
    );
  }

  final int id;
  final int agentVerificationFormSectionId;
  final String name;
  final String fieldType;
  final int sequence;
  final String translatedName;
  final bool isRequired;
  final String? icon;
  final List<AgentRegistrationFieldValue> formFieldsValues;
}

class AgentRegistrationFormSectionModel {
  AgentRegistrationFormSectionModel({
    required this.id,
    required this.name,
    required this.formType,
    required this.sequence,
    required this.translatedName,
    required this.fields,
  });

  factory AgentRegistrationFormSectionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawFields =
        json['agent_verification_forms'] as List? ??
        json['fields'] as List? ??
        [];
    return AgentRegistrationFormSectionModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      formType: json['form_type']?.toString() ?? '',
      sequence: json['sequence'] as int? ?? 0,
      translatedName:
          json['translated_name']?.toString() ?? json['name']?.toString() ?? '',
      fields: List<AgentRegistrationFormFieldModel>.from(
        rawFields.map(
          (x) => AgentRegistrationFormFieldModel.fromJson(
            x as Map<String, dynamic>,
          ),
        ),
      ),
    );
  }

  final int id;
  final String name;
  final String formType;
  final int sequence;
  final String translatedName;
  final List<AgentRegistrationFormFieldModel> fields;
}
