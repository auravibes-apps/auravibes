import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  group('serviceSkillDefinitions', () {
    test('cannot be mutated', () {
      expect(serviceSkillDefinitions.removeLast, throwsUnsupportedError);
    });

    test('uses unique service slugs', () {
      final slugs = serviceSkillDefinitions.map((skill) => skill.slug).toList();

      expect(slugs, hasLength(slugs.toSet().length));
      expect(slugs, containsAll(['openai', 'codex', 'brave', 'duckduckgo']));
      expect(slugs.where((slug) => slug.startsWith('search_')), isEmpty);
    });

    test('all service skills are declarative templates', () {
      final missingExecutors = <String>[];
      for (final skill in serviceSkillDefinitions) {
        if (skill.kind != AppSkillDefinitionKind.template) {
          missingExecutors.add('${skill.slug} is ${skill.kind}');
        }
        for (final tool in skill.tools) {
          if (tool.urlTemplate == null) {
            missingExecutors.add('${skill.slug}.${tool.slug}');
          }
        }
      }

      expect(missingExecutors, isEmpty);
    });

    test('all service tools have valid versioned manifests', () {
      for (final skill in serviceSkillDefinitions) {
        for (final tool in skill.tools) {
          final definition = tool.definition;
          expect(definition, isNotNull, reason: '${skill.slug}.${tool.slug}');
          try {
            validateSkillTemplateDefinition(definition!);
          } on Object catch (error) {
            fail('${skill.slug}.${tool.slug}: $error');
          }
        }
      }
    });

    test('resources are unique and complement a service tool', () {
      final invalid = <String>[];
      for (final skill in serviceSkillDefinitions) {
        final toolSlugs = skill.tools.map((tool) => tool.slug).toSet();
        final resourceSlugs = <String>{};
        for (final resource in skill.resources) {
          final path = '${skill.slug}.${resource.slug}';
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
            invalid.add('$path does not reference a service tool');
          }
        }
      }

      expect(invalid, isEmpty);
    });

    test('agent-facing text hides API internals', () {
      final leaks = <String>[];
      for (final skill in serviceSkillDefinitions) {
        _collectInternalLeaks(leaks, '${skill.slug}.title', skill.title);
        _collectInternalLeaks(
          leaks,
          '${skill.slug}.description',
          skill.description,
        );
        _collectInternalLeaks(leaks, '${skill.slug}.content', skill.content);
        for (final resource in skill.resources) {
          _collectInternalLeaks(
            leaks,
            '${skill.slug}.${resource.slug}.title',
            resource.title,
          );
          _collectInternalLeaks(
            leaks,
            '${skill.slug}.${resource.slug}.description',
            resource.description,
          );
          _collectInternalLeaks(
            leaks,
            '${skill.slug}.${resource.slug}.content',
            resource.content,
          );
        }
        for (final tool in skill.tools) {
          _collectInternalLeaks(
            leaks,
            '${skill.slug}.${tool.slug}.title',
            tool.title,
          );
          _collectInternalLeaks(
            leaks,
            '${skill.slug}.${tool.slug}.description',
            tool.description,
          );
        }
      }

      expect(leaks, isEmpty);
    });

    test('OpenAI skill does not claim Codex credential support', () {
      final openAi = serviceSkillDefinitions.singleWhere(
        (skill) => skill.slug == 'openai',
      );

      expect(openAi.title, 'OpenAI');
      expect(openAi.content.toLowerCase(), isNot(contains('codex')));
      expect(openAi.compatibleModelProviderIds, ['openai']);
      expect(
        openAi.compatibleModelProviderIds,
        isNot(contains('openai-codex')),
      );
    });

    test('Codex skill uses Codex model provider credentials', () {
      final codex = serviceSkillDefinitions.singleWhere(
        (skill) => skill.slug == 'codex',
      );

      expect(codex.title, 'OpenAI Codex');
      expect(codex.requiresCredential, isTrue);
      expect(codex.compatibleModelProviderIds, ['openai-codex']);
      expect(codex.tools.single.slug, 'web_search');
      expect(codex.tools.single.urlTemplate, isNotNull);
    });

    test('Gemini only reuses Google API-key credentials', () {
      final gemini = serviceSkillDefinitions.singleWhere(
        (skill) => skill.slug == 'gemini',
      );

      expect(gemini.compatibleModelProviderIds, ['google']);
      expect(
        gemini.compatibleModelProviderIds,
        isNot(contains('google-vertex')),
      );
    });

    test('DuckDuckGo uses raw HTML template instead of Instant Answer API', () {
      final duckDuckGo = serviceSkillDefinitions.singleWhere(
        (skill) => skill.slug == 'duckduckgo',
      );
      final tool = duckDuckGo.tools.single;

      expect(duckDuckGo.title, 'DuckDuckGo Search');
      expect(duckDuckGo.requiresCredential, isFalse);
      expect(tool.slug, 'search');
      expect(tool.urlTemplate, isNotNull);
    });

    test('SearXNG uses credential base URL instead of agent input', () {
      final searXng = serviceSkillDefinitions.singleWhere(
        (skill) => skill.slug == 'searxng',
      );
      final tool = searXng.tools.single;
      final properties = tool.inputJsonSchema['properties'] as Map;

      expect(searXng.requiresCredential, isTrue);
      expect(tool.requiresCredential, isTrue);
      expect(properties, contains('query'));
      expect(properties, isNot(contains('baseUrl')));
      expect(tool.urlTemplate?.credentialDefinitions, contains('baseUrl'));
    });

    test('provider tools expose expanded input schemas', () {
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

Map<String, Object?> _properties(String skillSlug, String toolSlug) {
  final skill = serviceSkillDefinitions.singleWhere(
    (skill) => skill.slug == skillSlug,
  );
  final tool = skill.tools.singleWhere((tool) => tool.slug == toolSlug);

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
