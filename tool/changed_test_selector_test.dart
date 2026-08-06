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

  test('parses NUL-delimited status and keeps renames atomic', () {
    final changes = parseNameStatus(
      'A\u0000packages/core/lib/new.dart\u0000'
      'M\u0000packages/core/lib/changed.dart\u0000'
      'D\u0000packages/core/lib/deleted.dart\u0000'
      'R100\u0000packages/core/lib/old.dart\u0000'
      'packages/core/lib/new-name.dart\u0000',
    );

    expect(changes.map((change) => change.status), [
      'added',
      'modified',
      'deleted',
      'renamed',
    ]);
    expect(changes.last.oldPath, 'packages/core/lib/old.dart');
    expect(changes.last.newPath, 'packages/core/lib/new-name.dart');
    expect(
      () => parseNameStatus('R100\u0000only-old.dart\u0000'),
      throwsFormatException,
    );
  });

  test('selects direct, transitive, shared, and cross-package consumers', () {
    final result = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/leaf.dart')],
      headSources: _sources,
      baseSources: _sources,
      packageRoots: _roots,
    );

    expect(result.mode, SelectionMode.affected);
    expect(result.packages, {
      'packages/core': [
        'test/behavior_test.dart',
        'test/transitive_behavior_test.dart',
      ],
      'packages/ui': ['test/widget_render_test.dart'],
    });
  });

  test('selects every shared consumer and changed current test', () {
    final shared = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/shared.dart')],
      headSources: _sources,
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(shared.packages['packages/core'], [
      'test/shared_one_test.dart',
      'test/shared_two_test.dart',
    ]);

    final changedTest = selectChangedTests(
      changes: [
        const ChangedFile.modified('packages/core/test/unrelated_test.dart'),
      ],
      headSources: _sources,
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(changedTest.packages, {
      'packages/core': ['test/unrelated_test.dart'],
    });
  });

  test('docs-only and multiple changes are empty or sorted unions', () {
    final docs = selectChangedTests(
      changes: [const ChangedFile.modified('README.md')],
      headSources: _sources,
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(docs.mode, SelectionMode.none);

    final multiple = selectChangedTests(
      changes: [
        const ChangedFile.modified('packages/core/lib/shared.dart'),
        const ChangedFile.modified('packages/core/lib/leaf.dart'),
        const ChangedFile.modified('packages/core/lib/shared.dart'),
      ],
      headSources: _sources,
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(multiple.packages['packages/core'], [
      'test/behavior_test.dart',
      'test/shared_one_test.dart',
      'test/shared_two_test.dart',
      'test/transitive_behavior_test.dart',
    ]);
  });

  test('conditional branches, deletes, and renames remain conservative', () {
    final conditionalSources = {
      ..._sources,
      'packages/core/lib/conditional.dart':
          "import 'leaf.dart' if (dart.library.io) 'leaf_io.dart';\n",
      'packages/core/lib/leaf_io.dart': 'class LeafIo {}',
      'packages/core/test/conditional_test.dart':
          "import 'package:core/conditional.dart';\nvoid main() {}",
    };
    final conditional = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/leaf.dart')],
      headSources: conditionalSources,
      baseSources: conditionalSources,
      packageRoots: _roots,
    );
    expect(
      conditional.packages['packages/core'],
      contains('test/conditional_test.dart'),
    );

    final deletedHead = Map<String, String>.from(_sources)
      ..remove('packages/core/lib/leaf.dart');
    final deleted = selectChangedTests(
      changes: [const ChangedFile.deleted('packages/core/lib/leaf.dart')],
      headSources: deletedHead,
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(
      deleted.packages['packages/core'],
      contains('test/behavior_test.dart'),
    );

    final renamedHead = Map<String, String>.from(_sources)
      ..remove('packages/core/lib/leaf.dart')
      ..['packages/core/lib/renamed_leaf.dart'] = 'class Leaf {}';
    final renamed = selectChangedTests(
      changes: [
        const ChangedFile.renamed(
          oldPath: 'packages/core/lib/leaf.dart',
          newPath: 'packages/core/lib/renamed_leaf.dart',
        ),
      ],
      headSources: renamedHead,
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(
      renamed.packages['packages/core'],
      contains('test/behavior_test.dart'),
    );
    expect(
      renamed.packages.values.expand((paths) => paths),
      isNot(contains('packages/core/lib/leaf.dart')),
    );
  });

  test('graph failures and global paths fail closed', () {
    final unresolved = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/bad.dart')],
      headSources: {
        ..._sources,
        'packages/core/lib/bad.dart': "import 'package:core/missing.dart';",
      },
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(unresolved.mode, SelectionMode.full);

    final parseFailure = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/bad.dart')],
      headSources: {
        ..._sources,
        'packages/core/lib/bad.dart': 'class {',
      },
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(parseFailure.mode, SelectionMode.full);

    final generated = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/value.g.dart')],
      headSources: _sources,
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(generated.mode, SelectionMode.full);
  });

  test('source with no current test consumer returns none', () {
    final result = selectChangedTests(
      changes: [
        const ChangedFile.modified('packages/core/lib/no_consumer.dart'),
      ],
      headSources: {
        ..._sources,
        'packages/core/lib/no_consumer.dart': 'class NoConsumer {}',
      },
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(result.mode, SelectionMode.none);
  });
}

const _roots = <String, String>{
  'core': 'packages/core',
  'ui': 'packages/ui',
};

const _sources = <String, String>{
  'packages/core/lib/leaf.dart': 'class Leaf {}',
  'packages/core/lib/transitive.dart':
      "import 'leaf.dart';\nclass Transitive {}",
  'packages/core/lib/shared.dart': 'class Shared {}',
  'packages/core/test/behavior_test.dart':
      "import 'package:core/leaf.dart';\nvoid main() {}",
  'packages/core/test/transitive_behavior_test.dart':
      "import 'package:core/transitive.dart';\nvoid main() {}",
  'packages/core/test/shared_one_test.dart':
      "import 'package:core/shared.dart';\nvoid main() {}",
  'packages/core/test/shared_two_test.dart':
      "import 'package:core/shared.dart';\nvoid main() {}",
  'packages/core/test/unrelated_test.dart': 'void main() {}',
  'packages/ui/lib/widget.dart':
      "import 'package:core/leaf.dart';\nclass Widget {}",
  'packages/ui/test/widget_render_test.dart':
      "import 'package:ui/widget.dart';\nvoid main() {}",
};
