import 'package:auravibes_app/features/service_connections/usecases/cloud_service_connection_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_service_connection_usecases_provider.g.dart';

@riverpod
Future<CloudServiceConnectionUsecases?> cloudServiceConnectionUsecases(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );

  return gateway == null
      ? null
      : CloudServiceConnectionUsecases(CloudWorkspaceResourceStore(gateway));
}
