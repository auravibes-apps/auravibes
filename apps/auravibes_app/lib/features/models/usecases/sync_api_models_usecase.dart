import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/services/model_api_service.dart';

class const SyncApiModelsUseCase({
  required final ApiModelRepository repository,
  required final ModelApiService apiService,
}) {
  Future<void> call() async {
    final apiResponse = await apiService.fetchAllModels();
    _validateCatalog(apiResponse);

    final providers = apiResponse.providers;
    final models = providers.expand((provider) => provider.models).toList();
    await repository.replaceAllData(
      providers: providers.map((provider) => provider.modelProvider).toList(),
      models: models,
    );
  }
}

void _validateCatalog(ModelApiResponse apiResponse) {
  if (apiResponse.providers.isEmpty ||
      apiResponse.providers.every((provider) => provider.models.isEmpty)) {
    throw const FormatException(
      'Model catalog response contained no providers or models.',
    );
  }
}
