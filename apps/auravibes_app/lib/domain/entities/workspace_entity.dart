// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_entity.freezed.dart';

/// Entity representing a workspace in the Aura application.
///
/// A workspace is a container for organizing and managing different
/// projects or environments within the Aura application.
@freezed
abstract class const WorkspaceEntity._() with _$WorkspaceEntity {
  /// Creates a new Workspace instance.
  const factory({
    /// Unique identifier for the workspace.
    required String id,

    /// Human-readable name of the workspace.
    required String name,

    /// Type of workspace (local or remote).
    required WorkspaceType type,

    /// Timestamp when the workspace was created.
    required DateTime createdAt,

    /// Timestamp when the workspace was last updated.
    required DateTime updatedAt,

    /// URL for remote workspaces, null for local workspaces.
    String? url,

    /// Cloud workspace identifier for mirrored cloud workspaces.
    String? cloudWorkspaceId,

    /// Cloud account identifier used to access this local mirror.
    String? cloudAccountId,
  }) = _WorkspaceEntity;
}

@freezed
abstract class const WorkspaceToCreate._() with _$WorkspaceToCreate {
  /// Creates a new WorkspaceToCreate instance.
  const factory({
    /// Human-readable name of the workspace.
    required String name,

    /// Type of workspace (local or remote).
    required WorkspaceType type,

    /// URL for remote workspaces, null for local workspaces.
    String? url,

    /// Cloud workspace identifier for mirrored cloud workspaces.
    String? cloudWorkspaceId,

    /// Cloud account identifier that owns this local mirror.
    String? cloudAccountId,
  }) = _WorkspaceToCreate;

  /// Returns true if the workspace name is not empty.
  bool get hasValidName => name.isNotEmpty;

  /// Returns true if this is a local workspace.
  bool get isLocal => type.isLocal;

  /// Returns true if this is a remote workspace.
  bool get isRemote => type.isRemote;

  /// Returns true if the workspace has a valid URL (for remote workspaces).
  bool get hasValidUrl {
    if (isLocal) return url == null && !_hasCloudMirror;

    return isRemote && (_hasUrl || _hasValidCloudMirror);
  }

  /// Returns true if the workspace is in a valid state.
  bool get isValid {
    return hasValidName && hasValidUrl;
  }

  bool get _hasCloudMirror =>
      cloudWorkspaceId != null && cloudAccountId != null;

  bool get _hasUrl => url?.isNotEmpty == true;

  bool get _hasValidCloudMirror =>
      cloudWorkspaceId?.isNotEmpty == true &&
      cloudAccountId?.isNotEmpty == true;
}

@freezed
abstract class const WorkspacePatch._() with _$WorkspacePatch {
  // Null fields mean the patch leaves those values unchanged.
  // ignore: unnecessary-nullable
  const factory({
    String? name,
    WorkspaceType? type,
    String? url,
    String? cloudWorkspaceId,
    String? cloudAccountId,
  }) = _WorkspacePatch;
  bool get _hasNoChanges =>
      name == null &&
      type == null &&
      url == null &&
      cloudWorkspaceId == null &&
      cloudAccountId == null;

  String? validationErrorFor(WorkspaceEntity current) {
    if (_hasNoChanges) {
      return 'At least one field must be provided';
    }

    final fieldError = _fieldValidationError(
      name: name,
      url: url,
      cloudWorkspaceId: cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
    );
    if (fieldError != null) return fieldError;

    return _mergedValidationError(_mergedWorkspace(current));
  }

  WorkspaceToCreate _mergedWorkspace(WorkspaceEntity current) =>
      WorkspaceToCreate(
        name: name ?? current.name,
        type: type ?? current.type,
        url: url ?? current.url,
        cloudWorkspaceId: cloudWorkspaceId ?? current.cloudWorkspaceId,
        cloudAccountId: cloudAccountId ?? current.cloudAccountId,
      );

  String? _mergedValidationError(WorkspaceToCreate workspace) {
    final hasCloudMirror = _hasCloudMirror(workspace);
    if (workspace.name.isEmpty) {
      return 'Workspace name cannot be empty';
    }
    if (workspace.type == WorkspaceType.local &&
        (workspace.url != null || hasCloudMirror)) {
      return 'Local workspace cannot have remote metadata';
    }
    if (workspace.type == WorkspaceType.remote &&
        _hasMissingUrl(workspace.url) &&
        !hasCloudMirror) {
      return 'Remote workspace must have a URL or cloud ID';
    }

    return null;
  }

  bool _hasCloudMirror(WorkspaceToCreate workspace) =>
      workspace.cloudWorkspaceId != null && workspace.cloudAccountId != null;

  bool _hasMissingUrl(String? url) => url == null || url.isEmpty;

  String? _fieldValidationError({
    required String? name,
    required String? url,
    required String? cloudWorkspaceId,
    required String? cloudAccountId,
  }) {
    if (name != null && name.isEmpty) return 'Workspace name cannot be empty';
    if (url != null && url.isEmpty) return 'Workspace URL cannot be empty';
    if (cloudWorkspaceId != null && cloudWorkspaceId.isEmpty) {
      return 'Cloud workspace ID cannot be empty';
    }
    if (cloudAccountId != null && cloudAccountId.isEmpty) {
      return 'Cloud account ID cannot be empty';
    }

    return null;
  }
}
