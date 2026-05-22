// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_workspace_use_case.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [CreateWorkspaceUseCase] instance.

@ProviderFor(createWorkspaceUseCase)
final createWorkspaceUseCaseProvider = CreateWorkspaceUseCaseProvider._();

/// Provides a [CreateWorkspaceUseCase] instance.

final class CreateWorkspaceUseCaseProvider
    extends
        $FunctionalProvider<
          CreateWorkspaceUseCase,
          CreateWorkspaceUseCase,
          CreateWorkspaceUseCase
        >
    with $Provider<CreateWorkspaceUseCase> {
  /// Provides a [CreateWorkspaceUseCase] instance.
  CreateWorkspaceUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createWorkspaceUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createWorkspaceUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateWorkspaceUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateWorkspaceUseCase create(Ref ref) {
    return createWorkspaceUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateWorkspaceUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateWorkspaceUseCase>(value),
    );
  }
}

String _$createWorkspaceUseCaseHash() =>
    r'4ba7982f79326c4e51da1710e1dd6c2f2f3a3b1d';
