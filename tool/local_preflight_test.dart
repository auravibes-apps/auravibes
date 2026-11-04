import 'dart:io';

import 'package:test/test.dart';

void main() {
  const preflightTimeout = Timeout(.new(minutes: 2));
  test('dry-run prints executable formatter and analyzer commands', () async {
    final root = await Directory.systemTemp.createTemp('local-preflight-');
    addTearDown(() => root.delete(recursive: true));
    final package = Directory('${root.path}/packages/core');
    final other = Directory('${root.path}/packages/other');
    final _ = await Directory('${package.path}/lib').create(recursive: true);
    final _ = await Directory('${package.path}/test').create(recursive: true);
    final _ = await Directory('${other.path}/lib').create(recursive: true);
    final _ = await File('${root.path}/pubspec.yaml').writeAsString('''
name: fixture
workspace:
  - packages/core
  - packages/other
''');
    final _ = await File('${package.path}/pubspec.yaml').writeAsString('''
name: core
''');
    final _ = await File('${other.path}/pubspec.yaml').writeAsString('''
name: other
''');
    final _ = await File('${package.path}/analysis_options.yaml')
        .writeAsString('');
    final _ = await File('${other.path}/analysis_options.yaml')
        .writeAsString('');
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
    final _ = await File('${other.path}/lib/changed.dart')
        .writeAsString('class Other {}\n');
    final _ = await File('${package.path}/test/changed_test.dart')
        .writeAsString('void main() {}\n');

    final script = '${Directory.current.path}/tool/local_preflight.dart';
    final arguments = [script, '--dry-run', '--base', base];
    final result = await Process.run(
      Platform.resolvedExecutable,
      arguments,
      workingDirectory: root.path,
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    final output = result.stdout.toString();
    expect(output, contains('fvm dart format --line-length 80'));
    expect(output, contains('fvm dart analyze --fatal-infos --fatal-warnings'));
    expect(output, contains('packages/core/lib/changed.dart'));
    expect(output, contains('packages/core/test/changed_test.dart'));
    expect(
      RegExp('fvm dart analyze --fatal-infos --fatal-warnings')
          .allMatches(output),
      hasLength(2),
    );
    expect(output, contains('packages/other/lib/changed.dart'));
    expect(
      output,
      isNot(contains('Changed paths considered for this selection')),
    );
    expect(output, isNot(contains('tool/localization_audit.dart')));
  });

  test(
    'plans the localization audit for app code and catalog changes',
    () async {
      final fixture = await _localizationFixture();
      final app = Directory('${fixture.root.path}/apps/auravibes_app');
      final source = File('${app.path}/lib/changed.dart');
      final catalog = File('${app.path}/assets/i18n/en.json');
      final unrelated = File(
        '${fixture.root.path}/packages/core/lib/other.dart',
      );

      Future<String> plan() async {
        final result = await _preflight(fixture, dryRun: true);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        expect(
          result.stdout,
          isNot(contains('fixture localization audit ran')),
        );

        return result.stdout.toString();
      }

      final _ = await source.writeAsString('class Changed {}\n');
      expect(
        await plan(),
        contains('fvm dart run tool/localization_audit.dart'),
      );
      final _ = await source.delete();

      final _ = await catalog.writeAsString('{"changed": "value"}\n');
      expect(
        await plan(),
        contains('fvm dart run tool/localization_audit.dart'),
      );
      final _ = await catalog.delete();
      expect(
        await plan(),
        contains('fvm dart run tool/localization_audit.dart'),
      );

      final _ = await _git(fixture.root, [
        'checkout',
        '--',
        'apps/auravibes_app/assets/i18n/en.json',
      ]);
      final _ = await _git(fixture.root, [
        'mv',
        'apps/auravibes_app/assets/i18n/en.json',
        'packages/core/lib/en.json',
      ]);
      expect(
        await plan(),
        contains('fvm dart run tool/localization_audit.dart'),
      );
      final _ = await _git(fixture.root, [
        'mv',
        'packages/core/lib/en.json',
        'apps/auravibes_app/assets/i18n/en.json',
      ]);
      final _ = await unrelated.writeAsString('class Other {}\n');
      expect(
        await plan(),
        isNot(contains('fvm dart run tool/localization_audit.dart')),
      );
    },
    timeout: preflightTimeout,
  );

  test('stops preflight when the localization audit fails', () async {
    final fixture = await _localizationFixture();
    final catalog = File(
      '${fixture.root.path}/apps/auravibes_app/assets/i18n/en.json',
    );
    final _ = await catalog.writeAsString('{"changed": "value"}\n');

    final result = await _preflight(fixture);
    expect(result.exitCode, 23, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('fixture localization audit ran'));
  });

  test('continues when the localization audit succeeds', () async {
    final fixture = await _localizationFixture(auditExitCode: 0);
    final catalog = File(
      '${fixture.root.path}/apps/auravibes_app/assets/i18n/en.json',
    );
    final _ = await catalog.writeAsString('{"changed": "value"}\n');

    final result = await _preflight(fixture);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('fixture localization audit ran'));
  });
}

Future<({Directory root, String base})> _localizationFixture({
  int auditExitCode = 23,
}) async {
  final root = await Directory.systemTemp.createTemp('local-preflight-l10n-');
  addTearDown(() => root.delete(recursive: true));
  final app = Directory('${root.path}/apps/auravibes_app');
  final _ = await Directory('${app.path}/lib').create(recursive: true);
  final _ = await Directory('${app.path}/assets/i18n').create(recursive: true);
  final _ = await Directory('${app.path}/tool').create(recursive: true);
  final _ = await Directory('${root.path}/packages/core/lib')
      .create(recursive: true);
  final _ = await File('${root.path}/pubspec.yaml').writeAsString('''
name: fixture
environment:
  sdk: ^3.13.0
workspace:
  - apps/auravibes_app
  - packages/core
''');
  for (final package in [app.path, '${root.path}/packages/core']) {
    final name = package == app.path ? 'fixture_app' : 'fixture_core';
    final _ = await File('$package/pubspec.yaml').writeAsString('''
name: $name
resolution: workspace
environment:
  sdk: ^3.13.0
''');
  }
  final _ = await File('${app.path}/assets/i18n/en.json').writeAsString('{}\n');
  final _ = await File('${app.path}/tool/localization_audit.dart')
      .writeAsString('''
import 'dart:io';
void main() {
  print('fixture localization audit ran');
  exit($auditExitCode);
}
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

  return (root: root, base: base);
}

Future<ProcessResult> _preflight(
  ({Directory root, String base}) fixture, {
  bool dryRun = false,
}) {
  final script = '${Directory.current.path}/tool/local_preflight.dart';
  final arguments = [script, if (dryRun) '--dry-run', '--base', fixture.base];

  return Process.run(
    Platform.resolvedExecutable,
    arguments,
    workingDirectory: fixture.root.path,
  );
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
