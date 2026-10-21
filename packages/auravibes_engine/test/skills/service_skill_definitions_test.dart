import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Connector service presets', () {
    test('catalogs are immutable and have unique identifiers', () {
      expect(serviceSkillPresets.removeLast, throwsUnsupportedError);
      expect(connectorDefinitions.removeLast, throwsUnsupportedError);
      expect(serviceSkillDefinitions.removeLast, throwsUnsupportedError);

      final connectorIds = connectorDefinitions
          .map((connector) => connector.identifier)
          .toList();
      final skillSlugs = serviceSkillDefinitions
          .map((skill) => skill.slug)
          .toList();

      expect(connectorIds, hasLength(connectorIds.toSet().length));
      expect(skillSlugs, hasLength(skillSlugs.toSet().length));
      expect(
        connectorIds,
        containsAll(['openai', 'codex', 'brave', 'duckduckgo']),
      );
      expect(
        skillSlugs,
        containsAll(['openai', 'codex', 'brave', 'duckduckgo']),
      );
    });

    test('Skills reference Connector IDs without owning Connector tools', () {
      for (final preset in serviceSkillPresets) {
        expect(preset.skill.tools, isEmpty, reason: preset.slug);
        expect(preset.skill.connectorToolIds, [
          for (final tool in preset.tools)
            'connector/${preset.identifier}/${tool.slug}',
        ], reason: preset.slug);
      }
    });

    test('Connector tools have valid request definitions', () {
      for (final connector in connectorDefinitions) {
        for (final tool in connector.tools) {
          final definition = tool.definition;
          expect(
            definition,
            isNotNull,
            reason: '${connector.identifier}.${tool.slug}',
          );
          try {
            validateConnectorToolRequestDefinition(definition!);
          } on Object catch (error) {
            fail('${connector.identifier}.${tool.slug}: $error');
          }
        }
      }
    });

    test('resources are unique and describe a Connector tool', () {
      final invalid = <String>[];
      for (final preset in serviceSkillPresets) {
        final toolSlugs = preset.tools.map((tool) => tool.slug).toSet();
        final resourceSlugs = <String>{};
        for (final resource in preset.resources) {
          final path = '${preset.slug}.${resource.slug}';
          if (resource.slug.isEmpty || !resourceSlugs.add(resource.slug)) {
            invalid.add('$path has a duplicate or empty slug');
          }
          if (resource.title.isEmpty || resource.description.isEmpty) {
            invalid.add('$path has incomplete summary metadata');
          }
          if (!toolSlugs.any(
            (toolSlug) =>
                resource.description.contains(toolSlug) ||
                resource.content.contains(toolSlug),
          )) {
            invalid.add('$path does not reference a Connector tool');
          }
        }
      }

      expect(invalid, isEmpty);
    });

    test('agent-facing guidance hides API internals', () {
      final leaks = <String>[];
      for (final preset in serviceSkillPresets) {
        _collectInternalLeaks(leaks, '${preset.slug}.title', preset.title);
        _collectInternalLeaks(
          leaks,
          '${preset.slug}.description',
          preset.description,
        );
        _collectInternalLeaks(leaks, '${preset.slug}.content', preset.content);
        for (final resource in preset.resources) {
          _collectInternalLeaks(
            leaks,
            '${preset.slug}.${resource.slug}.title',
            resource.title,
          );
          _collectInternalLeaks(
            leaks,
            '${preset.slug}.${resource.slug}.description',
            resource.description,
          );
          _collectInternalLeaks(
            leaks,
            '${preset.slug}.${resource.slug}.content',
            resource.content,
          );
        }
        for (final tool in preset.tools) {
          _collectInternalLeaks(
            leaks,
            '${preset.slug}.${tool.slug}.title',
            tool.title,
          );
          _collectInternalLeaks(
            leaks,
            '${preset.slug}.${tool.slug}.description',
            tool.description,
          );
        }
      }

      expect(leaks, isEmpty);
    });

    test('OpenAI Connector offers tools and model access', () {
      final openAi = _connector('openai');

      expect(openAi.title, 'OpenAI');
      expect(openAi.compatibleModelProviderIds, contains('openai'));
      expect(openAi.tools.map((tool) => tool.slug), contains('web_search'));
      expect(_connector('codex').compatibleModelProviderIds, ['openai-codex']);
    });

    test('Gemini Connector targets Google API-key models only', () {
      final gemini = _connector('gemini');

      expect(gemini.compatibleModelProviderIds, ['google']);
      expect(
        gemini.compatibleModelProviderIds,
        isNot(contains('google-vertex')),
      );
    });

    test('DuckDuckGo tool has no credential dependency', () {
      final connector = _connector('duckduckgo');
      final tool = connector.tools.single;

      expect(connector.title, 'DuckDuckGo Search');
      expect(tool.slug, 'search');
      expect(tool.requiresConnection, isFalse);
      expect(tool.urlTemplate, isNotNull);
    });

    test('SearXNG base URL belongs to Connector credentials', () {
      final connector = _connector('searxng');
      final tool = connector.tools.single;
      final properties = tool.inputJsonSchema['properties'] as Map;

      expect(tool.requiresConnection, isTrue);
      expect(properties, contains('query'));
      expect(properties, isNot(contains('baseUrl')));
      expect(tool.definition!.credentialDefinitions, contains('baseUrl'));
    });

    test('provider Connector tools expose their expanded input schemas', () {
      expect(_properties('openai', 'web_search'), contains('model'));
      expect(_properties('codex', 'web_search'), contains('blockedDomains'));
      expect(
        _properties('gemini', 'google_search_grounded_answer'),
        contains('model'),
      );
      expect(_properties('brave', 'web_search'), contains('country'));
      expect(_properties('duckduckgo', 'search'), contains('region'));
      expect(_properties('exa', 'search'), contains('includeDomains'));
      expect(_properties('perplexity', 'search'), contains('language'));
      expect(_properties('tinyfish', 'fetch'), contains('urls'));
      expect(_properties('jina', 'rerank'), contains('topN'));
      expect(_properties('kagi', 'summarize'), contains('summaryType'));
      expect(_properties('tavily', 'map'), contains('maxDepth'));
      expect(_properties('firecrawl', 'scrape'), contains('formats'));
      expect(_properties('parallel', 'search'), contains('searchQueries'));
      expect(_properties('parallel', 'search'), contains('sessionId'));
      expect(_properties('parallel', 'search'), contains('clientModel'));
      expect(_properties('parallel', 'search'), contains('includeDomains'));
      expect(_properties('parallel', 'search'), contains('timeoutSeconds'));
      expect(_properties('parallel', 'search'), contains('maxCharsPerResult'));
      expect(_properties('parallel', 'extract'), contains('urls'));
      expect(_properties('parallel', 'extract'), contains('maxCharsTotal'));
      expect(_properties('parallel', 'extract'), contains('timeoutSeconds'));
    });
  });
}

ConnectorDefinition _connector(String identifier) => connectorDefinitions
    .singleWhere((connector) => connector.identifier == identifier);

Map<String, Object?> _properties(String connectorId, String toolSlug) {
  final tool = _connector(connectorId).tools
      .singleWhere((tool) => tool.slug == toolSlug);

  return Map<String, Object?>.from(tool.inputJsonSchema['properties']! as Map);
}

void _collectInternalLeaks(List<String> leaks, String path, String text) {
  const forbidden = [
    'https://',
    'http://',
    'POST',
    'GET',
    'Bearer',
    'X-Subscription-Token',
    'Main API',
  ];
  for (final term in forbidden) {
    if (text.contains(term)) leaks.add('$path contains $term');
  }
}
