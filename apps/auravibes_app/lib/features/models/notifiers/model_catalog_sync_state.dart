import 'package:auravibes_app/features/models/notifiers/model_catalog_sync_failure.dart';

class const ModelCatalogSyncState({
  this.isSyncing = false,
  this.lastAttemptAt,
  this.lastSuccessfulSyncAt,
  this.failure,
}) {
  final bool isSyncing;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessfulSyncAt;
  final ModelCatalogSyncFailure? failure;

  ModelCatalogSyncState copyWith({
    bool? isSyncing,
    DateTime? lastAttemptAt,
    DateTime? lastSuccessfulSyncAt,
    ModelCatalogSyncFailure? failure,
    bool clearFailure = false,
  }) => ModelCatalogSyncState(
    isSyncing: isSyncing ?? this.isSyncing,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    lastSuccessfulSyncAt:
        lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
