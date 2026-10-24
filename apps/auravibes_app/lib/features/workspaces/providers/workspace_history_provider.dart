import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_history_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_history_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_history_provider.g.dart';

@riverpod
Future<ManageWorkspaceHistoryUsecase> workspaceHistoryUsecase(
  Ref ref,
  String workspaceId,
) async {
  final link = ref.keepAlive();
  try {
    final session = await ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    if (!ref.mounted) throw const WorkspaceTableException();
    if (session.cloud == null) {
      return ManageWorkspaceHistoryUsecase(
        LocalWorkspaceHistoryRepository(
          ref.watch(appDatabaseProvider),
          workspaceId,
        ),
      );
    }
    return await _cloudHistory(ref, session);
  } finally {
    link.close();
  }
}

Future<ManageWorkspaceHistoryUsecase> _cloudHistory(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) throw const WorkspaceTableException();

  return ManageWorkspaceHistoryUsecase(
    CloudWorkspaceHistoryRepository(.new(gateway)),
  );
}

@riverpod
Future<WorkspaceHistoryPolicy> workspaceHistoryPolicy(Ref ref, String workspaceId) async {
  final usecase = await ref.watch(workspaceHistoryUsecaseProvider(workspaceId).future);
  return await usecase.policy();
}
