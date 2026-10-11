import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_route_failure.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_availability.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'workspace_availability.dart';

part 'workspace_session_provider.g.dart';

@riverpod
WorkspaceSession workspaceSession(Ref _, WorkspaceSession session) => session;

@Riverpod(retry: _routeSessionRetry)
// ignore: prefer-static-class (required framework top-level declaration)
Future<WorkspaceSession> workspaceSessionForRoute(
  Ref ref,
  String localWorkspaceId,
) async {
  final _ = ref.watch(allWorkspacesProvider);
  final workspaces = await ref.read(allWorkspacesProvider.future);

  return _workspaceSessionForMirror(
    localWorkspaceId,
    _findWorkspace(workspaces, localWorkspaceId),
  );
}

Duration? _routeSessionRetry(int retryCount, Object error) {
  if (error is WorkspaceRouteFailure) return null;

  return ProviderContainer.defaultRetry(retryCount, error);
}

WorkspaceEntity _findWorkspace(
  List<WorkspaceEntity> workspaces,
  String localWorkspaceId,
) {
  final mirror = workspaces
      .where((item) => item.id == localWorkspaceId)
      .firstOrNull;
  if (mirror == null) {
    throw const WorkspaceRouteFailure(invalidMirror: false);
  }

  return mirror;
}

WorkspaceSession _workspaceSessionForMirror(
  String localWorkspaceId,
  WorkspaceEntity mirror,
) {
  if (mirror.type != WorkspaceType.remote) {
    return WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: localWorkspaceId),
    );
  }

  return _remoteWorkspaceSession(localWorkspaceId, mirror);
}

WorkspaceSession _remoteWorkspaceSession(
  String localWorkspaceId,
  WorkspaceEntity mirror,
) {
  final metadata = _remoteWorkspaceMetadata(mirror);
  if (metadata == null) {
    throw const WorkspaceRouteFailure(invalidMirror: true);
  }

  return WorkspaceSession(
    CloudWorkspaceRef(
      localWorkspaceId: localWorkspaceId,
      serverUrl: CloudAccountIdentity.canonicalServerOrigin(metadata.serverUrl),
      accountId: metadata.accountId,
      cloudWorkspaceId: metadata.cloudWorkspaceId,
    ),
  );
}

({String serverUrl, String accountId, int cloudWorkspaceId})?
_remoteWorkspaceMetadata(WorkspaceEntity mirror) {
  final serverUrl = mirror.url;
  final accountId = mirror.cloudAccountId;
  final cloudWorkspaceId = int.tryParse(mirror.cloudWorkspaceId ?? '');
  if (serverUrl == null || accountId == null || accountId.isEmpty) return null;
  if (cloudWorkspaceId == null || !_isValidServerUrl(serverUrl)) return null;

  return (
    serverUrl: serverUrl,
    accountId: accountId,
    cloudWorkspaceId: cloudWorkspaceId,
  );
}

bool _isValidServerUrl(String serverUrl) {
  final uri = Uri.tryParse(serverUrl);
  if (uri == null) return false;

  return _hasAllowedServerOrigin(uri);
}

bool _hasAllowedServerOrigin(Uri uri) =>
    ['http', 'https'].contains(uri.scheme) &&
    uri.host.isNotEmpty &&
    uri.userInfo.isEmpty &&
    !uri.hasQuery &&
    !uri.hasFragment;

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<WorkspaceAvailability> workspaceAvailability(
  Ref ref,
  String localWorkspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(localWorkspaceId).future,
  );
  final cloud = session.cloud;
  if (cloud == null) return WorkspaceAvailable(session);

  return await _checkCloudWorkspaceAvailability(ref, session, cloud);
}

Future<WorkspaceAvailability> _checkCloudWorkspaceAvailability(
  Ref ref,
  WorkspaceSession session,
  CloudWorkspaceRef cloud,
) async {
  final health = await ref.watch(
    cloudAccountHealthProvider(
      CloudAccountKeyFactory.fromIdentity(cloud.serverUrl, cloud.accountId),
    ).future,
  );

  return switch (health.status) {
    .verified => WorkspaceAvailable(session),
    .needsSignIn => WorkspaceAuthenticationRequired(session),
    .unknown => throw const AppCloudWorkspaceException(
      LocaleKeys.cloud_errors_unavailable,
    ),
  };
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<CloudWorkspaceStateGateway?> cloudWorkspaceStateGateway(
  Ref ref,
  WorkspaceSession session,
) async {
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

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<CloudWorkspaceStateGateway?> cloudWorkspaceStateGatewayForWorkspace(
  Ref ref,
  String localWorkspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(localWorkspaceId).future,
  );
  final cloud = session.cloud;
  if (cloud == null) return null;

  return await ref.watch(cloudWorkspaceStateGatewayProvider(session).future);
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Stream<List<WorkspaceResource>> cloudWorkspaceConfiguration(
  Ref ref,
  WorkspaceSession session,
) async* {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (gateway == null) {
    yield const [];

    return;
  }
  yield* gateway.watchResources(const [
    WorkspaceResourceKind.compactionSetting,
    WorkspaceResourceKind.workspaceSetting,
  ]);
}
