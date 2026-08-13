import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_executor.dart';
import 'package:auravibes_server/src/features/conversations/engine/server_tool_runtime.dart';
import 'package:test/test.dart';

void main() {
  const skills = [
    {
      'id': 'skill-1',
      'slug': 'research',
      'title': 'Research',
      'content': 'Use primary sources.',
      'isEnabled': true,
    },
  ];
  final descriptor = AgentResolvedToolName.skillTemplate(
    tableId: 'tool-1',
    skillSlug: 'research',
    toolIdentifier: 'search',
  );
  final tools = [
    ServerResolvedTool(
      descriptor: descriptor,
      spec: ToolSpec(
        name: descriptor.fullName,
        description: 'Search sources.',
        inputJsonSchema: const {
          'type': 'object',
          'properties': {
            'limit': {'type': 'integer'},
          },
          'required': ['limit'],
          'additionalProperties': false,
        },
      ),
    ),
  ];

  Future<SkillCommandTarget> command({
    String skill = 'research',
    String tool = 'search',
    Object? limit = 1,
    String? revision,
  }) async {
    final manifest = await buildCloudSkillManifest(
      slug: 'research',
      userSkills: skills,
      tools: tools,
    );
    return SkillCommandTarget.fromArguments({
      'skill': skill,
      'tool': tool,
      'args': {'limit': limit},
      'revision': revision ?? manifest!.revision,
    });
  }

  test('resolves current target and validates its schema', () async {
    expect(
      await resolveCloudSkillCommandTarget(
        command: await command(),
        userSkills: skills,
        tools: tools,
      ),
      same(tools.single),
    );
  });

  test('rejects unloaded target', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(),
        userSkills: skills,
        tools: const [],
      ),
      throwsStateError,
    );
  });

  test('rejects stale manifest revision', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(revision: 'stale'),
        userSkills: skills,
        tools: tools,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('list_skills to refresh'),
        ),
      ),
    );
  });

  test('rejects invalid target arguments', () async {
    await expectLater(
      resolveCloudSkillCommandTarget(
        command: await command(limit: 'wrong'),
        userSkills: skills,
        tools: tools,
      ),
      throwsFormatException,
    );
  });

  test('cloud skill control defaults allow list and confirm mutations', () {
    expect(
      defaultCloudToolPermission(
        AgentResolvedToolName.skillControl(toolIdentifier: listSkillsToolName),
      ),
      AgentToolPermissionResult.granted,
    );
    expect(
      defaultCloudToolPermission(
        AgentResolvedToolName.skillControl(toolIdentifier: loadSkillToolName),
      ),
      AgentToolPermissionResult.needsConfirmation,
    );
  });

  test('compiled DuckDuckGo callback uses injected HTTP client', () async {
    UrlRequest? captured;
    final result = await runCompiledServiceSkillTool(
      skillSlug: 'duckduckgo',
      toolSlug: 'search',
      input: const {'query': 'aura vibes'},
      httpClient: (request) {
        captured = request;
        return CancelableOperation.fromValue(
          UrlResponse(
            statusCode: HttpStatus.ok,
            body: '<html></html>',
            headers: const {},
            elapsed: Duration.zero,
          ),
        );
      },
    );

    expect(captured?.url, 'https://html.duckduckgo.com/html/');
    expect(captured?.method, UrlRequestMethod.post);
    expect(result, contains('"provider":"duckduckgo"'));
  });

  test('dynamic skill cannot supply a compiled callback', () async {
    expect(
      () => runCompiledServiceSkillTool(
        skillSlug: 'user-skill',
        toolSlug: 'search',
        input: const {},
        httpClient: (_) => throw StateError('must not run'),
      ),
      throwsA(isA<ServerToolNotConfiguredException>()),
    );
  });

  test(
    'server callback target rejects private, loopback, and HTTP credentials',
    () async {
      Future<List<InternetAddress>> privateLookup(String _) async => [
        InternetAddress('10.0.0.1'),
      ];
      Future<List<InternetAddress>> loopbackLookup(String _) async => [
        InternetAddress.loopbackIPv4,
      ];

      await expectLater(
        validateServerSkillRequestTarget(
          const UrlRequest(url: 'https://example.com'),
          requireHttps: false,
          lookup: privateLookup,
        ),
        throwsFormatException,
      );
      await expectLater(
        validateServerSkillRequestTarget(
          const UrlRequest(url: 'https://example.com'),
          requireHttps: false,
          lookup: loopbackLookup,
        ),
        throwsFormatException,
      );
      await expectLater(
        validateServerSkillRequestTarget(
          const UrlRequest(url: 'http://example.com'),
          requireHttps: true,
          lookup: (_) async => [InternetAddress('8.8.8.8')],
        ),
        throwsFormatException,
      );
    },
  );

  test('server callback target accepts resolved public address', () async {
    final target = await validateServerSkillRequestTarget(
      const UrlRequest(url: 'https://example.com/search'),
      requireHttps: true,
      lookup: (_) async => [InternetAddress('8.8.8.8')],
    );

    expect(target.uri.host, 'example.com');
    expect(target.addresses.single.address, '8.8.8.8');
  });

  test('server callback rejects redirects and oversized responses', () async {
    expect(
      () => rejectServerSkillRedirect(true),
      throwsA(isA<HttpException>()),
    );
    await expectLater(
      readBoundedServerSkillResponse(
        Stream.value([1, 2, 3]),
        maxBytes: 2,
      ),
      throwsFormatException,
    );
  });

  test('server callback cancellation closes request', () async {
    var closed = false;
    await closeOnServerSkillCancellation(
      isCancelled: () async => true,
      close: () => closed = true,
      done: Completer<void>().future,
      pollInterval: Duration.zero,
    );

    expect(closed, isTrue);
  });

  test('server callback timeout closes active request immediately', () async {
    var closed = false;
    final never = Completer<void>();

    await expectLater(
      runBoundedServerSkillRequest<void>(
        timeout: Duration.zero,
        run: () => never.future,
        close: () => closed = true,
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(closed, isTrue);
  });
}
