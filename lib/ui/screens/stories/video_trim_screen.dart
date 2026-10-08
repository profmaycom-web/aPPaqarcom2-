import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/stories/widgets/add_story_appbar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';

// Raw source videos have no inherent size/duration limit from the file
// picker, but the trimmer fully decodes the source into memory (video_player
// + native thumbnailer) before any trimming happens. Very long source clips
// can exhaust native memory and crash the process outside Dart's reach, so
// reject them before decode rather than let that happen.
const Duration _maxSourceVideoDuration = Duration(minutes: 5);

// Mirrors StoryReviewScreen's media size cap — applied here too as a
// defensive re-check on the trimmed output (see class doc below).
const int _maxTrimmedMediaSizeBytes = 100 * 1024 * 1024;

/// Trimmed video file plus its final clipped duration (whole seconds,
/// rounded), so callers can send `duration_seconds` explicitly on upload
/// instead of relying on the viewer's fallback.
class TrimmedVideoResult {
  const TrimmedVideoResult({required this.file, required this.durationSeconds});

  final File file;
  final int durationSeconds;
}

class VideoTrimScreen extends StatefulWidget {
  const VideoTrimScreen({required this.rawVideo, super.key});

  final File rawVideo;

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  final Trimmer _trimmer = Trimmer();
  bool _isLoaded = false;
  bool _loadFailed = false;
  bool _videoTooLong = false;
  bool _isSaving = false;
  bool _isPlaying = false;
  double _startValue = 0;
  double _endValue = 0;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget, matching the package's own example: TrimViewer and
    // VideoViewer must already be mounted (below, unconditionally) before
    // this completes, otherwise their internal `eventStream` listener
    // subscribes after `loadVideo` has already broadcast `initialized` and
    // never recovers — the trim UI silently stays empty forever.
    unawaited(_loadVideo());
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      await _trimmer.loadVideo(videoFile: widget.rawVideo);
      final duration = _trimmer.videoPlayerController?.value.duration;
      if (duration != null && duration > _maxSourceVideoDuration) {
        if (mounted) setState(() => _videoTooLong = true);
        return;
      }
      if (mounted) setState(() => _isLoaded = true);
    } on Exception {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  // ScrollableTrimViewer requires
  // `maxVideoLength * (1 + 2 * paddingFraction) <= totalVideoDuration`,
  // otherwise it throws. The admin-configured max (e.g. 60s) must win
  // whenever the source video is at least that long — only shrink it when
  // the video itself is shorter (nothing to select beyond its own length).
  // Padding is what flexes to satisfy the package's precondition, never
  // the configured max.
  static const double _defaultPaddingFraction = 0.2;

  Duration _effectiveMaxVideoLength() {
    final configured = Duration(seconds: AppSettings.storyMaxDurationSeconds);
    final totalDuration = _trimmer.videoPlayerController?.value.duration;
    if (totalDuration == null || totalDuration <= Duration.zero) {
      return configured;
    }
    return totalDuration < configured ? totalDuration : configured;
  }

  double _effectivePaddingFraction() {
    final totalDuration = _trimmer.videoPlayerController?.value.duration;
    final maxLength = _effectiveMaxVideoLength();
    if (totalDuration == null || maxLength.inMilliseconds == 0) {
      return _defaultPaddingFraction;
    }
    final allowed =
        (totalDuration.inMilliseconds / maxLength.inMilliseconds - 1) / 2;
    if (allowed <= 0) return 0;
    return allowed < _defaultPaddingFraction
        ? allowed
        : _defaultPaddingFraction;
  }

  Future<void> _onTapPlayPause() async {
    final playing = await _trimmer.videoPlaybackControl(
      startValue: _startValue,
      endValue: _endValue,
    );
    if (mounted) setState(() => _isPlaying = playing);
  }

  Future<void> _onTapSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      String? outputPath;
      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        onSave: (path) => outputPath = path,
      );
      if (outputPath == null) {
        throw Exception('Trim output path was null');
      }
      final trimmedFile = File(outputPath!);
      if (!trimmedFile.existsSync()) {
        throw Exception('Trim output file not found at "$outputPath"');
      }
      if (trimmedFile.lengthSync() > _maxTrimmedMediaSizeBytes) {
        if (!mounted) return;
        HelperUtils.showSnackBarMessage(
          context,
          'mediaFileTooLarge',
          type: .error,
        );
        setState(() => _isSaving = false);
        return;
      }
      if (!mounted) return;
      final trimmedSeconds = ((_endValue - _startValue) / 1000).round();
      Navigator.pop(
        context,
        TrimmedVideoResult(
          file: trimmedFile,
          durationSeconds: trimmedSeconds < 1 ? 1 : trimmedSeconds,
        ),
      );
    } on Exception {
      if (!mounted) return;
      HelperUtils.showSnackBarMessage(
        context,
        'videoTrimFailed',
        type: .error,
      );
      setState(() => _isSaving = false);
    }
  }

  Widget _buildCoverVideo() {
    final controller = _trimmer.videoPlayerController;
    if (controller == null || !controller.value.isInitialized) {
      return VideoViewer(trimmer: _trimmer);
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.buttonColor,
      body: _loadFailed || _videoTooLong
          ? Column(
              children: [
                const AddStoryAppbar(),
                Expanded(
                  child: Center(
                    child: CustomText(
                      _videoTooLong
                          ? 'videoTooLongToTrim'.translate(context)
                          : 'videoTrimFailed'.translate(context),
                      color: context.color.textColorDark,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(child: _buildCoverVideo()),
                      if (!_isLoaded) UiUtils.progress(),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: AddStoryAppbar(),
                        ),
                      ),
                      if (_isLoaded)
                        Positioned(
                          right: 16.rw(context),
                          bottom: 16.rh(context),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.color.textColorDark.withValues(
                                alpha: 0.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => unawaited(_onTapPlayPause()),
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                    ),
                    child: SingleChildScrollView(child: bodyItems()),
                  ),
                ),
              ],
            ),
    );
  }

  Widget bodyItems() {
    return Container(
      decoration: BoxDecoration(
        color: context.color.buttonColor,
        borderRadius: .vertical(top: .circular(16.rw(context))),
      ),
      padding: .all(16.rw(context)),
      child: Column(
        children: [
          SizedBox(height: 12.rh(context)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.color.tertiaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomText(
                  '${(_endValue - _startValue) ~/ 1000} '
                  '${'secLabel'.translate(context)}',
                  color: context.color.buttonColor,
                  fontSize: context.font.xxs,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8.rw(context)),
              Expanded(
                child: CustomText(
                  'slideForPerfectClip'.translate(context),
                  color: context.color.textLightColor,
                  fontSize: context.font.xs,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.rh(context)),
          TrimViewer(
            trimmer: _trimmer,
            // `_effectiveMaxVideoLength` keeps the scrollable editor's own
            // duration precondition satisfied, so `auto` always picks it —
            // forcing `ViewerType.scrollable` explicitly is riskier: that
            // path throws (leaving the widget permanently blank) on any
            // tiny rounding mismatch against the package's internal formula.
            showDuration: false,
            editorProperties: TrimEditorProperties(
              borderWidth: 4,
              borderPaintColor: context.color.tertiaryColor,
              circleSize: 8.rw(context),
              circleSizeOnDrag: 12.rw(context),
              circlePaintColor: context.color.tertiaryColor,
            ),
            viewerWidth: MediaQuery.sizeOf(context).width - 32.rw(context),
            viewerHeight: 57.rh(context),
            paddingFraction: _effectivePaddingFraction(),
            maxVideoLength: _effectiveMaxVideoLength(),
            onChangeStart: (value) => _startValue = value,
            onChangeEnd: (value) => _endValue = value,
            onChangePlaybackState: (value) =>
                setState(() => _isPlaying = value),
          ),
          SizedBox(height: 16.rh(context)),
          UiUtils.buildButton(
            context,
            buttonTitle: 'continue'.translate(context),
            isInProgress: _isSaving,
            onPressed: () {
              if (_isLoaded) unawaited(_onTapSave());
            },
          ),
        ],
      ),
    );
  }
}
