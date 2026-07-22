# Flutter Comics Viewer

A Flutter plugin for rendering interactive comics and puzzles with animations and sound.

## Features

- **Comics Rendering**: Display animated comics with automatic scroll and sound synchronization
- **Puzzle Support**: Render interactive puzzle grids with piece navigation
- **Sound Playback**: Position-synchronized audio playback
- **Cross-Platform**: Works on Android and iOS
- **Simple API**: Just 5 main methods for comics playback control

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_comics_viewer:
    path: ../path/to/flutter_comics_viewer
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';

class ComicsScreen extends StatefulWidget {
  @override
  _ComicsScreenState createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen> {
  final ComicsViewerController _controller = ComicsViewerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ComicsViewer(
        controller: _controller,
        filePath: '/path/to/episode.comics',
        onLoaded: () {
          print('Comics loaded!');
          _controller.play();
        },
        onScrollChanged: (position) {
          print('Scroll position: $position');
        },
        onError: (error) {
          print('Error: $error');
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Comics API

### ComicsViewer Widget

Main widget for displaying comics.

```dart
ComicsViewer({
  required ComicsViewerController controller,
  required String filePath,           // Path to .comics file
  VoidCallback? onLoaded,             // Called when comics loaded
  ValueChanged<double>? onScrollChanged, // Scroll position changed
  ValueChanged<String>? onError,      // Error occurred
  int languageIndex = 0,              // Language selection (0-based)
  bool soundEnabled = true,           // Enable/disable sounds
  bool showPreview = false,           // Show/hide preview layers
})
```

### ComicsViewerController

Controller for comics playback.

#### Methods

**1. Load and Display**

```dart
// Load .comics file (called automatically by widget)
await controller.loadComics('/path/to/file.comics');
```

**2. Playback Control**

```dart
// Start auto-scroll playback
controller.play();

// Pause playback
controller.pause();
```

**3. Navigation**

```dart
// Set scroll position (0.0 to duration)
controller.setScrollPosition(500.0);

// Get current scroll position
double position = controller.getScrollPosition();
```

**4. Preview & Sound**

```dart
// Toggle preview layers visibility
controller.togglePreview(true);  // Show preview
controller.togglePreview(false); // Hide preview

// Toggle sound playback
controller.toggleSounds(true);   // Enable sounds
controller.toggleSounds(false);  // Disable sounds
```

**5. Cleanup**

```dart
// Release resources (call in dispose)
controller.dispose();
```

#### Properties (Read-Only)

```dart
// Check if currently playing
bool playing = controller.isPlaying;

// Get total scrollable height
double totalHeight = controller.duration;

// Get current position
double currentPos = controller.currentPosition;
```

## Puzzle API

### PuzzleViewer Widget

Widget for displaying interactive puzzles.

```dart
PuzzleViewer({
  required PuzzleViewerController controller,
  required String filePath,           // Path to .puzzle file
  VoidCallback? onLoaded,
  ValueChanged<int>? onPieceSelected, // Piece index selected
  ValueChanged<String>? onError,
  bool soundEnabled = true,
  bool showPreview = false,
})
```

### PuzzleViewerController

Controller for puzzle interaction.

```dart
// Load puzzle file
await controller.loadPuzzle('/path/to/puzzle.puzzle');

// Navigate to piece by index
controller.selectPiece(5);

// Get current piece
int currentPiece = controller.currentPieceIndex;

// Get total pieces count
int totalPieces = controller.totalPieces;

// Control playback for current piece
controller.play();
controller.pause();

// Toggle preview/sounds for all pieces
controller.togglePreview(true);
controller.toggleSounds(false);

// Cleanup
controller.dispose();
```

## File Format

### .comics File

A .comics file is a ZIP archive containing:

- `data.json` - Comics structure and metadata
- `layers/` - Layer images (PNG)
- `sounds/` - Audio files (MP3)

**Example usage:**

```dart
// From app bundle
final filePath = 'assets/episodes/episode1.comics';

// From downloaded file
final filePath = '/data/user/0/com.app/files/episode1.comics';
```

### .puzzle File

A .puzzle file is a ZIP archive containing:

- Puzzle metadata (grid layout)
- Multiple .comics files (one per piece)

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';

class ComicsPlayerScreen extends StatefulWidget {
  final String comicsPath;

  ComicsPlayerScreen({required this.comicsPath});

  @override
  _ComicsPlayerScreenState createState() => _ComicsPlayerScreenState();
}

class _ComicsPlayerScreenState extends State<ComicsPlayerScreen> {
  late ComicsViewerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = ComicsViewerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comics Viewer'),
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
                _isPlaying ? _controller.play() : _controller.pause();
              });
            },
          ),
        ],
      ),
      body: ComicsViewer(
        controller: _controller,
        filePath: widget.comicsPath,
        soundEnabled: true,
        onLoaded: () {
          setState(() {
            _controller.play();
            _isPlaying = true;
          });
        },
        onScrollChanged: (position) {
          // Update progress bar
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Requirements

- **Flutter**: 3.3.0+
- **Dart**: 3.0.0+
- **Android**: API 21+ (Android 5.0)
- **iOS**: 13.0+

## Bundle ID

```
net.nativemind.flutter.comics.viewer
```

## License

Copyright © 2017-2026 Iron Water Studio, NativeMind. All rights reserved.
