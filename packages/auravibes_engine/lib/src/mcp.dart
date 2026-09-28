import 'dart:collection';
import 'dart:convert';

abstract final class McpDiscoveryPolicy {
  static const int maxTools = 100;
  static const int maxPages = 100;
  static const int maxCatalogBytes = 1024 * 1024;
  static const int maxCursorBytes = 4096;
  static const int maxNameLength = 200;
  static const int maxDescriptionLength = 4000;
  static const int maxSchemaBytes = 64 * 1024;
  static const int maxSchemaDepth = 16;
  static const int maxToolBytes = 2 * maxSchemaBytes + 16 * 1024;

  static String boundedSchema(Object? schema) {
    if (schema is! Map) {
      throw const FormatException('Invalid MCP tool schema.');
    }
    _validateJson(schema, 0, maxSchemaDepth);
    final encoded = jsonEncode(schema);
    if (utf8.encode(encoded).length > maxSchemaBytes) {
      throw const FormatException('MCP tool schema is too large.');
    }
    return encoded;
  }

  static Map<String, Object?> validateTool(Object? raw) {
    if (raw is! Map) throw const FormatException('Invalid MCP tool.');
    _validateJson(raw, 0, maxSchemaDepth + 2);
    final name = raw['name'];
    final description = raw['description'];
    final title = raw['title'];
    if (name is! String ||
        name.isEmpty ||
        name.length > maxNameLength ||
        (description != null &&
            (description is! String ||
                description.length > maxDescriptionLength)) ||
        (title != null && (title is! String || title.length > maxNameLength))) {
      throw const FormatException('Invalid MCP tool.');
    }
    if ((raw['supportsProgress'] != null && raw['supportsProgress'] is! bool) ||
        (raw['supportsCancellation'] != null &&
            raw['supportsCancellation'] is! bool) ||
        (raw['metadata'] != null && raw['metadata'] is! Map)) {
      throw const FormatException('Invalid MCP tool metadata.');
    }
    boundedSchema(raw['inputSchema'] ?? const <String, Object?>{});
    if (raw['outputSchema'] != null) boundedSchema(raw['outputSchema']);
    if (utf8.encode(jsonEncode(raw)).length > maxToolBytes) {
      throw const FormatException('MCP tool metadata is too large.');
    }
    return Map<String, Object?>.from(raw);
  }

  static void _validateJson(Object? value, int depth, int maxDepth) {
    if (depth > maxDepth) {
      throw const FormatException('MCP tool schema is too deep.');
    }
    switch (value) {
      case Map<Object?, Object?>():
        for (final entry in value.entries) {
          if (entry.key is! String) {
            throw const FormatException(
              'MCP tool schema has a non-string key.',
            );
          }
          _validateJson(entry.value, depth + 1, maxDepth);
        }
      case List<Object?>():
        for (final item in value) {
          _validateJson(item, depth + 1, maxDepth);
        }
      case null || String() || bool():
        return;
      case num():
        if (!value.isFinite) {
          throw const FormatException('MCP tool schema is not JSON.');
        }
        return;
      default:
        throw const FormatException('MCP tool schema is not JSON.');
    }
  }
}

Future<List<Map<String, Object?>>> collectMcpToolsCatalog(
  Future<Map<String, Object?>> Function(String? cursor) fetchPage,
) async {
  final tools = <Map<String, Object?>>[];
  final names = <String>{};
  final cursors = <String>{};
  var catalogBytes = 0;
  String? cursor;
  for (var page = 0; page < McpDiscoveryPolicy.maxPages; page++) {
    final result = await fetchPage(cursor);
    final rawTools = result['tools'];
    if (rawTools is! List ||
        rawTools.length > McpDiscoveryPolicy.maxTools - tools.length) {
      throw const FormatException('Invalid MCP tools response.');
    }
    for (final raw in rawTools) {
      final tool = McpDiscoveryPolicy.validateTool(raw);
      final name = switch (tool['name']) {
        final String name => name,
        _ => throw const FormatException('Invalid MCP tool.'),
      };
      if (!names.add(name)) {
        throw const FormatException('Duplicate MCP tool.');
      }
      catalogBytes += utf8.encode(jsonEncode(tool)).length;
      if (catalogBytes > McpDiscoveryPolicy.maxCatalogBytes) {
        throw const FormatException('MCP tools catalog is too large.');
      }
      tools.add(tool);
    }
    final nextCursor = result['nextCursor'];
    if (nextCursor == null) return tools;
    if (nextCursor is! String ||
        nextCursor.isEmpty ||
        utf8.encode(nextCursor).length > McpDiscoveryPolicy.maxCursorBytes ||
        !cursors.add(nextCursor)) {
      throw const FormatException('Invalid MCP tools cursor.');
    }
    cursor = nextCursor;
  }
  throw const FormatException('MCP tools page limit exceeded.');
}

final class McpDiscoveredTool {
  new({
    required this.name,
    required Map<String, Object?> inputSchema,
    Map<String, Object?>? outputSchema,
    this.description,
  }) : inputSchema = _freezeMap(inputSchema),
       outputSchema = outputSchema == null ? null : _freezeMap(outputSchema);

  final String name;
  final String? description;
  final Map<String, Object?> inputSchema;
  final Map<String, Object?>? outputSchema;
}

List<McpDiscoveredTool> parseMcpToolsList(
  Map<String, Object?> result, {
  required int maxTools,
  required void Function(Object? schema) validateInputSchema,
}) {
  final rawTools = result['tools'];
  if (rawTools is! List || rawTools.length > maxTools) {
    throw const FormatException('Invalid MCP tools response.');
  }
  return rawTools
      .map((raw) {
        final tool = McpDiscoveryPolicy.validateTool(raw);
        final name = tool['name'];
        final description = tool['description'];
        final schema = tool['inputSchema'] ?? const <String, Object?>{};
        final outputSchema = tool['outputSchema'];
        if (name is! String ||
            name.isEmpty ||
            (description != null && description is! String) ||
            schema is! Map ||
            !schema.keys.every((key) => key is String)) {
          throw const FormatException('Invalid MCP tool.');
        }
        validateInputSchema(schema);
        return McpDiscoveredTool(
          name: name,
          description: description as String?,
          inputSchema: Map<String, Object?>.from(schema),
          outputSchema: outputSchema is Map
              ? Map<String, Object?>.from(outputSchema)
              : null,
        );
      })
      .toList(growable: false);
}

sealed class const McpContent() {
  Map<String, Object?> toJson();
}

final class McpTextContent extends McpContent {
  new(this.text, {Map<String, Object?>? annotations})
    : annotations = annotations == null ? null : _freezeMap(annotations);
  final String text;
  final Map<String, Object?>? annotations;
  @override
  Map<String, Object?> toJson() => {
    'type': 'text',
    'text': text,
    if (annotations != null) 'annotations': annotations,
  };
}

final class McpBinaryContent extends McpContent {
  new({
    required this.type,
    required this.mimeType,
    this.data,
    this.url,
    Map<String, Object?>? annotations,
  }) : annotations = annotations == null ? null : _freezeMap(annotations);
  final String type;
  final String mimeType;
  final String? data;
  final String? url;
  final Map<String, Object?>? annotations;
  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'mimeType': mimeType,
    if (data != null) 'data': data,
    if (url != null) 'url': url,
    if (annotations != null) 'annotations': annotations,
  };
}

final class McpResourceContent extends McpContent {
  new({
    required this.uri,
    this.text,
    this.blob,
    this.mimeType,
    this.name,
    this.description,
    this.isLink = false,
    Map<String, Object?>? annotations,
    Map<String, Object?>? meta,
  }) : annotations = annotations == null ? null : _freezeMap(annotations),
       meta = meta == null ? null : _freezeMap(meta);
  final String uri;
  final String? text;
  final String? blob;
  final String? mimeType;
  final String? name;
  final String? description;
  final bool isLink;
  final Map<String, Object?>? annotations;
  final Map<String, Object?>? meta;
  @override
  Map<String, Object?> toJson() => {
    'type': isLink ? 'resource_link' : 'resource',
    'uri': uri,
    if (text != null) 'text': text,
    if (blob != null) 'blob': blob,
    if (mimeType != null) 'mimeType': mimeType,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (annotations != null) 'annotations': annotations,
    if (meta != null) '_meta': meta,
  };
}

class McpToolResult {
  new({
    List<McpContent> content = const [],
    Map<String, Object?>? structuredContent,
    this.isStreaming = false,
    this.isError,
  }) : content = List.unmodifiable(content),
       structuredContent = structuredContent == null
           ? null
           : _freezeMap(structuredContent);
  final List<McpContent> content;
  final Map<String, Object?>? structuredContent;
  final bool isStreaming;
  final bool? isError;

  String toModelText() {
    if (content case [McpTextContent(:final text)]
        when structuredContent == null && !isStreaming && isError != true) {
      return text;
    }
    return jsonEncode({
      'content': content.map((item) => item.toJson()).toList(),
      if (structuredContent != null) 'structuredContent': structuredContent,
      'isStreaming': isStreaming,
      if (isError != null) 'isError': isError,
    });
  }
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) =>
    UnmodifiableMapView({
      for (final entry in value.entries) entry.key: _freezeJson(entry.value),
    });
Object? _freezeJson(Object? value) => switch (value) {
  final Map<String, Object?> map => _freezeMap(map),
  final List<Object?> list => List<Object?>.unmodifiable(list.map(_freezeJson)),
  _ => value,
};
