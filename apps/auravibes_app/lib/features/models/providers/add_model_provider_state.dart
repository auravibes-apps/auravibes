// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_model_provider_state.g.dart';

final _log = Logger('add_model_providers');

@riverpod
class AddModelProviderState extends _$AddModelProviderState {
  String _workspaceId = '';

  @override
  AddModelProviderModel build(String workspaceId) {
    _workspaceId = workspaceId;
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
    final models = ref.watch(apiModelProvidersProvider).value;
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

  Future<ModelConnectionEntity?> addModelProvider() async {
    if (!state.isValid()) {
      return null;
    }

    try {
      final repo = ref.read(modelConnectionRepositoryProvider);

      return await repo.createModelConnection(
        ModelConnectionToCreate(
          name: state.name!,
          key: state.key!,
          workspaceId: _workspaceId,
          modelId: state.modelId!,
          url: state.url,
        ),
      );
    } on Exception catch (e, s) {
      _log.severe('addModelProvider error', e, s);
      rethrow;
    }
  }
}

final addCredentialsModelMutationProvider = Mutation<void>();
