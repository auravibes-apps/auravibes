// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_management_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier that tracks the workspace-management UI mode and
/// which workspace is currently being edited.
///
/// Does not own workspace data (that lives in the workspace list provider).

@ProviderFor(WorkspaceManagementMode)
final workspaceManagementModeProvider = WorkspaceManagementModeProvider._();

/// Notifier that tracks the workspace-management UI mode and
/// which workspace is currently being edited.
///
/// Does not own workspace data (that lives in the workspace list provider).
final class WorkspaceManagementModeProvider
    extends
        $NotifierProvider<WorkspaceManagementMode, WorkspaceManagementState> {
  /// Notifier that tracks the workspace-management UI mode and
  /// which workspace is currently being edited.
  ///
  /// Does not own workspace data (that lives in the workspace list provider).
  WorkspaceManagementModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceManagementModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceManagementModeHash();

  @$internal
  @override
  WorkspaceManagementMode create() => WorkspaceManagementMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceManagementState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceManagementState>(value),
    );
  }
}

String _$workspaceManagementModeHash() =>
    r'4bcac3379d519251888be5993e715094500c865b';

/// Notifier that tracks the workspace-management UI mode and
/// which workspace is currently being edited.
///
/// Does not own workspace data (that lives in the workspace list provider).

abstract class _$WorkspaceManagementMode
    extends $Notifier<WorkspaceManagementState> {
  WorkspaceManagementState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<WorkspaceManagementState, WorkspaceManagementState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkspaceManagementState, WorkspaceManagementState>,
              WorkspaceManagementState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
