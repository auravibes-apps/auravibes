import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  group('AppSkillExecutor', () {
    test('runs URL template tools through injected HTTP client', () async {
      late UrlRequest capturedRequest;
      final executor = _executor((request) {
        capturedRequest = request;

        return const UrlResponse(
          statusCode: 200,
          body: 'template body',
          headers: {},
          elapsed: .zero,
        );
      });

      final result = await executor
          .run(
            skill: _templateSkill,
            toolSlug: 'search',
            input: {'query': 'flutter'},
            credentials: const {'apiKey': 'secret'},
          )
          .value;

      expect(result, 'template body');
      expect(capturedRequest.url, 'https://example.com/search?q=flutter');
      expect(capturedRequest.headers, {'authorization': 'Bearer secret'});
    });

    test('returns only URL template response body', () async {
      final executor = _executor((request) {
        return const UrlResponse(
          statusCode: 418,
          body: 'safe body',
          headers: {
            'set-cookie': ['secret=value'],
          },
          elapsed: .new(seconds: 1),
        );
      });

      final result = await executor
          .run(
            skill: _templateSkill,
            toolSlug: 'search',
            input: {'query': 'flutter'},
            credentials: const {'apiKey': 'secret'},
          )
          .value;

      expect(result, 'safe body');
    });

    test('merges external credential definitions into a manifest', () async {
      late UrlRequest capturedRequest;
      final executor = SkillTemplateExecutor(const ResolveSkillUrlTemplate(), (
        request,
      ) {
        capturedRequest = request;
        return CancelableOperation.fromFuture(
          Future.value(
            const UrlResponse(
              statusCode: 200,
              body: 'ok',
              headers: {},
              elapsed: .zero,
            ),
          ),
        );
      });

      await executor
          .call(
            definition: const SkillTemplateDefinition(
              request: SkillUrlTemplate(
                url: 'https://example.com',
                headers: {'authorization': 'Bearer {{ credential.apiKey }}'},
              ),
              inputs: {},
            ),
            inputs: const {},
            credentials: const {'apiKey': 'secret'},
            credentialDefinitions: const {
              'apiKey': SkillCredentialAttributeDefinition(
                description: 'API key',
              ),
            },
          )
          .value;

      expect(capturedRequest.headers['authorization'], 'Bearer secret');
    });

    test('returns DuckDuckGo raw HTML response', () async {
      late UrlRequest capturedRequest;
      final executor = _executor((request) {
        capturedRequest = request;

        return const UrlResponse(
          statusCode: 200,
          body: _duckDuckGoHtml,
          headers: {},
          elapsed: .zero,
        );
      });

      final result = await executor
          .run(
            skill: serviceSkillDefinitions.singleWhere(
              (skill) => skill.slug == 'duckduckgo',
            ),
            toolSlug: 'search',
            input: {'query': 'flutter jobs', 'maxResults': 1},
          )
          .value;

      expect(capturedRequest.url, 'https://html.duckduckgo.com/html/');
      expect(capturedRequest.method, UrlRequestMethod.post);
      expect(capturedRequest.body, contains('q=flutter+jobs'));
      expect(capturedRequest.body, contains('kl=us-en'));
      expect(capturedRequest.body, contains('b='));
      expect(
        capturedRequest.headers['content-type'],
        'application/x-www-form-urlencoded',
      );
      expect(capturedRequest.headers['user-agent'], contains('Mozilla/5.0'));
      expect(result, _duckDuckGoHtml);
    });

    test(
      'returns provider challenge responses without normalization',
      () async {
        final executor = _executor((request) {
          return const UrlResponse(
            statusCode: 202,
            body: '<html><div class="anomaly-modal"></div></html>',
            headers: {},
            elapsed: .zero,
          );
        });

        final result = await executor
            .run(
              skill: serviceSkillDefinitions.singleWhere(
                (skill) => skill.slug == 'duckduckgo',
              ),
              toolSlug: 'search',
              input: {'query': 'flutter jobs'},
            )
            .value;

        expect(result, '<html><div class="anomaly-modal"></div></html>');
      },
    );

    test('maps OpenAI model and web filters into request body', () async {
      late UrlRequest capturedRequest;
      final executor = _executor((request) {
        capturedRequest = request;

        return const UrlResponse(
          statusCode: 200,
          body: '{}',
          headers: {},
          elapsed: .zero,
        );
      });

      await executor
          .run(
            skill: _skill('openai'),
            toolSlug: 'web_search',
            input: {
              'question': 'latest Flutter',
              'model': 'gpt-test',
              'searchContextSize': 'low',
              'allowedDomains': ['flutter.dev'],
              'includeImages': true,
              'maxOutputTokens': 256,
            },
            credentials: const {'apiKey': 'secret'},
          )
          .value;

      final body = jsonDecode(capturedRequest.body!) as Map;
      final tool = (body['tools'] as List).single as Map;

      expect(capturedRequest.url, 'https://api.openai.com/v1/responses');
      expect(body['model'], 'gpt-test');
      expect(body['max_output_tokens'], 256);
      expect(tool['search_context_size'], 'low');
      expect(tool['filters'], {
        'allowed_domains': ['flutter.dev'],
      });
      expect(body['search_content_types'], ['text', 'image']);
    });

    test('maps Gemini model into request URL', () async {
      late UrlRequest capturedRequest;
      final executor = _executor((request) {
        capturedRequest = request;

        return const UrlResponse(
          statusCode: 200,
          body: '{}',
          headers: {},
          elapsed: .zero,
        );
      });

      await executor
          .run(
            skill: _skill('gemini'),
            toolSlug: 'google_search_grounded_answer',
            input: {'question': 'Dart', 'model': 'gemini test/model'},
            credentials: const {'apiKey': 'gemini-key'},
          )
          .value;

      expect(
        capturedRequest.url,
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini%20test%2Fmodel:generateContent',
      );
      expect(capturedRequest.headers['x-goog-api-key'], 'gemini-key');
    });

    test('requires credentials before creating provider requests', () {
      final executor = _executor((request) {
        fail('HTTP client should not run without credentials.');
      });

      expect(
        () => executor.run(
          skill: _skill('gemini'),
          toolSlug: 'google_search_grounded_answer',
          input: {'question': 'Dart'},
        ),
        throwsFormatException,
      );
    });

    test('requires Kagi summarize url or text', () {
      final executor = _executor((request) {
        fail('HTTP client should not run without summarize content.');
      });

      expect(
        () => executor.run(
          skill: _skill('kagi'),
          toolSlug: 'summarize',
          input: const {},
          credentials: const {'apiKey': 'kagi-key'},
        ),
        throwsFormatException,
      );
    });

    test('does not execute tools without a URL template', () {
      expect(
        () =>
            _executor(
              (request) => const UrlResponse(
                statusCode: 200,
                body: '',
                headers: {},
                elapsed: .zero,
              ),
            ).run(
              skill: const AppSkillDefinition(
                identifier: 'native',
                slug: 'native',
                title: 'Native',
                description: 'Native',
                content: 'Native',
                tools: [
                  AppSkillToolDefinition(
                    slug: 'native',
                    title: 'Native',
                    description: 'Native',
                  ),
                ],
              ),
              toolSlug: 'native',
              input: const {},
            ),
        throwsUnsupportedError,
      );
    });

    test('maps Parallel extract URLs into request body', () async {
      late UrlRequest capturedRequest;
      final executor = _executor((request) {
        capturedRequest = request;

        return const UrlResponse(
          statusCode: 200,
          body: '{}',
          headers: {},
          elapsed: .zero,
        );
      });

      await executor
          .run(
            skill: _skill('parallel'),
            toolSlug: 'extract',
            input: {
              'urls': ['https://example.com'],
              'maxChars': 1200,
              'maxCharsTotal': 2400,
              'timeoutSeconds': 30,
            },
            credentials: const {'apiKey': 'parallel-key'},
          )
          .value;

      expect(capturedRequest.url, 'https://api.parallel.ai/v1/extract');
      expect(capturedRequest.headers['x-api-key'], 'parallel-key');
      expect(jsonDecode(capturedRequest.body!), {
        'urls': ['https://example.com'],
        'max_chars': 1200,
        'max_chars_total': 2400,
        'timeout_seconds': 30,
      });
    });

    test('maps Parallel search options into request body', () async {
      late UrlRequest capturedRequest;
      final executor = _executor((request) {
        capturedRequest = request;

        return const UrlResponse(
          statusCode: 200,
          body: '{}',
          headers: {},
          elapsed: .zero,
        );
      });

      await executor
          .run(
            skill: _skill('parallel'),
            toolSlug: 'search',
            input: {
              'query': 'fallback',
              'searchQueries': ['flutter', 'dart'],
              'mode': 'web',
              'sessionId': 'session-1',
              'clientModel': 'model-1',
              'includeDomains': ['dart.dev'],
              'excludeDomains': ['example.com'],
              'afterDate': '2026-01-01',
              'maxAgeSeconds': 86400,
              'timeoutSeconds': 20,
              'disableCacheFallback': true,
              'maxCharsPerResult': 500,
              'location': 'US',
              'maxResults': 4,
              'maxCharsTotal': 2000,
              'objective': 'current docs',
            },
            credentials: const {'apiKey': 'parallel-key'},
          )
          .value;

      expect(capturedRequest.url, 'https://api.parallel.ai/v1/search');
      expect(capturedRequest.headers['x-api-key'], 'parallel-key');
      expect(jsonDecode(capturedRequest.body!), {
        'search_queries': ['flutter', 'dart'],
        'max_chars_total': 2000,
        'mode': 'web',
        'session_id': 'session-1',
        'client_model': 'model-1',
        'include_domains': ['dart.dev'],
        'exclude_domains': ['example.com'],
        'after_date': '2026-01-01',
        'max_age_seconds': 86400,
        'timeout_seconds': 20,
        'disable_cache_fallback': true,
        'max_chars_per_result': 500,
        'location': 'US',
        'max_results': 4,
        'objective': 'current docs',
      });
    });

    test('throws for unknown tool', () {
      final executor = _executor((request) {
        return const UrlResponse(
          statusCode: 200,
          body: '',
          headers: {},
          elapsed: .zero,
        );
      });

      expect(
        () => executor.run(
          skill: _templateSkill,
          toolSlug: 'missing',
          input: const {},
        ),
        throwsUnsupportedError,
      );
    });
  });
}

AppSkillDefinition _skill(String slug) {
  return serviceSkillDefinitions.singleWhere((skill) => skill.slug == slug);
}

AppSkillExecutor _executor(UrlResponse Function(UrlRequest) run) {
  final httpClient = _FakeSkillHttpClient(run);

  return AppSkillExecutor(
    .new(const ResolveSkillUrlTemplate(), httpClient.execute),
  );
}

const _templateSkill = AppSkillDefinition(
  identifier: 'example',
  slug: 'example',
  title: 'Example',
  description: 'Example',
  content: 'Example',
  tools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search.',
      urlTemplate: .new(
        template: SkillUrlTemplate(
          url: 'https://example.com/search',
          headers: {'authorization': 'Bearer {{ credential.apiKey }}'},
          query: {'q': '{{ input.query }}'},
        ),
        inputs: {'query': SkillTemplateInputDefinition(description: 'Query')},
        credentialDefinitions: {
          'apiKey': SkillCredentialAttributeDefinition(description: 'API key'),
        },
      ),
    ),
  ],
);

class const _FakeSkillHttpClient(
  final UrlResponse Function(UrlRequest request) run,
) {
  CancelableOperation<UrlResponse> execute(UrlRequest request) {
    return CancelableOperation.fromFuture(.value(run(request)));
  }
}

const _duckDuckGoHtml = '''
<div class="result results_links">
  <a class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2Fjobs&amp;rut=abc">Flutter <b>Jobs</b></a>
  <div class="result__snippet">Remote &amp; mobile roles</div>
</div>
<div class="result results_links">
  <a class="result__a" href="https://example.com/second">Second result</a>
  <span class="result__snippet">Another result</span>
</div>
''';
