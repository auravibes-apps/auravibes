// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

export 'popular_api_providers.dart';

part 'api_model_providers_dao.g.dart';

int _sortProviders(ApiModelProvidersTable a, ApiModelProvidersTable b) {
  final aIndex = _popularProviderIndex(a);
  final bIndex = _popularProviderIndex(b);
  if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
  if (aIndex >= 0) return -1;
  if (bIndex >= 0) return 1;

  return a.name.compareTo(b.name);
}

int _popularProviderIndex(ApiModelProvidersTable provider) =>
    PopularApiProviders.values.indexOf(provider.id);

/// Data Access Object for API model providers operations.
@DriftAccessor(tables: [ApiModelProviders])
class ApiModelProvidersDao extends DatabaseAccessor<AppDatabase>
    with _$ApiModelProvidersDaoMixin, _ApiModelProvidersDaoApi {
  new(super.attachedDatabase);

  /// Retrieves a provider by its ID.
  ///
  /// Returns the provider with the given [id], or null if not found.
  Future<ApiModelProvidersTable?> getProviderById(String id) {
    return (select(
      apiModelProviders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}

mixin _ApiModelProvidersDaoApi {
  Future<List<ApiModelProvidersTable>> getAllProviders() =>
      ApiModelProvidersDaoReadOperations(this as ApiModelProvidersDao)
          .getAllProviders();

  Stream<List<ApiModelProvidersTable>> watchAllProviders() =>
      ApiModelProvidersDaoReadOperations(this as ApiModelProvidersDao)
          .watchAllProviders();

  Future<List<ApiModelProvidersTable>> getProvidersByType(String type) =>
      ApiModelProvidersDaoReadOperations(this as ApiModelProvidersDao)
          .getProvidersByType(type);

  Future<ApiModelProvidersTable> upsertProvider(
    ApiModelProvidersCompanion provider,
  ) =>
      ApiModelProvidersDaoReadOperations(this as ApiModelProvidersDao)
          .upsertProvider(provider);

  Future<bool> deleteProvider(String id) =>
      ApiModelProvidersDaoReadOperations(this as ApiModelProvidersDao)
          .deleteProvider(id);

  Future<bool> providerExists(String id) =>
      ApiModelProvidersDaoReadOperations(this as ApiModelProvidersDao)
          .providerExists(id);

  Future<List<ApiModelProvidersTable>> searchProvidersByName(String query) =>
      ApiModelProvidersDaoReadOperations(this as ApiModelProvidersDao)
          .searchProvidersByName(query);

  Future<int> getProviderCount() =>
      ApiModelProvidersDaoWriteOperations(this as ApiModelProvidersDao)
          .getProviderCount();

  Future<List<ApiModelProvidersTable>> batchUpsertProviders(
    List<ApiModelProvidersCompanion> providers,
  ) =>
      ApiModelProvidersDaoWriteOperations(this as ApiModelProvidersDao)
          .batchUpsertProviders(providers);

  Future<int> deleteAllProviders() =>
      ApiModelProvidersDaoWriteOperations(this as ApiModelProvidersDao)
          .deleteAllProviders();
}

extension ApiModelProvidersDaoReadOperations on ApiModelProvidersDao {
  /// Retrieves all API model providers from the database.
  ///
  /// Returns a list of all providers ordered by popularity first, then by name.
  Future<List<ApiModelProvidersTable>> getAllProviders() async {
    final allProviders = await select(apiModelProviders).get();

    // Sort providers: popular ones first in defined order, then alphabetically.
    return allProviders.sorted(_sortProviders);
  }

  Stream<List<ApiModelProvidersTable>> watchAllProviders() {
    return select(apiModelProviders)
        .watch()
        .map((providers) => providers.sorted(_sortProviders));
  }

  /// Retrieves providers by their type.
  ///
  /// Returns a list of providers with the specified [type].
  Future<List<ApiModelProvidersTable>> getProvidersByType(String type) {
    return (select(apiModelProviders)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  /// Inserts a new provider into the database.
  ///
  /// Returns the inserted provider.
  Future<ApiModelProvidersTable> upsertProvider(
    ApiModelProvidersCompanion provider,
  ) {
    return into(apiModelProviders).insertReturning(
      provider,
      onConflict: DoUpdate((_) => provider, target: [apiModelProviders.id]),
    );
  }

  /// Deletes a provider from the database.
  ///
  /// Deletes the provider with the given [id].
  /// Returns true if a provider was deleted, false otherwise.
  Future<bool> deleteProvider(String id) async {
    final deleteCount = await (delete(
      apiModelProviders,
    )..where((t) => t.id.equals(id))).go();

    return deleteCount > 0;
  }

  /// Checks if a provider with the given [id] exists.
  ///
  /// Returns true if the provider exists, false otherwise.
  Future<bool> providerExists(String id) async {
    final rows =
        await (selectOnly(apiModelProviders)
              ..addColumns([apiModelProviders.id])
              ..where(apiModelProviders.id.equals(id)))
            .get();

    return rows.isNotEmpty;
  }

  /// Searches for providers by name.
  ///
  /// Returns a list of providers whose names contain the [query] string.
  /// The search is case-insensitive.
  Future<List<ApiModelProvidersTable>> searchProvidersByName(String query) {
    return (select(apiModelProviders)
          ..where((t) => t.name.contains(query))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }
}

extension ApiModelProvidersDaoWriteOperations on ApiModelProvidersDao {
  /// Gets the count of all providers.
  ///
  /// Returns the total number of providers in the database.
  Future<int> getProviderCount() async {
    final rows = await (selectOnly(
      apiModelProviders,
    )..addColumns([apiModelProviders.id])).get();

    return rows.length;
  }

  /// Batch inserts multiple providers into the database.
  ///
  /// Returns the list of inserted providers.
  Future<List<ApiModelProvidersTable>> batchUpsertProviders(
    List<ApiModelProvidersCompanion> providers,
  ) {
    return transaction(() async {
      return [for (final provider in providers) await upsertProvider(provider)];
    });
  }

  /// Deletes all providers from the database.
  ///
  /// Returns the number of deleted providers.
  Future<int> deleteAllProviders() {
    return delete(apiModelProviders).go();
  }
}
