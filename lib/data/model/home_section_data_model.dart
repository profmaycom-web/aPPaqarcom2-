import 'package:ebroker/data/model/home_page_data_model.dart';

/// Parses `/api/homepage/sections-data` response.
///
/// Backend shape may vary slightly across deployments; this model is tolerant:
/// - Accepts `sections` or `data` as the list node.
class HomeSectionDataModel {
  HomeSectionDataModel({
    required this.sections,
    this.sliderSection = true,
    this.searchSection = true,
    this.allPropertiesSection = true,
  });

  factory HomeSectionDataModel.fromApiResponse(Map<String, dynamic> json) {
    final dynamic dataNode = json['data'];
    // Some backends might return `sections` at root; some nest it under `data`.
    // In the new API structure, the sections list is under `data['section_data']`.
    final dynamic sectionsNode =
        (dataNode is Map<String, dynamic>
            ? (dataNode['section_data'] ?? dataNode['sections'] ?? dataNode)
            : null) ??
        json['sections'] ??
        json['data'];

    final rawList = (sectionsNode is List)
        ? sectionsNode
        : (sectionsNode is Map<String, dynamic> &&
              sectionsNode['sections'] is List)
        ? sectionsNode['sections'] as List
        : const <dynamic>[];

    final sections = rawList
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => HomePageSection.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final isDataMap = dataNode is Map<String, dynamic>;
    final sliderSection =
        ((isDataMap ? dataNode['slider_section'] : null) as bool?) ??
        (json['slider_section'] as bool?) ??
        true;
    final searchSection =
        ((isDataMap ? dataNode['search_section'] : null) as bool?) ??
        (json['search_section'] as bool?) ??
        true;
    final allPropertiesSection =
        ((isDataMap ? dataNode['all_properties_section'] : null) as bool?) ??
        (json['all_properties_section'] as bool?) ??
        true;

    return HomeSectionDataModel(
      sections: sections,
      sliderSection: sliderSection,
      searchSection: searchSection,
      allPropertiesSection: allPropertiesSection,
    );
  }

  final List<HomePageSection> sections;
  final bool sliderSection;
  final bool searchSection;
  final bool allPropertiesSection;
}
