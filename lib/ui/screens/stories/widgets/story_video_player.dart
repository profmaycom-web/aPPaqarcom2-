import 'package:ebroker/exports/main_export.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

/// Bare, controls-free video player for story playback. Renders only the
/// video frame — no seek bar, no play/pause icon, no gestures of its own.
/// All interaction is owned by the caller via [onReady]/[onEnded]/[onError]
/// and the imperative play/pause methods on [StoryVideoPlayerState].
class StoryVideoPlayer extends StatefulWidget {
  const StoryVideoPlayer({
    required this.videoUrl,
    required this.onReady,
    required this.onEnded,
    required this.onError,
    super.key,
  });

  final String? videoUrl;
  final void Function(Duration duration) onReady;
  final VoidCallback onEnded;
  final VoidCallback onError;

  @override
  State<StoryVideoPlayer> createState() => StoryVideoPlayerState();
}

class StoryVideoPlayerState extends State<StoryVideoPlayer> {
  VideoPlayerController? _controller;
  bool _endedFired = false;
  // Bumped on every _loadVideo call so a superseded in-flight load (an old
  // dispose/initialize still awaiting when a newer story arrives) can tell
  // it's stale and bail out instead of racing the newer one for the native
  // decoder — see story_viewer_screen.dart's stable _videoPlayerKey comment.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadVideo(widget.videoUrl));
  }

  @override
  void didUpdateWidget(covariant StoryVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      unawaited(_loadVideo(widget.videoUrl));
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onPositionChanged);
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  Future<void> _loadVideo(String? url) async {
    final generation = ++_generation;

    // Fully await disposal of the previous controller before creating the
    // next one — creating a new native decoder while the old one is still
    // tearing down is what caused the freeze/no-audio bug this fixes.
    final previous = _controller;
    if (previous != null) {
      previous.removeListener(_onPositionChanged);
      if (mounted) setState(() => _controller = null);
      await previous.dispose();
    }
    if (!mounted || generation != _generation) return;

    _endedFired = false;
    if (url == null || url.trim().isEmpty) {
      widget.onError();
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
    } on Exception {
      await controller.dispose();
      if (mounted && generation == _generation) widget.onError();
      return;
    }
    if (!mounted || generation != _generation) {
      await controller.dispose();
      return;
    }
    await controller.setVolume(1);
    controller.addListener(_onPositionChanged);
    setState(() => _controller = controller);
    widget.onReady(controller.value.duration);
  }

  void _onPositionChanged() {
    final controller = _controller;
    if (controller == null || _endedFired) return;
    final value = controller.value;
    if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _endedFired = true;
      widget.onEnded();
    }
  }

  void play() => _controller?.play();

  void pause() => _controller?.pause();

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
