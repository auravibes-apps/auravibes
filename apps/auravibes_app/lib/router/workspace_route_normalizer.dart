import 'package:characters/characters.dart';

const _workspacePrefixSegmentCount = 3;
const _legacyDestinationStartSegmentIndex = 4;

/// Normalizes legacy workspace locations before route matching and validation.
abstract final class WorkspaceRouteNormalizer {
  /// Rewrites `/workspaces/<id>/more/<destination>` to its canonical path.
  ///
  /// Returns `null` when [location] does not contain the legacy path shape.
  /// Path segments remain raw so callers can still reject encoded separators
  /// and traversal after normalization.
  static String? normalizeLegacyMoreLocation(String location) {
    try {
      return _LegacyMoreLocationNormalizer.normalize(location);
    } on FormatException {
      return null;
    }
  }
}

typedef _RawLocationParts = ({
  String path,
  String? query,
  String fragmentSuffix,
});

abstract final class _LegacyMoreLocationNormalizer {
  static String? normalize(String location) {
    final rawLocation = _splitLocation(location);
    final segments = _legacyMoreSegments(rawLocation.path);
    if (segments == null) return null;

    final canonicalPath = _canonicalPath(segments);

    return _appendCanonicalQuery(canonicalPath, segments, rawLocation);
  }

  static _RawLocationParts _splitLocation(String location) {
    final characters = location.characters.toList();
    final queryIndex = characters.indexOf('?');
    final fragmentIndex = characters.indexOf('#');
    final rawQuery = _rawQuery(characters, queryIndex, fragmentIndex);
    final fragmentSuffix = _fragmentSuffix(characters, fragmentIndex);

    return (
      path: _rawPath(characters, queryIndex, fragmentIndex),
      query: rawQuery,
      fragmentSuffix: fragmentSuffix,
    );
  }

  static String? _rawQuery(
    List<String> characters,
    int queryIndex,
    int fragmentIndex,
  ) {
    if (queryIndex < 0 || (fragmentIndex >= 0 && fragmentIndex < queryIndex)) {
      return null;
    }

    final queryEnd = fragmentIndex < 0 ? characters.length : fragmentIndex;

    return characters
        .skip(queryIndex + 1)
        .take(queryEnd - queryIndex - 1)
        .join();
  }

  static String _fragmentSuffix(List<String> characters, int fragmentIndex) =>
      fragmentIndex < 0 ? '' : characters.skip(fragmentIndex).join();

  static List<String>? _legacyMoreSegments(String rawPath) {
    final segments = rawPath.split('/');
    if (segments.length <= _legacyDestinationStartSegmentIndex ||
        segments.firstOrNull != '' ||
        segments[1] != 'workspaces' ||
        segments[2].isEmpty ||
        segments[3] != 'more' ||
        segments[_legacyDestinationStartSegmentIndex].isEmpty) {
      return null;
    }

    return segments;
  }

  static String _canonicalPath(List<String> segments) =>
      [
        ...segments.take(_workspacePrefixSegmentCount),
        ...segments.skip(_legacyDestinationStartSegmentIndex),
      ].join('/');

  static String _appendCanonicalQuery(
    String canonicalPath,
    List<String> segments,
    _RawLocationParts rawLocation,
  ) {
    final acceptedKeys = _acceptedQueryKeys(
      segments.skip(_legacyDestinationStartSegmentIndex).toList(),
    );
    final query = _canonicalQuery(rawLocation.query, acceptedKeys);
    final querySuffix = query == null ? '' : '?$query';

    return '$canonicalPath$querySuffix${rawLocation.fragmentSuffix}';
  }

  static String? _canonicalQuery(String? rawQuery, Set<String> acceptedKeys) {
    if (rawQuery == null || rawQuery.isEmpty || acceptedKeys.isEmpty) {
      return null;
    }

    final queryValues = Uri.parse('/?$rawQuery').queryParametersAll;
    final filtered = _singleAcceptedValues(queryValues, acceptedKeys);
    if (filtered.isEmpty) return null;

    return Uri(queryParameters: filtered).query;
  }

  static Map<String, String> _singleAcceptedValues(
    Map<String, List<String>> queryValues,
    Set<String> acceptedKeys,
  ) {
    final filtered = <String, String>{};
    for (final key in acceptedKeys) {
      final values = queryValues[key];
      if (values != null && values.length == 1) {
        filtered[key] = values.single;
      }
    }

    return filtered;
  }

  static Set<String> _acceptedQueryKeys(List<String> path) => switch (path) {
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
}

String _rawPath(List<String> characters, int queryIndex, int fragmentIndex) {
  var pathEnd = characters.length;
  if (queryIndex >= 0 && queryIndex < pathEnd) pathEnd = queryIndex;
  if (fragmentIndex >= 0 && fragmentIndex < pathEnd) {
    pathEnd = fragmentIndex;
  }

  return characters.take(pathEnd).join();
}
