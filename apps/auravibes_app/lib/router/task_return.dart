/// Router-owned allowlist for task completion and cancellation.
abstract final class TaskReturn {
  static String? validate(String? location, {required String workspaceId}) {
    if (location == null ||
        !location.startsWith('/') ||
        location.startsWith('//') ||
        location.contains(r'\')) {
      return null;
    }
    try {
      final rawPath = location.split('?').first.split('#').first;
      final segments = rawPath.split('/');
      for (final segment in segments) {
        final decoded = Uri.decodeComponent(segment);
        if (decoded == '.' ||
            decoded == '..' ||
            decoded.contains('%') ||
            decoded.contains('/') ||
            decoded.contains(r'\')) {
          return null;
        }
      }
      final uri = Uri.parse(location);
      if (uri.hasScheme || uri.hasAuthority || uri.hasFragment) return null;
      final parts = uri.pathSegments;
      if (parts.length < 3 ||
          parts.firstOrNull != 'workspaces' ||
          parts[1] != workspaceId ||
          parts.any((part) => part.isEmpty)) {
        return null;
      }
      if (!_recognized(parts.skip(2).toList())) return null;

      return uri.toString();
    } on FormatException {
      return null;
    }
  }

  static bool _recognized(List<String> path) => switch (path) {
    ['chat', 'new'] ||
    ['chats'] ||
    ['chats', _] ||
    ['chats', _, 'sub-agents', _] ||
    ['settings'] ||
    ['workspace-settings'] ||
    ['more'] ||
    [
      'more',
      'tools' ||
          'models' ||
          'agents' ||
          'skills' ||
          'service-connections' ||
          'skill-credential-definitions' ||
          'manage-workspaces' ||
          'cloud-accounts',
    ] ||
    [
      'more',
      'agents' ||
          'skills' ||
          'service-connections' ||
          'skill-credential-definitions',
      _,
    ] ||
    ['more', 'skills', _, 'tools' || 'resources', _] ||
    ['more', 'manage-workspaces', 'create'] => true,
    ['more', 'manage-workspaces', 'cloud', _, final id] =>
      int.tryParse(id) != null,
    _ => false,
  };
}
