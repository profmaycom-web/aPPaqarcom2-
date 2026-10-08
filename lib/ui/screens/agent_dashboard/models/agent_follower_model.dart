class AgentFollowerModel {
  const AgentFollowerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profile,
    required this.slugId,
  });

  factory AgentFollowerModel.fromJson(Map<String, dynamic> json) {
    return AgentFollowerModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profile: json['profile']?.toString() ?? '',
      slugId: json['slug_id']?.toString() ?? '',
    );
  }

  final int id;
  final String name;
  final String email;
  final String profile;
  final String slugId;
}
