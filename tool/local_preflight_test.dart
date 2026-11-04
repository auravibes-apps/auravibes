import 'dart:io';

import 'package:test/test.dart';

void main() {
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

  test('catalog changes select the localization audit', () async {
    final fixture = await _localizationFixture();
    addTearDown(() => fixture.root.delete(recursive: true));
    final _ = await fixture.catalog.writeAsString('{"changed": "Changed"}\n');
    final result = await _preflight(fixture.root, fixture.base, dryRun: true);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
      result.stdout,
      contains('fvm dart run tool/localization_audit.dart'),
    );
  });

  test('app Dart changes select the localization audit', () async {
    final fixture = await _localizationFixture();
    addTearDown(() => fixture.root.delete(recursive: true));
    final source = File('${fixture.app.path}/lib/message.dart');
    final _ = await source.parent.create(recursive: true);
    final _ = await source.writeAsString('class Message {}\n');
    final result = await _preflight(fixture.root, fixture.base, dryRun: true);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('tool/localization_audit.dart'));
  });

  test('localization failure stops preflight with its exit code', () async {
    final fixture = await _localizationFixture();
    addTearDown(() => fixture.root.delete(recursive: true));
    final _ = await fixture.catalog.writeAsString('{"changed": "Changed"}\n');
    final result = await _preflight(fixture.root, fixture.base, dryRun: false);
    expect(result.exitCode, 42, reason: result.stderr.toString());
  });
}

Future<({Directory root, Directory app, File catalog, String base})>
_localizationFixture() async {
  final root = await Directory.systemTemp.createTemp('local-preflight-i18n-');
  final app = Directory('${root.path}/apps/auravibes_app');
  final catalog = File('${app.path}/assets/i18n/en.json');
  final _ = await catalog.parent.create(recursive: true);
  final audit = File('${app.path}/tool/localization_audit.dart');
  final _ = await audit.parent.create(recursive: true);
  final _ = await audit.writeAsString('''
import 'dart:io';
void main() => exit(42);
''');
  final _ = await File('${root.path}/pubspec.yaml').writeAsString('''
name: fixture
environment:
  sdk: ^3.13.0
workspace:
  - apps/auravibes_app
''');
  final _ = await File('${app.path}/pubspec.yaml').writeAsString('''
name: auravibes_app
environment:
  sdk: ^3.13.0
resolution: workspace
''');
  final _ = await catalog.writeAsString('{}\n');
  final _ = await _git(root, ['init', '--quiet']);
  final _ = await _git(root, ['config', 'user.name', 'Fixture']);
  final _ = await _git(root, [
    'config',
    'user.email',
    'fixture@example.invalid',
  ]);
  final _ = await _git(root, ['add', '.']);
  final _ = await _git(root, ['commit', '--quiet', '-m', 'base']);

  return (
    root: root,
    app: app,
    catalog: catalog,
    base: await _git(root, ['rev-parse', 'HEAD']),
  );
}

Future<ProcessResult> _preflight(
  Directory root,
  String base, {
  required bool dryRun,
}) {
  final arguments = [
    '${Directory.current.path}/tool/local_preflight.dart',
    if (dryRun) '--dry-run',
    '--base',
    base,
  ];
  final executable = Platform.resolvedExecutable;

  return Process.run(executable, arguments, workingDirectory: root.path);
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
