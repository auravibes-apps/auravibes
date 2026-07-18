import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/services/codex_oauth_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _ThrowingCodexOAuthService extends CodexOAuthService {
  @override
  Future<OAuthTokenEntity> authenticateWithBrowser() =>
      throw StateError('local OAuth touched');

  @override
  Future<OAuthTokenEntity> authenticateWithDeviceCode({
    void Function(CodexDeviceCode deviceCode)? onDeviceCode,
    bool Function()? isCancelled,
  }) => throw StateError('local OAuth touched');
}

void main() {
  const workspace = CloudWorkspaceRef(
    localWorkspaceId: 'local',
    serverUrl: 'https://example.com',
    accountId: 'account',
    cloudWorkspaceId: 7,
  );

  test('cloud device OAuth fails before local OAuth and persistence', () async {
    final gateway = CloudWorkspaceStateGateway.forTesting(
      workspace: workspace,
      readState: (_) => throw StateError('unused'),
      subscribe: (_) => const Stream.empty(),
    );
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider.overrideWithValue(
          const WorkspaceSession(workspace),
        ),
        workspaceSessionForRouteProvider.overrideWith(
          (_, _) async => const WorkspaceSession(workspace),
        ),
        cloudWorkspaceStateGatewayProvider.overrideWith(
          (_, _) async => gateway,
        ),
        cloudWorkspaceStateGatewayForWorkspaceProvider.overrideWith(
          (_, _) async => gateway,
        ),
        modelConnectionStoreProvider.overrideWith(
          (_, _) async => throw StateError('persistence touched'),
        ),
        apiModelProvidersProvider(workspaceId: 'local').overrideWith(
          (_) async => const [
            ApiModelProviderEntity(
              id: openAICodexProviderId,
              name: openAICodexDisplayName,
              type: ModelProvidersType.openai,
            ),
          ],
        ),
        codexOAuthServiceProvider.overrideWithValue(
          _ThrowingCodexOAuthService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(
      addModelProviderStateProvider('local').notifier,
    );
    final _ = await container.read(
      apiModelProvidersProvider(workspaceId: 'local').future,
    );
    notifier.setModel(openAICodexProviderId);

    await expectLater(
      notifier.addModelProvider(codexOAuthMethod: CodexOAuthMethod.deviceCode),
      throwsA(isA<UnsupportedWorkspaceCapabilityException>()),
    );
  });
}
