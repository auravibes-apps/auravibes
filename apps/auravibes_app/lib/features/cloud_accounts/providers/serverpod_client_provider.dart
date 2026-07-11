// ignore_for_file: implementation_imports
// Serverpod client exposes auth protocol through src imports.

import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/src/providers/future_provider.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

final serverpodAuthStoreProvider = Provider<ServerpodAuthStore>((ref) {
  return ServerpodAuthStore();
});

final cloudAccountsProvider = FutureProvider<List<CloudAccountSession>>((ref) {
  return ref.watch(serverpodAuthStoreProvider).listAccounts();
});

final preferredCloudAccountIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(serverpodAuthStoreProvider).preferredAccountId();
});

final FutureProviderFamily<Client?, String> serverpodClientForAccountProvider =
    FutureProvider.family<Client?, String>((ref, userId) async {
      const serverUrl = AppEnvConfig.auravibesServerUrl;
      if (serverUrl.isEmpty) return null;

      final store = ref.watch(serverpodAuthStoreProvider);
      final client = Client(serverUrl);
      final sessionManager = ClientAuthSessionManager(
        storage: store.authSuccessStorage(userId),
      );
      client.authSessionManager = sessionManager;
      final _ = await sessionManager.initialize();

      return client;
    });
