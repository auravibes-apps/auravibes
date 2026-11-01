import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('dry-run prints executable formatter and analyzer commands', () async {
    final root = await Directory.systemTemp.createTemp('local-preflight-');
    addTearDown(() => root.delete(recursive: true));
    final package = Directory('${root.path}/packages/core');
    final _ = await Directory('${package.path}/lib').create(recursive: true);
    final _ = await Directory('${package.path}/test').create(recursive: true);
    final _ = await File('${root.path}/pubspec.yaml').writeAsString('''
name: fixture
workspace:
  - packages/core
''');
    final _ = await File('${package.path}/pubspec.yaml').writeAsString('''
name: core
''');
    final _ = await _git(root, ['init', '--quiet']);
    final _ = await _git(root, ['config', 'user.name', 'Fixture']);
    final _ = await _git(root, [
      'config',
      'user.email',
      'fixture@example.invalid',
    ]);
    final _ = await _git(root, ['add', '.']);
    final _ = await _git(root, ['commit', '--quiet', '-m', 'base']);
    final base = await _git(root, ['rev-parse', 'HEAD']);
    final _ = await File('${package.path}/lib/changed.dart')
        .writeAsString('class Changed {}\n');
    final _ = await File('${package.path}/test/changed_test.dart')
        .writeAsString('void main() {}\n');

    final script = '${Directory.current.path}/tool/local_preflight.dart';
    final result = await Process.run(Platform.resolvedExecutable, [
      script,
      '--dry-run',
      '--base',
      base,
    ], workingDirectory: root.path);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    final output = result.stdout.toString();
    expect(output, contains('fvm dart format --line-length 80'));
    expect(output, contains('fvm dart analyze --fatal-infos --fatal-warnings'));
    expect(output, contains('packages/core/lib/changed.dart'));
    expect(output, contains('packages/core/test/changed_test.dart'));
  });
}

Future<String> _git(Directory root, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: root.path,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return result.stdout.toString().trim();
}
