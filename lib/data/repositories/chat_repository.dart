import 'package:dio/dio.dart';
import 'package:ebroker/config/app_config.dart';
import 'package:ebroker/data/model/chat/chated_user_model.dart';
import 'package:ebroker/data/model/data_output.dart';
import 'package:ebroker/ui/screens/chat/helpers/registerar.dart';
import 'package:ebroker/ui/screens/chat/model/chat_message_model.dart';
import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:material_ui/material_ui.dart';

class ChatRepository {
  BuildContext? setContext0;

  Future<void> setContext(BuildContext context) async => setContext0 = context;

  Future<DataOutput<ChatedUser>> fetchChatList(
    int pageNumber, {
    String? chatType,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': pageNumber,
      'per_page': AppConfig.apiDataLoadLimit,
    };
    if (chatType != null && chatType.isNotEmpty) {
      queryParameters['chat_type'] = chatType;
      queryParameters['type'] = chatType;
    }
    final response = await Api.get(
      url: Api.getChatList,
      queryParameters: queryParameters,
    );
    if (response['error'] == true) {
      throw ApiException(response['message']?.toString() ?? 'noDataFound');
    }

    final modelList = (response['data'] as List).map((e) {
      return ChatedUser.fromJson(e as Map<String, dynamic>? ?? {});
    }).toList();

    return DataOutput(
      total: int.parse(response['total_page']?.toString() ?? '0'),
      modelList: modelList,
    );
  }

  Future<DataOutput<ChatMessage>> getMessages({
    required int page,
    required int userId,
    required int propertyId,
  }) async {
    try {
      final response = await Api.get(
        url: Api.getMessages,
        queryParameters: {
          'user_id': userId,
          // Direct chats have no property, so property_id is left out.
          if (propertyId != 0) 'property_id': propertyId,
          'page': page,
          'per_page': Constant.minChatMessages,
        },
      );

      // Check if data exists and has the expected structure
      if (response['data'] == null ||
          response['data']['data'] == null ||
          response['data']['data'] is! List ||
          (response['data']['data'] as List).isEmpty) {
        return DataOutput(total: 0, modelList: []);
      }

      final modelList = (response['data']['data'] as List).map<ChatMessage>(
        (result) {
          try {
            // Safely convert to Map
            final resultMap = result as Map<String, dynamic>? ?? {};

            // Creating model
            final chatMessageModel = ChatMessage.fromJson(resultMap);

            // Set additional properties
            chatMessageModel
              ..isSentByMe =
                  HiveUtils.getUserId() == chatMessageModel.senderId.toString()
              ..isSentNow = false
              ..date = resultMap['created_at']?.toString() ?? ''
              ..timeAgo = resultMap['time_ago']?.toString() ?? '';

            // Handle file attachments properly
            if (resultMap['file'] != null &&
                resultMap['file'].toString().isNotEmpty) {
              chatMessageModel.file = resultMap['file'].toString();

              // Set the chat message type based on file extension
              final fileUrl = resultMap['file'].toString();
              final fileExt = fileUrl.split('.').last.toLowerCase();

              // Check if there's also a text message
              if (chatMessageModel.message != null &&
                  chatMessageModel.message.toString().isNotEmpty) {
                chatMessageModel.chatMessageType = 'file_and_text';
              } else if ([
                'jpg',
                'jpeg',
                'png',
                'gif',
                'webp',
              ].contains(fileExt)) {
                // Override the API's chat_message_type for image files
                chatMessageModel.chatMessageType = 'image';
              } else if (['mp3', 'wav', 'ogg', 'm4a'].contains(fileExt)) {
                chatMessageModel.chatMessageType = 'audio';
              } else {
                chatMessageModel.chatMessageType = 'file';
              }
            }

            // Creating message widget with proper type handling
            final message = filterMessageType(chatMessageModel)
              ..propertyId = chatMessageModel.propertyId
              ..receiverId = chatMessageModel.receiverId
              ..senderId = chatMessageModel.senderId
              ..isSentNow = chatMessageModel.isSentNow
              ..message = chatMessageModel.message
              ..file = chatMessageModel.file
              ..timeAgo = chatMessageModel.timeAgo
              ..date = chatMessageModel.date
              ..chatMessageType = chatMessageModel.chatMessageType;

            return message;
          } on Exception catch (_) {
            // Return an empty message in case of error
            return ChatMessage()
              ..isSentByMe = true
              ..isSentNow = false
              ..message = 'Error loading message';
          }
        },
      ).toList();

      // Filter out any invalid messages
      final validMessages = modelList
          .where((msg) => msg.id.isNotEmpty)
          .toList();

      return DataOutput(
        total: int.parse(response['total_page']?.toString() ?? '0'),
        modelList: validMessages,
        extraData: ExtraData(data: response['data']),
      );
    } on Exception catch (_) {
      // Return empty data on error
      return DataOutput(total: 0, modelList: []);
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String senderId,
    required String recieverId,
    required String? message,
    required String proeprtyId,
    MultipartFile? audio,
    MultipartFile? attachment,
    String? receiverRoleContext,
  }) async {
    // A direct chat (e.g. with an agent) has no property, so the API expects
    // no property_id and the receiver's role instead.
    final isDirectChat = proeprtyId.isEmpty || proeprtyId == '0';
    final parameters = <String, dynamic>{
      'sender_id': senderId,
      'receiver_id': recieverId,
      'message': message,
      if (!isDirectChat) 'property_id': proeprtyId,
      if (isDirectChat && (receiverRoleContext?.isNotEmpty ?? false))
        'receiver_role_context': receiverRoleContext,
      'file': attachment,
      'audio': audio,
    };
    if (message == null) {
      parameters.remove('message');
    }
    if (attachment == null) {
      parameters.remove('file');
    }
    if (audio == null) {
      parameters.remove('audio');
    }
    final map = await Api.post(
      url: Api.sendMessage,
      parameter: parameters,
    );

    return map;
  }

  Future<Map<String, dynamic>> blockUser({
    required String userId,
    required String reason,
  }) async {
    final parameters = <String, dynamic>{
      'to_user_id': userId,
      'to_admin': userId == '0' ? '1' : '0',
      'reason': reason,
    };
    if (userId != '0') {
      parameters.remove('to_admin');
    }
    final map = await Api.post(
      url: Api.blockUser,
      parameter: parameters,
    );

    return map;
  }

  Future<Map<String, dynamic>> unblockUser({
    required String userId,
  }) async {
    final parameters = <String, dynamic>{
      'to_user_id': userId,
      'to_admin': userId == '0' ? '1' : '0',
    };
    if (userId != '0') {
      parameters.remove('to_admin');
    }
    final map = await Api.post(
      url: Api.unblockUser,
      parameter: parameters,
    );

    return map;
  }
}
