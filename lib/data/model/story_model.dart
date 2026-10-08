int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value == null) return null;
  return int.tryParse(value.toString());
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  return value?.toString() == 'true' || value?.toString() == '1';
}

class StoriesResponseModel {
  StoriesResponseModel({
    this.sectionTitle,
    this.isGuest = false,
    this.userHasPremiumPropertiesAccess = false,
    this.userHasPremiumProjectsAccess = false,
    this.agents = const [],
    this.pagination,
  });

  factory StoriesResponseModel.fromJson(Map<String, dynamic> json) {
    final agentsJson = json['agents'];
    return StoriesResponseModel(
      sectionTitle: json['section_title']?.toString(),
      isGuest: _parseBool(json['is_guest']),
      userHasPremiumPropertiesAccess: _parseBool(
        json['user_has_premium_properties_access'],
      ),
      userHasPremiumProjectsAccess: _parseBool(
        json['user_has_premium_projects_access'],
      ),
      agents: agentsJson is List
          ? agentsJson
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) => StoryAgentModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      pagination: json['pagination'] is Map
          ? StoriesPaginationModel.fromJson(
              Map<String, dynamic>.from(json['pagination'] as Map),
            )
          : null,
    );
  }

  final String? sectionTitle;
  final bool isGuest;
  final bool userHasPremiumPropertiesAccess;
  final bool userHasPremiumProjectsAccess;
  final List<StoryAgentModel> agents;
  final StoriesPaginationModel? pagination;
}

class StoryAgentModel {
  StoryAgentModel({
    this.agentId,
    this.agentSlug,
    this.agentName,
    this.agentProfileImage,
    this.agentMobile,
    this.agentCountryCode,
    this.isAdmin = false,
    this.isAgentVerified = false,
    this.hasUnseenStory = false,
    this.premiumStoryCount = 0,
    this.premiumStories = const [],
    this.nonPremiumStories = const [],
  });

  factory StoryAgentModel.fromJson(Map<String, dynamic> json) {
    List<StoryItemModel> parseStories(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => StoryItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return StoryAgentModel(
      agentId: _parseInt(json['agent_id']),
      agentSlug: json['agent_slug_id']?.toString(),
      agentName: json['agent_name']?.toString(),
      agentProfileImage: json['agent_profile_image']?.toString(),
      agentMobile: json['agent_mobile']?.toString(),
      agentCountryCode: json['agent_country_code']?.toString(),
      isAdmin: _parseBool(json['is_admin']),
      isAgentVerified: _parseBool(json['is_agent_verified']),
      hasUnseenStory: _parseBool(json['has_unseen_story']),
      premiumStoryCount: _parseInt(json['premium_story_count']) ?? 0,
      premiumStories: parseStories(json['premium_stories']),
      nonPremiumStories: parseStories(json['non_premium_stories']),
    );
  }

  final int? agentId;
  final String? agentSlug;
  final String? agentName;
  final String? agentProfileImage;
  final String? agentMobile;
  final String? agentCountryCode;
  final bool isAdmin;
  final bool isAgentVerified;
  final bool hasUnseenStory;
  final int premiumStoryCount;
  final List<StoryItemModel> premiumStories;
  final List<StoryItemModel> nonPremiumStories;

  /// Non-premium + premium stories combined, oldest first — the canonical
  /// display order used by both the home-row preview and the full-screen
  /// viewer, so what a user taps is what they see first. If the API withheld
  /// premium content (empty [premiumStories] but [premiumStoryCount] > 0,
  /// meaning the viewer lacks premium access), a synthetic teaser card is
  /// appended so the viewer can prompt to upgrade instead of showing nothing.
  List<StoryItemModel> get orderedStories {
    final combined = [...nonPremiumStories, ...premiumStories]
      ..sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
    if (premiumStories.isEmpty && premiumStoryCount > 0) {
      combined.add(
        StoryItemModel(
          storyId: 'premium_teaser_$agentId',
          isPremiumTeaser: true,
          durationSeconds: 6,
        ),
      );
    }
    return combined;
  }
}

class StoryItemModel {
  StoryItemModel({
    this.storyId,
    this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.createdAt,
    this.expiresAt,
    this.viewCount,
    this.isPremium = false,
    this.isSeen = false,
    this.isActive,
    this.linkedEntity,
    this.isPremiumTeaser = false,
  });

  factory StoryItemModel.fromJson(Map<String, dynamic> json) {
    return StoryItemModel(
      storyId: json['story_id']?.toString(),
      mediaType: json['media_type']?.toString(),
      mediaUrl: json['media_url']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      durationSeconds: _parseInt(json['duration_seconds']),
      createdAt: json['created_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      viewCount: _parseInt(json['view_count']),
      isPremium: _parseBool(json['is_premium']),
      isSeen: _parseBool(json['is_seen']),
      isActive: json.containsKey('is_active')
          ? _parseBool(json['is_active'])
          : null,
      linkedEntity: json['linked_entity'] is Map
          ? StoryLinkedEntityModel.fromJson(
              Map<String, dynamic>.from(json['linked_entity'] as Map),
            )
          : null,
    );
  }

  final String? storyId;
  final String? mediaType;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? createdAt;
  final String? expiresAt;
  final int? viewCount;
  final bool isPremium;
  final bool isSeen;
  final bool? isActive;
  final StoryLinkedEntityModel? linkedEntity;

  /// True for the synthetic end-of-agent card shown when the API withheld
  /// premium stories (viewer lacks access) rather than an actual story.
  final bool isPremiumTeaser;
}

class StoryLinkedEntityModel {
  StoryLinkedEntityModel({
    this.type,
    this.id,
    this.slug,
    this.title,
    this.image,
    this.price,
    this.city,
    this.address,
    this.propertyType,
    this.isPremium = false,
  });

  factory StoryLinkedEntityModel.fromJson(Map<String, dynamic> json) {
    return StoryLinkedEntityModel(
      type: json['type']?.toString(),
      id: _parseInt(json['id']),
      slug: json['slug']?.toString(),
      title: json['title']?.toString(),
      image: json['image']?.toString(),
      price: json['price']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      propertyType: json['property_type']?.toString(),
      isPremium: _parseBool(json['is_premium']),
    );
  }

  final String? type;
  final int? id;
  final String? slug;
  final String? title;
  final String? image;
  final String? price;
  final String? city;
  final String? address;
  final String? propertyType;
  final bool isPremium;
}

class StoriesPaginationModel {
  StoriesPaginationModel({
    this.limit,
    this.offset,
    this.total,
    this.hasMore = false,
  });

  factory StoriesPaginationModel.fromJson(Map<String, dynamic> json) {
    return StoriesPaginationModel(
      limit: _parseInt(json['limit']),
      offset: _parseInt(json['offset']),
      total: _parseInt(json['total']),
      hasMore: _parseBool(json['has_more']),
    );
  }

  final int? limit;
  final int? offset;
  final int? total;
  final bool hasMore;
}

class MyStoriesResponseModel {
  MyStoriesResponseModel({
    this.premiumStories = const [],
    this.nonPremiumStories = const [],
  });

  factory MyStoriesResponseModel.fromJson(Map<String, dynamic> json) {
    List<StoryItemModel> parseStories(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => StoryItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return MyStoriesResponseModel(
      premiumStories: parseStories(json['premium_stories']),
      nonPremiumStories: parseStories(json['non_premium_stories']),
    );
  }

  final List<StoryItemModel> premiumStories;
  final List<StoryItemModel> nonPremiumStories;
}
