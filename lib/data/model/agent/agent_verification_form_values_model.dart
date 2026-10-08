import 'package:ebroker/data/model/agent/social_media_link_model.dart';

class AgentVerificationFormValueModel {
  AgentVerificationFormValueModel({
    this.id,
    this.userId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.user,
    this.verifyCustomerValues,
    this.workingHoursTotalPerDay,
    this.socialMediaLinks,
  });

  AgentVerificationFormValueModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int?
        : int.tryParse(json['id']?.toString() ?? '');
    userId = json['user_id'] is int
        ? json['user_id'] as int?
        : int.tryParse(json['user_id']?.toString() ?? '');
    status = json['status']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
    deletedAt = json['deleted_at']?.toString() ?? '';
    workingHoursTotalPerDay = json['working_hours_total_per_day'] != null
        ? (json['working_hours_total_per_day'] as num).toDouble()
        : null;
    user = json['user'] != null
        ? User.fromJson(json['user'] as Map<String, dynamic>)
        : (json['customer'] != null
              ? User.fromJson(json['customer'] as Map<String, dynamic>)
              : null);
    if (json['verify_customer_values'] != null) {
      verifyCustomerValues = <VerifyCustomerValues>[];
      for (final dynamic v in json['verify_customer_values'] as List) {
        verifyCustomerValues!.add(
          VerifyCustomerValues.fromJson(v as Map<String, dynamic>),
        );
      }
    } else if (json['values'] != null) {
      verifyCustomerValues = <VerifyCustomerValues>[];
      for (final dynamic v in json['values'] as List) {
        verifyCustomerValues!.add(
          VerifyCustomerValues.fromJson(v as Map<String, dynamic>),
        );
      }
    }
    if (json['social_media_links'] != null) {
      socialMediaLinks = <SocialMediaLinkModel>[];
      for (final dynamic v in json['social_media_links'] as List) {
        if (v is Map) {
          socialMediaLinks!.add(
            SocialMediaLinkModel.fromJson(v),
          );
        }
      }
    }
  }
  int? id;
  int? userId;
  String? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  User? user;
  List<VerifyCustomerValues>? verifyCustomerValues;
  double? workingHoursTotalPerDay;
  List<SocialMediaLinkModel>? socialMediaLinks;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (workingHoursTotalPerDay != null) {
      data['working_hours_total_per_day'] = workingHoursTotalPerDay;
    }
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (verifyCustomerValues != null) {
      data['verify_customer_values'] = verifyCustomerValues!
          .map((v) => v.toJson())
          .toList();
    }
    if (socialMediaLinks != null) {
      data['social_media_links'] = socialMediaLinks!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }
}

class User {
  User({
    this.id,
    this.name,
    this.profile,
    this.propertyCount,
    this.projectsCount,
    this.email,
    this.mobile,
    this.countryCode,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int?
        : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString() ?? '';
    profile = json['profile']?.toString() ?? '';
    propertyCount = json['property_count']?.toString() ?? '0';
    projectsCount = json['projects_count']?.toString() ?? '0';
    email = json['email']?.toString();
    mobile = json['mobile']?.toString();
    countryCode = json['country_code']?.toString();
  }
  int? id;
  String? name;
  String? profile;
  String? propertyCount;
  String? projectsCount;
  String? email;
  String? mobile;
  String? countryCode;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['profile'] = profile;
    data['property_count'] = propertyCount;
    data['projects_count'] = projectsCount;
    if (email != null) data['email'] = email;
    if (mobile != null) data['mobile'] = mobile;
    if (countryCode != null) data['country_code'] = countryCode;
    return data;
  }
}

class VerifyCustomerValues {
  VerifyCustomerValues({
    this.id,
    this.verifyCustomerId,
    this.verifyCustomerFormId,
    this.value,
    this.verifyForm,
  });

  VerifyCustomerValues.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int?
        : int.tryParse(json['id']?.toString() ?? '');
    verifyCustomerId = json['verify_customer_id'] is int
        ? json['verify_customer_id'] as int?
        : int.tryParse(json['verify_customer_id']?.toString() ?? '');
    verifyCustomerFormId = json['verify_customer_form_id'] is int
        ? json['verify_customer_form_id'] as int?
        : (json['agent_verification_form_id'] is int
              ? json['agent_verification_form_id'] as int?
              : int.tryParse(
                  json['verify_customer_form_id']?.toString() ??
                      json['agent_verification_form_id']?.toString() ??
                      '',
                ));
    value = json['value'];
    final formJson =
        json['verify_form'] ?? json['agent_verification_form'] ?? json['form'];
    verifyForm = formJson is Map<String, dynamic>
        ? VerifyForm.fromJson(formJson)
        : null;
  }
  int? id;
  int? verifyCustomerId;
  int? verifyCustomerFormId;
  dynamic value;
  VerifyForm? verifyForm;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['verify_customer_id'] = verifyCustomerId;
    data['verify_customer_form_id'] = verifyCustomerFormId;
    data['value'] = value;
    if (verifyForm != null) {
      data['verify_form'] = verifyForm!.toJson();
    }
    return data;
  }
}

class VerifyForm {
  VerifyForm({this.id, this.name, this.fieldType, this.formFieldsValues});

  VerifyForm.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int?
        : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString() ?? json['field_name']?.toString() ?? '';
    fieldType = json['field_type']?.toString() ?? '';
    if (json['form_fields_values'] != null) {
      formFieldsValues = <FormFieldsValues>[];
      for (final dynamic v in json['form_fields_values'] as List) {
        formFieldsValues!.add(
          FormFieldsValues.fromJson(v as Map<String, dynamic>),
        );
      }
    }
  }
  int? id;
  String? name;
  String? fieldType;
  List<FormFieldsValues>? formFieldsValues;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['field_type'] = fieldType;
    if (formFieldsValues != null) {
      data['form_fields_values'] = formFieldsValues!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }
}

class FormFieldsValues {
  FormFieldsValues({this.id, this.verifyCustomerFormId, this.value});

  FormFieldsValues.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    verifyCustomerFormId = json['verify_customer_form_id'] as int?;
    value = json['value']?.toString() ?? '';
  }
  int? id;
  int? verifyCustomerFormId;
  String? value;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['verify_customer_form_id'] = verifyCustomerFormId;
    data['value'] = value;
    return data;
  }
}
