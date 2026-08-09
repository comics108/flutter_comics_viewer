import 'package:path_provider/path_provider.dart';

/// Ensures the directory used internally by audioplayers' BytesSource
/// workaround exists before it writes a temporary media file.
Future<void> prepareAudioBytesCache() async {
  final directory = await getTemporaryDirectory();
  if (!await directory.exists()) await directory.create(recursive: true);
}
