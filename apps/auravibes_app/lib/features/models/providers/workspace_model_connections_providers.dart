import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_model_connections_providers.g.dart';

@riverpod
Future<List<ModelConnectionEntity>> listWorkspaceModelConnections(
  Ref ref, {
  required String workspaceId,
}) async {
  final modelConnectionRepository = ref.watch(
    modelConnectionRepositoryProvider,
  );

  return modelConnectionRepository.getModelConnections(
    ModelConnectionFilter(workspaces: [workspaceId]),
  );
}
