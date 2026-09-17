import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

class _FakeMcpConnectionNotifier extends McpConnectionNotifier {
  @override
  Future<McpConnectionVerification> prepareMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
  }) async => (
    id: 'verification-id',
    toolCount: 2,
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  @override
  Future<void> commitPreparedMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
    required String verificationId,
  }) => Future<void>.value();
}

class _FailingMcpConnectionNotifier extends McpConnectionNotifier {
  @override
  Future<McpConnectionVerification> prepareMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
  }) async => (
    id: 'verification-id',
    toolCount: 1,
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  @override
  Future<void> commitPreparedMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
    required String verificationId,
  }) async {
    throw Exception('connect failed');
  }
}

class _TestFailingMcpConnectionNotifier extends McpConnectionNotifier {
  @override
  Future<McpConnectionVerification> prepareMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
  }) async {
    throw Exception(
      'Authorization: Bearer secret-token api_key=secret-api-key',
    );
  }

  @override
  Future<void> commitPreparedMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
    required String verificationId,
  }) => Future<void>.value();
}

class _ExpiredMcpConnectionNotifier extends McpConnectionNotifier {
  @override
  Future<McpConnectionVerification> prepareMcpConnection(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
  }) async => (
    id: 'expired-verification-id',
    toolCount: 1,
    expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
  );
}

void main() {
  group('McpFormState', () {
    test('defaults are correct', () {
      const state = McpFormState();
      expect(state.name, '');
      expect(state.description, '');
      expect(state.url, '');
      expect(state.transport, McpTransportTypeOptions.streamableHttp);
      expect(state.authenticationType, McpAuthenticationTypeOptions.none);
      expect(state.bearerToken, '');
      expect(state.useHttp2, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.isTestingConnection, isFalse);
      expect(state.isConnectionVerified, isFalse);
      expect(state.verifiedToolCount, 0);
      expect(state.errorMessage, isNull);
    });

    group('availableAuthTypes', () {
      test('streamableHttp returns none and oauth', () {
        const state = McpFormState();
        expect(state.availableAuthTypes, [
          McpAuthenticationTypeOptions.none,
          McpAuthenticationTypeOptions.oauth,
        ]);
      });

      test('sse returns all auth types', () {
        const state = McpFormState(transport: .sse);
        expect(state.availableAuthTypes, McpAuthenticationTypeOptions.values);
      });
    });

    group('showOAuthFields', () {
      test('returns true when oauth selected', () {
        const state = McpFormState(authenticationType: .oauth);
        expect(state.showOAuthFields, isTrue);
      });

      test('returns false when none selected', () {
        const state = McpFormState();
        expect(state.showOAuthFields, isFalse);
      });
    });

    group('showBearerTokenField', () {
      test('returns true when bearerToken selected', () {
        const state = McpFormState(authenticationType: .bearerToken);
        expect(state.showBearerTokenField, isTrue);
      });

      test('returns false when none selected', () {
        const state = McpFormState();
        expect(state.showBearerTokenField, isFalse);
      });
    });

    group('toCreateEntity', () {
      test('converts to entity correctly', () {
        const state = McpFormState(
          name: '  My Server  ',
          description: '  A test server  ',
          url: '  https://example.com  ',
          transport: .sse,
        );
        final entity = state.toCreateEntity();
        expect(entity.name, 'My Server');
        expect(entity.description, 'A test server');
        expect(entity.url, 'https://example.com');
        expect(entity.transport, isA<McpTransportTypeSSE>());
      });

      test('preserves HTTP/2 in streamable HTTP transport', () {
        const state = McpFormState(
          name: 'Test',
          url: 'https://example.com',
          useHttp2: true,
        );

        final transport = state.toCreateEntity().transport;
        expect(transport, isA<McpTransportTypeStreamableHttp>());
        expect((transport as McpTransportTypeStreamableHttp).useHttp2, isTrue);
      });

      test('nulls empty description', () {
        const state = McpFormState(
          name: 'Test',
          description: '   ',
          url: 'https://example.com',
        );
        final entity = state.toCreateEntity();
        expect(entity.description, isNull);
      });
    });

    group('isValid', () {
      test('returns false when name is empty', () {
        const state = McpFormState(url: 'https://example.com');
        expect(state.isValid, isFalse);
      });

      test('returns false when url is empty', () {
        const state = McpFormState(name: 'Test');
        expect(state.isValid, isFalse);
      });

      test('returns true for valid none auth', () {
        const state = McpFormState(name: 'Test', url: 'https://example.com');
        expect(state.isValid, isTrue);
      });

      test('returns false when bearerToken auth but no token', () {
        const state = McpFormState(
          name: 'Test',
          url: 'https://example.com',
          authenticationType: .bearerToken,
        );
        expect(state.isValid, isFalse);
      });

      test('returns true when bearerToken auth with token', () {
        const state = McpFormState(
          name: 'Test',
          url: 'https://example.com',
          authenticationType: .bearerToken,
          bearerToken: 'my-token',
        );
        expect(state.isValid, isTrue);
      });
    });

    group('validationErrors', () {
      test('returns name error when empty', () {
        const state = McpFormState(url: 'https://example.com');
        expect(state.validationErrors, contains('Name is required.'));
      });

      test('returns url error when empty', () {
        const state = McpFormState(name: 'Test');
        expect(state.validationErrors, contains('URL is required.'));
      });
    });
  });

  group('McpFormNotifier', () {
    ProviderContainer? container;
    McpFormNotifier? notifier;
    ProviderContainer readContainer() =>
        container ?? fail('ProviderContainer not initialized');
    McpFormNotifier readNotifier() =>
        notifier ?? fail('McpFormNotifier not initialized');

    setUp(() async {
      final testContainer = ProviderContainer(
        overrides: [
          workspaceSessionProvider(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
          ).overrideWithValue(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
          ),
          workspaceSessionForRouteProvider.overrideWith(
            (_, _) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'ws1'),
            ),
          ),
          mcpConnectionProvider.overrideWith(_FakeMcpConnectionNotifier.new),
        ],
      );
      final workspaceSession = await testContainer.read(
        workspaceSessionForRouteProvider('ws1').future,
      );
      expect(workspaceSession, isA<WorkspaceSession>());
      container = testContainer;
      notifier = testContainer.read(mcpFormProvider('ws1').notifier);
    });

    tearDown(() => container?.dispose());

    test('build returns default state', () {
      expect(readContainer().read(mcpFormProvider('ws1')).name, '');
    });

    test('name field updates name', () {
      readNotifier().setName('New Name');
      expect(readContainer().read(mcpFormProvider('ws1')).name, 'New Name');
    });

    test('description field updates description', () {
      readNotifier().setDescription('Desc');
      expect(readContainer().read(mcpFormProvider('ws1')).description, 'Desc');
    });

    test('url field updates url', () {
      readNotifier().setUrl('https://example.com');
      expect(
        readContainer().read(mcpFormProvider('ws1')).url,
        'https://example.com',
      );
    });

    test('setTransport resets http2 when switching to sse', () {
      readNotifier().setUseHttp2(value: true);
      expect(readContainer().read(mcpFormProvider('ws1')).useHttp2, isTrue);

      readNotifier().setTransport(.sse);
      expect(readContainer().read(mcpFormProvider('ws1')).useHttp2, isFalse);
    });

    test('setTransport resets auth when switching to streamableHttp', () {
      readNotifier()
        ..setTransport(.sse)
        ..setAuthenticationType(.bearerToken);

      expect(
        readContainer().read(mcpFormProvider('ws1')).authenticationType,
        McpAuthenticationTypeOptions.bearerToken,
      );

      readNotifier().setTransport(.streamableHttp);
      expect(
        readContainer().read(mcpFormProvider('ws1')).authenticationType,
        McpAuthenticationTypeOptions.none,
      );
    });

    test('setTransport does nothing when value is null', () {
      final original = readContainer().read(mcpFormProvider('ws1'));
      readNotifier().setTransport(null);
      expect(
        readContainer().read(mcpFormProvider('ws1')).transport,
        original.transport,
      );
    });

    test('setAuthenticationType updates auth type', () {
      readNotifier().setAuthenticationType(.bearerToken);
      expect(
        readContainer().read(mcpFormProvider('ws1')).authenticationType,
        McpAuthenticationTypeOptions.bearerToken,
      );
    });

    test('bearer token field updates token', () {
      readNotifier().setBearerToken('my-token');
      expect(
        readContainer().read(mcpFormProvider('ws1')).bearerToken,
        'my-token',
      );
    });

    test('HTTP/2 field updates flag', () {
      readNotifier().setUseHttp2(value: true);
      expect(readContainer().read(mcpFormProvider('ws1')).useHttp2, isTrue);
    });

    test('submit returns false when invalid', () async {
      final result = await readNotifier().submit();
      expect(result, isFalse);
      expect(
        readContainer().read(mcpFormProvider('ws1')).errorMessage,
        isNotNull,
      );
    });

    test('submit logs validation errors', () async {
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      final previousLevel = Logger.root.level;
      Logger.root.level = .ALL;
      addTearDown(() {
        Logger.root.level = previousLevel;
      });

      final result = await readNotifier().submit();

      expect(result, isFalse);
      expect(
        records,
        contains(
          isA<LogRecord>()
              .having((record) => record.loggerName, 'loggerName', 'mcp_form')
              .having((record) => record.level, 'level', Level.WARNING)
              .having(
                (record) => record.message,
                'message',
                contains('MCP form error workspace=ws1'),
              ),
        ),
      );
    });

    test('submit returns true after verification', () async {
      readNotifier()
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(.none);

      expect(await readNotifier().testConnection(), isTrue);
      final result = await readNotifier().submit();
      expect(result, isTrue);
      expect(
        readContainer().read(mcpFormProvider('ws1')).isSubmitting,
        isFalse,
      );
    });

    test('submit requires verification', () async {
      readNotifier()
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(.none);

      expect(await readNotifier().submit(), isFalse);
      expect(
        readContainer().read(mcpFormProvider('ws1')).errorMessage,
        LocaleKeys.mcp_modal_verification_required,
      );
    });

    test('testConnection returns true when valid', () async {
      readNotifier()
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(.none);

      final result = await readNotifier().testConnection();

      expect(result, isTrue);
      expect(
        readContainer().read(mcpFormProvider('ws1')).isTestingConnection,
        isFalse,
      );
      expect(readContainer().read(mcpFormProvider('ws1')).errorMessage, isNull);
      expect(
        readContainer().read(mcpFormProvider('ws1')).isConnectionVerified,
        isTrue,
      );
    });

    test('name and description edits keep verification valid', () async {
      readNotifier()
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(.none);

      expect(await readNotifier().testConnection(), isTrue);
      readNotifier()
        ..setName('Renamed')
        ..setDescription('Updated description');

      expect(await readNotifier().submit(), isTrue);
    });

    test('URL edits invalidate verification', () async {
      readNotifier()
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(.none);

      expect(await readNotifier().testConnection(), isTrue);
      readNotifier().setUrl('https://changed.example.com');

      expect(await readNotifier().submit(), isFalse);
      expect(
        readContainer().read(mcpFormProvider('ws1')).isConnectionVerified,
        isFalse,
      );
    });

    test('expired verification blocks saving', () async {
      readContainer().dispose();
      final expiredContainer = ProviderContainer(
        overrides: [
          workspaceSessionProvider(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
          ).overrideWithValue(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
          ),
          workspaceSessionForRouteProvider.overrideWith(
            (_, _) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'ws1'),
            ),
          ),
          mcpConnectionProvider.overrideWith(_ExpiredMcpConnectionNotifier.new),
        ],
      );
      final workspaceSession = await expiredContainer.read(
        workspaceSessionForRouteProvider('ws1').future,
      );
      expect(workspaceSession, isA<WorkspaceSession>());
      container = expiredContainer;
      notifier = expiredContainer.read(mcpFormProvider('ws1').notifier);
      readNotifier()
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(.none);

      expect(await readNotifier().testConnection(), isFalse);
      expect(
        readContainer().read(mcpFormProvider('ws1')).isConnectionVerified,
        isFalse,
      );
      expect(await readNotifier().submit(), isFalse);
    });

    test('testConnection redacts failures and blocks saving', () async {
      readContainer().dispose();
      final failingContainer = ProviderContainer(
        overrides: [
          workspaceSessionProvider(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
          ).overrideWithValue(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
          ),
          workspaceSessionForRouteProvider.overrideWith(
            (_, _) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'ws1'),
            ),
          ),
          mcpConnectionProvider.overrideWith(
            _TestFailingMcpConnectionNotifier.new,
          ),
        ],
      );
      final workspaceSession = await failingContainer.read(
        workspaceSessionForRouteProvider('ws1').future,
      );
      expect(workspaceSession, isA<WorkspaceSession>());
      container = failingContainer;
      notifier = failingContainer.read(mcpFormProvider('ws1').notifier);

      readNotifier()
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(.none);

      final testResult = await readNotifier().testConnection();
      final stateAfterTest = readContainer().read(mcpFormProvider('ws1'));

      expect(testResult, isFalse);
      expect(stateAfterTest.errorMessage, contains('Bearer [REDACTED]'));
      expect(stateAfterTest.errorMessage, contains('api_key=[REDACTED]'));
      expect(stateAfterTest.errorMessage, isNot(contains('secret-token')));
      expect(stateAfterTest.errorMessage, isNot(contains('secret-api-key')));
      expect(stateAfterTest.isTestingConnection, isFalse);

      expect(await readNotifier().submit(), isFalse);
      expect(
        readContainer().read(mcpFormProvider('ws1')).isConnectionVerified,
        isFalse,
      );
    });

    test('submit logs connection exception with stack trace', () async {
      readContainer().dispose();
      final failingContainer = ProviderContainer(
        overrides: [
          workspaceSessionProvider(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
          ).overrideWithValue(
            const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws1')),
          ),
          workspaceSessionForRouteProvider.overrideWith(
            (_, _) async => const WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: 'ws1'),
            ),
          ),
          mcpConnectionProvider.overrideWith(_FailingMcpConnectionNotifier.new),
        ],
      );
      final workspaceSession = await failingContainer.read(
        workspaceSessionForRouteProvider('ws1').future,
      );
      expect(workspaceSession, isA<WorkspaceSession>());
      container = failingContainer;
      notifier = failingContainer.read(mcpFormProvider('ws1').notifier);

      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      final previousLevel = Logger.root.level;
      Logger.root.level = .ALL;
      addTearDown(() {
        Logger.root.level = previousLevel;
      });

      readNotifier()
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(.none);

      expect(await readNotifier().testConnection(), isTrue);
      final result = await readNotifier().submit();

      expect(result, isFalse);
      final record = records.firstWhere(
        (record) =>
            record.loggerName == 'mcp_form' &&
            record.level == Level.SEVERE &&
            record.message.contains('MCP form submit failed workspace=ws1'),
      );
      expect(record.error.toString(), contains('connect failed'));
      expect(record.stackTrace, isNotNull);
      expect(
        readContainer().read(mcpFormProvider('ws1')).isConnectionVerified,
        isTrue,
      );
    });
  });
}
