class SocialMediaLinkModel {
  SocialMediaLinkModel({
    required this.id,
    required this.name,
    required this.icon,
    this.url,
  });

  factory SocialMediaLinkModel.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = Map<String, dynamic>.from(rawJson);
    return SocialMediaLinkModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name:
          json['name']?.toString() ??
          json['title']?.toString() ??
          json['platform']?.toString() ??
          json['social_name']?.toString() ??
          '',
      icon:
          json['icon']?.toString() ??
          json['image']?.toString() ??
          json['icon_url']?.toString() ??
          '',
      url:
          json['url']?.toString() ??
          json['link']?.toString() ??
          json['social_url']?.toString() ??
          json['value']?.toString(),
    );
  }

  final int id;
  final String name;
  final String icon;
  final String? url;

  SocialMediaLinkModel copyWith({
    int? id,
    String? name,
    String? icon,
    String? url,
  }) {
    return SocialMediaLinkModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      if (url != null) 'url': url,
    };
  }
}
