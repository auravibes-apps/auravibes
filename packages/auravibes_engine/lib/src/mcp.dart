import 'dart:collection';
import 'dart:convert';

final class McpDiscoveredTool {
  new({
    required this.name,
    required Map<String, Object?> inputSchema,
    this.description,
  }) : inputSchema = _freezeMap(inputSchema);

  final String name;
  final String? description;
  final Map<String, Object?> inputSchema;
}

List<McpDiscoveredTool> parseMcpToolsList(Map<String, Object?> result) {
  final rawTools = result['tools'];
  if (rawTools is! List) {
    throw const FormatException('Invalid MCP tools response.');
  }
  return rawTools
      .map((raw) {
        if (raw is! Map) throw const FormatException('Invalid MCP tool.');
        final name = raw['name'];
        final description = raw['description'];
        final schema = raw['inputSchema'] ?? const <String, Object?>{};
        if (name is! String ||
            name.isEmpty ||
            (description != null && description is! String) ||
            schema is! Map ||
            !schema.keys.every((key) => key is String)) {
          throw const FormatException('Invalid MCP tool.');
        }
        return McpDiscoveredTool(
          name: name,
          description: description as String?,
          inputSchema: Map<String, Object?>.from(schema),
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
