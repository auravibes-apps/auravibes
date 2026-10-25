import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

abstract final class ProjectConnectedWorkspaceViewUsecase {
  static Map<String, Object?> call(
    Object? response,
    Map<String, String> bindings,
  ) {
    validate(bindings);
    final value = _decode(response);

    return {
      for (final binding in bindings.entries)
        binding.key: _boundValue(response, value, binding),
    };
  }

  static void validate(Map<String, String> bindings) {
    for (final pointer in bindings.values) {
      if (pointer.length > 512 ||
          (pointer.isNotEmpty && !pointer.startsWith('/')) ||
          pointer.split('/').length > 16) {
        throw const WorkspaceTableException();
      }
    }
  }
}

Object? _decode(Object? value) {
  if (value is! String) return value;
  try {
    return jsonDecode(value);
  } on FormatException {
    return value;
  }
}

Object? _boundValue(
  Object? response,
  Object? decoded,
  MapEntry<String, String> binding,
) {
  if (binding.key == 'source' && binding.value.isEmpty && response is String) {
    return response;
  }
  final value = _pointer(decoded, binding.value);
  if (binding.key != 'source' || value is String) return value;

  return const JsonEncoder.withIndent('  ').convert(value);
}

Object? _pointer(Object? value, String path) {
  var current = value;
  for (final encoded in path.split('/').skip(1)) {
    final segment = encoded.replaceAll('~1', '/').replaceAll('~0', '~');
    current = _step(current, segment);
  }

  return current;
}

Object? _step(Object? value, String segment) => switch (value) {
  final Map<Object?, Object?> map when map.containsKey(segment) => map[segment],
  final List<Object?> list => _index(list, segment),
  _ => throw const WorkspaceTableException(),
};
Object? _index(List<Object?> values, String segment) {
  final index = int.tryParse(segment);
  if (index == null || index < 0 || index >= values.length) {
    throw const WorkspaceTableException();
  }

  return values[index];
}
