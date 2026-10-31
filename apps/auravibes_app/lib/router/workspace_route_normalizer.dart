import 'package:characters/characters.dart';

/// Normalizes legacy workspace locations before route matching and validation.
abstract final class WorkspaceRouteNormalizer {
  /// Rewrites `/workspaces/<id>/more/<destination>` to its canonical path.
  ///
  /// Returns `null` when [location] does not contain the legacy path shape.
  /// Path segments remain raw so callers can still reject encoded separators
  /// and traversal after normalization.
  static String? normalizeLegacyMoreLocation(String location) {
    final locationCharacters = location.characters.toList();
    final queryIndex = locationCharacters.indexOf('?');
    final fragmentIndex = locationCharacters.indexOf('#');
    var pathEnd = locationCharacters.length;
    if (queryIndex >= 0 && queryIndex < pathEnd) pathEnd = queryIndex;
    if (fragmentIndex >= 0 && fragmentIndex < pathEnd) {
      pathEnd = fragmentIndex;
    }
    final fragmentSuffix = fragmentIndex < 0
        ? ''
        : locationCharacters.skip(fragmentIndex).join();

    final rawPath = locationCharacters.take(pathEnd).join();
    final segments = rawPath.split('/');
    if (segments.length < 5 ||
        segments.firstOrNull != '' ||
        segments[1] != 'workspaces' ||
        segments[2].isEmpty ||
        segments[3] != 'more' ||
        segments[4].isEmpty) {
      return null;
    }

    final canonicalPath = [...segments.take(3), ...segments.skip(4)].join('/');
    final acceptedKeys = _acceptedQueryKeys(segments.skip(4).toList());
    final queryStart = _queryStart(queryIndex, fragmentIndex);
    if (queryStart == null || acceptedKeys.isEmpty) {
      return '$canonicalPath$fragmentSuffix';
    }

    final queryEnd = fragmentIndex < 0
        ? locationCharacters.length
        : fragmentIndex;
    final rawQuery = locationCharacters
        .skip(queryStart)
        .take(queryEnd - queryStart)
        .join();
    if (rawQuery.isEmpty) return '$canonicalPath$fragmentSuffix';

    try {
      final queryValues = Uri.parse('/?$rawQuery').queryParametersAll;
      final filtered = <String, String>{};
      for (final key in acceptedKeys) {
        final values = queryValues[key];
        if (values != null && values.length == 1) {
          filtered[key] = values.single;
        }
      }
      if (filtered.isEmpty) return '$canonicalPath$fragmentSuffix';

      return '$canonicalPath?${Uri(queryParameters: filtered).query}'
          '$fragmentSuffix';
    } on FormatException {
      return null;
    }
  }
}

int? _queryStart(int queryIndex, int fragmentIndex) {
  if (queryIndex < 0 || (fragmentIndex >= 0 && fragmentIndex < queryIndex)) {
    return null;
  }

  return queryIndex + 1;
}

Set<String> _acceptedQueryKeys(List<String> path) => switch (path) {
  ['chat', 'new'] => const {'model-selection-id'},
  ['chats', _] => const {'message-id'},
  ['bookmarks'] => const {'conversation-id'},
  ['manage-workspaces'] => const {'view'},
  ['manage-workspaces', 'cloud', _, _] => const {'server-url'},
  ['cloud-accounts', 'add' || 'login' || 'register' || 'forgot-password'] =>
    const {'return-path'},
  ['service-connections'] => const {'view'},
  ['service-connections', 'new'] => const {
    'return-path',
    'type',
    'connectorId',
    'modelProviderId',
  },
  _ => const {},
};
