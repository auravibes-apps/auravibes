import 'package:auravibes_engine/src/model_capabilities.dart';

class ModelsDevCatalogValue({
  required final List<ModelsDevProviderValue> providers,
  required final List<ModelsDevModelValue> models,
}) {
  factory parse(
    Object? response, {
    Set<String> canonicalModelIds = const {},
    int? maxProviders,
    int? maxModels,
  }) {
    final catalog = _validatedCatalog(response, maxProviders);
    final providers = <ModelsDevProviderValue>[];
    final models = <ModelsDevModelValue>[];
    for (final entry in catalog.entries) {
      final parsed = _parseProvider(
        entry,
        canonicalModelIds,
        maxModels,
        models.length,
      );
      providers.add(parsed.provider);
      models.addAll(parsed.models);
    }
    if (models.isEmpty) {
      throw const FormatException('Catalog is empty.');
    }
    return ModelsDevCatalogValue(
      providers: .unmodifiable(providers),
      models: .unmodifiable(models),
    );
  }
}

Map<Object?, Object?> _validatedCatalog(Object? response, int? maxProviders) {
  if (response is! Map || response.isEmpty) {
    throw const FormatException('Expected non-empty catalog object.');
  }
  if (maxProviders != null && response.length > maxProviders) {
    throw const FormatException('Catalog exceeds provider limit.');
  }
  return response.cast<Object?, Object?>();
}

({ModelsDevProviderValue provider, List<ModelsDevModelValue> models})
_parseProvider(
  MapEntry<Object?, Object?> entry,
  Set<String> canonicalModelIds,
  int? maxModels,
  int existingModelCount,
) {
  final providerId = entry.key;
  if (providerId is! String || entry.value is! Map) {
    throw const FormatException('Invalid catalog provider.');
  }
  final json = _stringKeyedMap(entry.value);
  final id = _string(json, 'id');
  if (id != providerId) {
    throw const FormatException('Provider key does not match provider id.');
  }
  final rawModels = json['models'];
  if (rawModels is! Map) {
    throw const FormatException('Invalid provider models.');
  }
  if (maxModels != null && existingModelCount + rawModels.length > maxModels) {
    throw const FormatException('Catalog exceeds model limit.');
  }
  return (
    provider: ModelsDevProviderValue(
      id: id,
      name: _optionalString(json, 'name') ?? id,
      type: _optionalString(json, 'npm'),
      url: _optionalString(json, 'api'),
      documentationUrl: _optionalString(json, 'doc'),
    ),
    models: [
      for (final model in rawModels.entries)
        _parseModel(id, model, canonicalModelIds),
    ],
  );
}

ModelsDevModelValue _parseModel(
  String providerId,
  MapEntry<Object?, Object?> model,
  Set<String> canonicalModelIds,
) {
  final modelId = model.key;
  if (modelId is! String || model.value is! Map) {
    throw const FormatException('Invalid catalog model.');
  }
  final modelJson = _stringKeyedMap(model.value);
  final capabilities = ModelCapabilities.fromJson(
    providerId,
    _modelCapabilitiesJson(modelJson, modelId),
    canonicalModelIds,
  );
  if (capabilities.id != modelId) {
    throw const FormatException('Model key does not match model id.');
  }
  return ModelsDevModelValue(
    providerId: providerId,
    capabilities: capabilities,
  );
}

Map<String, dynamic> _modelCapabilitiesJson(
  Map<String, dynamic> modelJson,
  String modelId,
) => {
  ...modelJson,
  'name': modelJson['name'] ?? modelId,
  'limit':
      modelJson['limit'] ?? const <String, Object?>{'context': 0, 'output': 0},
  'modalities':
      modelJson['modalities'] ??
      const <String, Object?>{'input': <Object?>[], 'output': <Object?>[]},
};

class const ModelsDevProviderValue({
  required final String id,
  required final String name,
  final String? type,
  final String? url,
  final String? documentationUrl,
});

class const ModelsDevModelValue({
  required final String providerId,
  required final ModelCapabilities capabilities,
});

String _string(Map<String, dynamic> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) {
    throw FormatException('Missing $key.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
  }
  return value;
}

Map<String, dynamic> _stringKeyedMap(Object? value) {
  if (value is! Map || !value.keys.every((key) => key is String)) {
    throw const FormatException('Catalog object keys must be strings.');
  }
  return Map<String, dynamic>.from(value);
}
