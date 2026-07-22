import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'comics_viewer_controller.dart';

/// A widget that displays interactive comics with animations and sound
class ComicsViewer extends StatefulWidget {
  /// Controller for managing the comics viewer
  final ComicsViewerController controller;

  /// Initial comics file path
  final String? initialFilePath;

  /// Initial language index
  final int initialLanguageIndex;

  /// Whether sound should be enabled initially
  final bool initialSoundEnabled;

  /// Gesture recognizers for the platform view
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const ComicsViewer({
    super.key,
    required this.controller,
    this.initialFilePath,
    this.initialLanguageIndex = 0,
    this.initialSoundEnabled = true,
    this.gestureRecognizers,
  });

  @override
  State<ComicsViewer> createState() => _ComicsViewerState();
}

class _ComicsViewerState extends State<ComicsViewer> {
  @override
  void initState() {
    super.initState();
    _initializeViewer();
  }

  Future<void> _initializeViewer() async {
    // Set initial language and sound settings
    await widget.controller.setLanguageIndex(widget.initialLanguageIndex);
    await widget.controller.setSoundEnabled(widget.initialSoundEnabled);

    // Load initial comics if provided
    if (widget.initialFilePath != null) {
      await widget.controller.loadComics(widget.initialFilePath!);
    }
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use PlatformViewLink for better performance and customization
    const String viewType = 'flutter_comics_viewer';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: viewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: widget.gestureRecognizers ?? const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: <String, dynamic>{
              'filePath': widget.initialFilePath,
              'languageIndex': widget.initialLanguageIndex,
              'soundEnabled': widget.initialSoundEnabled,
            },
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: <String, dynamic>{
          'filePath': widget.initialFilePath,
          'languageIndex': widget.initialLanguageIndex,
          'soundEnabled': widget.initialSoundEnabled,
        },
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: widget.gestureRecognizers,
      );
    }

    return Center(
      child: Text(
        'ComicsViewer is not supported on ${defaultTargetPlatform.name}',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
