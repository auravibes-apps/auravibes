class const McpAppToolMetadata({
  required final String? resourceUri,
  final List<String>? visibility,
}) {
  factory fromMetadata(Map<String, dynamic>? metadata) {
    final uiValue = metadata?['ui'];
    final ui = uiValue is Map ? Map<String, dynamic>.from(uiValue) : null;
    final resourceUri = ui?.containsKey('resourceUri') == true
        ? _validResourceUri(ui?['resourceUri'])
        : _validResourceUri(metadata?['ui/resourceUri']);
    final visibilityValue = ui?['visibility'];
    final List<String>? visibility;
    if (visibilityValue is List) {
      visibility = visibilityValue.whereType<String>().toList(growable: false);
    } else if (visibilityValue == null) {
      visibility = null;
    } else {
      visibility = const [];
    }

    return .new(resourceUri: resourceUri, visibility: visibility);
  }

  bool get isVisibleToApp => visibility?.contains('app') ?? true;

  bool get isVisibleToModel => visibility?.contains('model') ?? true;
}

String? _validResourceUri(Object? value) {
  if (value is! String || !value.startsWith('ui://')) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return null;

  return value;
}
