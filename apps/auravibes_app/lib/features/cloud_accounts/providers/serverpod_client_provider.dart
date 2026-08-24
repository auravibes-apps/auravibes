// ignore_for_file: implementation_imports
// Serverpod client exposes auth protocol through src imports.

import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/src/providers/future_provider.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

final serverpodAuthStoreProvider = Provider<ServerpodAuthStore>((ref) {
  return ServerpodAuthStore(
    storageNamespace: ref.watch(appStorageNamespaceProvider),
  );
});

final cloudAccountsProvider = FutureProvider<List<CloudAccountSession>>((ref) {
  return ref
      .watch(serverpodAuthStoreProvider)
      .listAccounts(
        legacyServerUrl: AppEnvConfig.auravibesServerUrl,
      );
});

final FutureProviderFamily<Client?, ({String accountId, String serverUrl})>
serverpodClientForAccountProvider =
    FutureProvider.family<Client?, ({String accountId, String serverUrl})>((
      ref,
      key,
    ) async {
      final serverUrl = CloudAccountIdentity.canonicalServerOrigin(
        key.serverUrl,
      );
      if (serverUrl.isEmpty) return null;

      final store = ref.watch(serverpodAuthStoreProvider);
      final client = Client(serverUrl);
      final _ = ref.onDispose(client.close);
      final sessionManager = ClientAuthSessionManager(
        storage: store.authSuccessStorage(
          serverUrl: serverUrl,
          userId: key.accountId,
        ),
      );
      client.authSessionManager = sessionManager;
      final _ = await sessionManager.initialize();

      return client;
    });

final FutureProviderFamily<Client, ({String accountId, String serverUrl})>
serverpodClientForWorkspaceProvider =
    FutureProvider.family<Client, ({String serverUrl, String accountId})>(
      (ref, key) async {
        final store = ref.watch(serverpodAuthStoreProvider);
        final serverUrl = CloudAccountIdentity.canonicalServerOrigin(
          key.serverUrl,
        );
        final client = Client(serverUrl);
        final _ = ref.onDispose(client.close);
        final sessionManager = ClientAuthSessionManager(
          storage: store.authSuccessStorage(
            serverUrl: serverUrl,
            userId: key.accountId,
          ),
        );
        client.authSessionManager = sessionManager;
        final _ = await sessionManager.initialize();

        return client;
      },
    );
