import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_service_connection_usecases_provider.g.dart';

@riverpod
Future<CloudServiceConnectionUsecases?> cloudServiceConnectionUsecases(
  Ref ref,
  String workspaceId,
) async {
  final store = await cloudWorkspaceResourceStoreForWorkspace(ref, workspaceId);

  return store == null ? null : CloudServiceConnectionUsecases(store);
}
