// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:drift/drift.dart';

typedef _CloudWorkspaceData = ({
  String name,
  String cloudWorkspaceId,
  String cloudAccountId,
  String serverUrl,
});

/// Implementation of the [WorkspaceRepository] interface.
///
/// This class provides a concrete implementation of workspace data operations
/// using the Drift database. It handles the mapping between domain entities
/// and database records, and provides proper error handling using exceptions.
class WorkspaceRepository(
  /// The database instance for workspace operations.
  final AppDatabase _database, {
  final AttachmentFileStore _attachmentFileStore = const AttachmentFileStore(),
}) with
    _WorkspaceRepositoryOperationsApi,
    _WorkspaceRepositoryCloudApi,
    _WorkspaceRepositoryQueryApi {
  Future<List<WorkspaceEntity>> getAllWorkspaces() async {
    final workspaceTables = await _database.workspaceDao.getAllWorkspaces();

    return workspaceTables.map(_mapToWorkspace).toList();
  }
}

mixin _WorkspaceRepositoryOperationsApi {
  Stream<List<WorkspaceEntity>> watchAllWorkspaces() =>
      WorkspaceRepositoryOperations(this as WorkspaceRepository)
          .watchAllWorkspaces();

  Future<WorkspaceEntity?> getWorkspaceById(String id) =>
      WorkspaceRepositoryOperations(this as WorkspaceRepository)
          .getWorkspaceById(id);

  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type) =>
      WorkspaceRepositoryOperations(this as WorkspaceRepository)
          .getWorkspacesByType(type);

  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) =>
      WorkspaceRepositoryOperations(this as WorkspaceRepository)
          .createWorkspace(workspace);

  Future<WorkspaceEntity> patchWorkspace(String id, WorkspacePatch workspace) =>
      WorkspaceRepositoryOperations(this as WorkspaceRepository)
          .patchWorkspace(id, workspace);

  Future<bool> deleteWorkspace(String id) =>
      WorkspaceRepositoryOperations(this as WorkspaceRepository)
          .deleteWorkspace(id);
}

mixin _WorkspaceRepositoryCloudApi {
  Future<WorkspaceEntity?> getCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) =>
      WorkspaceRepositoryCloudOperations(this as WorkspaceRepository)
          .getCloudWorkspaceMirror(
            cloudWorkspaceId: cloudWorkspaceId,
            cloudAccountId: cloudAccountId,
            serverUrl: serverUrl,
          );

  Future<WorkspaceEntity?> getCloudWorkspaceMirrorByCloudId(
    String cloudWorkspaceId, {
    required String cloudAccountId,
    required String serverUrl,
  }) => WorkspaceRepositoryCloudOperations(this as WorkspaceRepository)
      .getCloudWorkspaceMirrorByCloudId(
        cloudWorkspaceId,
        cloudAccountId: cloudAccountId,
        serverUrl: serverUrl,
      );

  Future<WorkspaceEntity> upsertCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String name,
    required String serverUrl,
  }) =>
      WorkspaceRepositoryCloudOperations(this as WorkspaceRepository)
          .upsertCloudWorkspaceMirror(
            cloudWorkspaceId: cloudWorkspaceId,
            cloudAccountId: cloudAccountId,
            name: name,
            serverUrl: serverUrl,
          );

  Future<bool> deleteCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) =>
      WorkspaceRepositoryCloudOperations(this as WorkspaceRepository)
          .deleteCloudWorkspaceMirror(
            cloudWorkspaceId: cloudWorkspaceId,
            cloudAccountId: cloudAccountId,
            serverUrl: serverUrl,
          );

  Future<int> deleteCloudWorkspaceMirrorsForAccount(
    String cloudAccountId, {
    required String serverUrl,
  }) => WorkspaceRepositoryCloudOperations(
    this as WorkspaceRepository,
  ).deleteCloudWorkspaceMirrorsForAccount(cloudAccountId, serverUrl: serverUrl);
}

mixin _WorkspaceRepositoryQueryApi {
  Future<bool> workspaceExists(String id) =>
      WorkspaceRepositoryQueryOperations(this as WorkspaceRepository)
          .workspaceExists(id);

  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) =>
      WorkspaceRepositoryQueryOperations(this as WorkspaceRepository)
          .searchWorkspacesByName(query);

  Future<int> getWorkspaceCount() =>
      WorkspaceRepositoryQueryOperations(this as WorkspaceRepository)
          .getWorkspaceCount();

  Future<int> getWorkspaceCountByType(WorkspaceType type) =>
      WorkspaceRepositoryQueryOperations(this as WorkspaceRepository)
          .getWorkspaceCountByType(type);

  Future<bool> validateWorkspace(WorkspaceToCreate workspace) =>
      WorkspaceRepositoryQueryOperations(this as WorkspaceRepository)
          .validateWorkspace(workspace);

  Future<bool> patchWorkspaceTimestamp(String id) =>
      WorkspaceRepositoryQueryOperations(this as WorkspaceRepository)
          .patchWorkspaceTimestamp(id);
}

extension WorkspaceRepositoryOperations on WorkspaceRepository {
  Stream<List<WorkspaceEntity>> watchAllWorkspaces() {
    return _database.workspaceDao.watchAllWorkspaces().map(
      (tables) => tables.map(_mapToWorkspace).toList(),
    );
  }

  Future<WorkspaceEntity?> getWorkspaceById(String id) async {
    final workspacesTable = await _database.workspaceDao.getWorkspaceById(id);

    return workspacesTable != null ? _mapToWorkspace(workspacesTable) : null;
  }

  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type) async {
    final workspaceTables = await _database.workspaceDao.getWorkspacesByType(
      type,
    );

    return workspaceTables.map(_mapToWorkspace).toList();
  }

  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) async {
    // Validate workspace before creating.
    if (!await validateWorkspace(workspace)) {
      throw const WorkspaceValidationException('Invalid workspace data');
    }

    final workspaceCompanion = _mapToWorkspacesCompanion(workspace);
    final createdWorkspace = await _database.workspaceDao.insertWorkspace(
      workspaceCompanion,
    );

    return _mapToWorkspace(createdWorkspace);
  }

  Future<WorkspaceEntity> patchWorkspace(
    String id,
    WorkspacePatch workspace,
  ) async {
    final currentWorkspaceTable = await _requireWorkspace(id);

    _validateWorkspacePatch(workspace, _mapToWorkspace(currentWorkspaceTable));

    final updatedWorkspace = await _patchWorkspaceRow(
      id,
      _mapPatchToWorkspacesCompanion(workspace),
    );

    return _mapToWorkspace(updatedWorkspace);
  }

  Future<bool> deleteWorkspace(String id) async {
    // Check if workspace exists.
    if (!await workspaceExists(id)) {
      return false; // Return false instead of throwing for delete operations.
    }

    final attachmentPaths = await _attachmentPathsForWorkspace(id);
    final deleted = await _database.workspaceDao.deleteWorkspace(id);
    if (deleted) {
      final _ = await Future.wait(attachmentPaths.map(_deleteAttachmentFile));
    }

    return deleted;
  }
}

extension WorkspaceRepositoryCloudOperations on WorkspaceRepository {
  Future<WorkspaceEntity?> getCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) async {
    final row = await _findCloudWorkspaceMirror(
      cloudWorkspaceId: cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
      serverUrl: serverUrl,
    );

    return row == null ? null : _mapToWorkspace(row);
  }

  Future<WorkspaceEntity?> getCloudWorkspaceMirrorByCloudId(
    String cloudWorkspaceId, {
    required String cloudAccountId,
    required String serverUrl,
  }) async {
    final row = await _findCloudWorkspaceMirror(
      cloudWorkspaceId: cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
      serverUrl: serverUrl,
    );

    return row == null ? null : _mapToWorkspace(row);
  }

  Future<WorkspaceEntity> upsertCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String name,
    required String serverUrl,
  }) async {
    final cloudWorkspace = (
      name: name,
      cloudWorkspaceId: cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
      serverUrl: serverUrl,
    );
    final existing = await getCloudWorkspaceMirrorByCloudId(
      cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
      serverUrl: serverUrl,
    );

    if (existing == null) {
      return await createWorkspace(_cloudWorkspaceToCreate(cloudWorkspace));
    }

    return await patchWorkspace(
      existing.id,
      _cloudWorkspacePatch(cloudWorkspace),
    );
  }

  Future<bool> deleteCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) async {
    final existing = await getCloudWorkspaceMirror(
      cloudWorkspaceId: cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
      serverUrl: serverUrl,
    );
    if (existing == null) return false;

    return await deleteWorkspace(existing.id);
  }

  Future<int> deleteCloudWorkspaceMirrorsForAccount(
    String cloudAccountId, {
    required String serverUrl,
  }) async {
    final mirrors = await _findCloudWorkspaceMirrorsForAccount(
      cloudAccountId: cloudAccountId,
      serverUrl: serverUrl,
    );
    var deleted = 0;
    for (final mirror in mirrors) {
      if (await deleteWorkspace(mirror.id)) deleted++;
    }

    return deleted;
  }
}

extension WorkspaceRepositoryQueryOperations on WorkspaceRepository {
  Future<bool> workspaceExists(String id) {
    return _database.workspaceDao.workspaceExists(id);
  }

  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) async {
    final workspaceTables = await _database.workspaceDao.searchWorkspacesByName(
      query,
    );

    return workspaceTables.map(_mapToWorkspace).toList();
  }

  Future<int> getWorkspaceCount() {
    return _database.workspaceDao.getWorkspaceCount();
  }

  Future<int> getWorkspaceCountByType(WorkspaceType type) {
    return _database.workspaceDao.getWorkspaceCountByType(type);
  }

  Future<bool> validateWorkspace(WorkspaceToCreate workspace) async {
    if (!workspace.isValid) {
      throw WorkspaceValidationException(
        _getValidationErrorToCreate(workspace),
      );
    }

    return true;
  }

  Future<bool> patchWorkspaceTimestamp(String id) async {
    // Check if workspace exists.
    if (!await workspaceExists(id)) {
      return false; // Return false instead of throwing for patch operations.
    }

    return await _database.workspaceDao.patchWorkspaceTimestamp(id);
  }
}

extension on WorkspaceRepository {
  Future<WorkspacesTable> _requireWorkspace(String id) async {
    final workspace = await _database.workspaceDao.getWorkspaceById(id);
    if (workspace == null) throw WorkspaceNotFoundException(id);

    return workspace;
  }

  Future<WorkspacesTable> _patchWorkspaceRow(
    String id,
    WorkspacesCompanion companion,
  ) async {
    final updated = await _database.workspaceDao.patchWorkspace(id, companion);
    if (!updated) {
      throw WorkspaceException('Failed to patch workspace with ID $id');
    }

    final workspace = await _database.workspaceDao.getWorkspaceById(id);
    if (workspace == null) {
      throw WorkspaceException(
        'Failed to retrieve updated workspace with ID $id',
      );
    }

    return workspace;
  }

  Future<WorkspacesTable?> _findCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) async {
    return await (_database.select(_database.workspaces)..where(
          (workspace) =>
              workspace.cloudWorkspaceId.equals(cloudWorkspaceId) &
              workspace.cloudAccountId.equals(cloudAccountId) &
              workspace.url.equals(serverUrl),
        ))
        .getSingleOrNull();
  }

  Future<List<WorkspacesTable>> _findCloudWorkspaceMirrorsForAccount({
    required String cloudAccountId,
    required String serverUrl,
  }) async {
    return await (_database.select(_database.workspaces)..where(
          (workspace) =>
              workspace.cloudAccountId.equals(cloudAccountId) &
              workspace.url.equals(serverUrl),
        ))
        .get();
  }

  WorkspaceToCreate _cloudWorkspaceToCreate(_CloudWorkspaceData data) => .new(
    name: data.name,
    type: WorkspaceType.remote,
    url: data.serverUrl,
    cloudWorkspaceId: data.cloudWorkspaceId,
    cloudAccountId: data.cloudAccountId,
  );

  WorkspacePatch _cloudWorkspacePatch(_CloudWorkspaceData data) => .new(
    name: data.name,
    type: WorkspaceType.remote,
    url: data.serverUrl,
    cloudWorkspaceId: data.cloudWorkspaceId,
    cloudAccountId: data.cloudAccountId,
  );

  Future<List<String>> _attachmentPathsForWorkspace(String id) async {
    final rows = await _workspaceAttachmentRows(id);

    return [
      for (final row in rows)
        row.readTable(_database.messageAttachments).localPath,
    ];
  }

  Future<List<TypedResult>> _workspaceAttachmentRows(String id) async {
    return await (_database.select(_database.messageAttachments).join([
      innerJoin(
        _database.messages,
        _database.messages.id.equalsExp(_database.messageAttachments.messageId),
      ),
      innerJoin(
        _database.conversations,
        _database.conversations.id.equalsExp(_database.messages.conversationId),
      ),
    ])..where(_database.conversations.workspaceId.equals(id))).get();
  }

  Future<void> _deleteAttachmentFile(String localPath) async {
    try {
      await _attachmentFileStore.deleteFile(localPath);
    } on Object {
      return;
    }
  }
}

extension on WorkspaceRepository {
  /// Maps a [workspacesTable] database record to a [WorkspaceEntity]
  /// domain entity.
  ///
  /// [workspacesTable] The database record to map.
  /// Returns the corresponding [WorkspaceEntity] entity.
  WorkspaceEntity _mapToWorkspace(WorkspacesTable workspacesTable) {
    return WorkspaceEntity(
      id: workspacesTable.id,
      name: workspacesTable.name,
      type: workspacesTable.type,
      createdAt: workspacesTable.createdAt,
      updatedAt: workspacesTable.updatedAt,
      url: workspacesTable.url,
      cloudWorkspaceId: workspacesTable.cloudWorkspaceId,
      cloudAccountId: workspacesTable.cloudAccountId,
    );
  }

  /// Maps a [WorkspaceEntity] domain entity to a [WorkspacesCompanion]
  /// for database operations.
  ///
  /// [workspace] The workspace entity to map.
  /// Returns the corresponding [WorkspacesCompanion].
  WorkspacesCompanion _mapToWorkspacesCompanion(WorkspaceToCreate workspace) {
    return WorkspacesCompanion(
      name: .new(workspace.name),
      type: .new(workspace.type),
      url: .new(workspace.url),
      cloudWorkspaceId: .new(workspace.cloudWorkspaceId),
      cloudAccountId: .new(workspace.cloudAccountId),
    );
  }

  void _validateWorkspacePatch(
    WorkspacePatch workspace,
    WorkspaceEntity currentWorkspace,
  ) {
    final validationError = workspace.validationErrorFor(currentWorkspace);
    if (validationError != null) {
      throw WorkspaceValidationException(validationError);
    }
  }

  WorkspacesCompanion _mapPatchToWorkspacesCompanion(WorkspacePatch workspace) {
    return WorkspacesCompanion(
      name: .absentIfNull(workspace.name),
      type: .absentIfNull(workspace.type),
      url: .absentIfNull(workspace.url),
      cloudWorkspaceId: .absentIfNull(workspace.cloudWorkspaceId),
      cloudAccountId: .absentIfNull(workspace.cloudAccountId),
    );
  }

  /// Gets validation error message for a workspace.
  ///
  /// [workspace] The workspace to validate.
  /// Returns a string describing the validation error.
  String _getValidationErrorToCreate(WorkspaceToCreate workspace) {
    if (!workspace.hasValidName) return 'Workspace name cannot be empty';
    if (workspace.isLocal && !workspace.hasValidUrl) {
      return 'Local workspace cannot have remote metadata';
    }
    if (workspace.isRemote && !workspace.hasValidUrl) {
      return 'Remote workspace must have a URL or cloud ID';
    }

    return 'Unknown validation error';
  }
}

/// Base exception for workspace-related operations.
class WorkspaceException implements Exception {
  /// Creates a new WorkspaceException.
  const new(this.message, {this.localizationKey, this.cause});

  /// Error message describing the exception.
  /// Used as fallback when localization is unavailable.
  final String message;

  /// Localization key for user-facing error messages.
  final String? localizationKey;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: ${cause.runtimeType})' : '';

    return 'WorkspaceException: $message$causedBy';
  }
}

/// Exception thrown when workspace validation fails.
class WorkspaceValidationException extends WorkspaceException {
  /// Creates a new WorkspaceValidationException.
  const new(super.message, {super.localizationKey, super.cause});

  @override
  String toString() {
    final value = super.toString();
    return value;
  }
}

/// Exception thrown when a workspace is not found.
class WorkspaceNotFoundException extends WorkspaceException {
  /// Creates a new WorkspaceNotFoundException.
  const new(this.workspaceId, {super.cause})
    : super(
        'Workspace with ID "$workspaceId" not found',
        localizationKey: LocaleKeys.workspace_management_error_not_found,
      );

  /// ID of the workspace that was not found.
  final String workspaceId;

  @override
  String toString() {
    final value = super.toString();
    return value;
  }
}
