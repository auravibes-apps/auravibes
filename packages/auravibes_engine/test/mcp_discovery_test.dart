import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  List<McpDiscoveredTool> parse(Map<String, Object?> result) =>
      parseMcpToolsList(result, maxTools: 100, validateInputSchema: (_) {});

  test('validates tools/list payloads without transport concerns', () {
    final tools = parse({
      'tools': [
        {
          'name': 'search',
          'description': 'Search',
          'inputSchema': {'type': 'object'},
          'outputSchema': {
            'type': 'object',
            'required': ['answer'],
          },
        },
      ],
    });
    expect(tools.single.name, 'search');
    expect(tools.single.outputSchema, {
      'type': 'object',
      'required': ['answer'],
    });
    expect(
      () => parse({
        'tools': [
          {'name': 1},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => parse(<String, Object?>{
        'tools': <Object?>[
          <String, Object?>{
            'name': 'search',
            'inputSchema': <Object?, Object?>{1: 'invalid'},
          },
        ],
      }),
      throwsFormatException,
    );
  });

  test('validates tool count before materializing tools', () {
    var validatedSchemas = 0;

    expect(
      () => parseMcpToolsList(
        {
          'tools': [
            {'name': 'first'},
            {'name': 'second'},
          ],
        },
        maxTools: 1,
        validateInputSchema: (_) => validatedSchemas++,
      ),
      throwsFormatException,
    );
    expect(validatedSchemas, isZero);
  });

  test('validates schemas before recursively freezing them', () {
    Object? schema = 'value';
    for (var index = 0; index < 2000; index++) {
      schema = <Object?>[schema];
    }

    expect(
      () => parseMcpToolsList(
        {
          'tools': [
            {
              'name': 'deep',
              'inputSchema': {'schema': schema},
            },
          ],
        },
        maxTools: 1,
        validateInputSchema: (_) {
          throw const FormatException('Schema is too deep.');
        },
      ),
      throwsFormatException,
    );
  });

  test('enforces inclusive metadata and schema bounds', () {
    final schemaOverhead = utf8.encode(jsonEncode({'value': ''})).length;
    final schema = {
      'value': 'x' * (McpDiscoveryPolicy.maxSchemaBytes - schemaOverhead),
    };
    final tool = {
      'name': 'n' * McpDiscoveryPolicy.maxNameLength,
      'description': 'd' * McpDiscoveryPolicy.maxDescriptionLength,
      'inputSchema': schema,
    };
    expect(() => McpDiscoveryPolicy.validateTool(tool), returnsNormally);
    expect(
      () => McpDiscoveryPolicy.validateTool({
        ...tool,
        'name': 'n' * (McpDiscoveryPolicy.maxNameLength + 1),
      }),
      throwsFormatException,
    );
    expect(
      () => McpDiscoveryPolicy.validateTool({
        ...tool,
        'description': 'd' * (McpDiscoveryPolicy.maxDescriptionLength + 1),
      }),
      throwsFormatException,
    );
    expect(
      () => McpDiscoveryPolicy.boundedSchema({'value': '${schema['value']}x'}),
      throwsFormatException,
    );
  });

  test('rejects excessive depth, non-string keys, and non-JSON values', () {
    Object? nested = 'leaf';
    for (var index = 0; index < McpDiscoveryPolicy.maxSchemaDepth; index++) {
      nested = {'child': nested};
    }
    expect(() => McpDiscoveryPolicy.boundedSchema(nested), returnsNormally);
    expect(
      () => McpDiscoveryPolicy.boundedSchema({'child': nested}),
      throwsFormatException,
    );
    for (final schema in [
      <Object?, Object?>{1: 'value'},
      {'value': Object()},
      {'value': double.nan},
    ]) {
      expect(
        () => McpDiscoveryPolicy.boundedSchema(schema),
        throwsFormatException,
      );
    }
    expect(
      () => McpDiscoveryPolicy.validateTool({
        'name': 'tool',
        'outputSchema': <Object?, Object?>{1: 'value'},
      }),
      throwsFormatException,
    );
  });

  test('collects ordered pages including empty intermediate pages', () async {
    final cursors = <String?>[];
    final tools = await collectMcpToolsCatalog((cursor) async {
      cursors.add(cursor);
      return switch (cursor) {
        null => {
          'tools': [
            {'name': 'first'},
          ],
          'nextCursor': 'opaque-1',
        },
        'opaque-1' => {'tools': <Object?>[], 'nextCursor': 'opaque-2'},
        _ => {
          'tools': [
            {'name': 'last'},
          ],
        },
      };
    });
    expect(cursors, [null, 'opaque-1', 'opaque-2']);
    expect(tools.map((tool) => tool['name']), ['first', 'last']);
  });

  test('rejects repeated cursors and cumulative tool overflow', () async {
    await expectLater(
      collectMcpToolsCatalog(
        (_) async => {'tools': <Object?>[], 'nextCursor': 'same'},
      ),
      throwsFormatException,
    );
    await expectLater(
      collectMcpToolsCatalog(
        (_) async => {
          'tools': <Object?>[],
          'nextCursor': 'x' * (McpDiscoveryPolicy.maxCursorBytes + 1),
        },
      ),
      throwsFormatException,
    );
    await expectLater(
      collectMcpToolsCatalog(
        (cursor) async => {
          'tools': [
            for (var index = 0; index < (cursor == null ? 60 : 41); index++)
              {'name': '${cursor ?? 'first'}-$index'},
          ],
          if (cursor == null) 'nextCursor': 'second',
        },
      ),
      throwsFormatException,
    );
  });

  test('rejects catalog JSON that exceeds the aggregate byte limit', () async {
    await expectLater(
      collectMcpToolsCatalog(
        (_) async => {
          'tools': [
            for (var index = 0; index < 17; index++)
              {
                'name': 'tool-$index',
                'inputSchema': {'description': 'x' * 64000},
              },
          ],
        },
      ),
      throwsFormatException,
    );
  });

  test('stops at page limit and rejects a later-page failure', () async {
    var requests = 0;
    await expectLater(
      collectMcpToolsCatalog(
        (_) async => {'tools': <Object?>[], 'nextCursor': '${++requests}'},
      ),
      throwsFormatException,
    );
    expect(requests, McpDiscoveryPolicy.maxPages);
    await expectLater(
      collectMcpToolsCatalog((cursor) async {
        if (cursor != null) throw const FormatException('Later page failed.');
        return {
          'tools': [
            {'name': 'first'},
          ],
          'nextCursor': 'later',
        };
      }),
      throwsFormatException,
    );
  });
}
