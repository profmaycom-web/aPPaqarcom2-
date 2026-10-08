import 'dart:convert';
import 'package:ebroker/data/model/agent/social_media_link_model.dart';

class AgentProfileModel {
  AgentProfileModel({
    this.id,
    this.customerId,
    this.agentName,
    this.agentEmail,
    this.agentAddress,
    this.agentMobile,
    this.agentCountryCode,
    this.agentProfilePhoto,
    this.agentBanner,
    this.socialMediaLinks = const [],
    this.aboutMe,
    this.agentVerificationRejectReason,
    this.totalFollowers,
    this.serviceAreas,
    this.languages,
    this.experience,
    this.startTime,
    this.endTime,
    this.customFields = const {},
  });

  factory AgentProfileModel.fromJson(String str) =>
      AgentProfileModel.fromMap(json.decode(str) as Map<String, dynamic>);

  factory AgentProfileModel.fromMap(Map<String, dynamic> json) {
    var serviceAreas = _extractString(
      json['service_areas'] ??
          json['service_area'] ??
          json['service_areas_spoken'],
    );
    var languages = _extractString(
      json['languages'] ??
          json['languages_spoken'] ??
          json['language'],
    );
    var experience = _extractString(
      json['experience'] ??
          json['years_of_experience'] ??
          json['experience_years'],
    );
    var startTime = _extractString(
      json['start_time'] ??
          json['working_hours_start'] ??
          json['working_hours_start_time'],
    );
    var endTime = _extractString(
      json['end_time'] ??
          json['working_hours_end'] ??
          json['working_hours_end_time'],
    );

    final formValues = json['verify_customer_values'] as List? ??
        json['values'] as List? ??
        json['form_fields'] as List? ??
        json['custom_fields'] as List?;
    final customFieldsMap = <String, String>{};
    if (formValues != null) {
      for (final item in formValues) {
        if (item is Map) {
          final form = item['verify_form'] ??
              item['agent_verification_form'] ??
              item['form'];
          final formName = (form is Map ? form['name']?.toString() : null) ??
              item['name']?.toString() ??
              '';
          final val = _extractString(item['value']);
          if (val == null || val.isEmpty) continue;
          final lower = formName.toLowerCase().trim();

          if (serviceAreas == null &&
              (lower.contains('service') ||
                  (lower.contains('area') && !lower.contains('experience')) ||
                  lower.contains('region') ||
                  lower.contains('zone') ||
                  lower.contains('district') ||
                  lower.contains('locality') ||
                  lower.contains('location'))) {
            serviceAreas = val;
          } else if (languages == null &&
              (lower.contains('language') ||
                  lower.contains('lang') ||
                  lower.contains('speak') ||
                  lower.contains('fluent') ||
                  lower.contains('tongue'))) {
            languages = val;
          } else if (experience == null &&
              (lower.contains('experience') ||
                  lower == 'exp' ||
                  lower.endsWith(' exp') ||
                  lower.startsWith('exp ') ||
                  lower.contains('years of') ||
                  lower.contains('year'))) {
            experience = val;
          } else if (startTime == null &&
              (lower.contains('start') ||
                  lower.contains('begin') ||
                  lower.contains('opening') ||
                  (lower.contains('from') && lower.length < 15))) {
            startTime = val;
          } else if (endTime == null &&
              (lower.contains('close') ||
                  lower.contains('until') ||
                  (lower.contains('end') && !lower.contains('experience')) ||
                  (lower == 'to' || lower == 'until'))) {
            endTime = val;
          } else if (!lower.contains('about') &&
              !lower.contains('bio') &&
              !lower.contains('description') &&
              !lower.contains('introduction') &&
              formName.isNotEmpty) {
            customFieldsMap[formName] = val;
          }
        }
      }
    }

    return AgentProfileModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      customerId: json['customer_id'] is int
          ? json['customer_id'] as int
          : int.tryParse(json['customer_id']?.toString() ?? ''),
      agentName: _firstNonEmpty(json, ['agent_name', 'name']),
      agentEmail: _firstNonEmpty(json, ['agent_email', 'email']),
      agentAddress: _firstNonEmpty(json, ['agent_address', 'address']),
      agentMobile: _firstNonEmpty(json, ['agent_mobile', 'mobile']),
      agentCountryCode:
          _firstNonEmpty(json, ['agent_country_code', 'country_code']),
      agentProfilePhoto: _firstNonEmpty(
        json,
        ['agent_profile_photo', 'profile', 'profile_photo'],
      ),
      agentBanner:
          json['agent_banner']?.toString() ?? json['banner']?.toString(),
      socialMediaLinks: (json['social_media_links'] as List? ??
              json['social_media'] as List? ??
              json['social_links'] as List? ??
              json['socials'] as List?)
          ?.map(
            (e) => e is Map ? SocialMediaLinkModel.fromJson(e) : null,
          )
          .whereType<SocialMediaLinkModel>()
          .toList() ??
          [],
      aboutMe: _firstNonEmpty(json, ['about_me', 'about', 'bio']),
      agentVerificationRejectReason:
          json['agent_verification_reject_reason']?.toString(),
      totalFollowers: json['followers_count']?.toString() ??
          json['follower_count']?.toString() ??
          json['total_followers']?.toString(),
      serviceAreas: serviceAreas,
      languages: languages,
      experience: experience,
      startTime: startTime,
      endTime: endTime,
      customFields: customFieldsMap,
    );
  }

  /// Returns the first non-empty value among [keys], so an empty
  /// `agent_*` field falls back to the matching plain field.
  static String? _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  static String? _extractString(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final list = value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return list.isNotEmpty ? list.join(',') : null;
    }
    final str = value.toString().trim();
    if (str.startsWith('[') && str.endsWith(']')) {
      final inner = str.substring(1, str.length - 1).trim();
      return inner.isEmpty ? null : inner;
    }
    return str.isEmpty ? null : str;
  }


  final int? id;
  final int? customerId;
  final String? agentName;
  final String? agentEmail;
  final String? agentAddress;
  final String? agentMobile;
  final String? agentCountryCode;
  final String? agentProfilePhoto;
  final String? agentBanner;
  final List<SocialMediaLinkModel> socialMediaLinks;
  final String? aboutMe;
  final String? agentVerificationRejectReason;
  final String? totalFollowers;
  final String? serviceAreas;
  final String? languages;
  final String? experience;
  final String? startTime;
  final String? endTime;
  final Map<String, String> customFields;

  AgentProfileModel copyWith({
    int? id,
    int? customerId,
    String? agentName,
    String? agentEmail,
    String? agentAddress,
    String? agentMobile,
    String? agentCountryCode,
    String? agentProfilePhoto,
    String? agentBanner,
    List<SocialMediaLinkModel>? socialMediaLinks,
    String? aboutMe,
    String? agentVerificationRejectReason,
    String? totalFollowers,
    String? serviceAreas,
    String? languages,
    String? experience,
    String? startTime,
    String? endTime,
    Map<String, String>? customFields,
  }) => AgentProfileModel(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    agentName: agentName ?? this.agentName,
    agentEmail: agentEmail ?? this.agentEmail,
    agentAddress: agentAddress ?? this.agentAddress,
    agentMobile: agentMobile ?? this.agentMobile,
    agentCountryCode: agentCountryCode ?? this.agentCountryCode,
    agentProfilePhoto: agentProfilePhoto ?? this.agentProfilePhoto,
    agentBanner: agentBanner ?? this.agentBanner,
    socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
    aboutMe: aboutMe ?? this.aboutMe,
    agentVerificationRejectReason:
        agentVerificationRejectReason ?? this.agentVerificationRejectReason,
    totalFollowers: totalFollowers ?? this.totalFollowers,
    serviceAreas: serviceAreas ?? this.serviceAreas,
    languages: languages ?? this.languages,
    experience: experience ?? this.experience,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    customFields: customFields ?? this.customFields,
  );

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
    'id': id,
    'customer_id': customerId,
    'agent_name': agentName,
    'agent_email': agentEmail,
    'agent_address': agentAddress,
    'agent_mobile': agentMobile,
    'agent_country_code': agentCountryCode,
    'agent_profile_photo': agentProfilePhoto,
    'agent_banner': agentBanner,
    'social_media_links': socialMediaLinks.map((e) => e.toJson()).toList(),
    'about_me': aboutMe,
    'agent_verification_reject_reason': agentVerificationRejectReason,
    'total_followers': totalFollowers,
    'service_areas': serviceAreas,
    'languages': languages,
    'experience': experience,
    'start_time': startTime,
    'end_time': endTime,
    'custom_fields': customFields,
  };

  @override
  String toString() {
    return 'AgentProfileModel(id: $id, customerId: $customerId, agentName: $agentName, agentEmail: $agentEmail, agentAddress: $agentAddress, agentMobile: $agentMobile, agentCountryCode: $agentCountryCode, agentProfilePhoto: $agentProfilePhoto, agentBanner: $agentBanner, socialMediaLinks: $socialMediaLinks, aboutMe: $aboutMe, totalFollowers: $totalFollowers, serviceAreas: $serviceAreas, languages: $languages, experience: $experience, startTime: $startTime, endTime: $endTime)';
  }
}
