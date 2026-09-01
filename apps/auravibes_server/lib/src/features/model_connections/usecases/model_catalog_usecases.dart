import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../repositories/model_catalog_repository.dart';

class ModelCatalogUseCases(final ModelCatalogRepository _repository) {
  Future<List<ApiModelProvider>> listProviders(Session session) =>
      _repository.listProviders(session);

  Future<List<ApiModel>> listModels(
    Session session, {
    String? providerId,
  }) {
    final normalizedProviderId = providerId?.trim();
    return _repository.listModels(
      session,
      providerId: normalizedProviderId?.isEmpty ?? true
          ? null
          : normalizedProviderId,
    );
  }
}
