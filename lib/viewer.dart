
import 'viewer_platform_interface.dart';

class Viewer {
  Future<String?> getPlatformVersion() {
    return ViewerPlatform.instance.getPlatformVersion();
  }
}
