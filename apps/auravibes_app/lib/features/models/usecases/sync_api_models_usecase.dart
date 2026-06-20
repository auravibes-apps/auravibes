import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:collection/collection.dart';

class SyncApiModelsUseCase {
  const SyncApiModelsUseCase({
    required this.repository,
    required this.apiService,
  });

  final ApiModelRepository repository;
  final ModelApiService apiService;

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
