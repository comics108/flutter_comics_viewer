import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'viewer_platform_interface.dart';

/// An implementation of [ViewerPlatform] that uses method channels.
class MethodChannelViewer extends ViewerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('viewer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
