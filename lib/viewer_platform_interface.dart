import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'viewer_method_channel.dart';

abstract class ViewerPlatform extends PlatformInterface {
  /// Constructs a ViewerPlatform.
  ViewerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ViewerPlatform _instance = MethodChannelViewer();

  /// The default instance of [ViewerPlatform] to use.
  ///
  /// Defaults to [MethodChannelViewer].
  static ViewerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ViewerPlatform] when
  /// they register themselves.
  static set instance(ViewerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
