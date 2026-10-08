import 'package:ebroker/data/model/agent/agents_properties_models/customer_data.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/helpers/chat_helpers.dart';
import 'package:ebroker/ui/screens/chat/helpers/registerar.dart';
import 'package:ebroker/ui/screens/chat/model/chat_message_model.dart';
import 'package:ebroker/ui/screens/chat/widgets/chat_app_bar.dart';
import 'package:ebroker/ui/screens/chat/widgets/chat_contact_actions.dart';
import 'package:ebroker/ui/screens/chat/widgets/chat_input_bar.dart';
import 'package:ebroker/ui/screens/chat/widgets/message_renderer.dart';
import 'package:ebroker/ui/screens/proprties/property_details/utils/property_details_helpers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

int totalMessageCount = 0;

ValueNotifier<bool> showDeletebutton = ValueNotifier<bool>(false);

ValueNotifier<int> selectedMessageid = ValueNotifier<int>(-5);
ValueNotifier<int> selectedRecieverId = ValueNotifier<int>(-5);

class ChatScreenNew extends StatefulWidget {
  const ChatScreenNew({
    required this.profilePicture,
    required this.userName,
    required this.propertyImage,
    required this.proeprtyTitle,
    required this.userId,
    required this.propertyId,
    required this.isBlockedByMe,
    required this.isBlockedByUser,
    required this.isAgent,
    required this.isAgentVerified,
    required this.isUserVerified,
    required this.isAdmin,
    this.phoneNumber,
    this.propertySlugId,
    this.hasProperty = true,
    this.receiverRoleContext,
    this.isAppointmentAvailable = false,
    this.chatType = 'sent',
    super.key,
    this.from,
  });

  final String? from;
  final String profilePicture;
  final String userName;
  final String propertyImage;
  final String proeprtyTitle;
  final String userId;
  final String propertyId;
  final bool isBlockedByMe;
  final bool isBlockedByUser;
  final bool isAgent;
  final bool isAgentVerified;
  final bool isUserVerified;
  final bool isAdmin;
  final String? phoneNumber;
  final String? propertySlugId;
  final bool hasProperty;
  final String? receiverRoleContext;
  final bool isAppointmentAvailable;
  final String chatType;

  @override
  State<ChatScreenNew> createState() => _ChatScreenNewState();
}

class _ChatScreenNewState extends State<ChatScreenNew>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _reasonController = TextEditingController();

  late final Stream<PermissionStatus> _notificationStream;
  late final StreamSubscription<dynamic> _notificationSubscription;
  StreamSubscription<dynamic>? _chatNotificationSubscription; // Add this line
  bool isNotificationPermissionGranted = true;
  bool? isBlockedByMe;
  bool? isBlockedByUser;
  bool? isAgent;
  bool? isAgentVerified;
  bool? isUserVerified;
  bool? isAdmin;
  String? phoneNumber;
  String? propertySlugId;
  late bool hasProperty;
  String? receiverRoleContext;
  late bool isAppointmentAvailable;
  late String chatType;

  // Variables for scroll handling
  bool _isScrolling = false;
  Timer? _scrollDebouncer;

  @override
  void initState() {
    super.initState();
    ChatMessageHandler.handle();

    _setupScrollListener();
    _fetchInitialMessages();
    _listenToNotificationPermission();
    _setupChatNotificationListener();

    // Set this as the active chat to prevent notifications
    NotificationService.setActiveChat(widget.userId, widget.propertyId);

    isBlockedByMe = widget.isBlockedByMe;
    isBlockedByUser = widget.isBlockedByUser;
    isAgent = widget.isAgent;
    isAgentVerified = widget.isAgentVerified;
    isUserVerified = widget.isUserVerified;
    isAdmin = widget.isAdmin;
    phoneNumber = widget.phoneNumber;
    propertySlugId = widget.propertySlugId;
    hasProperty = widget.hasProperty;
    receiverRoleContext = widget.receiverRoleContext;
    isAppointmentAvailable = widget.isAppointmentAvailable;
    chatType = widget.chatType;

    // Ensure we have a context for message rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ChatMessageHandler.messageContext = context;
        // Initialize visible audio messages after the UI is built
        _handleVisibleAudioMessages();
      }
    });
  }

  void _setupChatNotificationListener() {
    _chatNotificationSubscription = NotificationService.chatMessageStream
        .listen((messageData) async {
          final type = messageData['type']?.toString() ?? '';

          // delete_message payloads use 'user_id' not 'sender_id'
          if (type == 'delete_message') {
            final userId = messageData['user_id']?.toString() ?? '';
            final msgPropertyId = messageData['property_id']?.toString() ?? '';
            final parsedUserId = int.tryParse(userId);
            final parsedPropertyId = int.tryParse(msgPropertyId);
            if (parsedUserId != null &&
                parsedPropertyId != null &&
                userId == widget.userId &&
                msgPropertyId == widget.propertyId &&
                mounted) {
              final cubit = context.read<LoadChatMessagesCubit>();
              if (!cubit.isClosed) {
                await cubit.load(
                  userId: parsedUserId,
                  propertyId: parsedPropertyId,
                );
              }
            }
            return;
          }

          // All messages cleared — pop screen and show snackbar
          if (type == 'chat_message_deleted') {
            final userId = messageData['user_id']?.toString() ?? '';
            final msgPropertyId = messageData['property_id']?.toString() ?? '';
            if (userId == widget.userId &&
                msgPropertyId == widget.propertyId &&
                mounted) {
              HelperUtils.showSnackBarMessage(
                context,
                'allChatMessagesDeletedByUser'.translate(context),
                type: .success,
              );
              Navigator.of(context).pop();
            }
            return;
          }

          // Check if this notification is for the current chat
          final senderId = messageData['sender_id']?.toString() ?? '';
          final propertyId = messageData['property_id']?.toString() ?? '';
          final message = messageData['message']?.toString() ?? '';
          final file = messageData['file']?.toString() ?? '';
          final audio = messageData['audio']?.toString() ?? '';

          // Determine message type based on file extension if present
          var messageType =
              messageData['chat_message_type']?.toString() ?? 'text';

          // Override message type for image files
          if (file.isNotEmpty) {
            final fileExt = file.split('.').last.toLowerCase();
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExt)) {
              messageType = 'image';
            }
          }

          if (senderId == widget.userId && propertyId == widget.propertyId) {
            // Get the actual message ID from notification if available
            final messageId =
                messageData['message_id']?.toString() ??
                messageData['id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString();

            // Check if message already exists to prevent duplicates
            final existingMessages = ChatMessageHandler.getMessages();
            final messageExists = existingMessages.any(
              (msg) =>
                  msg.id == messageId ||
                  (msg.senderId == senderId &&
                      msg.propertyId == propertyId &&
                      msg.message == message &&
                      msg.file == file &&
                      msg.audio == audio &&
                      msg.date ==
                          (messageData['created_at']?.toString() ??
                              DateTime.now().toIso8601String())),
            );

            // Only add if message doesn't already exist
            if (!messageExists) {
              // Create a new message from the notification data
              final newMessage = ChatMessage()
                ..id = messageId
                ..message = message
                ..chatMessageType = messageType
                ..senderId = senderId
                ..receiverId = HiveUtils.getUserId().toString()
                ..propertyId = propertyId
                ..file = file
                ..audio = audio
                ..isSentByMe =
                    false // Messages from notifications are from others
                ..date =
                    messageData['created_at']?.toString() ??
                    DateTime.now().toIso8601String()
                ..timeAgo = messageData['time_ago']?.toString() ?? '1s before';

              // Add the message to the handler
              await ChatMessageHandler.add(newMessage);

              // Force refresh the handler messages
              ChatMessageHandler.refreshMessages();

              // Force UI update
              if (mounted) {
                setState(() {});
              }
            }
          }
        });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() async {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          context.read<LoadChatMessagesCubit>().hasMoreChat()) {
        // Pause any playing audio before loading more messages to prevent UI stuttering
        // ChatHelpers.stopAllAudio();
        // Start loading animation
        _startLoadingAnimation();
        // Load more messages
        await context.read<LoadChatMessagesCubit>().loadMore();
      }

      // Check if scrolling has stopped to preload visible audio messages
      if (!_isScrolling) {
        _isScrolling = true;
        _scrollDebouncer?.cancel();
        _scrollDebouncer = Timer(const Duration(milliseconds: 300), () {
          _isScrolling = false;
          // Preload visible audio messages after scrolling stops
          _handleVisibleAudioMessages();
        });
      }
    });
  }

  void _fetchInitialMessages() {
    unawaited(
      context.read<LoadChatMessagesCubit>().load(
        userId: int.parse(widget.userId),
        propertyId: int.parse(widget.propertyId),
      ),
    );
  }

  void _listenToNotificationPermission() {
    _notificationStream = _notificationPermissionLoop();
    _notificationSubscription = _notificationStream.listen((
      status,
    ) {
      setState(() {
        isNotificationPermissionGranted = status.isGranted;
      });
    });
  }

  Stream<PermissionStatus> _notificationPermissionLoop() async* {
    while (true) {
      await Future<dynamic>.delayed(const Duration(seconds: 5));
      yield* Permission.notification.request().asStream();
    }
  }

  // Add these variables to the class
  bool _showLoadingAnimation = false;
  Timer? _loadingAnimationTimer;

  bool _shouldShowLoadingAnimation() {
    return _showLoadingAnimation;
  }

  // Add this method to start the animation
  void _startLoadingAnimation() {
    setState(() {
      _showLoadingAnimation = true;
    });

    // Cancel any existing timer
    _loadingAnimationTimer?.cancel();

    // Set a timer to hide the animation after it completes
    _loadingAnimationTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showLoadingAnimation = false;
        });
      }
    });
  }

  // Add this method to handle audio messages when they come into view
  void _handleVisibleAudioMessages() {
    // Add a post-frame callback to initialize audio players for visible messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        // Use the current message list to find visible audio messages
        final visibleMessages = ChatMessageHandler.getMessages();

        // Find audio messages in the visible area and preload them
        for (final message in visibleMessages) {
          if (message.chatMessageType == 'audio' &&
              message.audio != null &&
              message.audio!.isNotEmpty) {
            // Only preload a few audio files to avoid overwhelming the system
            if (visibleMessages.indexOf(message) < 5) {
              // Use a slight delay between preloads to avoid overwhelming the network
              Future.delayed(
                Duration(milliseconds: 500 * visibleMessages.indexOf(message)),
                () async {
                  if (mounted) {
                    await ChatHelpers.preloadAudio(message.id, message.audio!);
                  }
                },
              );
            }
          }
        }
      } on Exception catch (e) {
        debugPrint('Error handling visible audio messages: $e');
      }
    });
  }

  @override
  void dispose() {
    _loadingAnimationTimer?.cancel();
    _scrollController.dispose();
    _reasonController.dispose();
    unawaited(_notificationSubscription.cancel());
    unawaited(_chatNotificationSubscription?.cancel());
    _scrollDebouncer?.cancel();

    // Clear active chat when leaving the screen
    unawaited(clearChatMessages());
    super.dispose();
  }

  Future<void> _handleAppBarAction(String value) async {
    if (value == 'refreshChat') {
      _startLoadingAnimation();
    }
    await ChatHelpers.handleAppBarAction(
      context,
      value,
      widget.userId,
      widget.propertyId,
      _reasonController,
    );
  }

  Future<void> clearChatMessages() async {
    Future.delayed(Duration.zero, () {
      NotificationService.clearActiveChat();
      // Stop all audio playback before clearing messages
      // ChatHelpers.stopAllAudio();
      ChatMessageHandler.flush();
    });
  }

  void onTapBackButton() {
    final cubit = context.read<LoadChatMessagesCubit>();

    if (!cubit.isClosed) {
      unawaited(
        cubit.load(
          userId: int.tryParse(widget.userId) ?? 0,
          propertyId: int.tryParse(widget.propertyId) ?? 0,
        ),
      );
    }
    unawaited(context.read<GetChatListCubit>().fetch(forceRefresh: false));
    unawaited(clearChatMessages());
    unawaited(_notificationSubscription.cancel());
    unawaited(_chatNotificationSubscription?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onTapBackButton();
        Navigator.pop(context);
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SendMessageCubit()),
          BlocProvider(create: (_) => DeleteMessageCubit()),
        ],
        child: BlocBuilder<LoadChatMessagesCubit, LoadChatMessagesState>(
          builder: (context, state) {
            return BlocListener<SendMessageCubit, SendMessageState>(
              listener: (context, state) async {
                if (state is SendMessageSuccess) {
                  // Refresh messages when a new message is sent
                  _fetchInitialMessages();
                } else if (state is SendMessageFailed) {
                  _fetchInitialMessages();
                  // Show error message
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.error.toString(),
                    type: .error,
                  );
                }
              },
              child: Scaffold(
                appBar: ChatAppBar(
                  profilePicture: widget.profilePicture,
                  userName: widget.userName,
                  propertyTitle: widget.proeprtyTitle,
                  propertyImage: widget.propertyImage,
                  isAgent: isAgent ?? false,
                  isBlockedByMe: isBlockedByMe ?? false,
                  isBlockedByUser: isBlockedByUser ?? false,
                  isAgentVerified: isAgentVerified ?? false,
                  isUserVerified: isUserVerified ?? false,
                  isAdmin: isAdmin ?? false,
                  isNotificationPermissionGranted:
                      isNotificationPermissionGranted,
                  userId: widget.userId,
                  propertyId: widget.propertyId,
                  onMenuSelected: _handleAppBarAction,
                  onTapBackButton: onTapBackButton,
                  isFrom: widget.from ?? 'chat_list',
                  hasProperty: hasProperty,
                  receiverRoleContext: receiverRoleContext,
                  chatType: chatType,
                ),
                backgroundColor: context.color.primaryColor,
                body: Stack(
                  children: [
                    CustomImage(
                      imageUrl: AppIcons.chatBackground,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                    ),
                    Column(
                      children: [
                        _buildContactActions(context),
                        Expanded(
                          child: _buildChatList(context),
                        ),
                        if (state is LoadChatMessagesSuccess &&
                            state.isBlockedByMe)
                          _buildBlockedBanner(
                            'blockedByMe'.translate(context),
                          )
                        else if (state is LoadChatMessagesSuccess &&
                            state.isBlockedByUser)
                          _buildBlockedBanner(
                            'blockedByUser'.translate(context),
                          )
                        else
                          ChatInputBar(
                            receiverId: widget.userId,
                            propertyId: widget.propertyId,
                            scrollController: _scrollController,
                            receiverRoleContext: receiverRoleContext,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlockedBanner(String text) {
    return ChatHelpers.buildBlockedBanner(context, text);
  }

  String? get _effectivePhoneNumber {
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      return phoneNumber!.trim();
    }
    return null;
  }

  Widget _buildContactActions(BuildContext context) {
    final effectivePhone = _effectivePhoneNumber;
    final hasPhone = effectivePhone != null && effectivePhone.isNotEmpty;
    final canShowWhatsapp = AppSettings.showWhatsappButton && hasPhone;
    final canShowCall = hasPhone;

    return ChatContactActions(
      canShowAppointment: isAppointmentAvailable,
      canShowWhatsapp: canShowWhatsapp,
      canShowCall: canShowCall,
      onTapBookAppointment: _onTapBookAppointment,
      onTapWhatsapp: () => _onTapWhatsapp(phone: effectivePhone),
      onTapCall: () => _onTapCall(phone: effectivePhone),
    );
  }

  Future<void> _onTapBookAppointment() async {
    await GuestChecker.check(
      onNotGuest: () async {
        final parsedPropId = int.tryParse(widget.propertyId) ?? 0;
        final isPropertyLinked = hasProperty && parsedPropId != 0;
        final isProject = widget.from == 'project';

        if (isPropertyLinked && !isProject) {
          try {
            unawaited(Widgets.showLoader(context));
            final property = await HelperUtils.fetchPropertyDetails(
              propertyId: parsedPropId,
              isMyProperty: false,
            );
            Widgets.hideLoder(context);

            final preSelectedProperty = PropertyDetailsHelpers.toPropertiesData(
              property,
            );
            final agentDetails = PropertyDetailsHelpers.createAgentCustomerData(
              property,
            );

            if (!mounted) return;
            await Navigator.pushNamed(
              context,
              Routes.appointmentFlow,
              arguments: {
                'isAdmin': isAdmin ?? false,
                'agentDetails': agentDetails,
                'preSelectedProperty': preSelectedProperty,
              },
            );
            return;
          } on Exception {
            Widgets.hideLoder(context);
            // Fall back to direct agent appointment flow below if property fetch failed
          }
        }

        // Direct message to agent/admin or project chat: open starting at property selection
        final agentDetails = CustomerData(
          id: int.tryParse(widget.userId) ?? 0,
          slugId: propertySlugId ?? '',
          name: widget.userName,
          profile: widget.profilePicture,
          mobile: _effectivePhoneNumber ?? '',
          email: '',
          address: '',
          city: '',
          country: '',
          state: '',
          agentProfile: AgentProfileModel(),
          projectCount: '0',
          propertyCount: '0',
          propertiesSoldCount: '',
          propertiesRentedCount: '',
          isAppointmentAvailable: isAppointmentAvailable,
          isAgentVerified: isAgentVerified ?? false,
          isAdmin: isAdmin ?? false,
        );

        if (!mounted) return;
        await Navigator.pushNamed(
          context,
          Routes.appointmentFlow,
          arguments: {
            'isAdmin': isAdmin ?? false,
            'agentDetails': agentDetails,
          },
        );
      },
    );
  }

  Future<void> _onTapWhatsapp({String? phone}) async {
    final targetPhone = phone ?? _effectivePhoneNumber;
    if (targetPhone == null || targetPhone.isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'phoneNotAvailable'.translate(context),
        type: .warning,
      );
      return;
    }
    final cleanPhone = targetPhone.replaceAll(RegExp('[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onTapCall({String? phone}) async {
    final targetPhone = phone ?? _effectivePhoneNumber;
    if (targetPhone == null || targetPhone.isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        'phoneNotAvailable'.translate(context),
        type: .warning,
      );
      return;
    }
    final cleanPhone = targetPhone.replaceAll(RegExp('[^0-9]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildChatList(BuildContext context) {
    return BlocListener<LoadChatMessagesCubit, LoadChatMessagesState>(
      listener: (context, state) {
        if (state is LoadChatMessagesSuccess) {
          isBlockedByMe = state.isBlockedByMe;
          isBlockedByUser = state.isBlockedByUser;
          isAgent = state.isAgent;
          isAgentVerified = state.isAgentVerified;
          isUserVerified = state.isUserVerified;
          isAdmin = state.isAdmin;
          if (state.phoneNumber != null && state.phoneNumber!.isNotEmpty) {
            phoneNumber = state.phoneNumber;
          }
          if (state.propertySlugId != null &&
              state.propertySlugId!.isNotEmpty) {
            propertySlugId = state.propertySlugId;
          }
          if (state.hasProperty != null) {
            hasProperty = state.hasProperty!;
          }
          if (state.receiverRoleContext != null &&
              state.receiverRoleContext!.isNotEmpty) {
            receiverRoleContext = state.receiverRoleContext;
          }
          if (state.isAppointmentAvailable != null) {
            isAppointmentAvailable =
                widget.isAppointmentAvailable || state.isAppointmentAvailable!;
          }
          if (state.chatType != null && state.chatType!.isNotEmpty) {
            chatType = state.chatType!;
          }
          ChatMessageHandler.fillMessages(state.messages);
          if (mounted) setState(() {});
        }
      },
      child: StreamBuilder<List<ChatMessage>>(
        stream: ChatMessageHandler.listenMessages(),
        builder: (context, snapshot) {
          final messages = snapshot.data ?? [];
          if (context.read<LoadChatMessagesCubit>().state
              is LoadChatMessagesInProgress) {
            return ChatHelpers.buildChatShimmer(context, _scrollController);
          }
          if (messages.isEmpty) {
            return const SizedBox.shrink();
          }
          return Stack(
            children: [
              ListView(
                physics: Constant.scrollPhysics,
                padding: const EdgeInsets.symmetric(vertical: 16),
                controller: _scrollController,
                reverse: true,
                children: MessageRenderUtils.groupMessagesByDate(
                  context,
                  messages,
                ),
              ),
              if (_shouldShowLoadingAnimation())
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.color.backgroundColor,
                          context.color.backgroundColor.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.color.tertiaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
