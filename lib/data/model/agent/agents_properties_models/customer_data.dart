import 'package:ebroker/data/model/agent_profile_model.dart';
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

class CustomerData implements NativeAdWidgetContainer {
  const CustomerData({
    required this.id,
    required this.slugId,
    required this.name,
    required this.profile,
    required this.mobile,
    required this.email,
    required this.address,
    required this.city,
    required this.country,
    required this.state,
    required this.projectCount,
    required this.propertyCount,
    required this.propertiesSoldCount,
    required this.propertiesRentedCount,
    required this.isAppointmentAvailable,
    required this.isAgentVerified,
    required this.isAdmin,
    required this.agentProfile,
    this.followersCount,
    this.isFollowing = false,
  });

  CustomerData.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int? ?? 0,
      slugId = json['slug_id']?.toString() ?? '',
      name = json['name']?.toString() ?? '',
      profile = json['profile']?.toString() ?? '',
      mobile = json['mobile']?.toString() ?? '',
      email = json['email']?.toString() ?? '',
      address = json['address']?.toString() ?? '',
      city = json['city']?.toString() ?? '',
      country = json['country']?.toString() ?? '',
      state = json['state']?.toString() ?? '',
      projectCount = json['total_projects']?.toString() ?? '',
      propertyCount = json['total_properties']?.toString() ?? '',
      propertiesSoldCount = json['properties_sold_count']?.toString() ?? '',
      propertiesRentedCount = json['properties_rented_count']?.toString() ?? '',
      isAppointmentAvailable = _parseBool(json['is_appointment_available']),
      isAgentVerified = _parseBool(json['is_agent_verified']),
      agentProfile = AgentProfileModel.fromMap({
        ...json,
        if (json['agent_profile'] is Map)
          ...Map<String, dynamic>.from(json['agent_profile'] as Map),
        if (json['agent_details'] is Map)
          ...Map<String, dynamic>.from(json['agent_details'] as Map),
        if (json['agent'] is Map)
          ...Map<String, dynamic>.from(json['agent'] as Map),
        if (json['verification'] is Map)
          ...Map<String, dynamic>.from(json['verification'] as Map),
      }),
      isAdmin = _parseBool(json['is_admin']),
      followersCount =
          json['followers_count']?.toString() ??
          json['follower_count']?.toString() ??
          json['total_followers']?.toString() ??
          (json['agent_profile'] is Map
              ? (json['agent_profile']['followers_count']?.toString() ??
                    json['agent_profile']['follower_count']?.toString() ??
                    json['agent_profile']['total_followers']?.toString())
              : null) ??
          '0',
      isFollowing = _parseBool(json['is_following']);

  final int id;
  final String slugId;
  final String name;
  final String profile;
  final String mobile;
  final String email;
  final String address;
  final String city;
  final String country;
  final String state;
  final String projectCount;
  final String propertyCount;
  final String propertiesSoldCount;
  final String propertiesRentedCount;
  final bool isAppointmentAvailable;
  final bool isAgentVerified;
  final bool isAdmin;
  final AgentProfileModel agentProfile;
  final String? followersCount;
  final bool isFollowing;
}
