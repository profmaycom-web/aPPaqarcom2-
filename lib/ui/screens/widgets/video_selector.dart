import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;

enum VideoType {
  customUpload(0, 'customUpload'),
  youtube(1, 'youtube'),
  vimeo(2, 'vimeo');

  const VideoType(this.id, this.key);
  final int id;
  final String key;

  static VideoType fromId(int id) {
    return VideoType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => VideoType.youtube,
    );
  }
}

class VideoSelector extends StatefulWidget {
  const VideoSelector({
    required this.selectedVideoType,
    required this.onValueChanged,
    required this.youtubeController,
    required this.vimeoController,
    required this.selectedVideoFile,
    required this.onFileSelected,
    this.onRemoveVideo,
    this.existingCustomVideoUrl,
    super.key,
  });

  final int selectedVideoType;
  final void Function(int) onValueChanged;
  final TextEditingController youtubeController;
  final TextEditingController vimeoController;
  final File? selectedVideoFile;
  final void Function(File?) onFileSelected;
  final VoidCallback? onRemoveVideo;

  /// URL of an already-uploaded custom video (edit mode only).
  /// Used to show the preview when no local file has been picked yet.
  final String? existingCustomVideoUrl;

  @override
  State<VideoSelector> createState() => _VideoSelectorState();
}

class _VideoSelectorState extends State<VideoSelector>
    with TickerProviderStateMixin {
  late mui.TabController _tabController;
  late List<VideoType> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [VideoType.youtube, VideoType.vimeo];
    if (AppSettings.showDirectVideoUpload) {
      _tabs.add(VideoType.customUpload);
    }

    var initialIndex = _tabs.indexWhere(
      (t) => t.id == widget.selectedVideoType,
    );
    if (initialIndex == -1) initialIndex = 0;

    _tabController = mui.TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    widget.youtubeController.addListener(_onVideoLinkChanged);
    widget.vimeoController.addListener(_onVideoLinkChanged);
  }

  void _onVideoLinkChanged() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant VideoSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedVideoType != widget.selectedVideoType) {
      final newIndex = _tabs.indexWhere(
        (t) => t.id == widget.selectedVideoType,
      );
      if (newIndex != -1 && _tabController.index != newIndex) {
        _tabController.animateTo(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    widget.youtubeController.removeListener(_onVideoLinkChanged);
    widget.vimeoController.removeListener(_onVideoLinkChanged);
    super.dispose();
  }

  Widget _buildPreview() {
    final existingUrl = widget.existingCustomVideoUrl ?? '';

    if (widget.selectedVideoType == 0) {
      // Custom video: locally picked file takes priority, then fall back to
      // the existing remote URL (edit mode).
      if (widget.selectedVideoFile == null && existingUrl.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        height: 200.rh(context),
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: mui.Material(
            color: mui.Colors.transparent,
            child: CustomVideoPlayer(
              videoUrl: widget.selectedVideoFile == null ? existingUrl : null,
              videoFile: widget.selectedVideoFile,
            ),
          ),
        ),
      );
    }

    final activeController = widget.selectedVideoType == 1
        ? widget.youtubeController
        : widget.vimeoController;

    if (activeController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 200.rh(context),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: mui.Material(
          color: mui.Colors.transparent,
          child: CustomVideoPlayer(
            videoUrl: activeController.text.trim(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomText('videoPreview'.translate(context)),
        SizedBox(height: 8.rh(context)),
        CustomTabBar(
          tabController: _tabController,
          isScrollable: _tabs.length > 2,
          margin: EdgeInsets.zero,
          onTap: (index) {
            FocusScope.of(context).unfocus();
            widget.onValueChanged(_tabs[index].id);
            setState(() {
              _tabController.animateTo(index);
            });
          },
          tabs: _tabs.map((t) {
            return Tab(text: t.key.translate(context));
          }).toList(),
        ),
        SizedBox(height: 8.rh(context)),
        if (widget.selectedVideoType == 0)
          Builder(
            builder: (context) {
              final existingUrl = widget.existingCustomVideoUrl ?? '';
              final hasExistingUrl =
                  existingUrl.isNotEmpty && widget.selectedVideoFile == null;
              return GestureDetector(
                onTap: () async {
                  final result = await AppFilePicker.pickFile(
                    allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
                  );
                  if (result != null && result.path != null) {
                    final file = File(result.path!);
                    final fileSize = file.lengthSync();
                    const maxSize = 20 * 1024 * 1024; // 20MB
                    if (fileSize > maxSize) {
                      if (mounted) {
                        HelperUtils.showSnackBarMessage(
                          context,
                          '${'videoSizeLimit'.translate(context)} 20MB',
                          type: MessageType.error,
                        );
                      }
                      return;
                    }
                    widget.onFileSelected(file);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: context.color.borderColor),
                    borderRadius: BorderRadius.circular(4),
                    color: context.color.secondaryColor,
                  ),
                  padding: EdgeInsets.all(11.rw(context)),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          widget.selectedVideoFile?.path.split('/').last ??
                              (hasExistingUrl
                                  ? existingUrl.split('/').last
                                  : '${'selectVideo'.translate(context)} ${'maxVideoSize'.translate(context)}'),
                          maxLines: 1,
                          color:
                              (widget.selectedVideoFile != null ||
                                  hasExistingUrl)
                              ? context.color.textColorDark
                              : context.color.textLightColor,
                        ),
                      ),
                      SizedBox(width: 8.rw(context)),
                      if (widget.selectedVideoFile != null) ...[
                        // Clear locally picked file
                        GestureDetector(
                          onTap: () => widget.onFileSelected(null),
                          child: Icon(
                            Icons.close,
                            color: context.color.textColorDark,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 8.rw(context)),
                      ] else if (hasExistingUrl) ...[
                        // Remove existing remote video
                        GestureDetector(
                          onTap: () => widget.onRemoveVideo?.call(),
                          child: Icon(
                            Icons.close,
                            color: context.color.textColorDark,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 8.rw(context)),
                      ] else
                        CustomImage(
                          imageUrl: AppIcons.arrowRight,
                          color: context.color.textColorDark,
                          width: 24.rw(context),
                          height: 24.rh(context),
                          matchTextDirection: true,
                        ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          Builder(
            builder: (context) {
              final activeController = widget.selectedVideoType == 1
                  ? widget.youtubeController
                  : widget.vimeoController;
              return Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: activeController,
                      validator: CustomTextFieldValidator.link,
                      hintText: widget.selectedVideoType == 1
                          ? 'https://youtube.com/watch?v=...'
                          : 'https://vimeo.com/...',
                    ),
                  ),
                  if (activeController.text.trim().isNotEmpty) ...[
                    SizedBox(width: 8.rw(context)),
                    GestureDetector(
                      onTap: () {
                        activeController.clear();
                        widget.onRemoveVideo?.call();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.color.primaryColor.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: context.color.textColorDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        _buildPreview(),
      ],
    );
  }
}
