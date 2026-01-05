import 'open_file_stub.dart' if (dart.library.io) 'open_file_io.dart' as impl;

Future<void> openFilePath(String filePath) {
  return impl.openFilePath(filePath);
}
