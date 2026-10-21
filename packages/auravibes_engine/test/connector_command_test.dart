import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  const connector = AppSkillDefinition(
    identifier: 'notion',
    slug: 'notion',
    title: 'Notion',
    description: '',
    content: '',
    compatibleModelProviderIds: ['openai', 'anthropic'],
  );
  const tool = AppSkillToolDefinition(
    slug: 'search',
    title: 'Search',
    description: 'Find pages.',
    inputJsonSchema: {
      'type': 'object',
      'properties': {
        'query': {'type': 'string'},
      },
      'required': ['query'],
      'additionalProperties': false,
    },
    requiresCredential: true,
  );

  test('Connector tool ID and revision stay stable across runtimes', () {
    expect(connectorToolId(connector, tool), 'connector/notion/search');
    expect(
      connectorToolRevision(connector, tool),
      '6879b1fd801597df89e76273b039b099c632dbb237609d9e95505490a2c9da5c',
    );
  });
}
