import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_session_provider.g.dart';

sealed class WorkspaceAvailability {
  const WorkspaceAvailability(this.session);

  final WorkspaceSession session;
}

final class WorkspaceAvailable extends WorkspaceAvailability {
  const WorkspaceAvailable(super.session);
}

final class WorkspaceAuthenticationRequired extends WorkspaceAvailability {
  const WorkspaceAuthenticationRequired(super.session);
}

@Riverpod(keepAlive: true, dependencies: [])
WorkspaceSession workspaceSession(Ref _) {
  throw StateError(
    'WorkspaceSession must be overridden at the workspace route',
  );
}

@riverpod
Future<WorkspaceSession> workspaceSessionForRoute(
  Ref ref,
  String localWorkspaceId,
) async {
  final _ = ref.watch(allWorkspacesProvider);
  final workspaces = await ref.read(allWorkspacesProvider.future);
  final mirror = workspaces
      .where((item) => item.id == localWorkspaceId)
      .firstOrNull;
  if (mirror == null) {
    throw StateError('Workspace $localWorkspaceId not found');
  }

  final serverUrl = mirror.url;
  final accountId = mirror.cloudAccountId;
  final cloudWorkspaceId = int.tryParse(mirror.cloudWorkspaceId ?? '');
  if (mirror.type != WorkspaceType.remote) {
    return WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: localWorkspaceId),
    );
  }
  if (serverUrl == null ||
      accountId == null ||
      accountId.isEmpty ||
      cloudWorkspaceId == null) {
    throw StateError('Remote workspace $localWorkspaceId has invalid metadata');
  }

  return WorkspaceSession(
    CloudWorkspaceRef(
      localWorkspaceId: localWorkspaceId,
      serverUrl: canonicalServerOrigin(serverUrl),
      accountId: accountId,
      cloudWorkspaceId: cloudWorkspaceId,
    ),
  );
}

@riverpod
Future<WorkspaceAvailability> workspaceAvailability(
  Ref ref,
  String localWorkspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(localWorkspaceId).future,
  );
  final cloud = session.cloud;
  if (cloud == null) return WorkspaceAvailable(session);

  final client = await ref.watch(
    serverpodClientForWorkspaceProvider((
      serverUrl: cloud.serverUrl,
      accountId: cloud.accountId,
    )).future,
  );
  try {
    final _ = await client.account.currentUser();
  } on CloudWorkspaceException catch (error) {
    if (error.code == CloudWorkspaceErrorCode.authenticationRequired) {
      return WorkspaceAuthenticationRequired(session);
    }

    rethrow;
  }

  return WorkspaceAvailable(session);
}

@Riverpod(dependencies: [workspaceSession])
Future<CloudWorkspaceStateGateway?> cloudWorkspaceStateGateway(Ref ref) async {
  final cloud = ref.watch(workspaceSessionProvider).cloud;
  if (cloud == null) return null;

  final client = await ref.watch(
    serverpodClientForWorkspaceProvider((
      serverUrl: cloud.serverUrl,
      accountId: cloud.accountId,
    )).future,
  );

  return CloudWorkspaceStateGateway(client: client, workspace: cloud);
}

@riverpod
Future<CloudWorkspaceStateGateway?> cloudWorkspaceStateGatewayForWorkspace(
  Ref ref,
  String localWorkspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(localWorkspaceId).future,
  );
  final cloud = session.cloud;
  if (cloud == null) return null;

  final client = await ref.watch(
    serverpodClientForWorkspaceProvider((
      serverUrl: cloud.serverUrl,
      accountId: cloud.accountId,
    )).future,
  );

  return CloudWorkspaceStateGateway(client: client, workspace: cloud);
}

@Dependencies([cloudWorkspaceStateGateway])
@riverpod
Stream<List<WorkspaceResource>> cloudWorkspaceConfiguration(Ref ref) async* {
  final gateway = await ref.watch(cloudWorkspaceStateGatewayProvider.future);
  if (gateway == null) {
    yield const [];

    return;
  }
  yield* gateway.watchResources(const [
    WorkspaceResourceKind.compactionSetting,
    WorkspaceResourceKind.workspaceSetting,
  ]);
}
