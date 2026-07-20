import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../repositories/model_catalog_repository.dart';

typedef ModelsDevCatalogFetcher = Future<Object?> Function(Uri uri);

class ModelsDevCatalogSyncService {
  ModelsDevCatalogSyncService({
    ModelsDevCatalogFetcher? fetch,
    ModelCatalogRepository? repository,
  }) : _fetch = fetch ?? fetchModelsDevCatalog,
       _repository = repository ?? ModelCatalogRepository();

  static final uri = Uri.parse('https://models.dev/api.json');

  final ModelsDevCatalogFetcher _fetch;
  final ModelCatalogRepository _repository;

  Future<ModelsDevCatalog> load() async =>
      ModelsDevCatalog.parse(await _fetch(uri));

  Future<ModelsDevCatalog?> sync(
    Session session, {
    required bool Function() isActive,
    required WorkerCoordinatorLease coordinator,
  }) async {
    if (!isActive()) return null;
    final catalog = await load();
    if (!isActive()) return null;
    final applied = await _repository.replace(
      session,
      catalog: catalog,
      coordinator: coordinator,
    );
    return applied ? catalog : null;
  }
}

class ModelsDevCatalog {
  ModelsDevCatalog._(this.providers, this.models);

  static const maxProviders = 10000;
  static const maxModels = 100000;

  final List<ModelsDevProvider> providers;
  final List<ModelsDevModel> models;

  factory ModelsDevCatalog.parse(Object? response) {
    if (response is! Map) {
      throw const FormatException('Expected catalog object.');
    }
    if (response.length > maxProviders) {
      throw const FormatException('Too many catalog providers.');
    }
    final providers = <ModelsDevProvider>[];
    final models = <ModelsDevModel>[];
    for (final entry in response.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid catalog provider.');
      }
      final providerJson = Map<String, Object?>.from(entry.value as Map);
      final providerId = _requiredString(providerJson, 'id');
      if (providerId != entry.key) {
        throw const FormatException('Provider key does not match provider id.');
      }
      final providerModels = providerJson['models'];
      if (providerModels is! Map) {
        throw const FormatException('Invalid provider models.');
      }
      providers.add(
        ModelsDevProvider(
          id: providerId,
          name: _optionalString(providerJson, 'name') ?? providerId,
          type: _optionalString(providerJson, 'npm'),
          url: _optionalString(providerJson, 'api'),
          documentationUrl: _optionalString(providerJson, 'doc'),
        ),
      );
      for (final modelEntry in providerModels.entries) {
        if (models.length == maxModels ||
            modelEntry.key is! String ||
            modelEntry.value is! Map) {
          throw const FormatException('Invalid catalog model.');
        }
        final modelJson = Map<String, Object?>.from(modelEntry.value as Map);
        final modelId = _requiredString(modelJson, 'id');
        if (modelId != modelEntry.key) {
          throw const FormatException('Model key does not match model id.');
        }
        models.add(
          ModelsDevModel(
            providerId: providerId,
            id: modelId,
            name: _optionalString(modelJson, 'name') ?? modelId,
            limitContext: _nestedInt(modelJson, 'limit', 'context'),
            limitOutput: _nestedInt(modelJson, 'limit', 'output'),
            modalitiesInput: _nestedStrings(modelJson, 'modalities', 'input'),
            modalitiesOutput: _nestedStrings(
              modelJson,
              'modalities',
              'output',
            ),
            family: _optionalString(modelJson, 'family'),
            costInput: _nestedDouble(modelJson, 'cost', 'input'),
            costCacheRead: _nestedDouble(modelJson, 'cost', 'cache_read'),
            costOutput: _nestedDouble(modelJson, 'cost', 'output'),
            openWeights: _optionalBool(modelJson, 'open_weights') ?? false,
            supportsReasoning: _optionalBool(modelJson, 'reasoning') ?? false,
            supportsPriorityMode: _supportsPriorityMode(modelJson),
            supportsToolCalls: _optionalBool(modelJson, 'tool_call') ?? false,
          ),
        );
      }
    }
    if (providers.isEmpty || models.isEmpty) {
      throw const FormatException('Catalog is empty.');
    }
    return ModelsDevCatalog._(
      List.unmodifiable(providers),
      List.unmodifiable(models),
    );
  }
}

class ModelsDevProvider {
  const ModelsDevProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.documentationUrl,
  });

  final String id;
  final String name;
  final String? type;
  final String? url;
  final String? documentationUrl;
}

class ModelsDevModel {
  const ModelsDevModel({
    required this.providerId,
    required this.id,
    required this.name,
    required this.limitContext,
    required this.limitOutput,
    required this.modalitiesInput,
    required this.modalitiesOutput,
    required this.family,
    required this.costInput,
    required this.costCacheRead,
    required this.costOutput,
    required this.openWeights,
    required this.supportsReasoning,
    required this.supportsPriorityMode,
    required this.supportsToolCalls,
  });

  final String providerId;
  final String id;
  final String name;
  final int limitContext;
  final int limitOutput;
  final List<String> modalitiesInput;
  final List<String> modalitiesOutput;
  final String? family;
  final double costInput;
  final double costCacheRead;
  final double costOutput;
  final bool openWeights;
  final bool supportsReasoning;
  final bool supportsPriorityMode;
  final bool supportsToolCalls;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) throw FormatException('Missing $key.');
  return value;
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
  }
  return value;
}

int _nestedInt(Map<String, Object?> json, String parent, String key) {
  final value = _nestedValue(json, parent, key);
  if (value == null) return 0;
  if (value is! int || value < 0) {
    throw FormatException('Invalid $parent.$key.');
  }
  return value;
}

double _nestedDouble(Map<String, Object?> json, String parent, String key) {
  final value = _nestedValue(json, parent, key);
  if (value == null) return 0;
  if (value is! num || !value.isFinite || value < 0) {
    throw FormatException('Invalid $parent.$key.');
  }
  return value.toDouble();
}

List<String> _nestedStrings(
  Map<String, Object?> json,
  String parent,
  String key,
) {
  final value = _nestedValue(json, parent, key);
  if (value == null) return const [];
  if (value is! List || value.any((item) => item is! String || item.isEmpty)) {
    throw FormatException('Invalid $parent.$key.');
  }
  return List.unmodifiable(value.cast<String>());
}

Object? _nestedValue(Map<String, Object?> json, String parent, String key) {
  final value = json[parent];
  if (value == null) return null;
  if (value is! Map) throw FormatException('Invalid $parent.');
  return value[key];
}

bool? _optionalBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! bool) throw FormatException('Invalid $key.');
  return value;
}

bool _supportsPriorityMode(Map<String, Object?> json) {
  final experimental = _optionalMap(json, 'experimental');
  final modes = experimental == null
      ? null
      : _optionalMap(experimental, 'modes');
  final fast = modes == null ? null : _optionalMap(modes, 'fast');
  final provider = fast == null ? null : _optionalMap(fast, 'provider');
  final body = provider == null ? null : _optionalMap(provider, 'body');
  final serviceTier = body?['service_tier'];
  if (serviceTier == null) return false;
  if (serviceTier is! String) {
    throw const FormatException(
      'Invalid experimental.modes.fast.provider.body.service_tier.',
    );
  }
  return serviceTier == 'priority';
}

Map<String, Object?>? _optionalMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! Map || !value.keys.every((item) => item is String)) {
    throw FormatException('Invalid $key.');
  }
  return Map<String, Object?>.from(value);
}

Future<Object?> fetchModelsDevCatalog(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 15));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.isRedirect ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw HttpException(
        'models.dev returned ${response.statusCode}.',
        uri: uri,
      );
    }
    final bytes = await response
        .fold<BytesBuilder>(
          BytesBuilder(copy: false),
          (buffer, chunk) {
            if (buffer.length + chunk.length > 20 * 1024 * 1024) {
              throw const FormatException(
                'models.dev response exceeds 20 MiB.',
              );
            }
            buffer.add(chunk);
            return buffer;
          },
        )
        .timeout(const Duration(seconds: 15));
    return jsonDecode(utf8.decode(bytes.takeBytes()));
  } finally {
    client.close(force: true);
  }
}
