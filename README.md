# CopyClip - macOS Clipboard Manager

A powerful macOS clipboard manager that maintains a searchable history of all your clipboard items with a global hotkey shortcut.

## Features

- 📋 **Complete Clipboard History**: Automatically tracks all clipboard items
- 🔍 **Searchable**: Quickly find any clipboard item with instant search
- ⌨️ **Global Hotkey**: Press `Ctrl+Option+V` from anywhere to open the clipboard window
- 💾 **Persistent Storage**: History is saved and persists across app restarts
- 🎨 **Modern UI**: Clean, native macOS interface built with SwiftUI
- 🚀 **Lightweight**: Runs in the background without a dock icon

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building)

## Building the App

### Option 1: Using Xcode (Recommended)

1. Open `CopyClip.xcodeproj` in Xcode
2. Select the CopyClip scheme
3. Press `Cmd+B` to build
4. Press `Cmd+R` to run

### Option 2: Using Swift Package Manager

```bash
swift build -c release
```

## Installation

1. Build the app using one of the methods above
2. The built app will be in `build/Release/CopyClip.app` (SPM) or in Xcode's DerivedData folder
3. Drag `CopyClip.app` to your Applications folder
4. Open the app (you may need to allow it in System Settings > Privacy & Security)
5. Grant Accessibility permissions when prompted (required for global hotkeys)

## Usage

### Opening the Clipboard Window

- Press `Ctrl+Option+V` from anywhere in macOS
- The clipboard history window will appear centered on your current screen

### Using Clipboard History

1. **Search**: Type in the search bar to filter clipboard items
2. **Copy**: Click the copy icon or press Enter on an item to copy it
3. **Delete**: Click the trash icon to remove an item from history
4. **Clear All**: Click the trash icon in the header to clear all history

### Keyboard Shortcuts

- `Ctrl+Option+V`: Open/close clipboard window
- `Esc`: Close the window
- `Enter`: Copy selected item and close window
- `Cmd+F`: Focus search bar

## Permissions

The app requires the following permissions:

1. **Accessibility**: Required for global hotkey registration

   - Go to System Settings > Privacy & Security > Accessibility
   - Enable CopyClip

2. **Input Monitoring** (may be required on some systems)
   - Go to System Settings > Privacy & Security > Input Monitoring
   - Enable CopyClip

## Technical Details

- Built with SwiftUI and AppKit
- Uses Carbon APIs for global hotkey registration
- Stores clipboard history in UserDefaults
- Monitors clipboard changes every 0.5 seconds
- Maximum history size: 1000 items

## Project Structure

```
CopyClip/
├── Sources/
│   ├── main.swift              # App entry point
│   ├── ClipboardManager.swift  # Clipboard monitoring and history management
│   ├── WindowController.swift  # Window management
│   ├── ContentView.swift      # Main UI
│   └── HotKeyManager.swift    # Global hotkey handling
├── Info.plist                  # App configuration
├── Package.swift               # Swift Package Manager configuration
└── CopyClip.xcodeproj/         # Xcode project
```

## Troubleshooting

### Hotkey Not Working

1. Make sure Accessibility permissions are granted
2. Check if another app is using the same hotkey
3. Restart the app after granting permissions

### Clipboard Not Being Tracked

1. Make sure the app is running (check Activity Monitor)
2. The app runs without a dock icon, so it may not be obvious it's running
3. Try copying something and then pressing `Ctrl+Option+V` to check if it appears

### App Won't Launch

1. Check Console.app for error messages
2. Make sure you're running macOS 13.0 or later
3. Try building from Xcode to see compilation errors

## License

This project is provided as-is for personal use.

## Contributing

Feel free to submit issues or pull requests for improvements!
