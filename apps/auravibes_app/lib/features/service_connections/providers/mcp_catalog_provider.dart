import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_catalog_sign_in_required.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_catalog_provider.g.dart';

@riverpod
Future<List<McpCatalogListing>> mcpCatalog(Ref ref, String workspaceId) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final cloud = session.cloud;
  final client = cloud == null
      ? await _localWorkspaceCatalogClient(ref)
      : await ref.watch(
          serverpodClientForWorkspaceProvider((
            serverUrl: cloud.serverUrl,
            accountId: cloud.accountId,
          )).future,
        );

  return await client.mcpCatalog.list();
}

Future<Client> _localWorkspaceCatalogClient(Ref ref) async {
  final account = await _localCatalogAccount(ref);
  if (account == null) throw const McpCatalogSignInRequired();

  return await ref.watch(
    serverpodClientForWorkspaceProvider((
      serverUrl: account.serverUrl,
      accountId: account.userId,
    )).future,
  );
}

Future<CloudAccountSession?> _localCatalogAccount(Ref ref) async {
  final accounts = await ref.watch(cloudAccountsProvider.future);
  final preferred = await ref
      .watch(serverpodAuthStoreProvider)
      .preferredAccountIdentity();
  final origin = CloudAccountIdentity.canonicalServerOrigin(
    AppEnvConfig.auravibesServerUrl,
  );

  return _preferredCatalogAccount(accounts, origin, preferred);
}

CloudAccountSession? _preferredCatalogAccount(
  List<CloudAccountSession> accounts,
  String origin,
  String? preferredIdentity,
) {
  final matching = accounts.where(
    (account) =>
        CloudAccountIdentity.canonicalServerOrigin(account.serverUrl) == origin,
  );

  return _matchingPreferredAccount(matching, preferredIdentity) ??
      matching.firstOrNull;
}

CloudAccountSession? _matchingPreferredAccount(
  Iterable<CloudAccountSession> accounts,
  String? preferredIdentity,
) => accounts
    .where(
      (account) =>
          CloudAccountIdentity.accountIdentity(
            account.serverUrl,
            account.userId,
          ) ==
          preferredIdentity,
    )
    .firstOrNull;
