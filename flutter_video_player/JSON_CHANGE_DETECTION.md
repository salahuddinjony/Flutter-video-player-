# JSON Change Detection and Instruction Persistence

This document explains how the Flutter Video Player app detects JSON instruction changes and persists instructions.

## Overview

The app implements a robust change detection mechanism that:
1. Loads instructions from multiple sources (assets, local storage)
2. Detects changes using hash comparison
3. Persists applied instructions locally
4. Continues using last applied instructions until a change is detected
5. Supports real-time updates via Socket.IO

## Architecture

### Components Involved

1. **FileService** (`lib/services/file_service.dart`)
   - Reads instructions from assets and local storage
   - Calculates hash for change detection
   - Manages video file paths

2. **StorageService** (`lib/services/storage_service.dart`)
   - Saves/loads instructions using SharedPreferences
   - Stores instruction hash for comparison
   - Provides persistence layer

3. **SocketService** (`lib/services/socket_service.dart`)
   - Connects to Socket.IO server
   - Listens for instruction updates
   - Periodically checks for JSON file changes

4. **InstructionController** (`lib/controllers/instruction_controller.dart`)
   - Orchestrates instruction loading and application
   - Handles change detection logic
   - Manages Socket.IO integration

## Change Detection Flow

### 1. Initial Load (App Start)

```
App Start
    ↓
InstructionController.onInit()
    ↓
_loadInitialInstructions()
    ↓
Try to load from local storage
    ↓
If not found → Load from assets
    ↓
Calculate hash of loaded instructions
    ↓
Compare with last saved hash
    ↓
If different → Apply new instructions
If same → Use last applied instructions
```

### 2. Hash Calculation

The app uses a simple but effective hash mechanism:

```dart
String calculateHash(dynamic jsonData) {
  final jsonString = jsonEncode(jsonData);
  return jsonString.hashCode.toString();
}
```

- Converts JSON to string
- Uses Dart's built-in `hashCode` for comparison
- Returns string representation for storage

**Why this works:**
- Any change in JSON structure or values produces a different hash
- Fast comparison (O(1))
- No need for deep object comparison

### 3. Persistence Mechanism

#### Saving Instructions

When instructions are applied:

1. **Save to SharedPreferences:**
   ```dart
   await _storageService.saveInstructions(instructions);
   ```
   - Stores complete instruction JSON
   - Used for offline playback
   - Survives app restarts

2. **Save Hash:**
   ```dart
   await _storageService.saveInstructionsHash(hash);
   ```
   - Stores hash for quick comparison
   - Prevents unnecessary re-processing

#### Loading Instructions

Priority order:
1. **Local Storage** (Application Documents Directory)
   - `{documents}/instructions.json`
   - Updated via Socket.IO or file sync

2. **Assets** (Fallback)
   - `assets/instructions.json`
   - Bundled with app

3. **Last Applied** (Persistence)
   - From SharedPreferences
   - Used if no file found

## Real-Time Update Detection

### Socket.IO Integration

The app uses Socket.IO for real-time updates:

#### Connection Setup
```dart
_socketService.connect(serverUrl);
```

#### Event Listeners

1. **`instructions_update` Event:**
   - Receives complete instruction JSON
   - Immediately processes and applies
   - Updates local storage

2. **`json_updated` Event:**
   - Notification that JSON file changed
   - Triggers local file read
   - Compares and applies if changed

#### Periodic Checking

Even without Socket.IO events, the app checks every 30 seconds:

```dart
void _startPeriodicCheck() {
  Future.delayed(const Duration(seconds: 30), () {
    _checkForJsonUpdate();
    _startPeriodicCheck(); // Recursive scheduling
  });
}
```

### Change Detection Logic

```dart
Future<void> _handleInstructionsUpdate(InstructionsResponse instructions) async {
  // Calculate hash of new instructions
  final currentHash = _fileService.calculateHash(instructions.toJson());
  
  // Get last saved hash
  final lastHash = await _storageService.getLastInstructionsHash();
  
  // Compare hashes
  if (currentHash != lastHash) {
    // Instructions changed - apply them
    await _applyInstructions(instructions, currentHash);
  }
  // If same, do nothing - continue with current instructions
}
```

## Instruction Application Flow

When new instructions are detected:

```
New Instructions Detected
    ↓
_applyInstructions()
    ↓
Save to local storage (instructions.json)
    ↓
Save hash to SharedPreferences
    ↓
Apply to VideoPlayerController
    ↓
VideoPlayerController.applyInstructions()
    ↓
Build playlist from schedule
    ↓
Validate video files exist
    ↓
Start playback
```

## Offline-First Behavior

The app is designed to work offline:

1. **On First Launch:**
   - Loads from assets if available
   - Saves to local storage
   - Applies instructions

2. **On Subsequent Launches:**
   - Loads last applied instructions from SharedPreferences
   - Continues playback without network
   - Socket.IO attempts connection in background

3. **When Network Available:**
   - Socket.IO connects
   - Checks for updates
   - Applies if changed

4. **When Network Unavailable:**
   - Continues with last applied instructions
   - No interruption to playback

## Error Handling

### Missing Video Files

```dart
final videoPath = await _fileService.getVideoPath(item.folder, fileName);
if (videoPath != null) {
  // Add to playlist
} else {
  _showError('Video file not found: ${item.folder}/$fileName');
  // Skip this file, continue with others
}
```

- Files are validated before adding to playlist
- Missing files are logged and skipped
- Playback continues with available files

### Invalid JSON

```dart
try {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return InstructionsResponse.fromJson(json);
} catch (e) {
  print('Error reading instructions: $e');
  return null; // Fallback to last applied
}
```

- JSON parsing errors are caught
- App falls back to last applied instructions
- User sees error message

### Socket.IO Connection Failures

```dart
_socket!.onError((error) {
  print('Socket.IO error: $error');
  // App continues with last applied instructions
});
```

- Connection errors don't stop playback
- App continues in offline mode
- Reconnection attempts happen automatically

## Data Flow Diagram

```
┌─────────────────┐
│  Socket.IO      │───instructions_update───┐
│  Server         │                          │
└─────────────────┘                          │
                                              ↓
┌─────────────────┐      ┌─────────────────┐
│  Local File     │─────→│ Instruction     │
│  instructions   │      │ Controller      │
│  .json          │      └─────────────────┘
└─────────────────┘              │
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ↓                         ↓
          ┌─────────────────┐      ┌─────────────────┐
          │ Calculate Hash  │      │ Compare with    │
          │                 │      │ Last Hash       │
          └─────────────────┘      └─────────────────┘
                    │                         │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Hash Changed?         │
                    └────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
              YES   │                         │  NO
                    ↓                         ↓
          ┌─────────────────┐      ┌─────────────────┐
          │ Save to         │      │ Continue with   │
          │ Storage         │      │ Current         │
          │                 │      │ Instructions    │
          └─────────────────┘      └─────────────────┘
                    │
                    ↓
          ┌─────────────────┐
          │ Apply to Video  │
          │ Player          │
          └─────────────────┘
```

## Summary

The app's change detection mechanism ensures:

1. **Reliability:** Always has instructions to follow (from assets, local storage, or persistence)
2. **Efficiency:** Only processes instructions when they actually change
3. **Offline Support:** Works without network using last applied instructions
4. **Real-Time Updates:** Receives and applies updates via Socket.IO
5. **Persistence:** Survives app restarts and continues with last applied instructions

The hash-based comparison provides a fast and reliable way to detect changes without deep object comparison, making the system efficient and responsive.

