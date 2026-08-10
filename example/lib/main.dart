import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';

enum SampleVersion { v2012, v2026 }

extension SampleVersionAsset on SampleVersion {
  String get fileName => 'sample_$name.comics';
  String get assetPath => 'assets/$fileName';
}

const viewerKey = Key('sample-comics-viewer');
const viewerStatusKey = Key('viewer-status');
const viewerPositionKey = Key('viewer-position');
const sampleSelectorKey = Key('sample-selector');

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
  SampleVersion _selectedSample = SampleVersion.v2026;
  ComicsViewerSource? _source;
  Object? _loadError;
  bool _usingInjectedSource = false;

  String get _activeFileName {
    final source = _source;
    if (_usingInjectedSource && source != null) {
      return source.revisionKey.toString().split('/').last;
    }
    return _selectedSample.fileName;
  }

  @override
  void initState() {
    super.initState();
    _source = widget.source;
    _usingInjectedSource = widget.source != null;
    if (_source == null) unawaited(_loadBundledSample(_selectedSample));
  }

  Future<void> _loadBundledSample(SampleVersion sample) async {
    try {
      final data = await (widget.assetBundle ?? rootBundle).load(
        sample.assetPath,
      );
      if (!mounted) return;
      setState(() {
        _selectedSample = sample;
        _usingInjectedSource = false;
        _loadError = null;
        _source = ComicsViewerBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          revisionKey: sample.assetPath,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _selectedSample = sample;
        _usingInjectedSource = false;
        _loadError = error;
      });
    }
  }

  Future<void> _selectSample(SampleVersion sample) async {
    if (sample == _selectedSample && widget.source == null) return;
    await _controller.pause();
    if (!mounted) return;
    await _loadBundledSample(sample);
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
            _ViewerControls(
              controller: _controller,
              selectedSample: _selectedSample,
              activeFileName: _activeFileName,
              onSampleSelected: (sample) => unawaited(_selectSample(sample)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer() {
    if (_loadError case final error?) {
      return Center(child: Text('Failed to load $_activeFileName: $error'));
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
  const _ViewerControls({
    required this.controller,
    required this.selectedSample,
    required this.activeFileName,
    required this.onSampleSelected,
  });

  final ComicsViewerController controller;
  final SampleVersion selectedSample;
  final String activeFileName;
  final ValueChanged<SampleVersion> onSampleSelected;

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
                SegmentedButton<SampleVersion>(
                  key: sampleSelectorKey,
                  segments: const [
                    ButtonSegment(
                      value: SampleVersion.v2012,
                      label: Text('v2012'),
                    ),
                    ButtonSegment(
                      value: SampleVersion.v2026,
                      label: Text('v2026'),
                    ),
                  ],
                  selected: {selectedSample},
                  showSelectedIcon: false,
                  onSelectionChanged: ready
                      ? (selection) => onSampleSelected(selection.single)
                      : null,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _phaseLabel(state, activeFileName),
                      key: viewerStatusKey,
                    ),
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

  String _phaseLabel(ComicsViewerState state, String fileName) =>
      switch (state.phase) {
        ComicsViewerPhase.idle => 'Preparing $fileName…',
        ComicsViewerPhase.loading => 'Loading $fileName…',
        ComicsViewerPhase.loaded =>
          'Rendered $fileName — ${(state.position * 100).round()}%',
        ComicsViewerPhase.error => 'Viewer error: ${state.error}',
        ComicsViewerPhase.unsupported => 'Unsupported platform: ${state.error}',
      };
}
