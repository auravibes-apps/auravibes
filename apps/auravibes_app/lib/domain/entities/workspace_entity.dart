// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_entity.freezed.dart';

/// Entity representing a workspace in the Aura application.
///
/// A workspace is a container for organizing and managing different
/// projects or environments within the Aura application.
@freezed
abstract class WorkspaceEntity with _$WorkspaceEntity {
  /// Creates a new Workspace instance.
  const factory WorkspaceEntity({
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
  const WorkspaceEntity._();
}

@freezed
abstract class WorkspaceToCreate with _$WorkspaceToCreate {
  /// Creates a new WorkspaceToCreate instance.
  const factory WorkspaceToCreate({
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
  const WorkspaceToCreate._();

  /// Returns true if the workspace name is not empty.
  bool get hasValidName => name.isNotEmpty;

  /// Returns true if this is a local workspace.
  bool get isLocal => type.isLocal;

  /// Returns true if this is a remote workspace.
  bool get isRemote => type.isRemote;

  /// Returns true if the workspace has a valid URL (for remote workspaces).
  bool get hasValidUrl {
    final url = this.url;
    final cloudWorkspaceId = this.cloudWorkspaceId;
    final cloudAccountId = this.cloudAccountId;
    final hasCloudMirror = cloudWorkspaceId != null && cloudAccountId != null;
    if (isLocal && url == null && !hasCloudMirror) return true;

    return isRemote &&
        ((url != null && url.isNotEmpty) ||
            (cloudWorkspaceId != null &&
                cloudWorkspaceId.isNotEmpty &&
                cloudAccountId != null &&
                cloudAccountId.isNotEmpty));
  }

  /// Returns true if the workspace is in a valid state.
  bool get isValid {
    return hasValidName && hasValidUrl;
  }
}

@freezed
abstract class WorkspacePatch with _$WorkspacePatch {
  // Null fields mean the patch leaves those values unchanged.
  // ignore: unnecessary-nullable
  const factory WorkspacePatch({
    String? name,
    WorkspaceType? type,
    String? url,
    String? cloudWorkspaceId,
    String? cloudAccountId,
  }) = _WorkspacePatch;
  const WorkspacePatch._();

  String? validationErrorFor(WorkspaceEntity current) {
    final name = this.name;
    final url = this.url;
    final cloudWorkspaceId = this.cloudWorkspaceId;
    final cloudAccountId = this.cloudAccountId;

    if (name == null &&
        type == null &&
        url == null &&
        cloudWorkspaceId == null &&
        cloudAccountId == null) {
      return 'At least one field must be provided';
    }

    if (name != null && name.isEmpty) {
      return 'Workspace name cannot be empty';
    }

    if (url != null && url.isEmpty) {
      return 'Workspace URL cannot be empty';
    }

    if (cloudWorkspaceId != null && cloudWorkspaceId.isEmpty) {
      return 'Cloud workspace ID cannot be empty';
    }

    if (cloudAccountId != null && cloudAccountId.isEmpty) {
      return 'Cloud account ID cannot be empty';
    }

    final mergedName = name ?? current.name;
    final mergedType = type ?? current.type;
    final mergedUrl = url ?? current.url;
    final mergedCloudWorkspaceId = cloudWorkspaceId ?? current.cloudWorkspaceId;
    final mergedCloudAccountId = cloudAccountId ?? current.cloudAccountId;
    final hasCloudMirror =
        mergedCloudWorkspaceId != null && mergedCloudAccountId != null;

    if (mergedName.isEmpty) {
      return 'Workspace name cannot be empty';
    }

    if (mergedType == WorkspaceType.local &&
        (mergedUrl != null || hasCloudMirror)) {
      return 'Local workspace cannot have remote metadata';
    }

    if (mergedType == WorkspaceType.remote &&
        (mergedUrl == null || mergedUrl.isEmpty) &&
        !hasCloudMirror) {
      return 'Remote workspace must have a URL or cloud ID';
    }

    return null;
  }
}
