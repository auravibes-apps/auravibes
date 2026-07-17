import 'package:auravibes_app/i18n/locale_keys.dart';

enum WorkspaceMcpTransport { streamableHttp, sse }

enum WorkspaceMcpAuthentication { none, bearerToken, oauth }

final class WorkspaceCapabilities {
  const WorkspaceCapabilities({
    required this.modelProviderIds,
    required this.modelBrowserOAuth,
    required this.modelDeviceOAuth,
    required this.mcpTransports,
    required this.mcpAuthentication,
    required this.nativeTools,
    required this.skills,
    required this.attachments,
    required this.conversationToolOverrides,
    required this.offline,
    required this.agentExecution,
  });

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

  final Set<String> modelProviderIds;
  final bool modelBrowserOAuth;
  final bool modelDeviceOAuth;
  final Set<WorkspaceMcpTransport> mcpTransports;
  final Set<WorkspaceMcpAuthentication> mcpAuthentication;
  final bool nativeTools;
  final bool skills;
  final bool attachments;
  final bool conversationToolOverrides;
  final bool offline;
  final bool agentExecution;

  void require({required bool supported}) {
    if (!supported) throw const UnsupportedWorkspaceCapabilityException();
  }
}

final class UnsupportedWorkspaceCapabilityException implements Exception {
  const UnsupportedWorkspaceCapabilityException();

  String get localizationKey =>
      LocaleKeys.workspace_capabilities_unsupported_error;

  @override
  String toString() => localizationKey;
}
