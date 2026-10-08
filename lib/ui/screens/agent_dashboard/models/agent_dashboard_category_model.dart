class AgentDashboardCategoryModel {
  AgentDashboardCategoryModel({
    required this.id,
    required this.title,
    required this.views,
  });

  factory AgentDashboardCategoryModel.fromJson(Map<String, dynamic> json) {
    return AgentDashboardCategoryModel(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
    );
  }

  final int id;
  final String title;
  final int views;
}
