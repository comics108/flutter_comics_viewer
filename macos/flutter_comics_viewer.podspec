Pod::Spec.new do |s|
  s.name             = 'flutter_comics_viewer'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for rendering interactive comics and puzzles.'
  s.description      = <<-DESC
Flutter plugin for rendering interactive comics and puzzles with animations and sound.
                       DESC
  s.homepage         = 'https://nativemind.net'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'NativeMind' => 'info@nativemind.net' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_comics_viewer/Sources/flutter_comics_viewer/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
