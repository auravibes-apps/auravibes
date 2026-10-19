import 'dart:convert';

class McpAppToolMetadata {
  const McpAppToolMetadata({
    required this.resourceUri,
    List<String>? visibility,
  }) : _visibility = visibility;

  final String? resourceUri;
  final List<String>? _visibility;

  bool get isVisibleToApp => _visibility?.contains('app') ?? true;

  bool get isVisibleToModel => _visibility?.contains('model') ?? true;

  factory McpAppToolMetadata.fromMetadata(Map<String, dynamic>? metadata) {
    final uiValue = metadata?['ui'];
    final ui = uiValue is Map ? Map<String, dynamic>.from(uiValue) : null;
    final resourceUri = ui?.containsKey('resourceUri') == true
        ? _validResourceUri(ui?['resourceUri'])
        : _validResourceUri(metadata?['ui/resourceUri']);
    final visibilityValue = ui?['visibility'];
    final visibility = visibilityValue is List
        ? visibilityValue.whereType<String>().toList(growable: false)
        : visibilityValue == null
        ? null
        : const <String>[];

    return McpAppToolMetadata(resourceUri: resourceUri, visibility: visibility);
  }

  factory McpAppToolMetadata.fromResultRaw(String? responseRaw) {
    if (responseRaw == null) return McpAppToolMetadata.fromMetadata(null);
    try {
      final result = jsonDecode(responseRaw);
      final metadata = result is Map ? result['_meta'] : null;

      return McpAppToolMetadata.fromMetadata(
        metadata is Map ? Map<String, dynamic>.from(metadata) : null,
      );
    } on FormatException {
      return McpAppToolMetadata.fromMetadata(null);
    }
  }
}

String? _validResourceUri(Object? value) {
  if (value is! String || !value.startsWith('ui://')) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return null;

  return value;
}
