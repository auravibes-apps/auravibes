// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_workspace_selection_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lastWorkspaceSelectionRepository)
final lastWorkspaceSelectionRepositoryProvider =
    LastWorkspaceSelectionRepositoryProvider._();

final class LastWorkspaceSelectionRepositoryProvider
    extends
        $FunctionalProvider<
          WorkspaceSelectionRepository,
          WorkspaceSelectionRepository,
          WorkspaceSelectionRepository
        >
    with $Provider<WorkspaceSelectionRepository> {
  LastWorkspaceSelectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastWorkspaceSelectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastWorkspaceSelectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkspaceSelectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceSelectionRepository create(Ref ref) {
    return lastWorkspaceSelectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceSelectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceSelectionRepository>(value),
    );
  }
}

String _$lastWorkspaceSelectionRepositoryHash() =>
    r'9eaf74dc630414862a8ebc06942a73c4662b97ef';
