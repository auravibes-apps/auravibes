import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'credentials_providers.g.dart';

@Riverpod(
  dependencies: [
    credentialsModelsRepository,
  ],
)
Future<int?> modelContextLimit(Ref ref, String credentialsModelId) async {
  final selectedModel = await ref
      .watch(credentialsModelsRepositoryProvider)
      .getCredentialsModelById(credentialsModelId);
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
