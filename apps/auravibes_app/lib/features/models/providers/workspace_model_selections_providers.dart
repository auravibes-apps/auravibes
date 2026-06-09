// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_model_selections_providers.g.dart';

@riverpod
Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
listWorkspaceModelSelections(
  Ref ref, {
  required String workspaceId,
}) {
  final workspaceModelSelectionRepository = ref.watch(
    workspaceModelSelectionRepositoryProvider,
  );

  return workspaceModelSelectionRepository.watchWorkspaceModelSelections(
    WorkspaceModelSelectionFilter(workspaces: [workspaceId]),
  );
}

/// Groups models by connection id for two-step model selection.
/// Returns a map where keys are credential-backed connection ids.
@riverpod
Stream<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>
listModelsGroupedByProvider(Ref ref, {required String workspaceId}) {
  final controller =
      StreamController<
        Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
      >();
  final subscription = ref.listen(
    listWorkspaceModelSelectionsProvider(workspaceId: workspaceId),
    (_, next) {
      switch (next) {
        case AsyncData(:final value):
          controller.add(_groupModelsByProvider(value));
        case AsyncError(:final error, :final stackTrace):
          controller.addError(error, stackTrace);
        case AsyncLoading():
      }
    },
    fireImmediately: true,
  );

  final _ = ref.onDispose(() {
    subscription.close();
    unawaited(controller.close());
  });

  return controller.stream;
}

Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
_groupModelsByProvider(
  List<WorkspaceModelSelectionWithConnectionEntity> models,
) {
  final grouped = <String, List<WorkspaceModelSelectionWithConnectionEntity>>{};

  for (final model in models) {
    final connectionId = model.modelConnection.id;
    grouped.putIfAbsent(connectionId, () => []).add(model);
  }

  final sortedKeys = grouped.keys.toList()
    ..sort((left, right) => _compareProviderGroups(grouped, left, right));

  return {for (final key in sortedKeys) key: grouped[key]!};
}

int _compareProviderGroups(
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> grouped,
  String left,
  String right,
) {
  final leftModel = grouped[left]!.first;
  final rightModel = grouped[right]!.first;
  final providerCompare = leftModel.modelsProvider.name.compareTo(
    rightModel.modelsProvider.name,
  );
  if (providerCompare != 0) return providerCompare;

  final credentialCompare = leftModel.modelConnection.name.compareTo(
    rightModel.modelConnection.name,
  );
  if (credentialCompare != 0) return credentialCompare;

  return left.compareTo(right);
}
