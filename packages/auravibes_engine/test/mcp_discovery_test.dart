import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('validates tools/list payloads without transport concerns', () {
    final tools = parseMcpToolsList({
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
      () => parseMcpToolsList({
        'tools': [
          {'name': 1},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => parseMcpToolsList(<String, Object?>{
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
}
