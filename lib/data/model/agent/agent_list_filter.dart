/// Filters supported by `GET /agent-list`. All are optional and ANDed by the
/// API (list fields match ANY of their values). Sent as a base64-encoded JSON
/// object under the `filters` query parameter; plain query params for these
/// fields are no longer accepted by the API.
class AgentListFilter {
  const AgentListFilter({
    this.search = '',
    this.serviceArea = const [],
    this.language = const [],
    this.isVerified = false,
    this.minExperience,
    this.propertyType,
    this.categoryIds = const [],
    this.categoryNames = const {},
  });

  final String search;

  /// Sent as an array, never a comma-joined string: the API matches a single
  /// string as one literal substring.
  final List<String> serviceArea;
  final List<String> language;
  final bool isVerified;
  final int? minExperience;

  /// 0 = sell, 1 = rent
  final int? propertyType;

  /// List of category ids from `agent-filter-options` `property_categories`.
  final List<int> categoryIds;

  /// Display names of [categoryIds] keyed by id so the filter sheet can show the selected
  /// chips even when they aren't in the loaded options page. Not sent to the API.
  final Map<int, String> categoryNames;

  /// First category id, for backwards compatibility.
  int? get categoryId => categoryIds.isNotEmpty ? categoryIds.first : null;

  /// First category name, for backwards compatibility.
  String? get categoryName =>
      categoryId != null ? categoryNames[categoryId!] : null;

  /// Number of filters set from the filter sheet (search excluded).
  int get activeCount => [
    serviceArea.isNotEmpty,
    language.isNotEmpty,
    isVerified,
    minExperience != null,
    propertyType != null,
    categoryIds.isNotEmpty,
  ].where((e) => e).length;

  bool get isEmpty => search.isEmpty && activeCount == 0;

  AgentListFilter copyWith({
    String? search,
    List<String>? serviceArea,
    List<String>? language,
    bool? isVerified,
    int? Function()? minExperience,
    int? Function()? propertyType,
    List<int>? categoryIds,
    Map<int, String>? categoryNames,
    int? Function()? categoryId,
    String? Function()? categoryName,
  }) {
    var resolvedCategoryIds = categoryIds;
    var resolvedCategoryNames = categoryNames;
    if (resolvedCategoryIds == null && categoryId != null) {
      final legacyId = categoryId();
      resolvedCategoryIds = legacyId != null ? [legacyId] : const [];
      final legacyName = categoryName != null ? categoryName() : null;
      resolvedCategoryNames = legacyId != null && legacyName != null
          ? {legacyId: legacyName}
          : const {};
    }

    return AgentListFilter(
      search: search ?? this.search,
      serviceArea: serviceArea ?? this.serviceArea,
      language: language ?? this.language,
      isVerified: isVerified ?? this.isVerified,
      minExperience: minExperience != null
          ? minExperience()
          : this.minExperience,
      propertyType: propertyType != null ? propertyType() : this.propertyType,
      categoryIds: resolvedCategoryIds ?? this.categoryIds,
      categoryNames: resolvedCategoryNames ?? this.categoryNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (search.isNotEmpty) 'search': search,
      if (serviceArea.isNotEmpty) 'service_area': serviceArea,
      if (language.isNotEmpty) 'language': language,
      if (isVerified) 'is_verified': true,
      if (minExperience != null) 'min_experience': minExperience,
      if (propertyType != null) 'property_type': propertyType,
      if (categoryIds.isNotEmpty) 'category_id': categoryIds,
    };
  }
}
