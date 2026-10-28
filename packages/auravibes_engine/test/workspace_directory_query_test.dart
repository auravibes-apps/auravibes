import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  final tree = <String?, List<Map<String, Object?>>>{
    null: [
      {'id': 'sales', 'kind': 'folder', 'name': 'Sales'},
      {'id': 'notes', 'kind': 'file', 'name': 'Notes.txt'},
    ],
    'sales': [
      {'id': 'leads', 'kind': 'folder', 'name': 'Leads'},
      {'id': 'customers', 'kind': 'table', 'name': 'Customers'},
    ],
    'leads': [
      {'id': 'lead-file', 'kind': 'file', 'name': 'lead-notes.md'},
    ],
  };

  Future<Map<String, Object?>> query({
    String? path,
    String? pathRegex,
    String? nameRegex,
  }) => readWorkspaceDirectory(
    path: path,
    pathRegex: pathRegex,
    nameRegex: nameRegex,
    listChildren: (parentId) async => tree[parentId] ?? const [],
  );

  test(
    'omitted path lists root and empty root stays an empty directory',
    () async {
      final result = await query();
      expect(result['path'], '/');
      expect(result['entries']! as List, hasLength(2));
      expect(
        await readWorkspaceDirectory(
          path: null,
          pathRegex: null,
          nameRegex: null,
          listChildren: (_) async => const [],
        ),
        {
          'kind': 'directory',
          'path': '/',
          'entries': <Object?>[],
          'truncated': false,
        },
      );
    },
  );

  test('directory tool accepts optional path and regex arguments', () {
    expect(workspaceReadToolSpecs().map((spec) => spec.name), [
      workspaceReadDirectoryToolName,
      workspaceReadItemToolName,
      workspaceReadTableToolName,
    ]);
    expect(
      workspaceToolArgumentsForExecution(workspaceReadDirectoryToolName, {
        'path': 'Sales',
        'nameRegex': r'^Leads$',
      }),
      {'action': 'readDirectory', 'path': 'Sales', 'nameRegex': r'^Leads$'},
    );
    expect(workspaceCommandNeedsApproval({'action': 'readDirectory'}), isFalse);
    final description = workspaceReadDirectoryToolSpec().description;
    expect(description, contains('ECMAScript regex'));
    expect(description, contains('prefix with (?i)'));
    expect(
      () => workspaceToolArgumentsForExecution(workspaceReadDirectoryToolName, {
        'path': '',
      }),
      throwsFormatException,
    );
  });

  test('exact folder path lists direct children with reusable paths', () async {
    final result = await query(path: 'Sales');
    expect(result['path'], 'Sales');
    expect((result['entries']! as List).map((item) => (item as Map)['path']), [
      'Sales/Leads',
      'Sales/Customers',
    ]);
  });

  test('regex search traverses nested files and folders', () async {
    final result = await query(
      path: 'Sales',
      pathRegex: '^Leads/.*',
      nameRegex: 'notes',
    );
    expect((result['entries']! as List).map((item) => (item as Map)['path']), [
      'Sales/Leads/lead-notes.md',
    ]);
  });

  test('case-insensitive regex accepts a leading inline flag', () async {
    final result = await query(
      pathRegex: '(?i)^sales/leads',
      nameRegex: '(?i)LEAD-NOTES',
    );

    expect((result['entries']! as List).map((item) => (item as Map)['path']), [
      'Sales/Leads/lead-notes.md',
    ]);
  });

  test('directory failures return a repair hint for invalid regex fields', () {
    expect(
      workspaceFailureContext(
        jsonEncode({'code': 'invalid', 'detail': 'Invalid pathRegex.'}),
      ),
      {
        'outcome': 'failed',
        'code': 'invalid_regex',
        'field': 'pathRegex',
        'error': 'pathRegex is invalid. Use ECMAScript regex syntax.',
        'nextAction':
            'Remove the regex or correct its syntax; use a leading '
            '(?i) for case-insensitive matching.',
      },
    );
    expect(
      workspaceFailureContext(
        jsonEncode({'code': 'invalid', 'detail': 'Invalid nameRegex.'}),
      )['field'],
      'nameRegex',
    );
  });

  test('rejects invalid, ambiguous, and escaping folder paths', () async {
    await expectLater(query(path: 'Missing'), throwsFormatException);
    await expectLater(query(path: '../Sales'), throwsFormatException);
    await expectLater(query(path: '  '), throwsFormatException);
    await expectLater(query(nameRegex: '['), throwsFormatException);
    await expectLater(query(nameRegex: r'(a|aa)+$'), throwsFormatException);
  });

  test('bounds directory search output and marks truncation', () async {
    final result = await readWorkspaceDirectory(
      path: null,
      pathRegex: null,
      nameRegex: '.*',
      listChildren: (_) async => [
        for (var index = 0; index < 101; index++)
          {'id': '$index', 'kind': 'file', 'name': 'file-$index'},
      ],
    );
    expect(result['entries'] as List?, hasLength(100));
    expect(result['truncated'], isTrue);
  });

  test('context projection keeps only bounded directory metadata', () {
    expect(
      workspaceDirectoryResultForContext({
        'kind': 'directory',
        'path': '/',
        'entries': [
          {
            'id': 'table',
            'kind': 'table',
            'name': 'Contacts',
            'path': 'Contacts',
            'revision': 2,
            'schema': {'secret': 'drop'},
          },
        ],
        'private': 'drop',
      }),
      {
        'kind': 'directory',
        'path': '/',
        'entries': [
          {
            'id': 'table',
            'kind': 'table',
            'name': 'Contacts',
            'path': 'Contacts',
            'revision': 2,
          },
        ],
        'truncated': false,
      },
    );
  });
}
