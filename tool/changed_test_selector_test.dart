import 'package:test/test.dart';

import 'changed_test_selector.dart';

void main() {
  test('docs-only diff returns none', () {
    final result = selectChangedTests(
      changes: [const ChangedFile.modified('README.md')],
      headSources: {},
      baseSources: {},
      packageRoots: {},
    );

    expect(result.mode, SelectionMode.none);
    expect(result.packages, isEmpty);
  });

  test('global change returns full', () {
    final result = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/pubspec.yaml')],
      headSources: {},
      baseSources: {},
      packageRoots: {},
    );

    expect(result.mode, SelectionMode.full);
  });

  test('result serializes mode and omits empty packages for none/full', () {
    final none = SelectionResult(
      mode: SelectionMode.none,
      packages: {},
      reason: 'No executable test input.',
    );
    final full = SelectionResult(
      mode: SelectionMode.full,
      packages: {},
      reason: 'Global or ambiguous test input.',
    );

    expect(none.toJson(), {
      'mode': 'none',
      'reason': 'No executable test input.',
    });
    expect(full.toJson(), {
      'mode': 'full',
      'reason': 'Global or ambiguous test input.',
    });
  });

  test('result serializes affected package paths', () {
    final result = SelectionResult(
      mode: SelectionMode.affected,
      packages: {
        'packages/core': ['test/core_test.dart'],
      },
      reason: 'reverse import impact',
    );

    expect(result.toJson(), {
      'mode': 'affected',
      'packages': {
        'packages/core': ['test/core_test.dart'],
      },
      'reason': 'reverse import impact',
    });
  });

  test('rejects unsupported status at runtime', () {
    expect(
      () => ChangedFile(status: 'unsupported'),
      throwsArgumentError,
    );
  });

  test('freezes result package inputs and outputs', () {
    final paths = ['test/core_test.dart'];
    final packages = <String, List<String>>{'packages/core': paths};
    final result = SelectionResult(
      mode: SelectionMode.affected,
      packages: packages,
      reason: 'reverse import impact',
    );

    paths.add('test/other_test.dart');
    packages['packages/other'] = ['test/other_test.dart'];

    expect(result.packages, {
      'packages/core': ['test/core_test.dart'],
    });
    expect(
      () => result.packages['packages/core']!.add('test/other_test.dart'),
      throwsUnsupportedError,
    );
    expect(
      () => result.packages['packages/other'] = ['test/other_test.dart'],
      throwsUnsupportedError,
    );
  });
}
