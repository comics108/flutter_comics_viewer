import 'package:flutter_test/flutter_test.dart';
import 'package:viewer/viewer.dart';
import 'package:viewer/viewer_platform_interface.dart';
import 'package:viewer/viewer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockViewerPlatform
    with MockPlatformInterfaceMixin
    implements ViewerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ViewerPlatform initialPlatform = ViewerPlatform.instance;

  test('$MethodChannelViewer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelViewer>());
  });

  test('getPlatformVersion', () async {
    Viewer viewerPlugin = Viewer();
    MockViewerPlatform fakePlatform = MockViewerPlatform();
    ViewerPlatform.instance = fakePlatform;

    expect(await viewerPlugin.getPlatformVersion(), '42');
  });
}
