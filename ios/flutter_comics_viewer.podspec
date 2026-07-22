#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_comics_viewer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_comics_viewer'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for rendering interactive comics and puzzles.'
  s.description      = <<-DESC
Flutter plugin for rendering interactive comics and puzzles with animations and sound.
Provides a unified API for both iOS and Android platforms.
                       DESC
  s.homepage         = 'https://nativemind.net'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'NativeMind' => 'info@nativemind.net' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_comics_viewer/Sources/flutter_comics_viewer/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Link to ComicsViewer Swift Package
  # Note: The ComicsViewer package needs to be added to the app's Xcode project
  # This podspec assumes ComicsViewer is available as a local Swift Package
end
