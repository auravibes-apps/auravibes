import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/resolve_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_workspace_providers.g.dart';

typedef CloudWorkspaceDetailKey = ({
  String serverUrl,
  String accountId,
  int workspaceId,
});
typedef CloudWorkspaceRouteKey = ({
  String accountId,
  int workspaceId,
  String? serverUrl,
});

@riverpod
Future<CloudWorkspaceUseCases?> cloudWorkspaceUseCases(
  Ref ref,
  CloudAccountKey key,
) async {
  final client = await ref.watch(serverpodClientForAccountProvider(key).future);
  if (client == null) return null;

  return CloudWorkspaceUseCases(
    cloudRepository: .new(client),
    workspaceRepository: ref.watch(workspaceRepositoryProvider),
    cloudAccountId: key.accountId,
    serverUrl: key.serverUrl,
  );
}

@riverpod
Future<CloudWorkspaceViewState?> cloudWorkspaceState(
  Ref ref,
  CloudAccountKey key,
) async {
  final health = await ref.watch(cloudAccountHealthProvider(key).future);
  if (health.status == .needsSignIn) {
    return const CloudWorkspaceViewState.authenticationRequired();
  }
  if (health.status == .unknown) {
    throw const AppCloudWorkspaceException(LocaleKeys.cloud_errors_unavailable);
  }
  final useCases = await ref.watch(cloudWorkspaceUseCasesProvider(key).future);
  if (useCases == null) {
    throw const AppCloudWorkspaceException(LocaleKeys.cloud_errors_unavailable);
  }
  try {
    return await useCases.load();
  } on CloudWorkspaceException catch (error) {
    if (!CheckCloudAccountUsecase.requiresSignIn(error)) rethrow;
    ref.invalidate(cloudAccountHealthProvider(key));

    return const CloudWorkspaceViewState.authenticationRequired();
  }
}

@riverpod
Future<CloudWorkspaceDetailState?> cloudWorkspaceDetail(
  Ref ref,
  CloudWorkspaceDetailKey key,
) async {
  final account = cloudAccountKey(key.serverUrl, key.accountId);
  final useCases = await ref.watch(
    cloudWorkspaceUseCasesProvider(account).future,
  );
  if (useCases == null) {
    throw const AppCloudWorkspaceException(LocaleKeys.cloud_errors_unavailable);
  }
  try {
    return await useCases.loadDetail(key.workspaceId);
  } on CloudWorkspaceException catch (error) {
    if (CheckCloudAccountUsecase.requiresSignIn(error)) {
      ref.invalidate(cloudAccountHealthProvider(account));
    }
    rethrow;
  }
}

/// Old links may omit origin; resolving an ambiguous identity fails closed.
@riverpod
Future<CloudAccountKey> cloudWorkspaceRouteAccount(
  Ref ref,
  CloudWorkspaceRouteKey key,
) async {
  final accounts = await ref.watch(cloudAccountsProvider.future);
  final mirrors = await ref.watch(allWorkspacesProvider.future);

  return ResolveCloudAccountUsecase.call(
    accountId: key.accountId,
    accounts: accounts,
    mirrors: mirrors,
    workspaceId: key.workspaceId,
    serverUrl: key.serverUrl,
  );
}
