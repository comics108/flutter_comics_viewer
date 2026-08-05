import 'dart:typed_data';

import 'source_bytes_stub.dart'
    if (dart.library.io) 'source_bytes_io.dart'
    as implementation;

Future<Uint8List> readViewerPath(String path) =>
    implementation.readViewerPath(path);
