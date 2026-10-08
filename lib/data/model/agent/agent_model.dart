import 'package:ebroker/utils/admob/native_ad_manager.dart';

bool _parseBool(dynamic val, {bool defaultValue = false}) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) {
    return val == '1' || val.toLowerCase() == 'true';
  }
  return defaultValue;
}

class AgentModel implements NativeAdWidgetContainer {
  const AgentModel({
    required this.id,
    required this.name,
    required this.profile,
    required this.email,
    required this.projectsCount,
    required this.propertyCount,
    required this.mobile,
    required this.isAdmin,
    required this.isAgentVerified,
    this.followersCount,
    this.banner,
    this.isFollowing = false,
    this.isAppointmentAvailable = false,
    this.hasAppointmentInfo = true,
    this.mobileCountryCode,
  });

  AgentModel.fromJson(
    Map<String, dynamic> json, {
    bool defaultIsFollowing = false,
  }) : id = json['id'] as int? ?? 0,
       name = json['name']?.toString() ?? '',
       profile =
           json['profile']?.toString() ??
           (json['agent_profile'] is Map
               ? json['agent_profile']['agent_profile_photo']?.toString()
               : null) ??
           '',
       email =
           json['email']?.toString() ??
           (json['agent_profile'] is Map
               ? json['agent_profile']['agent_email']?.toString()
               : null) ??
           '',
       mobile =
           json['mobile']?.toString() ??
           (json['agent_profile'] is Map
               ? json['agent_profile']['agent_mobile']?.toString()
               : null) ??
           '',
       mobileCountryCode =
           json['country_code']?.toString() ??
           json['agent_country_code']?.toString() ??
           (json['agent_profile'] is Map
               ? json['agent_profile']['agent_country_code']?.toString()
               : null),
       projectsCount = json['total_projects']?.toString() ?? '0',
       propertyCount = json['total_properties']?.toString() ?? '0',
       isAdmin = _parseBool(json['is_admin']),
       isAgentVerified = _parseBool(json['is_agent_verified']),
       isAppointmentAvailable = _parseBool(json['is_appointment_available']),
       hasAppointmentInfo = json.containsKey('is_appointment_available'),
       banner =
           json['agent_banner']?.toString() ??
           json['banner']?.toString() ??
           (json['agent_profile'] is Map
               ? json['agent_profile']['agent_banner']?.toString()
               : null),
       followersCount =
           json['followers_count']?.toString() ??
           (json['agent_profile'] is Map
               ? json['agent_profile']['followers_count']?.toString()
               : null) ??
           '0',
       isFollowing = _parseBool(
         json['is_following'],
         defaultValue: defaultIsFollowing,
       );

  final int id;
  final String name;
  final String profile;
  final String email;
  final String projectsCount;
  final String propertyCount;
  final String mobile;
  final String? mobileCountryCode;
  final bool isAdmin;
  final bool isAgentVerified;
  final String? followersCount;
  final String? banner;
  final bool isFollowing;
  final bool isAppointmentAvailable;

  /// False when the source API (e.g. agent-list) didn't send
  /// `is_appointment_available`, so [isAppointmentAvailable] is only a default.
  final bool hasAppointmentInfo;

  AgentModel copywith({
    int? id,
    String? name,
    String? profile,
    String? email,
    String? projectsCount,
    String? propertyCount,
    String? mobile,
    String? mobileCountryCode,
    bool? isAdmin,
    bool? isUserVerified,
    bool? isAgentVerified,
    bool? isAgent,
    String? followersCount,
    String? banner,
    bool? isFollowing,
    bool? isAppointmentAvailable,
    bool? hasAppointmentInfo,
  }) => AgentModel(
    id: id ?? this.id,
    name: name ?? this.name,
    profile: profile ?? this.profile,
    email: email ?? this.email,
    projectsCount: projectsCount ?? this.projectsCount,
    propertyCount: propertyCount ?? this.propertyCount,
    mobile: mobile ?? this.mobile,
    mobileCountryCode: mobileCountryCode ?? this.mobileCountryCode,
    isAdmin: isAdmin ?? this.isAdmin,
    isAgentVerified: isAgentVerified ?? this.isAgentVerified,
    followersCount: followersCount ?? this.followersCount,
    banner: banner ?? this.banner,
    isFollowing: isFollowing ?? this.isFollowing,
    isAppointmentAvailable:
        isAppointmentAvailable ?? this.isAppointmentAvailable,
    hasAppointmentInfo:
        hasAppointmentInfo ??
        (isAppointmentAvailable != null || this.hasAppointmentInfo),
  );
}
