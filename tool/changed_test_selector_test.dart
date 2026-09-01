import 'dart:io';

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

  test('non-Dart non-global diff returns none', () {
    final result = selectChangedTests(
      changes: [
        const ChangedFile.modified('.pi/pi-lsp.json'),
        const ChangedFile.modified('.pi/settings.json'),
        const ChangedFile.modified('sonar-project.properties'),
      ],
      headSources: {},
      baseSources: {},
      packageRoots: {},
    );

    expect(result.mode, SelectionMode.none);
    expect(result.packages, isEmpty);
  });

  test('non-scoped changes do not force full beside package Dart', () {
    final result = selectChangedTests(
      changes: [
        const ChangedFile.modified('.pi/new-config.json'),
        const ChangedFile.modified('sonar-project.properties'),
        const ChangedFile.modified('packages/core/lib/leaf.dart'),
      ],
      headSources: _sources,
      baseSources: _sources,
      packageRoots: _roots,
    );

    expect(result.mode, SelectionMode.affected);
    expect(result.packages['packages/core'], [
      'test/behavior_test.dart',
      'test/transitive_behavior_test.dart',
    ]);
  });

  test('global change remains full beside non-scoped paths', () {
    final result = selectChangedTests(
      changes: [
        const ChangedFile.modified('.github/workflows/ci.yml'),
        const ChangedFile.modified('.pi/pi-lsp.json'),
        const ChangedFile.modified('sonar-project.properties'),
      ],
      headSources: {},
      baseSources: {},
      packageRoots: {},
    );

    expect(result.mode, SelectionMode.full);
  });

  test('package runtime config change returns full', () {
    final result = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/pubspec.yaml')],
      headSources: {},
      baseSources: {},
      packageRoots: {},
    );

    expect(result.mode, SelectionMode.full);
  });

  test('global classification precedes documentation classification', () {
    for (final path in [
      '.github/README.md',
      'tool/README.md',
      'assets/LICENSE',
    ]) {
      final result = selectChangedTests(
        changes: [ChangedFile.modified(path)],
        headSources: {},
        baseSources: {},
        packageRoots: {},
      );
      expect(result.mode, SelectionMode.full, reason: path);
    }
  });

  test('malformed changed file records return full', () {
    final malformed = [
      ChangedFile(status: 'modified'),
      ChangedFile(status: 'added', oldPath: 'old.dart'),
      ChangedFile(status: 'deleted', newPath: 'new.dart'),
      ChangedFile(status: 'renamed', newPath: 'new.dart'),
    ];

    for (final change in malformed) {
      final result = selectChangedTests(
        changes: [change],
        headSources: {},
        baseSources: {},
        packageRoots: {},
      );
      expect(result.mode, SelectionMode.full, reason: change.status);
    }
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
    expect(() => ChangedFile(status: 'unsupported'), throwsArgumentError);
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

  test('uses marker scope for Serverpod package with nonstandard root/name', () {
    const sources = <String, String>{
      'services/custom-root/lib/leaf.dart': 'class Leaf {}',
      'services/custom-root/test/features/feature_test.dart':
          '''import 'package:odd_name/leaf.dart';\nvoid main() {}''',
      'services/custom-root/test/unit_test.dart':
          '''import 'package:odd_name/leaf.dart';\nvoid main() {}''',
      'services/custom-root/test/integration/test_tools/serverpod_test_tools.dart':
          'class ServerpodMarker {}',
    };
    final result = selectChangedTests(
      changes: [
        const ChangedFile.modified('services/custom-root/lib/leaf.dart'),
      ],
      headSources: sources,
      baseSources: sources,
      packageRoots: const {'odd_name': 'services/custom-root'},
      serverpodPackageRoots: const {'services/custom-root'},
    );

    expect(result.packages, {
      'services/custom-root': ['test/features/feature_test.dart'],
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
          '''import 'leaf.dart' if (dart.library.io) 'leaf_io.dart';\n''',
      'packages/core/lib/leaf_io.dart': 'class LeafIo {}',
      'packages/core/test/conditional_test.dart':
          '''import 'package:core/conditional.dart';\nvoid main() {}''',
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
    expect(deleted.mode, SelectionMode.full);

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
    expect(renamed.mode, SelectionMode.full);
  });

  test('known opaque runtime marker forces full for production change', () {
    final result = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/leaf.dart')],
      headSources: {
        ..._sources,
        'packages/core/lib/runtime.dart': '''import 'dart:ffi';''',
      },
      baseSources: _sources,
      packageRoots: _roots,
    );

    expect(result.mode, SelectionMode.full);
  });

  test('base-only opaque marker covers deleted production change', () {
    final headSources = Map<String, String>.from(_sources)
      ..remove('packages/core/lib/leaf.dart');
    final baseSources = {
      ..._sources,
      'packages/core/lib/runtime.dart': '''import 'dart:mirrors';''',
    };
    final result = selectChangedTests(
      changes: [const ChangedFile.deleted('packages/core/lib/leaf.dart')],
      headSources: headSources,
      baseSources: baseSources,
      packageRoots: _roots,
    );

    expect(result.mode, SelectionMode.full);
  });

  test('head graph does not resolve against base-only files', () {
    final headSources = Map<String, String>.from(_sources)
      ..remove('packages/core/lib/leaf.dart')
      ..['packages/core/lib/changed.dart'] = 'class Changed {}';
    final result = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/changed.dart')],
      headSources: headSources,
      baseSources: _sources,
      packageRoots: _roots,
    );

    expect(result.mode, SelectionMode.full);
  });

  test('graph failures and global paths fail closed', () {
    final unresolved = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/bad.dart')],
      headSources: {
        ..._sources,
        'packages/core/lib/bad.dart': '''import 'package:core/missing.dart';''',
      },
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(unresolved.mode, SelectionMode.full);

    final parseFailure = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/bad.dart')],
      headSources: {..._sources, 'packages/core/lib/bad.dart': 'class {'},
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(parseFailure.mode, SelectionMode.full);

    final packageEscape = selectChangedTests(
      changes: [const ChangedFile.modified('packages/core/lib/escape.dart')],
      headSources: {
        ..._sources,
        'packages/core/lib/escape.dart':
            '''import 'package:core/../../ui/lib/widget.dart';''',
      },
      baseSources: _sources,
      packageRoots: _roots,
    );
    expect(packageEscape.mode, SelectionMode.full);

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
  test('manifest round trips and rejects malformed modes', () {
    final result = SelectionResult(
      mode: SelectionMode.affected,
      packages: {
        'packages/core': ['test/behavior_test.dart'],
      },
      reason: 'reverse import impact',
    );
    expect(SelectionResult.fromJson(result.toJson()).packages, result.packages);
    expect(
      () => SelectionResult.fromJson({'mode': 'wat', 'reason': 'bad'}),
      throwsFormatException,
    );
  });

  test(
    'matrix normalizes shard package and caps shards by test count',
    () async {
      final root = await _runnerFixture();
      addTearDown(() => root.delete(recursive: true));
      final selection = SelectionResult(
        mode: SelectionMode.affected,
        packages: {
          'packages/core': [
            'test/behavior_test.dart',
            'test/features/example_test.dart',
          ],
        },
        reason: 'test',
      );

      final matrix = await buildTestMatrix(
        selection,
        rootPath: root.path,
        shardPackage: r'packages\core',
        shardCount: 3,
      );

      expect(matrix, {
        'include': [
          {
            'package': 'packages/core',
            'shardIndex': 0,
            'totalShards': 2,
            'artifact': 'packages-core-0',
          },
          {
            'package': 'packages/core',
            'shardIndex': 1,
            'totalShards': 2,
            'artifact': 'packages-core-1',
          },
        ],
      });
    },
  );

  test('matrix emits no rows for no affected tests', () async {
    final matrix = await buildTestMatrix(
      SelectionResult(
        mode: SelectionMode.none,
        packages: const {},
        reason: 'docs',
      ),
      rootPath: Directory.current.path,
      shardPackage: 'apps/auravibes_app',
      shardCount: 3,
    );

    expect(matrix, const {'include': <Object>[]});
  });

  test(
    'matrix enumerates full suites without sharding other packages',
    () async {
      final root = await _runnerFixture();
      addTearDown(() => root.delete(recursive: true));

      final matrix = await buildTestMatrix(
        SelectionResult(
          mode: SelectionMode.full,
          packages: const {},
          reason: 'global',
        ),
        rootPath: root.path,
        shardPackage: 'apps/auravibes_app',
        shardCount: 3,
      );

      expect(matrix, {
        'include': [
          {
            'package': 'packages/core',
            'shardIndex': 0,
            'totalShards': 1,
            'artifact': 'packages-core-0',
          },
        ],
      });
    },
  );

  test('runner validates paths before launching', () async {
    final root = await _runnerFixture();
    addTearDown(() => root.delete(recursive: true));
    final selection = SelectionResult(
      mode: SelectionMode.affected,
      packages: {
        'packages/core': ['../outside.dart'],
      },
      reason: 'test',
    );
    var launches = 0;
    final code = await runSelectedTests(
      selection,
      rootPath: root.path,
      launcher:
          ({
            required executable,
            required arguments,
            required workingDirectory,
          }) async {
            launches++;

            return 0;
          },
    );
    expect(code, isNonZero);
    expect(launches, 0);
  });

  test('runner selects Flutter command and propagates failure', () async {
    final root = await _runnerFixture(flutter: true);
    addTearDown(() => root.delete(recursive: true));
    final selection = SelectionResult(
      mode: SelectionMode.affected,
      packages: {
        'packages/core': ['test/behavior_test.dart'],
      },
      reason: 'test',
    );
    var capturedArguments = <String>[];
    final code = await runSelectedTests(
      selection,
      rootPath: root.path,
      launcher:
          ({
            required executable,
            required arguments,
            required workingDirectory,
          }) async {
            capturedArguments = arguments;
            expect(executable, 'flutter');

            return 7;
          },
    );
    expect(code, 7);
    expect(
      capturedArguments,
      containsAllInOrder(['test', '--exclude-tags=integration']),
    );
  });

  test(
    'runner filters to one package, shards, and propagates coverage failure',
    () async {
      final root = await _runnerFixture();
      addTearDown(() => root.delete(recursive: true));
      final selection = SelectionResult(
        mode: SelectionMode.affected,
        packages: {
          'packages/core': ['test/behavior_test.dart'],
        },
        reason: 'test',
      );
      final commands = <List<String>>[];
      final code = await runSelectedTests(
        selection,
        rootPath: root.path,
        launcher:
            ({
              required executable,
              required arguments,
              required workingDirectory,
            }) async {
              commands.add(arguments);
              expect(executable, 'dart');
              expect(workingDirectory, endsWith('packages/core'));

              return arguments.contains('coverage:format_coverage') ? 9 : 0;
            },
        packageRoot: 'packages/core',
        totalShards: 2,
        shardIndex: 1,
        coverage: true,
      );

      expect(code, 9);
      expect(
        commands.firstOrNull,
        containsAll([
          '--coverage=coverage',
          '--total-shards=2',
          '--shard-index=1',
        ]),
      );
      expect(commands.last, containsAll(['run', 'coverage:format_coverage']));
    },
  );

  test(
    'runner rejects an unselected package and invalid shard before launch',
    () async {
      final root = await _runnerFixture();
      addTearDown(() => root.delete(recursive: true));
      final selection = SelectionResult(
        mode: SelectionMode.affected,
        packages: {
          'packages/core': ['test/behavior_test.dart'],
        },
        reason: 'test',
      );
      var launches = 0;
      Future<int> launcher({
        required String executable,
        required List<String> arguments,
        required String workingDirectory,
      }) async {
        expect(executable, 'dart');
        expect(arguments, isEmpty);
        expect(workingDirectory, endsWith('packages/core'));
        launches++;

        return 0;
      }

      expect(
        await runSelectedTests(
          selection,
          rootPath: root.path,
          launcher: launcher,
          packageRoot: 'packages/missing',
        ),
        isNonZero,
      );
      expect(
        await runSelectedTests(
          selection,
          rootPath: root.path,
          launcher: launcher,
          totalShards: 2,
          shardIndex: 2,
        ),
        isNonZero,
      );
      expect(launches, 0);
    },
  );

  test(
    'runner rejects sharding multiple selected packages before launching',
    () async {
      final root = await _runnerFixture();
      addTearDown(() => root.delete(recursive: true));
      final other = Directory('${root.path}/packages/other');
      final _ = await Directory('${other.path}/test').create(recursive: true);
      final _ = await File('${root.path}/pubspec.yaml').writeAsString('''
name: fixture
workspace:
  - packages/core
  - packages/other
''');
      final _ = await File('${other.path}/pubspec.yaml').writeAsString('''
name: other
''');
      final _ = await File('${other.path}/test/other_test.dart')
          .writeAsString('void main() {}');
      var launches = 0;

      final code = await runSelectedTests(
        SelectionResult(
          mode: SelectionMode.affected,
          packages: {
            'packages/core': ['test/behavior_test.dart'],
            'packages/other': ['test/other_test.dart'],
          },
          reason: 'test',
        ),
        rootPath: root.path,
        launcher:
            ({
              required executable,
              required arguments,
              required workingDirectory,
            }) async {
              launches++;

              return 0;
            },
        totalShards: 2,
        shardIndex: 0,
      );

      expect(code, isNonZero);
      expect(launches, 0);
    },
  );

  test('Serverpod runner limits paths to supported subtrees', () async {
    final root = await _runnerFixture(serverpod: true);
    addTearDown(() => root.delete(recursive: true));
    final selection = SelectionResult(
      mode: SelectionMode.affected,
      packages: {
        'packages/core': ['test/features/example_test.dart'],
      },
      reason: 'test',
    );
    var capturedArguments = <String>[];
    final code = await runSelectedTests(
      selection,
      rootPath: root.path,
      launcher:
          ({
            required executable,
            required arguments,
            required workingDirectory,
          }) async {
            capturedArguments = arguments;

            return 0;
          },
    );
    expect(code, 0);
    expect(capturedArguments, contains('test/features/example_test.dart'));
    expect(capturedArguments.skip(2), isNot(contains('test')));
  });
}

Future<Directory> _runnerFixture({
  bool flutter = false,
  bool serverpod = false,
}) async {
  final root = await Directory.systemTemp.createTemp('changed-selector-');
  final package = Directory('${root.path}/packages/core');
  final _ = await Directory('${package.path}/test/features')
      .create(recursive: true);
  final _ = await File('${root.path}/pubspec.yaml').writeAsString('''
name: fixture
workspace:
  - packages/core
''');
  final _ = await File('${package.path}/pubspec.yaml').writeAsString('''
name: core
dependencies:
${flutter ? '  flutter:\n    sdk: flutter\n' : ''}
''');
  final _ = await File('${package.path}/test/behavior_test.dart')
      .writeAsString('void main() {}');
  final _ = await File('${package.path}/test/features/example_test.dart')
      .writeAsString('void main() {}');
  if (serverpod) {
    final _ = await File(
      '${package.path}/test/integration/test_tools/serverpod_test_tools.dart',
    ).create(recursive: true);
  }

  return root;
}

const _roots = <String, String>{'core': 'packages/core', 'ui': 'packages/ui'};

const _sources = <String, String>{
  'packages/core/lib/leaf.dart': 'class Leaf {}',
  'packages/core/lib/transitive.dart':
      '''import 'leaf.dart';\nclass Transitive {}''',
  'packages/core/lib/shared.dart': 'class Shared {}',
  'packages/core/test/behavior_test.dart':
      '''import 'package:core/leaf.dart';\nvoid main() {}''',
  'packages/core/test/transitive_behavior_test.dart':
      '''import 'package:core/transitive.dart';\nvoid main() {}''',
  'packages/core/test/shared_one_test.dart':
      '''import 'package:core/shared.dart';\nvoid main() {}''',
  'packages/core/test/shared_two_test.dart':
      '''import 'package:core/shared.dart';\nvoid main() {}''',
  'packages/core/test/unrelated_test.dart': 'void main() {}',
  'packages/ui/lib/widget.dart':
      '''import 'package:core/leaf.dart';\nclass Widget {}''',
  'packages/ui/test/widget_render_test.dart':
      '''import 'package:ui/widget.dart';\nvoid main() {}''',
};
