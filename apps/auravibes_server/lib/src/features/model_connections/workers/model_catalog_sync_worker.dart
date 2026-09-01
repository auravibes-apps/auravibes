import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/models_dev_catalog_sync_service.dart';

class const ModelCatalogSyncWorker() {
  static const interval = Duration(hours: 12);
  Future<void> run(
    Session session, {
    required bool Function() isActive,
    required WorkerCoordinatorLease coordinator,
  }) async {
    final catalog = await ModelsDevCatalogSyncService().sync(
      session,
      isActive: isActive,
      coordinator: coordinator,
    );
    if (catalog == null || !isActive()) return;
    session.log(
      'models.dev catalog synced ${catalog.providers.length} providers and '
      '${catalog.models.length} models.',
    );
  }
}

Future<void> runModelCatalogSyncWorker(
  Session session, {
  required bool Function() isActive,
  required WorkerCoordinatorLease coordinator,
}) async {
  if (!isActive()) return;
  try {
    await const ModelCatalogSyncWorker().run(
      session,
      isActive: isActive,
      coordinator: coordinator,
    );
  } on Object catch (error, stackTrace) {
    session.log(
      'models.dev catalog sync failed.',
      level: LogLevel.warning,
      exception: error,
      stackTrace: stackTrace,
    );
  }
}
