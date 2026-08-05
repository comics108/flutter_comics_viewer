import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readViewerPath(String path) => File(path).readAsBytes();
