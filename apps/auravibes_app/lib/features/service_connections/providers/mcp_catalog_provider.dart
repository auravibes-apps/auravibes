import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
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
  final accounts = await ref.watch(cloudAccountsProvider.future);
  final preferred = await ref
      .watch(serverpodAuthStoreProvider)
      .preferredAccountIdentity();
  final origin = CloudAccountIdentity.canonicalServerOrigin(
    AppEnvConfig.auravibesServerUrl,
  );
  final matching = accounts.where(
    (account) =>
        CloudAccountIdentity.canonicalServerOrigin(account.serverUrl) == origin,
  );
  final account =
      matching.where((account) {
        return CloudAccountIdentity.accountIdentity(
              account.serverUrl,
              account.userId,
            ) ==
            preferred;
      }).firstOrNull ??
      matching.firstOrNull;
  if (account == null) throw const McpCatalogSignInRequired();
  final client = await ref.watch(
    serverpodClientForWorkspaceProvider((
      serverUrl: account.serverUrl,
      accountId: account.userId,
    )).future,
  );
  return client;
}

class const McpCatalogSignInRequired() implements Exception {
  String get localizationKey => LocaleKeys.mcp_catalog_sign_in_required;

  @override
  String toString() => localizationKey;
}
