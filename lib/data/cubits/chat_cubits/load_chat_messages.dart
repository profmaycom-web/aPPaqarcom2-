import 'package:ebroker/data/repositories/chat_repository.dart';
import 'package:ebroker/ui/screens/chat/model/chat_message_model.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoadChatMessagesState {}

class LoadChatMessagesInitial extends LoadChatMessagesState {}

class LoadChatMessagesInProgress extends LoadChatMessagesState {}

class LoadChatMessagesSuccess extends LoadChatMessagesState {
  LoadChatMessagesSuccess({
    required this.messages,
    required this.isBlockedByMe,
    required this.isAgent,
    required this.isBlockedByUser,
    required this.isAgentVerified,
    required this.isUserVerified,
    required this.isAdmin,
    required this.currentPage,
    required this.userId,
    required this.propertyId,
    required this.totalPage,
    required this.isLoadingMore,
    this.phoneNumber,
    this.propertySlugId,
    this.hasProperty,
    this.receiverRoleContext,
    this.isAppointmentAvailable,
    this.chatType,
  });
  List<ChatMessage> messages;
  bool isBlockedByMe;
  bool isBlockedByUser;
  bool isAgent;
  bool isAgentVerified;
  bool isUserVerified;
  bool isAdmin;
  int currentPage;
  int userId;
  int propertyId;
  int totalPage;
  bool isLoadingMore;
  String? phoneNumber;
  String? propertySlugId;
  bool? hasProperty;
  String? receiverRoleContext;
  bool? isAppointmentAvailable;
  String? chatType;

  LoadChatMessagesSuccess copyWith({
    List<ChatMessage>? messages,
    bool? isBlockedByMe,
    bool? isBlockedByUser,
    bool? isAgent,
    bool? isAgentVerified,
    bool? isUserVerified,
    bool? isAdmin,
    int? currentPage,
    int? userId,
    int? propertyId,
    int? totalPage,
    bool? isLoadingMore,
    String? phoneNumber,
    String? propertySlugId,
    bool? hasProperty,
    String? receiverRoleContext,
    bool? isAppointmentAvailable,
    String? chatType,
  }) {
    return LoadChatMessagesSuccess(
      messages: messages ?? this.messages,
      isAgent: isAgent ?? this.isAgent,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      isBlockedByUser: isBlockedByUser ?? this.isBlockedByUser,
      isAgentVerified: isAgentVerified ?? this.isAgentVerified,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      currentPage: currentPage ?? this.currentPage,
      userId: userId ?? this.userId,
      propertyId: propertyId ?? this.propertyId,
      totalPage: totalPage ?? this.totalPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      propertySlugId: propertySlugId ?? this.propertySlugId,
      hasProperty: hasProperty ?? this.hasProperty,
      receiverRoleContext: receiverRoleContext ?? this.receiverRoleContext,
      isAppointmentAvailable:
          isAppointmentAvailable ?? this.isAppointmentAvailable,
      chatType: chatType ?? this.chatType,
    );
  }

  @override
  String toString() {
    return '''LoadChatMessagesSuccess(messages: $messages, isBlockedByMe: $isBlockedByMe, isBlockedByUser: $isBlockedByUser, isAgent: $isAgent, isAgentVerified: $isAgentVerified, isUserVerified: $isUserVerified, isAdmin: $isAdmin, currentPage: $currentPage, userId: $userId, propertyId: $propertyId, totalPage: $totalPage, isLoadingMore: $isLoadingMore, phoneNumber: $phoneNumber, propertySlugId: $propertySlugId, hasProperty: $hasProperty, receiverRoleContext: $receiverRoleContext, isAppointmentAvailable: $isAppointmentAvailable, chatType: $chatType)''';
  }
}

class LoadChatMessagesFailed extends LoadChatMessagesState {
  LoadChatMessagesFailed({
    required this.error,
  });
  final dynamic error;
}

class LoadChatMessagesCubit extends Cubit<LoadChatMessagesState> {
  LoadChatMessagesCubit() : super(LoadChatMessagesInitial());
  final ChatRepository _chatRepostiory = ChatRepository();

  @override
  void emit(LoadChatMessagesState state) {
    if (isClosed) return;
    super.emit(state);
  }

  Future<void> load({
    required int userId,
    required int propertyId,
  }) async {
    try {
      // Only emit LoadChatMessagesInProgress
      //if we're not already in a success state
      if (state is! LoadChatMessagesSuccess) {
        emit(LoadChatMessagesInProgress());
      } else {
        // Instead of full loading state,
        //just update isLoadingMore in success state
        final currentState = state as LoadChatMessagesSuccess;
        emit(currentState.copyWith(isLoadingMore: true));
      }

      final result = await _chatRepostiory.getMessages(
        page: 1,
        userId: userId,
        propertyId: propertyId,
      );
      if (isClosed) return;

      final extraData = result.extraData?.data as Map<String, dynamic>?;
      final rawPhone =
          extraData?['phone_number'] ??
          extraData?['phone'] ??
          extraData?['mobile'] ??
          extraData?['user_mobile'] ??
          extraData?['agent_mobile'] ??
          extraData?['customer_number'] ??
          extraData?['customer_mobile'] ??
          (extraData?['property'] is Map
              ? (extraData!['property'] as Map)['customer_number'] ??
                    (extraData['property'] as Map)['mobile'] ??
                    (extraData['property'] as Map)['phone'] ??
                    ((extraData['property'] as Map)['customer'] is Map
                        ? ((extraData['property'] as Map)['customer']
                              as Map)['mobile']
                        : null)
              : null) ??
          (extraData?['project'] is Map
              ? (extraData!['project'] as Map)['mobile'] ??
                    (extraData['project'] as Map)['phone'] ??
                    (extraData['project'] as Map)['contact'] ??
                    ((extraData['project'] as Map)['customer'] is Map
                        ? ((extraData['project'] as Map)['customer']
                              as Map)['mobile']
                        : null)
              : null) ??
          (extraData?['customer'] is Map
              ? (extraData!['customer'] as Map)['mobile'] ??
                    (extraData['customer'] as Map)['phone']
              : null) ??
          (extraData?['user'] is Map
              ? (extraData!['user'] as Map)['mobile'] ??
                    (extraData['user'] as Map)['phone']
              : null);
      final phoneNumber = rawPhone?.toString().replaceAll(RegExp('[^0-9]'), '');
      final propertySlugId =
          extraData?['property_slug_id']?.toString() ??
          extraData?['slug_id']?.toString();
      final hasProperty = (extraData?.containsKey('has_property') ?? false)
          ? _asBool(extraData!['has_property'])
          : (propertyId != 0 ||
                (extraData?['project_id'] != null &&
                    extraData!['project_id'].toString() != '0') ||
                extraData?['project'] != null);
      final receiverRoleContext =
          extraData?['receiver_role_context']?.toString() ??
          extraData?['role_context']?.toString();
      final dynamic rawAppt =
          extraData?['is_appointment_available'] ??
          (extraData?['property'] is Map
              ? (extraData!['property'] as Map)['is_appointment_available']
              : null) ??
          (extraData?['project'] is Map
              ? (extraData!['project'] as Map)['is_appointment_available']
              : null) ??
          (extraData?['user'] is Map
              ? (extraData!['user'] as Map)['is_appointment_available']
              : null) ??
          (extraData?['customer'] is Map
              ? (extraData!['customer'] as Map)['is_appointment_available']
              : null);
      final isAppointmentAvailable = rawAppt != null ? _asBool(rawAppt) : null;
      final chatType = extraData?['chat_type']?.toString();

      if (result.modelList.isEmpty && result.total == 0) {
        emit(
          LoadChatMessagesSuccess(
            messages: [],
            isAgent: _asBool(extraData?['is_agent']),
            isBlockedByMe: _asBool(extraData?['is_blocked_by_me']),
            isBlockedByUser: _asBool(extraData?['is_blocked_by_user']),
            isAgentVerified: _asBool(extraData?['is_agent_verified']),
            isUserVerified: _asBool(extraData?['is_user_verified']),
            isAdmin:
                _asBool(
                  extraData?['is_admin'] ?? extraData?['is_admin_listing'],
                ) ||
                (extraData?['added_by']?.toString() == '0'),
            currentPage: 1,
            propertyId: propertyId,
            isLoadingMore: false,
            totalPage: 0,
            userId: userId,
            phoneNumber: phoneNumber,
            propertySlugId: propertySlugId,
            hasProperty: hasProperty,
            receiverRoleContext: receiverRoleContext,
            isAppointmentAvailable: isAppointmentAvailable,
            chatType: chatType,
          ),
        );
        return;
      }

      emit(
        LoadChatMessagesSuccess(
          messages: result.modelList,
          isAgent: _asBool(extraData?['is_agent']),
          isBlockedByMe: _asBool(extraData?['is_blocked_by_me']),
          isBlockedByUser: _asBool(extraData?['is_blocked_by_user']),
          isAgentVerified: _asBool(extraData?['is_agent_verified']),
          isUserVerified: _asBool(extraData?['is_user_verified']),
          isAdmin:
              _asBool(
                extraData?['is_admin'] ?? extraData?['is_admin_listing'],
              ) ||
              (extraData?['added_by']?.toString() == '0'),
          currentPage: 1,
          propertyId: propertyId,
          isLoadingMore: false,
          totalPage: result.total,
          userId: userId,
          phoneNumber: phoneNumber,
          propertySlugId: propertySlugId,
          hasProperty: hasProperty,
          receiverRoleContext: receiverRoleContext,
          isAppointmentAvailable: isAppointmentAvailable,
          chatType: chatType,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      // If we were previously in success state, keep the old data
      if (state is LoadChatMessagesSuccess) {
        final currentState = state as LoadChatMessagesSuccess;
        emit(currentState.copyWith(isLoadingMore: false));
      } else {
        emit(LoadChatMessagesFailed(error: e.toString()));
      }
    }
  }

  Future<void> loadMore() async {
    try {
      if (state is LoadChatMessagesSuccess) {
        if ((state as LoadChatMessagesSuccess).isLoadingMore) {
          return;
        }
        emit((state as LoadChatMessagesSuccess).copyWith(isLoadingMore: true));

        final result = await _chatRepostiory.getMessages(
          page: (state as LoadChatMessagesSuccess).currentPage + 1,
          userId: (state as LoadChatMessagesSuccess).userId,
          propertyId: (state as LoadChatMessagesSuccess).propertyId,
        );

        if (isClosed) return;

        final messagesSuccessState = state as LoadChatMessagesSuccess;

        messagesSuccessState.messages.addAll(result.modelList);

        emit(
          LoadChatMessagesSuccess(
            messages: messagesSuccessState.messages,
            isAgent: messagesSuccessState.isAgent,
            isBlockedByMe: messagesSuccessState.isBlockedByMe,
            isBlockedByUser: messagesSuccessState.isBlockedByUser,
            isAgentVerified: messagesSuccessState.isAgentVerified,
            isUserVerified: messagesSuccessState.isUserVerified,
            isAdmin: messagesSuccessState.isAdmin,
            currentPage: (state as LoadChatMessagesSuccess).currentPage + 1,
            propertyId: (state as LoadChatMessagesSuccess).propertyId,
            isLoadingMore: false,
            totalPage: result.total,
            userId: (state as LoadChatMessagesSuccess).userId,
            phoneNumber: messagesSuccessState.phoneNumber,
            propertySlugId: messagesSuccessState.propertySlugId,
            hasProperty: messagesSuccessState.hasProperty,
            receiverRoleContext: messagesSuccessState.receiverRoleContext,
            isAppointmentAvailable: messagesSuccessState.isAppointmentAvailable,
            chatType: messagesSuccessState.chatType,
          ),
        );
      }
    } on ApiException {
      if (isClosed) return;
      emit((state as LoadChatMessagesSuccess).copyWith(isLoadingMore: false));
    }
  }

  bool hasMoreChat() {
    if (state is LoadChatMessagesSuccess) {
      return (state as LoadChatMessagesSuccess).currentPage <
          (state as LoadChatMessagesSuccess).totalPage;
    }
    return false;
  }

  void clear() {
    emit(LoadChatMessagesInitial());
  }
}

bool _asBool(dynamic value) {
  final normalized = value?.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}
