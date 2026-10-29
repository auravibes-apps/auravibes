import 'dart:io';

import 'package:test/test.dart';

void main() {
  final script = File('tool/validate_changed_dart.dart').absolute.path;

  test('returns a failing process status for formatting violations', () async {
    final result = await _runFixture(script, 'void main( ){print(1);}\n');

    expect(result.stdout, contains('1 changed'));
    expect(result.exitCode, isNot(0), reason: '${result.stderr}');
  });

  test('returns a failing process status for analyzer errors', () async {
    final result = await _runFixture(
      script,
      'void main() {\n'
      '  int value = true;\n'
      '  print(value);\n'
      '}\n',
    );

    expect(result.stdout, contains('INVALID_ASSIGNMENT'));
    expect(result.exitCode, isNot(0), reason: '${result.stderr}');
  });

  test(
    'respects nested analyzer exclusions without skipping formatting',
    () async {
      final result = await _runFixture(
        script,
        'void main() {}\n',
        files: {
          'app/analysis_options.yaml':
              'analyzer:\n  exclude:\n    - lib/i18n/*\n',
          'app/lib/i18n/locale_keys.dart': 'const int value = true;\n',
        },
      );

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('Formatted 2 files'));
    },
  );

  test('still analyzes generated-looking names outside exclusions', () async {
    final result = await _runFixture(
      script,
      'void main() {}\n',
      files: {'locale_keys.dart': 'const int value = true;\n'},
    );

    expect(result.stdout, contains('INVALID_ASSIGNMENT'));
    expect(result.exitCode, isNot(0), reason: '${result.stderr}');
  });
}

Future<ProcessResult> _runFixture(
  String script,
  String source, {
  Map<String, String> files = const {},
}) async {
  final fixture = await Directory.systemTemp.createTemp('changed-dart-');
  addTearDown(() => fixture.delete(recursive: true));
  await _git(fixture, ['init', '--quiet']);
  await _git(fixture, [
    '-c',
    'user.name=Fixture',
    '-c',
    'user.email=fixture@example.invalid',
    '-c',
    'commit.gpgsign=false',
    'commit',
    '--quiet',
    '--allow-empty',
    '-m',
    'fixture',
  ]);
  final _ = await File('${fixture.path}/main.dart').writeAsString(source);
  for (final entry in files.entries) {
    final file = File('${fixture.path}/${entry.key}');
    final _ = await file.parent.create(recursive: true);
    final _ = await file.writeAsString(entry.value);
  }
  final arguments = [script];

  return await Process.run(
    Platform.resolvedExecutable,
    arguments,
    workingDirectory: fixture.path,
  );
}

Future<void> _git(Directory fixture, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: fixture.path,
  );
  expect(result.exitCode, 0, reason: '${result.stderr}');
}
