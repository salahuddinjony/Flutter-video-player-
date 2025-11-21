import 'package:get/get.dart';
import '../models/instruction_model.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';
import 'video_player_controller.dart';

class InstructionController extends GetxController {
  final FileService _fileService = FileService();
  final StorageService _storageService = StorageService();
  final FirebaseService _firebaseService = FirebaseService();
  final VideoPlayerController _videoController = Get.find<VideoPlayerController>();

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxString _statusMessage = ''.obs;
  String get statusMessage => _statusMessage.value;

  @override
  void onInit() {
    super.onInit();
    _initializeFirebase();
    // Clear old cached instructions to force reload from assets
    _clearOldCacheIfNeeded();
    _loadInitialInstructions();
  }

  /// Clear old cached instructions if they reference invalid files
  Future<void> _clearOldCacheIfNeeded() async {
    try {
      final lastInstructions = await _storageService.getLastInstructions();
      if (lastInstructions != null) {
        // Check if any video files in cached instructions might be invalid
        // Clear cache to force fresh load from assets
        print('Clearing old cached instructions to ensure fresh load...');
        await _storageService.clearInstructions();
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  @override
  void onClose() {
    _firebaseService.stopListening();
    super.onClose();
  }

  /// Initialize Firebase Firestore real-time listener
  void _initializeFirebase() {
    // Configure Firestore collection and document
    // Note: Collection name is 'instractions' (not 'instructions') as per Firebase
    // Listening to specific document: k9YeMsqLQddXWXFkEZXw
    const collectionPath = 'instractions'; // Match the actual Firebase collection name
    const String? documentId = 'k9YeMsqLQddXWXFkEZXw'; // Specific document ID from Firestore
    
    try {
      // Set up callback for instructions updates
      _firebaseService.onInstructionsUpdate = (InstructionsResponse instructions) {
        _handleInstructionsUpdate(instructions);
      };

      // Start listening after a delay to allow initial instructions to load first
      // Errors won't affect app functionality - it will work offline with local instructions
      // Only try to connect if Firebase was successfully initialized
      Future.delayed(const Duration(seconds: 2), () {
        try {
          // Check if Firebase is available before trying to connect
          _firebaseService.startListening(
            collectionPath: collectionPath,
            documentId: documentId,
          );
        } catch (e) {
          print('Firebase not available. App will work in offline mode.');
        }
      });
    } catch (e) {
      print('Error initializing Firebase listener: $e');
      print('App will work in offline mode with local instructions.');
    }
  }

  /// Load initial instructions
  Future<void> _loadInitialInstructions() async {
    _isLoading.value = true;
    _statusMessage.value = 'Loading instructions...';

    try {
      // Always load from assets first to get the latest instructions
      InstructionsResponse? instructions = await _fileService.readInstructionsFromAssets();
      
      // If not found in assets, try local storage
      instructions ??= await _fileService.readInstructionsFromLocal();
      
      // Save to local storage for offline use
      if (instructions != null) {
        await _fileService.saveInstructionsToLocal(instructions);
      }

      if (instructions != null) {
        // Always apply instructions from file to ensure we have the latest
        // This prevents issues with cached/stale instructions
        print('Applying instructions from file...');
        final currentHash = _fileService.calculateHash(
          instructions.toJson(),
        );
        await _applyInstructions(instructions, currentHash);
        _statusMessage.value = 'Instructions loaded successfully';
      } else {
        // Try to use last saved instructions
        final lastInstructions = await _storageService.getLastInstructions();
        if (lastInstructions != null) {
          await _videoController.applyInstructions(lastInstructions);
          _statusMessage.value = 'Using last saved instructions';
        } else {
          _statusMessage.value = 'No instructions found';
        }
      }
    } catch (e) {
      _statusMessage.value = 'Error loading instructions: $e';
      print('Error loading initial instructions: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Handle instructions update from Firebase Firestore or file change
  Future<void> _handleInstructionsUpdate(InstructionsResponse instructions) async {
    try {
      final currentHash = _fileService.calculateHash(
        instructions.toJson(),
      );
      final lastHash = await _storageService.getLastInstructionsHash();

      if (currentHash != lastHash) {
        _statusMessage.value = 'New instructions received, applying...';
        await _applyInstructions(instructions, currentHash);
        _statusMessage.value = 'Instructions updated successfully';
      }
    } catch (e) {
      _statusMessage.value = 'Error handling instructions update: $e';
      print('Error handling instructions update: $e');
    }
  }

  /// Apply instructions and save
  Future<void> _applyInstructions(
    InstructionsResponse instructions,
    String hash,
  ) async {
    // Save instructions to local storage
    await _fileService.saveInstructionsToLocal(instructions);
    
    // Save hash for change detection
    await _storageService.saveInstructionsHash(hash);
    
    // Apply to video player
    await _videoController.applyInstructions(instructions);
  }

  /// Manually reload instructions
  Future<void> reloadInstructions() async {
    _isLoading.value = true;
    _statusMessage.value = 'Reloading instructions...';
    
    try {
      final instructions = await _fileService.readInstructionsFromLocal();
      if (instructions == null) {
        _statusMessage.value = 'No instructions file found';
        return;
      }

      await _handleInstructionsUpdate(instructions);
    } catch (e) {
      _statusMessage.value = 'Error reloading instructions: $e';
    } finally {
      _isLoading.value = false;
    }
  }
}

