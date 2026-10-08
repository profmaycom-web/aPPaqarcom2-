import 'dart:math';

import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/model/chat_message_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

/// Audio message component that displays and handles audio playback
class AudioMessage extends ChatMessage {
  AudioMessage() {
    id = DateTime.now().toString();
    chatMessageType = 'audio';

    // Initialize audio player and listeners
    _audioPlayer = AudioPlayer();
    _initializeListeners();
  }

  // Audio state
  late AudioPlayer _audioPlayer;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<dynamic>? _errorSubscription;

  // Playback state
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = true;
  bool _hasError = false;
  bool _hasCompleted = false;
  Duration _duration = Duration.zero;

  // Value notifier for playback state to ensure UI updates
  final ValueNotifier<bool> playbackStateNotifier = ValueNotifier<bool>(false);

  // Static map to track all active audio players
  static final Map<String, AudioPlayer> _activePlayers = {};

  // Static map to the owning AudioMessage instance for each player, so
  // stopOtherPlayers() can flip their notifier synchronously instead of
  // relying solely on their playerStateStream event to arrive.
  static final Map<String, AudioMessage> _activeMessages = {};

  // Flag to prevent multiple initializations
  static final Set<String> _initializedMessageIds = {};

  // Map of audio MIME types
  static final Map<String, String> _audioMimeTypes = {
    'm4a': 'audio/mp4',
    'mp3': 'audio/mpeg',
    'mpeg': 'audio/mpeg',
    'mp4': 'audio/mp4',
  };

  // Helper method to get MIME type for a file - useful for debugging
  static String? getAudioMimeType(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final extension = path.substring(path.lastIndexOf('.') + 1).toLowerCase();
      return _audioMimeTypes[extension];
    } on Exception catch (e) {
      debugPrint('Error determining MIME type: $e');
      return null;
    }
  }

  // Static method to check if an audio message is playing
  static bool isPlaying(String messageId) {
    final player = _activePlayers[messageId];
    return player?.playing ?? false;
  }

  @override
  Future<void> init() async {
    // Skip initialization if this message has already been initialized
    if (_initializedMessageIds.contains(id)) {
      return;
    }

    try {
      // Mark this message as initialized
      _initializedMessageIds.add(id);
      debugPrint('Initializing audio message with ID: $id, URL: $audio');

      // Register this player
      _activePlayers[id] = _audioPlayer;
      _activeMessages[id] = this;

      // Try to load the audio if available
      if (audio != null && audio!.isNotEmpty) {
        await loadAudio();
      }

      // Sending is handled by the caller (ChatInputBar), which has a
      // BuildContext that is actually a descendant of SendMessageCubit's
      // provider. `context` here is ChatMessageHandler.messageContext, an
      // ancestor of that provider, so a send triggered from this method can
      // never resolve the cubit — do not attempt it here.
    } on Exception catch (e) {
      debugPrint('Error in init(): $e');
      _hasError = true;
    }

    super.init();
  }

  void _initializeListeners() {
    // Register listeners
    _processingStateSubscription = _audioPlayer.processingStateStream.listen(
      _processingStateListener,
    );
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      _playerStateListener,
    );
    _errorSubscription = _audioPlayer.errorStream.listen(
      (error) {
        debugPrint('Error playing audio $id: $error');
        _hasError = true;
      },
    );

    // Note: do NOT register in _activePlayers/_activeMessages here. This
    // runs from the constructor, before registerar.dart's cascade overwrites
    // the constructor's throwaway `id` with the real message id, so it would
    // register this instance under a stale key. init() (called once the
    // real id is set) does the registration instead. A stale extra entry
    // here made stopOtherPlayers() see this same instance as "some other
    // message" and pause itself right before its own pause branch ran,
    // which is why tapping pause instantly resumed playback.
  }

  Future<void> _processingStateListener(ProcessingState state) async {
    if (state == ProcessingState.ready) {
      _isBuffering = false;
      _isInitialized = true;
      _hasError = false;
      _hasCompleted = false;

      // Get duration
      await _updateDuration();
    } else if (state == ProcessingState.buffering) {
      _isBuffering = true;
      _hasCompleted = false;
    } else if (state == ProcessingState.completed) {
      _hasCompleted = true;
      _isPlaying = false;
    }
  }

  void _playerStateListener(PlayerState state) {
    _isPlaying = state.playing;
    debugPrint(
      'Player state change for message $id: ${state.processingState.name}, playing: ${state.playing}',
    );
    // if (state.processingState.name == 'completed') {
    //   _hasCompleted = true;
    //   _isPlaying = false;
    //   playbackStateNotifier.value = false;
    //   _audioPlayer..seek(Duration.zero)
    //   ..pause();
    // }

    // Update value notifier to trigger UI rebuild
    playbackStateNotifier.value = state.playing;
  }

  Future<void> _updateDuration() async {
    final duration = _audioPlayer.duration;
    if (duration != null) {
      _duration = duration;
      _isInitialized = true;
      debugPrint('Audio duration: ${_duration.inMilliseconds}ms');
    }
  }

  // Load and play audio from URL
  Future<void> loadAudio() async {
    if (_isInitialized && _audioPlayer.duration != null) return;

    try {
      _isBuffering = true;
      _hasError = false;

      debugPrint('Loading audio from URL for message $id: $audio');

      if (audio == null || audio!.isEmpty) {
        debugPrint('Audio URL is empty or null');
        _isBuffering = false;
        _hasError = true;
        return;
      }

      // Reset any previous audio source
      await _audioPlayer.stop();

      try {
        // Set timeout for audio loading to prevent indefinite waiting
        final audioLoadFuture = _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(audio!)),
        );

        // Apply a timeout to the audio loading process
        final result = await audioLoadFuture.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('Audio loading timed out after 15 seconds');
            _hasError = true;
            _isBuffering = false;
            throw TimeoutException('Audio loading timed out');
          },
        );

        if (result != null) {
          _duration = result;
          _isInitialized = true;
          _isBuffering = false;
          debugPrint(
            'Audio loaded successfully with duration: ${_duration.inSeconds}s',
          );
        } else {
          debugPrint('Audio loaded but duration is null');
          _isInitialized = true;
          _isBuffering = false;
        }
      } on Exception catch (e) {
        debugPrint('Failed to load audio: $e');

        // Try alternative method if the first one fails
        if (!_hasError || e is TimeoutException) {
          debugPrint('Attempting fallback method to load audio');
          try {
            final result = await _audioPlayer
                .setUrl(
                  audio!,
                )
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    debugPrint('Fallback audio loading timed out');
                    _hasError = true;
                    throw TimeoutException('Fallback audio loading timed out');
                  },
                );

            if (result != null) {
              _duration = result;
              _isInitialized = true;
              _isBuffering = false;
              _hasError = false;
              debugPrint(
                'Fallback audio loaded successfully: ${_duration.inSeconds}s',
              );
            } else {
              _hasError = true;
            }
          } on Exception catch (fallbackError) {
            debugPrint('Fallback audio loading failed: $fallbackError');
            _hasError = true;
          }
        } else {
          _hasError = true;
        }

        _isBuffering = false;
      }
    } on Exception catch (e) {
      debugPrint('Error in loadAudio: $e');
      _hasError = true;
      _isBuffering = false;
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    try {
      // Stop all other players
      await stopOtherPlayers();

      if (_hasError) {
        // Retry loading if there was an error
        _hasError = false;
        await loadAudio();
        // Wait a moment for initialization
        await Future<dynamic>.delayed(const Duration(milliseconds: 300));
        if (!_hasError && _isInitialized) {
          await _audioPlayer.play();
          _isPlaying = true;
          playbackStateNotifier.value = true;
        }
        return;
      }

      // If already playing, just pause
      if (_isPlaying) {
        debugPrint('Pausing audio for message $id');
        await _audioPlayer.pause();
        _isPlaying = false;
        playbackStateNotifier.value = false;
        return;
      }

      // If completed, seek to beginning
      if (_hasCompleted) {
        await _audioPlayer.seek(Duration.zero);
        _hasCompleted = false;
      }

      // If not initialized, start loading
      if (!_isInitialized) {
        debugPrint('Audio not initialized, loading for message $id...');
        await loadAudio();
        // Wait a moment for initialization
        await Future<dynamic>.delayed(const Duration(milliseconds: 300));
      }

      // Play the audio only if it's properly initialized
      if (_isInitialized && !_hasError) {
        debugPrint('Playing audio for message $id');
        await _audioPlayer.play();
        _isPlaying = true;
        playbackStateNotifier.value = true;
      } else {
        debugPrint(
          'Cannot play audio: initialized=$_isInitialized, hasError=$_hasError',
        );
      }
    } on Exception catch (e) {
      debugPrint('Error in togglePlayPause: $e');
      _hasError = true;
      playbackStateNotifier.value = false;
    }
  }

  // Stop all other playing audio
  Future<void> stopOtherPlayers() async {
    for (final entry in _activeMessages.entries) {
      if (entry.key != id) {
        await entry.value._pauseIfPlaying();
      }
    }
  }

  // Pauses this instance's player (if playing) and flips its own playing
  // state and notifier immediately. Called on OTHER instances by
  // stopOtherPlayers(); their playerStateStream would eventually catch up
  // to the same result, but that's an async race against the new player
  // starting, which showed up as the old bubble's icon getting stuck on
  // "pause" instead of flipping back to "play" right away.
  Future<void> _pauseIfPlaying() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    }
    if (_isPlaying) {
      _isPlaying = false;
      playbackStateNotifier.value = false;
    }
  }

  @override
  Future<void> onRemove() async {
    await context!.read<DeleteMessageCubit>().delete(
      messageId: id,
      receiverId: receiverId!,
      senderId: '',
      propertyId: '',
    );
    super.onRemove();
  }

  @override
  void dispose() {
    debugPrint('Disposing audio player for message $id');

    // Cancel all subscriptions
    unawaited(_processingStateSubscription?.cancel());
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());

    // Remove from active players map
    _activePlayers.remove(id);
    _activeMessages.remove(id);

    // Dispose of player
    unawaited(
      _audioPlayer.stop().then((_) async {
        await _audioPlayer.dispose();
      }),
    );

    super.dispose();
  }

  // Static method to clear initialization flags (useful for refreshing the chat)
  static void clearInitFlags() {
    _initializedMessageIds.clear();
  }

  @override
  Widget render(BuildContext context) {
    return Align(
      alignment: isSentByMe
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerStart,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          // Audio player UI
          Row(
            mainAxisSize: .min,
            children: [
              // Play/Pause button
              _buildPlayButton(context),
              // Progress bar and duration
              Expanded(child: _buildPositionSlider(context)),
              _buildDurationText(context),
            ],
          ),

          // Message sending indicator
          if (isSentNow && isSentByMe)
            BlocBuilder<SendMessageCubit, SendMessageState>(
              builder: (context, state) {
                if (state is SendMessageInProgress) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.color.tertiaryColor,
                          ),
                        ),
                        SizedBox(width: 4.rw(context)),
                        Text(
                          'Sending...',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.color.textColorDark.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  // Build play/pause button
  Widget _buildPlayButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: playbackStateNotifier,
      builder: (context, isPlaying, _) {
        final iconColor = isSentByMe
            ? Color.lerp(
                context.color.tertiaryColor,
                Colors.white,
                0.8,
              )
            : context.color.tertiaryColor;
        // Error state
        if (_hasError) {
          return GestureDetector(
            onTap: () async {
              // Retry loading
              debugPrint('Retrying audio load on user request');
              await loadAudio();
            },
            child: Icon(
              Icons.refresh,
              color: context.color.error,
              size: 28,
            ),
          );
        }

        // Loading/buffering state
        if (_isBuffering) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
              ),
            ),
          );
        }

        // Play/pause button
        return GestureDetector(
          onTap: togglePlayPause,
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow_rounded,
            color: iconColor,
            size: 30,
          ),
        );
      },
    );
  }

  Widget _buildPositionSlider(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final value = _duration.inMilliseconds > 0
            ? min(
                position.inMilliseconds.toDouble(),
                _duration.inMilliseconds.toDouble(),
              )
            : 0.0;
        final thumbColor = isSentByMe
            ? Color.lerp(
                context.color.tertiaryColor,
                Colors.white,
                0.8,
              )
            : context.color.tertiaryColor;
        return SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: thumbColor,
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.5),
            thumbColor: thumbColor,
            overlayColor: thumbColor!.withValues(alpha: 0.2),
          ),
          child: Slider(
            max: _duration.inMilliseconds.toDouble(),
            value: value,
            onChanged: (value) async {
              if (_isInitialized) {
                await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              }
            },
          ),
        );
      },
    );
  }

  // Build duration text
  Widget _buildDurationText(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;

        return CustomText(
          _formatDuration(_duration, position),
          fontSize: 12,
          color: isSentByMe
              ? context.color.buttonColor
              : context.color.textColorDark.withValues(alpha: 0.7),
        );
      },
    );
  }
}

// Format duration to mm:ss
String _formatDuration(Duration duration, Duration position) {
  final minutes = position != Duration.zero
      ? position.inMinutes.remainder(60).toString().padLeft(2, '0')
      : duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = position != Duration.zero
      ? position.inSeconds.remainder(60).toString().padLeft(2, '0')
      : duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Class representing position data for audio playback
class PositionData {
  PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}
