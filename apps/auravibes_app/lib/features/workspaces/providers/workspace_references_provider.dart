import 'package:auravibes_app/data/repositories/cloud_workspace_reference_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_reference_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_references_provider.g.dart';

@riverpod
Future<BrowseWorkspaceReferencesUsecase> workspaceReferencesUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceTableException();
  if (session.cloud == null) {
    return BrowseWorkspaceReferencesUsecase(
      LocalWorkspaceReferenceRepository(
        ref.watch(appDatabaseProvider),
        workspaceId,
      ),
    );
  }
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  if (!ref.mounted || gateway == null) throw const WorkspaceTableException();

  return BrowseWorkspaceReferencesUsecase(
    CloudWorkspaceReferenceRepository(.new(gateway)),
  );
}

@riverpod
Future<WorkspaceRecord> workspaceReferencedRecord(
  Ref ref,
  String workspaceId,
  String tableId,
  String id,
) async {
  final references = await ref.watch(
    workspaceReferencesUsecaseProvider(workspaceId).future,
  );

  return await references.record(tableId, id);
}
