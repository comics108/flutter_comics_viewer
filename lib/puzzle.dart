
import 'puzzle_platform_interface.dart';

class Puzzle {
  Future<String?> getPlatformVersion() {
    return PuzzlePlatform.instance.getPlatformVersion();
  }
}
