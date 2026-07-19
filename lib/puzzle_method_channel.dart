import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'puzzle_platform_interface.dart';

/// An implementation of [PuzzlePlatform] that uses method channels.
class MethodChannelPuzzle extends PuzzlePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('puzzle');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
