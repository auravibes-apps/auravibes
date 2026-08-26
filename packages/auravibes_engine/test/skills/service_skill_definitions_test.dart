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

    test('all native tools have an executor', () {
      final missingExecutors = [
        for (final skill in serviceSkillDefinitions)
          for (final tool in skill.nativeTools)
            if (tool.urlTemplate == null && tool.callback == null)
              '${skill.slug}.${tool.slug}',
      ];

      expect(missingExecutors, isEmpty);
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
        for (final tool in skill.nativeTools) {
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
      expect(codex.nativeTools.single.slug, 'web_search');
      expect(codex.nativeTools.single.callback, isNotNull);
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

    test('DuckDuckGo uses callback scraper instead of Instant Answer API', () {
      final duckDuckGo = serviceSkillDefinitions.singleWhere(
        (skill) => skill.slug == 'duckduckgo',
      );
      final tool = duckDuckGo.nativeTools.single;

      expect(duckDuckGo.title, 'DuckDuckGo Search');
      expect(duckDuckGo.requiresCredential, isFalse);
      expect(tool.slug, 'search');
      expect(tool.callback, isNotNull);
      expect(tool.urlTemplate, isNull);
    });

    test('SearXNG uses credential base URL instead of agent input', () {
      final searXng = serviceSkillDefinitions.singleWhere(
        (skill) => skill.slug == 'searxng',
      );
      final tool = searXng.nativeTools.single;
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
  final tool = skill.nativeTools.singleWhere((tool) => tool.slug == toolSlug);

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
