import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_engine/auravibes_engine.dart';
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

  Future<ModelsDevCatalog> load() async => ModelsDevCatalog.fromEngine(
    ModelsDevCatalogValue.parse(
      await _fetch(uri),
      maxProviders: ModelsDevCatalog.maxProviders,
      maxModels: ModelsDevCatalog.maxModels,
    ),
  );

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

class ModelsDevCatalog._(
  final List<ModelsDevProvider> providers,
  final List<ModelsDevModel> models,
) {
  static const maxProviders = 10000;
  static const maxModels = 100000;

  factory fromEngine(ModelsDevCatalogValue catalog) {
    if (catalog.providers.length > maxProviders ||
        catalog.models.length > maxModels) {
      throw const FormatException('Catalog exceeds limits.');
    }
    return ModelsDevCatalog._(
      List.unmodifiable([
        for (final provider in catalog.providers)
          ModelsDevProvider(
            id: provider.id,
            name: provider.name,
            type: provider.type,
            url: provider.url,
            documentationUrl: provider.documentationUrl,
          ),
      ]),
      List.unmodifiable([
        for (final model in catalog.models)
          ModelsDevModel(
            providerId: model.providerId,
            id: model.capabilities.id,
            name: model.capabilities.name,
            limitContext: model.capabilities.limitContext,
            limitOutput: model.capabilities.limitOutput,
            modalitiesInput: model.capabilities.inputModalities,
            modalitiesOutput: model.capabilities.outputModalities,
            family: model.capabilities.family,
            costInput: model.capabilities.costInput ?? 0,
            costCacheRead: model.capabilities.costCacheRead ?? 0,
            costOutput: model.capabilities.costOutput ?? 0,
            openWeights: model.capabilities.openWeights ?? false,
            supportsReasoning: model.capabilities.supportsReasoning,
            supportsPriorityMode: model.capabilities.supportsPriorityMode,
            supportsToolCalls: model.capabilities.supportsToolCalls,
          ),
      ]),
    );
  }

  factory parse(Object? response) =>
      ModelsDevCatalog.fromEngine(ModelsDevCatalogValue.parse(response));
}

class const ModelsDevProvider({
  required final String id,
  required final String name,
  required final String? type,
  required final String? url,
  required final String? documentationUrl,
});

class const ModelsDevModel({
  required final String providerId,
  required final String id,
  required final String name,
  required final int limitContext,
  required final int limitOutput,
  required final List<String> modalitiesInput,
  required final List<String> modalitiesOutput,
  required final String? family,
  required final double costInput,
  required final double costCacheRead,
  required final double costOutput,
  required final bool openWeights,
  required final bool supportsReasoning,
  required final bool supportsPriorityMode,
  required final bool supportsToolCalls,
});

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
