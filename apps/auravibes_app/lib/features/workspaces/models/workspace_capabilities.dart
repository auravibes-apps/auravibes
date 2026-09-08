import 'package:auravibes_app/features/workspaces/models/workspace_mcp_authentication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_mcp_transport.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';

export 'workspace_mcp_authentication.dart';
export 'workspace_mcp_transport.dart';

final class const WorkspaceCapabilities({
  required final Set<String> modelProviderIds,
  required final bool modelBrowserOAuth,
  required final bool modelDeviceOAuth,
  required final Set<WorkspaceMcpTransport> mcpTransports,
  required final Set<WorkspaceMcpAuthentication> mcpAuthentication,
  required final bool nativeTools,
  required final bool skills,
  required final bool attachments,
  required final bool conversationToolOverrides,
  required final bool offline,
  required final bool agentExecution,
}) {
  static const local = WorkspaceCapabilities(
    modelProviderIds: {'openai', 'openai-codex', 'openrouter', 'anthropic'},
    modelBrowserOAuth: true,
    modelDeviceOAuth: true,
    mcpTransports: {
      WorkspaceMcpTransport.streamableHttp,
      WorkspaceMcpTransport.sse,
    },
    mcpAuthentication: {
      WorkspaceMcpAuthentication.none,
      WorkspaceMcpAuthentication.bearerToken,
      WorkspaceMcpAuthentication.oauth,
    },
    nativeTools: true,
    skills: true,
    attachments: true,
    conversationToolOverrides: true,
    offline: true,
    agentExecution: true,
  );

  // Mirrors the implemented server provider, Codex OAuth, MCP, object, and
  // conversation contracts. Add capabilities only with matching enforcement.
  static const cloud = WorkspaceCapabilities(
    modelProviderIds: {'openai', 'openai-codex', 'openrouter', 'anthropic'},
    modelBrowserOAuth: true,
    modelDeviceOAuth: false,
    mcpTransports: {WorkspaceMcpTransport.streamableHttp},
    mcpAuthentication: {
      WorkspaceMcpAuthentication.none,
      WorkspaceMcpAuthentication.bearerToken,
    },
    nativeTools: false,
    skills: true,
    attachments: true,
    conversationToolOverrides: false,
    offline: false,
    agentExecution: true,
  );
  void require({required bool supported}) {
    if (!supported) throw const UnsupportedWorkspaceCapabilityException();
  }
}

final class const UnsupportedWorkspaceCapabilityException()
    implements Exception {
  String get localizationKey =>
      LocaleKeys.workspace_capabilities_unsupported_error;

  @override
  String toString() => localizationKey;
}
