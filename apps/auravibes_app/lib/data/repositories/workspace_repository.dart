// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:drift/drift.dart';

/// Implementation of the [WorkspaceRepository] interface.
///
/// This class provides a concrete implementation of workspace data operations
/// using the Drift database. It handles the mapping between domain entities
/// and database records, and provides proper error handling using exceptions.
class WorkspaceRepository {
  WorkspaceRepository(
    this._database, {
    AttachmentFileStore? attachmentFileStore,
  }) : _attachmentFileStore = attachmentFileStore ?? AttachmentFileStore();

  /// The database instance for workspace operations.
  final AppDatabase _database;
  final AttachmentFileStore _attachmentFileStore;

  Future<List<WorkspaceEntity>> getAllWorkspaces() async {
    final workspaceTables = await _database.workspaceDao.getAllWorkspaces();

    return workspaceTables.map(_mapToWorkspace).toList();
  }

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
    final currentWorkspaceTable = await _database.workspaceDao.getWorkspaceById(
      id,
    );
    if (currentWorkspaceTable == null) {
      throw WorkspaceNotFoundException(id);
    }

    _validateWorkspacePatch(
      workspace,
      _mapToWorkspace(currentWorkspaceTable),
    );

    final workspaceCompanion = _mapPatchToWorkspacesCompanion(workspace);
    final updated = await _database.workspaceDao.patchWorkspace(
      id,
      workspaceCompanion,
    );

    if (!updated) {
      throw WorkspaceException('Failed to patch workspace with ID $id');
    }

    final updatedWorkspace = await _database.workspaceDao.getWorkspaceById(id);

    if (updatedWorkspace == null) {
      throw WorkspaceException(
        'Failed to retrieve updated workspace with ID $id',
      );
    }

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
      final _ = await Future.wait(
        attachmentPaths.map(_deleteAttachmentFile),
      );
    }

    return deleted;
  }

  Future<WorkspaceEntity?> getCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) async {
    final row =
        await (_database.select(_database.workspaces)..where(
              (workspace) =>
                  workspace.cloudWorkspaceId.equals(cloudWorkspaceId) &
                  workspace.cloudAccountId.equals(cloudAccountId) &
                  workspace.url.equals(serverUrl),
            ))
            .getSingleOrNull();

    return row == null ? null : _mapToWorkspace(row);
  }

  Future<WorkspaceEntity?> getCloudWorkspaceMirrorByCloudId(
    String cloudWorkspaceId, {
    required String cloudAccountId,
    required String serverUrl,
  }) async {
    final row =
        await (_database.select(_database.workspaces)..where(
              (workspace) =>
                  workspace.cloudWorkspaceId.equals(cloudWorkspaceId) &
                  workspace.cloudAccountId.equals(cloudAccountId) &
                  workspace.url.equals(serverUrl),
            ))
            .getSingleOrNull();

    return row == null ? null : _mapToWorkspace(row);
  }

  Future<WorkspaceEntity> upsertCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String name,
    required String serverUrl,
  }) async {
    final existing = await getCloudWorkspaceMirrorByCloudId(
      cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
      serverUrl: serverUrl,
    );

    if (existing == null) {
      return createWorkspace(
        WorkspaceToCreate(
          name: name,
          type: WorkspaceType.remote,
          url: serverUrl,
          cloudWorkspaceId: cloudWorkspaceId,
          cloudAccountId: cloudAccountId,
        ),
      );
    }

    return patchWorkspace(
      existing.id,
      WorkspacePatch(
        name: name,
        type: WorkspaceType.remote,
        url: serverUrl,
        cloudWorkspaceId: cloudWorkspaceId,
        cloudAccountId: cloudAccountId,
      ),
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

    return deleteWorkspace(existing.id);
  }

  Future<int> deleteCloudWorkspaceMirrorsForAccount(
    String cloudAccountId, {
    String? serverUrl,
  }) {
    return _deleteCloudWorkspaceMirrorsForAccount(
      cloudAccountId,
      serverUrl: serverUrl,
    );
  }

  Future<int> _deleteCloudWorkspaceMirrorsForAccount(
    String cloudAccountId, {
    String? serverUrl,
  }) async {
    final mirrors =
        await (_database.select(_database.workspaces)..where(
              (workspace) =>
                  workspace.cloudAccountId.equals(cloudAccountId) &
                  (serverUrl == null
                      ? const Constant(true)
                      : workspace.url.equals(serverUrl)),
            ))
            .get();
    var deleted = 0;
    for (final mirror in mirrors) {
      if (await deleteWorkspace(mirror.id)) deleted++;
    }

    return deleted;
  }

  Future<List<String>> _attachmentPathsForWorkspace(String id) async {
    final rows = await (_database.select(_database.messageAttachments).join([
      innerJoin(
        _database.messages,
        _database.messages.id.equalsExp(
          _database.messageAttachments.messageId,
        ),
      ),
      innerJoin(
        _database.conversations,
        _database.conversations.id.equalsExp(_database.messages.conversationId),
      ),
    ])..where(_database.conversations.workspaceId.equals(id))).get();

    return [
      for (final row in rows)
        row.readTable(_database.messageAttachments).localPath,
    ];
  }

  Future<void> _deleteAttachmentFile(String localPath) async {
    try {
      await _attachmentFileStore.deleteFile(localPath);
    } on Object {
      return;
    }
  }

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

    return _database.workspaceDao.patchWorkspaceTimestamp(id);
  }

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
      name: Value(workspace.name),
      type: Value(workspace.type),
      url: Value(workspace.url),
      cloudWorkspaceId: Value(workspace.cloudWorkspaceId),
      cloudAccountId: Value(workspace.cloudAccountId),
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
      name: Value.absentIfNull(workspace.name),
      type: Value.absentIfNull(workspace.type),
      url: Value.absentIfNull(workspace.url),
      cloudWorkspaceId: Value.absentIfNull(workspace.cloudWorkspaceId),
      cloudAccountId: Value.absentIfNull(workspace.cloudAccountId),
    );
  }

  /// Gets validation error message for a workspace.
  ///
  /// [workspace] The workspace to validate.
  /// Returns a string describing the validation error.
  String _getValidationErrorToCreate(WorkspaceToCreate workspace) {
    if (workspace.name.isEmpty) return 'Workspace name cannot be empty';
    if (workspace.type == WorkspaceType.local &&
        (workspace.url != null || workspace.cloudWorkspaceId != null)) {
      return 'Local workspace cannot have remote metadata';
    }
    final url = workspace.url;
    final cloudWorkspaceId = workspace.cloudWorkspaceId;
    final cloudAccountId = workspace.cloudAccountId;
    if (workspace.type == WorkspaceType.remote &&
        (url == null || url.isEmpty) &&
        (cloudWorkspaceId == null ||
            cloudWorkspaceId.isEmpty ||
            cloudAccountId == null ||
            cloudAccountId.isEmpty)) {
      return 'Remote workspace must have a URL or cloud ID';
    }

    return 'Unknown validation error';
  }
}

/// Base exception for workspace-related operations.
class WorkspaceException implements Exception {
  /// Creates a new WorkspaceException.
  const WorkspaceException(this.message, {this.localizationKey, this.cause});

  /// Error message describing the exception.
  /// Used as fallback when localization is unavailable.
  final String message;

  /// Localization key for user-facing error messages.
  final String? localizationKey;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';

    return 'WorkspaceException: $message$causedBy';
  }
}

/// Exception thrown when workspace validation fails.
class WorkspaceValidationException extends WorkspaceException {
  /// Creates a new WorkspaceValidationException.
  const WorkspaceValidationException(
    super.message, {
    super.localizationKey,
    super.cause,
  });
}

/// Exception thrown when a workspace is not found.
class WorkspaceNotFoundException extends WorkspaceException {
  /// Creates a new WorkspaceNotFoundException.
  const WorkspaceNotFoundException(this.workspaceId, {super.cause})
    : super(
        'Workspace with ID "$workspaceId" not found',
        localizationKey: LocaleKeys.workspace_management_error_not_found,
      );

  /// ID of the workspace that was not found.
  final String workspaceId;
}

/// Exception thrown when attempting to delete the currently active workspace.
class WorkspaceDeleteActiveException extends WorkspaceException {
  /// Creates a new WorkspaceDeleteActiveException.
  const WorkspaceDeleteActiveException()
    : super(
        'Cannot delete the currently active workspace. '
        'Switch to another workspace first.',
        localizationKey: LocaleKeys.workspace_management_delete_active_error,
      );
}
