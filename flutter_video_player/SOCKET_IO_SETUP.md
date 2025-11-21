# Socket.IO Server Setup

This document explains how to set up a Socket.IO server for testing the Flutter Video Player app.

## Quick Setup with Node.js

### 1. Install Dependencies

```bash
npm init -y
npm install socket.io express
```

### 2. Create Server File (server.js)

```javascript
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = 3000;
const INSTRUCTIONS_FILE = path.join(__dirname, 'instructions.json');

// Serve instructions.json
app.get('/instructions.json', (req, res) => {
  if (fs.existsSync(INSTRUCTIONS_FILE)) {
    res.sendFile(INSTRUCTIONS_FILE);
  } else {
    res.status(404).json({ error: 'Instructions file not found' });
  }
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  // Send current instructions on connection
  if (fs.existsSync(INSTRUCTIONS_FILE)) {
    const instructions = JSON.parse(fs.readFileSync(INSTRUCTIONS_FILE, 'utf8'));
    socket.emit('instructions_update', instructions);
  }

  // Watch for file changes
  fs.watchFile(INSTRUCTIONS_FILE, (curr, prev) => {
    if (curr.mtime !== prev.mtime) {
      console.log('Instructions file updated');
      const instructions = JSON.parse(fs.readFileSync(INSTRUCTIONS_FILE, 'utf8'));
      io.emit('json_updated');
      io.emit('instructions_update', instructions);
    }
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

server.listen(PORT, () => {
  console.log(`Socket.IO server running on http://localhost:${PORT}`);
});
```

### 3. Create instructions.json in the same directory

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
              "20251110_162219_432380_5QayAWR5Fq2omQRMb8ab.mp4"
            ],
            "ad_id": 1,
            "repeat": 1,
            "sequence": 1
          }
        ]
      }
    }
  ]
}
```

### 4. Run the Server

```bash
node server.js
```

## Testing

1. Update the Socket.IO server URL in `lib/controllers/instruction_controller.dart`:
   ```dart
   const serverUrl = 'http://YOUR_IP_ADDRESS:3000';
   ```
   For Android emulator, use `http://10.0.2.2:3000`
   For physical device, use your computer's IP address

2. Modify `instructions.json` on the server - the app should receive the update automatically

3. The app will also check for updates every 30 seconds

## Events

- `instructions_update`: Sends the full instructions JSON
- `json_updated`: Notifies that the JSON file has been updated

## Alternative: Simple HTTP Server

If you don't want to use Socket.IO, you can use a simple HTTP server that the app polls:

```javascript
const express = require('express');
const app = express();

app.use(express.static('public'));

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
```

Place `instructions.json` in the `public` folder and the app will fetch it via HTTP.

