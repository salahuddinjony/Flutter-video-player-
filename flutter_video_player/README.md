# Flutter Video Player

A Flutter application that plays videos in a loop based on JSON instructions. The app supports offline playback, Socket.IO integration for real-time updates, and persistent instruction storage.

## Features

- ✅ Play 2-3 MP4 video files in a playlist
- ✅ Continuous looping according to schedule
- ✅ JSON-driven schedule configuration
- ✅ Persistent instruction storage
- ✅ Socket.IO integration for real-time JSON updates
- ✅ Full-screen video playback
- ✅ Offline-first architecture
- ✅ Error handling for missing files
- ✅ GetX state management
- ✅ GoRouter navigation
- ✅ MVC architecture

## Project Structure

```
lib/
├── controllers/          # GetX Controllers
│   ├── instruction_controller.dart
│   └── video_player_controller.dart
├── models/               # Data Models
│   └── instruction_model.dart
├── routes/               # Navigation
│   └── app_router.dart
├── services/             # Business Logic Services
│   ├── file_service.dart
│   ├── socket_service.dart
│   └── storage_service.dart
├── views/                # UI Views
│   └── video_player_view.dart
└── main.dart
```

## Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android device or emulator (API level 21+)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd flutter_video_player
```

2. Install dependencies:
```bash
flutter pub get
```

3. Add video files to the assets folder:
   - Place your MP4 video files in `assets/videos/ads/` (or the folder specified in your JSON)
   - Example: `assets/videos/ads/video1.mp4`

4. Update `assets/instructions.json` with your video configuration (see JSON Format section)

## Build & Run

### Android

1. Connect an Android device or start an emulator

2. Run the app:
```bash
flutter run
```

3. Build APK:
```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (macOS only)

```bash
flutter run -d ios
```

## JSON Instruction Format

The app reads instructions from `assets/instructions.json` or local storage. Here's the format:

```json
{
  "instructions": [
    {
      "type": "update_schedule",
      "name": "default_schedule",
      "data": {
        "playlist_repeat": "always",
        "playlist": [
          {
            "folder": "ads",
            "files": [
              "video1.mp4",
              "video2.mp4"
            ],
            "ad_id": 1,
            "repeat": 1,
            "sequence": 1
          },
          {
            "folder": "ads",
            "files": [
              "video3.mp4"
            ],
            "ad_id": 2,
            "repeat": 2,
            "sequence": 2
          }
        ]
      }
    }
  ]
}
```

### Field Descriptions

- `playlist_repeat`: Set to `"always"` for continuous looping
- `folder`: The folder name where videos are stored (relative to `assets/videos/`)
- `files`: Array of video file names
- `ad_id`: Unique identifier for the ad
- `repeat`: Number of times to repeat this specific video in the playlist
- `sequence`: Playback order sequence

## Socket.IO Integration

The app uses Socket.IO to periodically check for JSON instruction updates. 

### Configuration

Update the Socket.IO server URL in `lib/controllers/instruction_controller.dart`:

```dart
const serverUrl = 'http://your-server-url:3000';
```

For Android emulator, use: `http://10.0.2.2:3000`  
For physical device, use your computer's IP address

### Events

The app listens for:
- `instructions_update`: Receives new instructions directly
- `json_updated`: Notification that the JSON file has been updated

### Periodic Checking

The app also checks for JSON file updates every 30 seconds automatically.

### Server Setup

See [SOCKET_IO_SETUP.md](SOCKET_IO_SETUP.md) for detailed instructions on setting up a Socket.IO server for testing.

## How JSON Change Detection Works

For detailed information, see [JSON_CHANGE_DETECTION.md](JSON_CHANGE_DETECTION.md).

### Quick Overview

1. **Initial Load**: On app start, the app loads instructions from:
   - Local storage (if available)
   - Assets folder (fallback)

2. **Hash Calculation**: Each instruction set is hashed for change detection

3. **Change Detection**: 
   - When new instructions are received via Socket.IO or file update
   - The app compares the hash of new instructions with the last applied hash
   - If different, new instructions are applied

4. **Persistence**: 
   - Applied instructions are saved to SharedPreferences
   - The hash is also saved for future comparison
   - The app continues using the last applied instructions until a change is detected

5. **Offline Mode**: 
   - If Socket.IO is unavailable, the app continues using the last saved instructions
   - Videos play from local assets or device storage

## Error Handling

- **Missing Video Files**: If a video file listed in JSON is missing, it's skipped and an error is logged
- **Invalid JSON**: Invalid JSON format is caught and displayed to the user
- **Network Errors**: Socket.IO connection errors don't prevent offline playback

## Architecture

### MVC Pattern

- **Models**: Data structures (`instruction_model.dart`)
- **Views**: UI components (`video_player_view.dart`)
- **Controllers**: Business logic and state management (`*_controller.dart`)

### State Management

- **GetX**: Used for reactive state management
- Controllers are registered globally and accessible throughout the app

### Navigation

- **GoRouter**: Declarative routing configuration
- Single route for the video player view

## Sample Video Files

Due to file size limitations, sample videos are not included. To test the app:

1. Add 2-3 small MP4 video files to `assets/videos/ads/`
2. Update `assets/instructions.json` with the correct file names
3. Run the app

### Example Video Sources

You can use any MP4 videos for testing. For production, ensure videos are:
- MP4 format
- Reasonably sized for mobile devices
- Optimized for playback

## Troubleshooting

### Videos not playing

1. Check that video files exist in the correct folder
2. Verify file names match exactly in `instructions.json`
3. Check console logs for error messages

### Socket.IO not connecting

1. Verify the server URL is correct
2. Check network connectivity
3. The app will continue working offline with last saved instructions

### JSON not updating

1. Ensure the JSON file is valid
2. Check that the hash calculation is working (see logs)
3. Verify Socket.IO events are being received

## Development

### Running in Debug Mode

```bash
flutter run --debug
```

### Running Tests

```bash
flutter test
```

## License

This project is created for assignment purposes.

## Author

Flutter Video Player Assignment
