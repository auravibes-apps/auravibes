import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace.freezed.dart';

/// Entity representing a workspace in the Aura application.
///
/// A workspace is a container for organizing and managing different
/// projects or environments within the Aura application.
@freezed
abstract class WorkspaceEntity with _$WorkspaceEntity {
  /// Creates a new Workspace instance
  const factory WorkspaceEntity({
    /// Unique identifier for the workspace
    required String id,

    /// Human-readable name of the workspace
    required String name,

    /// Type of workspace (local or remote)
    required WorkspaceType type,

    /// Timestamp when the workspace was created
    required DateTime createdAt,

    /// Timestamp when the workspace was last updated
    required DateTime updatedAt,

    /// URL for remote workspaces, null for local workspaces
    String? url,
  }) = _WorkspaceEntity;
  const WorkspaceEntity._();
}

@freezed
abstract class WorkspaceToCreate with _$WorkspaceToCreate {
  /// Creates a new WorkspaceToCreate instance
  const factory WorkspaceToCreate({
    /// Human-readable name of the workspace
    required String name,

    /// Type of workspace (local or remote)
    required WorkspaceType type,

    /// URL for remote workspaces, null for local workspaces
    String? url,
  }) = _WorkspaceToCreate;
  const WorkspaceToCreate._();

  /// Returns true if the workspace name is not empty
  bool get hasValidName => name.isNotEmpty;

  /// Returns true if this is a local workspace
  bool get isLocal => type.isLocal;

  /// Returns true if this is a remote workspace
  bool get isRemote => type.isRemote;

  /// Returns true if the workspace has a valid URL (for remote workspaces)
  bool get hasValidUrl {
    if (isLocal && url == null) return true;
    return !isLocal && url != null && url!.isNotEmpty;
  }

  /// Returns true if the workspace is in a valid state
  bool get isValid {
    return hasValidName && hasValidUrl;
  }
}

@freezed
abstract class WorkspacePatch with _$WorkspacePatch {
  const factory WorkspacePatch({
    String? name,
    WorkspaceType? type,
    String? url,
  }) = _WorkspacePatch;
  const WorkspacePatch._();

  String? validationErrorFor(WorkspaceEntity current) {
    if (name == null && type == null && url == null) {
      return 'At least one field must be provided';
    }

    if (name != null && name!.isEmpty) {
      return 'Workspace name cannot be empty';
    }

    if (url != null && url!.isEmpty) {
      return 'Workspace URL cannot be empty';
    }

    final mergedName = name ?? current.name;
    final mergedType = type ?? current.type;
    final mergedUrl = url ?? current.url;

    if (mergedName.isEmpty) {
      return 'Workspace name cannot be empty';
    }

    if (mergedType == WorkspaceType.local && mergedUrl != null) {
      return 'Local workspace cannot have a URL';
    }

    if (mergedType == WorkspaceType.remote &&
        (mergedUrl == null || mergedUrl.isEmpty)) {
      return 'Remote workspace must have a URL';
    }

    return null;
  }
}
