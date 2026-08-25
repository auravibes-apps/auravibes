import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  const local = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: 'local'),
  );
  const cloud = WorkspaceSession(
    CloudWorkspaceRef(
      localWorkspaceId: 'mirror',
      serverUrl: 'https://server.example',
      accountId: 'account',
      cloudWorkspaceId: 1,
    ),
  );

  test('local and cloud capability matrix is explicit', () {
    expect(local.capabilities.nativeTools, isTrue);
    expect(local.capabilities.modelDeviceOAuth, isTrue);
    expect(local.capabilities.mcpTransports, WorkspaceMcpTransport.values);
    expect(
      local.capabilities.mcpAuthentication,
      WorkspaceMcpAuthentication.values,
    );
    expect(local.capabilities.conversationToolOverrides, isTrue);
    expect(local.capabilities.offline, isTrue);

    expect(cloud.capabilities.modelProviderIds, {
      'openai',
      'openai-codex',
      'openrouter',
      'anthropic',
    });
    expect(cloud.capabilities.modelBrowserOAuth, isTrue);
    expect(cloud.capabilities.modelDeviceOAuth, isFalse);
    expect(cloud.capabilities.mcpTransports, {
      WorkspaceMcpTransport.streamableHttp,
    });
    expect(cloud.capabilities.mcpAuthentication, {
      WorkspaceMcpAuthentication.none,
      WorkspaceMcpAuthentication.bearerToken,
    });
    expect(cloud.capabilities.nativeTools, isFalse);
    expect(cloud.capabilities.skills, isTrue);
    expect(cloud.capabilities.attachments, isTrue);
    expect(cloud.capabilities.conversationToolOverrides, isFalse);
    expect(cloud.capabilities.offline, isFalse);
    expect(cloud.capabilities.agentExecution, isTrue);
  });

  test(
    'cloud native catalog returns empty without reading local storage',
    () async {
      final container = ProviderContainer(
        overrides: [
          workspaceSessionProvider(cloud).overrideWithValue(cloud),
          workspaceSessionForRouteProvider.overrideWith((_, _) async => cloud),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(availableToolsToAddProvider('mirror').future),
        isEmpty,
      );
    },
  );

  test('unsupported cloud paths fail typed before local fallback', () async {
    final container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(cloud).overrideWithValue(cloud),
        workspaceSessionForRouteProvider.overrideWith((_, _) async => cloud),
      ],
    );
    addTearDown(container.dispose);
    final _ = await container.read(
      workspaceSessionForRouteProvider('mirror').future,
    );

    expect(
      () => cloud.capabilities.require(
        supported: cloud.capabilities.conversationToolOverrides,
      ),
      throwsA(isA<UnsupportedWorkspaceCapabilityException>()),
    );
    expect(
      () =>
          container.read(mcpFormProvider('mirror').notifier).setTransport(.sse),
      throwsA(isA<UnsupportedWorkspaceCapabilityException>()),
    );
    expect(
      () => container
          .read(mcpFormProvider('mirror').notifier)
          .setAuthenticationType(.oauth),
      throwsA(isA<UnsupportedWorkspaceCapabilityException>()),
    );
  });
}
