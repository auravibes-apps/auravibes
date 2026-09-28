import 'package:auravibes_engine/src/tool_schema.dart';

enum ToolSchemaIssueReason { invalidSchema, unsupportedKeyword, providerLimit }

class const ToolSchemaIssue({
  required final ToolSchemaIssueReason reason,
  required final String path,
  required final String detail,
});

/// Checks the OpenAI strict function schema subset without changing the input.
ToolSchemaIssue? strictToolSchemaIssue(Map<String, dynamic>? value) {
  if (value == null) {
    return const ToolSchemaIssue(
      reason: .invalidSchema,
      path: r'$.type',
      detail: 'must be "object"',
    );
  }
  return _StrictSchemaCheck(ToolSchema(value)).check();
}

const _allowedKeywords = {
  r'$defs',
  r'$ref',
  'additionalProperties',
  'anyOf',
  'const',
  'description',
  'enum',
  'items',
  'maxItems',
  'maxLength',
  'maximum',
  'minItems',
  'minLength',
  'minimum',
  'properties',
  'required',
  'title',
  'type',
};

final class _StrictSchemaCheck {
  new(this.schema);

  final ToolSchema schema;
  final Set<String> _active = {};
  final Set<String> _counted = {};
  int _propertyCount = 0;
  int _stringLength = 0;
  int _enumCount = 0;

  ToolSchemaIssue? check() {
    if (schema.root['type'] != 'object' ||
        schema.root.containsKey('anyOf') ||
        schema.root.containsKey(r'$ref')) {
      return _invalid(r'$.type', 'root must be an object');
    }
    return _visit((schema: schema.root, path: r'$'), 0);
  }

  ToolSchemaIssue? _visit(ToolSchemaNode node, int objectDepth) {
    if (!_active.add(node.path)) return null;
    try {
      return _checkNode(node, objectDepth, _counted.add(node.path));
    } finally {
      _active.remove(node.path);
    }
  }

  ToolSchemaIssue? _checkNode(
    ToolSchemaNode node,
    int objectDepth,
    bool countValues,
  ) {
    for (final key in node.schema.keys) {
      if (!_allowedKeywords.contains(key)) {
        return ToolSchemaIssue(
          reason: .unsupportedKeyword,
          path: '${node.path}.$key',
          detail: 'unsupported keyword',
        );
      }
    }
    final definitions = _definitions(node, objectDepth, countValues);
    if (definitions != null) return definitions;
    final values = countValues ? _values(node) : null;
    if (values != null) return values;
    final constraints = _constraints(node);
    if (constraints != null) return constraints;

    if (node.schema.containsKey(r'$ref')) {
      if (node.schema.containsKey('type') ||
          node.schema.containsKey('anyOf') ||
          node.schema.containsKey('enum') ||
          node.schema.containsKey('const') ||
          _hasValidationSiblings(node.schema, r'$ref')) {
        return _invalid(node.path, 'reference cannot combine with constraints');
      }
      return _reference(node, objectDepth);
    }
    if (node.schema.containsKey('anyOf')) {
      if (node.schema.containsKey('type') ||
          node.schema.containsKey('enum') ||
          node.schema.containsKey('const') ||
          _hasValidationSiblings(node.schema, 'anyOf')) {
        return _invalid(node.path, 'anyOf cannot combine with constraints');
      }
      return _alternatives(node, objectDepth);
    }

    final types = schema.types(node.schema['type']);
    if (types == null) {
      return _invalid('${node.path}.type', 'must name a supported type');
    }
    if (types.contains('object')) {
      return _object(node, objectDepth + 1, countValues);
    }
    if (types.contains('array')) return _array(node, objectDepth);
    return null;
  }

  ToolSchemaIssue? _definitions(
    ToolSchemaNode node,
    int depth,
    bool countValues,
  ) {
    if (!node.schema.containsKey(r'$defs')) return null;
    final definitions = node.schema[r'$defs'];
    if (definitions is! Map ||
        !definitions.keys.every((key) => key is String)) {
      return _invalid('${node.path}.\$defs', 'must be an object');
    }
    for (final entry in definitions.entries) {
      final path = '${node.path}.\$defs.${entry.key}';
      if (countValues) _stringLength += (entry.key as String).length;
      final child = schema.node(entry.value, path);
      if (child == null) return _invalid(path, 'must be a schema');
      final issue = _visit(child, depth);
      if (issue != null) return issue;
    }
    return _stringLimit(node.path);
  }

  ToolSchemaIssue? _reference(ToolSchemaNode node, int depth) {
    final target = schema.reference(node.schema[r'$ref']);
    if (target == null) {
      return _invalid('${node.path}.\$ref', 'must resolve to a local schema');
    }
    return _visit(target, depth);
  }

  ToolSchemaIssue? _alternatives(ToolSchemaNode node, int depth) {
    final branches = node.schema['anyOf'];
    if (branches is! List || branches.isEmpty) {
      return _invalid('${node.path}.anyOf', 'must be a non-empty array');
    }
    for (var index = 0; index < branches.length; index++) {
      final path = '${node.path}.anyOf[$index]';
      final child = schema.node(branches[index], path);
      if (child == null) return _invalid(path, 'must be a schema');
      final issue = _visit(child, depth);
      if (issue != null) return issue;
    }
    return null;
  }

  ToolSchemaIssue? _object(ToolSchemaNode node, int depth, bool countValues) {
    if (depth > 10) return _limit(node.path, 'object nesting exceeds 10');
    final properties = node.schema['properties'];
    if (properties is! Map || !properties.keys.every((key) => key is String)) {
      return _invalid('${node.path}.properties', 'must be an object');
    }
    if (node.schema['additionalProperties'] != false) {
      return _invalid('${node.path}.additionalProperties', 'must be false');
    }
    final required = node.schema['required'];
    if (required is! List ||
        !required.every((name) => name is String) ||
        required.toSet().length != required.length ||
        required.toSet().length != properties.length ||
        !required.toSet().containsAll(properties.keys)) {
      return _invalid('${node.path}.required', 'must list every property once');
    }
    for (final entry in properties.entries) {
      final path = '${node.path}.properties.${entry.key}';
      if (countValues) {
        _propertyCount++;
        _stringLength += (entry.key as String).length;
      }
      if (_propertyCount > 5000) {
        return _limit(path, 'property count exceeds 5000');
      }
      final child = schema.node(entry.value, path);
      if (child == null) return _invalid(path, 'must be a schema');
      final issue = _visit(child, depth);
      if (issue != null) return issue;
    }
    return _stringLimit(node.path);
  }

  ToolSchemaIssue? _array(ToolSchemaNode node, int depth) {
    final child = schema.node(node.schema['items'], '${node.path}.items');
    if (child == null) {
      return _invalid('${node.path}.items', 'must be a schema');
    }
    return _visit(child, depth);
  }

  ToolSchemaIssue? _values(ToolSchemaNode node) {
    final values = node.schema['enum'];
    if (node.schema.containsKey('enum')) {
      if (values is! List || values.isEmpty) {
        return _invalid('${node.path}.enum', 'must be a non-empty array');
      }
      _enumCount += values.length;
      if (_enumCount > 1000) {
        return _limit('${node.path}.enum', 'enum count exceeds 1000');
      }
      final length = values.whereType<String>().fold<int>(
        0,
        (total, value) => total + value.length,
      );
      if (values.length > 250 && length > 15000) {
        return _limit('${node.path}.enum', 'enum strings exceed 15000');
      }
      _stringLength += length;
    }
    if (node.schema['const'] case final String value) {
      _stringLength += value.length;
    }
    return _stringLimit(node.path);
  }

  ToolSchemaIssue? _constraints(ToolSchemaNode node) {
    for (final key in const [
      'minLength',
      'maxLength',
      'minItems',
      'maxItems',
    ]) {
      final value = node.schema[key];
      if (value != null && (value is! int || value < 0)) {
        return _invalid('${node.path}.$key', 'must be a non-negative integer');
      }
    }
    for (final key in const ['minimum', 'maximum']) {
      final value = node.schema[key];
      if (value != null && (value is! num || !value.isFinite)) {
        return _invalid('${node.path}.$key', 'must be a number');
      }
    }
    for (final key in const ['description', 'title']) {
      final value = node.schema[key];
      if (value != null && value is! String) {
        return _invalid('${node.path}.$key', 'must be a string');
      }
    }
    return null;
  }

  ToolSchemaIssue? _stringLimit(String path) => _stringLength > 120000
      ? _limit(path, 'schema strings exceed 120000')
      : null;

  ToolSchemaIssue _invalid(String path, String detail) =>
      ToolSchemaIssue(reason: .invalidSchema, path: path, detail: detail);

  ToolSchemaIssue _limit(String path, String detail) =>
      ToolSchemaIssue(reason: .providerLimit, path: path, detail: detail);

  bool _hasValidationSiblings(Map<String, Object?> node, String combinator) =>
      node.keys.any(
        (key) =>
            key != combinator &&
            key != r'$defs' &&
            key != 'description' &&
            key != 'title',
      );
}
