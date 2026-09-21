import 'dart:io';

import 'package:path/path.dart' as path;

Future<String> applicationDocumentsDirectory() async {
  final environment = Platform.environment;
  if (Platform.isMacOS) {
    final home = environment['HOME'];
    if (home == null) throw StateError('HOME is not set.');

    return path.join(
      home,
      'Library',
      'Containers',
      'me.auravibes.app.dev',
      'Data',
      'Documents',
    );
  }
  if (Platform.isLinux) {
    final result = await Process.run('xdg-user-dir', ['DOCUMENTS']);
    final documents = '${result.stdout}'.trim();
    if (result.exitCode == 0 && documents.isNotEmpty) return documents;

    final home = environment['HOME'];
    if (home != null) return path.join(home, 'Documents');
  }
  if (Platform.isWindows) {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      '[Environment]::GetFolderPath("MyDocuments")',
    ]);
    final documents = '${result.stdout}'.trim();
    if (result.exitCode == 0 && documents.isNotEmpty) return documents;
  }

  throw UnsupportedError(
    'Cannot locate the application documents directory. '
    'Pass --database-directory.',
  );
}
