import 'package:ebroker/data/model/project_model.dart';

class ProjectSectionsModel {
  ProjectSectionsModel({
    required this.projects,
    required this.featuredProjects,
    required this.premiumProjects,
    required this.curatedProjects,
    required this.locationBasedData,
    this.projectsSectionId,
    this.featuredProjectsSectionId,
    this.premiumProjectsSectionId,
    this.curatedProjectsSectionId,
  });

  factory ProjectSectionsModel.fromApiResponse(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};

    final projects = _parseSectionList<ProjectModel>(
      data['projects'],
      ProjectModel.fromMap,
    );
    final featured = _parseSectionList<ProjectModel>(
      data['featured_projects'],
      ProjectModel.fromMap,
    );
    final premium = _parseSectionList<ProjectModel>(
      data['premium_projects'],
      ProjectModel.fromMap,
    );
    final curated = _parseSectionList<ProjectModel>(
      data['curated_projects'],
      ProjectModel.fromMap,
    );

    return ProjectSectionsModel(
      projects: projects.items,
      featuredProjects: featured.items,
      premiumProjects: premium.items,
      curatedProjects: curated.items,
      locationBasedData: data['location_based_data'] as bool? ?? false,
      projectsSectionId: projects.sectionId,
      featuredProjectsSectionId: featured.sectionId,
      premiumProjectsSectionId: premium.sectionId,
      curatedProjectsSectionId: curated.sectionId,
    );
  }

  final List<ProjectModel> projects;
  final List<ProjectModel> featuredProjects;
  final List<ProjectModel> premiumProjects;
  final List<ProjectModel> curatedProjects;
  final bool locationBasedData;

  final int? projectsSectionId;
  final int? featuredProjectsSectionId;
  final int? premiumProjectsSectionId;
  final int? curatedProjectsSectionId;
}

({int? sectionId, List<T> items}) _parseSectionList<T>(
  dynamic node,
  T Function(Map<String, dynamic>) fromMap,
) {
  if (node is! Map) return (sectionId: null, items: <T>[]);
  final map = node.cast<String, dynamic>();
  final sectionId = map['section_id'] as int?;
  final list = (map['data'] as List? ?? const [])
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => fromMap(Map<String, dynamic>.from(e)))
      .toList();
  return (sectionId: sectionId, items: list);
}
