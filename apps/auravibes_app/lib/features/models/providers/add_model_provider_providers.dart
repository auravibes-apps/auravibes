import 'package:auravibes_app/domain/entities/credentials_entities.dart';
import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_model_provider_providers.g.dart';

sealed class AddModelException implements Exception {}

class AddModelExceptionNoWorkspace implements AddModelException {}

class AddModelExceptionNoUnkown implements AddModelException {}

final _log = Logger('add_model_providers');

@riverpod
class AddModelProviderState extends _$AddModelProviderState {
  @override
  AddModelProviderModel build() {
    return const AddModelProviderModel();
  }

  void setName(String newName) {
    state = state.copyWith(
      name: newName,
    );
  }

  void setKey(String newKey) {
    state = state.copyWith(
      key: newKey,
    );
  }

  void setModel(String? newValue) {
    final models = ref.watch(modelProvidersProvider).value;
    final model = models?.firstWhereOrNull(
      (element) {
        return element.id == newValue;
      },
    );
    state = state.copyWith(
      modelId: newValue,
      name: model?.name,
    );
  }

  void setUrl(String? newUrl) {
    state = state.copyWith(
      url: newUrl,
    );
  }

  Future<CredentialsEntity?> addModelProvider() async {
    if (!state.isValid()) {
      return null;
    }

    try {
      final repo = ref.read(modelProvidersRepositoryProvider);
      final wRepo = ref.read(workspaceRepositoryProvider);

      final workspaces = await wRepo.getAllWorkspaces();
      final firstWorkspace = workspaces.firstOrNull;
      if (firstWorkspace == null) {
        throw AddModelExceptionNoWorkspace();
      }

      final provider = await repo.createCredential(
        CredentialsToCreate(
          name: state.name!,
          modelId: state.modelId!,
          key: state.key!,
          url: state.url,
          workspaceId: firstWorkspace.id,
        ),
      );
      return provider;
    } on AddModelException catch (e) {
      _log.severe('addModelProvider known error', e);
      rethrow;
    } on Exception catch (e, s) {
      _log.severe('addModelProvider error', e, s);
      throw AddModelExceptionNoUnkown();
    }
  }
}

final addCredentialsModelMutationProvider = Mutation<void>();
