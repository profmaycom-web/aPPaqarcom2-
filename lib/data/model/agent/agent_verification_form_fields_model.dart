class AgentVerificationFormFieldsModel {
  AgentVerificationFormFieldsModel({
    required this.id,
    required this.name,
    required this.translatedName,
    required this.fieldType,
    required this.formFieldsValues,
    this.isRequired = false,
    this.icon,
  });

  factory AgentVerificationFormFieldsModel.fromJson(Map<String, dynamic> json) {
    return AgentVerificationFormFieldsModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      translatedName: json['translated_name']?.toString() ?? json['name']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? '',
      isRequired: json['is_required'] == true ||
          json['is_required'] == 1 ||
          json['is_required'] == '1',
      icon: json['icon']?.toString(),
      formFieldsValues: json['form_fields_values'] != null
          ? List<FormFieldValue>.from(
              (json['form_fields_values'] as List).map(
                (x) => FormFieldValue.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }
  final int id;
  final String name;
  final String? translatedName;
  final String fieldType;
  final bool isRequired;
  final String? icon;
  final List<FormFieldValue> formFieldsValues;
}

class FormFieldValue {
  FormFieldValue({
    required this.id,
    required this.verifyCustomerFormId,
    required this.value,
    required this.translatedValue,
  });

  factory FormFieldValue.fromJson(Map<String, dynamic> json) {
    return FormFieldValue(
      id: json['id'] as int,
      verifyCustomerFormId: json['verify_customer_form_id'] as int,
      value: json['value']?.toString() ?? '',
      translatedValue: json['translated_value']?.toString() ?? '',
    );
  }
  final int id;
  final int verifyCustomerFormId;
  final String value;
  final String? translatedValue;
}
