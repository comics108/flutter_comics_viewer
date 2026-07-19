import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'puzzle_method_channel.dart';

abstract class PuzzlePlatform extends PlatformInterface {
  /// Constructs a PuzzlePlatform.
  PuzzlePlatform() : super(token: _token);

  static final Object _token = Object();

  static PuzzlePlatform _instance = MethodChannelPuzzle();

  /// The default instance of [PuzzlePlatform] to use.
  ///
  /// Defaults to [MethodChannelPuzzle].
  static PuzzlePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PuzzlePlatform] when
  /// they register themselves.
  static set instance(PuzzlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
