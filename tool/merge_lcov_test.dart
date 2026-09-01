import 'dart:io';

import 'package:test/test.dart';

import 'merge_lcov.dart';

void main() {
  test('merges shard hits and normalizes package source paths', () async {
    final root = await Directory.systemTemp.createTemp('merge-lcov-');
    addTearDown(() => root.delete(recursive: true));
    final repository = Directory('${root.path}/repo')..createSync();
    final artifacts = Directory('${root.path}/artifacts')..createSync();
    await _writeReport(
      artifacts,
      name: 'first',
      packageRoot: 'apps/auravibes_app',
      report: '''
SF:lib/value.dart
FN:2,work
FNDA:1,work
DA:2,1
DA:3,0
BRDA:3,0,0,1
end_of_record
''',
    );
    await _writeReport(
      artifacts,
      name: 'second',
      packageRoot: 'apps/auravibes_app',
      report:
          '''
SF:${repository.path}/apps/auravibes_app/lib/value.dart
FN:2,work
FNDA:2,work
DA:2,3
DA:3,1
BRDA:3,0,0,2
end_of_record
''',
    );

    final output = '${root.path}/coverage/lcov.info';
    await mergeLcovReports(
      inputRoot: artifacts.path,
      outputPath: output,
      repositoryRoot: repository.path,
      expectedReports: 2,
    );

    expect(await File(output).readAsString(), '''
SF:apps/auravibes_app/lib/value.dart
FN:2,work
FNDA:3,work
FNF:1
FNH:1
DA:2,4
DA:3,1
LF:2
LH:2
BRDA:3,0,0,3
BRF:1
BRH:1
end_of_record
''');
  });

  test(
    'drops generated sources while retaining expected report count',
    () async {
      final root = await Directory.systemTemp.createTemp('merge-lcov-');
      addTearDown(() => root.delete(recursive: true));
      final artifacts = Directory('${root.path}/artifacts')..createSync();
      await _writeReport(
        artifacts,
        name: 'generated',
        packageRoot: 'packages/core',
        report: '''
SF:lib/value.g.dart
DA:1,1
end_of_record
''',
      );

      final output = '${root.path}/coverage/lcov.info';
      await mergeLcovReports(
        inputRoot: artifacts.path,
        outputPath: output,
        repositoryRoot: root.path,
        expectedReports: 1,
      );

      expect(await File(output).readAsString(), isEmpty);
    },
  );

  test('accepts CRLF reports', () async {
    final root = await Directory.systemTemp.createTemp('merge-lcov-');
    addTearDown(() => root.delete(recursive: true));
    final artifacts = Directory('${root.path}/artifacts')..createSync();
    await _writeReport(
      artifacts,
      name: 'crlf',
      packageRoot: 'packages/core',
      report: 'SF:lib/value.dart\r\nDA:1,1\r\nend_of_record\r\n',
    );

    final output = '${root.path}/coverage/lcov.info';
    await mergeLcovReports(
      inputRoot: artifacts.path,
      outputPath: output,
      repositoryRoot: root.path,
      expectedReports: 1,
    );

    expect(await File(output).readAsString(), '''
SF:packages/core/lib/value.dart
DA:1,1
LF:1
LH:1
end_of_record
''');
  });

  test('rejects missing reports and non-repository source paths', () async {
    final root = await Directory.systemTemp.createTemp('merge-lcov-');
    addTearDown(() => root.delete(recursive: true));
    final artifacts = Directory('${root.path}/artifacts')..createSync();
    await _writeReport(
      artifacts,
      name: 'outside',
      packageRoot: 'packages/core',
      report: '''
SF:/tmp/outside.dart
DA:1,1
end_of_record
''',
    );

    final _ = await expectLater(
      mergeLcovReports(
        inputRoot: artifacts.path,
        outputPath: '${root.path}/coverage/lcov.info',
        repositoryRoot: root.path,
        expectedReports: 2,
      ),
      throwsFormatException,
    );
    final _ = await expectLater(
      mergeLcovReports(
        inputRoot: artifacts.path,
        outputPath: '${root.path}/coverage/lcov.info',
        repositoryRoot: root.path,
        expectedReports: 1,
      ),
      throwsFormatException,
    );
  });

  test('rejects Windows absolute package roots', () async {
    final root = await Directory.systemTemp.createTemp('merge-lcov-');
    addTearDown(() => root.delete(recursive: true));
    final artifacts = Directory('${root.path}/artifacts')..createSync();
    await _writeReport(
      artifacts,
      name: 'windows-root',
      packageRoot: r'C:\package',
      report: '''
SF:lib/value.dart
DA:1,1
end_of_record
''',
    );

    final _ = await expectLater(
      mergeLcovReports(
        inputRoot: artifacts.path,
        outputPath: '${root.path}/coverage/lcov.info',
        repositoryRoot: root.path,
        expectedReports: 1,
      ),
      throwsFormatException,
    );
  });

  test('rejects Windows absolute source paths', () async {
    final root = await Directory.systemTemp.createTemp('merge-lcov-');
    addTearDown(() => root.delete(recursive: true));
    final artifacts = Directory('${root.path}/artifacts')..createSync();
    await _writeReport(
      artifacts,
      name: 'windows-source',
      packageRoot: 'packages/core',
      report: r'''
SF:C:\temp\outside.dart
DA:1,1
end_of_record
''',
    );

    final _ = await expectLater(
      mergeLcovReports(
        inputRoot: artifacts.path,
        outputPath: '${root.path}/coverage/lcov.info',
        repositoryRoot: root.path,
        expectedReports: 1,
      ),
      throwsFormatException,
    );
  });
}

Future<void> _writeReport(
  Directory artifacts, {
  required String name,
  required String packageRoot,
  required String report,
}) async {
  final directory = Directory('${artifacts.path}/$name')
    ..createSync(recursive: true);
  final _ = await File('${directory.path}/package-root')
      .writeAsString(packageRoot);
  final _ = await File('${directory.path}/lcov.info').writeAsString(report);
}
