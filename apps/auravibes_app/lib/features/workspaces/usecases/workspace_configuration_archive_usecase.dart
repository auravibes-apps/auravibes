import 'package:auravibes_app/data/repositories/local_workspace_configuration_importer.dart';
import 'package:auravibes_app/data/repositories/local_workspace_configuration_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_configuration_repository.dart';
import 'package:auravibes_app/features/workspaces/services/workspace_configuration_file_service.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_configuration_archive_usecase.g.dart';

typedef CloudWorkspaceConfigurationRepositoryFactory =
    Future<CloudWorkspaceConfigurationRepository> Function(
      WorkspaceEntity workspace,
    );

class const WorkspaceConfigurationArchiveUsecase({
  required final LocalWorkspaceConfigurationRepository _localRepository,
  required final LocalWorkspaceConfigurationImporter _localImporter,
  required final CloudWorkspaceConfigurationRepositoryFactory
  _cloudRepositoryFor,
  final WorkspaceConfigurationFileService _fileService =
      const WorkspaceConfigurationFileService(),
}) {
  Future<bool> exportArchive(
    WorkspaceEntity workspace, {
    Set<WorkspaceConfigurationKind>? selectedKinds,
  }) async {
    final archive = await _workspaceArchive(
      workspace,
      selectedKinds: selectedKinds,
    );
    final json = WorkspaceConfigurationArchiveCodec.encode(archive);

    return await _fileService.saveArchiveJson(json);
  }

  Future<bool> importArchive([WorkspaceEntity? workspace]) async {
    final json = await _fileService.pickArchiveJson();
    if (json == null) return false;

    await _importArchive(workspace, json);

    return true;
  }

  Future<WorkspaceConfigurationArchivePreview?> pickArchivePreview() async {
    final json = await _fileService.pickArchiveJson();
    if (json == null) return null;

    return WorkspaceConfigurationArchiveCodec.preview(json);
  }

  Future<void> applyArchivePreview(
    WorkspaceConfigurationArchivePreview preview, {
    WorkspaceEntity? workspace,
  }) => _importArchive(workspace, _encodePreview(preview));

  Future<WorkspaceConfigurationArchive> _workspaceArchive(
    WorkspaceEntity workspace, {
    Set<WorkspaceConfigurationKind>? selectedKinds,
  }) async {
    final cloudWorkspaceId = workspace.cloudWorkspaceId;
    if (cloudWorkspaceId == null) {
      return await _localRepository.export(
        workspace.id,
        selectedKinds: selectedKinds,
      );
    }

    return await (await _cloudRepositoryFor(workspace))
        .export(selectedKinds: selectedKinds);
  }

  Future<void> _importArchive(WorkspaceEntity? workspace, String json) async {
    final cloudWorkspaceId = workspace?.cloudWorkspaceId;
    if (workspace != null && cloudWorkspaceId != null) {
      await (await _cloudRepositoryFor(workspace)).importJson(json);

      return;
    }

    final _ = await _localImporter.importJson(
      json,
      targetWorkspaceId: workspace?.id,
    );
  }
}

String _encodePreview(WorkspaceConfigurationArchivePreview preview) =>
    WorkspaceConfigurationArchiveCodec.encode(preview.archive);

@riverpod
WorkspaceConfigurationArchiveUsecase workspaceConfigurationArchiveUsecase(
  Ref ref,
) {
  final database = ref.watch(appDatabaseProvider);

  return WorkspaceConfigurationArchiveUsecase(
    localRepository: .new(database),
    localImporter: .new(database),
    cloudRepositoryFor: (workspace) =>
        _cloudRepositoryForWorkspace(ref, workspace),
  );
}

Future<CloudWorkspaceConfigurationRepository> _cloudRepositoryForWorkspace(
  Ref ref,
  WorkspaceEntity workspace,
) async {
  final gateway = await ref.read(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspace.id).future,
  );
  if (gateway == null) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.invalid_target',
    );
  }

  return CloudWorkspaceConfigurationRepository(
    store: .new(gateway),
    workspaceName: workspace.name,
  );
}
