class AgentDashboardListingsModel {
  AgentDashboardListingsModel({
    required this.overall,
    required this.rangeWise,
  });

  factory AgentDashboardListingsModel.fromJson(Map<String, dynamic> json) {
    return AgentDashboardListingsModel(
      overall: AgentDashboardListingsOverall.fromJson(
        json['overall'] as Map<String, dynamic>? ?? {},
      ),
      rangeWise: (json['range_wise'] as List? ?? [])
          .map(
            (e) => AgentDashboardListingsEntry.fromJson(
              e as Map<String, dynamic>? ?? {},
            ),
          )
          .toList(),
    );
  }

  final AgentDashboardListingsOverall overall;
  final List<AgentDashboardListingsEntry> rangeWise;
}

class AgentDashboardListingsOverall {
  AgentDashboardListingsOverall({
    required this.totalProperties,
    required this.sellProperties,
    required this.rentProperties,
  });

  factory AgentDashboardListingsOverall.fromJson(Map<String, dynamic> json) {
    return AgentDashboardListingsOverall(
      totalProperties:
          int.tryParse(
            json['total_properties']?.toString() ??
                json['total_projects']?.toString() ??
                '0',
          ) ??
          0,
      sellProperties:
          int.tryParse(
            json['sell_properties']?.toString() ??
                json['upcoming_projects']?.toString() ??
                '0',
          ) ??
          0,
      rentProperties:
          int.tryParse(
            json['rent_properties']?.toString() ??
                json['under_construction_projects']?.toString() ??
                '0',
          ) ??
          0,
    );
  }

  final int totalProperties;
  final int sellProperties;
  final int rentProperties;
}

class AgentDashboardListingsEntry {
  AgentDashboardListingsEntry({
    required this.month,
    required this.monthKey,
    required this.date,
    required this.dayName,
    required this.totalProperties,
    required this.sellProperties,
    required this.rentProperties,
  });

  factory AgentDashboardListingsEntry.fromJson(Map<String, dynamic> json) {
    return AgentDashboardListingsEntry(
      month: json['month']?.toString() ?? '',
      monthKey: json['month_key']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      dayName: json['day_name']?.toString() ?? '',
      totalProperties:
          int.tryParse(
            json['total_properties']?.toString() ??
                json['total_projects']?.toString() ??
                '0',
          ) ??
          0,
      sellProperties:
          int.tryParse(
            json['sell_properties']?.toString() ??
                json['upcoming_projects']?.toString() ??
                '0',
          ) ??
          0,
      rentProperties:
          int.tryParse(
            json['rent_properties']?.toString() ??
                json['under_construction_projects']?.toString() ??
                '0',
          ) ??
          0,
    );
  }

  final String month;
  final String monthKey;
  final String date;
  final String dayName;
  final int totalProperties;
  final int sellProperties;
  final int rentProperties;
}
