import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/helpers/attachment.dart';
import 'package:ebroker/ui/screens/chat/helpers/chat_helpers.dart';
import 'package:ebroker/ui/screens/chat/helpers/registerar.dart';
import 'package:ebroker/ui/screens/chat/widgets/message_renderer.dart';
import 'package:ebroker/ui/screens/chat/widgets/record_button.dart';
import 'package:material_ui/material_ui.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    required this.receiverId,
    required this.propertyId,
    required this.scrollController,
    this.receiverRoleContext,
    super.key,
  });

  final String receiverId;
  final String propertyId;
  final ScrollController scrollController;
  final String? receiverRoleContext;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ValueNotifier<bool> _showRecordButton = ValueNotifier(true);
  PlatformFile? _attachment;
  late final AnimationController _recordAnimation;
  bool _isSending = false;
  bool _isSendingAudio = false;

  @override
  void initState() {
    super.initState();

    _recordAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _textController.addListener(() {
      _showRecordButton.value =
          _textController.text.trim().isEmpty && _attachment == null;
    });
  }

  @override
  void dispose() {
    _recordAnimation.dispose();
    _textController.dispose();
    _showRecordButton.dispose();
    super.dispose();
  }

  void _removeAttachment() {
    setState(() => _attachment = null);
    _showRecordButton.value = _textController.text.trim().isEmpty;
  }

  Future<void> _sendTextOrAttachment() async {
    if (_textController.text.trim().isEmpty && _attachment == null) return;
    if (_isSending) return; // Prevent multiple taps

    setState(() => _isSending = true);

    try {
      // Send to server using SendMessageCubit
      final sent = await context.read<SendMessageCubit>().send(
        proeprtyId: widget.propertyId,
        recieverId: widget.receiverId,
        senderId: HiveUtils.getUserId().toString(),
        message: _textController.text.trim(),
        attachment: _attachment?.path,
        receiverRoleContext: widget.receiverRoleContext,
      );

      if (sent) {
        _textController.clear();
        _removeAttachment();
        if (widget.scrollController.hasClients) {
          widget.scrollController.jumpTo(widget.scrollController.offset - 10);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendAudio(String? path) async {
    if (_isSendingAudio) return;
    setState(() => _isSendingAudio = true);

    try {
      final model = MessageRenderUtils.createChatMessage(
        message: _textController.text.trim(),
        audio: path,
        receiverId: widget.receiverId,
        propertyId: widget.propertyId,
        audioPath: path,
      );

      // Add to local message handler for immediate display
      await ChatMessageHandler.add(model);

      // Send to server using SendMessageCubit. This must happen with this
      // widget's own context: ChatMessageHandler.messageContext (used inside
      // AudioMessage.init()) is the ChatScreen State's context, which sits
      // above the MultiBlocProvider that supplies SendMessageCubit, so a
      // send triggered from there can never find the cubit.
      final sent = await context.read<SendMessageCubit>().send(
        proeprtyId: widget.propertyId,
        recieverId: widget.receiverId,
        senderId: HiveUtils.getUserId().toString(),
        message: _textController.text.trim(),
        attachment: _attachment?.path,
        receiverRoleContext: widget.receiverRoleContext,
        audio: path,
      );

      if (sent) {
        _textController.clear();
        if (widget.scrollController.hasClients) {
          widget.scrollController.jumpTo(widget.scrollController.offset - 10);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingAudio = false);
      }
    }
  }

  Future<void> _showAttachmentOptions(BuildContext context) async {
    await CustomBottomSheet.show<dynamic>(
      context: context,
      title: 'selectAttachment'.translate(context),
      borderRadius: 30,
      child: Row(
        children: [
          _buildAttachmentOption(
            context,
            Icons.image,
            'gallery'.translate(context),
            () async {
              Navigator.pop(context);
              await ChatHelpers.pickGalleryAttachment((file) {
                setState(() {
                  _attachment = file;
                });
                _showRecordButton.value = false;
              });
            },
          ),
          _buildAttachmentOption(
            context,
            Icons.insert_drive_file,
            'Documents'.translate(context),
            () async {
              Navigator.pop(context);
              await ChatHelpers.pickDocumentAttachment((file) {
                setState(() {
                  _attachment = file;
                });
                _showRecordButton.value = false;
              });
            },
          ),
          _buildAttachmentOption(
            context,
            Icons.audiotrack,
            'audio'.translate(context),
            () async {
              try {
                final file = await AppFilePicker.pickFile(
                  allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
                );

                if (file != null) {
                  await _sendAudio(file.path);
                  Navigator.pop(context);
                }
              } on Exception catch (e) {
                Navigator.pop(context);
                HelperUtils.showSnackBarMessage(
                  context,
                  e.toString(),
                  type: .error,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: .min,
          children: [
            ClipOval(
              child: ColoredBox(
                color: context.color.tertiaryColor.withValues(alpha: .2),
                child: Padding(
                  padding: .all(12.rw(context)),
                  child: Icon(
                    icon,
                    color: context.color.tertiaryColor,
                    size: 22.rh(context),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.rh(context)),
            CustomText(
              label,
              fontSize: context.font.sm,
              color: context.color.textColorDark,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachmentExt =
        _attachment?.path?.split('.').last.toLowerCase() ?? '';

    return Column(
      mainAxisSize: .min,
      children: [
        if (_attachment != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AttachmentPreview(
              attachment: _attachment!,
              isImage: ChatHelpers.supportedImageTypes.contains(attachmentExt),
              onRemove: _removeAttachment,
            ),
          ),
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: BottomAppBar(
            padding: const EdgeInsetsDirectional.all(10),
            color: context.color.secondaryColor,
            child: Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: _textController,
                    dense: true,
                    borderColor: context.color.borderColor,
                    hintText: 'writeHere'.translate(context),
                    suffix: GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CustomImage(
                          imageUrl: AppIcons.paperClip,
                          color: context.color.textColorDark,
                        ),
                      ),
                      onTap: () async {
                        if (_attachment != null) {
                          _removeAttachment();
                        } else {
                          await _showAttachmentOptions(context);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 10.rw(context)),
                ValueListenableBuilder<bool>(
                  valueListenable: _showRecordButton,
                  builder: (_, showRecord, _) {
                    return Container(
                      width: 46.rw(context),
                      height: 46.rh(context),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.color.tertiaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                        child: showRecord
                            ? RecordButton(
                                controller: _recordAnimation,
                                callback: (val) => _sendAudio(val as String?),
                                isSending: _isSendingAudio,
                              )
                            : GestureDetector(
                                onTap: _isSending
                                    ? null
                                    : _sendTextOrAttachment,
                                child: _isSending
                                    ? SizedBox(
                                        width: 20.rw(context),
                                        height: 20.rh(context),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                context.color.buttonColor,
                                              ),
                                        ),
                                      )
                                    : CustomImage(
                                        width: 24.rw(context),
                                        height: 24.rh(context),
                                        imageUrl: AppIcons.send,
                                        matchTextDirection: true,
                                        color: context.color.buttonColor,
                                      ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    required this.attachment,
    required this.isImage,
    required this.onRemove,
    super.key,
  });

  final PlatformFile attachment;
  final bool isImage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (isImage) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () async {
              await UiUtils.showFullScreenImage(
                context,
                provider: FileImage(File(attachment.path!)),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.color.borderColor,
                  width: 1.5,
                ),
              ),
              child: Image.file(
                File(attachment.path!),
                height: 100,
                width: 100,
                fit: .cover,
              ),
            ),
          ),
          // Remove button overlaid at top-right corner
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Document / audio attachment
    return ColoredBox(
      color: context.color.secondaryColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: .min,
          children: [
            Flexible(
              child: AttachmentMessage(
                url: attachment.path!,
                isSentByMe: true,
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: context.color.textColorDark.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: context.color.textColorDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
