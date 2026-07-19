import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/puzzle.dart';
import 'package:puzzle/puzzle_platform_interface.dart';
import 'package:puzzle/puzzle_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPuzzlePlatform
    with MockPlatformInterfaceMixin
    implements PuzzlePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PuzzlePlatform initialPlatform = PuzzlePlatform.instance;

  test('$MethodChannelPuzzle is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPuzzle>());
  });

  test('getPlatformVersion', () async {
    Puzzle puzzlePlugin = Puzzle();
    MockPuzzlePlatform fakePlatform = MockPuzzlePlatform();
    PuzzlePlatform.instance = fakePlatform;

    expect(await puzzlePlugin.getPlatformVersion(), '42');
  });
}
