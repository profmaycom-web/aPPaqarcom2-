/// A property category option from `GET /agent-filter-options`; [id] is what
/// `agent-list` expects as `category_id`.
class AgentFilterCategoryOption {
  const AgentFilterCategoryOption({required this.id, required this.name});

  factory AgentFilterCategoryOption.fromJson(Map<String, dynamic> json) {
    return AgentFilterCategoryOption(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  final int id;
  final String name;
}

/// One section of `GET /agent-filter-options` (`options` + `total`), as
/// returned when a `field` or `offset`/`limit` is passed.
class AgentFilterOptionPage<T> {
  const AgentFilterOptionPage({this.options = const [], this.total = 0});

  final List<T> options;
  final int total;

  bool get hasMore => options.length < total;
}

/// Response of the public `GET /agent-filter-options` endpoint, most-used
/// values first. Parses both the no-param shape (plain top-10 lists) and the
/// `offset`/`limit` shape (`{options, total}` per section).
class AgentFilterOptionsModel {
  const AgentFilterOptionsModel({
    this.serviceAreas = const AgentFilterOptionPage(),
    this.languages = const AgentFilterOptionPage(),
    this.propertyCategories = const AgentFilterOptionPage(),
  });

  factory AgentFilterOptionsModel.fromJson(Map<String, dynamic> json) {
    return AgentFilterOptionsModel(
      serviceAreas: parsePage(json['service_areas'], parseString),
      languages: parsePage(json['languages'], parseString),
      propertyCategories: parsePage(
        json['property_categories'],
        parseCategory,
      ),
    );
  }

  final AgentFilterOptionPage<String> serviceAreas;
  final AgentFilterOptionPage<String> languages;
  final AgentFilterOptionPage<AgentFilterCategoryOption> propertyCategories;

  static String parseString(dynamic e) => e.toString();

  static AgentFilterCategoryOption parseCategory(dynamic e) =>
      AgentFilterCategoryOption.fromJson(Map.from(e as Map? ?? {}));

  /// Accepts either a plain list or an `{options, total}` map.
  static AgentFilterOptionPage<T> parsePage<T>(
    dynamic raw,
    T Function(dynamic) parse,
  ) {
    if (raw is List) {
      return AgentFilterOptionPage(
        options: raw.map(parse).toList(),
        total: raw.length,
      );
    }
    if (raw is Map) {
      final options = (raw['options'] as List? ?? []).map(parse).toList();
      return AgentFilterOptionPage(
        options: options,
        total: int.tryParse(raw['total']?.toString() ?? '') ?? options.length,
      );
    }
    return AgentFilterOptionPage<T>();
  }
}
