import 'package:get/get.dart';
import 'package:video_player/video_player.dart' as video_player;
import '../models/instruction_model.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';
import 'dart:async';
import 'dart:io';

class VideoPlayerController extends GetxController {
  final FileService _fileService = FileService();
  final StorageService _storageService = StorageService();

  video_player.VideoPlayerController? _currentPlayer;
  video_player.VideoPlayerController? get currentPlayer => _currentPlayer;

  final RxList<String> _playlist = <String>[].obs;
  List<String> get playlist => _playlist;

  final RxInt _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;

  final RxBool _isPlaying = false.obs;
  bool get isPlaying => _isPlaying.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final RxString _currentVideoName = ''.obs;
  String get currentVideoName => _currentVideoName.value;

  final RxString _playlistRepeat = 'always'.obs;
  bool get isLooping => _playlistRepeat.value == 'always';

  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;

  Timer? _errorTimer;
  Timer? _positionTimer;

  @override
  void onInit() {
    super.onInit();
    _loadLastInstructions();
  }

  @override
  void onClose() {
    _currentPlayer?.dispose();
    _errorTimer?.cancel();
    _positionTimer?.cancel();
    super.onClose();
  }

  /// Load last applied instructions
  Future<void> _loadLastInstructions() async {
    final instructions = await _storageService.getLastInstructions();
    if (instructions != null && instructions.instructions.isNotEmpty) {
      await applyInstructions(instructions);
    }
  }

  /// Apply new instructions
  Future<void> applyInstructions(InstructionsResponse instructions) async {
    try {
      if (instructions.instructions.isEmpty) return;

      final instruction = instructions.instructions.firstWhere(
        (inst) => inst.type == 'update_schedule',
        orElse: () => instructions.instructions.first,
      );

      final schedule = instruction.data;
      _playlistRepeat.value = schedule.playlistRepeat;

      // Build playlist from schedule
      final List<String> newPlaylist = [];
      for (final item in schedule.playlist) {
        for (final fileName in item.files) {
          print('Looking for video: ${item.folder}/$fileName');
          final videoPath = await _fileService.getVideoPath(item.folder, fileName);
          if (videoPath != null) {
            print('Video found at: $videoPath');
            for (int i = 0; i < item.repeat; i++) {
              newPlaylist.add(videoPath);
            }
          } else {
            print('Video file not found: ${item.folder}/$fileName');
            _showError('Video file not found: ${item.folder}/$fileName');
          }
        }
      }

      if (newPlaylist.isEmpty) {
        _showError('No valid video files found in playlist');
        print('Playlist is empty, cannot play videos');
        return;
      }

      print('Playlist created with ${newPlaylist.length} video(s)');
      _playlist.value = newPlaylist;
      _currentIndex.value = 0;

      // Save instructions
      await _storageService.saveInstructions(instructions);

      // Start playing
      print('Starting video playback...');
      await playVideo(0);
    } catch (e) {
      _showError('Error applying instructions: $e');
    }
  }

  /// Play video at index
  Future<void> playVideo(int index) async {
    if (index < 0 || index >= _playlist.length) {
      _showError('Invalid video index: $index');
      print('Invalid video index: $index, playlist length: ${_playlist.length}');
      return;
    }

    try {
      // Dispose previous player safely
      final oldPlayer = _currentPlayer;
      _currentPlayer = null; // Clear reference first
      _positionTimer?.cancel(); // Stop position timer
      if (oldPlayer != null) {
        try {
          oldPlayer.removeListener(_videoListener);
          await oldPlayer.dispose();
        } catch (e) {
          print('Error disposing old player: $e');
        }
      }
      await Future.delayed(const Duration(milliseconds: 150));

      final videoPath = _playlist[index];
      print('Playing video at path: $videoPath');
      _currentVideoName.value = videoPath.split('/').last;

      // Initialize new player - check if it's an asset or file path
      if (videoPath.startsWith('assets/')) {
        print('Initializing asset video player...');
        _currentPlayer = video_player.VideoPlayerController.asset(videoPath);
      } else {
        print('Initializing file video player...');
        _currentPlayer = video_player.VideoPlayerController.file(File(videoPath));
      }
      
      print('Initializing video player...');
      await _currentPlayer!.initialize();
      print('Video player initialized successfully');

      // Set up listener for video completion
      _currentPlayer!.addListener(_videoListener);

      // Initialize position and duration
      position.value = Duration.zero;
      duration.value = _currentPlayer!.value.duration;

      // Start position update timer
      _startPositionTimer();

      // Start playing
      print('Starting video playback...');
      await _currentPlayer!.play();
      _isPlaying.value = true;
      _currentIndex.value = index;
      _errorMessage.value = '';
      print('Video is now playing');
    } catch (e, stackTrace) {
      print('Error playing video: $e');
      print('Stack trace: $stackTrace');
      _showError('Error playing video: $e');
      // Don't move to next video if it's the first one and failed
      if (index == 0) {
        print('First video failed, not moving to next');
      } else {
        _moveToNextVideo();
      }
    }
  }

  /// Video listener for completion detection
  void _videoListener() {
    final player = _currentPlayer;
    if (player == null) return;
    
    try {
      if (!player.value.isInitialized) return;
      
      final position = player.value.position;
      final duration = player.value.duration;
      
      // Check if video has reached the end (with small tolerance)
      if (duration.inMilliseconds > 0 && 
          position.inMilliseconds >= duration.inMilliseconds - 100) {
        player.removeListener(_videoListener);
        _moveToNextVideo();
      }
    } catch (e) {
      // Player was disposed, ignore
      print('Video listener error (player disposed): $e');
    }
  }

  /// Move to next video in playlist
  void _moveToNextVideo() {
    if (_playlist.isEmpty) return;

    int nextIndex = _currentIndex.value + 1;

    // Check if we need to loop the playlist
      if (nextIndex >= _playlist.length) {
        if (_playlistRepeat.value == 'always') {
          nextIndex = 0;
        } else {
          // Stop if not set to always repeat
          _isPlaying.value = false;
          return;
        }
      }

    playVideo(nextIndex);
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    final player = _currentPlayer;
    if (player == null) return;

    try {
      if (!player.value.isInitialized) return;
      
      if (_isPlaying.value) {
        await player.pause();
        _isPlaying.value = false;
      } else {
        await player.play();
        _isPlaying.value = true;
      }
    } catch (e) {
      // Player was disposed, ignore
      print('Error toggling play/pause (player disposed): $e');
    }
  }

  /// Go to next video
  void nextVideo() {
    if (_playlist.isEmpty) return;
    int nextIndex = _currentIndex.value + 1;
    
    if (nextIndex >= _playlist.length) {
      if (_playlistRepeat.value == 'always') {
        nextIndex = 0; // Loop to beginning
      } else {
        return; // Can't go next if not looping
      }
    }
    
    playVideo(nextIndex);
  }

  /// Go to previous video
  void previousVideo() {
    if (_playlist.isEmpty) return;
    int prevIndex = _currentIndex.value - 1;
    
    if (prevIndex < 0) {
      if (_playlistRepeat.value == 'always') {
        prevIndex = _playlist.length - 1; // Loop to end
      } else {
        return; // Can't go previous if at start and not looping
      }
    }
    
    playVideo(prevIndex);
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    final player = _currentPlayer;
    if (player == null) return;

    try {
      if (!player.value.isInitialized) return;
      await player.seekTo(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  /// Start position update timer
  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final player = _currentPlayer;
      if (player != null && player.value.isInitialized) {
        position.value = player.value.position;
        duration.value = player.value.duration;
      } else {
        position.value = Duration.zero;
        duration.value = Duration.zero;
      }
    });
  }

  /// Show error message
  void _showError(String message) {
    _errorMessage.value = message;
    print('Video Player Error: $message');
    
    // Clear error after 5 seconds
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 5), () {
      _errorMessage.value = '';
    });
  }
}

