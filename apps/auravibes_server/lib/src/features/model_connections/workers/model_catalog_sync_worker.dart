import 'package:serverpod/serverpod.dart';

import '../services/models_dev_catalog_sync_service.dart';

class ModelCatalogSyncWorker {
  const ModelCatalogSyncWorker();

  static const interval = Duration(hours: 12);
  Future<void> run(Session session) async {
    final catalog = await ModelsDevCatalogSyncService().sync(session);
    session.log(
      'models.dev catalog synced ${catalog.providers.length} providers and '
      '${catalog.models.length} models.',
    );
  }
}

class ModelCatalogSyncWorkerFutureCall extends FutureCall {
  @override
  Future<void> invoke(Session session, SerializableModel? object) =>
      poll(session);

  Future<void> poll(Session session) async {
    try {
      await const ModelCatalogSyncWorker().run(session);
    } on Object catch (error, stackTrace) {
      session.log(
        'models.dev catalog sync failed.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    } finally {
      // ignore: deprecated_member_use
      await session.serverpod.futureCallWithDelay(
        modelCatalogSyncWorkerFutureCallName,
        null,
        ModelCatalogSyncWorker.interval,
        identifier: modelCatalogSyncWorkerFutureCallIdentifier,
      );
    }
  }
}

const modelCatalogSyncWorkerFutureCallName = 'modelCatalogSyncWorker';
const modelCatalogSyncWorkerFutureCallIdentifier =
    'modelCatalogSyncWorker.poll';
