class AgentDashboardMostViewedModel {
  AgentDashboardMostViewedModel({
    required this.id,
    required this.title,
    required this.views,
  });

  factory AgentDashboardMostViewedModel.fromJson(Map<String, dynamic> json) {
    return AgentDashboardMostViewedModel(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
    );
  }

  final int id;
  final String title;
  final int views;
}
