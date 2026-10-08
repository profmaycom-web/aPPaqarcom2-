bool _parseBool(dynamic val, {bool defaultValue = false}) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is String) {
    return val == '1' || val.toLowerCase() == 'true';
  }
  return defaultValue;
}

class UserModel {
  UserModel({
    this.address,
    this.createdAt,
    this.customertotalpost,
    this.email,
    this.fcmId,
    this.authId,
    this.id,
    this.isActive,
    this.isProfileCompleted,
    this.logintype,
    this.countryCode,
    this.mobile,
    this.name,
    this.notification,
    this.profile,
    this.token,
    this.updatedAt,
    this.instagram,
    this.facebook,
    this.youtube,
    this.twitter,
    this.isAgent,
    this.isUserVerified,
    this.isAppointmentAvailable,
    this.becomeAgentStatus,
    this.slugId,
    this.password,
    this.fullMobile,
    this.defaultLanguage,
    this.isAdminAdded,
    this.isEmailVerified,
    this.isAgentVerified,
    this.subscription,
    this.aboutMe,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.isPremium,
    this.agentProfile,
    this.agentVerificationStatus,
    this.userVerificationStatus,
    this.becomeAgentVerification,
    this.agentVerification,
    this.becomeAgentRejectReason,
    this.userVerificationRejectReason,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    address = json['address']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    customertotalpost = json['customertotalpost']?.toString();
    email = json['email']?.toString() ?? '';
    fcmId = json['fcm_id']?.toString() ?? '';
    authId = json['auth_id']?.toString() ?? '';
    isDemoUser = json['is_demo_user'] as bool? ?? false; // Added for demo user
    isActive = json['isActive']?.toString() ?? '0';
    isProfileCompleted = json['isProfileCompleted'] as bool?;
    logintype = json['logintype']?.toString() ?? '';
    countryCode = json['country_code']?.toString() ?? '';
    mobile = json['mobile']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
    notification = json['notification']?.toString() ?? '0';
    profile = json['profile']?.toString() ?? '';
    token = json['token']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
    instagram = json['instagram_id']?.toString() ?? '';
    facebook = json['facebook_id']?.toString() ?? '';
    youtube = json['youtube_id']?.toString() ?? '';
    twitter = json['twitter_id']?.toString() ?? '';
    isAgent = _parseBool(json['is_agent']);
    isUserVerified = _parseBool(json['is_user_verified']);
    isAppointmentAvailable = _parseBool(json['is_appointment_available']);
    becomeAgentStatus = json['become_agent_status']?.toString() ?? '';
    slugId = json['slug_id']?.toString();
    password = json['password']?.toString();
    fullMobile = json['full_mobile']?.toString();
    defaultLanguage = json['default_language']?.toString();
    isAdminAdded = _parseBool(json['is_admin_added']);
    isEmailVerified = _parseBool(json['is_email_verified']);
    isAgentVerified = _parseBool(json['is_agent_verified']);
    subscription = json['subscription'] is int
        ? json['subscription'] as int
        : int.tryParse(json['subscription']?.toString() ?? '');
    aboutMe = json['about_me']?.toString();
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    city = json['city']?.toString();
    state = json['state']?.toString();
    country = json['country']?.toString();
    isPremium = json['is_premium'] is int
        ? json['is_premium'] as int
        : int.tryParse(json['is_premium']?.toString() ?? '');
    agentProfile = json['agent_profile_photo']?.toString();
    agentVerificationStatus = json['agent_verification_status']?.toString();
    userVerificationStatus = json['user_verification_status']?.toString();
    becomeAgentVerification = json['become_agent_verification'] is Map
        ? Map<String, dynamic>.from(json['become_agent_verification'] as Map)
        : null;
    agentVerification = json['agent_verification'] is Map
        ? Map<String, dynamic>.from(json['agent_verification'] as Map)
        : null;
    becomeAgentRejectReason = json['become_agent_reject_reason']?.toString();
    userVerificationRejectReason = json['user_verification_reject_reason']
        ?.toString();
  }
  int? id;
  String? address;
  String? createdAt;
  String? customertotalpost;
  String? email;
  String? fcmId;
  String? authId;
  bool? isDemoUser;
  String? isActive;
  bool? isProfileCompleted;
  String? logintype;
  String? countryCode;
  String? mobile;
  String? name;
  String? notification;
  String? profile;
  String? token;
  String? updatedAt;
  String? instagram;
  String? facebook;
  String? youtube;
  String? twitter;
  bool? isAgent;
  bool? isUserVerified;
  bool? isAppointmentAvailable;
  String? becomeAgentStatus;
  String? slugId;
  String? password;
  String? fullMobile;
  String? defaultLanguage;
  bool? isAdminAdded;
  bool? isEmailVerified;
  bool? isAgentVerified;
  int? subscription;
  String? aboutMe;
  String? latitude;
  String? longitude;
  String? city;
  String? state;
  String? country;
  int? isPremium;
  String? agentProfile;
  String? agentVerificationStatus;
  String? userVerificationStatus;
  Map<String, dynamic>? becomeAgentVerification;
  Map<String, dynamic>? agentVerification;
  String? becomeAgentRejectReason;
  String? userVerificationRejectReason;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['address'] = address;
    data['created_at'] = createdAt;
    data['customertotalpost'] = customertotalpost;
    data['email'] = email;
    data['fcm_id'] = fcmId;
    data['auth_id'] = authId;
    data['is_demo_user'] = isDemoUser;
    data['id'] = id;
    data['isActive'] = isActive;
    data['isProfileCompleted'] = isProfileCompleted;
    data['logintype'] = logintype;
    data['country_code'] = countryCode;
    data['mobile'] = mobile;
    data['name'] = name;
    data['notification'] = notification;
    data['profile'] = profile;
    data['token'] = token;
    data['updated_at'] = updatedAt;
    data['instagram_id'] = instagram;
    data['facebook_id'] = facebook;
    data['youtube_id'] = youtube;
    data['twitter_id'] = twitter;
    data['is_agent'] = isAgent;
    data['is_user_verified'] = isUserVerified;
    data['is_appointment_available'] = isAppointmentAvailable;
    data['become_agent_status'] = becomeAgentStatus;
    data['slug_id'] = slugId;
    data['password'] = password;
    data['full_mobile'] = fullMobile;
    data['default_language'] = defaultLanguage;
    data['is_admin_added'] = isAdminAdded;
    data['is_email_verified'] = isEmailVerified;
    data['is_agent_verified'] = isAgentVerified;
    data['subscription'] = subscription;
    data['about_me'] = aboutMe;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    data['is_premium'] = isPremium;
    data['agent_profile_photo'] = agentProfile;
    data['agent_verification_status'] = agentVerificationStatus;
    data['user_verification_status'] = userVerificationStatus;
    data['become_agent_verification'] = becomeAgentVerification;
    data['agent_verification'] = agentVerification;
    data['become_agent_reject_reason'] = becomeAgentRejectReason;
    data['user_verification_reject_reason'] = userVerificationRejectReason;
    return data;
  }

  @override
  String toString() {
    return '''UserModel(address: $address, createdAt: $createdAt, customertotalpost: $customertotalpost, email: $email, fcmId: $fcmId, authId: $authId, id: $id, isActive: $isActive, isProfileCompleted: $isProfileCompleted, logintype: $logintype, mobile: $mobile, name: $name, notification: $notification, profile: $profile, token: $token, updatedAt: $updatedAt, instagram: $instagram, facebook: $facebook, youtube: $youtube, twitter: $twitter, isAgent: $isAgent, isUserVerified: $isUserVerified, isAppointmentAvailable: $isAppointmentAvailable, becomeAgentStatus: $becomeAgentStatus, slugId: $slugId, fullMobile: $fullMobile, defaultLanguage: $defaultLanguage, isAdminAdded: $isAdminAdded, isEmailVerified: $isEmailVerified, isAgentVerified: $isAgentVerified, subscription: $subscription, aboutMe: $aboutMe, latitude: $latitude, longitude: $longitude, city: $city, state: $state, country: $country, isPremium: $isPremium, agentProfile: $agentProfile, agentVerificationStatus: $agentVerificationStatus)''';
  }
}
