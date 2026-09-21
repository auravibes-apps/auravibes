import 'dart:io';

import 'package:auravibes_app/app_storage_namespace.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test(
    'clones the default database without overwriting a scoped database',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clone_database_',
      );
      addTearDown(() => directory.delete(recursive: true));

      const hashSource = '/workspace/new';
      final defaultDatabase = File(
        path.join(
          directory.path,
          '${AppStorageNamespace.forHashSource(null)}.sqlite',
        ),
      );
      final scopedDatabase = File(
        path.join(
          directory.path,
          '${AppStorageNamespace.forHashSource(hashSource)}.sqlite',
        ),
      );
      final _ = await defaultDatabase.writeAsString('default data');

      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'tool/clone_database.dart',
        '--database-directory',
        directory.path,
        '--hash-source',
        hashSource,
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(await scopedDatabase.readAsString(), 'default data');

      final _ = await scopedDatabase.writeAsString('scoped data');
      final secondResult = await Process.run(Platform.resolvedExecutable, [
        'run',
        'tool/clone_database.dart',
        '--database-directory',
        directory.path,
        '--hash-source',
        hashSource,
      ]);

      expect(secondResult.exitCode, 0, reason: '${secondResult.stderr}');
      expect(await scopedDatabase.readAsString(), 'scoped data');
    },
  );
}
