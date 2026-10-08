class AgentDashboardSummaryModel {
  AgentDashboardSummaryModel({
    required this.properties,
    required this.projects,
    required this.propertiesViews,
    required this.appointments,
    required this.chats,
  });

  factory AgentDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return AgentDashboardSummaryModel(
      properties: AgentDashboardPropertiesStats.fromJson(
        json['properties'] as Map<String, dynamic>? ?? {},
      ),
      projects: AgentDashboardProjectsStats.fromJson(
        json['projects'] as Map<String, dynamic>? ?? {},
      ),
      propertiesViews: AgentDashboardViewsStats.fromJson(
        json['properties_views'] as Map<String, dynamic>? ?? {},
      ),
      appointments: AgentDashboardAppointmentsStats.fromJson(
        json['appointments'] as Map<String, dynamic>? ?? {},
      ),
      chats: (json['chats'] as List? ?? [])
          .map(
            (e) => AgentDashboardChat.fromJson(
              e as Map<String, dynamic>? ?? {},
            ),
          )
          .toList(),
    );
  }

  final AgentDashboardPropertiesStats properties;
  final AgentDashboardProjectsStats projects;
  final AgentDashboardViewsStats propertiesViews;
  final AgentDashboardAppointmentsStats appointments;
  final List<AgentDashboardChat> chats;
}

class AgentDashboardMonthlyEntry {
  AgentDashboardMonthlyEntry({
    required this.month,
    required this.monthKey,
    required this.count,
  });

  factory AgentDashboardMonthlyEntry.fromJson(
    Map<String, dynamic> json,
    String countKey,
  ) {
    return AgentDashboardMonthlyEntry(
      month: json['month']?.toString() ?? '',
      monthKey: json['month_key']?.toString() ?? '',
      count: int.tryParse(json[countKey]?.toString() ?? '0') ?? 0,
    );
  }

  final String month;
  final String monthKey;
  final int count;
}

class AgentDashboardPropertiesStats {
  AgentDashboardPropertiesStats({
    required this.totalProperties,
    required this.currentMonthPropertyCount,
    required this.monthlyPropertyCounts,
  });

  factory AgentDashboardPropertiesStats.fromJson(Map<String, dynamic> json) {
    return AgentDashboardPropertiesStats(
      totalProperties:
          int.tryParse(json['total_properties']?.toString() ?? '0') ?? 0,
      currentMonthPropertyCount:
          int.tryParse(
            json['current_month_property_count']?.toString() ?? '0',
          ) ??
          0,
      monthlyPropertyCounts: (json['monthly_property_counts'] as List? ?? [])
          .map(
            (e) => AgentDashboardMonthlyEntry.fromJson(
              e as Map<String, dynamic>? ?? {},
              'total_properties',
            ),
          )
          .toList(),
    );
  }

  final int totalProperties;
  final int currentMonthPropertyCount;
  final List<AgentDashboardMonthlyEntry> monthlyPropertyCounts;
}

class AgentDashboardProjectsStats {
  AgentDashboardProjectsStats({
    required this.totalProjects,
    required this.currentMonthProjectCount,
    required this.monthlyProjectCounts,
  });

  factory AgentDashboardProjectsStats.fromJson(Map<String, dynamic> json) {
    return AgentDashboardProjectsStats(
      totalProjects:
          int.tryParse(json['total_projects']?.toString() ?? '0') ?? 0,
      currentMonthProjectCount:
          int.tryParse(
            json['current_month_project_count']?.toString() ?? '0',
          ) ??
          0,
      monthlyProjectCounts: (json['monthly_project_counts'] as List? ?? [])
          .map(
            (e) => AgentDashboardMonthlyEntry.fromJson(
              e as Map<String, dynamic>? ?? {},
              'total_projects',
            ),
          )
          .toList(),
    );
  }

  final int totalProjects;
  final int currentMonthProjectCount;
  final List<AgentDashboardMonthlyEntry> monthlyProjectCounts;
}

class AgentDashboardViewsStats {
  AgentDashboardViewsStats({
    required this.totalViews,
    required this.currentMonthPropertyViews,
    required this.monthlyPropertyViews,
  });

  factory AgentDashboardViewsStats.fromJson(Map<String, dynamic> json) {
    return AgentDashboardViewsStats(
      totalViews: int.tryParse(json['total_views']?.toString() ?? '0') ?? 0,
      currentMonthPropertyViews:
          int.tryParse(
            json['current_month_property_views']?.toString() ?? '0',
          ) ??
          0,
      monthlyPropertyViews: (json['monthly_property_views'] as List? ?? [])
          .map(
            (e) => AgentDashboardMonthlyEntry.fromJson(
              e as Map<String, dynamic>? ?? {},
              'total_views',
            ),
          )
          .toList(),
    );
  }

  final int totalViews;
  final int currentMonthPropertyViews;
  final List<AgentDashboardMonthlyEntry> monthlyPropertyViews;
}

class AgentDashboardAppointmentsStats {
  AgentDashboardAppointmentsStats({
    required this.currentMonthCount,
    required this.todayCount,
    required this.monthlyAppointmentCounts,
  });

  factory AgentDashboardAppointmentsStats.fromJson(
    Map<String, dynamic> json,
  ) {
    return AgentDashboardAppointmentsStats(
      currentMonthCount:
          int.tryParse(
            json['current_month_appointment_count']?.toString() ?? '0',
          ) ??
          0,
      todayCount:
          int.tryParse(
            json['today_appointment_count']?.toString() ?? '0',
          ) ??
          0,
      monthlyAppointmentCounts:
          (json['monthly_appointment_counts'] as List? ?? [])
              .map(
                (e) => AgentDashboardMonthlyEntry.fromJson(
                  e as Map<String, dynamic>? ?? {},
                  'total_appointments',
                ),
              )
              .toList(),
    );
  }

  final int currentMonthCount;
  final int todayCount;
  final List<AgentDashboardMonthlyEntry> monthlyAppointmentCounts;
}

class AgentDashboardChat {
  AgentDashboardChat({
    required this.id,
    required this.otherUserName,
    required this.otherUserProfile,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.propertyTitle,
    required this.propertyTitleImage,
  });

  factory AgentDashboardChat.fromJson(Map<String, dynamic> json) {
    final otherUser = json['other_user'] as Map<String, dynamic>? ?? {};
    final property = json['property'] as Map<String, dynamic>? ?? {};

    return AgentDashboardChat(
      id: json['id'] as int? ?? 0,
      otherUserName: otherUser['name']?.toString() ?? '',
      otherUserProfile: otherUser['profile']?.toString() ?? '',
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageTime: json['last_message_time']?.toString() ?? '',
      propertyTitle: property['title']?.toString() ?? '',
      propertyTitleImage: property['title_image']?.toString() ?? '',
    );
  }

  final int id;
  final String otherUserName;
  final String otherUserProfile;
  final String lastMessage;
  final String lastMessageTime;
  final String propertyTitle;
  final String propertyTitleImage;
}
