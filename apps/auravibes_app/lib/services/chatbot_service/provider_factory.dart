import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:genkit/genkit.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_openai/genkit_openai.dart';

class ProviderFactory {
  const ProviderFactory({
    required this.encryptionService,
  });

  final EncryptionService encryptionService;

  Future<Genkit> createGenkit(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) async {
    final encrypted = config.modelConnection.key;
    final apiKey = await encryptionService.decrypt(encrypted);
    final type = config.modelsProvider.type;
    final baseUrl = config.modelConnection.url ?? config.modelsProvider.url;

    return Genkit(
      plugins: [
        if (type == ModelProvidersType.anthropic && baseUrl == null)
          anthropic(apiKey: apiKey)
        else
          openAI(
            apiKey: apiKey,
            baseUrl: baseUrl,
          ),
      ],
    );
  }

  ModelRef<dynamic> getModelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final type = config.modelsProvider.type;
    final modelId = config.workspaceModelSelection.modelId;
    final baseUrl = config.modelConnection.url ?? config.modelsProvider.url;

    final provider = (type == ModelProvidersType.anthropic && baseUrl == null)
        ? 'anthropic'
        : 'openai';

    return modelRef<dynamic>('$provider/$modelId');
  }
}
