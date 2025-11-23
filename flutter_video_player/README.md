# Download & Resources

- **APK:** [Download APK](https://drive.google.com/drive/folders/1vmPr5cphKf2hY_5Iyy5MwOFg84_QyHhD?usp=sharing)
- **Video Explanation:** [Watch on Loom](https://www.loom.com/share/1e9f070797724430a765066e605857e5)
- **GitHub Repository:** [Flutter-video-player-](https://github.com/salahuddinjony/Flutter-video-player-)

## JSON Change Detection and Instruction Persistence

The app ensures that video instructions are always up to date and reliable, both online and offline, using the following process:

1. **Initial Load**: On startup, the app loads instructions from Firebase Firestore if online, or from local storage/assets if offline.
2. **Hash Calculation**: The app calculates a hash of the current instructions to efficiently detect changes.
3. **Real-time Listening**: The app listens for updates to the instructions document in Firestore. When a change is detected, it fetches and validates the new instructions.
4. **Change Comparison**: The hash of the new instructions is compared to the last applied hash. If different, the new instructions are applied and the playlist is updated.
5. **Persistence**: The latest instructions and their hash are saved to local storage (using SharedPreferences), so the app can continue using the last valid instructions even if offline.
6. **Offline Mode**: If the app is offline or Firestore is unreachable, it loads and uses the last saved instructions from local storage, ensuring uninterrupted playback.

This approach guarantees seamless updates when online and robust fallback when offline, with all changes detected efficiently using hashing and real-time Firestore listeners.
# Flutter Video Player


A Flutter application that plays videos in a loop based on JSON instructions. The app supports offline playback, real-time updates using Firebase Firestore, and persistent instruction storage.

## What I Have Done in This Project

- Built a Flutter video player app that plays a playlist of MP4 videos in a continuous loop, based on instructions defined in a JSON file.
- Implemented persistent storage for instructions, so the app works offline and remembers the last valid configuration.
- Used Firebase Firestore to detect real-time changes to the JSON instructions, enabling instant updates to the video playlist when the backend changes.
- Designed the app to handle missing files, invalid JSON, and network errors gracefully, ensuring robust offline-first behavior.
- Used GetX for state management and MVC architecture for code organization.
- Provided clear error handling and logging for troubleshooting.


## Features

- ✅ Play 2-3 MP4 video files in a playlist
- ✅ Continuous looping according to schedule
- ✅ JSON-driven schedule configuration
- ✅ Persistent instruction storage
- ✅ Real-time JSON updates using Firebase Firestore
- ✅ Full-screen video playback
- ✅ Offline-first architecture
- ✅ Error handling for missing files
- ✅ GetX state management
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
│   ├── firebase_service.dart
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


## Real-time Updates with Firebase Firestore

The app uses Firebase Firestore to detect real-time changes to the JSON instructions. When the instructions document in Firestore is updated, the app automatically receives the new configuration and updates the video playlist accordingly.

### Configuration

- Set up your Firebase project and Firestore database.
- Update the Firestore document path in `lib/services/firebase_service.dart` or the relevant service file.
- Ensure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly configured.

### How It Works

1. On app start, the app loads instructions from Firestore if online, or from local storage/assets if offline.
2. The app listens for real-time updates to the instructions document in Firestore.
3. When a change is detected, the app validates and applies the new instructions, updating the video playlist instantly.
4. If offline, the app continues using the last saved instructions.

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
