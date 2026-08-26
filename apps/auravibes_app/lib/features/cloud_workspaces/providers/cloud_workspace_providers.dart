// ignore_for_file: implementation_imports, newline-before-return

// Hooks Riverpod publicly exports providers implemented under riverpod/lib/src.

import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/data/cloud_workspace_repository.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod/src/providers/future_provider.dart';

final FutureProviderFamily<CloudWorkspaceUseCases?, String>
cloudWorkspaceUseCasesProvider =
    FutureProvider.family<CloudWorkspaceUseCases?, String>((ref, userId) async {
      final client = await ref.watch(
        serverpodClientForAccountProvider((
          serverUrl: AppEnvConfig.auravibesServerUrl,
          accountId: userId,
        )).future,
      );
      if (client == null) return null;

      return CloudWorkspaceUseCases(
        cloudRepository: CloudWorkspaceRepository(client),
        workspaceRepository: ref.watch(workspaceRepositoryProvider),
        cloudAccountId: userId,
        serverUrl: AppEnvConfig.auravibesServerUrl,
      );
    });

final FutureProviderFamily<CloudWorkspaceViewState?, String>
cloudWorkspaceStateProvider =
    FutureProvider.family<CloudWorkspaceViewState?, String>((
      ref,
      userId,
    ) async {
      final useCases = await ref.watch(
        cloudWorkspaceUseCasesProvider(userId).future,
      );

      try {
        return await useCases?.load();
      } on CloudWorkspaceException catch (error) {
        if (error.code != CloudWorkspaceErrorCode.authenticationRequired) {
          rethrow;
        }

        return const CloudWorkspaceViewState.authenticationRequired();
      }
    });

typedef CloudWorkspaceDetailKey = ({String accountId, int workspaceId});

final FutureProviderFamily<CloudWorkspaceDetailState?, CloudWorkspaceDetailKey>
cloudWorkspaceDetailProvider =
    FutureProvider.family<CloudWorkspaceDetailState?, CloudWorkspaceDetailKey>((
      ref,
      key,
    ) async {
      final useCases = await ref.watch(
        cloudWorkspaceUseCasesProvider(key.accountId).future,
      );

      return await useCases?.loadDetail(key.workspaceId);
    });
