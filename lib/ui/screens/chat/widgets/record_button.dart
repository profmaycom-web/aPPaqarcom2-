import 'dart:async';
import 'dart:io';

import 'package:ebroker/ui/screens/chat/helpers/flow_shader.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    required this.controller,
    required this.callback,
    required this.isSending,
    super.key,
  });

  final AnimationController controller;
  final dynamic Function(dynamic path)? callback;
  final bool isSending;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  late Animation<double> buttonScaleAnimation;

  DateTime? startTime;
  Timer? timer;
  String recordDuration = '00:00';
  AudioRecorder? record;
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();

  bool isLocked = false;

  // Tracks the press gesture itself (true from onLongPressDown until
  // release/cancel), independent of `timer`. `timer` only starts once the
  // long-press is fully recognized AND the async permission check and
  // record.start() both resolve, so gating the lock/cancel overlay on it
  // made them appear ~1s after the finger actually went down instead of
  // right away alongside the button's own scale-up animation.
  bool _isPressing = false;

  static String documentPath = '';

  @override
  void initState() {
    super.initState();
    unawaited(getDocumentPath());
    buttonScaleAnimation = Tween<double>(begin: 1, end: 1.5).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticInOut),
        // Without an explicit reverseCurve, reverse() replays the same
        // Interval(0, 0.6) window: that interval only maps active output
        // below controller value 0.6, so on release the scale stayed
        // pinned at max for the first ~40% of the animation before it
        // even started shrinking. A full-range curve here lets it shrink
        // immediately as soon as the controller starts reversing.
        reverseCurve: Curves.easeOut,
      ),
    );
    record = AudioRecorder();
    // Must call setState on every tick: buttonScaleAnimation/timerAnimation/
    // lockerAnimation values are read directly in build(), so without a
    // listener that actually schedules a rebuild, the scale/slide only ever
    // updates opportunistically when something unrelated (e.g. the 1s
    // duration timer) happens to call setState. Cancelling recording stops
    // that timer immediately, so the reverse animation had nothing left to
    // trigger a repaint and the button appeared frozen at its last value.
    widget.controller.addListener(_onControllerTick);
  }

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  Future<void> getDocumentPath() async {
    documentPath = '${(await getApplicationDocumentsDirectory()).path}/';
  }

  @override
  void dispose() {
    // The controller is owned by the parent (ChatInputBar) and outlives
    // this State, so it must stop calling back into a disposed State.
    widget.controller.removeListener(_onControllerTick);

    // If the widget is torn down mid-recording (e.g. user backs out of the
    // chat), make sure the OS recording session is actually stopped before
    // disposing the recorder, otherwise the mic can be left held open.
    if (record != null) {
      final activeRecorder = record!;
      unawaited(
        (timer?.isActive ?? false)
            ? activeRecorder.stop().then((_) => activeRecorder.dispose())
            : activeRecorder.dispose(),
      );
    }
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showRecordingControls = _isPressing && !isLocked && !widget.isSending;
    return Stack(
      clipBehavior: .none,
      children: [
        lockSlider(show: showRecordingControls),
        cancelSlider(show: showRecordingControls),
        audioButton(),
        if (isLocked && !widget.isSending) timerLocked(),
      ],
    );
  }

  Widget lockSlider({required bool show}) {
    final iconColor = context.color.textColorDark;
    return PositionedDirectional(
      end: -10,
      bottom: kBottomNavigationBarHeight,
      child: AnimatedScale(
        scale: show ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: .all(8.rw(context)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: context.color.secondaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: .spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.color.tertiaryColor.withValues(alpha: .15),
                ),
                child: Icon(Icons.lock_outline, size: 18, color: iconColor),
              ),
              FlowShader(
                direction: .vertical,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Icon(Icons.keyboard_arrow_up, color: iconColor, size: 20),
                    Icon(Icons.keyboard_arrow_up, color: iconColor, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cancelSlider({required bool show}) {
    return PositionedDirectional(
      end: kBottomNavigationBarHeight - 10,
      top: -10,
      child: AnimatedScale(
        scale: show ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: .all(12.rw(context)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: context.color.primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
            child: Row(
              // mainAxisSize.max (the default) is required here so that
              // mainAxisAlignment.end actually has room to push the hint
              // toward the mic button's side of the bar - with .min the
              // content instead hugs the row's logical start, which in
              // RTL lands on the opposite physical side from the mic
              // button and looks completely detached from it.
              mainAxisAlignment: .end,
              children: [
                CustomText(recordDuration),
                SizedBox(width: 10.rw(context)),
                FlowShader(
                  duration: const Duration(seconds: 3),
                  flowColors: [
                    context.color.tertiaryColor,
                    const Color(0xFF9E9E9E),
                  ],
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      const Icon(Icons.keyboard_arrow_left, size: 20),
                      CustomText('slidetocancel'.translate(context)),
                    ],
                  ),
                ),
                SizedBox(width: 10.rw(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget timerLocked() {
    return PositionedDirectional(
      end: -15,
      bottom: -15,
      child: Container(
        height: 60,
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: GestureDetector(
          behavior: .opaque,
          onTap: () async {
            setState(() {
              isLocked = false;
            });
            await saveFile();
          },
          child: Row(
            mainAxisSize: .min,
            mainAxisAlignment: .end,
            children: [
              CustomText(recordDuration),
              SizedBox(width: 5.rw(context)),
              FlowShader(
                duration: const Duration(seconds: 3),
                flowColors: [context.color.tertiaryColor, Colors.red],
                child: CustomText('taploacktostop'.translate(context)),
              ),
              SizedBox(width: 10.rw(context)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.color.tertiaryColor.withValues(alpha: .15),
                ),
                child: Icon(
                  Icons.lock,
                  size: 18,
                  color: context.color.tertiaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget audioButton() {
    return GestureDetector(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: buttonScaleAnimation.value,
        child: widget.isSending
            ? SizedBox(
                width: 20.rw(context),
                height: 20.rh(context),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.color.buttonColor,
                  ),
                ),
              )
            : CustomImage(
                imageUrl: AppIcons.mic,
                color: context.color.buttonColor,
              ),
      ),
      onTap: () async {
        HelperUtils.showSnackBarMessage(
          context,
          'longPressToRecord',
          type: .warning,
          messageDuration: 2,
        );
      },
      onLongPressDown: (_) {
        if (widget.isSending) return;
        debugPrint('onLongPressDown');
        setState(() => _isPressing = true);
        widget.controller.forward();
      },
      onLongPressEnd: (details) async {
        if (widget.isSending) return;
        debugPrint('onLongPressEnd');
        setState(() => _isPressing = false);

        if (isCancelled(details.localPosition, context)) {
          // if (await Vibrate.canVibrate) Vibrate.feedback(FeedbackType.heavy);

          timer?.cancel();
          timer = null;
          startTime = null;
          recordDuration = '00:00';

          await widget.controller.reverse();
          debugPrint('Cancelled recording');
          final filePath = await record!.stop();
          debugPrint(filePath);
          await File(filePath!).delete();
          debugPrint('Deleted $filePath');
        } else if (checkIsLocked(details.localPosition)) {
          await widget.controller.reverse();

          // if (await Vibrate.canVibrate) Vibrate.feedback(FeedbackType.heavy);
          debugPrint('Locked recording');
          debugPrint(details.localPosition.dy.toString());
          setState(() {
            isLocked = true;
          });
        } else {
          await widget.controller.reverse();
          await saveFile();
        }
      },
      onLongPressCancel: () async {
        if (widget.isSending) return;
        debugPrint('onLongPressCancel');
        setState(() => _isPressing = false);
        await widget.controller.reverse();
      },
      onLongPress: () async {
        if (widget.isSending) return;
        debugPrint('onLongPress');
        // if (await Vibrate.canVibrate) Vibrate.feedback(FeedbackType.success);
        final isPermission = await record!.hasPermission();
        if (isPermission) {
          await record!.start(
            const RecordConfig(),
            path:
                '${documentPath}audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
          );
          startTime = DateTime.now();
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            final minDur = DateTime.now().difference(startTime!).inMinutes;
            final secDur = DateTime.now().difference(startTime!).inSeconds % 60;
            final min = minDur < 10 ? '0$minDur' : minDur.toString();
            final sec = secDur < 10 ? '0$secDur' : secDur.toString();
            setState(() {
              recordDuration = '$min:$sec';
            });
          });
        }
      },
    );
  }

  Future<void> saveFile() async {
    // if (await Vibrate.canVibrate) Vibrate.feedback(FeedbackType.success);
    // Must go through setState: these fields drive the lock/cancel overlay
    // visibility in build(), so mutating them silently left stale overlays
    // on screen (frozen mid-recording UI) while the audio then uploaded.
    if (mounted) {
      setState(() {
        timer?.cancel();
        timer = null;
        startTime = null;
        recordDuration = '00:00';
        isLocked = false;
      });
    } else {
      timer?.cancel();
      timer = null;
    }

    final filePath = await record?.stop();
    AudioState.files.add(filePath!);
    if (audioListKey.currentState != null) {
      audioListKey.currentState!.insertItem(AudioState.files.length - 1);
    }
    debugPrint(filePath);
    if (widget.callback != null) {
      widget.callback?.call(filePath);
    }
  }

  bool checkIsLocked(Offset offset) {
    return offset.dy < -18;
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return offset.dx < -(MediaQuery.of(context).size.width * 0.2);
  }
}

/// Choosing this method because using proper state management would be an
/// overkill for the scope of this project.
class AudioState {
  AudioState._();
  static List<String> files = [];
}
