import 'package:ebroker/data/model/agent/agents_properties_models/customer_data.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/project_data.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/properties_data.dart';
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

class AgentPropertyProjectModel implements NativeAdWidgetContainer {
  const AgentPropertyProjectModel({
    required this.customerData,
    required this.propertiesData,
    required this.projectData,
    required this.premiumPropertyCount,
    required this.isPackageAvailable,
    required this.isFeatureAvailable,
  });

  AgentPropertyProjectModel.fromJson(Map<String, dynamic> json)
    : projectData = (json['projects_data'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ProjectData.fromJson)
          .toList(),
      propertiesData = (json['properties_data'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PropertiesData.fromJson)
          .toList(),
      customerData = CustomerData.fromJson({
        ...?json['customer_data'] is Map
            ? Map<String, dynamic>.from(json['customer_data'] as Map)
            : null,
        if (json['agent_profile'] is Map)
          'agent_profile': json['agent_profile'],
        if (json['agent_details'] is Map)
          'agent_details': json['agent_details'],
        if (json['agent'] is Map)
          'agent': json['agent'],
        if (json['service_areas'] != null)
          'service_areas': json['service_areas'],
        if (json['service_area'] != null)
          'service_area': json['service_area'],
        if (json['languages'] != null)
          'languages': json['languages'],
        if (json['languages_spoken'] != null)
          'languages_spoken': json['languages_spoken'],
        if (json['experience'] != null)
          'experience': json['experience'],
        if (json['years_of_experience'] != null)
          'years_of_experience': json['years_of_experience'],
        if (json['start_time'] != null)
          'start_time': json['start_time'],
        if (json['working_hours_start'] != null)
          'working_hours_start': json['working_hours_start'],
        if (json['end_time'] != null)
          'end_time': json['end_time'],
        if (json['working_hours_end'] != null)
          'working_hours_end': json['working_hours_end'],
        if (json['social_media_links'] != null)
          'social_media_links': json['social_media_links'],
        if (json['social_media'] != null)
          'social_media': json['social_media'],
        if (json['social_links'] != null)
          'social_links': json['social_links'],
        if (json['about_me'] != null)
          'about_me': json['about_me'],
        if (json['verify_customer_values'] != null)
          'verify_customer_values': json['verify_customer_values'],
      }),
      premiumPropertyCount =
          json['premium_properties_count']?.toString() ?? '0',
      isPackageAvailable = _parseBool(json['package_available']),
      isFeatureAvailable = _parseBool(json['feature_available']);

  final List<ProjectData> projectData;
  final List<PropertiesData> propertiesData;
  final CustomerData customerData;
  final String premiumPropertyCount;
  final bool isPackageAvailable;
  final bool isFeatureAvailable;

  AgentPropertyProjectModel copyWith({
    List<ProjectData>? projectData,
    List<PropertiesData>? propertiesData,
    CustomerData? customerData,
    String? premiumPropertyCount,
    bool? isPackageAvailable,
    bool? isFeatureAvailable,
  }) {
    return AgentPropertyProjectModel(
      projectData: projectData ?? this.projectData,
      propertiesData: propertiesData ?? this.propertiesData,
      customerData: customerData ?? this.customerData,
      premiumPropertyCount: premiumPropertyCount ?? this.premiumPropertyCount,
      isPackageAvailable: isPackageAvailable ?? this.isPackageAvailable,
      isFeatureAvailable: isFeatureAvailable ?? this.isFeatureAvailable,
    );
  }
}
