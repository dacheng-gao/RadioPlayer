# RadioPlayer

A simple iOS radio streaming app built with SwiftUI. Stream audio content with background playback support and lock screen controls.

## Features

- 🎵 Audio streaming with AVPlayer
- 🔊 Background audio playback
- 🎛️ Lock screen and Control Center integration via MPRemoteCommandCenter
- 📱 Clean SwiftUI interface

## Requirements

- iOS 16.0+
- Xcode 15+
- Swift 5.9

## Build Locally

1. **Install XcodeGen** (if not already installed):
   ```bash
   brew install xcodegen
   ```

2. **Generate the Xcode project**:
   ```bash
   xcodegen generate
   ```

3. **Open and run**:
   ```bash
   open RadioPlayer.xcodeproj
   ```
   Then build and run on a simulator or device (⌘R).

## Project Structure

```
RadioPlayer/
├── AppCore/          # App configuration, state, and view model
├── Audio/            # Audio playback service and now playing info
├── Network/          # Media API client
└── ContentView.swift # Main UI
```

## License

MIT
