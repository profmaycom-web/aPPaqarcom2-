import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/model/chat_message_model.dart';
import 'package:ebroker/ui/screens/chat/widgets/audio_message.dart';
import 'package:ebroker/ui/screens/chat/widgets/message_renderer.dart';
import 'package:ebroker/ui/screens/chat/widgets/message_types/file_message.dart';
import 'package:ebroker/ui/screens/chat/widgets/message_types/image_message.dart';
import 'package:ebroker/ui/screens/chat/widgets/message_types/text_and_file.dart';
import 'package:ebroker/ui/screens/chat/widgets/message_types/text_message.dart';

class MessageType {
  final List<ChatMessage> _messageTypes = [
    TextMessage(),
    FileMessage(),
    FileAndText(),
    AudioMessage(),
    // Make sure we have an image message type handler
    ImageMessage(), // Add this if it doesn't exist
  ];

  ChatMessage? get(String type) {
    try {
      return _messageTypes
          .where((element) => element.chatMessageType == type)
          .first;
    } on Exception catch (_) {
      // Fallback to file message if type not found
      return _messageTypes
          .where((element) => element.chatMessageType == 'file')
          .first;
    }
  }
}

ChatMessage filterMessageType(ChatMessage message) {
  switch (message.chatMessageType) {
    case 'text':
      return TextMessage()
        ..id = message.id
        ..message = message.message
        ..senderId = message.senderId
        ..receiverId = message.receiverId
        ..propertyId = message.propertyId
        ..date = message.date
        ..timeAgo = message.timeAgo
        ..isSentByMe = message.isSentByMe
        ..isSentNow = message.isSentNow
        ..isSent = message.isSent;
    case 'image':
      return ImageMessage()
        ..id = message.id
        ..message = message.message
        ..senderId = message.senderId
        ..receiverId = message.receiverId
        ..propertyId = message.propertyId
        ..date = message.date
        ..timeAgo = message.timeAgo
        ..isSentByMe = message.isSentByMe
        ..isSentNow = message.isSentNow
        ..file = message.file
        ..isSent = message.isSent;
    case 'audio':
      // Ensure correct initialization of AudioMessage
      final audioMessage = AudioMessage()
        ..id = message.id
        ..message = message.message ?? ''
        ..senderId = message.senderId
        ..receiverId = message.receiverId
        ..propertyId = message.propertyId
        ..date = message.date
        ..timeAgo = message.timeAgo
        ..isSentByMe = message.isSentByMe
        ..isSentNow = message.isSentNow
        ..audio = message.audio
        ..chatMessageType = 'audio'
        ..isSent = message.isSent;

      // Debug audio URL when creating message
      debugPrint(
        'Created audio message with ID: ${message.id}, URL for streaming: ${message.audio}',
      );

      return audioMessage;
    // Add other cases as needed
    default:
      return message;
  }
}

class ChatMessageHandler {
  static final List<String> sentMessageIds = [];
  static final List<ChatMessage> _messages = [];

  /// Keeps a single long-lived message instance per message id so that
  /// media state (e.g. a loaded/playing [AudioMessage] player) survives
  /// list refreshes such as `fillMessages` instead of being recreated
  /// (and reloaded from the network) every time.
  static final Map<String, ChatMessage> _messageRegistry = {};
  static BuildContext? messageContext;

  static final _messageStream = StreamController<MessageAction>.broadcast();
  static final _allMessageStream =
      StreamController<List<ChatMessage>>.broadcast();

  // Add this flag to track if handle has been called
  static bool _isHandlerInitialized = false;

  /// For widgets like StreamBuilder
  static Stream<List<ChatMessage>> listenMessages() {
    // Make sure handle is called at least once
    if (!_isHandlerInitialized) {
      handle();
    }

    // Add initial data to the stream if there are messages
    if (_messages.isNotEmpty) {
      _allMessageStream.add(List.unmodifiable(_messages));
    }

    return _allMessageStream.stream;
  }

  static void handle() {
    if (_isHandlerInitialized) return;

    _isHandlerInitialized = true;
    _messageStream.stream.listen((action) {
      switch (action.action) {
        case 'add':
          _messages.add(action.message);
          syncMessages();
        case 'remove':
          // Note: The actual removal is now handled directly in the remove() method
          // This is just a fallback for any other listeners
          syncMessages();
      }
    });
  }

  static Future<void> add(ChatMessage data) async {
    try {
      // Check if message with same ID already exists to prevent duplicates
      final messageExists = _messages.any(
        (msg) => msg.id == data.id && data.id.isNotEmpty,
      );

      // If message already exists, don't add it again
      if (messageExists) {
        debugPrint(
          'Message with ID ${data.id} already exists, skipping duplicate',
        );
        return;
      }

      final message = filterMessageType(data)
        ..id = data.id
        ..propertyId = data.propertyId
        ..isSentByMe = data.isSentByMe
        ..isSentNow = data.isSentNow
        ..message = data.message
        ..file = data
            .file // Make sure file property is copied
        ..audio = data
            .audio // Make sure audio property is copied
        ..senderId = data.senderId
        ..receiverId = data.receiverId
        ..date = data.date
        ..timeAgo = data.timeAgo
        ..isSent = data.isSentByMe ? sentMessageIds.contains(data.id) : null;

      if (!sentMessageIds.contains(data.id) &&
          message.isSentByMe &&
          message.isSentNow) {
        sentMessageIds.add(data.id);
      }

      // Remember this instance so later refreshes (fillMessages) can reuse
      // it instead of constructing a fresh one and losing loaded media state.
      _messageRegistry[message.id] = message;

      // Set context for all message types that need it
      if (messageContext?.mounted ?? false) {
        message
          ..context = messageContext
          ..init();
      }

      _messageStream.sink.add(MessageAction(action: 'add', message: message));
    } on Exception catch (_) {}
  }

  static Future<void> remove(String id) async {
    try {
      final index = _messages.indexWhere((msg) => msg.id == id);
      debugPrint('Removing message at index: $index with ID: $id');
      debugPrint('Current messages count: ${_messages.length}');

      if (index != -1) {
        // Get reference to the message before removing it
        final message = _messages[index];

        // Remove from the messages list
        _messages.removeAt(index);
        _messageRegistry.remove(id);
        debugPrint('Message removed. Remaining messages: ${_messages.length}');

        // Send notification through the stream for action listeners
        _messageStream.sink.add(
          MessageAction(action: 'remove', message: message),
        );

        // IMPORTANT: Force update the UI by explicitly sending the updated message list
        // to all listeners of the _allMessageStream
        _allMessageStream.add(List.unmodifiable(_messages));

        // If we have context, force a rebuild
        if (messageContext?.mounted ?? false) {
          // Use a microtask to ensure this happens after the current build cycle
          await Future.microtask(syncMessages);
        }

        debugPrint('Message removed with ID: $id, UI update triggered');
      } else {
        debugPrint('Message with ID: $id not found for removal');
      }
    } on Exception catch (_) {}
  }

  static void fillMessages(List<ChatMessage> messages) {
    // Create a set to keep track of message IDs we've already processed
    final processedMessageIds = <String>{};
    final updatedMessages = <ChatMessage>[];

    // Reverse to show latest messages first
    for (final incoming in messages.reversed) {
      if (!processedMessageIds.add(incoming.id)) continue;

      final existing = _messageRegistry[incoming.id];

      ChatMessage message;
      if (existing != null &&
          existing.chatMessageType == incoming.chatMessageType) {
        // Reuse the already-initialized instance so any loaded/playing
        // media (e.g. an AudioMessage's player) survives this refresh,
        // and only sync the fields that can legitimately change.
        message = existing
          ..isSentByMe = incoming.isSentByMe
          ..isSentNow = incoming.isSentNow
          ..isSent = incoming.isSent
          ..message = incoming.message
          ..date = incoming.date
          ..timeAgo = incoming.timeAgo;
      } else {
        // Dispose a stale instance of a different type before replacing it.
        existing?.dispose();

        message = filterMessageType(incoming)
          ..id = incoming.id
          ..propertyId = incoming.propertyId
          ..isSentByMe = incoming.isSentByMe
          ..isSentNow = incoming.isSentNow
          ..message = incoming.message
          ..file = incoming.file
          ..audio = incoming.audio
          ..senderId = incoming.senderId
          ..receiverId = incoming.receiverId
          ..date = incoming.date
          ..timeAgo = incoming.timeAgo
          ..isSent = incoming.isSent;

        _messageRegistry[incoming.id] = message;

        if (messageContext?.mounted ?? false) {
          message
            ..context = messageContext
            ..init();
        }
      }

      updatedMessages.add(message);
    }

    _messages
      ..clear()
      ..addAll(updatedMessages);

    syncMessages();
  }

  // Add refreshMessages method to force refresh the message list
  static void refreshMessages() {
    // Make sure we have a listener before trying to sync
    if (_allMessageStream.hasListener) {
      syncMessages();
    }
  }

  static void syncMessages() {
    if (_allMessageStream.hasListener) {
      _allMessageStream.sink.add(List.unmodifiable(_messages));
    }
  }

  static void flush() {
    _messages.clear();
    // Widgets dispose their own message instance when they're torn down;
    // just drop our references so a later fillMessages doesn't try to
    // reuse an instance whose player has already been disposed.
    _messageRegistry.clear();
    syncMessages();
  }

  static void attachListener(void Function(List<ChatMessage>) listener) {
    _allMessageStream.stream.listen(listener);
  }

  // Add a method to check if messages are available
  static List<ChatMessage> getMessages() {
    return List.unmodifiable(_messages);
  }
}

///This class is using for render changes and
class RenderMessage extends StatefulWidget {
  const RenderMessage({required this.message, super.key});
  final ChatMessage message;

  @override
  MessageRenderState<RenderMessage> createState() => _RenderMessageState();
}

class _RenderMessageState extends MessageRenderState<RenderMessage>
    with AutomaticKeepAliveClientMixin {
  Widget? render;

  @override
  void initState() {
    super.initState();
    if (context.mounted) {
      ChatMessageHandler.messageContext = context;
    }

    widget.message.context = context;
  }

  @override
  void didChangeDependencies() {
    if (mounted) {
      widget.message.context = context;
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    widget.message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Use the new UnifiedMessageRenderer
    return UnifiedMessageRenderer(message: widget.message);
  }

  @override
  bool get wantKeepAlive => false;
}

abstract class MessageRenderState<T extends StatefulWidget> extends State<T> {
  static List<dynamic> renderedMessage = [];

  bool isRendered() {
    if (renderedMessage.contains(widget.key)) {
      return true;
    } else {
      renderedMessage.add(widget.key);
      return false;
    }
  }
}
