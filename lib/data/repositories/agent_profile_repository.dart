import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/hive_utils.dart';

class AgentProfileRepository {
  Future<AgentProfileModel> getAgentProfile({String? agentId}) async {
    final effectiveAgentId = (agentId != null && agentId.isNotEmpty)
        ? agentId
        : HiveUtils.getUserId();

    // Run all 3 API calls in parallel for speed
    final futures = await Future.wait<Map<String, dynamic>>([
      _fetchAgentProfile(effectiveAgentId),
      _fetchAgentProperties(effectiveAgentId),
      _fetchVerificationFormValues(effectiveAgentId),
    ]);

    final profileData = futures[0];
    final propertiesData = futures[1];
    final verificationData = futures[2];

    // Merge: start with profile data as base, then overlay properties, then verification
    final merged = <String, dynamic>{};

    // Layer 1: profile API data
    merged.addAll(profileData);

    // Layer 2: properties API data (only fills in missing fields)
    for (final entry in propertiesData.entries) {
      if (merged[entry.key] == null ||
          (merged[entry.key] is String &&
              (merged[entry.key] as String).isEmpty)) {
        merged[entry.key] = entry.value;
      }
    }

    // Layer 3: verification form values (always add verify_customer_values
    // since it's the most detailed source for business fields)
    for (final entry in verificationData.entries) {
      if (entry.key == 'verify_customer_values') {
        // Always prefer a non-empty verification list
        final existing = merged['verify_customer_values'];
        if (existing == null || (existing is List && existing.isEmpty)) {
          merged['verify_customer_values'] = entry.value;
        }
      } else if (merged[entry.key] == null ||
          (merged[entry.key] is String &&
              (merged[entry.key] as String).isEmpty)) {
        merged[entry.key] = entry.value;
      }
    }

    if (merged.isNotEmpty) {
      return AgentProfileModel.fromMap(merged);
    }

    return AgentProfileModel.fromMap(const {});
  }

  /// Fetches from get-agent-profile and flattens nested maps.
  Future<Map<String, dynamic>> _fetchAgentProfile(String? agentId) async {
    try {
      final response = await Api.get(
        url: Api.apiGetAgentProfile,
        queryParameters: agentId != null && agentId.isNotEmpty
            ? {
                'agent_id': agentId,
                'id': agentId,
                'user_id': agentId,
                'customer_id': agentId,
              }
            : null,
        passCountryId: false,
      );

      final result = <String, dynamic>{};
      dynamic rawData = response['data'];
      if (rawData is List && rawData.isNotEmpty) rawData = rawData.first;

      if (rawData is Map) {
        final rMap = Map<String, dynamic>.from(rawData);
        _flattenProfileMap(rMap, result);
      }
      return result;
    } on Exception catch (_) {
      return {};
    }
  }

  /// Fetches from agent-properties and extracts all business profile fields.
  Future<Map<String, dynamic>> _fetchAgentProperties(String? agentId) async {
    if (agentId == null || agentId.isEmpty) return {};
    try {
      final propRes = await Api.get(
        url: Api.getAgentProperties,
        queryParameters: {
          Api.id: agentId,
          'agent_id': agentId,
          Api.offset: 0,
          Api.limit: 1,
        },
        passCountryId: false,
      );

      final result = <String, dynamic>{};
      final dynamic pData = propRes['data'];
      if (pData is Map) {
        final pMap = Map<String, dynamic>.from(pData);
        _flattenProfileMap(pMap, result);
      }
      return result;
    } on Exception catch (_) {
      return {};
    }
  }

  /// Fetches from get-agent-verification-form-values.
  Future<Map<String, dynamic>> _fetchVerificationFormValues(
    String? agentId,
  ) async {
    if (agentId == null || agentId.isEmpty) return {};
    try {
      final verificationRes = await Api.get(
        url: Api.apiGetAgentVerificationFormValues,
        queryParameters: {
          'agent_id': agentId,
          'user_id': agentId,
          'id': agentId,
        },
        passCountryId: false,
      );

      final result = <String, dynamic>{};
      dynamic vData = verificationRes['data'];
      if (vData is List && vData.isNotEmpty) vData = vData.first;
      if (vData is Map) {
        final vMap = Map<String, dynamic>.from(vData);
        _flattenProfileMap(vMap, result);
      }
      return result;
    } on Exception catch (_) {
      return {};
    }
  }

  /// Recursively flattens a profile API response map into [result].
  /// Handles nested keys: agent_profile, customer_data, agent_details, agent, verification.
  void _flattenProfileMap(
    Map<String, dynamic> source,
    Map<String, dynamic> result,
  ) {
    // First flatten all well-known nested maps
    for (final nestedKey in [
      'agent_profile',
      'customer_data',
      'agent_details',
      'agent',
      'verification',
    ]) {
      if (source[nestedKey] is Map) {
        final nested = Map<String, dynamic>.from(source[nestedKey] as Map);
        _flattenProfileMap(nested, result);
      }
    }

    // Then add root-level fields (root overrides nested so profile data wins)
    for (final entry in source.entries) {
      if (entry.key == 'verify_customer_values') {
        // Always merge verify_customer_values lists
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          final existing = result['verify_customer_values'];
          if (existing is List) {
            // Combine both lists, deduplicating by id
            final combined = [...existing];
            for (final item in entry.value as List) {
              if (item is Map) {
                final id = item['id'];
                final alreadyExists = combined.any(
                  (e) => e is Map && e['id'] == id,
                );
                if (!alreadyExists) combined.add(item);
              }
            }
            result['verify_customer_values'] = combined;
          } else {
            result['verify_customer_values'] = entry.value;
          }
        }
      } else if (!_isNestedProfileKey(entry.key)) {
        result[entry.key] = entry.value;
      }
    }
  }

  bool _isNestedProfileKey(String key) {
    return key == 'agent_profile' ||
        key == 'customer_data' ||
        key == 'agent_details' ||
        key == 'agent' ||
        key == 'verification';
  }

  Future<Map<String, dynamic>> updateAgentProfile({
    String? agentName,
    String? email,
    String? address,
    String? aboutMe,
    String? mobile,
    String? countryCode,
    List<Map<String, dynamic>>? socialMediaLinks,
    String? serviceAreas,
    String? languages,
    String? experience,
    String? startTime,
    String? endTime,
    File? profilePhoto,
    File? agentBanner,
  }) async {
    final params = <String, dynamic>{
      'agent_name': agentName,
      'agent_email': email,
      'about_me': aboutMe,
      'agent_address': address,
      'agent_mobile': mobile,
      'country_code': countryCode,
    };

    if (socialMediaLinks != null && socialMediaLinks.isNotEmpty) {
      params['social_media_links'] = socialMediaLinks;
    }

    if (serviceAreas != null) {
      params['service_areas'] = serviceAreas;
      params['service_area'] = serviceAreas;
    }
    if (languages != null) {
      params['languages'] = languages;
      params['languages_spoken'] = languages;
    }
    if (experience != null) {
      params['experience'] = experience;
      params['years_of_experience'] = experience;
    }
    if (startTime != null) {
      params['start_time'] = startTime;
      params['working_hours_start'] = startTime;
    }
    if (endTime != null) {
      params['end_time'] = endTime;
      params['working_hours_end'] = endTime;
    }

    if (profilePhoto != null) {
      params['agent_profile_photo'] = await MultipartFile.fromFile(
        profilePhoto.path,
      );
    }

    if (agentBanner != null) {
      params['agent_banner'] = await MultipartFile.fromFile(
        agentBanner.path,
      );
    }

    return Api.post(
      url: Api.apiUpdateAgentProfile,
      parameter: params,
      passCountryId: false,
    );
  }
}
