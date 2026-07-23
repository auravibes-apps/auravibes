// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolve_workspace_selection_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(resolveWorkspaceSelectionUsecase)
final resolveWorkspaceSelectionUsecaseProvider =
    ResolveWorkspaceSelectionUsecaseProvider._();

final class ResolveWorkspaceSelectionUsecaseProvider
    extends
        $FunctionalProvider<
          ResolveWorkspaceSelectionUsecase,
          ResolveWorkspaceSelectionUsecase,
          ResolveWorkspaceSelectionUsecase
        >
    with $Provider<ResolveWorkspaceSelectionUsecase> {
  ResolveWorkspaceSelectionUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resolveWorkspaceSelectionUsecaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resolveWorkspaceSelectionUsecaseHash();

  @$internal
  @override
  $ProviderElement<ResolveWorkspaceSelectionUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResolveWorkspaceSelectionUsecase create(Ref ref) {
    return resolveWorkspaceSelectionUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResolveWorkspaceSelectionUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResolveWorkspaceSelectionUsecase>(
        value,
      ),
    );
  }
}

String _$resolveWorkspaceSelectionUsecaseHash() =>
    r'9567d4f5f34a3cb969dd5ad276a39d6c0096125a';
