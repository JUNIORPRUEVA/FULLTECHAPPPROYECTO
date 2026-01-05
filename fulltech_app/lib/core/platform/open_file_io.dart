import 'dart:io';

Future<void> openFilePath(String filePath) async {
  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', filePath]);
    return;
  }
  if (Platform.isMacOS) {
    await Process.run('open', [filePath]);
    return;
  }
  if (Platform.isLinux) {
    await Process.run('xdg-open', [filePath]);
    return;
  }

  throw UnsupportedError('Unsupported desktop platform');
}
