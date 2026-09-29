typedef ToolSchemaNode = ({Map<String, Object?> schema, String path});

/// Shared JSON Schema lookup for strict preflight and tool argument validation.
final class ToolSchema {
  const new(this.root);

  final Map<String, Object?> root;

  ToolSchemaNode? node(Object? value, String path) {
    if (value is! Map || !value.keys.every((key) => key is String)) {
      return null;
    }
    return (schema: Map<String, Object?>.from(value), path: path);
  }

  ToolSchemaNode? reference(Object? value) {
    if (value is! String || !value.startsWith('#')) return null;
    if (value == '#') return (schema: root, path: r'$');
    if (!value.startsWith('#/')) return null;

    Object? current = root;
    final path = StringBuffer(r'$');
    for (final raw in value.substring(2).split('/')) {
      final segment = raw.replaceAll('~1', '/').replaceAll('~0', '~');
      if (current is! Map || !current.containsKey(segment)) return null;
      current = current[segment];
      path.write('.$segment');
    }
    return node(current, path.toString());
  }

  bool acceptsNull(ToolSchemaNode node, [Set<String>? visited]) {
    final paths = visited ?? <String>{};
    if (!paths.add(node.path)) return false;

    final allowedValues = node.schema['enum'];
    if (allowedValues is List && !allowedValues.contains(null)) return false;
    if (node.schema.containsKey('const') && node.schema['const'] != null) {
      return false;
    }

    if (node.schema[r'$ref'] case final referenceValue?) {
      final target = reference(referenceValue);
      return target != null && acceptsNull(target, paths);
    }
    if (types(node.schema['type'])?.contains('null') == true) return true;
    if (node.schema['anyOf'] case final List<dynamic> branches) {
      for (var index = 0; index < branches.length; index++) {
        final branch = this.node(branches[index], '${node.path}.anyOf[$index]');
        if (branch != null && acceptsNull(branch, paths)) return true;
      }
    }
    return false;
  }

  Set<String>? types(Object? value) {
    const supported = {
      'array',
      'boolean',
      'integer',
      'null',
      'number',
      'object',
      'string',
    };
    if (value is String && supported.contains(value)) return {value};
    if (value is! List || value.length != 2) return null;
    final names = value.whereType<String>().toSet();
    if (names.length != 2 ||
        names.length != value.length ||
        !names.contains('null') ||
        !supported.containsAll(names)) {
      return null;
    }
    return names;
  }
}
