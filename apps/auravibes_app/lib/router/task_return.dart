import 'package:auravibes_app/router/workspace_route_normalizer.dart';

/// Router-owned allowlist for task completion and cancellation.
abstract final class TaskReturn {
  static String? validate(String? location, {required String workspaceId}) {
    final normalizedLocation = location == null
        ? null
        : WorkspaceRouteNormalizer.normalizeLegacyMoreLocation(location) ??
              location;
    if (!_TaskReturnValidation._hasSafeLocation(normalizedLocation)) {
      return null;
    }
    final safeLocation = normalizedLocation;
    if (safeLocation == null) return null;
    try {
      if (!_TaskReturnValidation._hasSafePathSegments(safeLocation)) {
        return null;
      }
      final uri = Uri.parse(safeLocation);
      if (!_TaskReturnValidation.isWorkspaceTask(uri, workspaceId)) return null;

      return uri.toString();
    } on FormatException {
      return null;
    }
  }
}

abstract final class _TaskReturnValidation {
  static bool isWorkspaceTask(Uri uri, String workspaceId) {
    if (uri.hasScheme || uri.hasAuthority || uri.hasFragment) return false;
    final parts = uri.pathSegments;
    if (parts.length < 3 ||
        parts.firstOrNull != 'workspaces' ||
        parts[1] != workspaceId ||
        parts.any((part) => part.isEmpty)) {
      return false;
    }

    return _recognized(parts.skip(2).toList());
  }

  static bool _hasSafeLocation(String? location) =>
      location != null &&
      location.startsWith('/') &&
      !location.startsWith('//') &&
      !location.contains(r'\');

  static bool _hasSafePathSegments(String location) {
    final rawPath = location.split('?').first.split('#').first;
    for (final segment in rawPath.split('/')) {
      if (_isUnsafeDecodedSegment(Uri.decodeComponent(segment))) return false;
    }

    return true;
  }

  static bool _isUnsafeDecodedSegment(String segment) =>
      segment == '.' ||
      segment == '..' ||
      segment.contains('%') ||
      segment.contains('/') ||
      segment.contains(r'\');

  static bool _recognized(List<String> path) =>
      _recognizedConversation(path) ||
      _recognizedWorkspaceSettings(path) ||
      _recognizedFeatureRoot(path) ||
      _recognizedFeatureChild(path);

  static bool _recognizedConversation(List<String> path) => switch (path) {
    ['chat', 'new'] ||
    ['chats'] ||
    ['chats', _] ||
    ['chats', _, 'sub-agents', _] => true,
    _ => false,
  };

  static bool _recognizedWorkspaceSettings(List<String> path) => switch (path) {
    ['settings'] || ['workspace-settings'] => true,
    _ => false,
  };

  static bool _recognizedFeatureRoot(List<String> path) => switch (path) {
    [
      'tools' ||
          'models' ||
          'agents' ||
          'skills' ||
          'service-connections' ||
          'manage-workspaces' ||
          'cloud-accounts',
    ] =>
      true,
    _ => false,
  };

  static bool _recognizedFeatureChild(List<String> path) => switch (path) {
    ['agents' || 'skills' || 'service-connections', _] ||
    ['skills', _, 'tools' || 'resources', _] ||
    ['manage-workspaces', 'create'] => true,
    ['manage-workspaces', 'cloud', _, final id] => int.tryParse(id) != null,
    _ => false,
  };
}
