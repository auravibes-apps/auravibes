/// Exact route classification shared by the shell and app-scope recovery gate.
abstract final class WorkspaceNavigation {
  static List<String> path(Uri uri) {
    final parts = uri.pathSegments;
    if (uri.hasScheme ||
        uri.hasAuthority ||
        parts.length < 3 ||
        parts.firstOrNull != 'workspaces') {
      return const [];
    }

    return parts.skip(2).toList();
  }

  static WorkspaceDestination? classify(Uri uri) => switch (path(uri)) {
    ['chat', 'new'] || ['chats', ...] => .chats,
    ['more', 'agents', ...] || ['more', 'skills', ...] => .agentsAndSkills,
    ['more', 'service-connections', ...] ||
    ['more', 'skill-credential-definitions', ...] ||
    ['more', 'tools'] ||
    ['more', 'models'] => .connections,
    ['settings'] => .appSettings,
    ['more', 'cloud-accounts', ...] => .cloudAccounts,
    _ => null,
  };

  /// Only these app-owned pages can recover an expired workspace session.
  static bool isAppScoped(Uri uri) => switch (path(uri)) {
    ['settings'] ||
    ['more', 'cloud-accounts'] ||
    [
      'more',
      'cloud-accounts',
      'add' || 'login' || 'register' || 'forgot-password',
    ] => true,
    _ => false,
  };

  static bool isConversation(Uri uri) => switch (path(uri)) {
    ['chats', _, ...] => true,
    _ => false,
  };

  static ConnectionDestination connectionView(String? view) => switch (view) {
    'providers' => .providers,
    'services' => .services,
    'credentials' => .credentials,
    _ => .overview,
  };
}

/// Sidebar destinations are presentation indexes, never shell branch indexes.
enum WorkspaceDestination {
  chats,
  agentsAndSkills,
  connections,
  appSettings,
  cloudAccounts,
}

enum AgentDestination { agents, skills }

enum ConnectionDestination { overview, providers, services, credentials, tools }
