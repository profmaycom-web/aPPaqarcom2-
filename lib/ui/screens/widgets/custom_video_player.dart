import 'package:ebroker/exports/main_export.dart';
//TODO (p) remove import
//import 'package:material_ui/material_ui.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  const CustomVideoPlayer({
    super.key,
    this.videoUrl,
    this.videoFile,
    this.autoPlay = false,
    this.autoMute = true,
    this.showFullScreenButton = true,
  });

  final String? videoUrl;
  final File? videoFile;
  final bool autoPlay;
  final bool autoMute;
  final bool showFullScreenButton;

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();

  static Future<void> showFullScreenDialog(
    BuildContext context, {
    String? videoUrl,
    File? videoFile,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CustomVideoPlayer(
                  videoUrl: videoUrl,
                  videoFile: videoFile,
                  autoPlay: true,
                ),
              ),
            ),
            PositionedDirectional(
              top: 40,
              end: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  // Incremented to force a full player rebuild on error recovery.
  int _playerKey = 0;
  OmniPlaybackController? _controller;
  bool _recoveryPending = false;
  int _recoveryAttempts = 0;
  static const _maxRecoveryAttempts = 3;

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerCreated(OmniPlaybackController controller) {
    _controller?.removeListener(_onControllerChanged);
    _controller = controller;
    controller.addListener(_onControllerChanged);
    _recoveryAttempts = 0;
  }

  // Called when the ExoPlayer surface is lost during screen recording start
  // on Android (SurfaceProducer.onSurfaceCleanup triggers a playback error).
  // Recovery: force-rebuild the OmniVideoPlayer with a new key so the player
  // re-initialises from scratch with a fresh surface.
  void _onControllerChanged() {
    if ((_controller?.hasError ?? false) &&
        !_recoveryPending &&
        _recoveryAttempts < _maxRecoveryAttempts) {
      _recoveryPending = true;
      _recoveryAttempts++;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _playerKey++;
            _recoveryPending = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    VideoSourceConfiguration? source;

    if (widget.videoFile != null) {
      source = VideoSourceConfiguration.file(
        videoFile: widget.videoFile!,
      );
    } else if (widget.videoUrl != null && widget.videoUrl!.trim().isNotEmpty) {
      final url = widget.videoUrl!.trim();
      if (HelperUtils.isYoutubeVideo(url)) {
        source =
            VideoSourceConfiguration.youtube(
              videoUrl: Uri.parse(url),
            ).copyWith(
              autoPlay: widget.autoPlay,
              autoMuteOnStart: widget.autoMute,
              initialVolume: widget.autoMute ? 0 : null,
            );
      } else if (HelperUtils.isVimeoVideo(url)) {
        source =
            VideoSourceConfiguration.vimeo(
              videoId: HelperUtils.getVimeoVideoId(url) ?? '',
            ).copyWith(
              autoPlay: widget.autoPlay,
              autoMuteOnStart: widget.autoMute,
              initialVolume: widget.autoMute ? 0 : null,
            );
      } else {
        try {
          source =
              VideoSourceConfiguration.network(
                videoUrl: Uri.parse(url),
              ).copyWith(
                autoPlay: widget.autoPlay,
                autoMuteOnStart: widget.autoMute,
                initialVolume: widget.autoMute ? 0 : null,
              );
        } on Exception catch (_) {
          // Invalid URI
        }
      }
    }

    if (source == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: OmniVideoPlayer(
        key: ValueKey('${widget.videoUrl ?? widget.videoFile?.path}-$_playerKey'),
        callbacks: VideoPlayerCallbacks(
          onControllerCreated: _onControllerCreated,
          onFullScreenToggled: (isFullScreen) async {
            if (!isFullScreen) {
              await SystemChrome.setPreferredOrientations([
                .portraitUp,
              ]);
              await SystemChrome.setEnabledSystemUIMode(
                .manual,
                overlays: [.top, .bottom],
              );
            }
          },
        ),
        configuration: VideoPlayerConfiguration(
          videoSourceConfiguration: source,
          playerTheme: .new(
            colors: VideoPlayerColorScheme(
              thumb: context.color.tertiaryColor,
              active: context.color.tertiaryColor,
              menuText: context.color.textColorDark,
              menuBackground: context.color.secondaryColor,
              menuTextSelected: context.color.tertiaryColor,
            ),
          ),
          playerUIVisibilityOptions: const PlayerUIVisibilityOptions().copyWith(
            showFullScreenButton: widget.showFullScreenButton,
            fitVideoToBounds: false,
            enableExitFullscreenOnVerticalSwipe: true,
            controlsPersistenceDuration: const Duration(milliseconds: 1500),
            enableOrientationLock: false,
          ),
        ),
      ),
    );
  }
}
