import 'dart:async';

import 'package:flutter/material.dart';

import 'comics_viewer_controller.dart';
import 'windows_comics_viewer_backend.dart';

/// Transparent Flutter layout anchor for the viewer-only WPF child HWND.
class WindowsComicsViewerSurface extends StatefulWidget {
  const WindowsComicsViewerSurface({super.key, required this.controller});

  final ComicsViewerController controller;

  @override
  State<WindowsComicsViewerSurface> createState() =>
      _WindowsComicsViewerSurfaceState();
}

class _WindowsComicsViewerSurfaceState
    extends State<WindowsComicsViewerSurface> {
  final WindowsComicsViewerBackend _backend = WindowsComicsViewerBackend();
  Rect? _lastBounds;
  double? _lastDpr;
  bool _created = false;
  bool _scheduled = false;

  void _scheduleLayout() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || box.size.isEmpty) return;
      final origin = box.localToGlobal(Offset.zero);
      final bounds = origin & box.size;
      final dpr = MediaQuery.devicePixelRatioOf(context);
      if (_lastBounds == bounds && _lastDpr == dpr) return;
      _lastBounds = bounds;
      _lastDpr = dpr;
      try {
        if (!_created) {
          await _backend.create(
            x: bounds.left,
            y: bounds.top,
            width: bounds.width,
            height: bounds.height,
            devicePixelRatio: dpr,
          );
          if (!mounted) return;
          _created = true;
          await widget.controller.attachBackend(_backend);
        } else {
          await _backend.setBounds(
            x: bounds.left,
            y: bounds.top,
            width: bounds.width,
            height: bounds.height,
            devicePixelRatio: dpr,
          );
        }
      } catch (error) {
        widget.controller.markUnsupported(error.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLayout();
    return const SizedBox.expand();
  }

  @override
  void dispose() {
    if (_created) unawaited(_backend.setVisible(false));
    // Controller owns the attached backend and performs final disposal.
    super.dispose();
  }
}
