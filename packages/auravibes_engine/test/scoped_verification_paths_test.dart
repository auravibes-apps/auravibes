import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes only reported paths and keeps their first-seen order', () {
    expect(
      normalizeScopedVerificationPaths([
        'lib//./first.dart',
        './lib/second.dart',
        'lib/first.dart',
      ]),
      ['lib/first.dart', 'lib/second.dart'],
    );
  });

  for (final path in [
    '', '.', './', '/', '/tmp/outside.dart', '../outside.dart',
    'lib/../../outside.dart', 'lib/../inside.dart', r'C:\file.dart',
    'C:/file.dart', r'\\server\share\file.dart', 'file:///tmp/file.dart',
    'https://example.test/file.dart', 'lib/\u0000file.dart',
    'lib/\nfile.dart', 'lib/\u007ffile.dart', '-option.dart',
    'lib/-option.dart',
  ]) {
    test('rejects a whole report containing ${path.replaceAll('\n', r'\n')}', () {
      expect(
        () => normalizeScopedVerificationPaths(['lib/safe.dart', path]),
        throwsFormatException,
      );
    });
  }

  test('keeps shell punctuation and encoded names as literal path data', () {
    expect(
      normalizeScopedVerificationPaths([
        r'lib/$(touch marker); name.dart',
        'lib/"quoted".dart',
        'lib/%2e%2e.dart',
      ]),
      [r'lib/$(touch marker); name.dart', 'lib/"quoted".dart', 'lib/%2e%2e.dart'],
    );
  });

  test('bounds report count before deduplication and UTF-8 path size', () {
    expect(
      () => normalizeScopedVerificationPaths(List.filled(129, 'same.dart')),
      throwsFormatException,
    );
    expect(
      () => normalizeScopedVerificationPaths(['${'é' * 2047}.dart']),
      throwsFormatException,
    );
    expect(normalizeScopedVerificationPaths(['a' * 4096]), hasLength(1));
  });

  test('ignores absent metadata and never parses model text', () {
    expect(parseScopedEditReport('changed paths: lib/main.dart'), isNull);
    expect(parseScopedEditReport({'content': 'lib/main.dart'}), isNull);
    expect(
      parseScopedEditReport(
        '{"auravibesChangedPaths":{"version":1,"workspaceRoot":"root",'
        '"paths":["lib/main.dart"]}}',
      ),
      isNull,
    );
  });

  test('accepts only a versioned structured report with no authority fields', () {
    final input = <String, Object?>{
      'auravibesChangedPaths': {
        'version': 1,
        'workspaceRoot': 'checkout',
        'paths': ['lib//main.dart'],
      },
    };
    final report = parseScopedEditReport(input);
    expect(report?.workspaceRoot, 'checkout');
    expect(report?.paths, ['lib/main.dart']);
    for (final field in ['command', 'runnerToolId', 'checks', 'enabled']) {
      expect(
        () => parseScopedEditReport({
          'auravibesChangedPaths': {
            'version': 1,
            'workspaceRoot': 'checkout',
            'paths': ['lib/main.dart'],
            field: 'injected',
          },
        }),
        throwsFormatException,
      );
    }
  });

  test('rejects malformed reports instead of treating them as safe paths', () {
    for (final value in <Object?>[
      null,
      [],
      {'version': 2, 'workspaceRoot': 'root', 'paths': ['main.dart']},
      {'version': 1.0, 'workspaceRoot': 'root', 'paths': ['main.dart']},
      {'version': 1, 'workspaceRoot': '', 'paths': ['main.dart']},
      {'version': 1, 'workspaceRoot': 'root', 'paths': ['main.dart', 3]},
      {'version': 1, 'workspaceRoot': 'root', 'paths': ['../main.dart']},
    ]) {
      expect(
        () => parseScopedEditReport({'auravibesChangedPaths': value}),
        throwsFormatException,
      );
    }
  });

  test('selects only configured checks matching normalized reported paths', () {
    final settings = _settings();
    final report = ScopedEditReport(
      workspaceRoot: 'checkout',
      paths: ['lib/a.dart', 'README.md', 'lib/b.dart'],
    );
    final selections = selectScopedVerificationChecks(settings, report);
    expect(selections.map((selection) => selection.check.id), ['dart', 'all']);
    expect(selections.first.paths, ['lib/a.dart', 'lib/b.dart']);
    expect(selections.last.paths, ['lib/a.dart', 'README.md', 'lib/b.dart']);
  });

  test('disabled settings select no commands even with a mismatched report', () {
    expect(
      selectScopedVerificationChecks(
        ScopedVerificationSettings(),
        ScopedEditReport(workspaceRoot: 'other', paths: ['main.dart']),
      ),
      isEmpty,
    );
  });

  test('report and selection cannot be changed after validation', () {
    final paths = ['a.dart'];
    final report = ScopedEditReport(workspaceRoot: 'checkout', paths: paths);
    paths.add('../escape.dart');
    expect(report.paths, ['a.dart']);
    expect(() => report.paths.clear(), throwsUnsupportedError);
    final selection = selectScopedVerificationChecks(_settings(), report).first;
    expect(() => selection.paths.add('unreported.dart'), throwsUnsupportedError);
  });

  test('different root and empty reports cannot select commands', () {
    expect(
      () => selectScopedVerificationChecks(
        _settings(),
        ScopedEditReport(workspaceRoot: 'checkout-sibling', paths: ['a.dart']),
      ),
      throwsFormatException,
    );
    expect(
      selectScopedVerificationChecks(
        _settings(),
        ScopedEditReport(workspaceRoot: 'checkout', paths: const []),
      ),
      isEmpty,
    );
  });
}

ScopedVerificationSettings _settings() => ScopedVerificationSettings(
  enabled: true,
  runnerToolId: 'runner',
  mcpServerId: 'server',
  workspaceRoot: 'checkout',
  editToolIds: const {'edit'},
  checks: [
    ScopedVerificationCheck(
      id: 'dart', executable: 'dart', arguments: const ['analyze'],
      pathSuffixes: const ['.dart'],
    ),
    ScopedVerificationCheck(id: 'all', executable: 'check'),
  ],
);
