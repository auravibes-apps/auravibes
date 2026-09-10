// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_entity.freezed.dart';

/// Entity representing a workspace in the Aura application.
///
/// A workspace is a container for organizing and managing different
/// projects or environments within the Aura application.
@immutable
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

  @override
  int get hashCode;

  @override
  String toString();

  @override
  bool operator ==(Object other);
}

@immutable
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

  /// Returns true if the workspace has a valid URL (for remote workspaces).
  bool get hasValidUrl {
    if (isLocal) return url == null && !hasCloudMirror();

    return isRemote && (_hasUrl(this) || _hasValidCloudMirror(this));
  }

  /// Returns true if the workspace is in a valid state.
  bool get isValid {
    return hasValidName && hasValidUrl;
  }

  @override
  String toString();

  /// Returns true if this workspace matches [expectedType] and is valid.
  bool isValidForType(WorkspaceType expectedType) =>
      type == expectedType && isValid;

  bool hasName(String expectedName) => name == expectedName;
}

extension WorkspaceToCreateValidation on WorkspaceToCreate {
  /// Returns true if this is a local workspace.
  bool get isLocal => type.isLocal;

  /// Returns true if this is a remote workspace.
  bool get isRemote => type.isRemote;

  bool matchesType(WorkspaceType expectedType) => type == expectedType;

  bool hasCloudMirror() => _hasCloudMirror(this);
}

@immutable
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
  @override
  int get hashCode;

  @override
  String toString();

  @override
  bool operator ==(Object other);

  String? validationErrorFor(WorkspaceEntity current) {
    if (_hasNoChanges(this)) {
      return 'At least one field must be provided';
    }

    final fieldError = _fieldValidationError(this);
    if (fieldError != null) return fieldError;

    return _mergedValidationError(_mergedWorkspace(this, current));
  }
}

bool _hasNoChanges(WorkspacePatch patch) =>
    patch.name == null &&
    patch.type == null &&
    patch.url == null &&
    patch.cloudWorkspaceId == null &&
    patch.cloudAccountId == null;

WorkspaceToCreate _mergedWorkspace(
  WorkspacePatch patch,
  WorkspaceEntity current,
) => WorkspaceToCreate(
  name: patch.name ?? current.name,
  type: patch.type ?? current.type,
  url: patch.url ?? current.url,
  cloudWorkspaceId: patch.cloudWorkspaceId ?? current.cloudWorkspaceId,
  cloudAccountId: patch.cloudAccountId ?? current.cloudAccountId,
);

String? _mergedValidationError(WorkspaceToCreate workspace) {
  final hasCloudMirror = _hasCloudMirror(workspace);
  return _firstValidationError([
    _emptyWorkspaceNameError(workspace),
    _localWorkspaceError(workspace, hasCloudMirror),
    _remoteWorkspaceError(workspace, hasCloudMirror),
  ]);
}

String? _emptyWorkspaceNameError(WorkspaceToCreate workspace) =>
    workspace.name.isEmpty ? 'Workspace name cannot be empty' : null;

String? _localWorkspaceError(
  WorkspaceToCreate workspace,
  bool hasCloudMirror,
) =>
    workspace.type == WorkspaceType.local &&
        (workspace.url != null || hasCloudMirror)
    ? 'Local workspace cannot have remote metadata'
    : null;

String? _remoteWorkspaceError(
  WorkspaceToCreate workspace,
  bool hasCloudMirror,
) =>
    workspace.type == WorkspaceType.remote &&
        _hasMissingUrl(workspace.url) &&
        !hasCloudMirror
    ? 'Remote workspace must have a URL or cloud ID'
    : null;

bool _hasCloudMirror(WorkspaceToCreate workspace) =>
    workspace.cloudWorkspaceId != null && workspace.cloudAccountId != null;

bool _hasUrl(WorkspaceToCreate workspace) => workspace.url?.isNotEmpty == true;

bool _hasValidCloudMirror(WorkspaceToCreate workspace) =>
    workspace.cloudWorkspaceId?.isNotEmpty == true &&
    workspace.cloudAccountId?.isNotEmpty == true;

bool _hasMissingUrl(String? url) => url == null || url.isEmpty;

String? _fieldValidationError(WorkspacePatch patch) => _firstValidationError([
  if (patch.name?.isEmpty == true) 'Workspace name cannot be empty',
  if (patch.url?.isEmpty == true) 'Workspace URL cannot be empty',
  if (patch.cloudWorkspaceId?.isEmpty == true)
    'Cloud workspace ID cannot be empty',
  if (patch.cloudAccountId?.isEmpty == true) 'Cloud account ID cannot be empty',
]);

String? _firstValidationError(Iterable<String?> errors) {
  for (final error in errors) {
    if (error != null) return error;
  }

  return null;
}
