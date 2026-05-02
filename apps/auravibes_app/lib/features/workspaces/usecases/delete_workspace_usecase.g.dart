// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_workspace_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [DeleteWorkspaceUseCase] instance.

@ProviderFor(deleteWorkspaceUseCase)
final deleteWorkspaceUseCaseProvider = DeleteWorkspaceUseCaseProvider._();

/// Provides a [DeleteWorkspaceUseCase] instance.

final class DeleteWorkspaceUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteWorkspaceUseCase,
          DeleteWorkspaceUseCase,
          DeleteWorkspaceUseCase
        >
    with $Provider<DeleteWorkspaceUseCase> {
  /// Provides a [DeleteWorkspaceUseCase] instance.
  DeleteWorkspaceUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteWorkspaceUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteWorkspaceUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteWorkspaceUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteWorkspaceUseCase create(Ref ref) {
    return deleteWorkspaceUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteWorkspaceUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteWorkspaceUseCase>(value),
    );
  }
}

String _$deleteWorkspaceUseCaseHash() =>
    r'8d68c0f996e0418548371f9f95c80d91b10bf946';
