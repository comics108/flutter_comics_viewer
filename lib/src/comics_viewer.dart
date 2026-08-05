import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'comics_viewer_controller.dart';
import 'comics_viewer_source.dart';
import 'dart_comics_viewer_backend.dart';
import 'dart_comics_viewer_surface.dart';
import 'windows_comics_viewer_surface.dart';

/// A widget that displays interactive comics with animations and sound
class ComicsViewer extends StatefulWidget {
  /// Controller for managing the comics viewer
  final ComicsViewerController controller;

  /// Initial comics file path
  final String? initialFilePath;

  /// Initial path/bytes source. Takes precedence over [initialFilePath].
  final ComicsViewerSource? source;

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
    this.source,
    this.initialLanguageIndex = 0,
    this.initialSoundEnabled = true,
    this.gestureRecognizers,
  });

  @override
  State<ComicsViewer> createState() => _ComicsViewerState();
}

class _ComicsViewerState extends State<ComicsViewer> {
  bool _unsupportedMarked = false;
  DartComicsViewerBackend? _dartBackend;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        kIsWeb) {
      _dartBackend = DartComicsViewerBackend();
      unawaited(widget.controller.attachBackend(_dartBackend!));
    }
    unawaited(widget.controller.setLanguageIndex(widget.initialLanguageIndex));
    unawaited(widget.controller.setSoundEnabled(widget.initialSoundEnabled));
    final source =
        widget.source ??
        (widget.initialFilePath == null
            ? null
            : ComicsViewerPath(widget.initialFilePath!));
    if (source != null) unawaited(widget.controller.load(source));
  }

  @override
  void dispose() {
    // The controller owns and disposes whichever backend is attached.
    super.dispose();
  }

  @override
  void didUpdateWidget(ComicsViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous =
        oldWidget.source ??
        (oldWidget.initialFilePath == null
            ? null
            : ComicsViewerPath(oldWidget.initialFilePath!));
    final next =
        widget.source ??
        (widget.initialFilePath == null
            ? null
            : ComicsViewerPath(widget.initialFilePath!));
    if (next != null && previous?.revisionKey != next.revisionKey) {
      unawaited(widget.controller.load(next));
    }
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
            gestureRecognizers:
                widget.gestureRecognizers ??
                const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: <String, dynamic>{
                'languageIndex': widget.initialLanguageIndex,
                'soundEnabled': widget.initialSoundEnabled,
              },
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () {
                params.onFocusChanged(true);
              },
            )
            ..addOnPlatformViewCreatedListener((viewId) {
              params.onPlatformViewCreated(viewId);
              unawaited(widget.controller.attachView(viewId));
            })
            ..create();
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: <String, dynamic>{
          'languageIndex': widget.initialLanguageIndex,
          'soundEnabled': widget.initialSoundEnabled,
        },
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: widget.gestureRecognizers,
        onPlatformViewCreated: (viewId) {
          unawaited(widget.controller.attachView(viewId));
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return WindowsComicsViewerSurface(controller: widget.controller);
    }

    final dartBackend = _dartBackend;
    if (dartBackend != null) {
      return DartComicsViewerSurface(backend: dartBackend);
    }

    if (!_unsupportedMarked) {
      _unsupportedMarked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.markUnsupported(
          'ComicsViewer is not supported on ${defaultTargetPlatform.name}',
        );
      });
    }
    return const SizedBox.expand();
  }
}
