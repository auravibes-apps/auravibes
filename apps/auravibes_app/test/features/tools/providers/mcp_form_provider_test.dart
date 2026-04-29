import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/features/tools/providers/mcp_form_provider.dart';
import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeMcpConnectionNotifier extends McpConnectionNotifier {
  McpServerFormToCreate? lastCreated;

  @override
  Future<void> addMcpServer(
    McpServerFormToCreate serverToCreate, {
    required String workspaceId,
  }) async {
    lastCreated = serverToCreate;
  }
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
        const state = McpFormState(
          transport: McpTransportTypeOptions.sse,
        );
        expect(
          state.availableAuthTypes,
          McpAuthenticationTypeOptions.values,
        );
      });
    });

    group('showOAuthFields', () {
      test('returns true when oauth selected', () {
        const state = McpFormState(
          authenticationType: McpAuthenticationTypeOptions.oauth,
        );
        expect(state.showOAuthFields, isTrue);
      });

      test('returns false when none selected', () {
        const state = McpFormState();
        expect(state.showOAuthFields, isFalse);
      });
    });

    group('showBearerTokenField', () {
      test('returns true when bearerToken selected', () {
        const state = McpFormState(
          authenticationType: McpAuthenticationTypeOptions.bearerToken,
        );
        expect(state.showBearerTokenField, isTrue);
      });

      test('returns false when none selected', () {
        const state = McpFormState();
        expect(state.showBearerTokenField, isFalse);
      });
    });

    group('showHttp2Toggle', () {
      test('returns true for streamableHttp', () {
        const state = McpFormState();
        expect(state.showHttp2Toggle, isTrue);
      });

      test('returns false for sse', () {
        const state = McpFormState(
          transport: McpTransportTypeOptions.sse,
        );
        expect(state.showHttp2Toggle, isFalse);
      });
    });

    group('toCreateEntity', () {
      test('converts to entity correctly', () {
        const state = McpFormState(
          name: '  My Server  ',
          description: '  A test server  ',
          url: '  https://example.com  ',
          transport: McpTransportTypeOptions.sse,
        );
        final entity = state.toCreateEntity();
        expect(entity.name, 'My Server');
        expect(entity.description, 'A test server');
        expect(entity.url, 'https://example.com');
        expect(entity.transport, isA<McpTransportTypeSSE>());
      });

      test('nulls empty description', () {
        const state = McpFormState(
          name: 'Test',
          url: 'https://example.com',
          description: '   ',
        );
        final entity = state.toCreateEntity();
        expect(entity.description, isNull);
      });
    });

    group('isValid', () {
      test('returns false when name is empty', () {
        const state = McpFormState(
          url: 'https://example.com',
        );
        expect(state.isValid, isFalse);
      });

      test('returns false when url is empty', () {
        const state = McpFormState(
          name: 'Test',
        );
        expect(state.isValid, isFalse);
      });

      test('returns true for valid none auth', () {
        const state = McpFormState(
          name: 'Test',
          url: 'https://example.com',
        );
        expect(state.isValid, isTrue);
      });

      test('returns false when bearerToken auth but no token', () {
        const state = McpFormState(
          name: 'Test',
          url: 'https://example.com',
          authenticationType: McpAuthenticationTypeOptions.bearerToken,
        );
        expect(state.isValid, isFalse);
      });

      test('returns true when bearerToken auth with token', () {
        const state = McpFormState(
          name: 'Test',
          url: 'https://example.com',
          authenticationType: McpAuthenticationTypeOptions.bearerToken,
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
    late ProviderContainer container;
    late McpFormNotifier notifier;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          mcpConnectionProvider.overrideWith(_FakeMcpConnectionNotifier.new),
        ],
      );
      notifier = container.read(mcpFormProvider('ws1').notifier);
    });

    tearDown(() => container.dispose());

    test('build returns default state', () {
      expect(container.read(mcpFormProvider('ws1')).name, '');
    });

    test('setName updates name', () {
      notifier.setName('New Name');
      expect(container.read(mcpFormProvider('ws1')).name, 'New Name');
    });

    test('setDescription updates description', () {
      notifier.setDescription('Desc');
      expect(
        container.read(mcpFormProvider('ws1')).description,
        'Desc',
      );
    });

    test('setUrl updates url', () {
      notifier.setUrl('https://example.com');
      expect(
        container.read(mcpFormProvider('ws1')).url,
        'https://example.com',
      );
    });

    test('setTransport resets http2 when switching to sse', () {
      notifier.setUseHttp2(true);
      expect(container.read(mcpFormProvider('ws1')).useHttp2, isTrue);

      notifier.setTransport(McpTransportTypeOptions.sse);
      expect(
        container.read(mcpFormProvider('ws1')).useHttp2,
        isFalse,
      );
    });

    test('setTransport resets auth when switching to streamableHttp', () {
      notifier
        ..setTransport(McpTransportTypeOptions.sse)
        ..setAuthenticationType(McpAuthenticationTypeOptions.bearerToken);

      expect(
        container.read(mcpFormProvider('ws1')).authenticationType,
        McpAuthenticationTypeOptions.bearerToken,
      );

      notifier.setTransport(McpTransportTypeOptions.streamableHttp);
      expect(
        container.read(mcpFormProvider('ws1')).authenticationType,
        McpAuthenticationTypeOptions.none,
      );
    });

    test('setTransport does nothing when value is null', () {
      final original = container.read(mcpFormProvider('ws1'));
      notifier.setTransport(null);
      expect(
        container.read(mcpFormProvider('ws1')).transport,
        original.transport,
      );
    });

    test('setAuthenticationType updates auth type', () {
      notifier.setAuthenticationType(McpAuthenticationTypeOptions.bearerToken);
      expect(
        container.read(mcpFormProvider('ws1')).authenticationType,
        McpAuthenticationTypeOptions.bearerToken,
      );
    });

    test('setBearerToken updates token', () {
      notifier.setBearerToken('my-token');
      expect(
        container.read(mcpFormProvider('ws1')).bearerToken,
        'my-token',
      );
    });

    test('setUseHttp2 updates flag', () {
      notifier.setUseHttp2(true);
      expect(container.read(mcpFormProvider('ws1')).useHttp2, isTrue);
    });

    test('setSubmitting updates flag', () {
      notifier.setSubmitting(value: true);
      expect(
        container.read(mcpFormProvider('ws1')).isSubmitting,
        isTrue,
      );
    });

    test('setError sets error message', () {
      notifier.setError('Something went wrong');
      expect(
        container.read(mcpFormProvider('ws1')).errorMessage,
        'Something went wrong',
      );
    });

    test('clearError clears error message', () {
      notifier
        ..setError('Error')
        ..clearError();
      expect(
        container.read(mcpFormProvider('ws1')).errorMessage,
        isNull,
      );
    });

    test('submit returns false when invalid', () async {
      final result = await notifier.submit();
      expect(result, isFalse);
      expect(
        container.read(mcpFormProvider('ws1')).errorMessage,
        isNotNull,
      );
    });

    test('submit returns true when valid', () async {
      notifier
        ..setName('Test')
        ..setUrl('https://example.com')
        ..setAuthenticationType(McpAuthenticationTypeOptions.none);

      final result = await notifier.submit();
      expect(result, isTrue);
      expect(
        container.read(mcpFormProvider('ws1')).isSubmitting,
        isFalse,
      );
    });
  });
}
