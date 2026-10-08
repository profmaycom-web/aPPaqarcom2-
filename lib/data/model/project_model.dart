import 'dart:convert';

import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/data/model/translation_model.dart';

bool _parseBool(dynamic val, {bool defaultValue = false}) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) {
    return val == '1' || val.toLowerCase() == 'true';
  }
  return defaultValue;
}

class ProjectModel {
  ProjectModel({
    this.id,
    this.slugId,
    this.categoryId,
    this.title,
    this.description,
    this.translatedTitle,
    this.translatedDescription,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    this.metaImage,
    this.image,
    this.lowQualityImage,
    this.videoLink,
    this.videoType,
    this.location,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.countryId,
    this.type,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.addedBy,
    this.customer,
    this.gallaryImages,
    this.documents,
    this.plans,
    this.category,
    this.requestStatus,
    this.isPromoted,
    this.isFeatureAvailable,
    this.rejectReason,
    this.editReason,
    this.translations,
    this.isPremium,
    this.expiryDate,
    this.isExpired,
    this.isAdmin,
    this.isUserVerified,
    this.isAgentVerified,
    this.isAgent,
    this.agentProfile,
    this.totalProperties,
    this.totalProjects,
    this.roleContext,
    this.isAppointmentAvailable,
    this.contactNumber,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as int?,
      slugId: map['slug_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      translatedTitle: map['translated_title']?.toString() ?? '',
      translatedDescription: map['translated_description']?.toString() ?? '',
      metaTitle: map['meta_title']?.toString() ?? '',
      metaDescription: map['meta_description']?.toString() ?? '',
      metaKeywords: map['meta_keywords']?.toString() ?? '',
      metaImage: map['meta_image']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      lowQualityImage: map['low_quality_image']?.toString(),
      videoLink: map['video_link']?.toString() ?? '',
      videoType: int.tryParse(map['video_type']?.toString() ?? '') ?? 1,
      location: map['location']?.toString() ?? '',
      latitude: map['latitude']?.toString() ?? '',
      longitude: map['longitude']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      country: map['country']?.toString() ?? '',
      countryId: map['country_id'] != null
          ? int.tryParse(map['country_id'].toString())
          : null,
      type: map['type']?.toString() ?? '',
      status: map['status']?.toString() ?? '0',
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      addedBy: map['added_by']?.toString() ?? '',
      customer: Customer.fromMap(
        map['customer'] as Map<String, dynamic>? ?? {},
      ),
      gallaryImages: (map['gallary_images'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map<ProjectGalleryModel>(ProjectGalleryModel.fromMap)
          .toList(),
      documents: (map['documents'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map<Document>(Document.fromMap)
          .toList(),
      plans: (map['plans'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map<Plan>(Plan.fromMap)
          .toList(),
      category: ProjectCategory.fromMap(
        map['category'] as Map<String, dynamic>? ?? {},
      ),
      requestStatus: map['request_status'] as String? ?? '',
      isPromoted: map['is_promoted'] as bool? ?? false,
      isFeatureAvailable: map['is_feature_available'] as bool? ?? false,
      rejectReason: map['reject_reason'] == null
          ? null
          : RejectReason.fromMap(
              map['reject_reason'] as Map<String, dynamic>,
            ),
      editReason: map['edit_reason']?.toString(),
      translations: List<Translations>.from(
        (map['translations'] as List? ?? []).map((x) {
          return Translations.fromJson(x as Map<String, dynamic>? ?? {});
        }),
      ),
      isPremium: _parseBool(map['is_premium']),
      expiryDate: map['expiry_date']?.toString(),
      isExpired: (map['is_expired'] as int? ?? 0) == 1,
      isAdmin: _parseBool(map['is_admin_listing'] ?? map['is_admin']) ||
          (map['added_by']?.toString() == '0'),
      isUserVerified: _parseBool(map['is_user_verified']),
      isAgentVerified: _parseBool(map['is_agent_verified']),
      isAgent: _parseBool(map['is_agent']),
      agentProfile: _parseAgentProfile(map),
      totalProperties: map['total_properties']?.toString() ?? '',
      totalProjects: map['total_projects']?.toString() ?? '',
      roleContext: map['role_context']?.toString() ?? 'user',
      isAppointmentAvailable: _parseBool(
        map['is_appointment_available'] ??
            (map['customer'] is Map
                ? (map['customer'] as Map)['is_appointment_available']
                : null),
      ),
      contactNumber: map['mobile']?.toString() ??
          map['contact']?.toString() ??
          map['phone']?.toString() ??
          (map['customer'] is Map
              ? (map['customer'] as Map)['mobile']?.toString()
              : null),
    );
  }

  static AgentProfileModel? _parseAgentProfile(Map<String, dynamic> map) {
    // API may return agent_profile at top level or nested inside customer
    final topLevel = map['agent_profile'];
    final customer = map['customer'] as Map<String, dynamic>?;
    AgentProfileModel? profile;
    if (topLevel is Map<String, dynamic>) {
      profile = AgentProfileModel.fromMap(topLevel);
    } else if (customer?['agent_profile'] is Map<String, dynamic>) {
      profile = AgentProfileModel.fromMap(
        customer!['agent_profile'] as Map<String, dynamic>,
      );
    }
    if (profile != null) {
      if (profile.totalFollowers == null || profile.totalFollowers!.isEmpty) {
        final fallbackFollowers =
            map['follower_count']?.toString() ??
            map['followers_count']?.toString() ??
            map['total_followers']?.toString() ??
            customer?['follower_count']?.toString() ??
            customer?['followers_count']?.toString() ??
            customer?['total_followers']?.toString();

        if (fallbackFollowers != null && fallbackFollowers.isNotEmpty) {
          profile = profile.copyWith(totalFollowers: fallbackFollowers);
        }
      }
      return profile;
    }
    return null;
  }

  int? id;
  String? slugId;
  String? categoryId;
  String? title;
  String? description;
  String? translatedTitle;
  String? translatedDescription;
  String? metaTitle;
  String? metaDescription;
  String? metaKeywords;
  String? metaImage;
  String? image;
  String? lowQualityImage;
  String? videoLink;
  int? videoType;
  String? location;
  String? latitude;
  String? longitude;
  String? city;
  String? state;
  String? country;
  int? countryId;
  String? type;
  String? status;
  String? createdAt;
  String? updatedAt;
  String? addedBy;
  Customer? customer;
  List<ProjectGalleryModel>? gallaryImages;
  List<Document>? documents;
  List<Plan>? plans;
  ProjectCategory? category;
  String? requestStatus;
  bool? isFeatureAvailable;
  bool? isPromoted;
  bool? isPremium;
  RejectReason? rejectReason;
  String? editReason;
  final List<Translations>? translations;
  String? expiryDate;
  bool? isExpired;
  bool? isAdmin;
  bool? isUserVerified;
  bool? isAgentVerified;
  bool? isAgent;
  AgentProfileModel? agentProfile;
  String? totalProperties;
  String? totalProjects;
  String? roleContext;
  bool? isAppointmentAvailable;
  String? contactNumber;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slug_id': slugId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'translated_title': translatedTitle,
      'translated_description': translatedDescription,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'meta_keywords': metaKeywords,
      'meta_image': metaImage,
      'image': image,
      'low_quality_image': lowQualityImage,
      'video_link': videoLink,
      'video_type': videoType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'country_id': countryId,
      'type': type,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'added_by': addedBy,
      'customer': customer?.toMap(),
      'gallary_images': gallaryImages?.map((e) => e.toMap()).toList(),
      'documents': documents?.map((x) => x.toMap()).toList(),
      'plans': plans?.map((x) => x.toMap()).toList(),
      'category': category?.toMap(),
      'request_status': requestStatus,
      'is_feature_available': isFeatureAvailable,
      'is_promoted': isPromoted,
      'reject_reason': rejectReason,
      'edit_reason': editReason,
      'translations': translations,
      'is_premium': isPremium,
      'expiry_date': expiryDate,
      'is_expired': (isExpired ?? false) ? 1 : 0,
      'is_admin_listing': isAdmin,
      'is_user_verified': isUserVerified,
      'is_agent_verified': isAgentVerified,
      'is_agent': isAgent,
      'agent_profile': agentProfile?.toMap(),
      'total_properties': totalProperties,
      'total_projects': totalProjects,
      'role_context': roleContext,
      'is_appointment_available': isAppointmentAvailable,
      'mobile': contactNumber,
    };
  }

  @override
  String toString() {
    return '''ProjectModel(id: $id, slugId: $slugId, categoryId: $categoryId, title: $title, description: $description, translatedTitle: $translatedTitle, translatedDescription: $translatedDescription metaTitle: $metaTitle, metaDescription: $metaDescription, metaKeywords: $metaKeywords, metaImage: $metaImage, image: $image, videoLink: $videoLink, location: $location, latitude: $latitude, longitude: $longitude, city: $city, state: $state, country: $country, type: $type, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, addedBy: $addedBy, customer: $customer, gallaryImages: $gallaryImages, documents: $documents, plans: $plans, category: $category, requestStatus: $requestStatus), isPromoted: $isPromoted, isFeatureAvailable: $isFeatureAvailable, rejectReason: $rejectReason, translations: $translations, isPremium: $isPremium, agentProfile: $agentProfile, roleContext: $roleContext)''';
  }
}

class Customer {
  Customer({
    this.id,
    this.name,
    this.profile,
    this.email,
    this.mobile,
    this.isVerified,
    this.totalProperties,
    this.totalProjects,
    this.isAdmin,
    this.totalFollowers,
    this.isFollowing = false,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      profile: map['profile']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      mobile: map['mobile']?.toString() ?? '',
      isVerified: _parseBool(map['is_user_verified']),
      totalProperties: map['total_properties']?.toString() ?? '',
      totalProjects: map['total_projects']?.toString() ?? '',
      isAdmin: _parseBool(map['is_admin']),
      totalFollowers:
          map['total_followers']?.toString() ??
          map['followers_count']?.toString() ??
          map['follower_count']?.toString() ??
          map['followers']?.toString() ??
          (map['agent_profile'] is Map
              ? (map['agent_profile']['total_followers']?.toString() ??
                    map['agent_profile']['followers_count']?.toString() ??
                    map['agent_profile']['followers']?.toString())
              : null),
      isFollowing: _parseBool(map['is_following']),
    );
  }
  int? id;
  String? name;
  String? profile;
  String? email;
  String? mobile;
  bool? isVerified;
  String? totalProperties;
  String? totalProjects;
  bool? isAdmin;
  String? totalFollowers;
  bool? isFollowing;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profile': profile,
      'email': email,
      'mobile': mobile,
      'is_user_verified': isVerified,
      'total_properties': totalProperties,
      'total_projects': totalProjects,
      'is_admin': isAdmin,
      'total_followers': totalFollowers,
      'is_following': isFollowing,
    };
  }
}

class Document {
  Document({
    this.id,
    this.name,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.projectId,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
    );
  }
  int? id;
  String? name;
  String? type;
  String? createdAt;
  String? updatedAt;
  String? projectId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'project_id': projectId,
    };
  }
}

class Plan {
  Plan({
    this.id,
    this.title,
    this.document,
    this.createdAt,
    this.updatedAt,
    this.projectId,
  });

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'] as int?,
      title: map['title']?.toString() ?? '',
      document: map['document']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      projectId: map['project_id']?.toString() ?? '',
    );
  }
  int? id;
  String? title;
  String? document;
  String? createdAt;
  String? updatedAt;
  String? projectId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'document': document,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'project_id': projectId,
    };
  }
}

class ProjectCategory {
  ProjectCategory({
    this.id,
    this.category,
    this.image,
    this.translatedName,
  });

  factory ProjectCategory.fromMap(Map<String, dynamic> map) {
    return ProjectCategory(
      id: map['id'] as int?,
      category: map['category']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      translatedName: map['translated_name']?.toString() ?? '',
    );
  }
  final int? id;
  final String? category;
  final String? image;
  final String? translatedName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'image': image,
      'translated_name': translatedName,
    };
  }
}

class RejectReason {
  RejectReason({
    this.id,
    this.propertyId,
    this.projectId,
    this.reason,
  });

  factory RejectReason.fromJson(String str) =>
      RejectReason.fromMap(json.decode(str) as Map<String, dynamic>);

  factory RejectReason.fromMap(Map<String, dynamic> json) => RejectReason(
    id: json['id'] as int?,
    propertyId: json['property_id']?.toString(),
    projectId: json['project_id']?.toString(),
    reason: json['reason']?.toString(),
  );

  final int? id;
  final String? propertyId;
  final String? projectId;
  final String? reason;

  RejectReason copyWith({
    int? id,
    String? propertyId,
    String? projectId,
    String? reason,
  }) => RejectReason(
    id: id ?? this.id,
    propertyId: propertyId ?? this.propertyId,
    projectId: projectId ?? this.projectId,
    reason: reason ?? this.reason,
  );

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
    'id': id,
    'property_id': propertyId,
    'project_id': projectId,
    'reason': reason,
  };
}

class ProjectGalleryModel {
  const ProjectGalleryModel({
    required this.id,
    required this.imageUrl,
    required this.type,
    required this.isVideo,
  });

  factory ProjectGalleryModel.fromMap(Map<String, dynamic> map) {
    return ProjectGalleryModel(
      id: map['id'] as int,
      imageUrl: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      isVideo: map['is_video'] as bool? ?? false,
    );
  }

  factory ProjectGalleryModel.fromJson(String source) =>
      ProjectGalleryModel.fromMap(json.decode(source) as Map<String, dynamic>);
  final int id;
  final String imageUrl;
  final String type;
  final bool isVideo;
  ProjectGalleryModel copyWith({
    int? id,
    String? imageUrl,
    String? type,
    bool? isVideo,
  }) {
    return ProjectGalleryModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      isVideo: isVideo ?? this.isVideo,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': imageUrl,
      'type': type,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ProjectGalleryModel(id: $id, imageUrl: $imageUrl, type: $type)';
}
