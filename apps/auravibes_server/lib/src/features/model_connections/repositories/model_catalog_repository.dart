import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/models_dev_catalog_sync_service.dart';

class ModelCatalogRepository {
  Future<void> replace(
    Session session, {
    required ModelsDevCatalog catalog,
  }) => session.db.transaction((transaction) async {
    final now = DateTime.now().toUtc();
    final providers = await ApiModelProvider.db.find(
      session,
      transaction: transaction,
    );
    final models = await ApiModel.db.find(session, transaction: transaction);
    final providersById = {
      for (final provider in providers) provider.providerId: provider,
    };
    final modelsByIdentity = {
      for (final model in models) (model.providerId, model.modelId): model,
    };

    for (final provider in catalog.providers) {
      final existing = providersById[provider.id];
      final row = ApiModelProvider(
        id: existing?.id,
        providerId: provider.id,
        name: provider.name,
        type: provider.type,
        url: provider.url,
        documentationUrl: provider.documentationUrl,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      if (existing == null) {
        await ApiModelProvider.db.insertRow(
          session,
          row,
          transaction: transaction,
        );
      } else {
        await ApiModelProvider.db.updateRow(
          session,
          row,
          transaction: transaction,
        );
      }
    }

    for (final model in catalog.models) {
      final existing = modelsByIdentity[(model.providerId, model.id)];
      final row = ApiModel(
        id: existing?.id,
        providerId: model.providerId,
        modelId: model.id,
        name: model.name,
        limitContext: model.limitContext,
        limitOutput: model.limitOutput,
        modalitiesInput: model.modalitiesInput,
        modalitiesOutput: model.modalitiesOutput,
        family: model.family,
        costInput: model.costInput,
        costCacheRead: model.costCacheRead,
        costOutput: model.costOutput,
        openWeights: model.openWeights,
        supportsReasoning: model.supportsReasoning,
        isCanonical: true,
        supportsPriorityMode: model.supportsPriorityMode,
        supportsToolCalls: model.supportsToolCalls,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      if (existing == null) {
        await ApiModel.db.insertRow(session, row, transaction: transaction);
      } else {
        await ApiModel.db.updateRow(session, row, transaction: transaction);
      }
    }

    final catalogModelIdentities = {
      for (final model in catalog.models) (model.providerId, model.id),
    };
    for (final model in models) {
      if (catalogModelIdentities.contains((model.providerId, model.modelId))) {
        continue;
      }
      await ApiModel.db.deleteRow(session, model, transaction: transaction);
    }

    final catalogProviderIds = {
      for (final provider in catalog.providers) provider.id,
    };
    for (final provider in providers) {
      if (catalogProviderIds.contains(provider.providerId)) {
        continue;
      }
      await ApiModelProvider.db.deleteRow(
        session,
        provider,
        transaction: transaction,
      );
    }
  });

  Future<List<ApiModelProvider>> listProviders(Session session) =>
      ApiModelProvider.db.find(
        session,
        orderBy: (table) => table.name,
      );

  Future<List<ApiModel>> listModels(
    Session session, {
    String? providerId,
  }) => ApiModel.db.find(
    session,
    where: providerId == null
        ? null
        : (table) => table.providerId.equals(providerId),
    orderByList: (table) => [table.providerId, table.name, table.modelId],
  );
}
