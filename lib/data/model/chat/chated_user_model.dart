import 'dart:async';

import 'package:material_ui/material_ui.dart';

class ChatedUser {
  ChatedUser({
    this.propertyId,
    this.title,
    this.translatedTitle,
    this.titleImage,
    this.userId,
    this.unreadCount,
    this.name,
    this.profile,
    this.firebaseId,
    this.fcmId,
    this.isBlockedByMe,
    this.isBlockedByUser,
    this.isAgent,
    this.isAgentVerified,
    this.isUserVerified,
    this.isAdmin,
    this.phoneNumber,
    this.propertySlugId,
    this.hasProperty,
    this.receiverRoleContext,
    this.isAppointmentAvailable,
    this.chatType,
    this.lastMessage,
    this.createdAt,
    this.timeAgo,
  });

  ChatedUser.fromJson(Map<String, dynamic> json, {BuildContext? context}) {
    final profileImage =
        json['profile'] ??
        json['user_profile'] ??
        json['profile_image'] ??
        json['image'];
    if (context != null && profileImage != null && profileImage != '') {
      unawaited(
        precacheImage(NetworkImage(profileImage.toString()), context),
      );
    }
    if (context != null &&
        json['title_image'] != null &&
        json['title_image'] != '') {
      unawaited(
        precacheImage(
          NetworkImage(json['title_image']?.toString() ?? ''),
          context,
        ),
      );
    }
    propertyId = json['property_id'] is int
        ? json['property_id'] as int
        : int.tryParse(
            json['property_id']?.toString() ??
                json['project_id']?.toString() ??
                '',
          );
    userId = json['user_id'] as int?;
    title = json['title']?.toString() ?? '';
    translatedTitle = json['translated_title']?.toString() ?? '';
    titleImage = json['title_image']?.toString() ?? '';
    unreadCount = json['unread_count']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
    profile = profileImage?.toString() ?? '';
    firebaseId = json['firebase_id']?.toString() ?? '';
    fcmId = json['fcm_id']?.toString() ?? '';
    isBlockedByMe = _asBool(json['is_blocked_by_me']);
    isBlockedByUser = _asBool(json['is_blocked_by_user']);
    isAgent = _asBool(json['is_agent']);
    isAgentVerified = _asBool(json['is_agent_verified']);
    isUserVerified = _asBool(json['is_user_verified']);
    isAdmin = _asBool(json['is_admin'] ?? json['is_admin_listing']) ||
        (json['added_by']?.toString() == '0');

    final rawPhone =
        json['phone_number'] ??
        json['phone'] ??
        json['mobile'] ??
        json['user_mobile'] ??
        json['agent_mobile'] ??
        json['customer_number'] ??
        json['customer_mobile'] ??
        (json['property'] is Map
            ? (json['property'] as Map)['customer_number'] ??
                (json['property'] as Map)['mobile'] ??
                (json['property'] as Map)['phone'] ??
                ((json['property'] as Map)['customer'] is Map
                    ? ((json['property'] as Map)['customer'] as Map)['mobile']
                    : null)
            : null) ??
        (json['project'] is Map
            ? (json['project'] as Map)['mobile'] ??
                (json['project'] as Map)['phone'] ??
                (json['project'] as Map)['contact'] ??
                ((json['project'] as Map)['customer'] is Map
                    ? ((json['project'] as Map)['customer'] as Map)['mobile']
                    : null)
            : null) ??
        (json['customer'] is Map
            ? (json['customer'] as Map)['mobile'] ??
                (json['customer'] as Map)['phone']
            : null) ??
        (json['user'] is Map
            ? (json['user'] as Map)['mobile'] ??
                (json['user'] as Map)['phone']
            : null);
    if (rawPhone != null) {
      phoneNumber = rawPhone.toString().replaceAll(RegExp('[^0-9]'), '');
    }
    propertySlugId =
        json['property_slug_id']?.toString() ?? json['slug_id']?.toString();
    if (json.containsKey('has_property') && json['has_property'] != null) {
      hasProperty = _asBool(json['has_property']);
    } else {
      hasProperty = (propertyId != null && propertyId != 0) ||
          (json['project_id'] != null && json['project_id'].toString() != '0') ||
          (json['project'] != null);
    }
    receiverRoleContext =
        json['receiver_role_context']?.toString() ??
        json['role_context']?.toString() ??
        (isAgent == true ? 'agent' : (isAdmin == true ? 'admin' : 'user'));
    final dynamic rawAppt = json['is_appointment_available'] ??
        (json['property'] is Map
            ? (json['property'] as Map)['is_appointment_available']
            : null) ??
        (json['project'] is Map
            ? (json['project'] as Map)['is_appointment_available']
            : null) ??
        (json['user'] is Map
            ? (json['user'] as Map)['is_appointment_available']
            : null) ??
        (json['customer'] is Map
            ? (json['customer'] as Map)['is_appointment_available']
            : null);
    isAppointmentAvailable = rawAppt != null && _asBool(rawAppt);
    chatType = json['chat_type']?.toString();
    lastMessage =
        json['last_message']?.toString() ??
        json['message']?.toString() ??
        json['last_chat_message']?.toString();
    createdAt = json['created_at']?.toString();
    timeAgo = json['time_ago']?.toString();
    date = json['date']?.toString();
  }
  int? propertyId;
  int? userId;
  String? title;
  String? translatedTitle;
  String? titleImage;

  String? name;
  String? unreadCount;
  String? profile;
  String? firebaseId;
  String? fcmId;
  bool? isBlockedByMe;
  bool? isBlockedByUser;
  bool? isAgent;
  bool? isAgentVerified;
  bool? isUserVerified;
  bool? isAdmin;

  String? phoneNumber;
  String? propertySlugId;
  bool? hasProperty;
  String? receiverRoleContext;
  bool? isAppointmentAvailable;
  String? chatType;
  String? lastMessage;
  String? createdAt;
  String? timeAgo;

  /// Time of the last message (ISO, UTC), as sent by the chat list API.
  String? date;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['property_id'] = propertyId;
    data['title'] = title;
    data['translated_title'] = translatedTitle;
    data['title_image'] = titleImage;
    data['user_id'] = userId;
    data['unread_count'] = unreadCount;
    data['name'] = name;
    data['profile'] = profile;
    data['firebase_id'] = firebaseId;
    data['fcm_id'] = fcmId;
    data['is_blocked_by_me'] = isBlockedByMe;
    data['is_blocked_by_user'] = isBlockedByUser;
    data['is_agent'] = isAgent;
    data['is_agent_verified'] = isAgentVerified;
    data['is_user_verified'] = isUserVerified;
    data['is_admin'] = isAdmin;
    data['phone_number'] = phoneNumber;
    data['property_slug_id'] = propertySlugId;
    data['has_property'] = hasProperty;
    data['receiver_role_context'] = receiverRoleContext;
    data['is_appointment_available'] = isAppointmentAvailable;
    data['chat_type'] = chatType;
    data['last_message'] = lastMessage;
    data['created_at'] = createdAt;
    data['time_ago'] = timeAgo;
    data['date'] = date;
    return data;
  }
}

bool _asBool(dynamic value) {
  final normalized = value?.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}
