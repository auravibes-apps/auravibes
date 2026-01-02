// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_workspace.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedWorkspace)
final selectedWorkspaceProvider = SelectedWorkspaceProvider._();

final class SelectedWorkspaceProvider
    extends $AsyncNotifierProvider<SelectedWorkspace, WorkspaceEntity> {
  SelectedWorkspaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedWorkspaceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedWorkspaceHash();

  @$internal
  @override
  SelectedWorkspace create() => SelectedWorkspace();
}

String _$selectedWorkspaceHash() => r'8615dd9d6cd11936dd1b8c6f3c61385cc11d9926';

abstract class _$SelectedWorkspace extends $AsyncNotifier<WorkspaceEntity> {
  FutureOr<WorkspaceEntity> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WorkspaceEntity>, WorkspaceEntity>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WorkspaceEntity>, WorkspaceEntity>,
              AsyncValue<WorkspaceEntity>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
