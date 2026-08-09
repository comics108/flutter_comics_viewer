import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';

const sampleAssetPath = 'assets/sample.comics';
const viewerKey = Key('sample-comics-viewer');
const viewerStatusKey = Key('viewer-status');
const viewerPositionKey = Key('viewer-position');

void main() {
  runApp(const MyApp());
}

/// A small, real harness for the package's Dart renderer.
///
/// macOS, Linux, and Web render the bundled archive through
/// [DartComicsViewerBackend]. Tests may inject a smaller source while exercising
/// the same public [ComicsViewer] API.
class MyApp extends StatefulWidget {
  const MyApp({super.key, this.source, this.assetBundle});

  final ComicsViewerSource? source;
  final AssetBundle? assetBundle;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ComicsViewerController _controller = ComicsViewerController();
  ComicsViewerSource? _source;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _source = widget.source;
    if (_source == null) unawaited(_loadBundledSample());
  }

  Future<void> _loadBundledSample() async {
    try {
      final data = await (widget.assetBundle ?? rootBundle).load(
        sampleAssetPath,
      );
      if (!mounted) return;
      setState(() {
        _source = ComicsViewerBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          revisionKey: sampleAssetPath,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Comics Viewer — macOS example'),
        ),
        body: Column(
          children: [
            Expanded(child: _buildViewer()),
            _ViewerControls(controller: _controller),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer() {
    if (_loadError case final error?) {
      return Center(child: Text('Failed to load $sampleAssetPath: $error'));
    }
    final source = _source;
    if (source == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ComicsViewer(
      key: viewerKey,
      controller: _controller,
      source: source,
    );
  }
}

class _ViewerControls extends StatelessWidget {
  const _ViewerControls({required this.controller});

  final ComicsViewerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final ready = state.phase == ComicsViewerPhase.loaded;
        return Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(_phaseLabel(state), key: viewerStatusKey),
                    const Spacer(),
                    IconButton(
                      tooltip: state.playing ? 'Pause' : 'Play',
                      onPressed: ready
                          ? () => unawaited(
                              state.playing
                                  ? controller.pause()
                                  : controller.play(),
                            )
                          : null,
                      icon: Icon(
                        state.playing ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                    IconButton(
                      tooltip: controller.muted ? 'Unmute' : 'Mute',
                      onPressed: ready
                          ? () => unawaited(
                              controller.setMuted(!controller.muted),
                            )
                          : null,
                      icon: Icon(
                        controller.muted ? Icons.volume_off : Icons.volume_up,
                      ),
                    ),
                  ],
                ),
                Slider(
                  key: viewerPositionKey,
                  value: state.position,
                  onChanged: ready
                      ? (value) =>
                            unawaited(controller.setScrollPosition(value))
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _phaseLabel(ComicsViewerState state) => switch (state.phase) {
    ComicsViewerPhase.idle => 'Preparing sample…',
    ComicsViewerPhase.loading => 'Loading sample.comics…',
    ComicsViewerPhase.loaded =>
      'Rendered sample.comics — ${(state.position * 100).round()}%',
    ComicsViewerPhase.error => 'Viewer error: ${state.error}',
    ComicsViewerPhase.unsupported => 'Unsupported platform: ${state.error}',
  };
}
