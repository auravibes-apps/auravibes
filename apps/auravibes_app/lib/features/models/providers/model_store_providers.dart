import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/data/cloud_model_stores.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/models/usecases/cloud_model_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_model_selection_store.dart';
part 'model_store_providers.g.dart';

@riverpod
Future<ModelConnectionStore> modelConnectionStore(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );
  if (gateway == null) return ref.watch(modelConnectionRepositoryProvider);

  return CloudModelStore(
    workspaceId,
    CloudModelConnectionUsecases(CloudModelGateway(gateway)),
  );
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<ModelSelectionStore> modelSelectionStore(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );
  if (gateway == null) {
    return _LocalModelSelectionStore(
      ref.watch(workspaceModelSelectionRepositoryProvider),
    );
  }

  return CloudModelStore(
    workspaceId,
    CloudModelConnectionUsecases(CloudModelGateway(gateway)),
  );
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<ModelCatalogStore> modelCatalogStore(Ref ref, String workspaceId) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );
  if (gateway == null) return ref.watch(apiModelRepositoryProvider);

  return CloudModelCatalogStore(CloudModelGateway(gateway));
}

// Top-level API/provider declarations are required by their consumers.
