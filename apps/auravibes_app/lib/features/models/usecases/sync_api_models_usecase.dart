import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:collection/collection.dart';

class const SyncApiModelsUseCase({
  required final ApiModelRepository repository,
  required final ModelApiService apiService,
}) {
  Future<void> call() async {
    final apiResponse = await apiService.fetchAllModels();

    final apiProviderEntities = apiResponse.providers
        .map((e) => e.modelProvider)
        .toList();
    final apiModelEntities = apiResponse.providers
        .map((e) => e.models)
        .flattenedToList;

    await repository.replaceAllData(
      providers: apiProviderEntities,
      models: apiModelEntities,
    );
  }
}
