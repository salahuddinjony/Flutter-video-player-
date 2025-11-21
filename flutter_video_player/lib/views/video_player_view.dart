import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart' as video_player;
import '../controllers/video_player_controller.dart' as vpc;
import '../controllers/instruction_controller.dart';
import 'dart:async';

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (mounted) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _showControls = true);
        }
      });
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoController = Get.find<vpc.VideoPlayerController>();
    final instructionController = Get.find<InstructionController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => _resetHideControlsTimer(),
        child: Obx(() {
          if (instructionController.isLoading) {
            return _buildLoadingState();
          }

          final player = videoController.currentPlayer;
          if (player == null || !player.value.isInitialized) {
            return _buildLoadingVideoState(videoController, instructionController);
          }

          // Double check player is still valid before building
          try {
            // Access a property to check if disposed
            final _ = player.value.aspectRatio;
            return _buildVideoPlayer(videoController, instructionController);
          } catch (e) {
            // Player was disposed, show loading state
            return _buildLoadingVideoState(videoController, instructionController);
          }
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading instructions...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingVideoState(
    vpc.VideoPlayerController videoController,
    InstructionController instructionController,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library,
                size: 64,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              videoController.errorMessage.isNotEmpty
                  ? videoController.errorMessage
                  : 'Loading video...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (instructionController.statusMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  instructionController.statusMessage,
                  style: TextStyle(
                    color: Colors.blue.shade200,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Playlist: ${videoController.playlist.length} video(s)',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(
    vpc.VideoPlayerController videoController,
    InstructionController instructionController,
  ) {
    // Schedule the timer reset after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetHideControlsTimer();
    });

    final player = videoController.currentPlayer;
    if (player == null || !player.value.isInitialized) {
      return _buildLoadingVideoState(videoController, instructionController);
    }

    // Safely check player size
    try {
      // Access size to verify player is still valid
      final _ = player.value.size;
    } catch (e) {
      // Player was disposed, return loading state
      return _buildLoadingVideoState(videoController, instructionController);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player - fill the entire screen
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: player.value.size.width,
              height: player.value.size.height,
              child: video_player.VideoPlayer(player),
            ),
          ),
        ),

        // Gradient overlay for better text visibility
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Error message overlay (top)
        if (videoController.errorMessage.isNotEmpty)
          _buildErrorMessage(videoController),

        // Status message overlay (below error)
        if (instructionController.statusMessage.isNotEmpty &&
            !instructionController.isLoading)
          _buildStatusMessage(instructionController, videoController),

        // Video controls overlay
        if (_showControls) _buildControlsOverlay(videoController),

        // Play/Pause button (center, always visible on tap)
        _buildPlayPauseButton(videoController),

        // Bottom controls bar with progress and navigation
        if (_showControls) _buildBottomControlsBar(videoController),
      ],
    );
  }

  Widget _buildErrorMessage(vpc.VideoPlayerController videoController) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  videoController.errorMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(
    InstructionController instructionController,
    vpc.VideoPlayerController videoController,
  ) {
    final topOffset = videoController.errorMessage.isNotEmpty ? 80.0 : 16.0;
    return Positioned(
      top: MediaQuery.of(context).padding.top + topOffset,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  instructionController.statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(vpc.VideoPlayerController videoController) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
              stops: const [0.0, 0.2, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(vpc.VideoPlayerController videoController) {
    return Center(
      child: GestureDetector(
        onTap: () {
          videoController.togglePlayPause();
          _resetHideControlsTimer();
        },
        child: Obx(() => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_showControls ? 0.6 : 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                videoController.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: _showControls ? 72 : 56,
                color: Colors.white.withOpacity(0.9),
              ),
            )),
      ),
    );
  }

  Widget _buildBottomControlsBar(vpc.VideoPlayerController videoController) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar with time
            _buildProgressBar(videoController),
            const SizedBox(height: 8),
            // Control buttons
            _buildControlButtons(videoController),
            const SizedBox(height: 8),
            // Info bar
            _buildInfoBar(videoController),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(vpc.VideoPlayerController videoController) {
    return Obx(() {
      // Access observable values directly
      final position = videoController.position.value;
      final duration = videoController.duration.value;
      final progress = duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Progress slider
            GestureDetector(
              onTapDown: (details) async {
                final RenderBox? box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final x = details.localPosition.dx;
                final width = box.size.width;
                final newProgress = (x / width).clamp(0.0, 1.0);
                final newPosition = Duration(
                  milliseconds: (duration.inMilliseconds * newProgress).round(),
                );
                await videoController.seekTo(newPosition);
                _resetHideControlsTimer();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Stack(
                      children: [
                        // Progress indicator
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Draggable thumb
                        Positioned(
                          left: (constraints.maxWidth * progress).clamp(0.0, constraints.maxWidth - 16),
                          top: -6,
                          child: GestureDetector(
                            onPanUpdate: (details) async {
                              final delta = details.delta.dx;
                              final currentProgress = (progress * constraints.maxWidth + delta) / constraints.maxWidth;
                              final clampedProgress = currentProgress.clamp(0.0, 1.0);
                              final newPosition = Duration(
                                milliseconds: (duration.inMilliseconds * clampedProgress).round(),
                              );
                              await videoController.seekTo(newPosition);
                              _resetHideControlsTimer();
                            },
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            // Time indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildControlButtons(vpc.VideoPlayerController videoController) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: videoController.currentIndex > 0 || videoController.isLooping
                ? () {
                    videoController.previousVideo();
                    _resetHideControlsTimer();
                  }
                : null,
            icon: const Icon(Icons.skip_previous, color: Colors.white),
            iconSize: 32,
            tooltip: 'Previous video',
          ),
          const SizedBox(width: 16),
          // Play/Pause button
          Obx(() => IconButton(
                onPressed: () {
                  videoController.togglePlayPause();
                  _resetHideControlsTimer();
                },
                icon: Icon(
                  videoController.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                ),
                iconSize: 48,
                tooltip: videoController.isPlaying ? 'Pause' : 'Play',
              )),
          const SizedBox(width: 16),
          // Next button
          IconButton(
            onPressed: videoController.currentIndex < videoController.playlist.length - 1 ||
                    videoController.isLooping
                ? () {
                    videoController.nextVideo();
                    _resetHideControlsTimer();
                  }
                : null,
            icon: const Icon(Icons.skip_next, color: Colors.white),
            iconSize: 32,
            tooltip: 'Next video',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(vpc.VideoPlayerController videoController) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Video counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${videoController.currentIndex + 1}/${videoController.playlist.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Loop indicator - access observable playlistRepeat
          Obx(() {
            final isLooping = videoController.isLooping;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLooping
                    ? Colors.green.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.loop,
                    color: isLooping
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLooping ? 'Looping' : 'No Loop',
                    style: TextStyle(
                      color: isLooping
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Video name
          if (videoController.currentVideoName.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  videoController.currentVideoName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
