import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'credentials_providers.g.dart';

@Riverpod(
  dependencies: [credentialsModelsRepository],
)
Future<CredentialsModelWithProviderEntity?> credentialsModelById(
  Ref ref,
  String credentialsModelId,
) async {
  return ref
      .watch(credentialsModelsRepositoryProvider)
      .getCredentialsModelById(credentialsModelId);
}

@Riverpod(
  dependencies: [credentialsModelById, getModelByProviderAndModelId],
)
Future<int?> modelContextLimit(Ref ref, String credentialsModelId) async {
  final selectedModel = await ref.watch(
    credentialsModelByIdProvider(credentialsModelId).future,
  );
  final modelId = selectedModel?.credentialsModel.modelId;
  final providerId = selectedModel?.modelsProvider.id;
  if (modelId == null || providerId == null) return null;

  final value = await ref.watch(
    getModelByProviderAndModelIdProvider(
      providerId: providerId,
      modelId: modelId,
    ).future,
  );
  return value?.limitContext;
}
