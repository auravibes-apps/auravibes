import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/data/cloud_model_stores.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_model_selection_store.dart';
part 'model_store_providers.g.dart';

@riverpod
Future<ModelConnectionStore> modelConnectionStore(
  Ref ref,
  String workspaceId,
) async {
  final keepAlive = ref.keepAlive();
  return _connectionStore(ref, workspaceId).whenComplete(keepAlive.close);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<ModelSelectionStore> modelSelectionStore(
  Ref ref,
  String workspaceId,
) async {
  final keepAlive = ref.keepAlive();
  return _selectionStore(ref, workspaceId).whenComplete(keepAlive.close);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<ModelCatalogStore> modelCatalogStore(Ref ref, String workspaceId) async {
  final keepAlive = ref.keepAlive();
  return _catalogStore(ref, workspaceId).whenComplete(keepAlive.close);
}

Future<CloudWorkspaceStateGateway?> _cloudGateway(
  Ref ref,
  String workspaceId,
) => ref.watch(
  cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
);

Future<ModelConnectionStore> _connectionStore(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await _cloudGateway(ref, workspaceId);
  return gateway == null
      ? ref.watch(modelConnectionRepositoryProvider)
      : CloudModelStore(workspaceId, .new(.new(gateway)));
}

Future<ModelSelectionStore> _selectionStore(Ref ref, String workspaceId) async {
  final gateway = await _cloudGateway(ref, workspaceId);
  return gateway == null
      ? _LocalModelSelectionStore(
          ref.watch(workspaceModelSelectionRepositoryProvider),
        )
      : CloudModelStore(workspaceId, .new(.new(gateway)));
}

Future<ModelCatalogStore> _catalogStore(Ref ref, String workspaceId) async {
  final gateway = await _cloudGateway(ref, workspaceId);
  return gateway == null
      ? ref.watch(apiModelRepositoryProvider)
      : CloudModelCatalogStore(.new(gateway));
}

// Top-level API/provider declarations are required by their consumers.
