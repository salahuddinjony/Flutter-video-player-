# What are "Instructions" and the JSON File?

## Simple Explanation

**Instructions** = A configuration file that tells the app **which videos to play** and **how to play them**.

**JSON File** = The file format used to store these instructions (it's like a settings/config file).

---

## What Does "Instructions Loaded" Mean?

When you see **"Instructions loaded successfully"**, it means:

1. ✅ The app found the `instructions.json` file
2. ✅ The app read and understood the video playlist configuration
3. ✅ The app is ready to play videos according to that configuration

---

## What is the JSON File?

The `instructions.json` file is like a **recipe** or **playlist** that tells the app:

- **Which videos to play** (file names)
- **Where to find them** (folder path)
- **How many times to repeat each video**
- **In what order to play them**
- **Whether to loop forever** or stop after one playthrough

---

## Example JSON File Breakdown

```json
{
  "instructions": [
    {
      "type": "update_schedule",           // Type of instruction
      "name": "default_schedule",          // Name of this schedule
      "data": {
        "playlist_repeat": "always",       // Loop forever? "always" = yes
        "playlist": [                       // List of videos to play
          {
            "folder": "ads",                // Videos are in assets/videos/ads/
            "files": [                      // Which video files to play
              "countdown_video.mp4"         // File name
            ],
            "ad_id": 1,                    // Unique ID for this video/ad
            "repeat": 1,                   // How many times to play this video
            "sequence": 1                   // Playback order (1st, 2nd, etc.)
          }
        ]
      }
    }
  ]
}
```

---

## Real-World Example

Imagine you have 3 videos:
- `video1.mp4`
- `video2.mp4`  
- `video3.mp4`

Your JSON file might look like:

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
            "files": ["video1.mp4", "video2.mp4"],
            "ad_id": 1,
            "repeat": 1,
            "sequence": 1
          },
          {
            "folder": "ads",
            "files": ["video3.mp4"],
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

**What this means:**
- Play `video1.mp4` once
- Play `video2.mp4` once
- Play `video3.mp4` twice (because `"repeat": 2`)
- Then loop back to the beginning and repeat forever (because `"playlist_repeat": "always"`)

**Playback order:** video1 → video2 → video3 → video3 → (loop) video1 → video2 → video3 → video3 → ...

---

## Why Use JSON?

1. **Easy to Update**: Change the JSON file without modifying code
2. **Remote Control**: Update videos via Socket.IO without reinstalling the app
3. **Flexible**: Add/remove videos, change order, adjust repeats easily
4. **Offline Support**: App saves the last instructions and works offline

---

## Where is the JSON File?

- **In your project**: `assets/instructions.json`
- **On device**: Saved to local storage after loading
- **Can be updated**: Via Socket.IO server or by replacing the file

---

## How Does It Work?

1. **App starts** → Looks for `instructions.json`
2. **Reads the file** → Understands which videos to play
3. **Creates playlist** → Builds the video queue
4. **Starts playing** → Follows the schedule
5. **Saves instructions** → Remembers them for next time
6. **Checks for updates** → Via Socket.IO every 30 seconds

---

## Summary

- **Instructions** = Video playlist configuration
- **JSON File** = The file that stores this configuration
- **"Instructions loaded"** = App successfully read and understood the playlist
- **Purpose** = Control which videos play, in what order, and how many times

Think of it like a **TV schedule** or **playlist** that tells the app what to show!

