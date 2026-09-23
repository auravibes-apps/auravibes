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
        },
      ],
    });
    expect(tools.single.name, 'search');
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
}
