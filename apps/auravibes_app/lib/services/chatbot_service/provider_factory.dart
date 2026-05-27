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
    final connectionUrl = config.modelConnection.url;
    final baseUrl = connectionUrl ?? config.modelsProvider.url;
    final shouldUseAnthropic = _shouldUseAnthropic(type, connectionUrl);

    return Genkit(
      plugins: [
        if (shouldUseAnthropic)
          anthropic(apiKey: apiKey, baseUrl: baseUrl)
        else
          openAI(
            apiKey: apiKey,
            baseUrl: baseUrl,
          ),
      ],
    );
  }

  ModelRef<Object?> getModelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    final type = config.modelsProvider.type;
    final modelId = config.workspaceModelSelection.modelId;
    final connectionUrl = config.modelConnection.url;

    final provider = _shouldUseAnthropic(type, connectionUrl)
        ? 'anthropic'
        : 'openai';

    return modelRef<Object?>('$provider/$modelId');
  }

  bool _shouldUseAnthropic(ModelProvidersType? type, String? connectionUrl) {
    return type == ModelProvidersType.anthropic && connectionUrl == null;
  }
}
