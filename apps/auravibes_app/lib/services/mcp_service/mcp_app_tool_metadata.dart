typedef McpAppToolMetadataValue = ({
  String? resourceUri,
  List<String>? visibility,
});

McpAppToolMetadataValue parseMcpAppToolMetadata(
  Map<String, dynamic>? metadata,
) {
  final ui = _metadataMap(metadata?['ui']);

  return (
    resourceUri: _resourceUri(ui, metadata),
    visibility: _visibility(ui?['visibility']),
  );
}

bool isMcpAppToolVisibleToApp(McpAppToolMetadataValue metadata) =>
    metadata.visibility?.contains('app') ?? true;

bool isMcpAppToolVisibleToModel(McpAppToolMetadataValue metadata) =>
    metadata.visibility?.contains('model') ?? true;

Map<String, dynamic>? _metadataMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

String? _resourceUri(Map<String, dynamic>? ui, Map<String, dynamic>? metadata) {
  final Object? value = switch (ui) {
    final Map<String, dynamic> uiMap when uiMap.containsKey('resourceUri') =>
      uiMap['resourceUri'],
    _ => metadata?['ui/resourceUri'],
  };

  return _validResourceUri(value);
}

List<String>? _visibility(Object? value) => switch (value) {
  final List<Object?> items => items.whereType<String>().toList(
    growable: false,
  ),
  null => null,
  _ => const [],
};

String? _validResourceUri(Object? value) {
  if (value is! String || !value.startsWith('ui://')) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return null;

  return value;
}
