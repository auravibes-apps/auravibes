// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_workspace_use_case.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides an [EditWorkspaceUseCase] instance.

@ProviderFor(editWorkspaceUseCase)
final editWorkspaceUseCaseProvider = EditWorkspaceUseCaseProvider._();

/// Provides an [EditWorkspaceUseCase] instance.

final class EditWorkspaceUseCaseProvider
    extends
        $FunctionalProvider<
          EditWorkspaceUseCase,
          EditWorkspaceUseCase,
          EditWorkspaceUseCase
        >
    with $Provider<EditWorkspaceUseCase> {
  /// Provides an [EditWorkspaceUseCase] instance.
  EditWorkspaceUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editWorkspaceUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editWorkspaceUseCaseHash();

  @$internal
  @override
  $ProviderElement<EditWorkspaceUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EditWorkspaceUseCase create(Ref ref) {
    return editWorkspaceUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditWorkspaceUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditWorkspaceUseCase>(value),
    );
  }
}

String _$editWorkspaceUseCaseHash() =>
    r'f1956d57765223c50a92143f595635cce0ad97e9';
