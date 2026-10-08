class CustomPageModel {
  CustomPageModel({
    this.id,
    this.title,
    this.translatedTitle,
    this.icon,
    this.content,
    this.translatedContent,
  });

  CustomPageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    title = json['title']?.toString() ?? '';
    translatedTitle = json['translated_title']?.toString() ?? '';
    icon = json['icon']?.toString() ?? '';
    content = json['content']?.toString() ?? '';
    translatedContent = json['translated_content']?.toString() ?? '';
  }

  int? id;
  String? title;
  String? translatedTitle;
  String? icon;
  String? content;
  String? translatedContent;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'translated_title': translatedTitle,
      'icon': icon,
      'content': content,
      'translated_content': translatedContent,
    };
  }

  String get displayTitle => translatedTitle ?? title ?? '';

  String get displayContent => translatedContent ?? content ?? '';
}
