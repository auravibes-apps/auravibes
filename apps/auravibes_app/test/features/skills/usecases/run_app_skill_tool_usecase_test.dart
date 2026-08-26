import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';
import 'package:auravibes_app/features/skills/usecases/app_skill_http_client_adapter.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_app_skill_tool_usecase.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const UrlRequest(url: 'https://example.com'));
  });

  group('RunAppSkillToolUsecase', () {
    test('all service native tools have an executor', () {
      final missingExecutors = [
        for (final skill in serviceSkillDefinitions)
          for (final tool in skill.nativeTools)
            if (tool.urlTemplate == null && tool.callback == null)
              '${skill.slug}.${tool.slug}',
      ];

      expect(missingExecutors, isEmpty);
    });

    test('executes DuckDuckGo callback scraper without credentials', () async {
      var capturedRequest = const UrlRequest(url: '');
      final usecase = _usecase(
        executeUrl: (request) async {
          capturedRequest = request;

          return _response(
            _duckDuckGoHtml,
            statusCode: 418,
            headers: const {
              'set-cookie': ['secret=value'],
            },
          );
        },
      );

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        skillSlug: 'duckduckgo',
        toolSlug: 'search',
        arguments: {'query': 'flutter jobs', 'maxResults': 1},
      );

      expect(
        result,
        '{"provider":"duckduckgo","query":"flutter jobs","sources":[{"title":"Flutter Jobs","url":"https://example.com/jobs","snippet":"Remote & mobile roles"}]}',
      );
      expect(capturedRequest.method, UrlRequestMethod.post);
      expect(capturedRequest.url, 'https://html.duckduckgo.com/html/');
      expect(capturedRequest.body, contains('q=flutter+jobs'));
      expect(
        capturedRequest.headers['content-type'],
        'application/x-www-form-urlencoded',
      );
    });

    test('rejects unsafe app skill URLs before execution', () async {
      final urlService = _MockUrlService();
      final adapter = AppSkillHttpClientAdapter(urlService);

      await expectLater(
        adapter.execute(const UrlRequest(url: 'http://localhost/search')).value,
        throwsA(isA<FormatException>()),
      );
      final _ = verifyNever(() => urlService.execute(any()));
    });

    test('executes SearXNG URL template with base URL credential', () async {
      final serviceConnections = _MockServiceConnectionRepository();
      var capturedRequest = const UrlRequest(url: '');
      when(
        () => serviceConnections.getById('connection-1'),
      ).thenAnswer((_) async => _serviceConnection());
      when(() => serviceConnections.readSecret('connection-1')).thenAnswer(
        (_) async => const ServiceConnectionSecretApiKey(
          apiKey: 'https://search.example.com',
        ),
      );
      final usecase = _usecase(
        serviceConnections: serviceConnections,
        candidatesBySlug: {
          'searxng': [_candidate('searxng')],
        },
        executeUrl: (request) async {
          capturedRequest = request;

          return _response('{"results":[]}');
        },
      );

      final _ = await usecase.call(
        workspaceId: 'workspace-1',
        skillSlug: 'searxng',
        toolSlug: 'search',
        arguments: {'query': 'dart'},
      );

      expect(
        capturedRequest.url,
        'https://search.example.com/search?q=dart&format=json',
      );
    });

    test(
      'rejects unsafe SearXNG credential base URL before execution',
      () async {
        final serviceConnections = _MockServiceConnectionRepository();
        final urlService = _MockUrlService();
        when(
          () => serviceConnections.getById('connection-1'),
        ).thenAnswer((_) async => _serviceConnection());
        when(() => serviceConnections.readSecret('connection-1')).thenAnswer(
          (_) async => const ServiceConnectionSecretApiKey(
            apiKey: 'http://localhost:8080',
          ),
        );
        final usecase = _usecase(
          serviceConnections: serviceConnections,
          candidatesBySlug: {
            'searxng': [_candidate('searxng')],
          },
          urlService: urlService,
          requirePublicUri: PublicUrlGuard.requireHttpsUri,
        );

        await expectLater(
          usecase.call(
            workspaceId: 'workspace-1',
            skillSlug: 'searxng',
            toolSlug: 'search',
            arguments: {'query': 'dart'},
          ),
          throwsA(isA<FormatException>()),
        );
        final _ = verifyNever(() => urlService.execute(any()));
      },
    );

    test(
      'executes Brave URL template with service credential header',
      () async {
        final serviceConnections = _MockServiceConnectionRepository();
        var capturedRequest = const UrlRequest(url: '');
        when(
          () => serviceConnections.getById('connection-1'),
        ).thenAnswer((_) async => _serviceConnection());
        when(() => serviceConnections.readSecret('connection-1')).thenAnswer(
          (_) async => const ServiceConnectionSecretApiKey(apiKey: 'brave-key'),
        );
        final usecase = _usecase(
          serviceConnections: serviceConnections,
          candidatesBySlug: {
            'brave': [_candidate('brave')],
          },
          executeUrl: (request) async {
            capturedRequest = request;

            return _response('{"web":{"results":[]}}');
          },
        );

        final _ = await usecase.call(
          workspaceId: 'workspace-1',
          skillSlug: 'brave',
          toolSlug: 'web_search',
          arguments: {
            'query': 'flutter',
            'maxResults': 3,
            'credentialId': 'service:connection-1',
          },
        );

        expect(
          capturedRequest.url,
          'https://api.search.brave.com/res/v1/web/search?q=flutter&count=3',
        );
        expect(capturedRequest.headers, {'X-Subscription-Token': 'brave-key'});
      },
    );

    test('executes POST URL template body', () async {
      final serviceConnections = _MockServiceConnectionRepository();
      var capturedRequest = const UrlRequest(url: '');
      when(
        () => serviceConnections.getById('connection-1'),
      ).thenAnswer((_) async => _serviceConnection());
      when(() => serviceConnections.readSecret('connection-1')).thenAnswer(
        (_) async => const ServiceConnectionSecretApiKey(apiKey: 'synthetic'),
      );
      final usecase = _usecase(
        serviceConnections: serviceConnections,
        candidatesBySlug: {
          'synthetic': [_candidate('synthetic')],
        },
        executeUrl: (request) async {
          capturedRequest = request;

          return _response('{"results":[]}');
        },
      );

      final _ = await usecase.call(
        workspaceId: 'workspace-1',
        skillSlug: 'synthetic',
        toolSlug: 'search',
        arguments: {'query': 'flutter', 'credentialId': 'service:connection-1'},
      );

      expect(capturedRequest.method, UrlRequestMethod.post);
      expect(capturedRequest.url, 'https://api.synthetic.new/v2/search');
      expect(capturedRequest.body, '{"query":"flutter"}');
      expect(capturedRequest.headers['authorization'], 'Bearer synthetic');
    });

    test('executes pending Exa contents URL template', () async {
      final serviceConnections = _MockServiceConnectionRepository();
      var capturedRequest = const UrlRequest(url: '');
      when(
        () => serviceConnections.getById('connection-1'),
      ).thenAnswer((_) async => _serviceConnection());
      when(() => serviceConnections.readSecret('connection-1')).thenAnswer(
        (_) async => const ServiceConnectionSecretApiKey(apiKey: 'exa-key'),
      );
      final usecase = _usecase(
        serviceConnections: serviceConnections,
        candidatesBySlug: {
          'exa': [_candidate('exa')],
        },
        executeUrl: (request) async {
          capturedRequest = request;

          return _response('{"results":[]}');
        },
      );

      final _ = await usecase.call(
        workspaceId: 'workspace-1',
        skillSlug: 'exa',
        toolSlug: 'contents',
        arguments: {
          'urls': ['https://example.com/post'],
          'credentialId': 'service:connection-1',
        },
      );

      expect(capturedRequest.method, UrlRequestMethod.post);
      expect(capturedRequest.url, 'https://api.exa.ai/contents');
      expect(capturedRequest.body, '{"urls":["https://example.com/post"]}');
      expect(capturedRequest.headers['x-api-key'], 'exa-key');
    });

    test('executes pending OpenAI callback request', () async {
      final serviceConnections = _MockServiceConnectionRepository();
      var capturedRequest = const UrlRequest(url: '');
      when(
        () => serviceConnections.getById('connection-1'),
      ).thenAnswer((_) async => _serviceConnection());
      when(() => serviceConnections.readSecret('connection-1')).thenAnswer(
        (_) async => const ServiceConnectionSecretApiKey(apiKey: 'openai-key'),
      );
      final usecase = _usecase(
        serviceConnections: serviceConnections,
        candidatesBySlug: {
          'openai': [_candidate('openai')],
        },
        executeUrl: (request) async {
          capturedRequest = request;

          return _response('{"output":[]}');
        },
      );

      final _ = await usecase.call(
        workspaceId: 'workspace-1',
        skillSlug: 'openai',
        toolSlug: 'web_search',
        arguments: {'question': 'latest Flutter news'},
      );

      expect(capturedRequest.method, UrlRequestMethod.post);
      expect(capturedRequest.url, 'https://api.openai.com/v1/responses');
      expect(capturedRequest.headers['authorization'], 'Bearer openai-key');
      expect(capturedRequest.body, contains('web_search'));
      expect(capturedRequest.body, contains('latest Flutter news'));
    });

    test('requires credentialId when multiple credentials exist', () async {
      final usecase = _usecase(
        candidatesBySlug: {
          'openai': [
            _candidate('openai'),
            _candidate('openai', id: 'service:connection-2'),
          ],
        },
      );

      await expectLater(
        usecase.call(
          workspaceId: 'workspace-1',
          skillSlug: 'openai',
          toolSlug: 'web_search',
          arguments: {'question': 'latest Flutter news'},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('executes Codex callback with refreshed OAuth credential', () async {
      final serviceConnections = _MockServiceConnectionRepository();
      final oauthCredentials = _MockOAuthCredentialService();
      var capturedRequest = const UrlRequest(url: '');
      when(() => serviceConnections.getById('codex-connection')).thenAnswer(
        (_) async => _serviceConnection(
          authenticationType: ServiceConnectionAuthenticationType.oauth2,
          metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
            const ServiceConnectionMetadata(
              accountId: 'account-1',
              provider: 'openai-codex',
            ),
          ),
        ),
      );
      when(() => serviceConnections.readSecret('codex-connection')).thenAnswer(
        (_) async => const ServiceConnectionSecretOAuth2(
          accessToken: 'stale-token',
          refreshToken: 'refresh-token',
        ),
      );
      when(
        () => oauthCredentials.getValidAccessToken('codex-connection'),
      ).thenAnswer((_) async => 'fresh-token');
      final usecase = _usecase(
        serviceConnections: serviceConnections,
        oauthCredentials: oauthCredentials,
        candidatesBySlug: {
          'codex': [_candidate('codex', id: 'model:codex-connection')],
        },
        executeUrl: (request) async {
          capturedRequest = request;

          return _response(
            '{"output_text":"Answer with source","output":[{"type":"message","content":[{"type":"output_text","text":"Answer with source","annotations":[{"type":"url_citation","url":"https://example.com","title":"Example"}]}]}]}',
          );
        },
      );

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        skillSlug: 'codex',
        toolSlug: 'web_search',
        arguments: {
          'question': 'latest Flutter news',
          'credentialId': 'model:codex-connection',
          'searchContextSize': 'medium',
          'webSearchMode': 'indexed',
          'allowedDomains': ['example.com'],
          'country': 'US',
          'region': 'CA',
          'city': 'San Francisco',
          'timezone': 'America/Los_Angeles',
          'includeImages': true,
          'maxOutputTokens': 512,
        },
      );

      expect(capturedRequest.method, UrlRequestMethod.post);
      expect(
        capturedRequest.url,
        'https://chatgpt.com/backend-api/codex/responses',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer fresh-token');
      expect(capturedRequest.headers['ChatGPT-Account-Id'], 'account-1');
      expect(capturedRequest.headers['OpenAI-Beta'], 'responses=experimental');
      expect(capturedRequest.headers['accept'], 'text/event-stream');
      expect(capturedRequest.body, contains('stream":true'));
      expect(capturedRequest.body, contains('web_search'));
      expect(capturedRequest.body, contains('search_context_size":"medium'));
      expect(capturedRequest.body, contains('index_gated_web_access":true'));
      expect(
        capturedRequest.body,
        contains('allowed_domains":["example.com"]'),
      );
      expect(capturedRequest.body, contains('"country":"US"'));
      expect(capturedRequest.body, contains('"city":"San Francisco"'));
      expect(
        capturedRequest.body,
        contains('search_content_types":["text","image"]'),
      );
      expect(capturedRequest.body, contains('max_output_tokens":512'));
      expect(capturedRequest.body, contains('latest Flutter news'));
      expect(result, contains('Answer with source'));
      expect(result, contains('https://example.com'));
    });

    test('aggregates Codex annotation events into final sources', () async {
      final serviceConnections = _MockServiceConnectionRepository();
      final oauthCredentials = _MockOAuthCredentialService();
      when(
        () => serviceConnections.getById('codex-annotation-connection'),
      ).thenAnswer(
        (_) async => _serviceConnection(
          authenticationType: ServiceConnectionAuthenticationType.oauth2,
          metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
            const ServiceConnectionMetadata(provider: 'openai-codex'),
          ),
        ),
      );
      when(
        () => serviceConnections.readSecret('codex-annotation-connection'),
      ).thenAnswer(
        (_) async => const ServiceConnectionSecretOAuth2(
          accessToken: 'stale-token',
          refreshToken: 'refresh-token',
        ),
      );
      when(
        () =>
            oauthCredentials.getValidAccessToken('codex-annotation-connection'),
      ).thenAnswer((_) async => 'fresh-token');
      final usecase = _usecase(
        serviceConnections: serviceConnections,
        oauthCredentials: oauthCredentials,
        candidatesBySlug: {
          'codex': [
            _candidate('codex', id: 'model:codex-annotation-connection'),
          ],
        },
        executeUrl: (_) async => _response('''
data: {"type":"response.output_text.delta","delta":"Final answer with citation"}
data: {"type":"response.output_text.annotation.added","annotation":{"type":"url_citation","title":"Pokemon.com","url":"https://www.pokemon.com/news"}}
data: [DONE]
'''),
      );

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        skillSlug: 'codex',
        toolSlug: 'web_search',
        arguments: {
          'question': 'latest Pokemon news',
          'credentialId': 'model:codex-annotation-connection',
        },
      );
      final resultText = (result ?? fail('Expected Codex result')) as String;
      final decoded = jsonDecode(resultText) as Map<String, dynamic>;

      expect(decoded['answer'], 'Final answer with citation');
      expect(decoded['sources'], [
        {'url': 'https://www.pokemon.com/news', 'title': 'Pokemon.com'},
      ]);
    });

    test('keeps SSE parsing as Codex fallback', () async {
      final serviceConnections = _MockServiceConnectionRepository();
      final oauthCredentials = _MockOAuthCredentialService();
      when(() => serviceConnections.getById('codex-sse-connection')).thenAnswer(
        (_) async => _serviceConnection(
          authenticationType: ServiceConnectionAuthenticationType.oauth2,
          metadataJson: ServiceConnectionAuthCodec.encodeMetadata(
            const ServiceConnectionMetadata(provider: 'openai-codex'),
          ),
        ),
      );
      when(
        () => serviceConnections.readSecret('codex-sse-connection'),
      ).thenAnswer(
        (_) async => const ServiceConnectionSecretOAuth2(
          accessToken: 'stale-token',
          refreshToken: 'refresh-token',
        ),
      );
      when(
        () => oauthCredentials.getValidAccessToken('codex-sse-connection'),
      ).thenAnswer((_) async => 'fresh-token');
      final usecase = _usecase(
        serviceConnections: serviceConnections,
        oauthCredentials: oauthCredentials,
        candidatesBySlug: {
          'codex': [_candidate('codex', id: 'model:codex-sse-connection')],
        },
        executeUrl: (_) async => _response('''
data: {"type":"response.output_text.delta","delta":"Streamed answer"}
data: {"type":"response.output_text.annotation.added","annotation":{"type":"url_citation","title":"Example","url":"https://example.com"}}
data: [DONE]
'''),
      );

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        skillSlug: 'codex',
        toolSlug: 'web_search',
        arguments: {
          'question': 'latest news',
          'credentialId': 'model:codex-sse-connection',
        },
      );
      final resultText = (result ?? fail('Expected Codex result')) as String;
      final decoded = jsonDecode(resultText) as Map<String, dynamic>;

      expect(decoded['answer'], 'Streamed answer');
      expect(decoded['sources'], [
        {'url': 'https://example.com', 'title': 'Example'},
      ]);
    });

    test('requires credential for Brave', () async {
      final usecase = _usecase();

      await expectLater(
        usecase.call(
          workspaceId: 'workspace-1',
          skillSlug: 'brave',
          toolSlug: 'web_search',
          arguments: {'query': 'flutter'},
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

RunAppSkillToolUsecase _usecase({
  ServiceConnectionRepository? serviceConnections,
  OAuthCredentialService? oauthCredentials,
  Map<String, List<AppSkillCredentialCandidate>> candidatesBySlug = const {},
  AppSearchUrlExecutor? executeUrl,
  UrlService? urlService,
  AppSkillUrlGuard? requirePublicUri,
}) {
  final effectiveUrlService = urlService ?? _MockUrlService();
  if (urlService == null) {
    when(() => effectiveUrlService.execute(any())).thenAnswer(
      (invocation) => CancelableOperation.fromFuture(
        (executeUrl ?? (_) async => _response(''))(
          invocation.positionalArguments.single as UrlRequest,
        ),
      ),
    );
  }

  Future<Uri> trustTestUrl(String url) => Future.value(Uri.parse(url));
  final httpClient = AppSkillHttpClientAdapter(
    effectiveUrlService,
    requirePublicUri: requirePublicUri ?? trustTestUrl,
  );

  return RunAppSkillToolUsecase(
    const AppSkillRegistry(),
    serviceConnections ?? _MockServiceConnectionRepository(),
    _MockSkillCredentialsRepository(),
    _FakeAppSkillCandidates(candidatesBySlug),
    AppSkillExecutor(
      RunSkillUrlTemplate(const ResolveSkillUrlTemplate(), httpClient.execute),
      httpClient.execute,
    ),
    oauthCredentials,
  );
}

class _FakeAppSkillCandidates
    implements ListAppSkillCredentialCandidatesUsecase {
  const _FakeAppSkillCandidates(this.candidatesBySlug);

  final Map<String, List<AppSkillCredentialCandidate>> candidatesBySlug;

  @override
  Future<List<AppSkillCredentialCandidate>> call({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    return candidatesBySlug[skill.slug] ?? const [];
  }

  @override
  bool isCredentialRequired(AppSkillDefinition skill) {
    return skill.requiresCredential ||
        skill.nativeTools.any((tool) => tool.requiresCredential);
  }

  @override
  Future<bool> hasUsableNativeTool({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    if (skill.nativeTools.any((tool) => !tool.requiresCredential)) {
      return true;
    }

    return (candidatesBySlug[skill.slug] ?? const []).isNotEmpty;
  }
}

AppSkillCredentialCandidate _candidate(
  String skillSlug, {
  String id = 'service:connection-1',
}) {
  return AppSkillCredentialCandidate(id: id, name: '$skillSlug credential');
}

UrlResponse _response(
  String body, {
  int statusCode = 200,
  Map<String, List<String>> headers = const {},
}) {
  return UrlResponse(
    statusCode: statusCode,
    body: body,
    headers: headers,
    elapsed: Duration.zero,
  );
}

ServiceConnectionEntity _serviceConnection({
  ServiceConnectionAuthenticationType authenticationType =
      ServiceConnectionAuthenticationType.apiKey,
  String? metadataJson,
}) {
  return ServiceConnectionEntity(
    id: 'connection-1',
    workspaceId: 'workspace-1',
    authenticationType: authenticationType,
    isEnabled: true,
    metadataJson: metadataJson,
    expiresAt: null,
    lastRefreshedAt: null,
    updatedAt: DateTime(2026),
    authStatus: ServiceConnectionAuthStatus.connected,
    lastAuthError: null,
  );
}

class _MockServiceConnectionRepository extends Mock
    implements ServiceConnectionRepository {}

class _MockSkillCredentialsRepository extends Mock
    implements SkillCredentialsRepository {}

class _MockUrlService extends Mock implements UrlService {}

class _MockOAuthCredentialService extends Mock
    implements OAuthCredentialService {}

typedef AppSearchUrlExecutor = Future<UrlResponse> Function(UrlRequest request);

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
