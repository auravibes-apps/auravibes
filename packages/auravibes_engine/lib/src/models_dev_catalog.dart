import 'package:auravibes_engine/src/model_capabilities.dart';

class ModelsDevCatalogValue {
  ModelsDevCatalogValue({required this.providers, required this.models});

  factory ModelsDevCatalogValue.parse(
    Object? response, {
    Set<String> canonicalModelIds = const {},
    int? maxProviders,
    int? maxModels,
  }) {
    if (response is! Map || response.isEmpty) {
      throw const FormatException('Expected non-empty catalog object.');
    }
    if (maxProviders != null && response.length > maxProviders) {
      throw const FormatException('Catalog exceeds provider limit.');
    }
    final providers = <ModelsDevProviderValue>[];
    final models = <ModelsDevModelValue>[];
    for (final entry in response.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid catalog provider.');
      }
      final json = _stringKeyedMap(entry.value);
      final id = _string(json, 'id');
      if (id != entry.key) {
        throw const FormatException('Provider key does not match provider id.');
      }
      final rawModels = json['models'];
      if (rawModels is! Map) {
        throw const FormatException('Invalid provider models.');
      }
      if (maxModels != null && models.length + rawModels.length > maxModels) {
        throw const FormatException('Catalog exceeds model limit.');
      }
      providers.add(
        ModelsDevProviderValue(
          id: id,
          name: _optionalString(json, 'name') ?? id,
          type: _optionalString(json, 'npm'),
          url: _optionalString(json, 'api'),
          documentationUrl: _optionalString(json, 'doc'),
        ),
      );
      for (final model in rawModels.entries) {
        if (model.key is! String || model.value is! Map) {
          throw const FormatException('Invalid catalog model.');
        }
        final modelJson = _stringKeyedMap(model.value);
        final capabilities = ModelCapabilities.fromJson(id, {
          ...modelJson,
          'name': modelJson['name'] ?? model.key,
          'limit':
              modelJson['limit'] ??
              const <String, Object?>{'context': 0, 'output': 0},
          'modalities':
              modelJson['modalities'] ??
              const <String, Object?>{
                'input': <Object?>[],
                'output': <Object?>[],
              },
        }, canonicalModelIds);
        if (capabilities.id != model.key) {
          throw const FormatException('Model key does not match model id.');
        }
        models.add(
          ModelsDevModelValue(providerId: id, capabilities: capabilities),
        );
      }
    }
    if (models.isEmpty) {
      throw const FormatException('Catalog is empty.');
    }
    return ModelsDevCatalogValue(
      providers: List.unmodifiable(providers),
      models: List.unmodifiable(models),
    );
  }

  final List<ModelsDevProviderValue> providers;
  final List<ModelsDevModelValue> models;
}

class ModelsDevProviderValue {
  const ModelsDevProviderValue({
    required this.id,
    required this.name,
    this.type,
    this.url,
    this.documentationUrl,
  });
  final String id;
  final String name;
  final String? type;
  final String? url;
  final String? documentationUrl;
}

class ModelsDevModelValue {
  const ModelsDevModelValue({
    required this.providerId,
    required this.capabilities,
  });
  final String providerId;
  final ModelCapabilities capabilities;
}

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
