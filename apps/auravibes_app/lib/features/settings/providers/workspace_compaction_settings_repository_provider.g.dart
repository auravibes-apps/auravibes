// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_compaction_settings_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceCompactionSettingsRepository)
final workspaceCompactionSettingsRepositoryProvider =
    WorkspaceCompactionSettingsRepositoryProvider._();

final class WorkspaceCompactionSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          WorkspaceCompactionSettingsRepository,
          WorkspaceCompactionSettingsRepository,
          WorkspaceCompactionSettingsRepository
        >
    with $Provider<WorkspaceCompactionSettingsRepository> {
  WorkspaceCompactionSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceCompactionSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$workspaceCompactionSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkspaceCompactionSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceCompactionSettingsRepository create(Ref ref) {
    return workspaceCompactionSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceCompactionSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<WorkspaceCompactionSettingsRepository>(value),
    );
  }
}

String _$workspaceCompactionSettingsRepositoryHash() =>
    r'9d71ac4ce7a67df77c38f945a620da830cf234f4';
